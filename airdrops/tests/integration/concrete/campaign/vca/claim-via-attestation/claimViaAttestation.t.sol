// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ERC1271WalletMock } from "@sablier/evm-utils/src/mocks/ERC1271WalletMock.sol";

import { ISablierMerkleSignature } from "src/interfaces/ISablierMerkleSignature.sol";
import { ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";
import { Errors } from "src/libraries/Errors.sol";
import { ClaimType } from "src/types/MerkleBase.sol";

import { ClaimViaAttestation_Integration_Test } from "./../../shared/claim-via-attestation/claimViaAttestation.t.sol";
import { MerkleVCA_Integration_Shared_Test } from "./../MerkleVCA.t.sol";

contract ClaimViaAttestation_MerkleVCA_Integration_Test is
    ClaimViaAttestation_Integration_Test,
    MerkleVCA_Integration_Shared_Test
{
    function setUp() public virtual override(MerkleVCA_Integration_Shared_Test, ClaimViaAttestation_Integration_Test) {
        MerkleVCA_Integration_Shared_Test.setUp();
        ClaimViaAttestation_Integration_Test.setUp();

        // Use the pre-created MerkleVCA campaign with ClaimType.ATTEST.
        merkleVCA = merkleVCAAttest;
        merkleBase = merkleVCAAttest;
    }

    function test_RevertGiven_ClaimTypeDEFAULT() external {
        merkleVCA = ISablierMerkleVCA(address(createMerkleVCA()));
        merkleBase = merkleVCA;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleBase_UnsupportedClaimType.selector, ClaimType.ATTEST, ClaimType.DEFAULT
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
        uint128 forgoneAmount = VCA_FULL_AMOUNT - VCA_CLAIM_AMOUNT;
        uint256 previousFeeAccrued = address(comptroller).balance;
        uint256 index = getIndexInMerkleTree();

        vm.expectEmit({ emitter: address(merkleVCA) });
        emit ISablierMerkleVCA.ClaimVCA({
            index: index,
            recipient: users.recipient,
            claimAmount: VCA_CLAIM_AMOUNT,
            forgoneAmount: forgoneAmount,
            to: users.eve,
            viaSig: false
        });

        expectCallToTransfer({ to: users.eve, value: VCA_CLAIM_AMOUNT });
        claimViaAttestation();

        assertTrue(merkleVCA.hasClaimed(index), "not claimed");
        assertEq(merkleVCA.totalForgoneAmount(), forgoneAmount, "total forgone amount");
        assertEq(address(comptroller).balance, previousFeeAccrued + AIRDROP_MIN_FEE_WEI, "fee collected");
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
        ISablierMerkleSignature(address(merkleVCA)).setAttestor(smartAttestor);
        setMsgSender(users.recipient);

        uint128 forgoneAmount = VCA_FULL_AMOUNT - VCA_CLAIM_AMOUNT;
        uint256 previousFeeAccrued = address(comptroller).balance;
        uint256 index = getIndexInMerkleTree();

        vm.expectEmit({ emitter: address(merkleVCA) });
        emit ISablierMerkleVCA.ClaimVCA({
            index: index,
            recipient: users.recipient,
            claimAmount: VCA_CLAIM_AMOUNT,
            forgoneAmount: forgoneAmount,
            to: users.eve,
            viaSig: false
        });

        expectCallToTransfer({ to: users.eve, value: VCA_CLAIM_AMOUNT });
        claimViaAttestation();

        assertTrue(merkleVCA.hasClaimed(index), "not claimed");
        assertEq(merkleVCA.totalForgoneAmount(), forgoneAmount, "total forgone amount");
        assertEq(address(comptroller).balance, previousFeeAccrued + AIRDROP_MIN_FEE_WEI, "fee collected");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                OVERRIDDEN-FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Overrides the {claimViaAttestation} function defined in {Integration_Test} to use VCA's function.
    function claimViaAttestation(
        uint256 msgValue,
        uint256 index,
        address to,
        uint128 amount,
        bytes32[] memory merkleProof,
        bytes memory attestation
    )
        internal
        override
    {
        ISablierMerkleVCA(address(merkleVCA)).claimViaAttestation{ value: msgValue }(
            index, to, amount, merkleProof, attestation
        );
    }
}
