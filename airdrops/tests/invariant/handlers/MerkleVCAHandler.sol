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

        // Calculate the forgone and claim amounts.
        uint128 forgoneAmount = merkleVCA.calculateForgoneAmount(leafData.amount, getBlockTimestamp());
        uint128 claimAmount = leafData.amount - forgoneAmount;

        // Skip if claim amount is zero.
        vm.assume(claimAmount > 0);

        // Get initial balance of recipient for rewards calculation.
        uint256 initialRecipientBalance = campaignToken.balanceOf(leafData.recipient);

        // Claim the airdrop.
        merkleVCA.claimTo{ value: AIRDROP_MIN_FEE_WEI }(
            leafData.index, leafData.recipient, leafData.amount, merkleProof
        );

        // Update redistribution rewards per 1e18 before claiming.
        if (merkleVCA.isRedistributionEnabled()) {
            store.updatePreviousVcaRedistributionRewardsPer1e18(
                address(campaign), merkleVCA.calculateRedistributionRewards({ fullAmount: 1e18 })
            );
        }

        // Update forgone amount for VCA campaign in store before calling the claim.
        store.updatePreviousVcaTotalForgoneAmount(address(campaign), leafData.amount - claimAmount);

        // Update claim amount in store.
        store.updateTotalClaimAmount(address(campaign), claimAmount);

        // Update total full amount requested for VCA campaign in store.
        store.updateVcaTotalFullAmountRequested(address(campaign), leafData.amount);

        if (merkleVCA.isRedistributionEnabled()) {
            // Get final balance of recipient for rewards calculation.
            uint256 finalRecipientBalance = campaignToken.balanceOf(leafData.recipient);

            // Calculate the rewards transferred to the recipient and update in store.
            uint256 rewardsTransferred = finalRecipientBalance - initialRecipientBalance - claimAmount;
            store.updateTotalRewardsDistributed(address(campaign), rewardsTransferred);
        }
    }

    function _deployCampaign(address campaignCreator, bytes32 merkleRoot) internal override returns (address campaign) {
        // Load pre-defined constructor parameters.
        MerkleVCA.ConstructorParams memory params;

        // First campaign deployed has redistribution disabled, second has it enabled.
        params.enableRedistribution = totalCalls["deployCampaign"] == 1;

        params.aggregateAmount = aggregateAmount;
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

        // Mark as VCA campaign in store.
        store.setVcaCampaign(campaign);
    }

    function _maxCampaignsDeployed() internal pure override returns (uint256) {
        return 2;
    }
}
