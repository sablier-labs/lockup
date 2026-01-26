// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { ISablierMerkleExecute } from "src/interfaces/ISablierMerkleExecute.sol";
import { Errors } from "src/libraries/Errors.sol";
import { MerkleExecute } from "src/types/DataTypes.sol";

import { MockReentrantStaking } from "../../../../../mocks/MockReentrantStaking.sol";
import { MockStakingNoTransfer } from "../../../../../mocks/MockStakingNoTransfer.sol";
import { MerkleExecute_Integration_Shared_Test } from "./../MerkleExecute.t.sol";

contract ClaimAndExecute_MerkleExecute_Integration_Test is MerkleExecute_Integration_Shared_Test {
    function setUp() public virtual override {
        MerkleExecute_Integration_Shared_Test.setUp();

        // Make the recipient the caller.
        setMsgSender(users.recipient);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    REVERT TESTS
    //////////////////////////////////////////////////////////////////////////*/

    function test_RevertGiven_CampaignStartTimeInFuture() external {
        uint40 warpTime = CAMPAIGN_START_TIME - 1 seconds;
        vm.warp({ newTimestamp: warpTime });

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierMerkleBase_CampaignNotStarted.selector, warpTime, CAMPAIGN_START_TIME)
        );
        claimAndExecute();
    }

    function test_RevertGiven_CampaignExpired() external givenCampaignStartTimeNotInFuture {
        uint40 warpTime = EXPIRATION + 1 seconds;
        vm.warp({ newTimestamp: warpTime });

        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_CampaignExpired.selector, warpTime, EXPIRATION));
        claimAndExecute();
    }

    function test_RevertGiven_MsgValueLessThanFee() external givenCampaignStartTimeNotInFuture givenCampaignNotExpired {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierMerkleBase_InsufficientFeePayment.selector, 0, AIRDROP_MIN_FEE_WEI)
        );
        claimAndExecute({
            msgValue: 0,
            index: getIndexInMerkleTree(),
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof(),
            arguments: abi.encode(CLAIM_AMOUNT)
        });
    }

    function test_RevertGiven_IndexClaimed()
        external
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
    {
        claimAndExecute();

        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_IndexClaimed.selector, getIndexInMerkleTree()));
        claimAndExecute();
    }

    function test_RevertWhen_IndexNotValid()
        external
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
    {
        uint256 invalidIndex = 1337;

        vm.expectRevert(Errors.SablierMerkleBase_InvalidProof.selector);
        claimAndExecute({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: invalidIndex,
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof(),
            arguments: abi.encode(CLAIM_AMOUNT)
        });
    }

    function test_RevertWhen_AmountNotValid()
        external
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
    {
        uint128 invalidAmount = 1337;

        vm.expectRevert(Errors.SablierMerkleBase_InvalidProof.selector);
        claimAndExecute({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            amount: invalidAmount,
            merkleProof: getMerkleProof(),
            arguments: abi.encode(invalidAmount)
        });
    }

    function test_RevertWhen_MerkleProofNotValid()
        external
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
        whenAmountValid
    {
        vm.expectRevert(Errors.SablierMerkleBase_InvalidProof.selector);
        claimAndExecute({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof(users.unknownRecipient),
            arguments: abi.encode(CLAIM_AMOUNT)
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
    {
        // Create a campaign with a reverting target function.
        MerkleExecute.ConstructorParams memory params = merkleExecuteConstructorParams({
            campaignCreator: users.campaignCreator,
            campaignStartTime: CAMPAIGN_START_TIME,
            expiration: EXPIRATION,
            merkleRoot: MERKLE_ROOT,
            tokenAddress: dai,
            targetAddress: address(mockStaking),
            selector: mockStaking.revertingFunction.selector,
            approveTarget: true
        });
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
    {
        // Deploy the malicious staking contract.
        MockReentrantStaking reentrantStaking = new MockReentrantStaking(dai);

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

    function test_GivenApproveTarget()
        external
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
        whenAmountValid
        givenApproveTarget
    {
        uint256 previousFeeAccrued = address(comptroller).balance;
        uint256 index = getIndexInMerkleTree();
        uint256 initialCampaignBalance = dai.balanceOf(address(merkleExecute));

        // Expect the {ClaimExecute} event to be emitted.
        vm.expectEmit({ emitter: address(merkleExecute) });
        emit ISablierMerkleExecute.ClaimExecute(index, users.recipient, CLAIM_AMOUNT, address(mockStaking));

        // Claim and execute.
        claimAndExecute();

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
        whenAmountValid
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
