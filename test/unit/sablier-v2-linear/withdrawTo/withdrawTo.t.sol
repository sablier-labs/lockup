// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__Withdraw__UnitTest is SablierV2LinearUnitTest {
    uint256 internal streamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        streamId = createDefaultStream();

        // Make the recipient the `msg.sender` in this test suite.
        vm.stopPrank();
        vm.startPrank(users.recipient);
    }

    /// @dev When the address to receive the tokens is zero, it should revert.
    function testCannotWithdrawTo__WithdrawToZeroAddress() external {
        address to = address(0);
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__WithdrawToZeroAddress.selector));
        uint256 withdrawAmount = 0;
        sablierV2Linear.withdrawTo(streamId, withdrawAmount, to);
    }

    /// @dev When the stream does not exist, it should revert.
    function testCannotWithdraw__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonExistent.selector, nonStreamId));
        uint256 withdrawAmount = 0;
        address to = stream.recipient;
        sablierV2Linear.withdrawTo(nonStreamId, withdrawAmount, to);
    }

    /// @dev When the stream does not exist, it should revert.
    function testCannotWithdraw__Unauthorized() external {
        // Make Eve the `msg.sender` in this test case.
        vm.stopPrank();
        vm.startPrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, streamId, users.eve));
        uint256 withdrawAmount = 0;
        address to = stream.recipient;
        sablierV2Linear.withdrawTo(streamId, withdrawAmount, to);
    }

    /// @dev When the withdraw amount is zero, it should revert.
    function testCannotWithdraw__WithdrawAmountZero() public {
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__WithdrawAmountZero.selector, streamId));
        uint256 withdrawAmount = 0;
        address to = stream.recipient;
        sablierV2Linear.withdrawTo(streamId, withdrawAmount, to);
    }

    /// @dev When the amount is greater than the withdrawable amount, it should revert.
    function testCannotWithdraw__WithdrawAmountGreaterThanWithdrawableAmount() public {
        uint256 withdrawAmountMaxUint256 = type(uint256).max;
        uint256 withdrawableAmount = 0;
        address to = stream.recipient;
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2.SablierV2__WithdrawAmountGreaterThanWithdrawableAmount.selector,
                streamId,
                withdrawAmountMaxUint256,
                withdrawableAmount
            )
        );
        sablierV2Linear.withdrawTo(streamId, withdrawAmountMaxUint256, to);
    }

    /// @dev When the stream ended, it should withdraw everything.
    function testWithdraw__StreamEnded() public {
        // Warp to the end of the stream.
        vm.warp(stream.stopTime);

        // Run the test.
        uint256 withdrawAmount = stream.depositAmount;
        address to = stream.recipient;
        sablierV2Linear.withdrawTo(streamId, withdrawAmount, to);
    }

    /// @dev When the stream ended, it should delete the stream.
    function testWithdraw__StreamEnded__DeleteStream() public {
        // Warp to the end of the stream.
        vm.warp(stream.stopTime);

        // Run the test.
        uint256 withdrawAmount = stream.depositAmount;
        address to = stream.recipient;
        sablierV2Linear.withdrawTo(streamId, withdrawAmount, to);
        ISablierV2Linear.Stream memory expectedStream;
        ISablierV2Linear.Stream memory deletedStream = sablierV2Linear.getStream(streamId);
        assertEq(expectedStream, deletedStream);
    }

    /// @dev When the stream ended, it should emit a Withdraw event.
    function testWithdraw__StreamEnded__Event() public {
        // Warp to the end of the stream.
        vm.warp(stream.stopTime);

        // Run the test.
        vm.expectEmit(true, true, false, true);
        uint256 withdrawAmount = stream.depositAmount;
        address to = stream.recipient;
        emit Withdraw(streamId, to, withdrawAmount);
        sablierV2Linear.withdrawTo(streamId, withdrawAmount, to);
    }

    /// @dev When the stream is ongoing, it should make the withdrawal.
    function testWithdraw__StreamOngoing() public {
        // Warp to 100 seconds after the start time (1% of the default stream duration).
        vm.warp(stream.startTime + DEFAULT_TIME_OFFSET);

        // Run the test.
        address to = stream.recipient;
        sablierV2Linear.withdrawTo(streamId, DEFAULT_WITHDRAW_AMOUNT, to);
    }

    /// @dev When the stream is ongoing, it should update the withdrawn amount.
    function testWithdraw__StreamOngoing__UpdateWithdrawnAmount() public {
        // Warp to 100 seconds after the start time (1% of the default stream duration).
        vm.warp(stream.startTime + DEFAULT_TIME_OFFSET);

        // Run the test.
        uint256 withdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        address to = stream.recipient;
        uint256 expectedWithdrawnAmount = stream.withdrawnAmount + withdrawnAmount;
        sablierV2Linear.withdrawTo(streamId, withdrawnAmount, to);
        ISablierV2Linear.Stream memory stream = sablierV2Linear.getStream(streamId);
        uint256 actualWithdrawnAmount = stream.withdrawnAmount;
        assertEq(expectedWithdrawnAmount, actualWithdrawnAmount);
    }

    /// @dev When the stream is ongoing, it should emit a Withdraw event.
    function testWithdraw__StreamOngoing__Event() public {
        // Warp to 100 seconds after the start time (1% of the default stream duration).
        vm.warp(stream.startTime + DEFAULT_TIME_OFFSET);

        // Run the test.
        uint256 withdrawAmount = DEFAULT_WITHDRAW_AMOUNT;
        address to = stream.recipient;
        vm.expectEmit(true, true, false, true);
        emit Withdraw(streamId, to, withdrawAmount);
        sablierV2Linear.withdrawTo(streamId, withdrawAmount, to);
    }
}
