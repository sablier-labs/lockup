// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierV2Lockup } from "core/interfaces/ISablierV2Lockup.sol";
import { Errors } from "core/libraries/Errors.sol";

import { WithdrawMaxAndTransfer_Integration_Shared_Test } from "../../../shared/lockup/withdrawMaxAndTransfer.t.sol";
import { Integration_Test } from "../../../Integration.t.sol";

abstract contract WithdrawMaxAndTransfer_Integration_Concrete_Test is
    Integration_Test,
    WithdrawMaxAndTransfer_Integration_Shared_Test
{
    function setUp() public virtual override(Integration_Test, WithdrawMaxAndTransfer_Integration_Shared_Test) {
        WithdrawMaxAndTransfer_Integration_Shared_Test.setUp();
    }

    function test_RevertWhen_DelegateCalled() external {
        bytes memory callData = abi.encodeCall(ISablierV2Lockup.withdrawMaxAndTransfer, (defaultStreamId, users.alice));
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    function test_RevertGiven_Null() external whenNotDelegateCalled {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        lockup.withdrawMaxAndTransfer({ streamId: nullStreamId, newRecipient: users.recipient1 });
    }

    function test_RevertWhen_CallerNotCurrentRecipient() external whenNotDelegateCalled givenNotNull {
        // Make Eve the caller in this test.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamId, users.eve)
        );
        lockup.withdrawMaxAndTransfer({ streamId: defaultStreamId, newRecipient: users.eve });
    }

    function test_RevertGiven_NFTBurned() external whenNotDelegateCalled givenNotNull whenCallerCurrentRecipient {
        // Deplete the stream.
        vm.warp({ newTimestamp: defaults.END_TIME() });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient1 });

        // Burn the NFT.
        lockup.burn({ streamId: defaultStreamId });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamId, users.recipient1)
        );
        lockup.withdrawMaxAndTransfer({ streamId: defaultStreamId, newRecipient: users.alice });
    }

    function test_WithdrawMaxAndTransfer_WithdrawableAmountZero()
        external
        whenNotDelegateCalled
        givenNotNull
        whenCallerCurrentRecipient
        givenNFTNotBurned
    {
        vm.warp({ newTimestamp: defaults.END_TIME() });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient1 });
        lockup.withdrawMaxAndTransfer({ streamId: defaultStreamId, newRecipient: users.alice });
    }

    function test_RevertGiven_StreamNotTransferable()
        external
        whenNotDelegateCalled
        givenNotNull
        whenCallerCurrentRecipient
        givenNFTNotBurned
        givenWithdrawableAmountNotZero
    {
        uint256 notTransferableStreamId = createDefaultStreamNotTransferable();
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_NotTransferable.selector, notTransferableStreamId)
        );
        lockup.withdrawMaxAndTransfer({ streamId: notTransferableStreamId, newRecipient: users.recipient1 });
    }

    function test_WithdrawMaxAndTransfer()
        external
        whenNotDelegateCalled
        givenNotNull
        whenCallerCurrentRecipient
        givenNFTNotBurned
        givenWithdrawableAmountNotZero
        givenStreamTransferable
    {
        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // Get the withdraw amount.
        uint128 expectedWithdrawnAmount = lockup.withdrawableAmountOf(defaultStreamId);

        // Expect the assets to be transferred to the Recipient.
        expectCallToTransfer({ to: users.recipient1, value: expectedWithdrawnAmount });

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({
            streamId: defaultStreamId,
            to: users.recipient1,
            amount: expectedWithdrawnAmount,
            asset: dai
        });
        vm.expectEmit({ emitter: address(lockup) });
        emit MetadataUpdate({ _tokenId: defaultStreamId });
        vm.expectEmit({ emitter: address(lockup) });
        emit Transfer({ from: users.recipient1, to: users.alice, tokenId: defaultStreamId });

        // Make the max withdrawal and transfer the NFT.
        uint128 actualWithdrawnAmount =
            lockup.withdrawMaxAndTransfer({ streamId: defaultStreamId, newRecipient: users.alice });

        // Assert that the withdrawn amount has been updated.
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");

        // Assert that Alice is the new stream recipient (and NFT owner).
        address actualRecipient = lockup.getRecipient(defaultStreamId);
        address expectedRecipient = users.alice;
        assertEq(actualRecipient, expectedRecipient, "recipient");
    }
}
