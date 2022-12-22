// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { LinearTest } from "../LinearTest.t.sol";

contract GetReturnableAmount__Test is LinearTest {
    uint256 internal defaultStreamId;

    /// @dev it should return zero.
    function testGetReturnableAmount__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256 actualReturnableAmount = linear.getReturnableAmount(nonStreamId);
        uint256 expectedReturnableAmount = 0;
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }

    modifier StreamExistent() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
        _;
    }

    /// @dev it should return the deposit amount.
    function testGetReturnableAmount__WithdrawableAmountZero__NoWithdrawals() external StreamExistent {
        uint256 actualReturnableAmount = linear.getReturnableAmount(defaultStreamId);
        uint256 expectedReturnableAmount = defaultStream.depositAmount;
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }

    /// @dev it should return the correct returnable amount.
    function testGetReturnableAmount__WithdrawableAmountZero__WithWithdrawals(uint40 timeWarp) external StreamExistent {
        timeWarp = boundUint40(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION * 2);

        // Warp into the future.
        vm.warp({ timestamp: defaultStream.startTime + timeWarp });

        // Withdraw the entire withdrawable amount.
        uint128 withdrawAmount = linear.getWithdrawableAmount(defaultStreamId);
        linear.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });

        // Run the test.
        uint256 actualReturnableAmount = linear.getReturnableAmount(defaultStreamId);
        uint256 expectedReturnableAmount = defaultStream.depositAmount - withdrawAmount;
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }

    /// @dev it should return the correct returnable amount.
    function testGetReturnableAmount__WithdrawableAmountNotZero__NoWithdrawals(
        uint40 timeWarp
    ) external StreamExistent {
        timeWarp = boundUint40(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION * 2);

        // Warp into the future.
        vm.warp({ timestamp: defaultStream.startTime + timeWarp });

        // Get the withdrawable amount.
        uint128 withdrawableAmount = linear.getWithdrawableAmount(defaultStreamId);

        // Run the test.
        uint256 actualReturnableAmount = linear.getReturnableAmount(defaultStreamId);
        uint256 expectedReturnableAmount = defaultStream.depositAmount - withdrawableAmount;
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }

    /// @dev it should return the correct returnable amount.
    function testGetReturnableAmount__WithdrawableAmountNotZero__WithWithdrawals(
        uint40 timeWarp,
        uint128 withdrawAmount
    ) external StreamExistent {
        timeWarp = boundUint40(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION * 2);

        // Warp into the future.
        vm.warp({ timestamp: defaultStream.startTime + timeWarp });

        // Bound the withdraw amount.
        uint128 initialWithdrawableAmount = linear.getWithdrawableAmount(defaultStreamId);
        withdrawAmount = boundUint128(withdrawAmount, 1, initialWithdrawableAmount - 1);

        // Make the withdrawal.
        linear.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });

        // Get the withdrawable amount.
        uint128 withdrawableAmount = linear.getWithdrawableAmount(defaultStreamId);

        // Run the test.
        uint256 actualReturnableAmount = linear.getReturnableAmount(defaultStreamId);
        uint256 expectedReturnableAmount = defaultStream.depositAmount - withdrawAmount - withdrawableAmount;
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }
}
