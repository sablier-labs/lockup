// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { LockupTranched_Integration_Concrete_Test } from "../LockupTranched.t.sol";
import { WithdrawableAmountOf_Integration_Concrete_Test } from
    "../../lockup/withdrawable-amount-of/withdrawableAmountOf.t.sol";

contract WithdrawableAmountOf_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Concrete_Test,
    WithdrawableAmountOf_Integration_Concrete_Test
{
    function setUp()
        public
        virtual
        override(LockupTranched_Integration_Concrete_Test, WithdrawableAmountOf_Integration_Concrete_Test)
    {
        LockupTranched_Integration_Concrete_Test.setUp();
        WithdrawableAmountOf_Integration_Concrete_Test.setUp();
    }

    function test_GivenStartTimeInPresent() external givenSTREAMINGStatus {
        vm.warp({ newTimestamp: defaults.START_TIME() });
        uint128 actualWithdrawableAmount = lockupTranched.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    modifier givenStartTimeInPast() {
        _;
    }

    function test_GivenNoPreviousWithdrawals() external givenSTREAMINGStatus givenStartTimeInPast {
        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.START_TIME() + defaults.CLIFF_DURATION() });

        // Run the test.
        uint128 actualWithdrawableAmount = lockupTranched.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = defaults.tranches()[0].amount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    function test_GivenPreviousWithdrawal() external givenSTREAMINGStatus givenStartTimeInPast {
        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.START_TIME() + defaults.CLIFF_DURATION() });

        // Make the withdrawal.
        lockupTranched.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: defaults.CLIFF_AMOUNT() });

        // Run the test.
        uint128 actualWithdrawableAmount = lockupTranched.withdrawableAmountOf(defaultStreamId);

        uint128 expectedWithdrawableAmount = defaults.tranches()[0].amount - defaults.CLIFF_AMOUNT();
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }
}
