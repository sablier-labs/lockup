// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Lockup_PriceGated_Integration_Fuzz_Test } from "./LockupPriceGated.t.sol";

contract StreamedAmountOf_Lockup_PriceGated_Integration_Fuzz_Test is Lockup_PriceGated_Integration_Fuzz_Test {
    /// @dev Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - Multiple time jumps before end time
    /// - Oracle price below target
    function testFuzz_StreamedAmountOf_EndTimeInFuture(uint40 timeJump)
        external
        givenNotNull
        whenLatestPriceBelowTarget
    {
        // Bound time jump to be before the end time.
        timeJump = boundUint40(timeJump, 0, defaults.TOTAL_DURATION() - 1);

        // Warp to the specified time.
        vm.warp({ newTimestamp: defaults.START_TIME() + timeJump });

        uint128 actualStreamedAmount = lockup.streamedAmountOf(ids.defaultStream);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    /// @dev Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - Multiple time jumps at or after end time
    /// - Oracle price below target
    function testFuzz_StreamedAmountOf_EndTimeNotInFuture(uint40 timeJump)
        external
        givenNotNull
        whenLatestPriceBelowTarget
    {
        // Bound time jump to be at or after end time.
        timeJump = boundUint40(timeJump, defaults.TOTAL_DURATION(), defaults.TOTAL_DURATION() + 365 days);

        // Warp to the specified time.
        vm.warp({ newTimestamp: defaults.START_TIME() + timeJump });

        // Price is below target but current time is at or after end time, so full amount should be available.
        uint128 actualStreamedAmount = lockup.streamedAmountOf(ids.defaultStream);
        uint128 expectedStreamedAmount = defaults.DEPOSIT_AMOUNT();
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    /// @dev Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - Multiple prices at or above target
    /// - Multiple time jumps
    function testFuzz_StreamedAmountOf_WhenLatestPriceNotBelowTarget(
        uint128 price,
        uint40 timeJump
    )
        external
        givenNotNull
    {
        // Bound oracle price to be over the target price.
        price = uint128(bound(price, defaults.LPG_TARGET_PRICE(), type(uint128).max));

        // Set oracle price.
        oracle.setPrice(price);

        // Bound time jump (can be any time - before or after end).
        timeJump = boundUint40(timeJump, 0, defaults.TOTAL_DURATION() + 365 days);

        // Warp to the specified time.
        vm.warp({ newTimestamp: defaults.START_TIME() + timeJump });

        // Price is at or above target, so full amount should be available regardless of time jump.
        uint128 actualStreamedAmount = lockup.streamedAmountOf(ids.defaultStream);
        uint128 expectedStreamedAmount = defaults.DEPOSIT_AMOUNT();
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }
}
