// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ISablierLockupTranched } from "../../core/interfaces/ISablierLockupTranched.sol";

import { ISablierMerkleBase } from "./ISablierMerkleBase.sol";
import { MerkleLT } from "../types/DataTypes.sol";

/// @title ISablierMerkleLT
/// @notice Merkle Lockup campaign that creates LockupTranched streams.
interface ISablierMerkleLT is ISablierMerkleBase {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a recipient claims a stream.
    event Claim(uint256 index, address indexed recipient, uint128 amount, uint256 indexed streamId);

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice A flag indicating whether the streams can be canceled.
    /// @dev This is an immutable state variable.
    function CANCELABLE() external returns (bool);

    /// @notice The address of the {SablierLockupTranched} contract.
    function LOCKUP_TRANCHED() external view returns (ISablierLockupTranched);

    /// @notice The start time of the streams created through `claim` function.
    /// @dev A start time value of zero will be considered as `block.timestamp`.
    function STREAM_START_TIME() external returns (uint40);

    /// @notice The total percentage of the tranches.
    function TOTAL_PERCENTAGE() external view returns (uint64);

    /// @notice A flag indicating whether the stream NFTs are transferable.
    /// @dev This is an immutable state variable.
    function TRANSFERABLE() external returns (bool);

    /// @notice Retrieves the tranches with their respective unlock percentages and durations.
    function getTranchesWithPercentages() external view returns (MerkleLT.TrancheWithPercentage[] memory);
}
