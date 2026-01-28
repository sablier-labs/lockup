// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Escrow } from "src/types/Escrow.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Getters_Integration_Concrete_Test is Integration_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   BTT TREE TESTS
    //////////////////////////////////////////////////////////////////////////*/

    function test_GivenNullOrder() external {
        // It should revert for all getters.
        expectRevert_NullOrder(abi.encodeCall(escrow.getBuyer, (orderIds.nullOrder)), orderIds.nullOrder);
        expectRevert_NullOrder(abi.encodeCall(escrow.getBuyToken, (orderIds.nullOrder)), orderIds.nullOrder);
        expectRevert_NullOrder(abi.encodeCall(escrow.getExpireAt, (orderIds.nullOrder)), orderIds.nullOrder);
        expectRevert_NullOrder(abi.encodeCall(escrow.getMinBuyAmount, (orderIds.nullOrder)), orderIds.nullOrder);
        expectRevert_NullOrder(abi.encodeCall(escrow.getSellAmount, (orderIds.nullOrder)), orderIds.nullOrder);
        expectRevert_NullOrder(abi.encodeCall(escrow.getSeller, (orderIds.nullOrder)), orderIds.nullOrder);
        expectRevert_NullOrder(abi.encodeCall(escrow.getSellToken, (orderIds.nullOrder)), orderIds.nullOrder);
        expectRevert_NullOrder(abi.encodeCall(escrow.statusOf, (orderIds.nullOrder)), orderIds.nullOrder);
        expectRevert_NullOrder(abi.encodeCall(escrow.wasCanceled, (orderIds.nullOrder)), orderIds.nullOrder);
        expectRevert_NullOrder(abi.encodeCall(escrow.wasFilled, (orderIds.nullOrder)), orderIds.nullOrder);
    }

    function test_GivenNotNullOrder() external view givenNotNullOrder {
        // It should return correct buyer.
        assertEq(escrow.getBuyer(orderIds.defaultOrder), address(0), "buyer should be zero address");
        assertEq(escrow.getBuyer(orderIds.designatedBuyerOrder), users.buyer, "designated buyer");

        // It should return correct buy token.
        assertEq(escrow.getBuyToken(orderIds.defaultOrder), buyToken, "buyToken");

        // It should return correct expire at.
        assertEq(escrow.getExpireAt(orderIds.defaultOrder), EXPIRY, "expireAt");

        // It should return correct min buy amount.
        assertEq(escrow.getMinBuyAmount(orderIds.defaultOrder), MIN_BUY_AMOUNT, "minBuyAmount");

        // It should return correct sell amount.
        assertEq(escrow.getSellAmount(orderIds.defaultOrder), SELL_AMOUNT, "sellAmount");

        // It should return correct seller.
        assertEq(escrow.getSeller(orderIds.defaultOrder), users.seller, "seller");

        // It should return correct sell token.
        assertEq(escrow.getSellToken(orderIds.defaultOrder), sellToken, "sellToken");

        // It should return correct status.
        assertEq(escrow.statusOf(orderIds.defaultOrder), Escrow.Status.OPEN, "status");
        assertEq(escrow.statusOf(orderIds.canceledOrder), Escrow.Status.CANCELLED, "canceled status");
        assertEq(escrow.statusOf(orderIds.filledOrder), Escrow.Status.FILLED, "filled status");

        // It should return correct was canceled flag.
        assertFalse(escrow.wasCanceled(orderIds.defaultOrder), "wasCanceled should be false");
        assertTrue(escrow.wasCanceled(orderIds.canceledOrder), "wasCanceled should be true");

        // It should return correct was filled flag.
        assertFalse(escrow.wasFilled(orderIds.defaultOrder), "wasFilled should be false");
        assertTrue(escrow.wasFilled(orderIds.filledOrder), "wasFilled should be true");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      GET BUYER
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetBuyer_RevertGiven_NullOrder() external {
        // It should revert.
        expectRevert_NullOrder(abi.encodeCall(escrow.getBuyer, (orderIds.nullOrder)), orderIds.nullOrder);
    }

    function test_GetBuyer_WhenOrderHasNoBuyer() external view givenNotNullOrder {
        // It should return the zero address.
        address buyer = escrow.getBuyer(orderIds.defaultOrder);
        assertEq(buyer, address(0), "buyer should be zero address");
    }

    function test_GetBuyer_WhenOrderHasDesignatedBuyer() external view givenNotNullOrder {
        // It should return the buyer address.
        address buyer = escrow.getBuyer(orderIds.designatedBuyerOrder);
        assertEq(buyer, users.buyer, "buyer");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    GET BUY TOKEN
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetBuyToken_RevertGiven_NullOrder() external {
        // It should revert.
        expectRevert_NullOrder(abi.encodeCall(escrow.getBuyToken, (orderIds.nullOrder)), orderIds.nullOrder);
    }

    function test_GetBuyToken() external view givenNotNullOrder {
        // It should return the buy token address.
        IERC20 token = escrow.getBuyToken(orderIds.defaultOrder);
        assertEq(token, buyToken, "buyToken");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    GET EXPIRE AT
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetExpireAt_RevertGiven_NullOrder() external {
        // It should revert.
        expectRevert_NullOrder(abi.encodeCall(escrow.getExpireAt, (orderIds.nullOrder)), orderIds.nullOrder);
    }

    function test_GetExpireAt() external view givenNotNullOrder {
        // It should return the expireAt timestamp.
        uint40 expireAt = escrow.getExpireAt(orderIds.defaultOrder);
        assertEq(expireAt, EXPIRY, "expireAt");
    }

    function test_GetExpireAt_WhenZero() external givenNotNullOrder {
        // Create an order that never expires.
        setMsgSender(users.seller);
        uint256 orderId = escrow.createOrder({
            sellToken: sellToken,
            sellAmount: SELL_AMOUNT,
            buyToken: buyToken,
            minBuyAmount: MIN_BUY_AMOUNT,
            buyer: address(0),
            expireAt: ZERO_EXPIRY
        });

        // It should return zero.
        uint40 expireAt = escrow.getExpireAt(orderId);
        assertEq(expireAt, 0, "expireAt should be zero");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 GET MIN BUY AMOUNT
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetMinBuyAmount_RevertGiven_NullOrder() external {
        // It should revert.
        expectRevert_NullOrder(abi.encodeCall(escrow.getMinBuyAmount, (orderIds.nullOrder)), orderIds.nullOrder);
    }

    function test_GetMinBuyAmount() external view givenNotNullOrder {
        // It should return the min buy amount.
        uint128 minBuyAmount = escrow.getMinBuyAmount(orderIds.defaultOrder);
        assertEq(minBuyAmount, MIN_BUY_AMOUNT, "minBuyAmount");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  GET SELL AMOUNT
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetSellAmount_RevertGiven_NullOrder() external {
        // It should revert.
        expectRevert_NullOrder(abi.encodeCall(escrow.getSellAmount, (orderIds.nullOrder)), orderIds.nullOrder);
    }

    function test_GetSellAmount() external view givenNotNullOrder {
        // It should return the sell amount.
        uint128 sellAmount = escrow.getSellAmount(orderIds.defaultOrder);
        assertEq(sellAmount, SELL_AMOUNT, "sellAmount");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     GET SELLER
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetSeller_RevertGiven_NullOrder() external {
        // It should revert.
        expectRevert_NullOrder(abi.encodeCall(escrow.getSeller, (orderIds.nullOrder)), orderIds.nullOrder);
    }

    function test_GetSeller() external view givenNotNullOrder {
        // It should return the seller address.
        address seller = escrow.getSeller(orderIds.defaultOrder);
        assertEq(seller, users.seller, "seller");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   GET SELL TOKEN
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetSellToken_RevertGiven_NullOrder() external {
        // It should revert.
        expectRevert_NullOrder(abi.encodeCall(escrow.getSellToken, (orderIds.nullOrder)), orderIds.nullOrder);
    }

    function test_GetSellToken() external view givenNotNullOrder {
        // It should return the sell token address.
        IERC20 token = escrow.getSellToken(orderIds.defaultOrder);
        assertEq(token, sellToken, "sellToken");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     STATUS OF
    //////////////////////////////////////////////////////////////////////////*/

    function test_StatusOf_RevertGiven_NullOrder() external {
        // It should revert.
        expectRevert_NullOrder(abi.encodeCall(escrow.statusOf, (orderIds.nullOrder)), orderIds.nullOrder);
    }

    function test_StatusOf_Canceled() external view givenNotNullOrder givenOrderCanceled {
        // It should return CANCELLED.
        Escrow.Status status = escrow.statusOf(orderIds.canceledOrder);
        assertEq(status, Escrow.Status.CANCELLED, "status");
    }

    function test_StatusOf_Filled() external view givenNotNullOrder givenOrderFilled {
        // It should return FILLED.
        Escrow.Status status = escrow.statusOf(orderIds.filledOrder);
        assertEq(status, Escrow.Status.FILLED, "status");
    }

    function test_StatusOf_Expired() external givenNotNullOrder givenOrderExpired {
        // It should return EXPIRED.
        // Create an order and let it expire.
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

        Escrow.Status status = escrow.statusOf(orderId);
        assertEq(status, Escrow.Status.EXPIRED, "status");
    }

    function test_StatusOf_Open() external view givenNotNullOrder givenOrderOpen {
        // It should return OPEN.
        Escrow.Status status = escrow.statusOf(orderIds.defaultOrder);
        assertEq(status, Escrow.Status.OPEN, "status");
    }

    function test_StatusOf_OpenNonExpiring() external givenNotNullOrder givenOrderOpen {
        // Create an order that never expires.
        setMsgSender(users.seller);
        uint256 orderId = escrow.createOrder({
            sellToken: sellToken,
            sellAmount: SELL_AMOUNT,
            buyToken: buyToken,
            minBuyAmount: MIN_BUY_AMOUNT,
            buyer: address(0),
            expireAt: ZERO_EXPIRY
        });

        // Warp far into the future.
        vm.warp(block.timestamp + 365 days * 100);

        // It should still return OPEN.
        Escrow.Status status = escrow.statusOf(orderId);
        assertEq(status, Escrow.Status.OPEN, "status should still be OPEN");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    WAS CANCELED
    //////////////////////////////////////////////////////////////////////////*/

    function test_WasCanceled_RevertGiven_NullOrder() external {
        // It should revert.
        expectRevert_NullOrder(abi.encodeCall(escrow.wasCanceled, (orderIds.nullOrder)), orderIds.nullOrder);
    }

    function test_WasCanceled_True() external view givenNotNullOrder {
        // It should return true for canceled order.
        bool result = escrow.wasCanceled(orderIds.canceledOrder);
        assertTrue(result, "wasCanceled should be true");
    }

    function test_WasCanceled_False() external view givenNotNullOrder {
        // It should return false for non-canceled order.
        bool result = escrow.wasCanceled(orderIds.defaultOrder);
        assertFalse(result, "wasCanceled should be false");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     WAS FILLED
    //////////////////////////////////////////////////////////////////////////*/

    function test_WasFilled_RevertGiven_NullOrder() external {
        // It should revert.
        expectRevert_NullOrder(abi.encodeCall(escrow.wasFilled, (orderIds.nullOrder)), orderIds.nullOrder);
    }

    function test_WasFilled_True() external view givenNotNullOrder {
        // It should return true for filled order.
        bool result = escrow.wasFilled(orderIds.filledOrder);
        assertTrue(result, "wasFilled should be true");
    }

    function test_WasFilled_False() external view givenNotNullOrder {
        // It should return false for non-filled order.
        bool result = escrow.wasFilled(orderIds.defaultOrder);
        assertFalse(result, "wasFilled should be false");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   NEXT ORDER ID
    //////////////////////////////////////////////////////////////////////////*/

    function test_NextOrderId() external view {
        // It should return the next order ID.
        uint256 nextId = escrow.nextOrderId();
        // Should be greater than 0 since we've created orders in setUp.
        assertTrue(nextId > 0, "nextOrderId should be greater than 0");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    TRADE FEE
    //////////////////////////////////////////////////////////////////////////*/

    function test_TradeFee() external view {
        // It should return the current trade fee.
        uint256 tradeFee = escrow.tradeFee().unwrap();
        assertEq(tradeFee, DEFAULT_TRADE_FEE.unwrap(), "tradeFee");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  MAX TRADE FEE
    //////////////////////////////////////////////////////////////////////////*/

    function test_MaxTradeFee() external view {
        // It should return the maximum trade fee.
        uint256 maxFee = escrow.MAX_TRADE_FEE().unwrap();
        assertEq(maxFee, MAX_TRADE_FEE.unwrap(), "MAX_TRADE_FEE");
    }
}
