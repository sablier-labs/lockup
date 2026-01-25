// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud, convert } from "@prb/math/src/UD60x18.sol";
import { console } from "forge-std/src/console.sol";
import { Lockup } from "src/types/Lockup.sol";
import { LockupLinear } from "src/types/LockupLinear.sol";
import { Integration_Test } from "./../../Integration.t.sol";

/// @notice Test demonstrating rounding issue where G>1 can exceed G=1 streamed amount
contract GranularityRounding_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();
        lockupModel = Lockup.Model.LOCKUP_LINEAR;
    }

    /// @dev Demonstrates that streamedAmountOf with granularity=7 can exceed
    ///      the calculated amount with granularity=1 due to denominator truncation.
    function test_GranularityRoundingViolation() external {
        console.log("ud(1)", ud(1).unwrap());
        console.log("convert(1)", convert(1).unwrap());

        console.log("ud(100).div(ud(granularity))", ud(100).div(ud(7)).unwrap());

        // Specific values that trigger the rounding issue:
        // - elapsed / granularity = 49 / 7 = 7 (exact, no truncation)
        // - duration * 1e18 / granularity = 100e18 / 7 = 14285714285714285714 (TRUNCATED)
        // Dividing by truncated denominator gives LARGER result

        uint40 startTime = getBlockTimestamp();
        uint40 cliffTime = 0; // No cliff for simplicity
        uint40 duration = 100 seconds;
        uint40 endTime = startTime + duration;
        uint40 granularity = 7 seconds; // Key: 100 is not divisible by 7
        uint128 depositAmount = 1e27; // Large amount to see the rounding effect

        // Create stream params
        Lockup.CreateWithTimestamps memory params = Lockup.CreateWithTimestamps({
            sender: users.sender,
            recipient: users.recipient,
            depositAmount: depositAmount,
            token: dai,
            cancelable: true,
            transferable: true,
            timestamps: Lockup.Timestamps({ start: startTime, end: endTime }),
            shape: "Linear"
        });

        LockupLinear.UnlockAmounts memory unlockAmounts = LockupLinear.UnlockAmounts({ start: 0, cliff: 0 });

        // Create the stream with granularity = 7
        uint256 streamId = lockup.createWithTimestampsLL(params, unlockAmounts, granularity, cliffTime);

        // Warp to elapsed = 49 seconds (exactly divisible by 7)
        vm.warp(startTime + 49 seconds);

        // Get actual streamed amount from contract (uses granularity = 7)
        uint128 actualStreamed = lockup.streamedAmountOf(streamId);

        // Calculate what would be streamed with granularity = 1
        uint128 streamedIfGranularity1 = calculateStreamedAmountLL({
            startTime: startTime,
            cliffTime: cliffTime,
            endTime: endTime,
            depositAmount: depositAmount,
            unlockAmounts: unlockAmounts,
            granularity: 1 seconds
        });

        console.log("Actual streamed (G=7):", actualStreamed);
        console.log("Streamed if G=1:", streamedIfGranularity1);

        // This assertion demonstrates the violation:
        // actualStreamed (with G=7) > streamedIfGranularity1 (with G=1)
        assertGt(
            actualStreamed, streamedIfGranularity1, "Expected: actualStreamed > streamedIfGranularity1 due to rounding"
        );
    }

    function test_weekly_unlocks() public {
        _defaultParams.cliffTime = 0;
        _defaultParams.unlockAmounts.cliff = 0;
        _defaultParams.createWithTimestamps.depositAmount = 52e18;
        _defaultParams.createWithTimestamps.timestamps.end =
            _defaultParams.createWithTimestamps.timestamps.start + (1 weeks * 52); // almost 1 Y duration
        _defaultParams.granularity = 1 weeks;

        uint256 id = createDefaultStream();

        vm.warp(_defaultParams.createWithTimestamps.timestamps.start + 1 + (1 weeks * 51));
        assertEq(lockup.streamedAmountOf(id), 51e18);
    }

    function test_overflow() public {
        // elapsedTimeInGranularityUnits * streamableAmount * granularity * 1e18

        uint256 a = type(uint40).max;
        uint256 b = type(uint128).max;
        uint256 c = type(uint40).max;
        uint256 result = a * b * c * 1e18;
        console.log("Overflow test result:", result);
    }
}
