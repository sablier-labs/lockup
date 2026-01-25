// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ISablierMerkleBase } from "./ISablierMerkleBase.sol";

/// @title ISablierMerkleExecute
/// @notice MerkleExecute enables an airdrop model where eligible users claim tokens and immediately execute a call
/// on a target contract (e.g., staking, lending pool deposit). The claimed tokens are approved to the target contract,
/// and a call is made using the stored function selector combined with user-provided arguments.
interface ISablierMerkleExecute is ISablierMerkleBase {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a claim is executed on behalf of an eligible recipient.
    /// @param index The index of the airdrop recipient in the Merkle tree.
    /// @param recipient The address of the airdrop recipient (always `msg.sender`).
    /// @param amount The amount of ERC-20 tokens claimed.
    /// @param target The address of the target contract that was called.
    event ClaimExecute(uint256 index, address indexed recipient, uint128 amount, address indexed target);

    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Whether to approve the claimed amount to the target contract before calling it.
    /// @dev This is an immutable state variable.
    function APPROVE_TARGET() external view returns (bool);

    /// @notice The function selector to call on the target contract.
    /// @dev This is an immutable state variable.
    function SELECTOR() external view returns (bytes4);

    /// @notice The address of the target contract to call after claiming.
    /// @dev This is an immutable state variable.
    function TARGET() external view returns (address);

    /*//////////////////////////////////////////////////////////////////////////
                              STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Claim airdrop and execute the call to the target contract.
    ///
    /// @dev It emits a {ClaimExecute} event.
    ///
    /// Notes:
    /// - Unlike other Merkle campaigns, this function does not have a `recipient` parameter. The recipient is always
    /// `msg.sender` to prevent security risks where someone could claim on behalf of another user and execute
    /// arbitrary calls.
    /// - The function approves the exact claim amount to the {TARGET}, executes the call, then revokes the approval.
    /// - If the target contract transfers tokens and if there is an amount encoded in `arguments`, it must match the
    /// airdropped `amount`. Otherwise, the remaining tokens will be left in the campaign contract.
    ///
    /// Requirements:
    /// - The current time must be greater than or equal to the campaign start time.
    /// - The campaign must not have expired.
    /// - `msg.value` must not be less than the value returned by {COMPTROLLER.calculateMinFeeWei}.
    /// - The `index` must not be claimed already.
    /// - The Merkle proof must be valid.
    /// - The external call to the target contract must succeed.
    ///
    /// @param index The index of `msg.sender` in the Merkle tree.
    /// @param amount The amount of ERC-20 tokens allocated to `msg.sender`.
    /// @param merkleProof The proof of inclusion in the Merkle tree.
    /// @param arguments The function ABI-encoded arguments for {SELECTOR}.
    function claimAndExecute(
        uint256 index,
        uint128 amount,
        bytes32[] calldata merkleProof,
        bytes calldata arguments
    )
        external
        payable;
}
