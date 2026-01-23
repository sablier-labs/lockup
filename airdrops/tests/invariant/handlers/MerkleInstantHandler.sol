// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { SablierMerkleInstant } from "src/SablierMerkleInstant.sol";
import { MerkleInstant } from "src/types/DataTypes.sol";
import { LeafData } from "../../utils/MerkleBuilder.sol";
import { Store } from "../stores/Store.sol";
import { BaseHandler } from "./BaseHandler.sol";

/// @notice Handler for the Merkle Instant campaign.
contract MerkleInstantHandler is BaseHandler {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(address comptroller_, Store store_) BaseHandler(comptroller_, store_) { }

    /*//////////////////////////////////////////////////////////////////////////
                                     OVERRIDES
    //////////////////////////////////////////////////////////////////////////*/

    function _claim(LeafData memory leafData, bytes32[] memory merkleProof) internal override {
        SablierMerkleInstant merkleInstant = SablierMerkleInstant(address(campaign));

        // Claim the airdrop.
        merkleInstant.claim{ value: AIRDROP_MIN_FEE_WEI }(
            leafData.index, leafData.recipient, leafData.amount, merkleProof
        );

        // Update claim amount in store.
        store.updateTotalClaimAmount(address(campaign), leafData.amount);
    }

    function _deployCampaign(address campaignCreator, bytes32 merkleRoot) internal override returns (address) {
        // Prepare constructor parameters.
        MerkleInstant.ConstructorParams memory params;

        params.campaignName = CAMPAIGN_NAME;
        params.campaignStartTime = getBlockTimestamp();
        params.expiration = getBlockTimestamp() + 365 days;
        params.initialAdmin = campaignCreator;
        params.ipfsCID = IPFS_CID;
        params.merkleRoot = merkleRoot;
        params.token = campaignToken;

        // Deploy and return the campaign address.
        return address(new SablierMerkleInstant(params, campaignCreator, comptroller));
    }
}
