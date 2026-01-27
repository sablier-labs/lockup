// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";
import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Integration_Test } from "./../../Integration.t.sol";

contract Redeem_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_NullVault() external {
        // It should revert.
        expectRevert_NullVault(abi.encodeCall(bob.redeem, (vaultIds.nullVault)), vaultIds.nullVault);
    }

    function test_RevertGiven_VaultNotSettled() external givenNotNullVault {
        // It should revert.
        expectRevert_VaultNotSettled(abi.encodeCall(bob.redeem, (vaultIds.defaultVault)), vaultIds.defaultVault);
    }

    function test_RevertWhen_NoSharesToRedeem() external givenNotNullVault givenVaultSettled {
        // It should revert.
        // Use the settled vault but with a user who has no shares.
        setMsgSender(users.eve);
        expectRevert_NoSharesToRedeem(
            abi.encodeCall(bob.redeem, (vaultIds.settledVault)), vaultIds.settledVault, users.eve
        );
    }

    function test_RevertWhen_FeePaymentInsufficient()
        external
        givenNotNullVault
        givenVaultSettled
        whenCallerHasShares
        givenVaultHasNoAdapter
    {
        // It should revert.
        // Set a non-zero minimum fee for Bob protocol (1 USD = 1e8 in comptroller's 8-decimal format).
        // Use the admin account which has FEE_MANAGEMENT_ROLE.
        setMsgSender(admin);
        comptroller.setMinFeeUSD(ISablierComptroller.Protocol.Bob, 1e8);
        setMsgSender(users.depositor);

        // Create a fresh vault and deposit.
        uint256 vaultId = createDefaultVault();
        bob.enter(vaultId, DEPOSIT_AMOUNT);

        // Warp past expiry to settle the vault.
        vm.warp(EXPIRY + 1);

        // Get the minimum fee required.
        uint256 minFee =
            comptroller.calculateMinFeeWeiFor({ protocol: ISablierComptroller.Protocol.Bob, user: users.depositor });

        // Ensure minFee is greater than 0 for this test.
        assertGt(minFee, 0, "minFee should be greater than 0");

        // Attempt to redeem with insufficient fee.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierBob_InsufficientFeePayment.selector, minFee - 1, minFee));
        bob.redeem{ value: minFee - 1 }(vaultId);
    }

    function test_WhenNativeFeeTransferredToComptroller()
        external
        givenNotNullVault
        givenVaultSettled
        whenCallerHasShares
        givenVaultHasNoAdapter
    {
        // It should transfer the native fee to the comptroller address.
        // Create a fresh vault and deposit.
        uint256 vaultId = createDefaultVault();
        bob.enter(vaultId, DEPOSIT_AMOUNT);

        // Warp past expiry to settle the vault.
        vm.warp(EXPIRY + 1);

        // Get comptroller balance before.
        uint256 comptrollerBalanceBefore = address(comptroller).balance;

        // Redeem with a non-zero msg.value.
        bob.redeem{ value: 1 ether }(vaultId);

        // Assert native fee was transferred to comptroller.
        uint256 comptrollerBalanceAfter = address(comptroller).balance;
        assertEq(comptrollerBalanceAfter - comptrollerBalanceBefore, 1 ether, "fee should be sent to comptroller");
    }

    function test_WhenFeePaymentSufficient()
        external
        givenNotNullVault
        givenVaultSettled
        whenCallerHasShares
        givenVaultHasNoAdapter
    {
        // It should redeem with native fee.
        // Create a fresh vault and deposit.
        uint256 vaultId = createDefaultVault();
        uint128 amount = DEPOSIT_AMOUNT;
        bob.enter(vaultId, amount);

        // Get state before.
        address shareToken = address(bob.getShareToken(vaultId));
        uint256 daiBalanceBefore = dai.balanceOf(users.depositor);
        uint256 adminEthBefore = comptroller.admin().balance;

        // Warp past expiry to settle the vault.
        vm.warp(EXPIRY + 1);

        // Get the minimum fee required.
        uint256 minFee =
            comptroller.calculateMinFeeWeiFor({ protocol: ISablierComptroller.Protocol.Bob, user: users.depositor });

        // Expect the Redeem event (feeAmount is 0 for non-adapter vaults).
        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.Redeem({
            vaultId: vaultId,
            user: users.depositor,
            amountReceived: amount,
            sharesBurned: amount,
            fee: 0
        });

        // Redeem with sufficient fee.
        (uint256 transferredAmount, uint256 feeAmount) = bob.redeem{ value: minFee }(vaultId);

        // Assert return values: for non-adapter vaults, transferredAmount equals deposit and feeAmount is 0.
        assertEq(transferredAmount, amount, "transferredAmount should equal deposit amount");
        assertEq(feeAmount, 0, "feeAmount should be 0 for non-adapter vaults");

        // Assert shares were burned.
        uint256 shareBalanceAfter = IERC20(shareToken).balanceOf(users.depositor);
        assertEq(shareBalanceAfter, 0, "share balance should be zero after redeem");

        // Assert tokens were returned.
        uint256 daiBalanceAfter = dai.balanceOf(users.depositor);
        assertEq(daiBalanceAfter - daiBalanceBefore, amount, "tokens returned");

        // Assert native fee was forwarded to comptroller admin.
        uint256 adminEthAfter = comptroller.admin().balance;
        assertEq(adminEthAfter - adminEthBefore, minFee, "fee forwarded to admin");
    }

    function test_GivenVaultNotUnstaked()
        external
        givenNotNullVault
        givenVaultSettled
        whenCallerHasShares
        givenVaultHasAdapter
    {
        // It should unstake all and redeem.
        // Create a vault with adapter and deposit.
        uint256 vaultId = createVaultWithAdapter();
        uint128 amount = WETH_DEPOSIT_AMOUNT;
        bob.enter(vaultId, amount);

        // Warp past expiry to settle the vault.
        vm.warp(EXPIRY + 1);

        // Verify vault has not been unstaked yet.
        assertEq(adapter.getWethReceivedAfterUnstaking(vaultId), 0, "vault should not be unstaked before redeem");

        // Redeem (should trigger unstakeFullAmount first).
        (uint256 transferredAmount,) = bob.redeem(vaultId);

        // Assert return values: transferredAmount should be non-zero.
        assertGt(transferredAmount, 0, "transferredAmount should be non-zero");

        // Verify vault is now unstaked (wethReceived > 0).
        assertGt(adapter.getWethReceivedAfterUnstaking(vaultId), 0, "vault should be unstaked after redeem");
    }

    function test_GivenNoPositiveYield()
        external
        givenNotNullVault
        givenVaultSettled
        whenCallerHasShares
        givenVaultHasAdapter
        givenVaultAlreadyUnstaked
    {
        // It should redeem without fee.
        // Create a vault with adapter and deposit.
        uint256 vaultId = createVaultWithAdapter();
        uint128 amount = WETH_DEPOSIT_AMOUNT;
        bob.enter(vaultId, amount);

        // Warp past expiry to settle the vault.
        vm.warp(EXPIRY + 1);

        // Manually unstake all first.
        bob.unstakeTokensViaAdapter(vaultId);

        // Get state before.
        uint256 wethBalanceBefore = IERC20(address(weth)).balanceOf(users.depositor);

        // Redeem.
        (uint256 transferredAmount, uint256 feeAmount) = bob.redeem(vaultId);

        // Assert return values: no positive yield means feeAmount is 0.
        assertEq(feeAmount, 0, "feeAmount should be 0 when no positive yield");

        // Assert WETH returned is close to deposited amount (minus Curve slippage).
        // No yield fee since there's no positive yield.
        uint256 wethBalanceAfter = IERC20(address(weth)).balanceOf(users.depositor);
        uint256 wethReturned = wethBalanceAfter - wethBalanceBefore;
        uint256 minExpected = (amount * 9980) / 10_000; // 99.8% minimum (accounts for slippage)
        assertGe(wethReturned, minExpected, "WETH returned should be close to deposited amount");

        // Assert transferredAmount matches actual WETH received.
        assertEq(transferredAmount, wethReturned, "transferredAmount should match actual WETH received");
    }

    function test_GivenPositiveYield()
        external
        givenNotNullVault
        givenVaultSettled
        whenCallerHasShares
        givenVaultHasAdapter
        givenVaultAlreadyUnstaked
    {
        // It should redeem with yield fee.
        // Create a vault with adapter and deposit.
        uint256 vaultId = createVaultWithAdapter();
        uint128 amount = WETH_DEPOSIT_AMOUNT;
        bob.enter(vaultId, amount);

        // Simulate yield by changing the wstETH exchange rate.
        // Lower rate = more stETH per wstETH when unwrapping = yield.
        // To get 10% yield: new_rate = old_rate / 1.1 = 0.9e18 / 1.1 = 0.818e18
        wsteth.setExchangeRate(0.818e18);

        // Warp past expiry to settle the vault.
        vm.warp(EXPIRY + 1);

        // Manually unstake all first.
        bob.unstakeTokensViaAdapter(vaultId);

        // Get state before.
        uint256 wethBalanceBefore = IERC20(address(weth)).balanceOf(users.depositor);
        uint256 comptrollerBalanceBefore = IERC20(address(weth)).balanceOf(address(comptroller));

        // Redeem.
        (uint256 transferredAmount, uint256 feeAmount) = bob.redeem(vaultId);

        // Assert return values: positive yield means non-zero feeAmount.
        assertGt(feeAmount, 0, "feeAmount should be non-zero with positive yield");
        assertGt(transferredAmount, 0, "transferredAmount should be non-zero");

        // Assert user received WETH (with some yield minus fee).
        uint256 wethBalanceAfter = IERC20(address(weth)).balanceOf(users.depositor);
        uint256 wethReturned = wethBalanceAfter - wethBalanceBefore;

        // Assert transferredAmount matches actual WETH received.
        assertEq(transferredAmount, wethReturned, "transferredAmount should match actual WETH received");

        // User should receive more than deposited amount due to yield.
        assertGt(wethReturned, 0, "WETH returned should be non-zero");

        // Assert fee was sent to comptroller (if there was positive yield).
        uint256 comptrollerBalanceAfter = IERC20(address(weth)).balanceOf(address(comptroller));
        uint256 feeReceived = comptrollerBalanceAfter - comptrollerBalanceBefore;
        assertGt(feeReceived, 0, "fee should be sent to comptroller");

        // Assert feeAmount return value matches actual fee sent to comptroller.
        assertEq(feeAmount, feeReceived, "feeAmount should match actual fee sent to comptroller");
    }
}
