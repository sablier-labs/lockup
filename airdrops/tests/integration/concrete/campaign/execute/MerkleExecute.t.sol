// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";

import { Integration_Test } from "./../../../Integration.t.sol";

import { CalculateMinFeeWei_Integration_Test } from "./../shared/calculate-min-fee-wei/calculateMinFeeWei.t.sol";
import { Clawback_Integration_Test } from "./../shared/clawback/clawback.t.sol";
import { DomainSeparator_Integration_Test } from "./../shared/domain-separator/domainSeparator.t.sol";
import { HasClaimed_Integration_Test } from "./../shared/has-claimed/hasClaimed.t.sol";
import { HasExpired_Integration_Test } from "./../shared/has-expired/hasExpired.t.sol";
import { LowerMinFeeUSD_Integration_Test } from "./../shared/lower-min-fee-usd/lowerMinFeeUSD.t.sol";

/*//////////////////////////////////////////////////////////////////////////
                             NON-SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

abstract contract MerkleExecute_Integration_Shared_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();

        // Cast the {FactoryMerkleExecute} contract as {ISablierFactoryMerkleBase}
        factoryMerkleBase = factoryMerkleExecute;

        // Cast the {MerkleExecute} contract as {ISablierMerkleBase}
        merkleBase = merkleExecute;

        // Set the campaign type.
        campaignType = "execute";
    }

    /// @dev Override the claim function to use claimAndExecute since MerkleExecute has a different signature.
    /// The recipient is always msg.sender in MerkleExecute.
    function claim() internal virtual override {
        claimAndExecute();
    }

    /// @dev Override to use claimAndExecute with custom parameters.
    function claim(
        uint256 msgValue,
        uint256 index,
        address, /* recipient - ignored, always msg.sender */
        uint128 amount,
        bytes32[] memory merkleProof
    )
        internal
        virtual
        override
    {
        claimAndExecute({
            msgValue: msgValue,
            index: index,
            amount: amount,
            merkleProof: merkleProof,
            arguments: abi.encode(amount)
        });
    }

    /// @dev Override claimTo to use claimAndExecute since MerkleExecute doesn't have claimTo.
    function claimTo() internal virtual override {
        claimAndExecute();
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

contract CalculateMinFeeWei_MerkleExecute_Integration_Test is
    MerkleExecute_Integration_Shared_Test,
    CalculateMinFeeWei_Integration_Test
{
    function setUp() public override(MerkleExecute_Integration_Shared_Test, Integration_Test) {
        MerkleExecute_Integration_Shared_Test.setUp();
    }
}

contract Clawback_MerkleExecute_Integration_Test is MerkleExecute_Integration_Shared_Test, Clawback_Integration_Test {
    function setUp() public override(MerkleExecute_Integration_Shared_Test, Integration_Test) {
        MerkleExecute_Integration_Shared_Test.setUp();
    }
}

contract DomainSeparator_MerkleExecute_Integration_Test is
    MerkleExecute_Integration_Shared_Test,
    DomainSeparator_Integration_Test
{
    function setUp() public override(MerkleExecute_Integration_Shared_Test, Integration_Test) {
        MerkleExecute_Integration_Shared_Test.setUp();
    }
}

contract HasClaimed_MerkleExecute_Integration_Test is
    MerkleExecute_Integration_Shared_Test,
    HasClaimed_Integration_Test
{
    function setUp() public override(MerkleExecute_Integration_Shared_Test, Integration_Test) {
        MerkleExecute_Integration_Shared_Test.setUp();
    }
}

contract HasExpired_MerkleExecute_Integration_Test is
    MerkleExecute_Integration_Shared_Test,
    HasExpired_Integration_Test
{
    function setUp() public override(MerkleExecute_Integration_Shared_Test, Integration_Test) {
        MerkleExecute_Integration_Shared_Test.setUp();

        // Create a campaign with zero expiration to be used in this test.
        campaignWithZeroExpiration =
            ISablierMerkleBase(createMerkleExecute(merkleExecuteConstructorParams({ expiration: 0 })));
    }
}

contract LowerMinFeeUSD_MerkleExecute_Integration_Test is
    MerkleExecute_Integration_Shared_Test,
    LowerMinFeeUSD_Integration_Test
{
    function setUp() public override(MerkleExecute_Integration_Shared_Test, Integration_Test) {
        MerkleExecute_Integration_Shared_Test.setUp();
    }
}
