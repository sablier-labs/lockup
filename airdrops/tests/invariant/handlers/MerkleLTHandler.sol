// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { SablierMerkleLT } from "src/SablierMerkleLT.sol";
import { MerkleLT } from "src/types/DataTypes.sol";
import { LeafData } from "../../utils/MerkleBuilder.sol";
import { Store } from "../stores/Store.sol";
import { BaseHandler } from "./BaseHandler.sol";

/// @notice Handler for the Merkle LT campaign.
contract MerkleLTHandler is BaseHandler {
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
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function _claim(LeafData memory leafData, bytes32[] memory merkleProof) internal override {
        SablierMerkleLT merkleLT = SablierMerkleLT(address(campaign));

        // Claim the airdrop.
        merkleLT.claim{ value: AIRDROP_MIN_FEE_WEI }(leafData.index, leafData.recipient, leafData.amount, merkleProof);

        // Update claim amount in store.
        store.updateTotalClaimAmount(address(campaign), leafData.amount);
    }

    function _deployCampaign(
        address campaignCreator,
        bytes32 merkleRoot
    )
        internal
        override
        returns (ISablierMerkleBase campaign)
    {
        // Fuzz the tranches with percentages.
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages_ = new MerkleLT.TrancheWithPercentage[](2);
        fuzzTranchesMerkleLT({ vestingStartTime: 0, tranches: tranchesWithPercentages_ });

        // Prepare constructor parameters.
        MerkleLT.ConstructorParams memory params;

        params.campaignName = CAMPAIGN_NAME;
        params.campaignStartTime = getBlockTimestamp();
        params.cancelable = STREAM_CANCELABLE;
        params.expiration = getBlockTimestamp() + 365 days;
        params.initialAdmin = campaignCreator;
        params.ipfsCID = IPFS_CID;
        params.lockup = lockup;
        params.merkleRoot = merkleRoot;
        params.shape = STREAM_SHAPE;
        params.token = campaignToken;
        params.tranchesWithPercentages = tranchesWithPercentages_;
        params.transferable = STREAM_TRANSFERABLE;
        params.vestingStartTime = 0; // Use block.timestamp as sentinel value

        // Deploy and return the campaign address.
        campaign = ISablierMerkleBase(new SablierMerkleLT(params, campaignCreator, comptroller));
    }
}
