// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { MerkleVCA_Integration_Shared_Test } from "../MerkleVCA.t.sol";

contract CalculateRedistributionRewardsPerToken_MerkleVCA_Integration_Test is MerkleVCA_Integration_Shared_Test {
    function test_RevertGiven_RedistributionNotEnabled() external {
        // It should revert.
        vm.expectRevert(Errors.SablierMerkleVCA_RedistributionNotEnabled.selector);
        merkleVCA.calculateRedistributionRewardsPerToken();
    }

    modifier givenRedistributionEnabled() {
        // Enable the redistribution.
        setMsgSender(users.campaignCreator);
        merkleVCA.enableRedistribution();
        _;
    }

    function test_WhenNoClaimIsMade() external givenRedistributionEnabled {
        // It should return zero.
        assertEq(merkleVCA.calculateRedistributionRewardsPerToken(), 0, "redistribution rewards per token");
    }

    function test_WhenAtleastOneClaimIsMade() external givenRedistributionEnabled {
        vm.warp({ newTimestamp: CAMPAIGN_START_TIME });

        // Make a claim.
        setMsgSender(users.recipient);
        claimTo({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            to: users.recipient,
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof()
        });

        // It should return non-zero value.
        assertEq(
            merkleVCA.calculateRedistributionRewardsPerToken(),
            VCA_REWARDS_PER_TOKEN,
            "redistribution rewards per token"
        );
    }
}
