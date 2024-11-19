// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Integration_Test } from "../../../Integration.t.sol";

abstract contract RefundableAmountOf_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_Null() external {
        expectRevert_Null({ callData: abi.encodeCall(lockup.refundableAmountOf, nullStreamId) });
    }

    function test_GivenNonCancelableStream() external givenNotNull {
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });
        uint128 actualRefundableAmount = lockup.refundableAmountOf(notCancelableStreamId);
        uint128 expectedRefundableAmount = 0;
        assertEq(actualRefundableAmount, expectedRefundableAmount, "refundableAmount");
    }

    function test_GivenCanceledStreamAndCANCELEDStatus() external givenNotNull givenCancelableStream {
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });
        lockup.cancel(defaultStreamId);
        uint128 actualRefundableAmount = lockup.refundableAmountOf(defaultStreamId);
        uint128 expectedRefundableAmount = 0;
        assertEq(actualRefundableAmount, expectedRefundableAmount, "refundableAmount");
    }

    function test_GivenCanceledStreamAndDEPLETEDStatus() external givenNotNull givenCancelableStream {
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });
        lockup.cancel(defaultStreamId);
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() + 10 seconds });
        uint128 actualRefundableAmount = lockup.refundableAmountOf(defaultStreamId);
        uint128 expectedRefundableAmount = 0;
        assertEq(actualRefundableAmount, expectedRefundableAmount, "refundableAmount");
    }

    function test_GivenPENDINGStatus() external givenNotNull givenCancelableStream givenNotCanceledStream {
        vm.warp({ newTimestamp: getBlockTimestamp() - 1 seconds });
        uint128 actualRefundableAmount = lockup.refundableAmountOf(defaultStreamId);
        uint128 expectedReturnableAmount = defaults.DEPOSIT_AMOUNT();
        assertEq(actualRefundableAmount, expectedReturnableAmount, "refundableAmount");
    }

    function test_GivenSTREAMINGStatus() external givenNotNull givenCancelableStream givenNotCanceledStream {
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });
        uint128 actualRefundableAmount = lockup.refundableAmountOf(defaultStreamId);
        uint128 expectedReturnableAmount = defaults.REFUND_AMOUNT();
        assertEq(actualRefundableAmount, expectedReturnableAmount, "refundableAmount");
    }

    function test_GivenSETTLEDStatus() external givenNotNull givenCancelableStream givenNotCanceledStream {
        vm.warp({ newTimestamp: defaults.END_TIME() });
        uint128 actualRefundableAmount = lockup.refundableAmountOf(defaultStreamId);
        uint128 expectedReturnableAmount = 0;
        assertEq(actualRefundableAmount, expectedReturnableAmount, "refundableAmount");
    }

    function test_GivenDEPLETEDStatus() external givenNotNull givenCancelableStream givenNotCanceledStream {
        vm.warp({ newTimestamp: defaults.END_TIME() });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        uint128 actualRefundableAmount = lockup.refundableAmountOf(defaultStreamId);
        uint128 expectedReturnableAmount = 0;
        assertEq(actualRefundableAmount, expectedReturnableAmount, "refundableAmount");
    }
}
