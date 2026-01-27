// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ud, UD60x18 } from "@prb/math/src/UD60x18.sol";
import { Batch } from "@sablier/evm-utils/src/Batch.sol";
import { Comptrollerable } from "@sablier/evm-utils/src/Comptrollerable.sol";

import { SablierEscrowState } from "./abstracts/SablierEscrowState.sol";
import { ISablierEscrow } from "./interfaces/ISablierEscrow.sol";
import { Errors } from "./libraries/Errors.sol";
import { Escrow } from "./types/Escrow.sol";

/*

███████╗ █████╗ ██████╗ ██╗     ██╗███████╗██████╗     ███████╗███████╗ ██████╗██████╗  ██████╗ ██╗    ██╗
██╔════╝██╔══██╗██╔══██╗██║     ██║██╔════╝██╔══██╗    ██╔════╝██╔════╝██╔════╝██╔══██╗██╔═══██╗██║    ██║
███████╗███████║██████╔╝██║     ██║█████╗  ██████╔╝    █████╗  ███████╗██║     ██████╔╝██║   ██║██║ █╗ ██║
╚════██║██╔══██║██╔══██╗██║     ██║██╔══╝  ██╔══██╗    ██╔══╝  ╚════██║██║     ██╔══██╗██║   ██║██║███╗██║
███████║██║  ██║██████╔╝███████╗██║███████╗██║  ██║    ███████╗███████║╚██████╗██║  ██║╚██████╔╝╚███╔███╔╝
╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝    ╚══════╝╚══════╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝  ╚══╝╚══╝

*/

