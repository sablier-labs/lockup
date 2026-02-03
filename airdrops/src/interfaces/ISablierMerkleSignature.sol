// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ClaimType } from "../types/DataTypes.sol";
import { ISablierMerkleBase } from "./ISablierMerkleBase.sol";

/// @title ISablierMerkleSignature
/// @notice Interface for Merkle campaigns that support EIP-712 signature-based claims.
interface ISablierMerkleSignature is ISablierMerkleBase {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the attestor address is set.
    event SetAttestor(address indexed caller, address previousAttestor, address newAttestor);

    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the attestor address used for verifying attestation signatures.
    /// @dev A zero address indicates that the attestor is not set.
    function attestor() external view returns (address);

    /// @notice A flag indicating whether the attestor has been set by the campaign admin. Once set by admin, the
    /// comptroller can no longer change it.
    function attestorSetByAdmin() external view returns (bool);

    /// @notice Retrieves the claim type available in the campaign.
    function claimType() external view returns (ClaimType);

    /// @notice The domain separator, as required by EIP-712 and EIP-1271, used for signing claims to prevent replay
    /// attacks across different campaigns.
    function domainSeparator() external view returns (bytes32);

    /*//////////////////////////////////////////////////////////////////////////
                              STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Sets the attestor address used for verifying attestation signatures.
    ///
    /// @dev Emits a {SetAttestor} event.
    ///
    /// Notes:
    /// - The zero address can be used to disable attestation-based claims.
    /// - If the campaign admin sets the attestor, the comptroller can no longer change it.
    ///
    /// Requirements:
    /// - `msg.sender` must be the comptroller or the campaign admin.
    /// - If `msg.sender` is the comptroller, the admin must not have already set the attestor.
    ///
    /// @param newAttestor The new attestor address. It can be the zero address.
    function setAttestor(address newAttestor) external;
}
