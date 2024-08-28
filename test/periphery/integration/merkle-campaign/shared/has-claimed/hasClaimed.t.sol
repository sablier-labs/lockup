// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { MerkleCampaign_Integration_Shared_Test } from "../../shared/MerkleCampaign.t.sol";

abstract contract HasClaimed_Integration_Test is MerkleCampaign_Integration_Shared_Test {
    function setUp() public virtual override {
        MerkleCampaign_Integration_Shared_Test.setUp();
    }

    function test_WhenIndexNotInMerkleTree() external {
        uint256 indexNotInTree = 1337e18;
        assertFalse(merkleBase.hasClaimed(indexNotInTree), "claimed");
    }

    function test_GivenRecipientNotClaimed() external whenIndexInMerkleTree {
        // It should return false.
        assertFalse(merkleBase.hasClaimed(defaults.INDEX1()), "claimed");
    }

    function test_GivenRecipientClaimed() external whenIndexInMerkleTree {
        // Make the first claim to set `_firstClaimTime`.
        claim();

        // It should return true.
        assertTrue(merkleBase.hasClaimed(defaults.INDEX1()), "not claimed");
    }
}
