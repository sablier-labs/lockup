// solhint-disable max-line-length
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__Withdraw is SablierV2LinearUnitTest {
    uint256 internal daiStreamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        daiStreamId = createDefaultDaiStream();

        // Make the recipient the `msg.sender` in this test suite.
        changePrank(users.recipient);
    }
}

contract SablierV2Linear__Withdraw__StreamNonExistent is SablierV2Linear__Withdraw {
    /// @dev it should revert.
    function testCannotWithdraw() external {
        uint256 nonStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonExistent.selector, nonStreamId));
        uint256 withdrawAmount = 0;
        sablierV2Linear.withdraw(nonStreamId, withdrawAmount);
    }
}

contract StreamExistent {}

contract SablierV2Linear__Withdraw__CallerUnauthorized is SablierV2Linear__Withdraw, StreamExistent {
    /// @dev it should revert.
    function testCannotWithdraw__CallerUnauthorized() external {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, daiStreamId, users.eve));
        uint256 withdrawAmount = 0;
        sablierV2Linear.withdraw(daiStreamId, withdrawAmount);
    }
}

contract SablierV2Linear__Withdraw__CallerSender is SablierV2Linear__Withdraw, StreamExistent {
    /// @dev it should make the withdrawal.
    function testWithdraw() external {
        // Make the sender the `msg.sender` in this test case.
        changePrank(users.sender);

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);
        uint256 withdrawAmount = WITHDRAW_AMOUNT_DAI;

        // Run the test.
        sablierV2Linear.withdraw(daiStreamId, withdrawAmount);
    }
}

contract CallerRecipient {}

contract SablierV2Linear__Withdraw__StreamExistent__WithdrawAmountZero is
    SablierV2Linear__Withdraw,
    StreamExistent,
    CallerRecipient
{
    /// @dev it should revert.
    function testCannotWithdraw__WithdrawAmountZero() external {
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__WithdrawAmountZero.selector, daiStreamId));
        uint256 withdrawAmount = 0;
        sablierV2Linear.withdraw(daiStreamId, withdrawAmount);
    }
}

contract WithdrawAmountNotZero {}

contract SablierV2Linear__Withdraw__WithdrawAmountGreaterThanWithdrawableAmount is
    SablierV2Linear__Withdraw,
    StreamExistent,
    CallerRecipient,
    WithdrawAmountNotZero
{
    /// @dev it should revert.
    function testCannotWithdraw__WithdrawAmountGreaterThanWithdrawableAmount() external {
        uint256 withdrawAmountMaxUint256 = MAX_UINT_256;
        uint256 withdrawableAmount = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2.SablierV2__WithdrawAmountGreaterThanWithdrawableAmount.selector,
                daiStreamId,
                withdrawAmountMaxUint256,
                withdrawableAmount
            )
        );
        sablierV2Linear.withdraw(daiStreamId, withdrawAmountMaxUint256);
    }
}

contract WithdrawAmountLessThanOrEqualToWithdrawableAmount {}

contract SablierV2Linear__Withdraw__StreamEnded is
    SablierV2Linear__Withdraw,
    StreamExistent,
    CallerRecipient,
    WithdrawAmountNotZero,
    WithdrawAmountLessThanOrEqualToWithdrawableAmount
{
    /// @dev it should cancel and delete the stream.
    function testWithdraw() external {
        // Warp to the end of the stream.
        vm.warp(daiStream.stopTime);

        // Run the test.
        uint256 withdrawAmount = daiStream.depositAmount;
        sablierV2Linear.withdraw(daiStreamId, withdrawAmount);
        ISablierV2Linear.Stream memory deletedStream = sablierV2Linear.getStream(daiStreamId);
        ISablierV2Linear.Stream memory expectedStream;
        assertEq(deletedStream, expectedStream);
    }

    /// @dev it should emit a Withdraw event.
    function testWithdraw__Event() external {
        // Warp to the end of the stream.
        vm.warp(daiStream.stopTime);

        // Run the test.
        vm.expectEmit(true, true, false, true);
        uint256 withdrawAmount = daiStream.depositAmount;
        emit Withdraw(daiStreamId, daiStream.recipient, withdrawAmount);
        sablierV2Linear.withdraw(daiStreamId, withdrawAmount);
    }
}

contract SablierV2Linear__Withdraw__StreamOngoing is
    SablierV2Linear__Withdraw,
    StreamExistent,
    CallerRecipient,
    WithdrawAmountNotZero,
    WithdrawAmountLessThanOrEqualToWithdrawableAmount
{
    /// @dev it should make the withdrawal and update the withdrawn amount.
    function testWithdraw() external {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Linear.withdraw(daiStreamId, WITHDRAW_AMOUNT_DAI);
        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(daiStreamId);
        uint256 actualWithdrawnAmount = actualStream.withdrawnAmount;
        uint256 expectedWithdrawnAmount = WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    /// @dev it should emit a Withdraw event.
    function testWithdraw__Event() external {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        uint256 withdrawAmount = WITHDRAW_AMOUNT_DAI;
        vm.expectEmit(true, true, false, true);
        emit Withdraw(daiStreamId, daiStream.recipient, withdrawAmount);
        sablierV2Linear.withdraw(daiStreamId, withdrawAmount);
    }
}
