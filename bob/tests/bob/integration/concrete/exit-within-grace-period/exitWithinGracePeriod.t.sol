// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierBob } from "src/interfaces/ISablierBob.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract ExitWithinGracePeriod_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_NullVault() external {
        // It should revert.
        expectRevert_NullVault(abi.encodeCall(bob.exitWithinGracePeriod, (vaultIds.nullVault)), vaultIds.nullVault);
    }

    function test_RevertGiven_VaultSettled() external givenNotNullVault {
        // It should revert when trying to exit a settled vault.
        // Create a vault and deposit.
        uint256 vaultId = createDefaultVault();
        uint128 amount = DEPOSIT_AMOUNT;
        bob.enter(vaultId, amount);

        // Settle the vault by setting price to target.
        mockOracle.setPrice(SETTLED_PRICE);
        bob.syncPriceFromOracle(vaultId);

        // Verify we're still within the grace period.
        uint40 depositedAt = bob.getFirstDepositTime(vaultId, users.depositor);
        uint40 gracePeriodEnd = depositedAt + 4 hours;
        assertTrue(block.timestamp < gracePeriodEnd, "should still be in grace period");

        // Attempt to exit should revert because vault is settled.
        expectRevert_VaultSettled(abi.encodeCall(bob.exitWithinGracePeriod, (vaultId)), vaultId);
    }

    function test_RevertGiven_VaultExpired() external givenNotNullVault {
        // It should revert when trying to exit an expired vault.
        // Create a vault and deposit.
        uint256 vaultId = createDefaultVault();
        uint128 amount = DEPOSIT_AMOUNT;
        bob.enter(vaultId, amount);

        // Warp past expiry (vault expires but price never hit target).
        vm.warp(EXPIRY + 1);

        // Attempt to exit should revert because vault is expired.
        expectRevert_VaultSettled(abi.encodeCall(bob.exitWithinGracePeriod, (vaultId)), vaultId);
    }

    function test_RevertWhen_NoSharesToRedeem() external givenNotNullVault givenVaultActive {
        // It should revert.
        uint256 vaultId = vaultIds.defaultVault;
        expectRevert_NoSharesToRedeem(abi.encodeCall(bob.exitWithinGracePeriod, (vaultId)), vaultId, users.depositor);
    }

    function test_RevertWhen_CallerNotOriginalDepositor()
        external
        givenNotNullVault
        givenVaultActive
        whenCallerHasShares
    {
        // User A deposits and transfers shares to User B.
        uint256 vaultId = vaultIds.defaultVault;
        uint128 amount = DEPOSIT_AMOUNT;

        // User A makes a deposit.
        bob.enter(vaultId, amount);

        // User A transfers shares to User B.
        IERC20(address(bob.getShareToken(vaultId))).transfer(users.depositor2, amount);

        // User B tries to exit within grace period but has no depositedAt.
        vm.stopPrank();
        vm.startPrank(users.depositor2);

        // It should revert.
        expectRevert_CallerNotDepositor(abi.encodeCall(bob.exitWithinGracePeriod, (vaultId)), vaultId, users.depositor2);
    }

    function test_RevertWhen_GracePeriodExpired()
        external
        givenNotNullVault
        givenVaultActive
        whenCallerHasShares
        whenCallerIsOriginalDepositor
    {
        uint256 vaultId = vaultIds.defaultVault;
        uint128 amount = DEPOSIT_AMOUNT;

        // Make a deposit.
        bob.enter(vaultId, amount);
        uint40 depositedAt = uint40(block.timestamp);
        uint40 gracePeriodEnd = depositedAt + 4 hours;

        // Warp past the grace period.
        vm.warp(gracePeriodEnd + 1);

        // It should revert.
        expectRevert_GracePeriodExpired(
            abi.encodeCall(bob.exitWithinGracePeriod, (vaultId)), vaultId, users.depositor, depositedAt, gracePeriodEnd
        );
    }

    function test_GivenVaultHasNoAdapter()
        external
        givenNotNullVault
        givenVaultActive
        whenCallerHasShares
        whenCallerIsOriginalDepositor
        whenWithinGracePeriod
    {
        // It should exit and return tokens.
        uint256 vaultId = vaultIds.defaultVault;
        uint128 amount = DEPOSIT_AMOUNT;

        // Make a deposit.
        bob.enter(vaultId, amount);

        // Get state before exit.
        address shareToken = address(bob.getShareToken(vaultId));
        uint256 daiBalanceBefore = dai.balanceOf(users.depositor);

        // Warp forward but stay within grace period.
        vm.warp(block.timestamp + 2 hours);

        // Expect the ExitWithinGracePeriod event.
        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.ExitWithinGracePeriod({
            vaultId: vaultId,
            user: users.depositor,
            amountReceived: amount,
            sharesBurned: amount
        });

        // Exit within grace period.
        bob.exitWithinGracePeriod(vaultId);

        // Assert shares were burned.
        uint256 shareBalanceAfter = IERC20(shareToken).balanceOf(users.depositor);
        assertEq(shareBalanceAfter, 0, "share balance should be zero after exit");

        // Assert the deposit record was cleared.
        uint40 depositedAt = bob.getFirstDepositTime(vaultId, users.depositor);
        assertEq(depositedAt, 0, "depositedAt should be cleared");

        // Assert tokens were returned.
        uint256 daiBalanceAfter = dai.balanceOf(users.depositor);
        assertEq(daiBalanceAfter - daiBalanceBefore, amount, "tokens returned");
    }

    function test_GivenVaultHasAdapter()
        external
        givenNotNullVault
        givenVaultActive
        whenCallerHasShares
        whenCallerIsOriginalDepositor
        whenWithinGracePeriod
    {
        // It should exit via adapter unstake.
        uint256 vaultId = vaultIds.adapterVault;
        uint128 amount = WETH_DEPOSIT_AMOUNT;

        // Make a deposit.
        bob.enter(vaultId, amount);

        // Get state before exit.
        address shareToken = address(bob.getShareToken(vaultId));
        uint256 wethBalanceBefore = weth.balanceOf(users.depositor);
        uint256 shareBalanceBefore = IERC20(shareToken).balanceOf(users.depositor);

        // Warp forward but stay within grace period.
        vm.warp(block.timestamp + 2 hours);

        // Expect the ExitWithinGracePeriod event.
        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.ExitWithinGracePeriod({
            vaultId: vaultId,
            user: users.depositor,
            amountReceived: amount,
            sharesBurned: amount
        });

        // Exit within grace period.
        bob.exitWithinGracePeriod(vaultId);

        // Assert shares were burned.
        uint256 shareBalanceAfter = IERC20(shareToken).balanceOf(users.depositor);
        assertEq(shareBalanceBefore - shareBalanceAfter, amount, "shares burned");

        // Assert WETH was returned to the user (minus Curve slippage).
        // Curve slippage is 10 bps (0.1%), so user gets back ~99.9% of deposited amount.
        uint256 wethBalanceAfter = weth.balanceOf(users.depositor);
        uint256 wethReturned = wethBalanceAfter - wethBalanceBefore;
        uint256 minExpected = (amount * 9980) / 10_000; // 99.8% minimum (accounts for slippage)
        assertGe(wethReturned, minExpected, "WETH returned should be close to deposited amount");
        assertLe(wethReturned, amount, "WETH returned should not exceed deposited amount");

        // Assert adapter tracking was cleared.
        assertEq(adapter.getYieldBearingTokenBalanceFor(vaultId, users.depositor), 0, "adapter wstETH cleared");
    }
}
