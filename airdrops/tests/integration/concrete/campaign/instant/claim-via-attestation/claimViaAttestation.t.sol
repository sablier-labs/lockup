// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ERC1271WalletMock } from "@sablier/evm-utils/src/mocks/ERC1271WalletMock.sol";

import { ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";
import { ISablierMerkleSignature } from "src/interfaces/ISablierMerkleSignature.sol";
import { Errors } from "src/libraries/Errors.sol";
import { ClaimType } from "src/types/DataTypes.sol";

import { ClaimViaAttestation_Integration_Test } from "./../../shared/claim-via-attestation/claimViaAttestation.t.sol";
import { MerkleInstant_Integration_Shared_Test } from "./../MerkleInstant.t.sol";

contract ClaimViaAttestation_MerkleInstant_Integration_Test is
    ClaimViaAttestation_Integration_Test,
    MerkleInstant_Integration_Shared_Test
{
    function setUp()
        public
        virtual
        override(MerkleInstant_Integration_Shared_Test, ClaimViaAttestation_Integration_Test)
    {
        MerkleInstant_Integration_Shared_Test.setUp();
        ClaimViaAttestation_Integration_Test.setUp();

        // Use the pre-created MerkleInstant campaign with ClaimType.ATTEST.
        merkleBase = merkleInstantAttest;
    }

    function test_RevertGiven_ClaimTypeDEFAULT() external {
        merkleBase = merkleInstant;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleBase_InvalidClaimType.selector, ClaimType.ATTEST, ClaimType.DEFAULT
            )
        );
        claimViaAttestation();
    }

    function test_WhenAttestationValid()
        external
        override
        givenClaimTypeNotDefault
        whenToAddressNotZero
        givenAttestorNotZero
        givenAttestorIsEOA
    {
        _test_ClaimViaAttestation();
    }

    function test_WhenAttestorImplementsIERC1271Interface()
        external
        override
        givenClaimTypeNotDefault
        whenToAddressNotZero
        givenAttestorNotZero
        givenAttestorIsContract
    {
        // Deploy an ERC1271 wallet with the EOA attestor as the admin.
        address smartAttestor = address(new ERC1271WalletMock(attestor));

        // Set the attestor to the smart contract.
        setMsgSender(users.campaignCreator);
        ISablierMerkleSignature(address(merkleInstant)).setAttestor(smartAttestor);
        setMsgSender(users.recipient);

        _test_ClaimViaAttestation();
    }

    function _test_ClaimViaAttestation() internal {
        uint256 previousFeeAccrued = address(comptroller).balance;
        uint256 index = getIndexInMerkleTree();

        vm.expectEmit({ emitter: address(merkleBase) });
        emit ISablierMerkleInstant.ClaimInstant(index, users.recipient, CLAIM_AMOUNT, users.eve, false);

        expectCallToTransfer({ to: users.eve, value: CLAIM_AMOUNT });
        claimViaAttestation();

        assertTrue(ISablierMerkleInstant(address(merkleBase)).hasClaimed(index), "not claimed");
        assertEq(address(comptroller).balance, previousFeeAccrued + AIRDROP_MIN_FEE_WEI, "fee collected");
    }
}
