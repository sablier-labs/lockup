// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { Arrays } from "@openzeppelin/contracts/utils/Arrays.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud2x18, uUNIT } from "@prb/math/src/UD2x18.sol";
import { UD60x18, ud, ZERO } from "@prb/math/src/UD60x18.sol";

import { Broker, Lockup, LockupDynamic, LockupLinear, LockupTranched } from "../../src/core/types/DataTypes.sol";
import { BatchLockup, MerkleBase, MerkleLT } from "../../src/periphery/types/DataTypes.sol";

import { ArrayBuilder } from "./ArrayBuilder.sol";
import { Constants } from "./Constants.sol";
import { BatchLockupBuilder } from "./BatchLockupBuilder.sol";
import { Merkle } from "./Murky.sol";
import { MerkleBuilder } from "./MerkleBuilder.sol";
import { Users } from "./Types.sol";

/// @notice Contract with default values used throughout the tests.
contract Defaults is Constants, Merkle {
    using MerkleBuilder for uint256[];

    /*//////////////////////////////////////////////////////////////////////////
                                      GENERICS
    //////////////////////////////////////////////////////////////////////////*/

    uint64 public constant BATCH_SIZE = 10;
    UD60x18 public constant BROKER_FEE = UD60x18.wrap(0.003e18); // 0.3%
    uint128 public constant BROKER_FEE_AMOUNT = 30.090270812437311935e18; // 0.3% of total amount
    uint128 public constant CLIFF_AMOUNT = 2500e18;
    uint40 public immutable CLIFF_TIME;
    uint40 public constant CLIFF_DURATION = 2500 seconds;
    uint128 public constant DEPOSIT_AMOUNT = 10_000e18;
    uint40 public immutable END_TIME;
    uint256 public constant MAX_SEGMENT_COUNT = 10_000;
    uint40 public immutable MAX_SEGMENT_DURATION;
    uint256 public constant MAX_TRANCHE_COUNT = 10_000;
    uint128 public constant REFUND_AMOUNT = DEPOSIT_AMOUNT - CLIFF_AMOUNT;
    uint256 public constant SEGMENT_COUNT = 2;
    uint40 public immutable START_TIME;
    uint128 public constant TOTAL_AMOUNT = 10_030.090270812437311935e18; // deposit + broker fee
    uint40 public constant TOTAL_DURATION = 10_000 seconds;
    uint256 public constant TRANCHE_COUNT = 3;
    uint128 public constant TOTAL_TRANSFER_AMOUNT = DEPOSIT_AMOUNT * uint128(BATCH_SIZE);
    uint128 public constant WITHDRAW_AMOUNT = 2600e18;
    uint40 public immutable WARP_26_PERCENT; // 26% of the way through the stream

    /*//////////////////////////////////////////////////////////////////////////
                                  MERKLE-LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    uint256 public constant AGGREGATE_AMOUNT = CLAIM_AMOUNT * RECIPIENT_COUNT;
    bool public constant CANCELABLE = false;
    uint128 public constant CLAIM_AMOUNT = 10_000e18;
    uint40 public immutable EXPIRATION;
    uint40 public constant FIRST_CLAIM_TIME = JULY_1_2024;
    uint256 public constant INDEX1 = 1;
    uint256 public constant INDEX2 = 2;
    uint256 public constant INDEX3 = 3;
    uint256 public constant INDEX4 = 4;
    string public constant IPFS_CID = "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR";
    uint256[] public LEAVES = new uint256[](RECIPIENT_COUNT);
    uint256 public constant RECIPIENT_COUNT = 4;
    bytes32 public MERKLE_ROOT;
    string public constant NAME = "Airdrop Campaign";
    bytes32 public constant NAME_BYTES32 = bytes32(abi.encodePacked("Airdrop Campaign"));
    uint64 public constant TOTAL_PERCENTAGE = uUNIT;
    bool public constant TRANSFERABLE = false;

    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 private asset;
    Users private users;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {
        START_TIME = JULY_1_2024 + 2 days;
        CLIFF_TIME = START_TIME + CLIFF_DURATION;
        END_TIME = START_TIME + TOTAL_DURATION;
        EXPIRATION = JULY_1_2024 + 12 weeks;
        MAX_SEGMENT_DURATION = TOTAL_DURATION / uint40(MAX_SEGMENT_COUNT);
        WARP_26_PERCENT = START_TIME + CLIFF_DURATION + 100 seconds;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev We need a separate function to initialize the Merkle tree because, at the construction time, the users are
    /// not yet set.
    function initMerkleTree() public {
        LEAVES[0] = MerkleBuilder.computeLeaf(INDEX1, users.recipient1, CLAIM_AMOUNT);
        LEAVES[1] = MerkleBuilder.computeLeaf(INDEX2, users.recipient2, CLAIM_AMOUNT);
        LEAVES[2] = MerkleBuilder.computeLeaf(INDEX3, users.recipient3, CLAIM_AMOUNT);
        LEAVES[3] = MerkleBuilder.computeLeaf(INDEX4, users.recipient4, CLAIM_AMOUNT);
        MerkleBuilder.sortLeaves(LEAVES);
        MERKLE_ROOT = getRoot(LEAVES.toBytes32());
    }

    function setAsset(IERC20 asset_) public {
        asset = asset_;
    }

    function setUsers(Users memory users_) public {
        users = users_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    function broker() public view returns (Broker memory) {
        return Broker({ account: users.broker, fee: BROKER_FEE });
    }

    function brokerNull() public pure returns (Broker memory) {
        return Broker({ account: address(0), fee: ZERO });
    }

    function durations() public pure returns (LockupLinear.Durations memory) {
        return LockupLinear.Durations({ cliff: CLIFF_DURATION, total: TOTAL_DURATION });
    }

    function lockupAmounts() public pure returns (Lockup.Amounts memory) {
        return Lockup.Amounts({ deposited: DEPOSIT_AMOUNT, refunded: 0, withdrawn: 0 });
    }

    function lockupCreateAmounts() public pure returns (Lockup.CreateAmounts memory) {
        return Lockup.CreateAmounts({ deposit: DEPOSIT_AMOUNT, brokerFee: BROKER_FEE_AMOUNT });
    }

    function lockupDynamicStream() public view returns (LockupDynamic.StreamLD memory) {
        return LockupDynamic.StreamLD({
            amounts: lockupAmounts(),
            asset: asset,
            endTime: END_TIME,
            isCancelable: true,
            isDepleted: false,
            isStream: true,
            isTransferable: true,
            recipient: users.recipient,
            segments: segments(),
            sender: users.sender,
            startTime: START_TIME,
            wasCanceled: false
        });
    }

    function lockupDynamicTimestamps() public view returns (LockupDynamic.Timestamps memory) {
        return LockupDynamic.Timestamps({ start: START_TIME, end: END_TIME });
    }

    function lockupLinearStream() public view returns (LockupLinear.StreamLL memory) {
        return LockupLinear.StreamLL({
            amounts: lockupAmounts(),
            asset: asset,
            cliffTime: CLIFF_TIME,
            endTime: END_TIME,
            isCancelable: true,
            isTransferable: true,
            isDepleted: false,
            isStream: true,
            recipient: users.recipient,
            sender: users.sender,
            startTime: START_TIME,
            wasCanceled: false
        });
    }

    function lockupLinearTimestamps() public view returns (LockupLinear.Timestamps memory) {
        return LockupLinear.Timestamps({ start: START_TIME, cliff: CLIFF_TIME, end: END_TIME });
    }

    function lockupTranchedStream() public view returns (LockupTranched.StreamLT memory) {
        return LockupTranched.StreamLT({
            amounts: lockupAmounts(),
            asset: asset,
            endTime: END_TIME,
            isCancelable: true,
            isDepleted: false,
            isStream: true,
            isTransferable: true,
            recipient: users.recipient,
            sender: users.sender,
            startTime: START_TIME,
            tranches: tranches(),
            wasCanceled: false
        });
    }

    function lockupTranchedTimestamps() public view returns (LockupTranched.Timestamps memory) {
        return LockupTranched.Timestamps({ start: START_TIME, end: END_TIME });
    }

    function segments() public view returns (LockupDynamic.Segment[] memory segments_) {
        segments_ = new LockupDynamic.Segment[](2);
        segments_[0] = (
            LockupDynamic.Segment({ amount: 2500e18, exponent: ud2x18(3.14e18), timestamp: START_TIME + CLIFF_DURATION })
        );
        segments_[1] = (
            LockupDynamic.Segment({ amount: 7500e18, exponent: ud2x18(0.5e18), timestamp: START_TIME + TOTAL_DURATION })
        );
    }

    function segmentsWithDurations()
        public
        view
        returns (LockupDynamic.SegmentWithDuration[] memory segmentsWithDurations_)
    {
        LockupDynamic.Segment[] memory segments_ = segments();
        segmentsWithDurations_ = new LockupDynamic.SegmentWithDuration[](2);
        segmentsWithDurations_[0] = (
            LockupDynamic.SegmentWithDuration({
                amount: segments_[0].amount,
                exponent: segments_[0].exponent,
                duration: 2500 seconds
            })
        );
        segmentsWithDurations_[1] = (
            LockupDynamic.SegmentWithDuration({
                amount: segments_[1].amount,
                exponent: segments_[1].exponent,
                duration: 7500 seconds
            })
        );
    }

    function tranches() public view returns (LockupTranched.Tranche[] memory tranches_) {
        tranches_ = new LockupTranched.Tranche[](3);
        tranches_[0] = LockupTranched.Tranche({ amount: 2500e18, timestamp: START_TIME + CLIFF_DURATION });
        tranches_[1] = LockupTranched.Tranche({ amount: 100e18, timestamp: WARP_26_PERCENT });
        tranches_[2] = LockupTranched.Tranche({ amount: 7400e18, timestamp: START_TIME + TOTAL_DURATION });
    }

    function tranchesWithDurations()
        public
        pure
        returns (LockupTranched.TrancheWithDuration[] memory tranchesWithDurations_)
    {
        tranchesWithDurations_ = new LockupTranched.TrancheWithDuration[](3);
        tranchesWithDurations_[0] = LockupTranched.TrancheWithDuration({ amount: 2500e18, duration: 2500 seconds });
        tranchesWithDurations_[1] = LockupTranched.TrancheWithDuration({ amount: 100e18, duration: 100 seconds });
        tranchesWithDurations_[2] = LockupTranched.TrancheWithDuration({ amount: 7400e18, duration: 7400 seconds });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   CREATE-PARAMS
    //////////////////////////////////////////////////////////////////////////*/

    function createWithDurationsLD() public view returns (LockupDynamic.CreateWithDurations memory) {
        return LockupDynamic.CreateWithDurations({
            sender: users.sender,
            recipient: users.recipient,
            totalAmount: TOTAL_AMOUNT,
            asset: asset,
            cancelable: true,
            transferable: true,
            segments: segmentsWithDurations(),
            broker: broker()
        });
    }

    function createWithDurationsBrokerNullLD() public view returns (LockupDynamic.CreateWithDurations memory) {
        LockupDynamic.CreateWithDurations memory params = createWithDurationsLD();
        params.totalAmount = DEPOSIT_AMOUNT;
        params.broker = brokerNull();
        return params;
    }

    function createWithDurationsLL() public view returns (LockupLinear.CreateWithDurations memory) {
        return LockupLinear.CreateWithDurations({
            sender: users.sender,
            recipient: users.recipient,
            totalAmount: TOTAL_AMOUNT,
            asset: asset,
            cancelable: true,
            transferable: true,
            durations: durations(),
            broker: broker()
        });
    }

    function createWithDurationsBrokerNullLL() public view returns (LockupLinear.CreateWithDurations memory) {
        LockupLinear.CreateWithDurations memory params = createWithDurationsLL();
        params.totalAmount = DEPOSIT_AMOUNT;
        params.broker = brokerNull();
        return params;
    }

    function createWithDurationsLT() public view returns (LockupTranched.CreateWithDurations memory) {
        return LockupTranched.CreateWithDurations({
            sender: users.sender,
            recipient: users.recipient,
            totalAmount: TOTAL_AMOUNT,
            asset: asset,
            cancelable: true,
            transferable: true,
            tranches: tranchesWithDurations(),
            broker: broker()
        });
    }

    function createWithDurationsBrokerNullLT() public view returns (LockupTranched.CreateWithDurations memory) {
        LockupTranched.CreateWithDurations memory params = createWithDurationsLT();
        params.totalAmount = DEPOSIT_AMOUNT;
        params.broker = brokerNull();
        return params;
    }

    function createWithTimestampsLD() public view returns (LockupDynamic.CreateWithTimestamps memory) {
        return LockupDynamic.CreateWithTimestamps({
            sender: users.sender,
            recipient: users.recipient,
            totalAmount: TOTAL_AMOUNT,
            asset: asset,
            cancelable: true,
            transferable: true,
            startTime: START_TIME,
            segments: segments(),
            broker: broker()
        });
    }

    function createWithTimestampsBrokerNullLD() public view returns (LockupDynamic.CreateWithTimestamps memory) {
        LockupDynamic.CreateWithTimestamps memory params = createWithTimestampsLD();
        params.totalAmount = DEPOSIT_AMOUNT;
        params.broker = brokerNull();
        return params;
    }

    function createWithTimestampsLL() public view returns (LockupLinear.CreateWithTimestamps memory) {
        return LockupLinear.CreateWithTimestamps({
            sender: users.sender,
            recipient: users.recipient,
            totalAmount: TOTAL_AMOUNT,
            asset: asset,
            cancelable: true,
            transferable: true,
            timestamps: lockupLinearTimestamps(),
            broker: broker()
        });
    }

    function createWithTimestampsBrokerNullLL() public view returns (LockupLinear.CreateWithTimestamps memory) {
        LockupLinear.CreateWithTimestamps memory params = createWithTimestampsLL();
        params.totalAmount = DEPOSIT_AMOUNT;
        params.broker = brokerNull();
        return params;
    }

    function createWithTimestampsLT() public view returns (LockupTranched.CreateWithTimestamps memory) {
        return LockupTranched.CreateWithTimestamps({
            sender: users.sender,
            recipient: users.recipient,
            totalAmount: TOTAL_AMOUNT,
            asset: asset,
            cancelable: true,
            transferable: true,
            startTime: START_TIME,
            tranches: tranches(),
            broker: broker()
        });
    }

    function createWithTimestampsBrokerNullLT() public view returns (LockupTranched.CreateWithTimestamps memory) {
        LockupTranched.CreateWithTimestamps memory params = createWithTimestampsLT();
        params.totalAmount = DEPOSIT_AMOUNT;
        params.broker = brokerNull();
        return params;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    BATCH-LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    function incrementalStreamIds() public pure returns (uint256[] memory streamIds) {
        return ArrayBuilder.fillStreamIds({ firstStreamId: 1, batchSize: BATCH_SIZE });
    }

    /// @dev Returns a default-size batch of {BatchLockup.CreateWithDurationsLD} parameters.
    function batchCreateWithDurationsLD() public view returns (BatchLockup.CreateWithDurationsLD[] memory batch) {
        batch = BatchLockupBuilder.fillBatch(createWithDurationsBrokerNullLD(), BATCH_SIZE);
    }

    /// @dev Returns a default-size batch of {BatchLockup.CreateWithDurationsLL} parameters.
    function batchCreateWithDurationsLL() public view returns (BatchLockup.CreateWithDurationsLL[] memory batch) {
        batch = BatchLockupBuilder.fillBatch(createWithDurationsBrokerNullLL(), BATCH_SIZE);
    }

    /// @dev Returns a default-size batch of {BatchLockup.CreateWithDurationsLT} parameters.
    function batchCreateWithDurationsLT() public view returns (BatchLockup.CreateWithDurationsLT[] memory batch) {
        batch = BatchLockupBuilder.fillBatch(createWithDurationsBrokerNullLT(), BATCH_SIZE);
    }

    /// @dev Returns a default-size batch of {BatchLockup.CreateWithTimestampsLD} parameters.
    function batchCreateWithTimestampsLD() public view returns (BatchLockup.CreateWithTimestampsLD[] memory batch) {
        batch = batchCreateWithTimestampsLD(BATCH_SIZE);
    }

    /// @dev Returns a batch of {BatchLockup.CreateWithTimestampsLD} parameters.
    function batchCreateWithTimestampsLD(uint256 batchSize)
        public
        view
        returns (BatchLockup.CreateWithTimestampsLD[] memory batch)
    {
        batch = BatchLockupBuilder.fillBatch(createWithTimestampsBrokerNullLD(), batchSize);
    }

    /// @dev Returns a default-size batch of {BatchLockup.CreateWithTimestampsLL} parameters.
    function batchCreateWithTimestampsLL() public view returns (BatchLockup.CreateWithTimestampsLL[] memory batch) {
        batch = batchCreateWithTimestampsLL(BATCH_SIZE);
    }

    /// @dev Returns a batch of {BatchLockup.CreateWithTimestampsLL} parameters.
    function batchCreateWithTimestampsLL(uint256 batchSize)
        public
        view
        returns (BatchLockup.CreateWithTimestampsLL[] memory batch)
    {
        batch = BatchLockupBuilder.fillBatch(createWithTimestampsBrokerNullLL(), batchSize);
    }

    /// @dev Returns a default-size batch of {BatchLockup.CreateWithTimestampsLT} parameters.
    function batchCreateWithTimestampsLT() public view returns (BatchLockup.CreateWithTimestampsLT[] memory batch) {
        batch = batchCreateWithTimestampsLT(BATCH_SIZE);
    }

    /// @dev Returns a batch of {BatchLockup.CreateWithTimestampsLL} parameters.
    function batchCreateWithTimestampsLT(uint256 batchSize)
        public
        view
        returns (BatchLockup.CreateWithTimestampsLT[] memory batch)
    {
        batch = BatchLockupBuilder.fillBatch(createWithTimestampsBrokerNullLT(), batchSize);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  MERKLE-LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    function baseParams() public view returns (MerkleBase.ConstructorParams memory) {
        return baseParams(users.admin, asset, EXPIRATION, MERKLE_ROOT);
    }

    function baseParams(
        address admin,
        IERC20 asset_,
        uint40 expiration,
        bytes32 merkleRoot
    )
        public
        pure
        returns (MerkleBase.ConstructorParams memory)
    {
        return MerkleBase.ConstructorParams({
            asset: asset_,
            expiration: expiration,
            initialAdmin: admin,
            ipfsCID: IPFS_CID,
            merkleRoot: merkleRoot,
            name: NAME
        });
    }

    function index1Proof() public view returns (bytes32[] memory) {
        uint256 leaf = MerkleBuilder.computeLeaf(INDEX1, users.recipient1, CLAIM_AMOUNT);
        uint256 pos = Arrays.findUpperBound(LEAVES, leaf);
        return getProof(LEAVES.toBytes32(), pos);
    }

    function index2Proof() public view returns (bytes32[] memory) {
        uint256 leaf = MerkleBuilder.computeLeaf(INDEX2, users.recipient2, CLAIM_AMOUNT);
        uint256 pos = Arrays.findUpperBound(LEAVES, leaf);
        return getProof(LEAVES.toBytes32(), pos);
    }

    function index3Proof() public view returns (bytes32[] memory) {
        uint256 leaf = MerkleBuilder.computeLeaf(INDEX3, users.recipient3, CLAIM_AMOUNT);
        uint256 pos = Arrays.findUpperBound(LEAVES, leaf);
        return getProof(LEAVES.toBytes32(), pos);
    }

    function index4Proof() public view returns (bytes32[] memory) {
        uint256 leaf = MerkleBuilder.computeLeaf(INDEX4, users.recipient4, CLAIM_AMOUNT);
        uint256 pos = Arrays.findUpperBound(LEAVES, leaf);
        return getProof(LEAVES.toBytes32(), pos);
    }

    function getLeaves() public view returns (uint256[] memory) {
        return LEAVES;
    }

    function tranchesMerkleLT() public view returns (LockupTranched.Tranche[] memory tranches_) {
        tranches_ = new LockupTranched.Tranche[](2);
        tranches_[0] = LockupTranched.Tranche({ amount: 2500e18, timestamp: uint40(block.timestamp) + CLIFF_DURATION });
        tranches_[1] = LockupTranched.Tranche({ amount: 7500e18, timestamp: uint40(block.timestamp) + TOTAL_DURATION });
    }

    /// @dev Mirros the logic from {SablierMerkleLT._calculateTranches}.
    function tranchesMerkleLT(uint128 totalAmount) public view returns (LockupTranched.Tranche[] memory tranches_) {
        tranches_ = tranchesMerkleLT();

        uint128 amount0 = ud(totalAmount).mul(tranchesWithPercentages()[0].unlockPercentage.intoUD60x18()).intoUint128();
        uint128 amount1 = ud(totalAmount).mul(tranchesWithPercentages()[1].unlockPercentage.intoUD60x18()).intoUint128();

        tranches_[0].amount = amount0;
        tranches_[1].amount = amount1;

        uint128 amountsSum = amount0 + amount1;

        if (amountsSum != totalAmount) {
            tranches_[1].amount += totalAmount - amountsSum;
        }
    }

    function tranchesWithPercentages()
        public
        pure
        returns (MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages_)
    {
        tranchesWithPercentages_ = new MerkleLT.TrancheWithPercentage[](2);
        tranchesWithPercentages_[0] =
            MerkleLT.TrancheWithPercentage({ unlockPercentage: ud2x18(0.25e18), duration: 2500 seconds });
        tranchesWithPercentages_[1] =
            MerkleLT.TrancheWithPercentage({ unlockPercentage: ud2x18(0.75e18), duration: 7500 seconds });
    }
}
