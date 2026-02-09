// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import { SablierMerkleLL } from "src/SablierMerkleLL.sol";
import { MerkleLL } from "src/types/MerkleLL.sol";
import { LeafData } from "../../utils/MerkleBuilder.sol";
import { Store } from "../stores/Store.sol";
import { BaseHandler } from "./BaseHandler.sol";

/// @notice Handler for the Merkle LL campaign.
contract MerkleLLHandler is BaseHandler {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    ISablierLockup public lockup;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(address comptroller_, address lockup_, Store store_) BaseHandler(comptroller_, store_) {
        lockup = ISablierLockup(lockup_);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     OVERRIDES
    //////////////////////////////////////////////////////////////////////////*/

    function _claim(LeafData memory leafData, bytes32[] memory merkleProof) internal override {
        SablierMerkleLL merkleLL = SablierMerkleLL(address(campaign));

        // Claim the airdrop.
        merkleLL.claim{ value: AIRDROP_MIN_FEE_WEI }(leafData.index, leafData.recipient, leafData.amount, merkleProof);

        // Update claim amount in store.
        store.updateTotalClaimAmount(address(campaign), leafData.amount);
    }

    function _deployCampaign(address campaignCreator, bytes32 merkleRoot) internal override returns (address) {
        // Prepare constructor parameters.
        MerkleLL.ConstructorParams memory params;

        params.campaignName = CAMPAIGN_NAME;
        params.campaignStartTime = getBlockTimestamp();
        params.cancelable = STREAM_CANCELABLE;
        params.cliffDuration = VESTING_CLIFF_DURATION;
        params.cliffUnlockPercentage = VESTING_CLIFF_UNLOCK_PERCENTAGE;
        params.expiration = getBlockTimestamp() + 365 days;
        params.initialAdmin = campaignCreator;
        params.ipfsCID = IPFS_CID;
        params.lockup = lockup;
        params.merkleRoot = merkleRoot;
        params.shape = STREAM_SHAPE;
        params.startUnlockPercentage = VESTING_START_UNLOCK_PERCENTAGE;
        params.token = campaignToken;
        params.totalDuration = VESTING_TOTAL_DURATION;
        params.transferable = STREAM_TRANSFERABLE;
        params.vestingStartTime = 0; // Use block.timestamp as sentinel value

        // Deploy and return the campaign address.
        return address(new SablierMerkleLL(params, campaignCreator, comptroller));
    }
}
