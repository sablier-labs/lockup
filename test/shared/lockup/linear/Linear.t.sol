// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Broker, Lockup, LockupLinear } from "../../../../src/types/DataTypes.sol";

import { Lockup_Shared_Test } from "../Lockup.t.sol";

/// @title Linear_Shared_Test
/// @notice Common testing logic needed across {SablierV2LockupLinear} unit and fuzz tests.
abstract contract Linear_Shared_Test is Lockup_Shared_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                      STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct DefaultParams {
        LockupLinear.CreateWithDurations createWithDurations;
        LockupLinear.CreateWithRange createWithRange;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    LockupLinear.Stream internal defaultStream;
    DefaultParams internal defaultParams;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Lockup_Shared_Test.setUp();

        // Initialize the default params to be used for the create functions.
        defaultParams = DefaultParams({
            createWithDurations: LockupLinear.CreateWithDurations({
                asset: DEFAULT_ASSET,
                broker: Broker({ account: users.broker, fee: DEFAULT_BROKER_FEE }),
                cancelable: true,
                durations: DEFAULT_DURATIONS,
                sender: users.sender,
                recipient: users.recipient,
                totalAmount: DEFAULT_TOTAL_AMOUNT
            }),
            createWithRange: LockupLinear.CreateWithRange({
                asset: DEFAULT_ASSET,
                broker: Broker({ account: users.broker, fee: DEFAULT_BROKER_FEE }),
                cancelable: true,
                sender: users.sender,
                range: DEFAULT_LINEAR_RANGE,
                recipient: users.recipient,
                totalAmount: DEFAULT_TOTAL_AMOUNT
            })
        });

        // Create the default stream to be used across all tests.
        defaultStream = LockupLinear.Stream({
            amounts: DEFAULT_LOCKUP_AMOUNTS,
            asset: defaultParams.createWithRange.asset,
            cliffTime: defaultParams.createWithRange.range.cliff,
            endTime: defaultParams.createWithRange.range.end,
            isCancelable: defaultParams.createWithRange.cancelable,
            isCanceled: false,
            isDepleted: false,
            isStream: true,
            sender: defaultParams.createWithRange.sender,
            startTime: defaultParams.createWithRange.range.start
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Creates the default stream.
    function createDefaultStream() internal override returns (uint256 streamId) {
        streamId = linear.createWithRange(defaultParams.createWithRange);
    }

    /// @dev Creates the default stream with the provided address.
    function createDefaultStreamWithAsset(IERC20 asset) internal override returns (uint256 streamId) {
        LockupLinear.CreateWithRange memory params = defaultParams.createWithRange;
        params.asset = asset;
        streamId = linear.createWithRange(params);
    }

    /// @dev Creates the default stream with the provided broker.
    function createDefaultStreamWithBroker(Broker memory broker) internal override returns (uint256 streamId) {
        LockupLinear.CreateWithRange memory params = defaultParams.createWithRange;
        params.broker = broker;
        streamId = linear.createWithRange(params);
    }

    /// @dev Creates the default stream with durations.
    function createDefaultStreamWithDurations() internal returns (uint256 streamId) {
        streamId = linear.createWithDurations(defaultParams.createWithDurations);
    }

    /// @dev Creates the default stream with the provided durations.
    function createDefaultStreamWithDurations(LockupLinear.Durations memory durations)
        internal
        returns (uint256 streamId)
    {
        LockupLinear.CreateWithDurations memory params = defaultParams.createWithDurations;
        params.durations = durations;
        streamId = linear.createWithDurations(params);
    }

    /// @dev Creates the default stream that is not cancelable.
    function createDefaultStreamNotCancelable() internal override returns (uint256 streamId) {
        LockupLinear.CreateWithRange memory params = defaultParams.createWithRange;
        params.cancelable = false;
        streamId = linear.createWithRange(params);
    }

    /// @dev Creates the default stream with the provided end time.
    function createDefaultStreamWithEndTime(uint40 endTime) internal override returns (uint256 streamId) {
        LockupLinear.CreateWithRange memory params = defaultParams.createWithRange;
        params.range = LockupLinear.Range({
            start: defaultParams.createWithRange.range.start,
            cliff: defaultParams.createWithRange.range.cliff,
            end: endTime
        });
        streamId = linear.createWithRange(params);
    }

    /// @dev Creates the default stream with the provided range.
    function createDefaultStreamWithRange(LockupLinear.Range memory range) internal returns (uint256 streamId) {
        LockupLinear.CreateWithRange memory params = defaultParams.createWithRange;
        params.range = range;
        streamId = linear.createWithRange(params);
    }

    /// @dev Creates the default stream with the provided recipient.
    function createDefaultStreamWithRecipient(address recipient) internal override returns (uint256 streamId) {
        LockupLinear.CreateWithRange memory params = defaultParams.createWithRange;
        params.recipient = recipient;
        streamId = linear.createWithRange(params);
    }

    /// @dev Creates the default stream with the provided sender.
    function createDefaultStreamWithSender(address sender) internal override returns (uint256 streamId) {
        LockupLinear.CreateWithRange memory params = defaultParams.createWithRange;
        params.sender = sender;
        streamId = linear.createWithRange(params);
    }

    /// @dev Creates the default stream with the provided start time.
    function createDefaultStreamWithStartTime(uint40 startTime) internal override returns (uint256 streamId) {
        LockupLinear.CreateWithRange memory params = defaultParams.createWithRange;
        params.range = LockupLinear.Range({
            start: startTime,
            cliff: defaultParams.createWithRange.range.cliff,
            end: defaultParams.createWithRange.range.end
        });
        streamId = linear.createWithRange(params);
    }

    /// @dev Creates the default stream with the provided total amount.
    function createDefaultStreamWithTotalAmount(uint128 totalAmount) internal returns (uint256 streamId) {
        LockupLinear.CreateWithRange memory params = defaultParams.createWithRange;
        params.totalAmount = totalAmount;
        streamId = linear.createWithRange(params);
    }
}
