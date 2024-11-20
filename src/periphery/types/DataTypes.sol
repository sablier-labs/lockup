// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD2x18 } from "@prb/math/src/UD2x18.sol";

library MerkleBase {
    /// @notice Struct encapsulating the base constructor parameters of a Merkle campaign.
    /// @param asset The contract address of the ERC-20 asset to be distributed.
    /// @param expiration The expiration of the campaign, as a Unix timestamp.
    /// @param initialAdmin The initial admin of the campaign.
    /// @param ipfsCID The content identifier for indexing the contract on IPFS.
    /// @param merkleRoot The Merkle root of the claim data.
    /// @param name The name of the campaign.
    struct ConstructorParams {
        IERC20 asset;
        uint40 expiration;
        address initialAdmin;
        string ipfsCID;
        bytes32 merkleRoot;
        string name;
    }
}

library MerkleFactory {
    /// @notice Struct encapsulating the custom fee details for a given campaign creator.
    /// @param enabled Whether the fee is enabled. If false, the default fee will be applied for campaigns created by
    /// the given creator.
    /// @param fee The fee amount.
    struct SablierFeeByUser {
        bool enabled;
        uint256 fee;
    }
}

library MerkleLL {
    /// @notice Struct encapsulating the start time, cliff duration and the end duration used to construct the time
    /// variables in `Lockup.CreateWithTimestampsLL`.
    /// @dev A start time value of zero will be considered as `block.timestamp`.
    /// @param startTime The start time of the stream.
    /// @param startAmount The amount to be unlocked at the start time.
    /// @param cliffDuration The duration of the cliff.
    /// @param cliffAmount The amount to be unlocked at the cliff time.
    /// @param totalDuration The total duration of the stream.
    struct Schedule {
        uint40 startTime;
        uint128 startAmount;
        uint40 cliffDuration;
        uint128 cliffAmount;
        uint40 totalDuration;
    }
}

library MerkleLT {
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
