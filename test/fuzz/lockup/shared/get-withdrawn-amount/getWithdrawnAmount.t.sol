// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Fuzz_Test } from "../../../Fuzz.t.sol";

abstract contract GetWithdrawnAmount_Fuzz_Test is Fuzz_Test, Lockup_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Fuzz_Test, Lockup_Shared_Test) {
        // Make the recipient the caller in this test suite.
        changePrank({ who: users.recipient });
    }

    modifier streamNonNull() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
        _;
    }

    /// @dev it should return zero.
    function testFuzz_GetWithdrawnAmount_NoWithdrawals(uint256 timeWarp) external streamNonNull {
        timeWarp = bound(timeWarp, 0, DEFAULT_TOTAL_DURATION * 2);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Assert that the withdrawn amount was updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = 0;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    /// @dev it should return the correct withdrawn amount.
    function testFuzz_GetWithdrawnAmount_WithWithdrawals(
        uint256 timeWarp,
        uint128 withdrawAmount
    ) external streamNonNull {
        timeWarp = bound(timeWarp, DEFAULT_CLIFF_TIME, DEFAULT_TOTAL_DURATION - 1);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Bound the withdraw amount.
        uint128 streamedAmount = lockup.streamedAmountOf(defaultStreamId);
        withdrawAmount = boundUint128(withdrawAmount, 1, streamedAmount);

        // Make the withdrawal.
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });

        // Assert that the withdrawn amount was updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }
}
