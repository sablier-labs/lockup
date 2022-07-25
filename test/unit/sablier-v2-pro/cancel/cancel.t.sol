// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Pro } from "@sablier/v2-core/interfaces/ISablierV2Pro.sol";

import { SablierV2ProUnitTest } from "../SablierV2ProUnitTest.t.sol";

contract SablierV2Pro__Cancel is SablierV2ProUnitTest {
    uint256 internal daiStreamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        daiStreamId = createDefaultDaiStream();
    }

    /// @dev it should revert.
    function testCannotCancel__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonExistent.selector, nonStreamId));
        sablierV2Pro.cancel(nonStreamId);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should revert.
    function testCannotCancel__CallerNotRecipient() external StreamExistent {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, daiStreamId, users.eve));
        sablierV2Pro.cancel(daiStreamId);
    }

    modifier CallerAuthorized() {
        _;
    }

    /// @dev it should cancel and delete the stream.
    function testCancel__CallerRecipient() external StreamExistent CallerAuthorized {
        // Make the recipient the `msg.sender` in this test case.
        changePrank(users.recipient);

        // Run the test.
        sablierV2Pro.cancel(daiStreamId);
        ISablierV2Pro.Stream memory deletedStream = sablierV2Pro.getStream(daiStreamId);
        ISablierV2Pro.Stream memory expectedStream;
        assertEq(deletedStream, expectedStream);
    }

    modifier CallerSender() {
        _;
    }

    /// @dev it should revert.
    function testCannotCancel__StreamNonCancelable() external StreamExistent CallerAuthorized CallerSender {
        // Create the non-cancelable stream.
        uint256 nonCancelableDaiStreamId = createNonCancelableDaiStream();

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonCancelable.selector, nonCancelableDaiStreamId)
        );
        sablierV2Pro.cancel(nonCancelableDaiStreamId);
    }

    modifier StreamCancelable() {
        _;
    }

    /// @dev it should cancel and delete the stream.
    function testCancel__StreamEnded() external StreamExistent CallerAuthorized CallerSender StreamCancelable {
        // Warp to the end of the stream.
        vm.warp(daiStream.stopTime);

        // Run the test.
        sablierV2Pro.cancel(daiStreamId);
        ISablierV2Pro.Stream memory deletedStream = sablierV2Pro.getStream(daiStreamId);
        ISablierV2Pro.Stream memory expectedStream;
        assertEq(deletedStream, expectedStream);
    }

    /// @dev it should emit a Cancel event.
    function testCancel__StreamEnded__Event() external StreamExistent CallerAuthorized CallerSender StreamCancelable {
        // Warp to the end of the stream.
        vm.warp(daiStream.stopTime);

        // Run the test.
        vm.expectEmit(true, true, false, true);
        uint256 withdrawAmount = daiStream.depositAmount;
        uint256 returnAmount = 0;
        emit Cancel(daiStreamId, daiStream.recipient, withdrawAmount, returnAmount);
        sablierV2Pro.cancel(daiStreamId);
    }

    /// @dev it should cancel and delete the stream.
    function testCancel__StreamOngoing() external StreamExistent CallerAuthorized CallerSender StreamCancelable {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Pro.cancel(daiStreamId);
        ISablierV2Pro.Stream memory deletedStream = sablierV2Pro.getStream(daiStreamId);
        ISablierV2Pro.Stream memory expectedStream;
        assertEq(deletedStream, expectedStream);
    }

    /// @dev it should emit a Cancel event.
    function testCancel__StreamOngoing__Event() external StreamExistent CallerAuthorized CallerSender StreamCancelable {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        uint256 withdrawAmount = SEGMENT_AMOUNTS_DAI[0];
        uint256 returnAmount = daiStream.depositAmount - SEGMENT_AMOUNTS_DAI[0];
        vm.expectEmit(true, true, false, true);
        emit Cancel(daiStreamId, daiStream.recipient, withdrawAmount, returnAmount);
        sablierV2Pro.cancel(daiStreamId);
    }
}
