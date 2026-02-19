// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierLidoAdapter } from "src/interfaces/ISablierLidoAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract CreateVault_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_TokenAddressZero() external {
        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierBob_TokenAddressZero.selector));
        bob.createVault({
            token: IERC20(address(0)),
            oracle: AggregatorV3Interface(address(mockOracle)),
            expiry: EXPIRY,
            targetPrice: TARGET_PRICE
        });
    }

    function test_RevertWhen_TokenIsNativeToken() external whenTokenAddressNotZero {
        // Set the native token.
        setMsgSender(address(comptroller));
        bob.setNativeToken(address(dai));
        setMsgSender(users.depositor);

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierBob_ForbidNativeToken.selector, address(dai)));
        bob.createVault({
            token: IERC20(address(dai)),
            oracle: AggregatorV3Interface(address(mockOracle)),
            expiry: EXPIRY,
            targetPrice: TARGET_PRICE
        });
    }

    function test_RevertWhen_ExpiryInPast() external whenTokenAddressNotZero whenTokenNotNativeToken {
        // It should revert.
        uint40 pastExpiry = uint40(block.timestamp - 1);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierBob_ExpiryInPast.selector, pastExpiry, uint40(block.timestamp))
        );
        bob.createVault({
            token: IERC20(address(dai)),
            oracle: AggregatorV3Interface(address(mockOracle)),
            expiry: pastExpiry,
            targetPrice: TARGET_PRICE
        });
    }

    function test_RevertWhen_TargetPriceZero() external whenTokenAddressNotZero whenTokenNotNativeToken whenExpiryInFuture {
        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierBob_TargetPriceZero.selector));
        bob.createVault({
            token: IERC20(address(dai)),
            oracle: AggregatorV3Interface(address(mockOracle)),
            expiry: EXPIRY,
            targetPrice: 0
        });
    }

    function test_RevertWhen_TargetPriceAtOrBelowCurrentPrice()
        external
        whenTokenAddressNotZero
        whenTokenNotNativeToken
        whenExpiryInFuture
        whenTargetPriceNotZero
    {
        // Test with target price equal to current price.
        uint128 targetPriceEqualToCurrent = INITIAL_PRICE;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierBob_TargetPriceTooLow.selector, targetPriceEqualToCurrent, INITIAL_PRICE
            )
        );
        bob.createVault({
            token: IERC20(address(dai)),
            oracle: AggregatorV3Interface(address(mockOracle)),
            expiry: EXPIRY,
            targetPrice: targetPriceEqualToCurrent
        });

        // Test with target price below current price.
        uint128 targetPriceBelowCurrent = INITIAL_PRICE - 1;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierBob_TargetPriceTooLow.selector, targetPriceBelowCurrent, INITIAL_PRICE)
        );
        bob.createVault({
            token: IERC20(address(dai)),
            oracle: AggregatorV3Interface(address(mockOracle)),
            expiry: EXPIRY,
            targetPrice: targetPriceBelowCurrent
        });
    }

    function test_GivenNoDefaultAdapterForToken()
        external
        whenTokenAddressNotZero
        whenTokenNotNativeToken
        whenExpiryInFuture
        whenTargetPriceNotZero
        whenTargetPriceAboveCurrentPrice
    {
        // It should create the vault without adapter.
        uint256 expectedVaultId = bob.nextVaultId();

        // Create the vault.
        uint256 vaultId = bob.createVault({
            token: IERC20(address(dai)),
            oracle: AggregatorV3Interface(address(mockOracle)),
            expiry: EXPIRY,
            targetPrice: TARGET_PRICE
        });

        // Assert the vault ID matches expected.
        assertEq(vaultId, expectedVaultId, "vaultId");

        // Assert the vault was created correctly.
        assertEq(bob.getUnderlyingToken(vaultId), IERC20(address(dai)), "vault.token");
        assertEq(address(bob.getOracle(vaultId)), address(mockOracle), "vault.oracle");
        assertEq(bob.getExpiry(vaultId), EXPIRY, "vault.expiry");
        assertEq(bob.getTargetPrice(vaultId), TARGET_PRICE, "vault.targetPrice");
        assertEq(address(bob.getAdapter(vaultId)), address(0), "vault.adapter should be zero");
        assertEq(bob.getLastSyncedPrice(vaultId), INITIAL_PRICE, "vault.lastSyncedPrice");
        assertEq(bob.getLastSyncedAt(vaultId), uint40(block.timestamp), "vault.lastSyncedAt");

        // Assert the share token was deployed.
        assertTrue(address(bob.getShareToken(vaultId)) != address(0), "shareToken should be deployed");

        // Assert the share token decimals match the underlying token.
        assertEq(bob.getShareToken(vaultId).decimals(), dai.decimals(), "shareToken.decimals");

        // Assert the next vault ID was incremented.
        assertEq(bob.nextVaultId(), vaultId + 1, "nextVaultId");
    }

    function test_GivenDefaultAdapterForToken()
        external
        whenTokenAddressNotZero
        whenTokenNotNativeToken
        whenExpiryInFuture
        whenTargetPriceNotZero
        whenTargetPriceAboveCurrentPrice
    {
        // It should create the vault with adapter.
        setMsgSender(address(comptroller));
        bob.setDefaultAdapter(IERC20(address(weth)), ISablierLidoAdapter(address(adapter)));

        // Switch back to depositor.
        setMsgSender(users.depositor);

        // Create the vault with WETH (which has an adapter).
        uint256 vaultId = bob.createVault({
            token: IERC20(address(weth)),
            oracle: AggregatorV3Interface(address(mockOracle)),
            expiry: EXPIRY,
            targetPrice: TARGET_PRICE
        });

        // Assert the vault was created with the adapter.
        assertEq(bob.getUnderlyingToken(vaultId), IERC20(address(weth)), "vault.token");
        assertEq(address(bob.getAdapter(vaultId)), address(adapter), "vault.adapter should be set");
    }
}
