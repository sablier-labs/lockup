// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ClaimType } from "./MerkleBase.sol";

library MerkleInstant {
    /// @notice Struct encapsulating the constructor parameters of Merkle Instant campaigns.
    /// @dev The fields are arranged alphabetically.
    /// @param campaignName The name of the campaign.
    /// @param campaignStartTime The start time of the campaign, as a Unix timestamp.
    /// @param claimType The type of claim functions supported by the campaign.
    /// @param expiration The expiration of the campaign, as a Unix timestamp. A value of zero means the campaign does
    /// not expire.
    /// @param initialAdmin The initial admin of the campaign.
    /// @param ipfsCID The content identifier for indexing the contract on IPFS. An empty value may break certain UI
    /// features that depend upon the IPFS CID.
    /// @param merkleRoot The Merkle root of the claim data.
    /// @param token The contract address of the ERC-20 token to be distributed.
    struct ConstructorParams {
        string campaignName;
        uint40 campaignStartTime;
        ClaimType claimType;
        uint40 expiration;
        address initialAdmin;
        string ipfsCID;
        bytes32 merkleRoot;
        IERC20 token;
    }
}
