// solhint-disable max-line-length
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__CreateWithDuration__CliffDurationCalculationOverflows is SablierV2LinearUnitTest {
    /// @dev it should revert due to the start time being greater than the stop time.
    function testCannotCreateWithDuration__CliffDurationCalculationOverflow(uint256 cliffDuration) external {
        vm.assume(cliffDuration > MAX_UINT_256 - block.timestamp);
        uint256 totalDuration = cliffDuration;
        uint256 cliffTime;
        uint256 stopTime;
        unchecked {
            cliffTime = block.timestamp + cliffDuration;
            stopTime = cliffTime;
        }
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2.SablierV2__StartTimeGreaterThanStopTime.selector,
                block.timestamp,
                stopTime
            )
        );
        sablierV2Linear.createWithDuration(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            cliffDuration,
            totalDuration,
            daiStream.cancelable
        );
    }
}

contract CliffDurationCalculationDoesNotOverflow {}

contract SablierV2Linear__CreateWithDuration__TotalDurationCalculationOverflows is
    SablierV2LinearUnitTest,
    CliffDurationCalculationDoesNotOverflow
{
    /// @dev it should revert.
    function testCannotCreateWithDuration(uint256 cliffDuration, uint256 totalDuration) external {
        vm.assume(cliffDuration <= MAX_UINT_256 - block.timestamp);
        vm.assume(totalDuration > MAX_UINT_256 - block.timestamp);
        uint256 stopTime;
        unchecked {
            stopTime = block.timestamp + totalDuration;
        }
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2.SablierV2__StartTimeGreaterThanStopTime.selector,
                block.timestamp,
                stopTime
            )
        );
        sablierV2Linear.createWithDuration(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            cliffDuration,
            totalDuration,
            daiStream.cancelable
        );
    }
}

contract TotalDurationCalculationDoesNotOverflow {}

contract SablierV2Linear__CreateWithDuration is
    SablierV2LinearUnitTest,
    CliffDurationCalculationDoesNotOverflow,
    TotalDurationCalculationDoesNotOverflow
{
    /// @dev it should create the stream with duration.
    function testCreateWithDuration(uint256 cliffDuration, uint256 totalDuration) external {
        vm.assume(cliffDuration <= totalDuration);
        vm.assume(totalDuration <= MAX_UINT_256 - block.timestamp);
        uint256 cliffTime;
        uint256 stopTime;
        unchecked {
            cliffTime = block.timestamp + cliffDuration;
            stopTime = block.timestamp + totalDuration;
        }
        uint256 daiStreamId = sablierV2Linear.createWithDuration(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            cliffDuration,
            totalDuration,
            daiStream.cancelable
        );
        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(daiStreamId);
        assertEq(actualStream.sender, daiStream.sender);
        assertEq(actualStream.recipient, daiStream.recipient);
        assertEq(actualStream.depositAmount, daiStream.depositAmount);
        assertEq(actualStream.token, daiStream.token);
        assertEq(actualStream.startTime, daiStream.startTime);
        assertEq(actualStream.cliffTime, cliffTime);
        assertEq(actualStream.stopTime, stopTime);
        assertEq(actualStream.cancelable, daiStream.cancelable);
        assertEq(actualStream.withdrawnAmount, daiStream.withdrawnAmount);
    }
}
