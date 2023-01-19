// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

/// @title Errors
/// @notice Library with custom errors used across the core contracts.
library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                              SABLIER-V2 CUSTOM ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the broker fee is greater than the maximum fee permitted.
    error SablierV2_BrokerFeeTooHigh(UD60x18 brokerFee, UD60x18 maxFee);

    /// @notice Emitted when attempting to claim protocol revenues for a token that did not accrue any revenues.
    error SablierV2_NoProtocolRevenues(IERC20 token);

    /// @notice Emitted when attempting to create a stream with a zero deposit amount.
    error SablierV2_NetDepositAmountZero();

    /// @notice Emitted when the new global fee is greater than the maximum permitted.
    error SablierV2_NewGlobalFeeGreaterThanMaxPermitted(UD60x18 newGlobalFee, UD60x18 maxGlobalFee);

    /// @notice Emitted when the protocol fee is greater than the maximum fee permitted.
    error SablierV2_ProtocolFeeTooHigh(UD60x18 protocolFee, UD60x18 maxFee);

    /// @notice Emitted when attempting to renounce an already non-cancelable stream.
    error SablierV2_RenounceNonCancelableStream(uint256 streamId);

    /// @notice Emitted when the stream id points to a stream that is not canceled or depleted.
    error SablierV2_StreamNotCanceledOrDepleted(uint256 streamId);

    /// @notice Emitted when the stream id points to a stream that is not active.
    error SablierV2_StreamNotActive(uint256 streamId);

    /// @notice Emitted when attempting to cancel a stream that is already non-cancelable.
    error SablierV2_StreamNonCancelable(uint256 streamId);

    /// @notice Emitted when the `msg.sender` is not authorized to perform some action.
    error SablierV2_Unauthorized(uint256 streamId, address caller);

    /// @notice Emitted when attempting to withdraw from multiple streams and the count of the stream ids does
    /// not match the count of the amounts.
    error SablierV2_WithdrawArraysNotEqual(uint256 streamIdsCount, uint256 amountsCount);

    /// @notice Emitted when attempting to withdraw more than can be withdrawn.
    error SablierV2_WithdrawAmountGreaterThanWithdrawableAmount(
        uint256 streamId,
        uint128 amount,
        uint128 withdrawableAmount
    );

    /// @notice Emitted when attempting to withdraw zero tokens from a stream.
    /// @notice The id of the stream.
    error SablierV2_WithdrawAmountZero(uint256 streamId);

    /// @notice Emitted when the sender of the stream attempts to withdraw to some address other than the recipient.
    error SablierV2_WithdrawSenderUnauthorized(uint256 streamId, address sender, address to);

    /// @notice Emitted when attempting to withdraw to a zero address.
    error SablierV2_WithdrawToZeroAddress();

    /*//////////////////////////////////////////////////////////////////////////
                           SABLIER-V2-LINEAR CUSTOM ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when attempting to create a stream with a cliff time greater than stop time;
    error SablierV2Linear_CliffTimeGreaterThanStopTime(uint40 cliffTime, uint40 stopTime);

    /// @notice Emitted when attempting to create a stream with a start time greater than cliff time;
    error SablierV2Linear_StartTimeGreaterThanCliffTime(uint40 startTime, uint40 cliffTime);

    /*//////////////////////////////////////////////////////////////////////////
                            SABLIER-V2-PRO CUSTOM ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when attempting to create a stream and the count of the segments does not match the
    /// count of the deltas.
    error SablierV2Pro_SegmentArraysNotEqual(uint256 segmentCount, uint256 deltaCount);

    /// @notice Emitted when attempting to create a stream with a net deposit amount that does not equal the segment
    /// amounts sum.
    error SablierV2Pro_NetDepositAmountNotEqualToSegmentAmountsSum(uint128 netDepositAmount, uint128 segmentAmountsSum);

    /// @notice Emitted when attempting to create a stream with one or more segment counts greater than the maximum
    /// permitted.
    error SablierV2Pro_SegmentCountTooHigh(uint256 count);

    /// @notice Emitted when attempting to create a stream with zero segments.
    error SablierV2Pro_SegmentCountZero();

    /// @notice Emitted when attempting to create a stream with segment milestones that are not ordered.
    error SablierV2Pro_SegmentMilestonesNotOrdered(uint256 index, uint40 previousMilestone, uint40 currentMilestone);

    /// @notice Emitted when attempting to create a stream with the start time greater than the first segment milestone.
    error SablierV2Pro_StartTimeGreaterThanFirstMilestone(uint40 startTime, uint40 segmentMilestone);
}
