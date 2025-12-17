// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { MerkleVCA } from "src/types/DataTypes.sol";

import { MerkleVCA_Integration_Shared_Test } from "../MerkleVCA.t.sol";

contract CalculateRedistributionRewardsPerToken_MerkleVCA_Integration_Test is MerkleVCA_Integration_Shared_Test {
    function setUp() public override {
        MerkleVCA_Integration_Shared_Test.setUp();

        // Warp to campaign start time.
        vm.warp({ newTimestamp: CAMPAIGN_START_TIME });
    }

    function test_RevertGiven_RedistributionNotEnabled() external {
        // It should revert.
        vm.expectRevert(Errors.SablierMerkleVCA_RedistributionNotEnabled.selector);
        merkleVCA.calculateRedistributionRewardsPerToken();
    }

    function test_GivenTotalForgoneAmountZero() external givenRedistributionEnabled(merkleVCA) {
        // Check that the total forgone amount is zero.
        assertEq(merkleVCA.totalForgoneAmount(), 0, "total forgone amount");

        // It should return zero.
        assertEq(merkleVCA.calculateRedistributionRewardsPerToken(), 0, "rewards per token");
    }

    function test_GivenAggregateAmountUndervalued()
        external
        givenRedistributionEnabled(merkleVCA)
        givenTotalForgoneAmountNotZero
    {
        // Create a new campaign with aggregate amount less than the actual aggregate amount.
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.aggregateAmount = VCA_FULL_AMOUNT - 1;
        merkleVCA = createMerkleVCA(params);
        merkleBase = merkleVCA;

        // Enable the redistribution on new campaign.
        merkleVCA.enableRedistribution();

        // Claim early so that there is some forgone amount.
        setMsgSender(users.recipient);
        claimTo({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            to: users.recipient,
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof()
        });

        // Check that the total forgone amount is not zero.
        assertGt(merkleVCA.totalForgoneAmount(), 0, "total forgone amount");

        // It should return zero.
        assertEq(merkleVCA.calculateRedistributionRewardsPerToken(), 0, "rewards per token");
    }

    function test_GivenInsufficientBalance()
        external
        givenRedistributionEnabled(merkleVCA)
        givenTotalForgoneAmountNotZero
        givenAggregateAmountNotUndervalued
    {
        // Claim early so that there is some forgone amount.
        setMsgSender(users.recipient);
        claimTo({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            to: users.recipient,
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof()
        });

        // Clawback some tokens from the campaign so that it has insufficient balance.
        setMsgSender(users.campaignCreator);
        merkleVCA.clawback(address(this), 1e18);

        // It should return zero.
        assertEq(merkleVCA.calculateRedistributionRewardsPerToken(), 0, "rewards per token");
    }

    function test_GivenSufficientBalance()
        external
        givenRedistributionEnabled(merkleVCA)
        givenTotalForgoneAmountNotZero
        givenAggregateAmountNotUndervalued
    {
        // Claim early so that there is some forgone amount.
        setMsgSender(users.recipient);
        claimTo({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            to: users.recipient,
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof()
        });

        // It should return correct value.
        assertEq(merkleVCA.calculateRedistributionRewardsPerToken(), VCA_REWARDS_PER_TOKEN, "rewards per token");
    }
}
