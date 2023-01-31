// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Fuzz_Test } from "../../../Fuzz.t.sol";

abstract contract ReturnableAmountOf_Fuzz_Test is Fuzz_Test, Lockup_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Fuzz_Test, Lockup_Shared_Test) {}

    modifier streamActive() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
        _;
    }

    /// @dev it should return the correct returnable amount.
    function testFuzz_ReturnableAmountOf(uint256 timeWarp) external streamActive {
        timeWarp = bound(timeWarp, 0, DEFAULT_TOTAL_DURATION * 2);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Get the streamed amount.
        uint128 streamedAmount = lockup.streamedAmountOf(defaultStreamId);

        // Run the test.
        uint256 actualReturnableAmount = lockup.returnableAmountOf(defaultStreamId);
        uint256 expectedReturnableAmount = DEFAULT_NET_DEPOSIT_AMOUNT - streamedAmount;
        assertEq(actualReturnableAmount, expectedReturnableAmount, "returnableAmount");
    }
}
