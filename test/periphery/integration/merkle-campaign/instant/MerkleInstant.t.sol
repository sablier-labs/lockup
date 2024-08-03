// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleBase } from "src/periphery/interfaces/ISablierMerkleBase.sol";

import { Clawback_Integration_Test } from "../shared/clawback/clawback.t.sol";
import { GetFirstClaimTime_Integration_Test } from "../shared/get-first-claim-time/getFirstClaimTime.t.sol";
import { HasClaimed_Integration_Test } from "../shared/has-claimed/hasClaimed.t.sol";
import { HasExpired_Integration_Test } from "../shared/has-expired/hasExpired.t.sol";
import { MerkleCampaign_Integration_Shared_Test } from "../shared/MerkleCampaign.t.sol";

/*//////////////////////////////////////////////////////////////////////////
                             NON-SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

abstract contract MerkleInstant_Integration_Shared_Test is MerkleCampaign_Integration_Shared_Test {
    function setUp() public virtual override {
        MerkleCampaign_Integration_Shared_Test.setUp();

        // Cast the {merkleInstant} contract as {ISablierMerkleBase}
        merkleBase = ISablierMerkleBase(merkleInstant);
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

contract Clawback_MerkleLInstant_Integration_Test is
    Clawback_Integration_Test,
    MerkleInstant_Integration_Shared_Test
{
    modifier afterFirstClaim() override {
        // Make the first claim to set `_firstClaimTime`.
        claimInstant();
        _;
    }

    function setUp() public override(Clawback_Integration_Test, MerkleInstant_Integration_Shared_Test) {
        Clawback_Integration_Test.setUp();
        MerkleInstant_Integration_Shared_Test.setUp();
    }
}

contract GetFirstClaimTime_MerkleLInstant_Integration_Test is
    GetFirstClaimTime_Integration_Test,
    MerkleInstant_Integration_Shared_Test
{
    modifier afterFirstClaim() override {
        // Make the first claim to set `_firstClaimTime`.
        claimInstant();
        _;
    }

    function setUp() public override(GetFirstClaimTime_Integration_Test, MerkleInstant_Integration_Shared_Test) {
        GetFirstClaimTime_Integration_Test.setUp();
        MerkleInstant_Integration_Shared_Test.setUp();
    }
}

contract HasClaimed_MerkleLInstant_Integration_Test is
    HasClaimed_Integration_Test,
    MerkleInstant_Integration_Shared_Test
{
    modifier givenRecipientHasClaimed() override {
        // Make the first claim to set `_firstClaimTime`.
        claimInstant();
        _;
    }

    function setUp() public override(HasClaimed_Integration_Test, MerkleInstant_Integration_Shared_Test) {
        HasClaimed_Integration_Test.setUp();
        MerkleInstant_Integration_Shared_Test.setUp();
    }
}

contract HasExpired_MerkleLInstant_Integration_Test is
    HasExpired_Integration_Test,
    MerkleInstant_Integration_Shared_Test
{
    modifier createMerkleCampaignWithZeroExpiry() override {
        campaignWithZeroExpiry = ISablierMerkleBase(createMerkleInstant({ expiration: 0 }));
        _;
    }

    function setUp() public override(HasExpired_Integration_Test, MerkleInstant_Integration_Shared_Test) {
        HasExpired_Integration_Test.setUp();
        MerkleInstant_Integration_Shared_Test.setUp();
    }
}
