// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD2x18 } from "@prb/math/src/UD2x18.sol";

import { Broker, LockupDynamic, LockupLinear, LockupTranched } from "../../core/types/DataTypes.sol";

library BatchLockup {
    /// @notice A struct encapsulating all parameters of {SablierLockupDynamic.createWithDurations} except for the
    /// asset.
    struct CreateWithDurationsLD {
        address sender;
        address recipient;
        uint128 totalAmount;
        bool cancelable;
        bool transferable;
        LockupDynamic.SegmentWithDuration[] segments;
        Broker broker;
    }

    /// @notice A struct encapsulating all parameters of {SablierLockupLinear.createWithDurations} except for the
    /// asset.
    struct CreateWithDurationsLL {
        address sender;
        address recipient;
        uint128 totalAmount;
        bool cancelable;
        bool transferable;
        LockupLinear.Durations durations;
        Broker broker;
    }

    /// @notice A struct encapsulating all parameters of {SablierLockupTranched.createWithDurations} except for the
    /// asset.
    struct CreateWithDurationsLT {
        address sender;
        address recipient;
        uint128 totalAmount;
        bool cancelable;
        bool transferable;
        LockupTranched.TrancheWithDuration[] tranches;
        Broker broker;
    }

    /// @notice A struct encapsulating all parameters of {SablierLockupDynamic.createWithTimestamps} except for the
    /// asset.
    struct CreateWithTimestampsLD {
        address sender;
        address recipient;
        uint128 totalAmount;
        bool cancelable;
        bool transferable;
        uint40 startTime;
        LockupDynamic.Segment[] segments;
        Broker broker;
    }

    /// @notice A struct encapsulating all parameters of {SablierLockupLinear.createWithTimestamps} except for the
    /// asset.
    struct CreateWithTimestampsLL {
        address sender;
        address recipient;
        uint128 totalAmount;
        bool cancelable;
        bool transferable;
        LockupLinear.Timestamps timestamps;
        Broker broker;
    }

    /// @notice A struct encapsulating all parameters of {SablierLockupTranched.createWithTimestamps} except for the
    /// asset.
    struct CreateWithTimestampsLT {
        address sender;
        address recipient;
        uint128 totalAmount;
        bool cancelable;
        bool transferable;
        uint40 startTime;
        LockupTranched.Tranche[] tranches;
        Broker broker;
    }
}

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
