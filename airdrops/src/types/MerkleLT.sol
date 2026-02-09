// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD2x18 } from "@prb/math/src/UD2x18.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";

import { ClaimType } from "./MerkleBase.sol";

library MerkleLT {
    /// @notice Struct encapsulating the constructor parameters of Merkle Lockup Tranched campaigns.
    /// @dev The fields are arranged alphabetically.
    /// @param campaignName The name of the campaign.
    /// @param campaignStartTime The start time of the campaign, as a Unix timestamp.
    /// @param cancelable Indicates if the Lockup stream will be cancelable after claiming.
    /// @param claimType The type of claim functions supported by the campaign.
    /// @param expiration The expiration of the campaign, as a Unix timestamp. A value of zero means the campaign does
    /// not expire.
    /// @param initialAdmin The initial admin of the campaign.
    /// @param ipfsCID The content identifier for indexing the contract on IPFS. An empty value may break certain UI
    /// features that depend upon the IPFS CID.
    /// @param lockup The address of the {SablierLockup} contract.
    /// @param merkleRoot The Merkle root of the claim data.
    /// @param shape The shape of Lockup stream, used for differentiating between streams in the  UI.
    /// @param token The contract address of the ERC-20 token to be distributed.
    /// @param tranchesWithPercentages The tranches with their respective unlock percentages, which are documented in
    /// {MerkleLT.TrancheWithPercentage}.
    /// @param transferable Indicates if the Lockup stream will be transferable after claiming.
    /// @param vestingStartTime The start time of the vesting stream, as a Unix timestamp. Zero is a sentinel value for
    /// `block.timestamp`.
    struct ConstructorParams {
        string campaignName;
        uint40 campaignStartTime;
        bool cancelable;
        ClaimType claimType;
        uint40 expiration;
        address initialAdmin;
        string ipfsCID;
        ISablierLockup lockup;
        bytes32 merkleRoot;
        string shape;
        IERC20 token;
        MerkleLT.TrancheWithPercentage[] tranchesWithPercentages;
        bool transferable;
        uint40 vestingStartTime;
    }

    /// @notice Struct encapsulating the unlock percentage and duration of a tranche.
    /// @dev Since users may have different amounts allocated, this struct makes it possible to calculate the amounts
    /// at claim time. An 18-decimal format is used to represent percentages: 100% = 1e18. For more information, see
    /// the PRBMath documentation on UD2x18: https://github.com/PaulRBerg/prb-math
    /// @param unlockPercentage The percentage designated to be unlocked in this tranche.
    /// @param duration The time difference in seconds between this tranche and the previous one.
    struct TrancheWithPercentage {
        // slot 0
        UD2x18 unlockPercentage;
        uint40 duration;
    }
}
