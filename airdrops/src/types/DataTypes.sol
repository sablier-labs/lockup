// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable one-contract-per-file
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD2x18 } from "@prb/math/src/UD2x18.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";

/// @notice Enum representing the type of claim functions available for a Merkle campaign.
/// @custom:value DEFAULT Activates `claim`, `claimTo`, and `claimViaSig` functions.
/// @custom:value ATTEST Activates only the `claimViaAttestation` function.
enum ClaimType {
    DEFAULT,
    ATTEST
}

library MerkleBase {
    /// @notice Struct encapsulating the constructor parameters of {SablierMerkleBase} contract.
    /// @dev The fields are arranged alphabetically.
    /// @param campaignCreator The address of campaign creator which should be the same as the `msg.sender`.
    /// @param campaignName The name of the campaign.
    /// @param campaignStartTime The start time of the campaign, as a Unix timestamp.
    /// @param comptroller The address of the comptroller contract.
    /// @param expiration The expiration of the campaign, as a Unix timestamp. A value of zero means the campaign does
    /// not expire.
    /// @param initialAdmin The initial admin of the campaign.
    /// @param ipfsCID The content identifier for indexing the contract on IPFS. An empty value may break certain UI
    /// features that depend upon the IPFS CID.
    /// @param merkleRoot The Merkle root of the claim data.
    /// @param token The contract address of the ERC-20 token to be distributed.
    struct ConstructorParams {
        address campaignCreator;
        string campaignName;
        uint40 campaignStartTime;
        address comptroller;
        uint40 expiration;
        address initialAdmin;
        string ipfsCID;
        bytes32 merkleRoot;
        IERC20 token;
    }
}

library MerkleExecute {
    /// @notice Struct encapsulating the constructor parameters of Merkle Execute campaigns.
    /// @dev The fields are arranged alphabetically.
    /// @param campaignName The name of the campaign.
    /// @param campaignStartTime The start time of the campaign, as a Unix timestamp.
    /// @param expiration The expiration of the campaign, as a Unix timestamp. A value of zero means the campaign does
    /// not expire.
    /// @param initialAdmin The initial admin of the campaign.
    /// @param ipfsCID The content identifier for indexing the contract on IPFS. An empty value may break certain UI
    /// features that depend upon the IPFS CID.
    /// @param merkleRoot The Merkle root of the claim data.
    /// @param selector The function selector to call on the target contract users claim tokens.
    /// @param target The address of the target contract (staking contract, lending pool) to which the function
    /// selector will be called when users claim tokens.
    /// @param token The contract address of the ERC-20 token to be distributed.
    struct ConstructorParams {
        string campaignName;
        uint40 campaignStartTime;
        uint40 expiration;
        address initialAdmin;
        string ipfsCID;
        bytes32 merkleRoot;
        bytes4 selector;
        address target;
        IERC20 token;
    }
}

library MerkleInstant {
    /// @notice Struct encapsulating the constructor parameters of Merkle Instant campaigns.
    /// @dev The fields are arranged alphabetically.
    /// @param campaignName The name of the campaign.
    /// @param campaignStartTime The start time of the campaign, as a Unix timestamp.
    /// @param claimType The type of claim functions to be enabled in the campaign.
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

library MerkleLL {
    /// @notice Struct encapsulating the constructor parameters of Merkle Lockup Linear campaigns.
    /// @dev The fields are arranged alphabetically.
    /// @param campaignName The name of the campaign.
    /// @param campaignStartTime The start time of the campaign, as a Unix timestamp.
    /// @param cancelable Indicates if the Lockup stream will be cancelable after claiming.
    /// @param claimType The type of claim functions to be enabled in the campaign.
    /// @param cliffDuration The cliff duration of the vesting stream, in seconds.
    /// @param cliffUnlockPercentage The percentage of the claim amount due to be unlocked at the vesting cliff time, as
    /// a fixed-point number where 1e18 is 100%
    /// @param expiration The expiration of the campaign, as a Unix timestamp. A value of zero means the campaign does
    /// not expire.
    /// @param granularity The smallest step in time between two consecutive token unlocks. Zero is a sentinel
    /// value for 1 second.
    /// @param initialAdmin The initial admin of the campaign.
    /// @param ipfsCID The content identifier for indexing the contract on IPFS. An empty value may break certain UI
    /// features that depend upon the IPFS CID.
    /// @param lockup The address of the {SablierLockup} contract.
    /// @param merkleRoot The Merkle root of the claim data.
    /// @param shape The shape of the vesting stream, used for differentiating between streams in the UI.
    /// @param startUnlockPercentage The percentage of the claim amount due to be unlocked at the vesting start time, as
    /// a fixed-point number where 1e18 is 100%.
    /// @param token The contract address of the ERC-20 token to be distributed.
    /// @param totalDuration The total duration of the vesting stream, in seconds.
    /// @param transferable Indicates if the Lockup stream will be transferable after claiming.
    /// @param vestingStartTime The start time of the vesting stream, as a Unix timestamp. Zero is a sentinel value for
    /// `block.timestamp`.
    struct ConstructorParams {
        string campaignName;
        uint40 campaignStartTime;
        bool cancelable;
        ClaimType claimType;
        uint40 cliffDuration;
        UD60x18 cliffUnlockPercentage;
        uint40 expiration;
        uint40 granularity;
        address initialAdmin;
        string ipfsCID;
        ISablierLockup lockup;
        bytes32 merkleRoot;
        string shape;
        UD60x18 startUnlockPercentage;
        IERC20 token;
        uint40 totalDuration;
        bool transferable;
        uint40 vestingStartTime;
    }
}

library MerkleLockup {
    /// @notice Struct encapsulating the constructor parameters of {SablierMerkleLockup} contract.
    /// @dev The fields are arranged alphabetically.
    /// @param cancelable Whether Lockup stream will be cancelable after claiming.
    /// @param lockup The address of the {SablierLockup} contract.
    /// @param shape The shape of the vesting stream, used for differentiating between streams in the UI.
    /// @param transferable Whether Lockup stream will be transferable after claiming.
    struct ConstructorParams {
        bool cancelable;
        ISablierLockup lockup;
        string shape;
        bool transferable;
    }
}

library MerkleLT {
    /// @notice Struct encapsulating the constructor parameters of Merkle Lockup Tranched campaigns.
    /// @dev The fields are arranged alphabetically.
    /// @param campaignName The name of the campaign.
    /// @param campaignStartTime The start time of the campaign, as a Unix timestamp.
    /// @param cancelable Indicates if the Lockup stream will be cancelable after claiming.
    /// @param claimType The type of claim functions to be enabled in the campaign.
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

library MerkleVCA {
    /// @notice Struct encapsulating the constructor parameters of Merkle VCA campaigns.
    /// @dev The fields are arranged alphabetically.
    /// @param aggregateAmount The total amount of ERC-20 tokens to be distributed to all recipients. If its value is
    /// set lower than actual total allocations in the Merkle tree, it can either cause a race condition among the
    /// recipients or rewards would be calculated as 0 if its too low. As a campaign creator, it is recommended to set
    /// the value to the actual total allocations.
    /// @param campaignName The name of the campaign.
    /// @param campaignStartTime The start time of the campaign, as a Unix timestamp.
    /// @param claimType The type of claim functions to be enabled in the campaign.
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
