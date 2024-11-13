// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { MAX_UD60x18, ud } from "@prb/math/src/UD60x18.sol";

import { ISablierLockup } from "src/core/interfaces/ISablierLockup.sol";
import { Errors } from "src/core/libraries/Errors.sol";
import { Broker, Lockup } from "src/core/types/DataTypes.sol";

import { Lockup_Linear_Integration_Fuzz_Test } from "./LockupLinear.t.sol";

contract CreateWithTimestampsLL_Integration_Fuzz_Test is Lockup_Linear_Integration_Fuzz_Test {
    function testFuzz_RevertWhen_BrokerFeeTooHigh(Broker memory broker)
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
    {
        vm.assume(broker.account != address(0));
        broker.fee = _bound(broker.fee, MAX_BROKER_FEE + ud(1), MAX_UD60x18);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierHelpers_BrokerFeeTooHigh.selector, broker.fee, MAX_BROKER_FEE)
        );

        _defaultParams.createWithTimestamps.broker = broker;
        lockup.createWithTimestampsLL(_defaultParams.createWithTimestamps, _defaultParams.cliffTime);
    }

    function testFuzz_RevertWhen_StartTimeNotLessThanCliffTime(uint40 startTime)
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
    {
        startTime = boundUint40(startTime, defaults.CLIFF_TIME() + 1 seconds, defaults.END_TIME() - 1 seconds);
        _defaultParams.createWithTimestamps.timestamps.start = startTime;

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierHelpers_StartTimeNotLessThanCliffTime.selector, startTime, defaults.CLIFF_TIME()
            )
        );
        lockup.createWithTimestampsLL(_defaultParams.createWithTimestamps, _defaultParams.cliffTime);
    }

    function testFuzz_RevertWhen_CliffTimeNotLessThanEndTime(
        uint40 cliffTime,
        uint40 endTime
    )
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
    {
        uint40 startTime = defaults.START_TIME();
        endTime = boundUint40(endTime, startTime + 1 seconds, startTime + 2 weeks);
        cliffTime = boundUint40(cliffTime, endTime, MAX_UNIX_TIMESTAMP);

        _defaultParams.createWithTimestamps.timestamps.start = startTime;
        _defaultParams.createWithTimestamps.timestamps.end = endTime;

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierHelpers_CliffTimeNotLessThanEndTime.selector, cliffTime, endTime)
        );

        lockup.createWithTimestampsLL(_defaultParams.createWithTimestamps, cliffTime);
    }

    struct Vars {
        uint256 expectedStreamId;
        uint256 actualStreamId;
        uint256 actualNextStreamId;
        address actualNFTOwner;
        Lockup.Status actualStatus;
        Lockup.CreateAmounts createAmounts;
        uint256 expectedNextStreamId;
        address expectedNFTOwner;
        Lockup.Status expectedStatus;
    }

    /// @dev Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - All possible permutations for the funder, sender, recipient, and broker
    /// - Multiple values for the total amount
    /// - Cancelable and not cancelable
    /// - Start time in the past
    /// - Start time in the present
    /// - Start time in the future
    /// - Start time lower than and equal to cliff time
    /// - Cliff time zero and not zero
    /// - Multiple values for the cliff time and the end time
    /// - Multiple values for the broker fee, including zero
    function testFuzz_CreateWithTimestampsLL(
        address funder,
        Lockup.CreateWithTimestamps memory params,
        uint40 cliffTime
    )
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenCliffTimeLessThanEndTime
        whenBrokerFeeNotExceedMaxValue
        whenAssetContract
        whenAssetERC20
    {
        vm.assume(
            funder != address(0) && params.sender != address(0) && params.recipient != address(0)
                && params.broker.account != address(0)
        );
        vm.assume(params.totalAmount != 0);
        params.timestamps.start =
            boundUint40(params.timestamps.start, defaults.START_TIME(), defaults.START_TIME() + 10_000 seconds);
        params.broker.fee = _bound(params.broker.fee, 0, MAX_BROKER_FEE);
        params.transferable = true;

        // The cliff time must be either zero or greater than the start time.
        if (cliffTime > 0) {
            cliffTime = boundUint40(cliffTime, params.timestamps.start + 1 seconds, params.timestamps.start + 52 weeks);
            params.timestamps.end = boundUint40(params.timestamps.end, cliffTime + 1 seconds, MAX_UNIX_TIMESTAMP);
        } else {
            params.timestamps.end =
                boundUint40(params.timestamps.end, params.timestamps.start + 1 seconds, MAX_UNIX_TIMESTAMP);
        }

        // Calculate the fee amounts and the deposit amount.
        Vars memory vars;

        vars.createAmounts.brokerFee = ud(params.totalAmount).mul(params.broker.fee).intoUint128();
        vars.createAmounts.deposit = params.totalAmount - vars.createAmounts.brokerFee;

        // Make the fuzzed funder the caller in this test.
        resetPrank(funder);
        vars.expectedStreamId = lockup.nextStreamId();

        // Mint enough assets to the funder.
        deal({ token: address(dai), to: funder, give: params.totalAmount });

        // Approve {SablierLockup} to transfer the assets from the fuzzed funder.
        dai.approve({ spender: address(lockup), value: MAX_UINT256 });

        // Expect the assets to be transferred from the funder to {SablierLockup}.
        expectCallToTransferFrom({ from: funder, to: address(lockup), value: vars.createAmounts.deposit });

        // Expect the broker fee to be paid to the broker, if not zero.
        if (vars.createAmounts.brokerFee > 0) {
            expectCallToTransferFrom({ from: funder, to: params.broker.account, value: vars.createAmounts.brokerFee });
        }

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockup.CreateLockupLinearStream({
            streamId: vars.expectedStreamId,
            funder: funder,
            sender: params.sender,
            recipient: params.recipient,
            amounts: vars.createAmounts,
            asset: dai,
            cancelable: params.cancelable,
            transferable: params.transferable,
            timestamps: Lockup.Timestamps({ start: params.timestamps.start, end: params.timestamps.end }),
            cliffTime: cliffTime,
            broker: params.broker.account
        });

        params.asset = dai;

        // Create the stream.
        vars.actualStreamId = lockup.createWithTimestampsLL(params, cliffTime);

        // It should create the stream.
        assertEq(lockup.getDepositedAmount(vars.actualStreamId), vars.createAmounts.deposit, "depositedAmount");
        assertEq(lockup.getAsset(vars.actualStreamId), dai, "asset");
        assertEq(lockup.getEndTime(vars.actualStreamId), params.timestamps.end, "endTime");
        assertEq(lockup.isCancelable(vars.actualStreamId), params.cancelable, "isCancelable");
        assertFalse(lockup.isDepleted(vars.actualStreamId), "isDepleted");
        assertTrue(lockup.isStream(vars.actualStreamId), "isStream");
        assertTrue(lockup.isTransferable(vars.actualStreamId), "isTransferable");
        assertEq(lockup.getRecipient(vars.actualStreamId), params.recipient, "recipient");
        assertEq(lockup.getSender(vars.actualStreamId), params.sender, "sender");
        assertEq(lockup.getStartTime(vars.actualStreamId), params.timestamps.start, "startTime");
        assertFalse(lockup.wasCanceled(vars.actualStreamId), "wasCanceled");
        assertEq(lockup.getCliffTime(vars.actualStreamId), cliffTime, "cliff");
        assertEq(lockup.getLockupModel(vars.actualStreamId), Lockup.Model.LOCKUP_LINEAR);

        // Assert that the stream's status is correct.
        vars.actualStatus = lockup.statusOf(vars.actualStreamId);
        vars.expectedStatus =
            params.timestamps.start > getBlockTimestamp() ? Lockup.Status.PENDING : Lockup.Status.STREAMING;
        assertEq(vars.actualStatus, vars.expectedStatus);

        // Assert that the next stream ID has been bumped.
        vars.actualNextStreamId = lockup.nextStreamId();
        vars.expectedNextStreamId = vars.actualStreamId + 1;
        assertEq(vars.actualNextStreamId, vars.expectedNextStreamId, "nextStreamId");
    }
}
