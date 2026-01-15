// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { SablierMerkleVCA } from "src/SablierMerkleVCA.sol";
import { MerkleVCA } from "src/types/DataTypes.sol";
import { LeafData } from "../../utils/MerkleBuilder.sol";
import { Store } from "../stores/Store.sol";
import { BaseHandler } from "./BaseHandler.sol";

/// @notice Handler for the Merkle VCA campaign.
contract MerkleVCAHandler is BaseHandler {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(address comptroller_, Store store_) BaseHandler(comptroller_, store_) { }

    /*//////////////////////////////////////////////////////////////////////////
                                     OVERRIDES
    //////////////////////////////////////////////////////////////////////////*/

    function _claim(LeafData memory leafData, bytes32[] memory merkleProof) internal override {
        SablierMerkleVCA merkleVCA = SablierMerkleVCA(address(campaign));

        // Calculate the claim amount.
        uint128 claimAmount =
            merkleVCA.calculateClaimAmount({ fullAmount: leafData.amount, claimTime: getBlockTimestamp() });

        // Skip if claim amount is zero.
        vm.assume(claimAmount > 0);

        // Calculate the forgone amount.
        uint128 forgoneAmount = leafData.amount - claimAmount;

        // Claim the airdrop.
        merkleVCA.claimTo{ value: AIRDROP_MIN_FEE_WEI }(
            leafData.index, leafData.recipient, leafData.amount, merkleProof
        );

        // Update claim amount in store.
        store.updateTotalClaimAmount(address(campaign), claimAmount);

        // Update forgone amount for VCA campaign in store.
        store.updateTotalForgoneAmount(forgoneAmount);

        // Update total claim amount requested for VCA campaign in store.
        store.updateVcaTotalClaimAmountRequested(leafData.amount);
    }

    function _deployCampaign(address campaignCreator, bytes32 merkleRoot) internal override returns (address campaign) {
        // Load pre-defined constructor parameters.
        MerkleVCA.ConstructorParams memory params;

        params.campaignName = CAMPAIGN_NAME;
        params.campaignStartTime = getBlockTimestamp();
        params.expiration = getBlockTimestamp() + 365 days;
        params.initialAdmin = campaignCreator;
        params.ipfsCID = IPFS_CID;
        params.merkleRoot = merkleRoot;
        params.token = campaignToken;
        params.unlockPercentage = VCA_UNLOCK_PERCENTAGE;
        params.vestingEndTime = getBlockTimestamp() + VESTING_TOTAL_DURATION;
        params.vestingStartTime = getBlockTimestamp();

        // Deploy and return the campaign address.
        campaign = address(new SablierMerkleVCA(params, campaignCreator, comptroller));

        // Update VCA campaign in store.
        store.updateVcaCampaign(campaign);
    }
}
