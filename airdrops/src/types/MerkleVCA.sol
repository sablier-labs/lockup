// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { ClaimType } from "./MerkleBase.sol";

library MerkleVCA {
    /// @notice Struct encapsulating the constructor parameters of Merkle VCA campaigns.
    /// @dev The fields are arranged alphabetically.
    /// @param aggregateAmount The total amount of ERC-20 tokens to be distributed to all recipients. If its value is
    /// set lower than actual total allocations in the Merkle tree, it can either cause a race condition among the
    /// recipients or rewards would be calculated as 0 if its too low. As a campaign creator, it is recommended to set
    /// the value to the actual total allocations.
    /// @param campaignName The name of the campaign.
    /// @param campaignStartTime The start time of the campaign, as a Unix timestamp.
    /// @param claimType The type of claim functions supported by the campaign.
    /// @param enableRedistribution Enable redistribution of forgone tokens at deployment.
    /// @param expiration The expiration of the campaign, as a Unix timestamp.
    /// @param initialAdmin The initial admin of the campaign.
    /// @param ipfsCID The content identifier for indexing the contract on IPFS. An empty value may break certain UI
    /// features that depend upon the IPFS CID.
    /// @param merkleRoot The Merkle root of the claim data.
    /// @param token The contract address of the ERC-20 token to be distributed.
    /// @param unlockPercentage The percentage of the full amount that will unlock immediately at the start time,
    /// denominated as fixed-point number where 1e18 is 100%.
    /// @param vestingEndTime Vesting end time, as a Unix timestamp.
    /// @param vestingStartTime Vesting start time, as a Unix timestamp.
    struct ConstructorParams {
        uint128 aggregateAmount;
        string campaignName;
        uint40 campaignStartTime;
        ClaimType claimType;
        bool enableRedistribution;
        uint40 expiration;
        address initialAdmin;
        string ipfsCID;
        bytes32 merkleRoot;
        IERC20 token;
        UD60x18 unlockPercentage;
        uint40 vestingEndTime;
        uint40 vestingStartTime;
    }
}
