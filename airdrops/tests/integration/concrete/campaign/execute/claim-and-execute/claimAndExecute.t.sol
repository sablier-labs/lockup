// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleExecute } from "src/interfaces/ISablierMerkleExecute.sol";
import { MerkleExecute } from "src/types/DataTypes.sol";

import { MockStakingRevert } from "./../../../../../mocks/MockStakingRevert.sol";
import { Integration_Test } from "./../../../../Integration.t.sol";
import { Claim_Integration_Test } from "./../../shared/claim/claim.t.sol";
import { MerkleExecute_Integration_Shared_Test } from "./../MerkleExecute.t.sol";

contract ClaimAndExecute_MerkleExecute_Integration_Test is
    MerkleExecute_Integration_Shared_Test,
    Claim_Integration_Test
{
    function setUp() public virtual override(MerkleExecute_Integration_Shared_Test, Integration_Test) {
        MerkleExecute_Integration_Shared_Test.setUp();

        // Make the recipient the caller.
        setMsgSender(users.recipient);
    }

    function test_RevertWhen_TargetTransferAmountOverdraws()
        external
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
        whenRecipientEligible
        whenAmountValid
        whenMerkleProofValid
    {
        uint128 overdrawAmount = CLAIM_AMOUNT + 1;

        // It should revert because the `claimAndExecute` function only approves the claim amount.
        vm.expectRevert();
        merkleExecute.claimAndExecute{ value: AIRDROP_MIN_FEE_WEI }({
            index: getIndexInMerkleTree(),
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof(),
            arguments: abi.encode(overdrawAmount)
        });
    }

    function test_RevertWhen_TargetCallNotSucceed()
        external
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
        whenAmountValid
        whenMerkleProofValid
        whenTargetTransferAmountNotOverdraw
    {
        // Deploy the reverting staking contract.
        MockStakingRevert mockStakingRevert = new MockStakingRevert();

        // Create a campaign with a reverting target function.
        MerkleExecute.ConstructorParams memory params = merkleExecuteConstructorParams();
        params.target = address(mockStakingRevert);
        params.campaignName = "Reverting campaign";

        setMsgSender(users.campaignCreator);
        ISablierMerkleExecute revertingCampaign = createMerkleExecute(params);

        setMsgSender(users.recipient);

        // It should revert.
        vm.expectRevert("Shall not pass!");
        revertingCampaign.claimAndExecute{ value: AIRDROP_MIN_FEE_WEI }(
            getIndexInMerkleTree(), CLAIM_AMOUNT, getMerkleProof(), abi.encode(CLAIM_AMOUNT)
        );
    }

    function test_WhenTargetCallSucceeds()
        external
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
        whenRecipientEligible
        whenAmountValid
        whenMerkleProofValid
        whenTargetTransferAmountNotOverdraw
    {
        uint256 previousFeeAccrued = address(comptroller).balance;
        uint256 index = getIndexInMerkleTree();
        uint256 initialCampaignBalance = dai.balanceOf(address(merkleExecute));

        // Expect the {ClaimExecute} event to be emitted.
        vm.expectEmit({ emitter: address(merkleExecute) });
        emit ISablierMerkleExecute.ClaimExecute(index, users.recipient, CLAIM_AMOUNT, address(mockStaking));

        // Claim and execute.
        claim();

        // Assert the index is marked as claimed.
        assertTrue(merkleExecute.hasClaimed(index), "not claimed");

        // Assert the fee was collected.
        assertEq(address(comptroller).balance, previousFeeAccrued + AIRDROP_MIN_FEE_WEI, "fee not collected");

        // Assert the tokens were transferred to the target.
        assertEq(dai.balanceOf(address(merkleExecute)), initialCampaignBalance - CLAIM_AMOUNT, "tokens not transferred");
        assertEq(dai.balanceOf(address(mockStaking)), CLAIM_AMOUNT, "tokens not received by target");
    }
}
