// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { SablierMerkleSignature } from "./abstracts/SablierMerkleSignature.sol";
import { ISablierMerkleInstant } from "./interfaces/ISablierMerkleInstant.sol";
import { MerkleBase, MerkleInstant } from "./types/DataTypes.sol";

/*

███████╗ █████╗ ██████╗ ██╗     ██╗███████╗██████╗
██╔════╝██╔══██╗██╔══██╗██║     ██║██╔════╝██╔══██╗
███████╗███████║██████╔╝██║     ██║█████╗  ██████╔╝
╚════██║██╔══██║██╔══██╗██║     ██║██╔══╝  ██╔══██╗
███████║██║  ██║██████╔╝███████╗██║███████╗██║  ██║
╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝

███╗   ███╗███████╗██████╗ ██╗  ██╗██╗     ███████╗    ██╗███╗   ██╗███████╗████████╗ █████╗ ███╗   ██╗████████╗
████╗ ████║██╔════╝██╔══██╗██║ ██╔╝██║     ██╔════╝    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗████╗  ██║╚══██╔══╝
██╔████╔██║█████╗  ██████╔╝█████╔╝ ██║     █████╗      ██║██╔██╗ ██║███████╗   ██║   ███████║██╔██╗ ██║   ██║
██║╚██╔╝██║██╔══╝  ██╔══██╗██╔═██╗ ██║     ██╔══╝      ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║╚██╗██║   ██║
██║ ╚═╝ ██║███████╗██║  ██║██║  ██╗███████╗███████╗    ██║██║ ╚████║███████║   ██║   ██║  ██║██║ ╚████║   ██║
╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝    ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝

*/

/// @title SablierMerkleInstant
/// @notice See the documentation in {ISablierMerkleInstant}.
contract SablierMerkleInstant is
    ISablierMerkleInstant, // 3 inherited components
    SablierMerkleSignature // 3 inherited components
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Constructs the contract by initializing the immutable state variables.
    constructor(
        MerkleInstant.ConstructorParams memory campaignParams,
        address campaignCreator,
        address comptroller
    )
        SablierMerkleSignature(
            MerkleBase.ConstructorParams({
                campaignName: campaignParams.campaignName,
                campaignStartTime: campaignParams.campaignStartTime,
                expiration: campaignParams.expiration,
                initialAdmin: campaignParams.initialAdmin,
                ipfsCID: campaignParams.ipfsCID,
                merkleRoot: campaignParams.merkleRoot,
                token: campaignParams.token
            }),
            campaignCreator,
            comptroller
        )
    { }

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleInstant
    function claim(
        uint256 index,
        address recipient,
        uint128 amount,
        bytes32[] calldata merkleProof
    )
        external
        payable
        override
    {
        // Check, Effect and Interaction: Pre-process the claim parameters on behalf of the recipient.
        _preProcessClaim(index, recipient, amount, merkleProof);

        // Interaction: Post-process the claim parameters on behalf of the recipient.
        _postProcessClaim({ index: index, recipient: recipient, to: recipient, amount: amount, viaSig: false });
    }

    /// @inheritdoc ISablierMerkleInstant
    function claimTo(
        uint256 index,
        address to,
        uint128 amount,
        bytes32[] calldata merkleProof
    )
        external
        payable
        override
        notZeroAddress(to)
    {
        // Check, Effect and Interaction: Pre-process the claim parameters on behalf of `msg.sender`.
        _preProcessClaim({ index: index, recipient: msg.sender, amount: amount, merkleProof: merkleProof });

        // Interaction: Post-process the claim parameters on behalf of `msg.sender`.
        _postProcessClaim({ index: index, recipient: msg.sender, to: to, amount: amount, viaSig: false });
    }

    /// @inheritdoc ISablierMerkleInstant
    function claimViaAttestation(
        uint256 index,
        uint128 amount,
        bytes32[] calldata merkleProof,
        bytes calldata attestation
    )
        external
        payable
        override
    {
        // Check: verify attestation signature matches attestor from storage.
        _checkAttestation(msg.sender, attestation);

        // Check, Effect and Interaction: Pre-process the claim parameters on behalf of `msg.sender`.
        _preProcessClaim({ index: index, recipient: msg.sender, amount: amount, merkleProof: merkleProof });

        // Interaction: Post-process the claim parameters on behalf of `msg.sender`.
        _postProcessClaim({ index: index, recipient: msg.sender, to: msg.sender, amount: amount, viaSig: false });
    }

    /// @inheritdoc ISablierMerkleInstant
    function claimViaSig(
        uint256 index,
        address recipient,
        address to,
        uint128 amount,
        uint40 validFrom,
        bytes32[] calldata merkleProof,
        bytes calldata signature
    )
        external
        payable
        override
        notZeroAddress(to)
    {
        // Check: the signature is valid and the recovered signer matches the recipient.
        _checkSignature(index, recipient, to, amount, validFrom, signature);

        // Check, Effect and Interaction: Pre-process the claim parameters on behalf of the recipient.
        _preProcessClaim(index, recipient, amount, merkleProof);

        // Interaction: Post-process the claim parameters on behalf of the recipient.
        _postProcessClaim({ index: index, recipient: recipient, to: to, amount: amount, viaSig: true });
    }

    /*//////////////////////////////////////////////////////////////////////////
                          PRIVATE STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Post-processes the claim execution by handling the tokens transfer and emitting an event.
    function _postProcessClaim(uint256 index, address recipient, address to, uint128 amount, bool viaSig) private {
        // Interaction: withdraw the tokens to the `to` address.
        TOKEN.safeTransfer(to, amount);

        // Emit claim event.
        emit ClaimInstant(index, recipient, amount, to, viaSig);
    }
}
