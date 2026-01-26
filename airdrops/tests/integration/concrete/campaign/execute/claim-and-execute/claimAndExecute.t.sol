// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { ISablierMerkleExecute } from "src/interfaces/ISablierMerkleExecute.sol";
import { MerkleExecute } from "src/types/DataTypes.sol";

import { MockStakingNoTransfer } from "./../../../../../mocks/MockStakingNoTransfer.sol";
import { MockStakingReentrant } from "./../../../../../mocks/MockStakingReentrant.sol";
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

    function test_RevertWhen_ArgumentsNotValid()
        external
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
        whenRecipientEligible
        whenAmountValid
        whenMerkleProofValid
        whenArgumentsNotValid
    {
        // Pass arguments that encode a larger amount than approved.
        // The campaign approves CLAIM_AMOUNT, but arguments request more.
        uint128 invalidArgumentsAmount = CLAIM_AMOUNT + 1;

        // The target's transferFrom will fail because the allowance is only CLAIM_AMOUNT.
        vm.expectRevert();
        merkleExecute.claimAndExecute{ value: AIRDROP_MIN_FEE_WEI }({
            index: getIndexInMerkleTree(),
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof(),
            arguments: abi.encode(invalidArgumentsAmount)
        });
    }

    function test_RevertWhen_TargetCallFails()
        external
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
        whenAmountValid
        whenMerkleProofValid
        whenArgumentsValid
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

        vm.expectRevert("Shall not pass!");
        revertingCampaign.claimAndExecute{ value: AIRDROP_MIN_FEE_WEI }(
            getIndexInMerkleTree(), CLAIM_AMOUNT, getMerkleProof(), abi.encode(CLAIM_AMOUNT)
        );
    }

    function test_RevertWhen_Reentrancy()
        external
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
        whenAmountValid
        whenMerkleProofValid
        whenArgumentsValid
    {
        // Deploy the malicious staking contract.
        MockStakingReentrant reentrantStaking = new MockStakingReentrant(dai);

        // Create a campaign with the malicious staking contract as the target.
        MerkleExecute.ConstructorParams memory params = merkleExecuteConstructorParams();
        params.target = address(reentrantStaking);
        params.selector = reentrantStaking.stake.selector;
        params.campaignName = "Reentrant campaign";

        setMsgSender(users.campaignCreator);
        ISablierMerkleExecute reentrantCampaign = createMerkleExecute(params);

        setMsgSender(users.recipient);

        bytes memory arguments =
            abi.encode(getIndexInMerkleTree(), CLAIM_AMOUNT, getMerkleProof(), abi.encode(CLAIM_AMOUNT));

        // The reentrancy attempt should revert with ReentrancyGuardReentrantCall error.
        vm.expectRevert(ReentrancyGuard.ReentrancyGuardReentrantCall.selector);
        reentrantCampaign.claimAndExecute{ value: AIRDROP_MIN_FEE_WEI }(
            getIndexInMerkleTree(), CLAIM_AMOUNT, getMerkleProof(), arguments
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    SUCCESS TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Override the virtual test from Claim_Integration_Test to test MerkleExecute-specific behavior.
    function test_WhenMerkleProofValid()
        external
        override
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
        whenRecipientEligible
        whenAmountValid
    {
        uint256 previousFeeAccrued = address(comptroller).balance;
        uint256 index = getIndexInMerkleTree();
        uint256 initialCampaignBalance = dai.balanceOf(address(merkleExecute));

        vm.expectEmit({ emitter: address(merkleExecute) });
        emit ISablierMerkleExecute.ClaimExecute(index, users.recipient, CLAIM_AMOUNT, address(mockStaking));

        claim();

        assertTrue(merkleExecute.hasClaimed(index), "not claimed");
        assertEq(address(comptroller).balance, previousFeeAccrued + AIRDROP_MIN_FEE_WEI, "fee not collected");
        assertEq(dai.balanceOf(address(merkleExecute)), initialCampaignBalance - CLAIM_AMOUNT, "tokens not transferred");
        assertEq(dai.balanceOf(address(mockStaking)), CLAIM_AMOUNT, "tokens not received by target");
    }

    function test_GivenApproveTarget()
        external
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
        whenRecipientEligible
        whenAmountValid
        whenMerkleProofValid
        whenArgumentsValid
        givenApproveTarget
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

    function test_GivenNotApproveTarget()
        external
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
        whenRecipientEligible
        whenAmountValid
        whenMerkleProofValid
        whenArgumentsValid
        givenNotApproveTarget
    {
        // Deploy the mock staking contract that doesn't require token transfers.
        MockStakingNoTransfer mockStakingNoTransfer = new MockStakingNoTransfer();

        // Create a campaign without approve target.
        MerkleExecute.ConstructorParams memory params = merkleExecuteConstructorParams();
        params.approveTarget = false;
        params.target = address(mockStakingNoTransfer);
        params.selector = mockStakingNoTransfer.stake.selector;

        setMsgSender(users.campaignCreator);
        ISablierMerkleExecute noApproveCampaign = createMerkleExecute(params);

        setMsgSender(users.recipient);

        uint256 previousFeeAccrued = address(comptroller).balance;
        uint256 index = getIndexInMerkleTree();
        uint256 initialCampaignBalance = dai.balanceOf(address(noApproveCampaign));

        // Expect the {ClaimExecute} event to be emitted.
        vm.expectEmit({ emitter: address(noApproveCampaign) });
        emit ISablierMerkleExecute.ClaimExecute(index, users.recipient, CLAIM_AMOUNT, address(mockStakingNoTransfer));

        // Claim and execute.
        noApproveCampaign.claimAndExecute{ value: AIRDROP_MIN_FEE_WEI }(
            index, CLAIM_AMOUNT, getMerkleProof(), abi.encode(CLAIM_AMOUNT)
        );

        // Assert the index is marked as claimed.
        assertTrue(noApproveCampaign.hasClaimed(index), "not claimed");

        // Assert the fee was collected.
        assertEq(address(comptroller).balance, previousFeeAccrued + AIRDROP_MIN_FEE_WEI, "fee not collected");

        // Assert the tokens were NOT transferred (still in campaign).
        assertEq(dai.balanceOf(address(noApproveCampaign)), initialCampaignBalance, "tokens should not be transferred");

        // Assert the target call was executed (stake recorded).
        assertEq(mockStakingNoTransfer.stakedBalance(address(noApproveCampaign)), CLAIM_AMOUNT, "stake not recorded");
    }
}
