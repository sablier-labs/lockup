// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud, UD60x18 } from "@prb/math/src/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract UnstakeFullAmount_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_NullVault() external {
        // It should revert.
        expectRevert_NullVault(abi.encodeCall(bob.unstakeTokensViaAdapter, (vaultIds.nullVault)), vaultIds.nullVault);
    }

    function test_RevertGiven_VaultNotSettled() external givenNotNullVault {
        // It should revert.
        // The adapterVault is not settled, so unstakeFullAmount should revert.
        expectRevert_VaultNotSettled(
            abi.encodeCall(bob.unstakeTokensViaAdapter, (vaultIds.adapterVault)), vaultIds.adapterVault
        );
    }

    function test_RevertGiven_VaultHasNoAdapter() external givenNotNullVault givenVaultSettled {
        // It should revert.
        // settledVault has no adapter.
        expectRevert_VaultHasNoAdapter(
            abi.encodeCall(bob.unstakeTokensViaAdapter, (vaultIds.settledVault)), vaultIds.settledVault
        );
    }

    function test_RevertGiven_VaultAlreadyUnstaked() external givenNotNullVault givenVaultSettled givenVaultHasAdapter {
        // It should revert.
        // Create a vault with adapter and deposit.
        uint256 vaultId = createVaultWithAdapter();
        uint128 amount = WETH_DEPOSIT_AMOUNT;
        bob.enter(vaultId, amount);

        // Warp past expiry to settle the vault.
        vm.warp(EXPIRY + 1);

        // Unstake all once.
        bob.unstakeTokensViaAdapter(vaultId);

        // Verify unstaking happened (wethReceived > 0).
        assertTrue(adapter.getWethReceivedAfterUnstaking(vaultId) > 0, "vault should have wethReceived after unstake");

        // Attempt to unstake again should revert.
        expectRevert_VaultAlreadyUnstaked(abi.encodeCall(bob.unstakeTokensViaAdapter, (vaultId)), vaultId);
    }

    function test_RevertGiven_NothingToUnstake()
        external
        givenNotNullVault
        givenVaultSettled
        givenVaultHasAdapter
        givenVaultNotUnstaked
        givenNothingToUnstake
    {
        // It should revert.
        // Create a vault with adapter but don't deposit anything.
        uint256 vaultId = createVaultWithAdapter();

        // Warp past expiry to settle the vault.
        vm.warp(EXPIRY + 1);

        // Attempt to unstake should revert since there's nothing to unstake.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierBob_UnstakeAmountZero.selector, vaultId));
        bob.unstakeTokensViaAdapter(vaultId);
    }

    function test_RevertWhen_SlippageExceeded()
        external
        givenNotNullVault
        givenVaultSettled
        givenVaultHasAdapter
        givenVaultNotUnstaked
        givenSomethingToUnstake
        whenSlippageExceeded
    {
        // It should revert when Curve returns less ETH than the minimum acceptable.
        // Create a vault with adapter and deposit.
        uint256 vaultId = createVaultWithAdapter();
        uint128 amount = WETH_DEPOSIT_AMOUNT;
        bob.enter(vaultId, amount);

        // Warp past expiry to settle the vault.
        vm.warp(EXPIRY + 1);

        // Configure the mock Curve pool to simulate extreme slippage (10% loss).
        // The adapter has a default slippage tolerance of 0.5% (50 bps), so 10% should exceed it.
        curvePool.setActualSlippage(1000); // 10% slippage

        // The adapter calculates minEthOut based on get_dy() which returns the expected amount,
        // then applies slippage tolerance. If exchange() returns less than minEthOut, it reverts.
        // Get the total wstETH to calculate expected values.
        uint128 totalWstETH = adapter.getTotalYieldBearingTokenBalance(vaultId);

        // Calculate expected values for the error:
        // 1. wstETH unwrap: totalWstETH * 1e18 / exchangeRate (0.9e18) = stETH amount
        uint256 stETHAmount = (totalWstETH * 1e18) / wsteth.exchangeRate();
        // 2. Expected ETH from Curve (get_dy returns 1:1): stETHAmount
        uint256 expectedEthOut = stETHAmount;
        // 3. minEthOut with 0.5% slippage tolerance
        UD60x18 slippageTolerance = adapter.slippageTolerance();
        uint256 minEthOut = ud(expectedEthOut).mul(ud(1e18).sub(slippageTolerance)).unwrap();
        // 4. Actual output with 10% slippage
        uint256 actualOutput = (stETHAmount * (10_000 - 1000)) / 10_000;

        // Attempt to unstake all should revert with SlippageExceeded.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLidoAdapter_SlippageExceeded.selector, minEthOut, actualOutput)
        );
        bob.unstakeTokensViaAdapter(vaultId);
    }

    function test_WhenSlippageWithinTolerance()
        external
        givenNotNullVault
        givenVaultSettled
        givenVaultHasAdapter
        givenVaultNotUnstaked
        givenSomethingToUnstake
        whenSlippageWithinTolerance
    {
        // It should unstake all tokens.
        // Create a vault with adapter and deposit.
        uint256 vaultId = createVaultWithAdapter();
        uint128 amount = WETH_DEPOSIT_AMOUNT;
        bob.enter(vaultId, amount);

        // Warp past expiry to settle the vault.
        vm.warp(EXPIRY + 1);

        // Get the total wstETH in the vault (exchange rate 0.9e18, so 1 WETH → 0.9 wstETH).
        uint128 totalWstETH = adapter.getTotalYieldBearingTokenBalance(vaultId);
        assertTrue(totalWstETH > 0, "vault should have wstETH before unstake");

        // Record WETH balance before unstake.
        uint256 bobWethBefore = IERC20(address(weth)).balanceOf(address(bob));

        // Unstake all.
        bob.unstakeTokensViaAdapter(vaultId);

        // Verify vault is now unstaked (wethReceived is non-zero).
        assertGt(adapter.getWethReceivedAfterUnstaking(vaultId), 0, "vault should have wethReceived after unstake");

        // Verify WETH was transferred to bob contract.
        // The amount will be slightly less than deposited due to Curve slippage.
        uint256 bobWethAfter = IERC20(address(weth)).balanceOf(address(bob));
        uint256 wethReceived = bobWethAfter - bobWethBefore;

        // Should receive close to deposited amount (minus small Curve slippage).
        uint256 minExpected = (amount * 9980) / 10_000; // 99.8% minimum
        assertGe(wethReceived, minExpected, "WETH received should be close to deposited");
        assertGt(totalWstETH, 0, "totalWstETH should be non-zero");
    }
}
