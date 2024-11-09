// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Lockup } from "src/core/types/DataTypes.sol";

import { Integration_Test } from "./../../Integration.t.sol";

contract WithdrawableAmountOf_Lockup_Dynamic_Integration_Fuzz_Test is Integration_Test {
    /// @dev Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - End time in the past
    /// - End time in the present
    /// - End time in the future
    /// - Status streaming
    /// - Status settled
    function testFuzz_WithdrawableAmountOf_NoPreviousWithdrawals(uint40 timeJump) external givenStartTimeInPast {
        timeJump = boundUint40(timeJump, defaults.CLIFF_DURATION(), defaults.TOTAL_DURATION() * 2);

        // Create the stream with a custom total amount. The broker fee is disabled so that it doesn't interfere with
        // the calculations.
        Lockup.CreateWithTimestamps memory params = defaults.createWithTimestampsBrokerNull();
        uint256 streamId = lockup.createWithTimestampsLD(params, defaults.segments());

        // Simulate the passage of time.
        uint40 blockTimestamp = defaults.START_TIME() + timeJump;
        vm.warp({ newTimestamp: blockTimestamp });

        // Run the test.
        uint128 actualWithdrawableAmount = lockup.withdrawableAmountOf(streamId);
        uint128 expectedWithdrawableAmount =
            calculateLockupDynamicStreamedAmount(defaults.segments(), defaults.START_TIME(), defaults.DEPOSIT_AMOUNT());
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    /// @dev Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - End time in the past
    /// - End time in the present
    /// - End time in the future
    /// - Multiple withdraw amounts
    /// - Status streaming
    /// - Status settled
    /// - Status depleted
    /// - Withdraw amount equal to deposited amount and not
    function testFuzz_WithdrawableAmountOf(
        uint40 timeJump,
        uint128 withdrawAmount
    )
        external
        givenStartTimeInPast
        givenPreviousWithdrawal
    {
        // Create the stream with a custom total amount. The broker fee is disabled so that it doesn't interfere with
        // the calculations.
        Lockup.CreateWithTimestamps memory params = defaults.createWithTimestampsBrokerNull();
        params.totalAmount = defaults.DEPOSIT_AMOUNT();
        uint256 streamId = lockup.createWithTimestampsLD(params, defaults.segments());

        timeJump = boundUint40(timeJump, defaults.CLIFF_DURATION(), defaults.TOTAL_DURATION() * 2);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.START_TIME() + timeJump });

        // Bound the withdraw amount.
        uint128 streamedAmount =
            calculateLockupDynamicStreamedAmount(defaults.segments(), defaults.START_TIME(), defaults.DEPOSIT_AMOUNT());
        withdrawAmount = boundUint128(withdrawAmount, 1, streamedAmount);

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: users.recipient, amount: withdrawAmount });

        // Run the test.
        uint128 actualWithdrawableAmount = lockup.withdrawableAmountOf(streamId);
        uint128 expectedWithdrawableAmount = streamedAmount - withdrawAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }
}
