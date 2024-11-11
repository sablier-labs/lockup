// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleFactory } from "src/periphery/interfaces/ISablierMerkleFactory.sol";
import { ISablierMerkleLT } from "src/periphery/interfaces/ISablierMerkleLT.sol";
import { Errors } from "src/periphery/libraries/Errors.sol";
import { MerkleBase, MerkleLT } from "src/periphery/types/DataTypes.sol";

import { MerkleCampaign_Integration_Test } from "../../MerkleCampaign.t.sol";

contract CreateMerkleLT_Integration_Test is MerkleCampaign_Integration_Test {
    function test_RevertWhen_NameTooLong() external {
        MerkleBase.ConstructorParams memory baseParams = defaults.baseParams();
        bool cancelable = defaults.CANCELABLE();
        bool transferable = defaults.TRANSFERABLE();
        uint40 streamStartTime = defaults.STREAM_START_TIME_ZERO();
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages = defaults.tranchesWithPercentages();
        uint256 aggregateAmount = defaults.AGGREGATE_AMOUNT();
        uint256 recipientCount = defaults.RECIPIENT_COUNT();

        baseParams.name = "this string is longer than 32 characters";

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleBase_CampaignNameTooLong.selector, bytes(baseParams.name).length, 32
            )
        );

        merkleFactory.createMerkleLT(
            baseParams,
            lockup,
            cancelable,
            transferable,
            streamStartTime,
            tranchesWithPercentages,
            aggregateAmount,
            recipientCount
        );
    }

    /// @dev This test works because a default MerkleLT contract is deployed in {Integration_Test.setUp}
    function test_RevertGiven_CampaignAlreadyExists() external whenNameNotTooLong {
        MerkleBase.ConstructorParams memory baseParams = defaults.baseParams();
        bool cancelable = defaults.CANCELABLE();
        bool transferable = defaults.TRANSFERABLE();
        uint40 streamStartTime = defaults.STREAM_START_TIME_ZERO();
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages = defaults.tranchesWithPercentages();
        uint256 aggregateAmount = defaults.AGGREGATE_AMOUNT();
        uint256 recipientCount = defaults.RECIPIENT_COUNT();

        // Expect a revert due to CREATE2.
        vm.expectRevert();
        merkleFactory.createMerkleLT(
            baseParams,
            lockup,
            cancelable,
            transferable,
            streamStartTime,
            tranchesWithPercentages,
            aggregateAmount,
            recipientCount
        );
    }

    function test_GivenCustomFeeSet(
        address campaignOwner,
        uint40 expiration,
        uint256 customFee
    )
        external
        whenNameNotTooLong
        givenCampaignNotExists
    {
        // Set the Sablier fee to 0 for this test.
        resetPrank(users.admin);
        merkleFactory.setSablierFeeByUser(users.campaignOwner, customFee);

        resetPrank(users.campaignOwner);
        address expectedLT = computeMerkleLTAddress(campaignOwner, expiration, customFee);

        MerkleBase.ConstructorParams memory baseParams = defaults.baseParams({
            campaignOwner: campaignOwner,
            asset_: dai,
            merkleRoot: defaults.MERKLE_ROOT(),
            expiration: expiration
        });

        // It should emit a {CreateMerkleLT} event.
        vm.expectEmit({ emitter: address(merkleFactory) });
        emit ISablierMerkleFactory.CreateMerkleLT({
            merkleLT: ISablierMerkleLT(expectedLT),
            baseParams: baseParams,
            lockup: lockup,
            cancelable: defaults.CANCELABLE(),
            transferable: defaults.TRANSFERABLE(),
            streamStartTime: defaults.STREAM_START_TIME_ZERO(),
            tranchesWithPercentages: defaults.tranchesWithPercentages(),
            totalDuration: defaults.TOTAL_DURATION(),
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT(),
            sablierFee: customFee
        });

        ISablierMerkleLT actualLT = createMerkleLT(campaignOwner, expiration);
        assertGt(address(actualLT).code.length, 0, "MerkleLT contract not created");
        assertEq(address(actualLT), expectedLT, "MerkleLT contract does not match computed address");

        // It should create the campaign with custom fee.
        assertEq(actualLT.SABLIER_FEE(), customFee, "sablier fee");
        // It should set the current factory address.
        assertEq(actualLT.FACTORY(), address(merkleFactory), "factory");
    }

    function test_GivenCustomFeeNotSet(
        address campaignOwner,
        uint40 expiration
    )
        external
        whenNameNotTooLong
        givenCampaignNotExists
    {
        address expectedLT = computeMerkleLTAddress(campaignOwner, expiration);

        MerkleBase.ConstructorParams memory baseParams = defaults.baseParams({
            campaignOwner: campaignOwner,
            asset_: dai,
            merkleRoot: defaults.MERKLE_ROOT(),
            expiration: expiration
        });

        vm.expectEmit({ emitter: address(merkleFactory) });
        emit ISablierMerkleFactory.CreateMerkleLT({
            merkleLT: ISablierMerkleLT(expectedLT),
            baseParams: baseParams,
            lockup: lockup,
            cancelable: defaults.CANCELABLE(),
            transferable: defaults.TRANSFERABLE(),
            streamStartTime: defaults.STREAM_START_TIME_ZERO(),
            tranchesWithPercentages: defaults.tranchesWithPercentages(),
            totalDuration: defaults.TOTAL_DURATION(),
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT(),
            sablierFee: defaults.DEFAULT_SABLIER_FEE()
        });

        ISablierMerkleLT actualLT = createMerkleLT(campaignOwner, expiration);
        assertGt(address(actualLT).code.length, 0, "MerkleLT contract not created");
        assertEq(address(actualLT), expectedLT, "MerkleLT contract does not match computed address");

        // It should create the campaign with custom fee.
        assertEq(actualLT.SABLIER_FEE(), defaults.DEFAULT_SABLIER_FEE(), "default sablier fee");
        // It should set the current factory address.
        assertEq(actualLT.FACTORY(), address(merkleFactory), "factory");
    }
}
