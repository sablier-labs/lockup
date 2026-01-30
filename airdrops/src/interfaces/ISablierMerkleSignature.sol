// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ClaimType } from "../types/DataTypes.sol";
import { ISablierMerkleBase } from "./ISablierMerkleBase.sol";

/// @title ISablierMerkleSignature
/// @notice Abstract contract providing helper functions for verifying EIP-712 and EIP-1271 signatures for Merkle
/// campaigns.
interface ISablierMerkleSignature is ISablierMerkleBase {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the address of the attestor is set in this contract.
    event SetAttestor(address indexed caller, address indexed previousAttestor, address indexed newAttestor);

    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the attestor address used for creating attestation signatures.
    function attestor() external view returns (address);

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
    /// Requirements:
    /// - `msg.sender` must be either the comptroller or the campaign admin.
    ///
    /// @param newAttestor The new attestor address. If zero, the attestor from the comptroller will be used.
    function setAttestor(address newAttestor) external;
}
