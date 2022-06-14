// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Cliff } from "@sablier/v2-core/interfaces/ISablierV2Cliff.sol";

import { SablierV2CliffUnitTest } from "../SablierV2CliffUnitTest.t.sol";

contract SablierV2Cliff__Cancel__UnitTest is SablierV2CliffUnitTest {
    uint256 internal streamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        streamId = createDefaultStream();
    }

    /// @dev When the stream does not exist, it should revert.
    function testCannotCancel__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonExistent.selector, nonStreamId));
        sablierV2Cliff.cancel(nonStreamId);
    }

    /// @dev When the caller is neither the sender nor the recipient, it should revert.
    function testCannotCancel__CallerUnauthorized() external {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, streamId, users.eve));
        sablierV2Cliff.cancel(streamId);
    }

    /// @dev When caller is the recipient, it should make the withdrawal.
    function testCancel__CallerRecipient() external {
        // Make the recipient the `msg.sender` in this test case.
        changePrank(users.recipient);

        // Run the test.
        sablierV2Cliff.cancel(streamId);
    }

    /// @dev When the stream is non-cancelable, it should revert.
    function testCannotCancel__StreamNonCancelable() external {
        // Create the non-cancelable stream.
        bool cancelable = false;
        uint256 nonCancelableStreamId = sablierV2Cliff.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            stream.cliffTime,
            stream.stopTime,
            cancelable
        );

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonCancelable.selector, nonCancelableStreamId)
        );
        sablierV2Cliff.cancel(nonCancelableStreamId);
    }

    /// @dev When the stream ended, it should cancel the stream.
    function testCancel__StreamEnded() external {
        // Warp to the end of the stream.
        vm.warp(stream.stopTime);

        // Run the test.
        sablierV2Cliff.cancel(streamId);
    }

    /// @dev When the stream ended, it should delete the stream.
    function testCancel__StreamEnded__DeleteStream() external {
        // Warp to the end of the stream.
        vm.warp(stream.stopTime);

        // Run the test.
        sablierV2Cliff.cancel(streamId);
        ISablierV2Cliff.Stream memory deletedStream = sablierV2Cliff.getStream(streamId);
        ISablierV2Cliff.Stream memory expectedStream;
        assertEq(deletedStream, expectedStream);
    }

    /// @dev When the stream ended, it should emit a Cancel event.
    function testCancel__StreamEnded__Event() external {
        // Warp to the end of the stream.
        vm.warp(stream.stopTime);

        // Run the test.
        vm.expectEmit(true, true, false, true);
        uint256 withdrawAmount = stream.depositAmount;
        uint256 returnAmount = 0;
        emit Cancel(streamId, stream.recipient, withdrawAmount, returnAmount);
        sablierV2Cliff.cancel(streamId);
    }

    /// @dev When the stream is ongoing, it should cancel the stream.
    function testCancel__StreamOngoing() external {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(stream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Cliff.cancel(streamId);
    }

    /// @dev When the stream is ongoing, it should delete the stream.
    function testCancel__StreamOngoing__DeleteStream() external {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(stream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Cliff.cancel(streamId);
        ISablierV2Cliff.Stream memory deletedStream = sablierV2Cliff.getStream(streamId);
        ISablierV2Cliff.Stream memory expectedStream;
        assertEq(deletedStream, expectedStream);
    }

    /// @dev When the stream is ongoing, it should emit a Cancel event.
    function testCancel__StreamOngoing__Event() external {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(stream.startTime + TIME_OFFSET);

        // Run the test.
        uint256 withdrawAmount = WITHDRAW_AMOUNT;
        uint256 returnAmount = stream.depositAmount - WITHDRAW_AMOUNT;
        vm.expectEmit(true, true, false, true);
        emit Cancel(streamId, stream.recipient, withdrawAmount, returnAmount);
        sablierV2Cliff.cancel(streamId);
    }
}
