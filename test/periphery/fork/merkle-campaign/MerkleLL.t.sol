// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Arrays } from "@openzeppelin/contracts/utils/Arrays.sol";

import { ISablierMerkleFactory } from "src/periphery/interfaces/ISablierMerkleFactory.sol";
import { ISablierMerkleBase, ISablierMerkleLL } from "src/periphery/interfaces/ISablierMerkleLL.sol";
import { MerkleBase } from "src/periphery/types/DataTypes.sol";

import { MerkleBuilder } from "./../../../utils/MerkleBuilder.sol";
import { Fork_Test } from "./../Fork.t.sol";

abstract contract MerkleLL_Fork_Test is Fork_Test {
    using MerkleBuilder for uint256[];

    constructor(IERC20 asset_) Fork_Test(asset_) { }

    /// @dev Encapsulates the data needed to compute a Merkle tree leaf.
    struct LeafData {
        uint256 index;
        uint256 recipientSeed;
        uint128 amount;
    }

    struct Params {
        address campaignOwner;
        uint40 expiration;
        LeafData[] leafData;
        uint256 posBeforeSort;
    }

    struct Vars {
        uint256 aggregateAmount;
        uint128[] amounts;
        MerkleBase.ConstructorParams baseParams;
        uint128 clawbackAmount;
        address expectedLL;
        uint256 expectedStreamId;
        uint256[] indexes;
        uint256 leafPos;
        uint256 leafToClaim;
        ISablierMerkleLL merkleLL;
        bytes32[] merkleProof;
        bytes32 merkleRoot;
        address[] recipients;
        uint256 recipientCount;
    }

    // We need the leaves as a storage variable so that we can use OpenZeppelin's {Arrays.findUpperBound}.
    uint256[] public leaves;

    function testForkFuzz_MerkleLL(Params memory params) external {
        vm.assume(params.campaignOwner != address(0) && params.campaignOwner != users.campaignOwner);
        vm.assume(params.leafData.length > 0);
        assumeNoBlacklisted({ token: address(FORK_ASSET), addr: params.campaignOwner });
        params.posBeforeSort = _bound(params.posBeforeSort, 0, params.leafData.length - 1);

        // The expiration must be either zero or greater than the block timestamp.
        if (params.expiration != 0) {
            params.expiration = boundUint40(params.expiration, getBlockTimestamp() + 1 seconds, MAX_UNIX_TIMESTAMP);
        }

        /*//////////////////////////////////////////////////////////////////////////
                                          CREATE
        //////////////////////////////////////////////////////////////////////////*/

        Vars memory vars;
        vars.recipientCount = params.leafData.length;
        vars.amounts = new uint128[](vars.recipientCount);
        vars.indexes = new uint256[](vars.recipientCount);
        vars.recipients = new address[](vars.recipientCount);
        for (uint256 i = 0; i < vars.recipientCount; ++i) {
            vars.indexes[i] = params.leafData[i].index;

            // Bound each leaf amount so that `aggregateAmount` does not overflow.
            vars.amounts[i] = boundUint128(
                params.leafData[i].amount,
                defaults.START_AMOUNT() + defaults.CLIFF_AMOUNT(),
                uint128(MAX_UINT128 / vars.recipientCount - 1)
            );
            vars.aggregateAmount += vars.amounts[i];

            // Avoid zero recipient addresses.
            uint256 boundedRecipientSeed = _bound(params.leafData[i].recipientSeed, 1, type(uint160).max);
            vars.recipients[i] = address(uint160(boundedRecipientSeed));
        }

        leaves = new uint256[](vars.recipientCount);
        leaves = MerkleBuilder.computeLeaves(vars.indexes, vars.recipients, vars.amounts);

        // Sort the leaves in ascending order to match the production environment.
        MerkleBuilder.sortLeaves(leaves);

        // Compute the Merkle root.
        if (leaves.length == 1) {
            // If there is only one leaf, the Merkle root is the hash of the leaf itself.
            vars.merkleRoot = bytes32(leaves[0]);
        } else {
            vars.merkleRoot = getRoot(leaves.toBytes32());
        }

        // Make the campaign owner as the caller.
        resetPrank({ msgSender: params.campaignOwner });

        uint256 sablierFee = defaults.DEFAULT_SABLIER_FEE();

        vars.expectedLL = computeMerkleLLAddress(
            params.campaignOwner, params.campaignOwner, FORK_ASSET, vars.merkleRoot, params.expiration, sablierFee
        );

        vars.baseParams = defaults.baseParams({
            campaignOwner: params.campaignOwner,
            asset_: FORK_ASSET,
            merkleRoot: vars.merkleRoot,
            expiration: params.expiration
        });

        vm.expectEmit({ emitter: address(merkleFactory) });
        emit ISablierMerkleFactory.CreateMerkleLL({
            merkleLL: ISablierMerkleLL(vars.expectedLL),
            baseParams: vars.baseParams,
            lockup: lockup,
            cancelable: defaults.CANCELABLE(),
            transferable: defaults.TRANSFERABLE(),
            schedule: defaults.schedule(),
            aggregateAmount: vars.aggregateAmount,
            recipientCount: vars.recipientCount,
            sablierFee: sablierFee
        });

        vars.merkleLL = merkleFactory.createMerkleLL({
            baseParams: vars.baseParams,
            lockup: lockup,
            cancelable: defaults.CANCELABLE(),
            transferable: defaults.TRANSFERABLE(),
            schedule: defaults.schedule(),
            aggregateAmount: vars.aggregateAmount,
            recipientCount: vars.recipientCount
        });

        // Fund the MerkleLL contract.
        deal({ token: address(FORK_ASSET), to: address(vars.merkleLL), give: vars.aggregateAmount });

        assertGt(address(vars.merkleLL).code.length, 0, "MerkleLL contract not created");
        assertEq(address(vars.merkleLL), vars.expectedLL, "MerkleLL contract does not match computed address");

        /*//////////////////////////////////////////////////////////////////////////
                                          CLAIM
        //////////////////////////////////////////////////////////////////////////*/

        // Make the recipient as the caller.
        resetPrank({ msgSender: vars.recipients[params.posBeforeSort] });
        vm.deal(vars.recipients[params.posBeforeSort], 1 ether);

        assertFalse(vars.merkleLL.hasClaimed(vars.indexes[params.posBeforeSort]));

        vars.leafToClaim = MerkleBuilder.computeLeaf(
            vars.indexes[params.posBeforeSort],
            vars.recipients[params.posBeforeSort],
            vars.amounts[params.posBeforeSort]
        );
        vars.leafPos = Arrays.findUpperBound(leaves, vars.leafToClaim);

        vars.expectedStreamId = lockup.nextStreamId();

        vm.expectEmit({ emitter: address(vars.merkleLL) });
        emit ISablierMerkleLL.Claim(
            vars.indexes[params.posBeforeSort],
            vars.recipients[params.posBeforeSort],
            vars.amounts[params.posBeforeSort],
            vars.expectedStreamId
        );

        // Compute the Merkle proof.
        if (leaves.length == 1) {
            // If there is only one leaf, the Merkle proof should be an empty array as no proof is needed because the
            // leaf is the root.
        } else {
            vars.merkleProof = getProof(leaves.toBytes32(), vars.leafPos);
        }

        expectCallToClaimWithData({
            merkleLockup: address(vars.merkleLL),
            sablierFee: sablierFee,
            index: vars.indexes[params.posBeforeSort],
            recipient: vars.recipients[params.posBeforeSort],
            amount: vars.amounts[params.posBeforeSort],
            merkleProof: vars.merkleProof
        });

        vars.merkleLL.claim{ value: sablierFee }({
            index: vars.indexes[params.posBeforeSort],
            recipient: vars.recipients[params.posBeforeSort],
            amount: vars.amounts[params.posBeforeSort],
            merkleProof: vars.merkleProof
        });

        // Assert that the stream has been created successfully.
        assertEq(
            lockup.getDepositedAmount(vars.expectedStreamId), vars.amounts[params.posBeforeSort], "deposited amount"
        );
        assertEq(lockup.getRefundedAmount(vars.expectedStreamId), 0, "refunded amount");
        assertEq(lockup.getWithdrawnAmount(vars.expectedStreamId), 0, "withdrawn amount");
        assertEq(lockup.getAsset(vars.expectedStreamId), FORK_ASSET, "asset");
        assertEq(
            lockup.getCliffTime(vars.expectedStreamId), getBlockTimestamp() + defaults.CLIFF_DURATION(), "cliff time"
        );
        assertEq(lockup.getEndTime(vars.expectedStreamId), getBlockTimestamp() + defaults.TOTAL_DURATION(), "end time");
        assertEq(lockup.isCancelable(vars.expectedStreamId), defaults.CANCELABLE(), "is cancelable");
        assertEq(lockup.isDepleted(vars.expectedStreamId), false, "is depleted");
        assertEq(lockup.isStream(vars.expectedStreamId), true, "is stream");
        assertEq(lockup.isTransferable(vars.expectedStreamId), defaults.TRANSFERABLE(), "is transferable");
        assertEq(lockup.getRecipient(vars.expectedStreamId), vars.recipients[params.posBeforeSort], "recipient");
        assertEq(lockup.getSender(vars.expectedStreamId), params.campaignOwner, "sender");
        assertEq(lockup.getStartTime(vars.expectedStreamId), getBlockTimestamp(), "start time");
        assertEq(lockup.wasCanceled(vars.expectedStreamId), false, "was canceled");
        assertEq(lockup.getUnlockAmounts(vars.expectedStreamId).start, defaults.START_AMOUNT(), "unlock amounts start");
        assertEq(lockup.getUnlockAmounts(vars.expectedStreamId).cliff, defaults.CLIFF_AMOUNT(), "unlock amounts cliff");

        assertTrue(vars.merkleLL.hasClaimed(vars.indexes[params.posBeforeSort]));

        /*//////////////////////////////////////////////////////////////////////////
                                        CLAWBACK
        //////////////////////////////////////////////////////////////////////////*/

        // Make the campaign owner as the caller.
        resetPrank({ msgSender: params.campaignOwner });

        if (params.expiration > 0) {
            vars.clawbackAmount = uint128(FORK_ASSET.balanceOf(address(vars.merkleLL)));
            vm.warp({ newTimestamp: uint256(params.expiration) + 1 seconds });

            expectCallToTransfer({ asset: FORK_ASSET, to: params.campaignOwner, value: vars.clawbackAmount });
            vm.expectEmit({ emitter: address(vars.merkleLL) });
            emit ISablierMerkleBase.Clawback({
                to: params.campaignOwner,
                admin: params.campaignOwner,
                amount: vars.clawbackAmount
            });
            vars.merkleLL.clawback({ to: params.campaignOwner, amount: vars.clawbackAmount });
        }

        /*//////////////////////////////////////////////////////////////////////////
                                        WITHDRAW-FEE
        //////////////////////////////////////////////////////////////////////////*/

        // Make the factory admin as the caller.
        resetPrank({ msgSender: users.admin });

        vm.expectEmit({ emitter: address(merkleFactory) });
        emit ISablierMerkleFactory.WithdrawSablierFees({
            admin: users.admin,
            merkleBase: vars.merkleLL,
            to: users.admin,
            sablierFees: sablierFee
        });
        merkleFactory.withdrawFees({ to: payable(users.admin), merkleBase: vars.merkleLL });

        assertEq(address(vars.merkleLL).balance, 0, "merkle lockup ether balance");
        assertEq(users.admin.balance, sablierFee, "admin ether balance");
    }
}
