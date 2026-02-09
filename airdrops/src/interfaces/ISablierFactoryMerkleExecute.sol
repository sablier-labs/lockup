// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { MerkleExecute } from "../types/MerkleExecute.sol";
import { ISablierFactoryMerkleBase } from "./ISablierFactoryMerkleBase.sol";
import { ISablierMerkleExecute } from "./ISablierMerkleExecute.sol";

/// @title ISablierFactoryMerkleExecute
/// @notice A factory that deploys MerkleExecute campaign contracts.
/// @dev See the documentation in {ISablierMerkleExecute}.
interface ISablierFactoryMerkleExecute is ISablierFactoryMerkleBase {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a {SablierMerkleExecute} campaign is created.
    event CreateMerkleExecute(
        ISablierMerkleExecute indexed merkleExecute,
        MerkleExecute.ConstructorParams campaignParams,
        uint256 aggregateAmount,
        uint256 recipientCount,
        address comptroller,
        uint256 minFeeUSD
    );

    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Computes the deterministic address where {SablierMerkleExecute} campaign will be deployed.
    /// @dev Reverts if the requirements from {createMerkleExecute} are not met.
    function computeMerkleExecute(
        address campaignCreator,
        MerkleExecute.ConstructorParams calldata campaignParams
    )
        external
        view
        returns (address merkleExecute);

    /*//////////////////////////////////////////////////////////////////////////
                              STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a new MerkleExecute campaign for claim-and-execute distribution of tokens.
    ///
    /// @dev Emits a {CreateMerkleExecute} event.
    ///
    /// Notes:
    /// - The contract is created with CREATE2.
    /// - The campaign's fee will be set to the min USD fee unless a custom fee is set for `msg.sender`.
    /// - A value of zero for `campaignParams.expiration` means the campaign does not expire.
    /// - The create function does not validate if the `campaignParams.selector` is a function implemented by the target
    /// contract. In that case, the `claimAndExecute` function will revert.
    /// - If the target contract does not implement the `campaignParams.selector` but has `fallback`, the
    /// `claimAndExecute` call may silently succeed. If fallback does not transfer claim tokens, the claim tokens will
    /// be left in the campaign contract. These tokens can be clawbacked by the campaign creator.
    ///
    /// Requirements:
    /// - `campaignParams.token` must not be the forbidden native token.
    /// - `campaignParams.target` must be a contract.
    ///
    /// @param campaignParams Struct encapsulating the {SablierMerkleExecute} parameters, which are documented in
    /// {DataTypes}.
    /// @param aggregateAmount The total amount of ERC-20 tokens to be distributed to all recipients.
    /// @param recipientCount The total number of recipient addresses eligible for the airdrop.
    /// @return merkleExecute The address of the newly created MerkleExecute campaign.
    function createMerkleExecute(
        MerkleExecute.ConstructorParams calldata campaignParams,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        returns (ISablierMerkleExecute merkleExecute);
}
