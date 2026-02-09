// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";
import { Errors } from "src/libraries/Errors.sol";
import { ClaimType } from "src/types/MerkleBase.sol";

import { ClaimTo_Integration_Test } from "./../../shared/claim-to/claimTo.t.sol";
import { MerkleInstant_Integration_Shared_Test } from "./../MerkleInstant.t.sol";

contract ClaimTo_MerkleInstant_Integration_Test is ClaimTo_Integration_Test, MerkleInstant_Integration_Shared_Test {
    function setUp() public virtual override(MerkleInstant_Integration_Shared_Test, ClaimTo_Integration_Test) {
        MerkleInstant_Integration_Shared_Test.setUp();
        ClaimTo_Integration_Test.setUp();
    }

    function test_RevertGiven_ClaimTypeATTEST() external {
        merkleBase = merkleInstantAttest;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleBase_UnsupportedClaimType.selector, ClaimType.DEFAULT, ClaimType.ATTEST
            )
        );
        claimTo();
    }

    function test_WhenMerkleProofValid()
        external
        override
        givenClaimTypeNotAttest
        whenToAddressNotZero
        givenCallerNotClaimed
        whenCallerEligible
    {
        uint256 previousFeeAccrued = address(comptroller).balance;
        uint256 index = getIndexInMerkleTree();

        vm.expectEmit({ emitter: address(merkleInstant) });
        emit ISablierMerkleInstant.ClaimInstant(index, users.recipient, CLAIM_AMOUNT, users.eve, false);

        expectCallToTransfer({ to: users.eve, value: CLAIM_AMOUNT });
        expectCallToClaimToWithMsgValue(address(merkleInstant), AIRDROP_MIN_FEE_WEI);
        claimTo();

        assertTrue(merkleInstant.hasClaimed(index), "not claimed");

        assertEq(address(comptroller).balance, previousFeeAccrued + AIRDROP_MIN_FEE_WEI, "fee collected");
    }
}
