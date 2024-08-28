// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleBase } from "src/periphery/interfaces/ISablierMerkleBase.sol";

import { MerkleCampaign_Integration_Shared_Test } from "../../shared/MerkleCampaign.t.sol";

abstract contract HasExpired_Integration_Test is MerkleCampaign_Integration_Shared_Test {
    function setUp() public virtual override {
        MerkleCampaign_Integration_Shared_Test.setUp();
    }

    function test_WhenExpirationZero() external {
        ISablierMerkleBase campaignWithZeroExpiry = ISablierMerkleBase(createMerkleLT({ expiration: 0 }));
        assertFalse(campaignWithZeroExpiry.hasExpired(), "campaign expired");
    }

    function test_WhenExpirationInPast() external view whenExpirationNotZero {
        assertFalse(merkleBase.hasExpired(), "campaign expired");
    }

    function test_WhenTheExpirationInPresent() external whenExpirationNotZero {
        vm.warp({ newTimestamp: defaults.EXPIRATION() });
        assertTrue(merkleBase.hasExpired(), "campaign not expired");
    }

    function test_WhenTheExpirationInFuture() external whenExpirationNotZero {
        vm.warp({ newTimestamp: defaults.EXPIRATION() + 1 seconds });
        assertTrue(merkleBase.hasExpired(), "campaign not expired");
    }
}
