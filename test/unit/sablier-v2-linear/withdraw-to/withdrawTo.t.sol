// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__UnitTest__WithdrawTo is SablierV2LinearUnitTest {
    uint256 internal streamId;
    address internal to;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        streamId = createDefaultStream();

        // Make the recipient the `msg.sender` in this test suite.
        changePrank(users.recipient);

        to = users.alice;
    }

    /// @dev When the stream does not exist, it should revert.
    function testCannotWithdrawTo__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonExistent.selector, nonStreamId));
        uint256 withdrawAmount = 0;
        sablierV2Linear.withdrawTo(nonStreamId, to, withdrawAmount);
    }

    /// @dev When the to address is zero, it should revert.
    function testCannotWithdrawTo__ZeroAddress() external {
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__WithdrawZeroAddress.selector));
        address zero = address(0);
        uint256 withdrawAmount = 0;
        sablierV2Linear.withdrawTo(streamId, zero, withdrawAmount);
    }

    /// @dev When the caller is the sender, it should revert.
    function testCannotWithdrawTo__CallerSender() external {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.sender);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, streamId, users.sender));
        uint256 withdrawAmount = 0;
        sablierV2Linear.withdrawTo(streamId, to, withdrawAmount);
    }

    /// @dev When the caller is an unauthorized third-party, it should revert.
    function testCannotWithdrawTo__CallerUnauthorized() external {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, streamId, users.eve));
        uint256 withdrawAmount = 0;
        sablierV2Linear.withdrawTo(streamId, to, withdrawAmount);
    }

    /// @dev When the withdraw amount is zero, it should revert.
    function testCannotWithdrawTo__WithdrawAmountZero() external {
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__WithdrawAmountZero.selector, streamId));
        uint256 withdrawAmount = 0;
        sablierV2Linear.withdrawTo(streamId, to, withdrawAmount);
    }

    /// @dev When the amount is greater than the withdrawable amount, it should revert.
    function testCannotWithdrawTo__WithdrawAmountGreaterThanWithdrawableAmount() external {
        uint256 withdrawAmount = type(uint256).max;
        uint256 withdrawableAmount = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2.SablierV2__WithdrawAmountGreaterThanWithdrawableAmount.selector,
                streamId,
                withdrawAmount,
                withdrawableAmount
            )
        );
        sablierV2Linear.withdrawTo(streamId, to, withdrawAmount);
    }

    /// @dev When the to address is the recipient, it should make the withdrawal.
    function testWithdrawTo__Recipient() external {
        // Warp to 100 seconds after the start time (1% of the default stream duration).
        vm.warp(stream.startTime + TIME_OFFSET);

        // Run the test.
        address toRecipient = stream.recipient;
        sablierV2Linear.withdrawTo(streamId, toRecipient, WITHDRAW_AMOUNT);
    }

    /// @dev When the stream ended, it should withdraw everything.
    function testWithdrawTo__ThirdParty__StreamEnded() external {
        // Warp to the end of the stream.
        vm.warp(stream.stopTime);

        // Run the test.
        uint256 withdrawAmount = stream.depositAmount;
        sablierV2Linear.withdrawTo(streamId, to, withdrawAmount);
    }

    /// @dev When the stream ended, it should delete the stream.
    function testWithdrawTo__ThirdParty__StreamEnded__DeleteStream() external {
        // Warp to the end of the stream.
        vm.warp(stream.stopTime);

        // Run the test.
        uint256 withdrawAmount = stream.depositAmount;
        sablierV2Linear.withdrawTo(streamId, to, withdrawAmount);
        ISablierV2Linear.Stream memory deletedStream = sablierV2Linear.getStream(streamId);
        ISablierV2Linear.Stream memory expectedStream;
        assertEq(deletedStream, expectedStream);
    }

    /// @dev When the stream ended, it should emit a Withdraw event.
    function testWithdrawTo__ThirdParty__StreamEnded__Event() external {
        // Warp to the end of the stream.
        vm.warp(stream.stopTime);

        // Run the test.
        vm.expectEmit(true, true, false, true);
        uint256 withdrawAmount = stream.depositAmount;
        emit Withdraw(streamId, to, withdrawAmount);
        sablierV2Linear.withdrawTo(streamId, to, withdrawAmount);
    }

    /// @dev When the stream is ongoing, it should make the withdrawal.
    function testWithdrawTo__ThirdParty__StreamOngoing() external {
        // Warp to 100 seconds after the start time (1% of the default stream duration).
        vm.warp(stream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Linear.withdrawTo(streamId, to, WITHDRAW_AMOUNT);
    }

    /// @dev When the stream is ongoing, it should update the withdrawn amount.
    function testWithdrawTo__ThirdParty__StreamOngoing__UpdateWithdrawnAmount() external {
        // Warp to 100 seconds after the start time (1% of the default stream duration).
        vm.warp(stream.startTime + TIME_OFFSET);

        // Run the test.
        uint256 withdrawnAmount = WITHDRAW_AMOUNT;
        sablierV2Linear.withdrawTo(streamId, to, withdrawnAmount);
        ISablierV2Linear.Stream memory queriedStream = sablierV2Linear.getStream(streamId);
        uint256 actualWithdrawnAmount = queriedStream.withdrawnAmount;
        uint256 expectedWithdrawnAmount = stream.withdrawnAmount + withdrawnAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    /// @dev When the stream is ongoing, it should emit a Withdraw event.
    function testWithdrawTo__ThirdParty__StreamOngoing__Event() external {
        // Warp to 100 seconds after the start time (1% of the default stream duration).
        vm.warp(stream.startTime + TIME_OFFSET);

        // Run the test.
        uint256 withdrawAmount = WITHDRAW_AMOUNT;
        vm.expectEmit(true, true, false, true);
        emit Withdraw(streamId, to, withdrawAmount);
        sablierV2Linear.withdrawTo(streamId, to, withdrawAmount);
    }
}
