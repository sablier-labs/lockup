// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { Broker, Durations, LockupLinearStream, Range } from "../types/Structs.sol";
import { ISablierV2Lockup } from "./ISablierV2Lockup.sol";

/// @title ISablierV2LockupLinear
/// @notice Creates streams whose streaming function is:
///
/// $$
/// f(x) = x * d + c
/// $$
///
/// Where:
///
/// - $x$ is the elapsed time divided by the total duration of the stream.
/// - $d$ is the deposit amount.
/// - $c$ is the cliff amount.
interface ISablierV2LockupLinear is ISablierV2Lockup {
    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Queries the cliff time of the stream.
    /// @param streamId The id of the stream to make the query for.
    function getCliffTime(uint256 streamId) external view returns (uint40 cliffTime);

    /// @notice Queries the range of the stream, a struct that encapsulates (i) the start time of the stream,
    //// (ii) the cliff time of the stream, and (iii) the end time of the stream, all as Unix timestamps.
    /// @param streamId The id of the stream to make the query for.
    function getRange(uint256 streamId) external view returns (Range memory range);

    /// @notice Queries the stream struct entity.
    /// @param streamId The id of the stream to make the query for.
    function getStream(uint256 streamId) external view returns (LockupLinearStream memory stream);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a stream funded by `msg.sender` wrapped in an ERC-721 NFT, setting the start time to
    /// `block.timestamp` and the end time to `block.timestamp + durations.total`.
    ///
    /// @dev Emits a {CreateLockupLinearStream} and a {Transfer} event.
    ///
    /// Requirements:
    /// - All from {createWithRange}.
    ///
    /// @param sender The address from which to stream the assets, which will have the ability to
    /// cancel the stream. It doesn't have to be the same as `msg.sender`.
    /// @param recipient The address toward which to stream the assets.
    /// @param grossDepositAmount The gross amount of assets to be deposited, inclusive of fees, in units of the asset's
    /// decimals.
    /// @param asset The contract address of the ERC-20 asset to use for streaming.
    /// @param cancelable A boolean that indicates whether the stream will be cancelable or not.
    /// @param durations A struct that encapsulates (i) the duration of the cliff period and (ii) the total duration of
    /// the stream, both in seconds.
    /// @param broker An optional struct that encapsulates (i) the address of the broker that has helped create the
    /// stream and (ii) the percentage fee that the broker is paid from the gross deposit amount, as an UD60x18 number.
    /// @return streamId The id of the newly created stream.
    function createWithDurations(
        address sender,
        address recipient,
        uint128 grossDepositAmount,
        IERC20 asset,
        bool cancelable,
        Durations calldata durations,
        Broker calldata broker
    ) external returns (uint256 streamId);

    /// @notice Creates a new stream funded by `msg.sender` wrapped in an ERC-721 NFT, setting the start time and the
    /// end time to the provided values.
    ///
    /// @dev Emits a {CreateLockupLinearStream} and a {Transfer} event.
    ///
    /// Notes:
    /// - As long as they are ordered, it is not an error to set a range in the past.
    ///
    /// Requirements:
    /// - `recipient` must not be the zero address.
    /// - `grossDepositAmount` must not be zero.
    /// - `range.start` must not be greater than `range.cliff`.
    /// - `range.cliff` must not be greater than `range.end`.
    /// - `msg.sender` must have allowed this contract to spend at least `grossDepositAmount` assets.
    /// - If set, `broker.fee` must not be greater than `MAX_FEE`.
    ///
    /// @param sender The address from which to stream the assets, which will have the ability to cancel the stream.
    /// It doesn't have to be the same as `msg.sender`.
    /// @param recipient The address toward which to stream the assets.
    /// @param grossDepositAmount The gross amount of assets to deposit, inclusive of fees, in units of the asset's
    /// decimals.
    /// @param asset The contract address of the ERC-20 asset to use for streaming.
    /// @param cancelable A boolean that indicates whether the stream will be cancelable or not.
    /// @param range A struct that encapsulates (i) the start time of the stream, (ii) the cliff time of the stream,
    /// and (iii) the end time of the stream, all as Unix timestamps.
    /// @param broker An optional struct that encapsulates (i) the address of the broker that has helped create the
    /// stream and (ii) the percentage fee that the broker is paid from the deposit amount, as an UD60x18 number.
    /// @return streamId The id of the newly created stream.
    function createWithRange(
        address sender,
        address recipient,
        uint128 grossDepositAmount,
        IERC20 asset,
        bool cancelable,
        Range calldata range,
        Broker calldata broker
    ) external returns (uint256 streamId);
}
