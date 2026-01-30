// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { SignatureChecker } from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import { ISablierMerkleSignature } from "./../interfaces/ISablierMerkleSignature.sol";
import { Errors } from "./../libraries/Errors.sol";
import { SignatureHash } from "./../libraries/SignatureHash.sol";
import { ClaimType, MerkleBase } from "./../types/DataTypes.sol";
import { SablierMerkleBase } from "./SablierMerkleBase.sol";

/// @title SablierMerkleSignature
/// @notice Abstract contract providing EIP-712 signature verification for Merkle campaigns.
abstract contract SablierMerkleSignature is
    ISablierMerkleSignature, // 1 inherited component
    SablierMerkleBase // 2 inherited components
{
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Cache the chain ID in order to invalidate the cached domain separator if the chain ID changes in case of a
    /// chain split.
    uint256 private immutable _CACHED_CHAIN_ID;

    /// @dev The domain separator, as required by EIP-712 and EIP-1271, used for signing claim to prevent replay attacks
    /// across different campaigns.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;

    /// @inheritdoc ISablierMerkleSignature
    address public override attestor;

    /// @inheritdoc ISablierMerkleSignature
    bool public override attestorSetByAdmin;

    /// @inheritdoc ISablierMerkleSignature
    ClaimType public override claimType;

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Modifier to check that the provided claim type matches the campaign's claim type.
    modifier checkClaimType(ClaimType claimType_) {
        _checkClaimType(claimType_);
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Constructs the contract by initializing the immutable state variables.
    constructor(
        MerkleBase.ConstructorParams memory baseParams,
        address attestor_,
        address campaignCreator,
        ClaimType claimType_,
        address comptroller
    )
        SablierMerkleBase(baseParams, campaignCreator, comptroller)
    {
        // Cache the chain ID.
        _CACHED_CHAIN_ID = block.chainid;

        // Compute and store the domain separator to be used for claiming using an EIP-712 or EIP-1271 signature.
        _CACHED_DOMAIN_SEPARATOR = keccak256(
            abi.encode(SignatureHash.DOMAIN_TYPEHASH, SignatureHash.PROTOCOL_NAME, block.chainid, address(this))
        );

        // Effect: set the initial attestor.
        attestor = attestor_;

        // Effect: set the claim type.
        claimType = claimType_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleSignature
    function domainSeparator() external view override returns (bytes32) {
        return _domainSeparator();
    }

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleSignature
    function setAttestor(address newAttestor) external override {
        bool isCallerAdmin = msg.sender == admin;
        bool isCallerComptroller = msg.sender == COMPTROLLER;

        // Check: the caller is the comptroller or the admin.
        if (!isCallerAdmin && !isCallerComptroller) {
            revert Errors.SablierMerkleSignature_CallerNotComptrollerOrAdmin({
                comptroller: COMPTROLLER,
                admin: admin,
                caller: msg.sender
            });
        }

        // Check: if the caller is the comptroller, the admin must not have already set the attestor.
        if (isCallerComptroller && attestorSetByAdmin) {
            revert Errors.SablierMerkleSignature_AttestorAlreadySetByAdmin();
        }

        address previousAttestor = attestor;

        // Effect: set the new attestor.
        attestor = newAttestor;

        // Effect: if the caller is the admin, mark that the admin has set the attestor.
        if (isCallerAdmin && !attestorSetByAdmin) {
            attestorSetByAdmin = true;
        }

        // Log the event.
        emit SetAttestor({ caller: msg.sender, previousAttestor: previousAttestor, newAttestor: newAttestor });
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Verifies the attestation signature against the recipient. It supports both EIP-712 and EIP-1271 signatures.
    function _checkAttestation(address recipient, bytes calldata attestation) internal view {
        // Get the attestor from storage.
        address attestor_ = attestor;

        // Check: attestor is set.
        if (attestor_ == address(0)) {
            revert Errors.SablierMerkleSignature_AttestorNotSet();
        }

        // Create Identity struct hash.
        bytes32 identityHash = keccak256(abi.encode(SignatureHash.IDENTITY_TYPEHASH, recipient));

        // Verify signature matches attestor.
        _verifySignature({ signer: attestor_, structHash: identityHash, signature: attestation });
    }

    /// @dev Verifies the signature against the provided parameters. It supports both EIP-712 and EIP-1271 signatures.
    function _checkSignature(
        uint256 index,
        address recipient,
        address to,
        uint128 amount,
        uint40 validFrom,
        bytes calldata signature
    )
        internal
        view
    {
        // Encode the parameters using claim type hash and hash it.
        bytes32 claimHash = keccak256(abi.encode(SignatureHash.CLAIM_TYPEHASH, index, recipient, to, amount, validFrom));

        // Verify signature matches recipient.
        _verifySignature({ signer: recipient, structHash: claimHash, signature: signature });

        // Check: the `validFrom` is less than or equal to the current block timestamp.
        if (validFrom > uint40(block.timestamp)) {
            revert Errors.SablierMerkleSignature_SignatureNotYetValid(validFrom, uint40(block.timestamp));
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PRIVATE READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks that the provided claim type matches the campaign's claim type.
    function _checkClaimType(ClaimType claimType_) private view {
        if (claimType != claimType_) {
            revert Errors.SablierMerkleSignature_InvalidClaimType({
                claimTypeCalled: claimType_,
                claimTypeSupported: claimType
            });
        }
    }

    /// @dev Verifies an EIP-712 or EIP-1271 signature against a signer and struct hash.
    /// @param signer The expected signer address.
    /// @param structHash The hash of the typed data struct.
    /// @param signature The signature to verify.
    function _verifySignature(address signer, bytes32 structHash, bytes calldata signature) private view {
        // Create EIP-712 digest.
        bytes32 digest =
            MessageHashUtils.toTypedDataHash({ domainSeparator: _domainSeparator(), structHash: structHash });

        // Supports both EOA signatures (ECDSA recovery) and smart contract signatures (EIP-1271).
        bool isSignatureValid =
            SignatureChecker.isValidSignatureNow({ signer: signer, hash: digest, signature: signature });

        // Check: `isSignatureValid` is true.
        if (!isSignatureValid) {
            revert Errors.SablierMerkleSignature_InvalidSignature();
        }
    }

    /// @dev Returns the domain separator for the current chain.
    function _domainSeparator() private view returns (bytes32) {
        // If the current chain ID is the same as the cached chain ID, return the cached domain separator.
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        }
        // Otherwise, compute the domain separator for the current chain ID.
        else {
            return keccak256(
                abi.encode(SignatureHash.DOMAIN_TYPEHASH, SignatureHash.PROTOCOL_NAME, block.chainid, address(this))
            );
        }
    }
}
