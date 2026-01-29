// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleLL } from "src/interfaces/ISablierMerkleLL.sol";

import { ClaimViaAttestation_Integration_Test } from "./../../shared/claim-via-attestation/claimViaAttestation.t.sol";
import { MerkleLL_Integration_Shared_Test } from "./../MerkleLL.t.sol";

contract ClaimViaAttestation_MerkleLL_Integration_Test is
    ClaimViaAttestation_Integration_Test,
    MerkleLL_Integration_Shared_Test
{
    function setUp() public virtual override(MerkleLL_Integration_Shared_Test, ClaimViaAttestation_Integration_Test) {
        MerkleLL_Integration_Shared_Test.setUp();
        ClaimViaAttestation_Integration_Test.setUp();
    }

    function test_WhenAttestationValid() external override whenRecipientAddressNotZero givenAttestorSet {
        uint256 expectedStreamId = lockup.nextStreamId();
        uint256 previousFeeAccrued = address(comptroller).balance;
        uint256 index = getIndexInMerkleTree();

        vm.expectEmit({ emitter: address(merkleLL) });
        emit ISablierMerkleLL.ClaimLLWithVesting(
            index,
            users.recipient,
            CLAIM_AMOUNT,
            expectedStreamId,
            users.recipient,
            false
        );

        expectCallToTransferFrom({ from: address(merkleLL), to: address(lockup), value: CLAIM_AMOUNT });
        claimViaAttestation();

        assertTrue(merkleLL.hasClaimed(index), "not claimed");

        assertEq(address(comptroller).balance, previousFeeAccrued + AIRDROP_MIN_FEE_WEI, "fee collected");
    }
}