/// @title SablierEscrow
/// @notice See the documentation in {ISablierEscrow}.
contract SablierEscrow is
    Batch, // 1 inherited component
    Comptrollerable, // 1 inherited component
    ISablierEscrow, // 2 inherited components
    SablierEscrowState // 1 inherited component
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialComptroller The address of the initial comptroller contract.
    /// @param initialTradeFee The initial trade fee percentage.
    constructor(
        address initialComptroller,
        UD60x18 initialTradeFee
    )
        Comptrollerable(initialComptroller)
        SablierEscrowState(initialTradeFee)
    { }

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierEscrow
    function cancelOrder(uint256 orderId) external override notNull(orderId) {
        // Load the order from storage.
        Escrow.Order storage order = _orders[orderId];

        // Check: the caller is the seller.
        if (msg.sender != order.seller) {
            revert Errors.SablierEscrow_CallerNotAuthorized(orderId, msg.sender, order.seller);
        }

        // Check: the order has not been filled.
        if (order.wasFilled) {
            revert Errors.SablierEscrow_OrderFilled(orderId);
        }

        // Check: the order has not been canceled.
        if (order.wasCanceled) {
            revert Errors.SablierEscrow_OrderCancelled(orderId);
        }

        // Load values from storage into memory.
        uint128 sellAmount = order.sellAmount;

        // Effect: mark the order as canceled.
        order.wasCanceled = true;

        // Interaction: transfer sell tokens to caller.
        order.sellToken.safeTransfer(msg.sender, sellAmount);

        // Log the event.
        emit CancelOrder(orderId, msg.sender, sellAmount);
    }

    /// @inheritdoc ISablierEscrow
    function createOrder(
        IERC20 sellToken,
        uint128 sellAmount,
        IERC20 buyToken,
        uint128 minBuyAmount,
        address buyer,
        uint40 expireAt
    )
        external
        override
        returns (uint256 orderId)
    {
        // Check: sell token is not the zero address.
        if (address(sellToken) == address(0)) {
            revert Errors.SablierEscrow_SellTokenZero();
        }

        // Check: buy token is not the zero address.
        if (address(buyToken) == address(0)) {
            revert Errors.SablierEscrow_BuyTokenZero();
        }

        // Check: sell and buy tokens are not the same.
        if (sellToken == buyToken) {
            revert Errors.SablierEscrow_SameToken(sellToken);
        }

        // Check: sell amount is not zero.
        if (sellAmount == 0) {
            revert Errors.SablierEscrow_SellAmountZero();
        }

        // Check: minimum buy amount is not zero.
        if (minBuyAmount == 0) {
            revert Errors.SablierEscrow_MinBuyAmountZero();
        }

        // Check: expireAt is in the future. Zero is sentinel for orders that never expire.
        if (expireAt > 0 && expireAt <= block.timestamp) {
            revert Errors.SablierEscrow_ExpireAtInPast(expireAt, uint40(block.timestamp));
        }

        // Use the current next order ID as this order's ID.
        orderId = nextOrderId;

        // Effect: increment the next order ID.
        unchecked {
            nextOrderId = orderId + 1;
        }

        // Effect: create the order.
        _orders[orderId] = Escrow.Order({
            seller: msg.sender,
            buyer: buyer,
            sellToken: sellToken,
            buyToken: buyToken,
            sellAmount: sellAmount,
            minBuyAmount: minBuyAmount,
            expireAt: expireAt,
            wasCanceled: false,
            wasFilled: false
        });

        // Interaction: transfer sell tokens from caller to this contract.
        sellToken.safeTransferFrom(msg.sender, address(this), sellAmount);

        // Log the event.
        emit CreateOrder(orderId, msg.sender, buyer, sellToken, buyToken, sellAmount, minBuyAmount, expireAt);
    }

    /// @inheritdoc ISablierEscrow
    function fillOrder(uint256 orderId, uint128 buyAmount) external override notNull(orderId) {
        // Check: the order is open.
        {
            Escrow.Status status = _statusOf(orderId);
            if (status != Escrow.Status.OPEN) {
                revert Errors.SablierEscrow_OrderNotOpen(orderId, status);
            }
        }

        // Load the order from storage.
        Escrow.Order storage order = _orders[orderId];

        // Check: if the order has buyer specified, the caller must be the buyer.
        if (order.buyer != address(0) && msg.sender != order.buyer) {
            revert Errors.SablierEscrow_CallerNotAuthorized(orderId, msg.sender, order.buyer);
        }

        // Check: the buy amount meets the minimum asked.
        if (buyAmount < order.minBuyAmount) {
            revert Errors.SablierEscrow_InsufficientBuyAmount(buyAmount, order.minBuyAmount);
        }

        // Load values from storage into memory.
        IERC20 buyToken = order.buyToken;
        address seller = order.seller;
        IERC20 sellToken = order.sellToken;
        uint128 sellAmount = order.sellAmount;

        // Effect: mark the order as filled.
        order.wasFilled = true;

        // Get the trade fee from storage.
        UD60x18 currentTradeFee = tradeFee;

        uint128 amountToTransferToSeller = buyAmount;
        uint128 amountToTransferToBuyer = sellAmount;
        uint128 feeDeductedFromBuyerAmount;
        uint128 feeDeductedFromSellerAmount;

        // If the fee is non-zero, deduct the fee from both sides.
        if (currentTradeFee.unwrap() > 0) {
            // Calculate the fee on the sell amount.
            feeDeductedFromBuyerAmount = ud(sellAmount).mul(currentTradeFee).intoUint128();
            amountToTransferToBuyer -= feeDeductedFromBuyerAmount;

            // Calculate the fee on the buy amount.
            feeDeductedFromSellerAmount = ud(buyAmount).mul(currentTradeFee).intoUint128();
            amountToTransferToSeller -= feeDeductedFromSellerAmount;

            // Set comptroller as the fee recipient.
            address feeRecipient = address(comptroller);

            // Interaction: transfer fees to the fee recipient.
            buyToken.safeTransferFrom(msg.sender, feeRecipient, feeDeductedFromSellerAmount);
            sellToken.safeTransfer(feeRecipient, feeDeductedFromBuyerAmount);
        }

        // Interaction: transfer buy token to the seller.
        buyToken.safeTransferFrom(msg.sender, seller, amountToTransferToSeller);

        // Interaction: transfer sell tokens to the buyer.
        sellToken.safeTransfer(msg.sender, amountToTransferToBuyer);

        // Log the event.
        emit FillOrder({
            orderId: orderId,
            buyer: msg.sender,
            seller: seller,
            sellAmount: amountToTransferToBuyer,
            buyAmount: amountToTransferToSeller,
            feeDeductedFromBuyerAmount: feeDeductedFromBuyerAmount,
            feeDeductedFromSellerAmount: feeDeductedFromSellerAmount
        });
    }

    /// @inheritdoc ISablierEscrow
    function setTradeFee(UD60x18 newTradeFee) external override onlyComptroller {
        // Check: the new trade fee does not exceed the maximum trade fee.
        if (newTradeFee.gt(MAX_TRADE_FEE)) {
            revert Errors.SablierEscrow_TradeFeeExceedsMax(newTradeFee.unwrap(), MAX_TRADE_FEE.unwrap());
        }

        // Cache the current trade fee for the event.
        UD60x18 previousTradeFee = tradeFee;

        // Effect: set the new trade fee.
        tradeFee = newTradeFee;

        // Log the event.
        emit SetTradeFee(address(comptroller), previousTradeFee, newTradeFee);
    }
}
