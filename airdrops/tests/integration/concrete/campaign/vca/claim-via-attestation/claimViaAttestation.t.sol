// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ERC1271WalletMock } from "@sablier/evm-utils/src/mocks/ERC1271WalletMock.sol";

import { ISablierMerkleSignature } from "src/interfaces/ISablierMerkleSignature.sol";
import { ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";

import { ClaimViaAttestation_Integration_Test } from "./../../shared/claim-via-attestation/claimViaAttestation.t.sol";
import { MerkleVCA_Integration_Shared_Test } from "./../MerkleVCA.t.sol";

contract ClaimViaAttestation_MerkleVCA_Integration_Test is
    ClaimViaAttestation_Integration_Test,
    MerkleVCA_Integration_Shared_Test
{
    function setUp() public virtual override(MerkleVCA_Integration_Shared_Test, ClaimViaAttestation_Integration_Test) {
        MerkleVCA_Integration_Shared_Test.setUp();
        ClaimViaAttestation_Integration_Test.setUp();
    }

    function test_WhenAttestationValid()
        external
        override
        whenRecipientAddressNotZero
        givenAttestorSet
        givenAttestorIsEOA
    {
        _test_ClaimViaAttestation();
    }

    function test_WhenAttestorImplementsIERC1271Interface()
        external
        override
        whenRecipientAddressNotZero
        givenAttestorSet
        givenAttestorIsContract
    {
        // Deploy an ERC1271 wallet with the EOA attestor as the admin.
        address smartAttestor = address(new ERC1271WalletMock(attestor));

        // Set the attestor to the smart contract.
        ISablierMerkleSignature(address(merkleVCA)).setAttestor(smartAttestor);

        _test_ClaimViaAttestation();
    }

    function _test_ClaimViaAttestation() internal {
        uint128 forgoneAmount = VCA_FULL_AMOUNT - VCA_CLAIM_AMOUNT;
        uint256 previousFeeAccrued = address(comptroller).balance;
        uint256 index = getIndexInMerkleTree();

        vm.expectEmit({ emitter: address(merkleVCA) });
        emit ISablierMerkleVCA.ClaimVCA({
            index: index,
            recipient: users.recipient,
            claimAmount: VCA_CLAIM_AMOUNT,
            forgoneAmount: forgoneAmount,
            to: users.recipient,
            viaSig: false
        });

        expectCallToTransfer({ to: users.recipient, value: VCA_CLAIM_AMOUNT });
        claimViaAttestation();

        assertTrue(merkleVCA.hasClaimed(index), "not claimed");
        assertEq(merkleVCA.totalForgoneAmount(), forgoneAmount, "total forgone amount");
        assertEq(address(comptroller).balance, previousFeeAccrued + AIRDROP_MIN_FEE_WEI, "fee collected");
    }
}
