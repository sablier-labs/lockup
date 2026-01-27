// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";
import { ISablierLidoAdapter } from "src/interfaces/ISablierLidoAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

/// @title Adapter_Integration_Concrete_Test
/// @notice Tests for SablierLidoAdapter that are not covered by other tests.
contract Adapter_Integration_Concrete_Test is Integration_Test {
    /*//////////////////////////////////////////////////////////////////////////
                            ONLY_SABLIER_BOB MODIFIER
    //////////////////////////////////////////////////////////////////////////*/

    function test_RevertWhen_StakeCalledDirectly() external {
        // Calling stake directly on adapter (not through SablierBob) should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLidoAdapter_OnlySablierBob.selector, users.depositor, address(bob))
        );
        adapter.stake(1, users.depositor, 1 ether);
    }

    function test_RevertWhen_UnstakeForUserWithinGracePeriodCalledDirectly() external {
        // Calling unstakeForUserWithinGracePeriod directly should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLidoAdapter_OnlySablierBob.selector, users.depositor, address(bob))
        );
        adapter.unstakeForUserWithinGracePeriod(1, users.depositor);
    }

    function test_RevertWhen_UnstakeAllCalledDirectly() external {
        // Calling unstakeFullAmount directly should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLidoAdapter_OnlySablierBob.selector, users.depositor, address(bob))
        );
        adapter.unstakeFullAmount(1);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                CALCULATE REDEMPTION
    //////////////////////////////////////////////////////////////////////////*/

    function test_CalculateRedemption_NoWstETH() external view {
        // For a vault with no wstETH deposits, should return zero.
        uint256 vaultId = vaultIds.defaultVault; // This vault has no adapter.
        (uint256 wethAmount, uint256 feeAmount) =
            adapter.calculateAmountToTransferWithYield(vaultId, users.depositor, 100e18);

        // When totalWstETH == 0, it returns (0, 0).
        assertEq(wethAmount, 0, "wethAmount should be zero");
        assertEq(feeAmount, 0, "feeAmount should be zero");
    }

    function test_CalculateRedemption_BeforeUnstake() external {
        // Before unstaking, _vaultWethReceived is 0, so should return zero.
        uint256 vaultId = createVaultWithAdapter();
        uint128 amount = WETH_DEPOSIT_AMOUNT;
        bob.enter(vaultId, amount);

        // Vault has wstETH but not yet unstaked (totalWeth == 0).
        (uint256 wethAmount, uint256 feeAmount) =
            adapter.calculateAmountToTransferWithYield(vaultId, users.depositor, amount);

        // totalWeth == 0 triggers early return with (0, 0).
        assertEq(wethAmount, 0, "wethAmount should be zero");
        assertEq(feeAmount, 0, "feeAmount should be zero");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                ERC165 INTERFACE
    //////////////////////////////////////////////////////////////////////////*/

    function test_SupportsInterface_ISablierBobAdapter() external view {
        bool supported = adapter.supportsInterface(type(ISablierBobAdapter).interfaceId);
        assertTrue(supported, "should support ISablierBobAdapter interface");
    }

    function test_SupportsInterface_ISablierLidoAdapter() external view {
        bool supported = adapter.supportsInterface(type(ISablierLidoAdapter).interfaceId);
        assertTrue(supported, "should support ISablierLidoAdapter interface");
    }

    function test_SupportsInterface_IERC165() external view {
        bytes4 ierc165InterfaceId = 0x01ffc9a7;
        bool supported = adapter.supportsInterface(ierc165InterfaceId);
        assertTrue(supported, "should support IERC165 interface");
    }

    function test_SupportsInterface_InvalidInterface() external view {
        bytes4 randomInterfaceId = 0xdeadbeef;
        bool supported = adapter.supportsInterface(randomInterfaceId);
        assertFalse(supported, "should not support random interface");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   GET VAULT YIELD FEE
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetVaultYieldFee_ReturnsSnapshotedFee() external {
        // Create a vault with adapter (fee is snapshotted at creation time).
        uint256 vaultId = createVaultWithAdapter();

        // Verify the fee was snapshotted correctly.
        assertEq(adapter.getVaultYieldFee(vaultId).unwrap(), DEFAULT_YIELD_FEE.unwrap(), "vault yield fee");
    }

    function test_GetVaultYieldFee_ImmutableAfterCreation() external {
        // Create a vault with adapter (fee is snapshotted at creation time).
        uint256 vaultId = createVaultWithAdapter();

        // Record the initial vault yield fee.
        uint256 initialVaultFee = adapter.getVaultYieldFee(vaultId).unwrap();

        // Change the global yield fee via comptroller.
        setMsgSender(address(comptroller));
        adapter.setYieldFee(MAX_YIELD_FEE); // Set to maximum (20%)
        setMsgSender(users.depositor);

        // Verify the vault's snapshotted fee is unchanged.
        assertEq(adapter.getVaultYieldFee(vaultId).unwrap(), initialVaultFee, "vault fee should be unchanged");

        // Verify the global fee did change.
        assertEq(adapter.feeOnYield().unwrap(), MAX_YIELD_FEE.unwrap(), "global fee should have changed");
    }

    /*//////////////////////////////////////////////////////////////////////////
                              ON SHARE TRANSFER DIRECT CALL
    //////////////////////////////////////////////////////////////////////////*/

    function test_RevertWhen_OnShareTransferCalledDirectly() external {
        // Create a vault (with or without adapter).
        uint256 vaultId = vaultIds.defaultVault;

        // Attempt to call onShareTransfer directly (not through the share token).
        // This should revert because msg.sender is not the share token.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierBob_CallerNotShareToken.selector, vaultId, users.depositor)
        );
        bob.onShareTransfer(vaultId, users.depositor, users.depositor2, 100e18, 200e18);
    }

    function test_RevertWhen_OnShareTransferCalledByWrongShareToken() external {
        // Create two vaults.
        uint256 vaultId1 = createDefaultVault();
        uint256 vaultId2 = createDefaultVault();

        // Get the share token for vault2 (we do not need vault1's share token for this test).
        address shareToken2 = address(bob.getShareToken(vaultId2));

        // Attempt to call onShareTransfer for vault1 using vault2's share token as the caller.
        // This should revert because the caller is not the share token for vault1.
        setMsgSender(shareToken2);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierBob_CallerNotShareToken.selector, vaultId1, shareToken2));
        bob.onShareTransfer(vaultId1, users.depositor, users.depositor2, 100e18, 200e18);
    }

    /*//////////////////////////////////////////////////////////////////////////
                             SHARE TRANSFER WSTETH TRACKING
    //////////////////////////////////////////////////////////////////////////*/

    function test_ShareTransfer_UpdatesWstETHAttribution() external {
        // Create vault with adapter and deposit.
        uint256 vaultId = createVaultWithAdapter();
        uint128 amount = WETH_DEPOSIT_AMOUNT;
        bob.enter(vaultId, amount);

        // Get the share token.
        IERC20 shareToken = IERC20(address(bob.getShareToken(vaultId)));

        // User A (depositor) has all wstETH.
        uint256 userAWstETH = adapter.getYieldBearingTokenBalanceFor(vaultId, users.depositor);
        assertGt(userAWstETH, 0, "user A should have wstETH");

        // User B (depositor2) has no wstETH.
        uint256 userBWstETH = adapter.getYieldBearingTokenBalanceFor(vaultId, users.depositor2);
        assertEq(userBWstETH, 0, "user B should have no wstETH initially");

        // Transfer half the shares from user A to user B.
        uint256 transferAmount = amount / 2;
        shareToken.transfer(users.depositor2, transferAmount);

        // Verify wstETH attribution moved proportionally.
        uint256 expectedTransferredWstETH = userAWstETH / 2;
        uint256 userAWstETHAfter = adapter.getYieldBearingTokenBalanceFor(vaultId, users.depositor);
        uint256 userBWstETHAfter = adapter.getYieldBearingTokenBalanceFor(vaultId, users.depositor2);

        // Allow 1 wei rounding error.
        assertApproxEqAbs(userAWstETHAfter, userAWstETH - expectedTransferredWstETH, 1, "user A wstETH reduced");
        assertApproxEqAbs(userBWstETHAfter, expectedTransferredWstETH, 1, "user B received wstETH");

        // Total wstETH should remain the same.
        assertEq(userAWstETHAfter + userBWstETHAfter, userAWstETH, "total wstETH unchanged");
    }

    function test_ShareTransfer_NoAdapter_NoOp() external {
        // Use the default vault (no adapter).
        uint256 vaultId = vaultIds.defaultVault;
        uint128 amount = DEPOSIT_AMOUNT;
        bob.enter(vaultId, amount);

        // Get the share token.
        IERC20 shareToken = IERC20(address(bob.getShareToken(vaultId)));

        // Transfer should succeed without reverting (no adapter, so no wstETH to track).
        uint256 transferAmount = amount / 2;
        shareToken.transfer(users.depositor2, transferAmount);

        // Verify the shares moved.
        assertEq(shareToken.balanceOf(users.depositor), amount - transferAmount, "depositor balance");
        assertEq(shareToken.balanceOf(users.depositor2), transferAmount, "depositor2 balance");
    }
}
