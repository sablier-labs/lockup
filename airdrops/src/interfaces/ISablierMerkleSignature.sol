// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ISablierMerkleBase } from "./ISablierMerkleBase.sol";

/// @title ISablierMerkleSignature
/// @notice Interface for Merkle campaigns that support EIP-712 signature-based claims.
interface ISablierMerkleSignature is ISablierMerkleBase {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the attestor address is set.
    event SetAttestor(address indexed caller, address indexed previousAttestor, address indexed newAttestor);

    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the attestor address used for verifying attestation signatures.
    function attestor() external view returns (address);

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
    /// - `msg.sender` must either be the comptroller or the campaign admin.
    ///
    /// @param newAttestor The new attestor address. If zero, the attestor from the comptroller will be used.
    function setAttestor(address newAttestor) external;
}
