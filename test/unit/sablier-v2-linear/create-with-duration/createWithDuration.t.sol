// solhint-disable max-line-length
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__CreateWithDuration is SablierV2LinearUnitTest {
    /// @dev it should revert due to the start time being greater than the stop time.
    function testCannotCreateWithDuration__CliffDurationCalculationOverflows(uint64 cliffDuration) external {
        vm.assume(cliffDuration > UINT64_MAX - uint64(block.timestamp));
        uint64 totalDuration = cliffDuration;
        uint64 cliffTime;
        uint64 stopTime;
        unchecked {
            cliffTime = uint64(block.timestamp) + cliffDuration;
            stopTime = cliffTime;
        }
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2.SablierV2__StartTimeGreaterThanStopTime.selector,
                uint64(block.timestamp),
                stopTime
            )
        );
        sablierV2Linear.createWithDuration(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            cliffDuration,
            totalDuration,
            daiStream.cancelable
        );
    }

    modifier CliffDurationCalculationDoesNotOverflow() {
        _;
    }

    /// @dev When the total duration calculation overflows uint256, it should revert.
    function testCannotCreateWithDuration__TotalDurationCalculationOverflows(uint64 cliffDuration, uint64 totalDuration)
        external
        CliffDurationCalculationDoesNotOverflow
    {
        vm.assume(cliffDuration <= UINT64_MAX - uint64(block.timestamp));
        vm.assume(totalDuration > UINT64_MAX - uint64(block.timestamp));
        uint64 stopTime;
        unchecked {
            stopTime = uint64(block.timestamp) + totalDuration;
        }
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2.SablierV2__StartTimeGreaterThanStopTime.selector,
                uint64(block.timestamp),
                stopTime
            )
        );
        sablierV2Linear.createWithDuration(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            cliffDuration,
            totalDuration,
            daiStream.cancelable
        );
    }

    modifier TotalDurationCalculationDoesNotOverflow() {
        _;
    }

    /// @dev it should create the stream with duration.
    function testCreateWithDuration(uint64 cliffDuration, uint64 totalDuration)
        external
        CliffDurationCalculationDoesNotOverflow
        TotalDurationCalculationDoesNotOverflow
    {
        vm.assume(cliffDuration <= totalDuration);
        vm.assume(totalDuration <= UINT64_MAX - uint64(block.timestamp));
        uint64 cliffTime;
        uint64 stopTime;
        unchecked {
            cliffTime = uint64(block.timestamp) + cliffDuration;
            stopTime = uint64(block.timestamp) + totalDuration;
        }
        uint256 daiStreamId = sablierV2Linear.createWithDuration(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            cliffDuration,
            totalDuration,
            daiStream.cancelable
        );

        address actualRecipient = sablierV2Linear.getRecipient(daiStreamId);
        assertEq(actualRecipient, users.recipient);

        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(daiStreamId);
        assertEq(actualStream.sender, daiStream.sender);
        assertEq(actualStream.depositAmount, daiStream.depositAmount);
        assertEq(actualStream.token, daiStream.token);
        assertEq(actualStream.startTime, daiStream.startTime);
        assertEq(actualStream.cliffTime, cliffTime);
        assertEq(actualStream.stopTime, stopTime);
        assertEq(actualStream.cancelable, daiStream.cancelable);
        assertEq(actualStream.withdrawnAmount, daiStream.withdrawnAmount);
    }
}
