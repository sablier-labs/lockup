// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";
import { ISablierMerkleSignature } from "src/interfaces/ISablierMerkleSignature.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract ClaimViaAttestation_Integration_Test is Integration_Test {
    function setUp() public virtual override {
        // Make `users.campaignCreator` the caller for this test.
        setMsgSender(users.campaignCreator);
    }

    function test_RevertWhen_RecipientAddressZero() external {
        vm.expectRevert(Errors.SablierMerkleBase_ToZeroAddress.selector);
        claimViaAttestation({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            recipient: address(0),
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof(),
            attestation: abi.encode(0)
        });
    }

    function test_RevertGiven_AttestorNotSet() external whenRecipientAddressNotZero {
        // Remove the attestor from the campaign.
        ISablierMerkleSignature(address(merkleBase)).setAttestor(address(0));

        vm.expectRevert(Errors.SablierMerkleSignature_AttestorNotSet.selector);
        claimViaAttestation({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            recipient: users.recipient,
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof(),
            attestation: abi.encode(0)
        });
    }

    function test_RevertWhen_AttestationInvalid() external whenRecipientAddressNotZero givenAttestorSet {
        // Generate an invalid attestation.
        bytes memory invalidAttestation = vm.randomBytes(65);

        vm.expectRevert(Errors.SablierMerkleSignature_InvalidSignature.selector);
        claimViaAttestation({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            recipient: users.recipient,
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof(),
            attestation: invalidAttestation
        });
    }

    /// @dev Since the implementation of `claimViaAttestation()` differs in each Merkle campaign, we declare this virtual
    /// dummy test. The child contracts implement it.
    function test_WhenAttestationValid()
        external
        virtual
        whenRecipientAddressNotZero
        givenAttestorSet
    {
        // The child contract must check that the claim event is emitted.
        // It should mark the index as claimed.
        // It should transfer the fee from the caller address to the comptroller.
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenRecipientAddressNotZero() {
        _;
    }
}
