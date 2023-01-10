// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { SD1x18 } from "@prb/math/SD1x18.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";

import { Errors } from "./Errors.sol";
import { CreateAmounts, Range, Segment } from "../types/Structs.sol";

/// @title Helpers
/// @notice Library with helper functions needed across the Sablier V2 contracts.
library Helpers {
    /*//////////////////////////////////////////////////////////////////////////
                             INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks that neither fee is greater than `MAX_FEE`, and then calculates the protocol fee amount, the
    /// broker fee amount, and the net deposit amount.
    function checkAndCalculateFees(
        uint128 grossDepositAmount,
        UD60x18 protocolFee,
        UD60x18 brokerFee,
        UD60x18 maxFee
    ) internal pure returns (CreateAmounts memory amounts) {
        if (grossDepositAmount == 0) {
            return CreateAmounts(0, 0, 0);
        }

        // Checks: the protocol fee is not greater than `MAX_FEE`.
        if (protocolFee.gt(maxFee)) {
            revert Errors.SablierV2__ProtocolFeeTooHigh(protocolFee, maxFee);
        }

        // Calculate the protocol fee amount.
        amounts.protocolFee = uint128(UD60x18.unwrap(ud(grossDepositAmount).mul(protocolFee)));

        // Checks: the broker fee is not greater than `MAX_FEE`.
        if (brokerFee.gt(maxFee)) {
            revert Errors.SablierV2__BrokerFeeTooHigh(brokerFee, maxFee);
        }

        // Calculate the broker fee amount.
        amounts.brokerFee = uint128(UD60x18.unwrap(ud(grossDepositAmount).mul(brokerFee)));

        unchecked {
            // Assert that the gross deposit amount is always strictly greater than the sum of the protocol fee amount
            // and the broker fee amount.
            assert(grossDepositAmount > amounts.protocolFee + amounts.brokerFee);

            // Calculate the deposit amount (the amount net of fees).
            amounts.netDeposit = grossDepositAmount - amounts.protocolFee - amounts.brokerFee;
        }
    }

    /// @dev Checks the arguments of the `create` function in the {SablierV2Linear} contract.
    function checkCreateLinearParams(uint128 netDepositAmount, Range memory range) internal pure {
        // Checks: the net deposit amount is not zero.
        if (netDepositAmount == 0) {
            revert Errors.SablierV2__NetDepositAmountZero();
        }

        // Checks: the start time is less than or equal to the cliff time.
        if (range.start > range.cliff) {
            revert Errors.SablierV2Linear__StartTimeGreaterThanCliffTime(range.start, range.cliff);
        }

        // Checks: the cliff time is less than or equal to the stop time.
        if (range.cliff > range.stop) {
            revert Errors.SablierV2Linear__CliffTimeGreaterThanStopTime(range.cliff, range.stop);
        }
    }

    /// @dev Checks the arguments of the `create` function in the {SablierV2Pro} contract.
    function checkCreateProParams(
        uint128 netDepositAmount,
        Segment[] memory segments,
        uint256 maxSegmentCount,
        uint40 startTime
    ) internal pure {
        // Checks: the net deposit amount is not zero.
        if (netDepositAmount == 0) {
            revert Errors.SablierV2__NetDepositAmountZero();
        }

        // Check that the amount count is not zero.
        uint256 segmentCount = segments.length;
        if (segmentCount == 0) {
            revert Errors.SablierV2Pro__SegmentCountZero();
        }

        // Check that the amount count is not greater than the maximum segment count permitted.
        if (segmentCount > maxSegmentCount) {
            revert Errors.SablierV2Pro__SegmentCountTooHigh(segmentCount);
        }

        // Checks: requirements of segments variables.
        _checkProSegments(segments, segmentCount, netDepositAmount, startTime);
    }

    // @dev Checks that the segment array counts match, and then adjusts the segments by calculating the milestones.
    function checkDeltasAndAdjustSegments(Segment[] memory segments, uint40[] memory deltas) internal view {
        // Checks: check that the segment array counts match.
        uint256 deltaCount = deltas.length;
        if (segments.length != deltaCount) {
            revert Errors.SablierV2Pro__SegmentArraysNotEqual(segments.length, deltaCount);
        }

        // Make the current time the start time of the stream.
        uint40 startTime = uint40(block.timestamp);

        // Calculate the segment milestones and set them in the segments array. It is safe to use unchecked arithmetic
        // because the `_createWithMilestone` function will nonetheless check the soundness of the segment milestones.
        unchecked {
            segments[0].milestone = startTime + deltas[0];
            for (uint256 i = 1; i < deltaCount; ++i) {
                segments[i].milestone = segments[i - 1].milestone + deltas[i];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                             PRIVATE CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks that:
    ///
    /// 1. The first milestone is greater than or equal to the start time.
    /// 2. The milestones are ordered chronologically.
    /// 3. There are no duplicate milestones.
    /// 4. The deposit amount is equal to the segment amounts summed up.
    function _checkProSegments(
        Segment[] memory segments,
        uint256 segmentCount,
        uint128 netDepositAmount,
        uint40 startTime
    ) private pure {
        // Check that the first milestone is greater than or equal to the start time.
        if (startTime > segments[0].milestone) {
            revert Errors.SablierV2Pro__StartTimeGreaterThanFirstMilestone(startTime, segments[0].milestone);
        }

        // Pre-declare the variables needed in the for loop.
        uint40 currentMilestone;
        uint40 previousMilestone;
        uint128 segmentAmountsSum;

        // Iterate over the segments to sum up the segment amounts and check that the milestones are ordered.
        uint256 index;
        for (index = 0; index < segmentCount; ) {
            // Add the current segment amount to the sum.
            segmentAmountsSum = segmentAmountsSum + segments[index].amount;

            // Check that the previous milestone is less than the current milestone. Note that this can overflow.
            currentMilestone = segments[index].milestone;
            if (previousMilestone >= currentMilestone) {
                revert Errors.SablierV2Pro__SegmentMilestonesNotOrdered(index, previousMilestone, currentMilestone);
            }

            // Make the current milestone the previous milestone of the next loop iteration.
            previousMilestone = currentMilestone;

            // Increment the for loop iterator.
            unchecked {
                index += 1;
            }
        }

        // Check that the deposit amount is equal to the segment amounts sum.
        if (netDepositAmount != segmentAmountsSum) {
            revert Errors.SablierV2Pro__NetDepositAmountNotEqualToSegmentAmountsSum(
                netDepositAmount,
                segmentAmountsSum
            );
        }
    }
}
