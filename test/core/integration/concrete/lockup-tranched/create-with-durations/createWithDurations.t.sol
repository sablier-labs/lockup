// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierLockupTranched } from "src/core/interfaces/ISablierLockupTranched.sol";
import { Errors } from "src/core/libraries/Errors.sol";
import { Lockup, LockupTranched } from "src/core/types/DataTypes.sol";

import { CreateWithDurations_Integration_Shared_Test } from "../../../shared/lockup/createWithDurations.t.sol";
import { LockupTranched_Integration_Concrete_Test } from "../LockupTranched.t.sol";

contract CreateWithDurations_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Concrete_Test,
    CreateWithDurations_Integration_Shared_Test
{
    function setUp()
        public
        virtual
        override(LockupTranched_Integration_Concrete_Test, CreateWithDurations_Integration_Shared_Test)
    {
        LockupTranched_Integration_Concrete_Test.setUp();
        CreateWithDurations_Integration_Shared_Test.setUp();
        streamId = lockupTranched.nextStreamId();
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData =
            abi.encodeCall(ISablierLockupTranched.createWithDurations, defaults.createWithDurationsLT());
        (bool success, bytes memory returnData) = address(lockupTranched).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    function test_RevertWhen_TrancheCountExceedsMaxValue() external whenNoDelegateCall {
        LockupTranched.TrancheWithDuration[] memory tranches = new LockupTranched.TrancheWithDuration[](25_000);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockupTranched_TrancheCountTooHigh.selector, 25_000));
        createDefaultStreamWithDurations(tranches);
    }

    function test_RevertWhen_FirstIndexHasZeroDuration()
        external
        whenNoDelegateCall
        whenTrancheCountNotExceedMaxValue
    {
        uint40 startTime = getBlockTimestamp();
        LockupTranched.TrancheWithDuration[] memory tranches = defaults.createWithDurationsLT().tranches;
        tranches[2].duration = 0;
        uint256 index = 2;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockupTranched_TrancheTimestampsNotOrdered.selector,
                index,
                startTime + tranches[0].duration + tranches[1].duration,
                startTime + tranches[0].duration + tranches[1].duration
            )
        );
        createDefaultStreamWithDurations(tranches);
    }

    function test_RevertWhen_StartTimeExceedsFirstTimestamp()
        external
        whenNoDelegateCall
        whenTrancheCountNotExceedMaxValue
        whenFirstIndexHasNonZeroDuration
        whenTimestampsCalculationOverflows
    {
        unchecked {
            uint40 startTime = getBlockTimestamp();
            LockupTranched.TrancheWithDuration[] memory tranches = defaults.tranchesWithDurations();
            tranches[0].duration = MAX_UINT40;
            vm.expectRevert(
                abi.encodeWithSelector(
                    Errors.SablierLockupTranched_StartTimeNotLessThanFirstTrancheTimestamp.selector,
                    startTime,
                    startTime + tranches[0].duration
                )
            );
            createDefaultStreamWithDurations(tranches);
        }
    }

    function test_RevertWhen_TimestampsNotStrictlyIncreasing()
        external
        whenNoDelegateCall
        whenTrancheCountNotExceedMaxValue
        whenFirstIndexHasNonZeroDuration
        whenTimestampsCalculationOverflows
        whenStartTimeNotExceedsFirstTimestamp
    {
        unchecked {
            uint40 startTime = getBlockTimestamp();

            // Create new tranches that overflow when the timestamps are eventually calculated.
            LockupTranched.TrancheWithDuration[] memory tranches = new LockupTranched.TrancheWithDuration[](2);
            tranches[0] = LockupTranched.TrancheWithDuration({ amount: 0, duration: startTime + 1 seconds });
            tranches[1] = defaults.tranchesWithDurations()[0];
            tranches[1].duration = MAX_UINT40;

            // Expect the relevant error to be thrown.
            uint256 index = 1;
            vm.expectRevert(
                abi.encodeWithSelector(
                    Errors.SablierLockupTranched_TrancheTimestampsNotOrdered.selector,
                    index,
                    startTime + tranches[0].duration,
                    startTime + tranches[0].duration + tranches[1].duration
                )
            );

            // Create the stream.
            createDefaultStreamWithDurations(tranches);
        }
    }

    function test_WhenTimestampsCalculationNotOverflow()
        external
        whenNoDelegateCall
        whenTrancheCountNotExceedMaxValue
        whenFirstIndexHasNonZeroDuration
    {
        // Make the Sender the stream's funder
        address funder = users.sender;

        // Declare the timestamps.
        uint40 blockTimestamp = getBlockTimestamp();
        LockupTranched.Timestamps memory timestamps =
            LockupTranched.Timestamps({ start: blockTimestamp, end: blockTimestamp + defaults.TOTAL_DURATION() });

        LockupTranched.TrancheWithDuration[] memory tranchesWithDurations = defaults.tranchesWithDurations();
        LockupTranched.Tranche[] memory tranches = defaults.tranches();
        tranches[0].timestamp = timestamps.start + tranchesWithDurations[0].duration;
        tranches[1].timestamp = tranches[0].timestamp + tranchesWithDurations[1].duration;
        tranches[2].timestamp = tranches[1].timestamp + tranchesWithDurations[2].duration;

        // It should perform the ERC-20 transfers.
        expectCallToTransferFrom({ from: funder, to: address(lockupTranched), value: defaults.DEPOSIT_AMOUNT() });

        // Expect the broker fee to be paid to the broker.
        expectCallToTransferFrom({ from: funder, to: users.broker, value: defaults.BROKER_FEE_AMOUNT() });

        // It should emit {MetadataUpdate} and {CreateLockupTranchedStream} events.
        vm.expectEmit({ emitter: address(lockupTranched) });
        emit MetadataUpdate({ _tokenId: streamId });
        vm.expectEmit({ emitter: address(lockupTranched) });
        emit CreateLockupTranchedStream({
            streamId: streamId,
            funder: funder,
            sender: users.sender,
            recipient: users.recipient,
            amounts: defaults.lockupCreateAmounts(),
            asset: dai,
            cancelable: true,
            transferable: true,
            tranches: tranches,
            timestamps: timestamps,
            broker: users.broker
        });

        // Create the stream.
        createDefaultStreamWithDurations();

        // It should create the stream.
        LockupTranched.StreamLT memory actualStream = lockupTranched.getStream(streamId);
        LockupTranched.StreamLT memory expectedStream = defaults.lockupTranchedStream();
        expectedStream.endTime = timestamps.end;
        expectedStream.startTime = timestamps.start;
        expectedStream.tranches = tranches;
        assertEq(actualStream, expectedStream);

        // Assert that the stream's status is "STREAMING".
        Lockup.Status actualStatus = lockupTranched.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);

        // It should bump the next stream ID.
        uint256 actualNextStreamId = lockupTranched.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId, "nextStreamId");

        // It should mint the NFT.
        address actualNFTOwner = lockupTranched.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
