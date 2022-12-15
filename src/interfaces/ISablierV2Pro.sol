// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { SD1x18 } from "@prb/math/SD1x18.sol";

import { DataTypes } from "../libraries/DataTypes.sol";

import { ISablierV2 } from "./ISablierV2.sol";

/// @title ISablierV2Pro
/// @notice Creates streams with custom emission curves.
interface ISablierV2Pro is ISablierV2 {
    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Reads the segment amounts used to compose the custom emission curve.
    /// @param streamId The id of the stream to make the query for.
    /// @return segmentAmounts The segment amounts used to compose the custom emission curve.
    function getSegmentAmounts(uint256 streamId) external view returns (uint128[] memory segmentAmounts);

    /// @notice Reads the segment exponents used to compose the custom emission curve.
    /// @param streamId The id of the stream to make the query for.
    /// @return segmentExponents The segment exponents used to compose the custom emission curve.
    function getSegmentExponents(uint256 streamId) external view returns (SD1x18[] memory segmentExponents);

    /// @notice Reads the segment milestones used to compose the custom emission curve.
    /// @param streamId The id of the stream to make the query for.
    /// @return segmentMilestones The segment milestones used to compose the custom emission curve.
    function getSegmentMilestones(uint256 streamId) external view returns (uint40[] memory segmentMilestones);

    /// @notice Reads the stream struct.
    /// @param streamId The id of the stream to make the query for.
    /// @return stream The stream struct.
    function getStream(uint256 streamId) external view returns (DataTypes.ProStream memory stream);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a new stream funded by `msg.sender` wrapped in an ERC-721 NFT. The `stopTime` is implied by
    /// the last element in the `segmentMilestones` array.
    ///
    /// @dev Emits a {CreateProStream} and a {Transfer} event.
    ///
    /// Requirements:
    /// - `sender` must not be the zero address.
    /// - `recipient` must not be the zero address.
    /// - `depositAmount` must not be zero.
    /// - `startTime` must not be greater than `stopTime`.
    /// - `segmentAmounts` must be non-empty and not greater than `MAX_SEGMENT_COUNT`.
    /// - `segmentAmounts` summed up must be equal to `depositAmount`.
    /// - `segmentExponents` must be non-empty and not greater than `MAX_SEGMENT_COUNT`.
    /// - `segmentMilestones` must be non-empty and not greater than `MAX_SEGMENT_COUNT`.
    /// - `segmentMilestones` must be bounded between `startTime` and `stopTime`.
    /// - `msg.sender` must have allowed this contract to spend `depositAmount` tokens.
    ///
    /// @param sender The address from which to stream the tokens, which will have the ability to cancel the stream.
    /// It doesn't have to be the same as `msg.sender`.
    /// @param recipient The address toward which to stream the tokens.
    /// @param depositAmount The total amount of tokens to be streamed.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param startTime The unix timestamp in seconds for when the stream will start.
    /// @param segmentAmounts The amounts used to compose the custom emission curve.
    /// @param segmentExponents The exponents used to compose the custom emission curve.
    /// @param segmentMilestones The milestones used to compose the custom emission curve.
    /// @param cancelable Whether the stream will be cancelable or not.
    /// @return streamId The id of the newly created stream.
    function create(
        address sender,
        address recipient,
        uint128 depositAmount,
        address token,
        uint40 startTime,
        uint128[] memory segmentAmounts,
        SD1x18[] memory segmentExponents,
        uint40[] memory segmentMilestones,
        bool cancelable
    ) external returns (uint256 streamId);

    /// @notice Creates a stream funded by `msg.sender` wrapped in an ERC-721 NFT and sets the start time to
    /// `block.timestamp` and the stop time to `block.timestamp + sum(segmentDeltas)`.
    ///
    /// @dev Emits a {CreateProStream} and a {Transfer} event.
    ///
    /// Requirements:
    /// - All from `create`.
    ///
    /// @param sender The address from which to stream the tokens, which will have the ability to cancel the stream.
    /// It doesn't have to be the same as `msg.sender`.
    /// @param recipient The address toward which to stream the tokens.
    /// @param depositAmount The amount of tokens to be streamed.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param segmentAmounts The amounts used to compose the custom emission curve.
    /// @param segmentExponents The exponents used to compose the custom emission curve.
    /// @param segmentDeltas The differences between the milestones used to compose the custom emission curve.
    /// @param cancelable Whether the stream is cancelable or not.
    /// @return streamId The id of the newly created stream.
    function createWithDuration(
        address sender,
        address recipient,
        uint128 depositAmount,
        address token,
        uint128[] memory segmentAmounts,
        SD1x18[] memory segmentExponents,
        uint40[] memory segmentDeltas,
        bool cancelable
    ) external returns (uint256 streamId);
}
