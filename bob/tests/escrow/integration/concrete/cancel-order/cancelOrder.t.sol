// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierEscrow } from "src/interfaces/ISablierEscrow.sol";
import { Escrow } from "src/types/Escrow.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract CancelOrder_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_NullOrder() external {
        // It should revert.
        expectRevert_NullOrder(abi.encodeCall(escrow.cancelOrder, (orderIds.nullOrder)), orderIds.nullOrder);
    }

    function test_RevertWhen_CallerNotSeller() external givenNotNullOrder {
        // It should revert.
        // Create an order as seller.
        setMsgSender(users.seller);
        uint256 orderId = escrow.createOrder({
            sellToken: sellToken,
            sellAmount: SELL_AMOUNT,
            buyToken: buyToken,
            minBuyAmount: MIN_BUY_AMOUNT,
            buyer: address(0),
            expireAt: EXPIRY
        });

        // Try to cancel as buyer (not the seller).
        setMsgSender(users.buyer);
        expectRevert_CallerNotAuthorized(
            abi.encodeCall(escrow.cancelOrder, (orderId)), orderId, users.buyer, users.seller
        );
    }

    function test_RevertGiven_OrderFilled() external givenNotNullOrder whenCallerSeller {
        // It should revert.
        // Create and fill an order.
        setMsgSender(users.seller);
        uint256 orderId = escrow.createOrder({
            sellToken: sellToken,
            sellAmount: SELL_AMOUNT,
            buyToken: buyToken,
            minBuyAmount: MIN_BUY_AMOUNT,
            buyer: address(0),
            expireAt: EXPIRY
        });

        setMsgSender(users.buyer);
        escrow.fillOrder(orderId, MIN_BUY_AMOUNT);

        // Try to cancel the filled order.
        setMsgSender(users.seller);
        expectRevert_OrderFilled(abi.encodeCall(escrow.cancelOrder, (orderId)), orderId);
    }

    function test_RevertGiven_OrderAlreadyCanceled() external givenNotNullOrder whenCallerSeller {
        // It should revert.
        // Create and cancel an order.
        setMsgSender(users.seller);
        uint256 orderId = escrow.createOrder({
            sellToken: sellToken,
            sellAmount: SELL_AMOUNT,
            buyToken: buyToken,
            minBuyAmount: MIN_BUY_AMOUNT,
            buyer: address(0),
            expireAt: EXPIRY
        });

        escrow.cancelOrder(orderId);

        // Try to cancel again.
        expectRevert_OrderCancelled(abi.encodeCall(escrow.cancelOrder, (orderId)), orderId);
    }

    function test_GivenOrderOpenOrExpired() external givenNotNullOrder whenCallerSeller {
        // It should cancel the order and emit {CancelOrder} event.
        // Create an order.
        setMsgSender(users.seller);
        uint256 orderId = escrow.createOrder({
            sellToken: sellToken,
            sellAmount: SELL_AMOUNT,
            buyToken: buyToken,
            minBuyAmount: MIN_BUY_AMOUNT,
            buyer: address(0),
            expireAt: EXPIRY
        });

        // Record balance before cancel.
        uint256 sellerBalanceBefore = sellToken.balanceOf(users.seller);
        uint256 escrowBalanceBefore = sellToken.balanceOf(address(escrow));

        // Expect the CancelOrder event.
        vm.expectEmit({ emitter: address(escrow) });
        emit ISablierEscrow.CancelOrder({ orderId: orderId, seller: users.seller, sellAmount: SELL_AMOUNT });

        // Cancel the order.
        escrow.cancelOrder(orderId);

        // It should mark the order as canceled.
        assertEq(escrow.statusOf(orderId), Escrow.Status.CANCELLED, "order.status");
        assertTrue(escrow.wasCanceled(orderId), "order.wasCanceled");
        assertFalse(escrow.wasFilled(orderId), "order.wasFilled should be false");

        // It should transfer sell tokens back to seller.
        assertEq(sellToken.balanceOf(users.seller), sellerBalanceBefore + SELL_AMOUNT, "seller balance");
        assertEq(sellToken.balanceOf(address(escrow)), escrowBalanceBefore - SELL_AMOUNT, "escrow balance");
    }

    function test_CancelExpiredOrder() external givenNotNullOrder whenCallerSeller givenOrderExpired {
        // It should cancel the order (expired orders can still be canceled by seller).
        // Create an order.
        setMsgSender(users.seller);
        uint256 orderId = escrow.createOrder({
            sellToken: sellToken,
            sellAmount: SELL_AMOUNT,
            buyToken: buyToken,
            minBuyAmount: MIN_BUY_AMOUNT,
            buyer: address(0),
            expireAt: EXPIRY
        });

        // Warp past expiry.
        vm.warp(EXPIRY + 1);

        // Verify the order is expired.
        assertEq(escrow.statusOf(orderId), Escrow.Status.EXPIRED, "order should be expired");

        // Record balance before cancel.
        uint256 sellerBalanceBefore = sellToken.balanceOf(users.seller);

        // Expect the CancelOrder event.
        vm.expectEmit({ emitter: address(escrow) });
        emit ISablierEscrow.CancelOrder({ orderId: orderId, seller: users.seller, sellAmount: SELL_AMOUNT });

        // Cancel the expired order.
        escrow.cancelOrder(orderId);

        // It should mark the order as canceled.
        assertEq(escrow.statusOf(orderId), Escrow.Status.CANCELLED, "order.status should be CANCELLED");
        assertTrue(escrow.wasCanceled(orderId), "order.wasCanceled");

        // It should transfer sell tokens back to seller.
        assertEq(sellToken.balanceOf(users.seller), sellerBalanceBefore + SELL_AMOUNT, "seller balance");
    }

    function test_CancelNonExpiringOrder() external givenNotNullOrder whenCallerSeller {
        // It should cancel an order that never expires.
        // Create an order that never expires.
        setMsgSender(users.seller);
        uint256 orderId = escrow.createOrder({
            sellToken: sellToken,
            sellAmount: SELL_AMOUNT,
            buyToken: buyToken,
            minBuyAmount: MIN_BUY_AMOUNT,
            buyer: address(0),
            expireAt: ZERO_EXPIRY // Never expires
        });

        // Warp far into the future.
        vm.warp(block.timestamp + 365 days * 10);

        // Verify the order is still open (not expired).
        assertEq(escrow.statusOf(orderId), Escrow.Status.OPEN, "order should still be OPEN");

        // Record balance before cancel.
        uint256 sellerBalanceBefore = sellToken.balanceOf(users.seller);

        // Cancel the order.
        escrow.cancelOrder(orderId);

        // It should mark the order as canceled.
        assertEq(escrow.statusOf(orderId), Escrow.Status.CANCELLED, "order.status");
        assertTrue(escrow.wasCanceled(orderId), "order.wasCanceled");

        // It should transfer sell tokens back to seller.
        assertEq(sellToken.balanceOf(users.seller), sellerBalanceBefore + SELL_AMOUNT, "seller balance");
    }
}
