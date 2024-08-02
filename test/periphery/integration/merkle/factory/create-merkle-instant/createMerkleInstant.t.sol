// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleInstant } from "src/periphery/interfaces/ISablierMerkleInstant.sol";
import { Errors } from "src/periphery/libraries/Errors.sol";
import { MerkleBase } from "src/periphery/types/DataTypes.sol";

import { Merkle_Integration_Test } from "../../Merkle.t.sol";

contract CreateMerkleInstant_Integration_Test is Merkle_Integration_Test {
    function test_RevertWhen_CampaignNameTooLong() external {
        MerkleBase.ConstructorParams memory baseParams = defaults.baseParams();
        uint256 aggregateAmount = defaults.AGGREGATE_AMOUNT();
        uint256 recipientCount = defaults.RECIPIENT_COUNT();

        baseParams.name = "this string is longer than 32 characters";

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleBase_CampaignNameTooLong.selector, bytes(baseParams.name).length, 32
            )
        );

        merkleFactory.createMerkleInstant({
            baseParams: baseParams,
            aggregateAmount: aggregateAmount,
            recipientCount: recipientCount
        });
    }

    modifier whenCampaignNameNotTooLong() {
        _;
    }

    /// @dev This test works because a default MerkleInstant contract is deployed in {Integration_Test.setUp}
    function test_RevertGiven_CreatedAlready() external whenCampaignNameNotTooLong {
        MerkleBase.ConstructorParams memory baseParams = defaults.baseParams();
        uint256 aggregateAmount = defaults.AGGREGATE_AMOUNT();
        uint256 recipientCount = defaults.RECIPIENT_COUNT();

        // Expect a revert due to CREATE2.
        vm.expectRevert();
        merkleFactory.createMerkleInstant({
            baseParams: baseParams,
            aggregateAmount: aggregateAmount,
            recipientCount: recipientCount
        });
    }

    modifier givenNotCreatedAlready() {
        _;
    }

    function testFuzz_CreateMerkleInstant(
        address admin,
        uint40 expiration
    )
        external
        whenCampaignNameNotTooLong
        givenNotCreatedAlready
    {
        vm.assume(admin != users.admin);
        address expectedMerkleInstant = computeMerkleInstantAddress(admin, expiration);

        MerkleBase.ConstructorParams memory baseParams = defaults.baseParams({
            admin: admin,
            asset_: dai,
            merkleRoot: defaults.MERKLE_ROOT(),
            expiration: expiration
        });

        vm.expectEmit({ emitter: address(merkleFactory) });
        emit CreateMerkleInstant({
            merkleInstant: ISablierMerkleInstant(expectedMerkleInstant),
            baseParams: baseParams,
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT()
        });

        address actualInstant = address(createMerkleInstant(admin, expiration));
        assertGt(actualInstant.code.length, 0, "MerkleInstant contract not created");
        assertEq(actualInstant, expectedMerkleInstant, "MerkleInstant contract does not match computed address");
    }
}
