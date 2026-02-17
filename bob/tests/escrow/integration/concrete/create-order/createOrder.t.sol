// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierEscrow } from "src/interfaces/ISablierEscrow.sol";
import { Escrow } from "src/types/Escrow.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract CreateOrder_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_SellTokenZero() external {
        // It should revert.
        expectRevert_SellTokenZero(
            abi.encodeCall(
                escrow.createOrder, (IERC20(address(0)), SELL_AMOUNT, buyToken, MIN_BUY_AMOUNT, address(0), EXPIRY)
            )
        );
    }

    function test_RevertWhen_BuyTokenZero() external whenSellTokenNotZero {
        // It should revert.
        expectRevert_BuyTokenZero(
            abi.encodeCall(
                escrow.createOrder, (sellToken, SELL_AMOUNT, IERC20(address(0)), MIN_BUY_AMOUNT, address(0), EXPIRY)
            )
        );
    }

    function test_RevertWhen_TokensSame() external whenSellTokenNotZero whenBuyTokenNotZero {
        // It should revert.
        expectRevert_SameToken(
            abi.encodeCall(escrow.createOrder, (sellToken, SELL_AMOUNT, sellToken, MIN_BUY_AMOUNT, address(0), EXPIRY)),
            sellToken
        );
    }

    function test_RevertWhen_SellAmountZero() external whenSellTokenNotZero whenBuyTokenNotZero whenTokensNotSame {
        // It should revert.
        expectRevert_SellAmountZero(
            abi.encodeCall(escrow.createOrder, (sellToken, 0, buyToken, MIN_BUY_AMOUNT, address(0), EXPIRY))
        );
    }

    function test_RevertWhen_MinBuyAmountZero()
        external
        whenSellTokenNotZero
        whenBuyTokenNotZero
        whenTokensNotSame
        whenSellAmountNotZero
    {
        // It should revert.
        expectRevert_MinBuyAmountZero(
            abi.encodeCall(escrow.createOrder, (sellToken, SELL_AMOUNT, buyToken, 0, address(0), EXPIRY))
        );
    }

    function test_RevertWhen_ExpiryTimeInPast()
        external
        whenSellTokenNotZero
        whenBuyTokenNotZero
        whenTokensNotSame
        whenSellAmountNotZero
        whenMinBuyAmountNotZero
    {
        // It should revert.
        uint40 pastExpiry = uint40(block.timestamp - 1);
        expectRevert_ExpiryTimeInPast(
            abi.encodeCall(
                escrow.createOrder, (sellToken, SELL_AMOUNT, buyToken, MIN_BUY_AMOUNT, address(0), pastExpiry)
            ),
            pastExpiry,
            uint40(block.timestamp)
        );
    }

    function test_GivenNoDesignatedBuyer()
        external
        whenSellTokenNotZero
        whenBuyTokenNotZero
        whenTokensNotSame
        whenSellAmountNotZero
        whenMinBuyAmountNotZero
        whenExpiryTimeValidOrZero
    {
        // It should create the order open to anyone.
        uint256 expectedOrderId = escrow.nextOrderId();
        uint256 sellerBalanceBefore = sellToken.balanceOf(users.seller);
        uint256 escrowBalanceBefore = sellToken.balanceOf(address(escrow));

        // Expect the CreateOrder event.
        vm.expectEmit({ emitter: address(escrow) });
        emit ISablierEscrow.CreateOrder({
            orderId: expectedOrderId,
            seller: users.seller,
            buyer: address(0),
            sellToken: sellToken,
            buyToken: buyToken,
            sellAmount: SELL_AMOUNT,
            minBuyAmount: MIN_BUY_AMOUNT,
            expiryTime: EXPIRY
        });

        // Create the order.
        uint256 orderId = escrow.createOrder({
            sellToken: sellToken,
            sellAmount: SELL_AMOUNT,
            buyToken: buyToken,
            minBuyAmount: MIN_BUY_AMOUNT,
            buyer: address(0),
            expiryTime: EXPIRY
        });

        // Assert the order ID matches expected.
        assertEq(orderId, expectedOrderId, "orderId");

        // Assert the order was created correctly.
        assertEq(escrow.getSeller(orderId), users.seller, "order.seller");
        assertEq(escrow.getBuyer(orderId), address(0), "order.buyer should be zero");
        assertEq(escrow.getSellToken(orderId), sellToken, "order.sellToken");
        assertEq(escrow.getBuyToken(orderId), buyToken, "order.buyToken");
        assertEq(escrow.getSellAmount(orderId), SELL_AMOUNT, "order.sellAmount");
        assertEq(escrow.getMinBuyAmount(orderId), MIN_BUY_AMOUNT, "order.minBuyAmount");
        assertEq(escrow.getExpiryTime(orderId), EXPIRY, "order.expiryTime");
        assertEq(escrow.statusOf(orderId), Escrow.Status.OPEN, "order.status");
        assertFalse(escrow.wasCanceled(orderId), "order.wasCanceled");
        assertFalse(escrow.wasFilled(orderId), "order.wasFilled");

        // Assert the next order ID was incremented.
        assertEq(escrow.nextOrderId(), orderId + 1, "nextOrderId");

        // Assert the sell tokens were transferred to escrow.
        assertEq(sellToken.balanceOf(users.seller), sellerBalanceBefore - SELL_AMOUNT, "seller balance");
        assertEq(sellToken.balanceOf(address(escrow)), escrowBalanceBefore + SELL_AMOUNT, "escrow balance");
    }

    function test_GivenDesignatedBuyerSpecified()
        external
        whenSellTokenNotZero
        whenBuyTokenNotZero
        whenTokensNotSame
        whenSellAmountNotZero
        whenMinBuyAmountNotZero
        whenExpiryTimeValidOrZero
    {
        // It should create the order with buyer restriction.
        uint256 expectedOrderId = escrow.nextOrderId();

        // Expect the CreateOrder event.
        vm.expectEmit({ emitter: address(escrow) });
        emit ISablierEscrow.CreateOrder({
            orderId: expectedOrderId,
            seller: users.seller,
            buyer: users.buyer,
            sellToken: sellToken,
            buyToken: buyToken,
            sellAmount: SELL_AMOUNT,
            minBuyAmount: MIN_BUY_AMOUNT,
            expiryTime: EXPIRY
        });

        // Create the order with designated buyer.
        uint256 orderId = escrow.createOrder({
            sellToken: sellToken,
            sellAmount: SELL_AMOUNT,
            buyToken: buyToken,
            minBuyAmount: MIN_BUY_AMOUNT,
            buyer: users.buyer,
            expiryTime: EXPIRY
        });

        // Assert the order was created with designated buyer.
        assertEq(escrow.getBuyer(orderId), users.buyer, "order.buyer should be designated buyer");
        assertEq(escrow.statusOf(orderId), Escrow.Status.OPEN, "order.status");
    }

    function test_GivenExpiryTimeIsZero()
        external
        whenSellTokenNotZero
        whenBuyTokenNotZero
        whenTokensNotSame
        whenSellAmountNotZero
        whenMinBuyAmountNotZero
    {
        // It should create the order that never expires.
        uint256 expectedOrderId = escrow.nextOrderId();

        // Expect the CreateOrder event.
        vm.expectEmit({ emitter: address(escrow) });
        emit ISablierEscrow.CreateOrder({
            orderId: expectedOrderId,
            seller: users.seller,
            buyer: address(0),
            sellToken: sellToken,
            buyToken: buyToken,
            sellAmount: SELL_AMOUNT,
            minBuyAmount: MIN_BUY_AMOUNT,
            expiryTime: ZERO_EXPIRY
        });

        // Create the order that never expires.
        uint256 orderId = escrow.createOrder({
            sellToken: sellToken,
            sellAmount: SELL_AMOUNT,
            buyToken: buyToken,
            minBuyAmount: MIN_BUY_AMOUNT,
            buyer: address(0),
            expiryTime: ZERO_EXPIRY
        });

        // Assert the order was created with zero expiry.
        assertEq(escrow.getExpiryTime(orderId), 0, "order.expiryTime should be zero");
        assertEq(escrow.statusOf(orderId), Escrow.Status.OPEN, "order.status");

        // Warp far into the future and verify it's still open.
        vm.warp(block.timestamp + 365 days);
        assertEq(escrow.statusOf(orderId), Escrow.Status.OPEN, "order.status should still be OPEN");
    }
}
