// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { ud2x18 } from "@prb/math/src/UD2x18.sol";

import { ISablierLockupDynamic } from "src/core/interfaces/ISablierLockupDynamic.sol";
import { Errors } from "src/core/libraries/Errors.sol";
import { Lockup, LockupDynamic } from "src/core/types/DataTypes.sol";

import { LockupDynamic_Integration_Shared_Test } from "../LockupDynamic.t.sol";

contract CreateWithDurations_LockupDynamic_Integration_Concrete_Test is LockupDynamic_Integration_Shared_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        LockupDynamic_Integration_Shared_Test.setUp();
        streamId = lockupDynamic.nextStreamId();
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData =
            abi.encodeCall(ISablierLockupDynamic.createWithDurations, defaults.createWithDurationsLD());
        (bool success, bytes memory returnData) = address(lockupDynamic).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    function test_RevertWhen_SegmentCountExceedsMaxValue() external whenNoDelegateCall {
        LockupDynamic.SegmentWithDuration[] memory segments = new LockupDynamic.SegmentWithDuration[](25_000);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockupDynamic_SegmentCountTooHigh.selector, 25_000));
        createDefaultStreamWithDurations(segments);
    }

    function test_RevertWhen_FirstIndexHasZeroDuration()
        external
        whenNoDelegateCall
        whenSegmentCountNotExceedMaxValue
    {
        uint40 startTime = getBlockTimestamp();
        LockupDynamic.SegmentWithDuration[] memory segments = defaults.createWithDurationsLD().segments;
        segments[1].duration = 0;
        uint256 index = 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockupDynamic_SegmentTimestampsNotOrdered.selector,
                index,
                startTime + segments[0].duration,
                startTime + segments[0].duration
            )
        );
        createDefaultStreamWithDurations(segments);
    }

    function test_RevertWhen_StartTimeExceedsFirstTimestamp()
        external
        whenNoDelegateCall
        whenSegmentCountNotExceedMaxValue
        whenFirstIndexHasNonZeroDuration
        whenTimestampsCalculationOverflows
    {
        unchecked {
            uint40 startTime = getBlockTimestamp();
            LockupDynamic.SegmentWithDuration[] memory segments = defaults.segmentsWithDurations();
            segments[0].duration = MAX_UINT40;
            vm.expectRevert(
                abi.encodeWithSelector(
                    Errors.SablierLockupDynamic_StartTimeNotLessThanFirstSegmentTimestamp.selector,
                    startTime,
                    startTime + segments[0].duration
                )
            );
            createDefaultStreamWithDurations(segments);
        }
    }

    function test_RevertWhen_TimestampsNotStrictlyIncreasing()
        external
        whenNoDelegateCall
        whenSegmentCountNotExceedMaxValue
        whenFirstIndexHasNonZeroDuration
        whenTimestampsCalculationOverflows
        whenStartTimeNotExceedsFirstTimestamp
    {
        unchecked {
            uint40 startTime = getBlockTimestamp();

            // Create new segments that overflow when the timestamps are eventually calculated.
            LockupDynamic.SegmentWithDuration[] memory segments = new LockupDynamic.SegmentWithDuration[](2);
            segments[0] = LockupDynamic.SegmentWithDuration({
                amount: 0,
                exponent: ud2x18(1e18),
                duration: startTime + 1 seconds
            });
            segments[1] = defaults.segmentsWithDurations()[0];
            segments[1].duration = MAX_UINT40;

            // Expect the relevant error to be thrown.
            uint256 index = 1;
            vm.expectRevert(
                abi.encodeWithSelector(
                    Errors.SablierLockupDynamic_SegmentTimestampsNotOrdered.selector,
                    index,
                    startTime + segments[0].duration,
                    startTime + segments[0].duration + segments[1].duration
                )
            );

            // Create the stream.
            createDefaultStreamWithDurations(segments);
        }
    }

    function test_WhenTimestampsCalculationNotOverflow()
        external
        whenNoDelegateCall
        whenSegmentCountNotExceedMaxValue
        whenFirstIndexHasNonZeroDuration
    {
        // Make the Sender the stream's funder
        address funder = users.sender;

        // Declare the timestamps.
        uint40 blockTimestamp = getBlockTimestamp();
        LockupDynamic.Timestamps memory timestamps =
            LockupDynamic.Timestamps({ start: blockTimestamp, end: blockTimestamp + defaults.TOTAL_DURATION() });

        // Adjust the segments.
        LockupDynamic.SegmentWithDuration[] memory segmentsWithDurations = defaults.segmentsWithDurations();
        LockupDynamic.Segment[] memory segments = defaults.segments();
        segments[0].timestamp = timestamps.start + segmentsWithDurations[0].duration;
        segments[1].timestamp = segments[0].timestamp + segmentsWithDurations[1].duration;

        // It should perform the ERC-20 transfers.
        expectCallToTransferFrom({ from: funder, to: address(lockupDynamic), value: defaults.DEPOSIT_AMOUNT() });

        // Expect the broker fee to be paid to the broker.
        expectCallToTransferFrom({ from: funder, to: users.broker, value: defaults.BROKER_FEE_AMOUNT() });

        // It should emit {CreateLockupDynamicStream} and {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(lockupDynamic) });
        emit IERC4906.MetadataUpdate({ _tokenId: streamId });
        vm.expectEmit({ emitter: address(lockupDynamic) });
        emit ISablierLockupDynamic.CreateLockupDynamicStream({
            streamId: streamId,
            funder: funder,
            sender: users.sender,
            recipient: users.recipient,
            amounts: defaults.lockupCreateAmounts(),
            asset: dai,
            cancelable: true,
            transferable: true,
            segments: segments,
            timestamps: timestamps,
            broker: users.broker
        });

        // Create the stream.
        createDefaultStreamWithDurations();

        // It should create the stream.
        LockupDynamic.StreamLD memory actualStream = lockupDynamic.getStream(streamId);
        LockupDynamic.StreamLD memory expectedStream = defaults.lockupDynamicStream();
        expectedStream.endTime = timestamps.end;
        expectedStream.segments = segments;
        expectedStream.startTime = timestamps.start;
        assertEq(actualStream, expectedStream);

        // Assert that the stream's status is "STREAMING".
        Lockup.Status actualStatus = lockupDynamic.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);

        // It should bump the next stream ID.
        uint256 actualNextStreamId = lockupDynamic.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId, "nextStreamId");

        // It should mint the NFT.
        address actualNFTOwner = lockupDynamic.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
