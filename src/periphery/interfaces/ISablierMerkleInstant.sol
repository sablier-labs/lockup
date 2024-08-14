// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ISablierMerkleBase } from "./ISablierMerkleBase.sol";

/// @title ISablierMerkleInstant
/// @notice MerkleInstant enables instant airdrop campaigns.
interface ISablierMerkleInstant is ISablierMerkleBase {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a recipient claims an instant airdrop.
    event Claim(uint256 index, address indexed recipient, uint128 amount);
}
