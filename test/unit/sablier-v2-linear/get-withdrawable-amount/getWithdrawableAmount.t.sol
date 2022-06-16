// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__UnitTest__GetWithdrawableAmount is SablierV2LinearUnitTest {
    uint256 internal streamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, all tests need it.
        streamId = createDefaultStream();
    }

    /// @dev When the stream does not exist, it should return zero.
    function testGetWithdrawableAmount__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(nonStreamId);
        uint256 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When the start time is greater than the block timestamp, it should return zero.
    function testGetWithdrawableAmount__StartTimeGreaterThanBlockTimestamp() external {
        vm.warp(stream.startTime - 1 seconds);
        uint256 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(streamId);
        uint256 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When the start time is equal to the block timestamp, it should return zero.
    function testGetWithdrawableAmount__StartTimeEqualToBlockTimestamp() external {
        uint256 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(streamId);
        uint256 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When the current time is greater than the stop time and there have been withdrawals, it should
    /// return the deposit amount minus the withdrawn amount.
    function testGetWithdrawableAmount__CurrentTimeGreaterThanStopTime__WithWithdrawals() external {
        vm.warp(stream.stopTime + 1 seconds);
        sablierV2Linear.withdraw(streamId, WITHDRAW_AMOUNT);
        uint256 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(streamId);
        uint256 expectedWithdrawableAmount = stream.depositAmount - WITHDRAW_AMOUNT;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When the current time is greater than the stop time and there have been no withdrawals, it should
    /// return the deposit amount.
    function testGetWithdrawableAmount__CurrentTimeGreaterThanStopTime__NoWithdrawals() external {
        vm.warp(stream.stopTime + 1 seconds);
        uint256 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(streamId);
        uint256 expectedWithdrawableAmount = stream.depositAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When the current time is equal to the stop time and there have been withdrawals, it should
    /// return the deposit amount minus the withdrawn amount.
    function testGetWithdrawableAmount__CurrentTimeEqualToStopTime__WithWithdrawals() external {
        vm.warp(stream.stopTime);
        sablierV2Linear.withdraw(streamId, WITHDRAW_AMOUNT);
        uint256 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(streamId);
        uint256 expectedWithdrawableAmount = stream.depositAmount - WITHDRAW_AMOUNT;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When the current time is equal to the stop time and there have been no withdrawals, it should
    /// return the deposit amount.
    function testGetWithdrawableAmount__CurrentTimeEqualToStopTime__NoWithdrawals() external {
        vm.warp(stream.stopTime);
        uint256 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(streamId);
        uint256 expectedWithdrawableAmount = stream.depositAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When the current time is less than the stop time and there have been withdrawals, it should
    /// return the correct withdrawable amount.
    function testGetWithdrawableAmount__CurrentTimeLessThanStopTime__WithWithdrawals() external {
        vm.warp(stream.startTime + TIME_OFFSET);
        sablierV2Linear.withdraw(streamId, WITHDRAW_AMOUNT);
        uint256 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(streamId);
        uint256 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When the current time is less than the stop time and there have been no withdrawals, it should
    /// return the correct withdrawable amount.
    function testGetWithdrawableAmount__CurrentTimeLessThanStopTime__NoWithdrawals() external {
        vm.warp(stream.startTime + TIME_OFFSET);
        uint256 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(streamId);
        uint256 expectedWithdrawableAmount = WITHDRAW_AMOUNT;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }
}
