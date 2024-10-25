// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleBase } from "src/periphery/interfaces/ISablierMerkleBase.sol";
import { Clawback_Integration_Test } from "./../shared/clawback/clawback.t.sol";
import { GetFirstClaimTime_Integration_Test } from "./../shared/get-first-claim-time/getFirstClaimTime.t.sol";
import { HasClaimed_Integration_Test } from "./../shared/has-claimed/hasClaimed.t.sol";
import { HasExpired_Integration_Test } from "./../shared/has-expired/hasExpired.t.sol";
import { MerkleCampaign_Integration_Test } from "./../MerkleCampaign.t.sol";
import { WithdrawFees_Integration_Test } from "./../shared/withdraw-fees/withdrawFees.t.sol";

/*//////////////////////////////////////////////////////////////////////////
                             NON-SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

abstract contract MerkleLL_Integration_Shared_Test is MerkleCampaign_Integration_Test {
    function setUp() public virtual override {
        MerkleCampaign_Integration_Test.setUp();

        // Cast the {MerkleLL} contract as {ISablierMerkleBase}
        merkleBase = ISablierMerkleBase(merkleLL);
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

contract Clawback_MerkleLL_Integration_Test is MerkleLL_Integration_Shared_Test, Clawback_Integration_Test {
    function setUp() public override(MerkleLL_Integration_Shared_Test, MerkleCampaign_Integration_Test) {
        MerkleLL_Integration_Shared_Test.setUp();
    }
}

contract GetFirstClaimTime_MerkleLL_Integration_Test is
    MerkleLL_Integration_Shared_Test,
    GetFirstClaimTime_Integration_Test
{
    function setUp() public override(MerkleLL_Integration_Shared_Test, MerkleCampaign_Integration_Test) {
        MerkleLL_Integration_Shared_Test.setUp();
    }
}

contract HasClaimed_MerkleLL_Integration_Test is MerkleLL_Integration_Shared_Test, HasClaimed_Integration_Test {
    function setUp() public override(MerkleLL_Integration_Shared_Test, MerkleCampaign_Integration_Test) {
        MerkleLL_Integration_Shared_Test.setUp();
    }
}

contract HasExpired_MerkleLL_Integration_Test is MerkleLL_Integration_Shared_Test, HasExpired_Integration_Test {
    function setUp() public override(MerkleLL_Integration_Shared_Test, MerkleCampaign_Integration_Test) {
        MerkleLL_Integration_Shared_Test.setUp();
    }
}

contract WithdrawFees_MerkleLL_Integration_Test is MerkleLL_Integration_Shared_Test, WithdrawFees_Integration_Test {
    function setUp() public override(MerkleLL_Integration_Shared_Test, MerkleCampaign_Integration_Test) {
        MerkleLL_Integration_Shared_Test.setUp();
    }
}
