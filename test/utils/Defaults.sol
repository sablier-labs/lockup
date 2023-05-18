// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD2x18, ud2x18 } from "@prb/math/UD2x18.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { Broker } from "../../src/types/Generics.sol";
import { Lockup } from "../../src/types/Lockup.sol";
import { LockupDynamic } from "../../src/types/LockupDynamic.sol";
import { LockupLinear } from "../../src/types/LockupLinear.sol";

import { Constants } from "./Constants.sol";
import { Users } from "./Types.sol";

/// @notice Contract with default values used throughout the tests.
contract Defaults is Constants {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    UD60x18 public constant BROKER_FEE = UD60x18.wrap(0.003e18); // 0.3%
    uint128 public constant BROKER_FEE_AMOUNT = 30.120481927710843373e18; // 0.3% of total amount
    uint128 public constant CLIFF_AMOUNT = 2500e18;
    uint40 public immutable CLIFF_TIME;
    uint40 public constant CLIFF_DURATION = 2500 seconds;
    uint128 public constant DEPOSIT_AMOUNT = 10_000e18;
    uint40 public immutable END_TIME;
    UD60x18 public constant FLASH_FEE = UD60x18.wrap(0.0005e18); // 0.05%
    uint256 public constant MAX_SEGMENT_COUNT = 1000;
    uint40 public immutable MAX_SEGMENT_DURATION;
    UD60x18 public constant PROTOCOL_FEE = UD60x18.wrap(0.001e18); // 0.1%
    uint128 public constant PROTOCOL_FEE_AMOUNT = 10.040160642570281124e18; // 0.1% of total amount
    uint128 public constant REFUND_AMOUNT = DEPOSIT_AMOUNT - CLIFF_AMOUNT;
    uint256 public SEGMENT_COUNT;
    uint40 public immutable START_TIME;
    uint128 public constant TOTAL_AMOUNT = 10_040.160642570281124497e18; // deposit / (1 - fee)
    uint40 public constant TOTAL_DURATION = 10_000 seconds;
    uint128 public constant WITHDRAW_AMOUNT = 2600e18;
    uint40 public immutable WARP_26_PERCENT; // 26% of the way through the stream

    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 private asset;
    Users private users;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {
        START_TIME = uint40(MAY_1_2023) + 2 days;
        CLIFF_TIME = START_TIME + CLIFF_DURATION;
        END_TIME = START_TIME + TOTAL_DURATION;
        MAX_SEGMENT_DURATION = TOTAL_DURATION / uint40(MAX_SEGMENT_COUNT);
        SEGMENT_COUNT = 2;
        WARP_26_PERCENT = START_TIME + CLIFF_DURATION + 100 seconds;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function setAsset(IERC20 asset_) external {
        asset = asset_;
    }

    function setUsers(Users memory users_) external {
        users = users_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    function broker() public view returns (Broker memory broker_) {
        broker_ = Broker({ account: users.broker, fee: BROKER_FEE });
    }

    function durations() public pure returns (LockupLinear.Durations memory durations_) {
        durations_ = LockupLinear.Durations({ cliff: CLIFF_DURATION, total: TOTAL_DURATION });
    }

    function dynamicRange() public view returns (LockupDynamic.Range memory dynamicRange_) {
        dynamicRange_ = LockupDynamic.Range({ start: START_TIME, end: END_TIME });
    }

    function dynamicStream() external view returns (LockupDynamic.Stream memory dynamicStream_) {
        dynamicStream_ = LockupDynamic.Stream({
            amounts: lockupAmounts(),
            asset: asset,
            endTime: END_TIME,
            isCancelable: true,
            isDepleted: false,
            isStream: true,
            segments: segments(),
            sender: users.sender,
            startTime: START_TIME,
            wasCanceled: false
        });
    }

    function linearRange() public view returns (LockupLinear.Range memory linearRange_) {
        linearRange_ = LockupLinear.Range({ start: START_TIME, cliff: CLIFF_TIME, end: END_TIME });
    }

    function linearStream() external view returns (LockupLinear.Stream memory linearStream_) {
        linearStream_ = LockupLinear.Stream({
            amounts: lockupAmounts(),
            asset: asset,
            cliffTime: CLIFF_TIME,
            endTime: END_TIME,
            isCancelable: true,
            isDepleted: false,
            isStream: true,
            sender: users.sender,
            startTime: START_TIME,
            wasCanceled: false
        });
    }

    function lockupAmounts() public pure returns (Lockup.Amounts memory lockupAmounts_) {
        lockupAmounts_ = Lockup.Amounts({ deposited: DEPOSIT_AMOUNT, refunded: 0, withdrawn: 0 });
    }

    function lockupCreateAmounts() external pure returns (Lockup.CreateAmounts memory lockupCreateAmounts_) {
        lockupCreateAmounts_ = Lockup.CreateAmounts({
            deposit: DEPOSIT_AMOUNT,
            protocolFee: PROTOCOL_FEE_AMOUNT,
            brokerFee: BROKER_FEE_AMOUNT
        });
    }

    function maxSegments() external view returns (LockupDynamic.Segment[] memory maxSegments_) {
        uint128 amount = DEPOSIT_AMOUNT / uint128(MAX_SEGMENT_COUNT);
        UD2x18 exponent = ud2x18(2.71e18);

        // Generate a bunch of segments with the same amount, same exponent, and with milestones evenly spread apart.
        maxSegments_ = new LockupDynamic.Segment[](MAX_SEGMENT_COUNT);
        for (uint40 i = 0; i < MAX_SEGMENT_COUNT; ++i) {
            maxSegments_[i] = (
                LockupDynamic.Segment({
                    amount: amount,
                    exponent: exponent,
                    milestone: START_TIME + MAX_SEGMENT_DURATION * (i + 1)
                })
            );
        }
    }

    function segments() public view returns (LockupDynamic.Segment[] memory segments_) {
        segments_ = new LockupDynamic.Segment[](2);
        segments_[0] = (
            LockupDynamic.Segment({ amount: 2500e18, exponent: ud2x18(3.14e18), milestone: START_TIME + CLIFF_DURATION })
        );
        segments_[1] = (
            LockupDynamic.Segment({ amount: 7500e18, exponent: ud2x18(0.5e18), milestone: START_TIME + TOTAL_DURATION })
        );
    }

    function segmentsWithDeltas() public view returns (LockupDynamic.SegmentWithDelta[] memory segmentsWithDeltas_) {
        LockupDynamic.Segment[] memory segments_ = segments();
        segmentsWithDeltas_ = new LockupDynamic.SegmentWithDelta[](2);
        segmentsWithDeltas_[0] = (
            LockupDynamic.SegmentWithDelta({
                amount: segments_[0].amount,
                exponent: segments_[0].exponent,
                delta: 2500 seconds
            })
        );
        segmentsWithDeltas_[1] = (
            LockupDynamic.SegmentWithDelta({
                amount: segments_[1].amount,
                exponent: segments_[1].exponent,
                delta: 7500 seconds
            })
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       PARAMS
    //////////////////////////////////////////////////////////////////////////*/

    function createWithDeltas() external view returns (LockupDynamic.CreateWithDeltas memory params_) {
        params_ = LockupDynamic.CreateWithDeltas({
            asset: asset,
            broker: broker(),
            cancelable: true,
            recipient: users.recipient,
            segments: segmentsWithDeltas(),
            sender: users.sender,
            totalAmount: TOTAL_AMOUNT
        });
    }

    function createWithDurations() public view returns (LockupLinear.CreateWithDurations memory params_) {
        params_ = LockupLinear.CreateWithDurations({
            asset: asset,
            broker: broker(),
            cancelable: true,
            durations: durations(),
            recipient: users.recipient,
            sender: users.sender,
            totalAmount: TOTAL_AMOUNT
        });
    }

    function createWithMilestones() external view returns (LockupDynamic.CreateWithMilestones memory params_) {
        params_ = LockupDynamic.CreateWithMilestones({
            asset: asset,
            broker: broker(),
            cancelable: true,
            recipient: users.recipient,
            segments: segments(),
            sender: users.sender,
            startTime: START_TIME,
            totalAmount: TOTAL_AMOUNT
        });
    }

    function createWithRange() public view returns (LockupLinear.CreateWithRange memory params_) {
        params_ = LockupLinear.CreateWithRange({
            asset: asset,
            broker: broker(),
            cancelable: true,
            range: linearRange(),
            recipient: users.recipient,
            sender: users.sender,
            totalAmount: TOTAL_AMOUNT
        });
    }
}
