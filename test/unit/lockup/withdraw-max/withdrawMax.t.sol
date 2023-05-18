// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Lockup } from "src/types/Lockup.sol";

import { WithdrawMax_Shared_Test } from "../../../shared/lockup/withdraw-max/withdrawMax.t.sol";
import { Unit_Test } from "../../Unit.t.sol";

abstract contract WithdrawMax_Unit_Test is Unit_Test, WithdrawMax_Shared_Test {
    function setUp() public virtual override(Unit_Test, WithdrawMax_Shared_Test) {
        WithdrawMax_Shared_Test.setUp();
    }

    function test_WithdrawMax_EndTimeNotInTheFuture() external {
        // Warp to the stream's end.
        vm.warp({ timestamp: defaults.END_TIME() + 1 seconds });

        // Expect the ERC-20 assets to be transferred to the recipient.
        expectCallToTransfer({ to: users.recipient, amount: defaults.DEPOSIT_AMOUNT() });

        // Expect a {WithdrawFromLockupStream} event to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({
            streamId: defaultStreamId,
            to: users.recipient,
            amount: defaults.DEPOSIT_AMOUNT()
        });

        // Make the max withdrawal.
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = defaults.DEPOSIT_AMOUNT();
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");

        // Assert that the stream's status is "DEPLETED".
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.DEPLETED;
        assertEq(actualStatus, expectedStatus);

        // Assert that the stream is not cancelable anymore.
        bool isCancelable = lockup.isCancelable(defaultStreamId);
        assertFalse(isCancelable, "isCancelable");

        // Assert that the NFT has not been burned.
        address actualNFTowner = lockup.ownerOf({ tokenId: defaultStreamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTowner, expectedNFTOwner, "NFT owner");
    }

    function test_WithdrawMax() external whenEndTimeInTheFuture {
        // Simulate the passage of time.
        vm.warp({ timestamp: defaults.WARP_26_PERCENT() });

        // Get the withdraw amount.
        uint128 withdrawAmount = lockup.withdrawableAmountOf(defaultStreamId);

        // Expect the assets to be transferred to the recipient.
        expectCallToTransfer({ to: users.recipient, amount: withdrawAmount });

        // Expect a {WithdrawFromLockupStream} event to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });

        // Make the max withdrawal.
        lockup.withdrawMax(defaultStreamId, users.recipient);

        // Assert that the stream's status is still "STREAMING".
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }
}
