// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud, UD60x18 } from "@prb/math/src/UD60x18.sol";

import { ISablierEscrow } from "src/interfaces/ISablierEscrow.sol";
import { SablierEscrow } from "src/SablierEscrow.sol";
import { Escrow } from "src/types/Escrow.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract FillOrder_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_NullOrder() external {
        // It should revert.
        setMsgSender(users.buyer);
        expectRevert_NullOrder(abi.encodeCall(escrow.fillOrder, (orderIds.nullOrder, BUY_AMOUNT)), orderIds.nullOrder);
    }

    function test_RevertGiven_OrderCanceled() external givenNotNullOrder {
        // It should revert.
        setMsgSender(users.buyer);
        expectRevert_OrderNotOpen(
            abi.encodeCall(escrow.fillOrder, (orderIds.canceledOrder, BUY_AMOUNT)),
            orderIds.canceledOrder,
            Escrow.Status.CANCELLED
        );
    }

    function test_RevertGiven_OrderFilled() external givenNotNullOrder {
        // It should revert.
        setMsgSender(users.buyer);
        expectRevert_OrderNotOpen(
            abi.encodeCall(escrow.fillOrder, (orderIds.filledOrder, BUY_AMOUNT)),
            orderIds.filledOrder,
            Escrow.Status.FILLED
        );
    }

    function test_RevertGiven_OrderExpired() external givenNotNullOrder {
        // It should revert.
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

        setMsgSender(users.buyer);
        expectRevert_OrderNotOpen(
            abi.encodeCall(escrow.fillOrder, (orderId, BUY_AMOUNT)), orderId, Escrow.Status.EXPIRED
        );
    }

    function test_RevertWhen_CallerNotDesignatedBuyer()
        external
        givenNotNullOrder
        givenOrderOpen
        givenOrderHasDesignatedBuyer
    {
        // It should revert.
        // Create an order with designated buyer.
        setMsgSender(users.seller);
        uint256 orderId = escrow.createOrder({
            sellToken: sellToken,
            sellAmount: SELL_AMOUNT,
            buyToken: buyToken,
            minBuyAmount: MIN_BUY_AMOUNT,
            buyer: users.buyer, // Designated buyer
            expireAt: EXPIRY
        });

        // Try to fill with a different buyer.
        setMsgSender(users.buyer2);
        expectRevert_CallerNotAuthorized(
            abi.encodeCall(escrow.fillOrder, (orderId, BUY_AMOUNT)), orderId, users.buyer2, users.buyer
        );
    }

    function test_WhenCallerDesignatedBuyer()
        external
        givenNotNullOrder
        givenOrderOpen
        givenOrderHasDesignatedBuyer
        whenCallerDesignatedBuyer
    {
        // It should fill the order.
        // Create an order with designated buyer.
        setMsgSender(users.seller);
        uint256 orderId = escrow.createOrder({
            sellToken: sellToken,
            sellAmount: SELL_AMOUNT,
            buyToken: buyToken,
            minBuyAmount: MIN_BUY_AMOUNT,
            buyer: users.buyer,
            expireAt: EXPIRY
        });

        // Fill with designated buyer.
        setMsgSender(users.buyer);

        // Get the current trade fee.
        UD60x18 currentTradeFee = escrow.tradeFee();
        uint128 feeFromSellAmount = ud(SELL_AMOUNT).mul(currentTradeFee).intoUint128();
        uint128 feeFromBuyAmount = ud(BUY_AMOUNT).mul(currentTradeFee).intoUint128();
        uint128 sellAmountAfterFee = SELL_AMOUNT - feeFromSellAmount;
        uint128 buyAmountAfterFee = BUY_AMOUNT - feeFromBuyAmount;

        // Expect the FillOrder event.
        vm.expectEmit({ emitter: address(escrow) });
        emit ISablierEscrow.FillOrder({
            orderId: orderId,
            buyer: users.buyer,
            seller: users.seller,
            sellAmount: sellAmountAfterFee,
            buyAmount: buyAmountAfterFee,
            feeDeductedFromBuyerAmount: feeFromSellAmount,
            feeDeductedFromSellerAmount: feeFromBuyAmount
        });

        escrow.fillOrder(orderId, BUY_AMOUNT);

        // Assert the order is now filled.
        assertEq(escrow.statusOf(orderId), Escrow.Status.FILLED, "order.status");
        assertTrue(escrow.wasFilled(orderId), "order.wasFilled");
    }

    function test_RevertWhen_BuyAmountInsufficient() external givenNotNullOrder givenOrderOpen givenOrderHasNoBuyer {
        // It should revert.
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

        // Try to fill with insufficient buy amount.
        setMsgSender(users.buyer);
        uint128 insufficientAmount = MIN_BUY_AMOUNT - 1;
        expectRevert_InsufficientBuyAmount(
            abi.encodeCall(escrow.fillOrder, (orderId, insufficientAmount)), insufficientAmount, MIN_BUY_AMOUNT
        );
    }

    function test_GivenTradeFeeZero()
        external
        givenNotNullOrder
        givenOrderOpen
        givenOrderHasNoBuyer
        whenBuyAmountSufficient
    {
        // It should fill the order without fees.
        // Deploy a new escrow with zero fee.
        SablierEscrow zeroFeeEscrow = new SablierEscrow(address(comptroller), ZERO_TRADE_FEE);

        // Approve the new escrow.
        setMsgSender(users.seller);
        sellToken.approve(address(zeroFeeEscrow), type(uint256).max);

        setMsgSender(users.buyer);
        buyToken.approve(address(zeroFeeEscrow), type(uint256).max);

        // Create an order.
        setMsgSender(users.seller);
        uint256 orderId = zeroFeeEscrow.createOrder({
            sellToken: sellToken,
            sellAmount: SELL_AMOUNT,
            buyToken: buyToken,
            minBuyAmount: MIN_BUY_AMOUNT,
            buyer: address(0),
            expireAt: EXPIRY
        });

        // Record balances before fill.
        uint256 sellerSellTokenBefore = sellToken.balanceOf(users.seller);
        uint256 sellerBuyTokenBefore = buyToken.balanceOf(users.seller);
        uint256 buyerSellTokenBefore = sellToken.balanceOf(users.buyer);
        uint256 buyerBuyTokenBefore = buyToken.balanceOf(users.buyer);
        uint256 comptrollerSellTokenBefore = sellToken.balanceOf(address(comptroller));
        uint256 comptrollerBuyTokenBefore = buyToken.balanceOf(address(comptroller));

        // Expect the FillOrder event with zero fees.
        vm.expectEmit({ emitter: address(zeroFeeEscrow) });
        emit ISablierEscrow.FillOrder({
            orderId: orderId,
            buyer: users.buyer,
            seller: users.seller,
            sellAmount: SELL_AMOUNT, // Full amount, no fee
            buyAmount: BUY_AMOUNT, // Full amount, no fee
            feeDeductedFromBuyerAmount: 0,
            feeDeductedFromSellerAmount: 0
        });

        // Fill the order.
        setMsgSender(users.buyer);
        zeroFeeEscrow.fillOrder(orderId, BUY_AMOUNT);

        // Assert the order is now filled.
        assertEq(zeroFeeEscrow.statusOf(orderId), Escrow.Status.FILLED, "order.status");
        assertTrue(zeroFeeEscrow.wasFilled(orderId), "order.wasFilled");

        // Assert balances - full amounts transferred with no fees.
        assertEq(sellToken.balanceOf(users.seller), sellerSellTokenBefore, "seller sell token unchanged");
        assertEq(buyToken.balanceOf(users.seller), sellerBuyTokenBefore + BUY_AMOUNT, "seller received buy tokens");
        assertEq(sellToken.balanceOf(users.buyer), buyerSellTokenBefore + SELL_AMOUNT, "buyer received sell tokens");
        assertEq(buyToken.balanceOf(users.buyer), buyerBuyTokenBefore - BUY_AMOUNT, "buyer sent buy tokens");
        assertEq(sellToken.balanceOf(address(comptroller)), comptrollerSellTokenBefore, "comptroller no sell fee");
        assertEq(buyToken.balanceOf(address(comptroller)), comptrollerBuyTokenBefore, "comptroller no buy fee");
    }

    function test_GivenTradeFeeNonzero()
        external
        givenNotNullOrder
        givenOrderOpen
        givenOrderHasNoBuyer
        whenBuyAmountSufficient
    {
        // It should fill the order and deduct fees.
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

        // Record balances before fill.
        uint256 sellerSellTokenBefore = sellToken.balanceOf(users.seller);
        uint256 sellerBuyTokenBefore = buyToken.balanceOf(users.seller);
        uint256 buyerSellTokenBefore = sellToken.balanceOf(users.buyer);
        uint256 buyerBuyTokenBefore = buyToken.balanceOf(users.buyer);
        uint256 comptrollerSellTokenBefore = sellToken.balanceOf(address(comptroller));
        uint256 comptrollerBuyTokenBefore = buyToken.balanceOf(address(comptroller));

        // Calculate expected fees (1% default trade fee).
        UD60x18 currentTradeFee = escrow.tradeFee();
        uint128 feeFromSellAmount = ud(SELL_AMOUNT).mul(currentTradeFee).intoUint128();
        uint128 feeFromBuyAmount = ud(BUY_AMOUNT).mul(currentTradeFee).intoUint128();
        uint128 sellAmountAfterFee = SELL_AMOUNT - feeFromSellAmount;
        uint128 buyAmountAfterFee = BUY_AMOUNT - feeFromBuyAmount;

        // Expect the FillOrder event.
        vm.expectEmit({ emitter: address(escrow) });
        emit ISablierEscrow.FillOrder({
            orderId: orderId,
            buyer: users.buyer,
            seller: users.seller,
            sellAmount: sellAmountAfterFee,
            buyAmount: buyAmountAfterFee,
            feeDeductedFromBuyerAmount: feeFromSellAmount,
            feeDeductedFromSellerAmount: feeFromBuyAmount
        });

        // Fill the order.
        setMsgSender(users.buyer);
        escrow.fillOrder(orderId, BUY_AMOUNT);

        // Assert the order is now filled.
        assertEq(escrow.statusOf(orderId), Escrow.Status.FILLED, "order.status");
        assertTrue(escrow.wasFilled(orderId), "order.wasFilled");

        // Assert balances with fees deducted.
        assertEq(sellToken.balanceOf(users.seller), sellerSellTokenBefore, "seller sell token unchanged");
        assertEq(
            buyToken.balanceOf(users.seller), sellerBuyTokenBefore + buyAmountAfterFee, "seller received buy tokens"
        );
        assertEq(
            sellToken.balanceOf(users.buyer), buyerSellTokenBefore + sellAmountAfterFee, "buyer received sell tokens"
        );
        assertEq(buyToken.balanceOf(users.buyer), buyerBuyTokenBefore - BUY_AMOUNT, "buyer sent buy tokens");
        assertEq(
            sellToken.balanceOf(address(comptroller)),
            comptrollerSellTokenBefore + feeFromSellAmount,
            "comptroller received sell fee"
        );
        assertEq(
            buyToken.balanceOf(address(comptroller)),
            comptrollerBuyTokenBefore + feeFromBuyAmount,
            "comptroller received buy fee"
        );
    }

    function test_FillOrderAtExactMinBuyAmount()
        external
        givenNotNullOrder
        givenOrderOpen
        givenOrderHasNoBuyer
        whenBuyAmountSufficient
    {
        // It should fill the order when buy amount equals min buy amount.
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

        // Fill with exact min buy amount.
        setMsgSender(users.buyer);
        escrow.fillOrder(orderId, MIN_BUY_AMOUNT);

        // Assert the order is now filled.
        assertEq(escrow.statusOf(orderId), Escrow.Status.FILLED, "order.status");
        assertTrue(escrow.wasFilled(orderId), "order.wasFilled");
    }
}
