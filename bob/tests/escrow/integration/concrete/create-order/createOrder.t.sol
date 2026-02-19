// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierEscrow } from "src/interfaces/ISablierEscrow.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Escrow } from "src/types/Escrow.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract CreateOrder_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_SellTokenZero() external {
        // It should revert.
        vm.expectRevert(Errors.SablierEscrow_SellTokenZero.selector);
        escrow.createOrder({
            sellToken: IERC20(address(0)),
            sellAmount: SELL_AMOUNT,
            buyToken: buyToken,
            minBuyAmount: MIN_BUY_AMOUNT,
            buyer: users.buyer,
            expiryTime: ORDER_EXPIRY_TIME
        });
    }

    function test_RevertWhen_SellTokenIsNativeToken() external whenSellTokenNotZero {
        // Set the native token to the sell token.
        setMsgSender(address(comptroller));
        escrow.setNativeToken(address(sellToken));
        setMsgSender(users.seller);

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierEscrow_ForbidNativeToken.selector, address(sellToken)));
        escrow.createOrder({
            sellToken: sellToken,
            sellAmount: SELL_AMOUNT,
            buyToken: buyToken,
            minBuyAmount: MIN_BUY_AMOUNT,
            buyer: users.buyer,
            expiryTime: ORDER_EXPIRY_TIME
        });
    }

    function test_RevertWhen_BuyTokenZero() external whenSellTokenNotZero whenSellTokenNotNativeToken {
        // It should revert.
        vm.expectRevert(Errors.SablierEscrow_BuyTokenZero.selector);
        escrow.createOrder({
            sellToken: sellToken,
            sellAmount: SELL_AMOUNT,
            buyToken: IERC20(address(0)),
            minBuyAmount: MIN_BUY_AMOUNT,
            buyer: users.buyer,
            expiryTime: ORDER_EXPIRY_TIME
        });
    }

    function test_RevertWhen_BuyTokenIsNativeToken()
        external
        whenSellTokenNotZero
        whenSellTokenNotNativeToken
        whenBuyTokenNotZero
    {
        // Set the native token to the buy token.
        setMsgSender(address(comptroller));
        escrow.setNativeToken(address(buyToken));
        setMsgSender(users.seller);

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierEscrow_ForbidNativeToken.selector, address(buyToken)));
        escrow.createOrder({
            sellToken: sellToken,
            sellAmount: SELL_AMOUNT,
            buyToken: buyToken,
            minBuyAmount: MIN_BUY_AMOUNT,
            buyer: users.buyer,
            expiryTime: ORDER_EXPIRY_TIME
        });
    }

    function test_RevertWhen_TokensSame()
        external
        whenSellTokenNotZero
        whenSellTokenNotNativeToken
        whenBuyTokenNotZero
        whenBuyTokenNotNativeToken
    {
        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierEscrow_SameToken.selector, sellToken));
        escrow.createOrder({
            sellToken: sellToken,
            sellAmount: SELL_AMOUNT,
            buyToken: sellToken,
            minBuyAmount: MIN_BUY_AMOUNT,
            buyer: users.buyer,
            expiryTime: ORDER_EXPIRY_TIME
        });
    }

    function test_RevertWhen_SellAmountZero()
        external
        whenSellTokenNotZero
        whenSellTokenNotNativeToken
        whenBuyTokenNotZero
        whenBuyTokenNotNativeToken
        whenTokensNotSame
    {
        // It should revert.
        vm.expectRevert(Errors.SablierEscrow_SellAmountZero.selector);
        escrow.createOrder({
            sellToken: sellToken,
            sellAmount: 0,
            buyToken: buyToken,
            minBuyAmount: MIN_BUY_AMOUNT,
            buyer: users.buyer,
            expiryTime: ORDER_EXPIRY_TIME
        });
    }

    function test_RevertWhen_MinBuyAmountZero()
        external
        whenSellTokenNotZero
        whenSellTokenNotNativeToken
        whenBuyTokenNotZero
        whenBuyTokenNotNativeToken
        whenTokensNotSame
        whenSellAmountNotZero
    {
        // It should revert.
        vm.expectRevert(Errors.SablierEscrow_MinBuyAmountZero.selector);
        escrow.createOrder({
            sellToken: sellToken,
            sellAmount: SELL_AMOUNT,
            buyToken: buyToken,
            minBuyAmount: 0,
            buyer: users.buyer,
            expiryTime: ORDER_EXPIRY_TIME
        });
    }

    function test_WhenExpiryTimeZero()
        external
        whenSellTokenNotZero
        whenSellTokenNotNativeToken
        whenBuyTokenNotZero
        whenBuyTokenNotNativeToken
        whenTokensNotSame
        whenSellAmountNotZero
        whenMinBuyAmountNotZero
    {
        _testCreateOrder({ buyer: users.buyer, expiryTime: 0 });
    }

    function test_RevertWhen_ExpiryTimeNotInFuture()
        external
        whenSellTokenNotZero
        whenSellTokenNotNativeToken
        whenBuyTokenNotZero
        whenBuyTokenNotNativeToken
        whenTokensNotSame
        whenSellAmountNotZero
        whenMinBuyAmountNotZero
        whenExpiryTimeNotZero
    {
        uint40 expiryTime = getBlockTimestamp() - 1;

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierEscrow_ExpiryTimeInPast.selector, expiryTime, getBlockTimestamp())
        );
        escrow.createOrder({
            sellToken: sellToken,
            sellAmount: SELL_AMOUNT,
            buyToken: buyToken,
            minBuyAmount: MIN_BUY_AMOUNT,
            buyer: users.buyer,
            expiryTime: expiryTime
        });
    }

    function test_WhenNoDesignatedBuyer()
        external
        whenSellTokenNotZero
        whenSellTokenNotNativeToken
        whenBuyTokenNotZero
        whenBuyTokenNotNativeToken
        whenTokensNotSame
        whenSellAmountNotZero
        whenMinBuyAmountNotZero
        whenExpiryTimeNotZero
        whenExpiryTimeInFuture
    {
        _testCreateOrder({ buyer: address(0), expiryTime: ORDER_EXPIRY_TIME });
    }

    function test_WhenDesignatedBuyer()
        external
        whenSellTokenNotZero
        whenSellTokenNotNativeToken
        whenBuyTokenNotZero
        whenBuyTokenNotNativeToken
        whenTokensNotSame
        whenSellAmountNotZero
        whenMinBuyAmountNotZero
        whenExpiryTimeNotZero
        whenExpiryTimeInFuture
    {
        _testCreateOrder({ buyer: users.buyer, expiryTime: ORDER_EXPIRY_TIME });
    }

    /// @dev Private shared logic.
    function _testCreateOrder(address buyer, uint40 expiryTime) private {
        uint256 expectedOrderId = escrow.nextOrderId();

        // It should perform the ERC-20 transfers.
        expectCallToTransferFrom({ token: sellToken, from: users.seller, to: address(escrow), value: SELL_AMOUNT });

        // It should emit a {CreateOrder} event.
        vm.expectEmit({ emitter: address(escrow) });
        emit ISablierEscrow.CreateOrder({
            orderId: expectedOrderId,
            seller: users.seller,
            buyer: buyer,
            sellToken: sellToken,
            buyToken: buyToken,
            sellAmount: SELL_AMOUNT,
            minBuyAmount: MIN_BUY_AMOUNT,
            expiryTime: expiryTime
        });

        uint256 orderId = escrow.createOrder({
            sellToken: sellToken,
            sellAmount: SELL_AMOUNT,
            buyToken: buyToken,
            minBuyAmount: MIN_BUY_AMOUNT,
            buyer: buyer,
            expiryTime: expiryTime
        });

        // It should create the order.
        assertEq(orderId, expectedOrderId, "orderId");
        assertEq(escrow.getSeller(orderId), users.seller, "order.seller");
        assertEq(escrow.getBuyer(orderId), buyer, "order.buyer");
        assertEq(escrow.getSellToken(orderId), sellToken, "order.sellToken");
        assertEq(escrow.getBuyToken(orderId), buyToken, "order.buyToken");
        assertEq(escrow.getSellAmount(orderId), SELL_AMOUNT, "order.sellAmount");
        assertEq(escrow.getMinBuyAmount(orderId), MIN_BUY_AMOUNT, "order.minBuyAmount");
        assertEq(escrow.getExpiryTime(orderId), expiryTime, "order.expiryTime");
        assertEq(escrow.tradeFee(), DEFAULT_TRADE_FEE, "escrow.tradeFee");
        assertFalse(escrow.wasCanceled(orderId), "order.wasCanceled");
        assertFalse(escrow.wasFilled(orderId), "order.wasFilled");

        // It should update the status.
        assertEq(escrow.statusOf(orderId), Escrow.Status.OPEN, "order.status");

        // It should bump the next order ID.
        assertEq(escrow.nextOrderId(), orderId + 1, "nextOrderId");
    }
}
