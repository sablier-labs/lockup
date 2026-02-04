// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Noop } from "@sablier/evm-utils/src/mocks/Noop.sol";

import { ISablierMerkleSignature } from "src/interfaces/ISablierMerkleSignature.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract ClaimViaAttestation_Integration_Test is Integration_Test {
    function setUp() public virtual override {
        // Make `users.recipient` the caller for this test since `claimViaAttestation` uses `msg.sender` as the
        // recipient.
        setMsgSender(users.recipient);
    }

    function test_RevertGiven_AttestorNotSet() external {
        // Remove the attestor from the campaign as well as the comptroller.
        setMsgSender(users.campaignCreator);
        ISablierMerkleSignature(address(merkleBase)).setAttestor(address(0));
        setMsgSender(admin);
        comptroller.setAttestor(address(0));

        // Change caller back to the recipient.
        setMsgSender(users.recipient);

        vm.expectRevert(Errors.SablierMerkleSignature_AttestorNotSet.selector);
        claimViaAttestation({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof(),
            attestation: abi.encode(0)
        });
    }

    function test_RevertWhen_AttestationInvalid() external givenAttestorSet givenAttestorIsEOA {
        // Generate an invalid attestation.
        bytes memory invalidAttestation = vm.randomBytes(65);

        vm.expectRevert(Errors.SablierMerkleSignature_InvalidSignature.selector);
        claimViaAttestation({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof(),
            attestation: invalidAttestation
        });
    }

    /// @dev Since the implementation of `claimViaAttestation()` differs in each Merkle campaign, we declare this
    /// virtual dummy test. The child contracts implement it.
    function test_WhenAttestationValid() external virtual givenAttestorSet givenAttestorIsEOA {
        // The child contract must check that the claim event is emitted.
        // It should mark the index as claimed.
        // It should transfer the fee from the caller address to the comptroller.
    }

    function test_RevertWhen_AttestorNotImplementIERC1271Interface() external givenAttestorSet givenAttestorIsContract {
        // Deploy a contract that does not implement IERC1271.
        address smartAttestorWithoutIERC1271 = address(new Noop());

        // Set the attestor to the contract without IERC1271.
        setMsgSender(users.campaignCreator);
        ISablierMerkleSignature(address(merkleBase)).setAttestor(smartAttestorWithoutIERC1271);
        setMsgSender(users.recipient);

        vm.expectRevert(Errors.SablierMerkleSignature_InvalidSignature.selector);
        claimViaAttestation({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof(),
            attestation: abi.encode(0)
        });
    }

    /// @dev Since the implementation of `claimViaAttestation()` differs in each Merkle campaign, we declare this
    /// virtual dummy test. The child contracts implement it.
    function test_WhenAttestorImplementsIERC1271Interface() external virtual givenAttestorSet givenAttestorIsContract {
        // The child contract must check that the claim event is emitted.
        // It should mark the index as claimed.
        // It should transfer the fee from the caller address to the comptroller.
    }
}
