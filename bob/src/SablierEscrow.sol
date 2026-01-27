// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { ud, UD60x18 } from "@prb/math/src/UD60x18.sol";
import { Batch } from "@sablier/evm-utils/src/Batch.sol";
import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";

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
    ISablierEscrow, // 2 inherited components
    ReentrancyGuard, // 1 inherited component
    SablierEscrowState // 2 inherited components
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialComptroller The address of the initial comptroller contract.
    constructor(address initialComptroller) SablierEscrowState(initialComptroller) { }

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierEscrow
    function createOrder(
        IERC20 sellToken,
        uint128 sellAmount,
        IERC20 buyToken,
        uint128 minBuyAmount,
        address buyer,
        uint40 expiry
    )
        external
        override
        nonReentrant
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

        // Check: sell and buy tokens are different.
        if (sellToken == buyToken) {
            revert Errors.SablierEscrow_SameToken(address(sellToken));
        }

        // Check: sell amount is not zero.
        if (sellAmount == 0) {
            revert Errors.SablierEscrow_SellAmountZero();
        }

        // Check: minimum buy amount is not zero.
        if (minBuyAmount == 0) {
            revert Errors.SablierEscrow_MinBuyAmountZero();
        }

        // Check: expiry is in the future.
        if (expiry <= block.timestamp) {
            revert Errors.SablierEscrow_ExpiryInPast(expiry, uint40(block.timestamp));
        }

        // Use the current next order ID as this order's ID (IDs start from 1).
        orderId = nextOrderId;

        // Effect: increment the next order ID.
        // Using unchecked because this cannot realistically overflow, as it would require creating 2^256 orders.
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
            expiry: expiry,
            wasCanceled: false,
            wasAccepted: false
        });

        // Log the order creation.
        emit OrderCreated(orderId, msg.sender, buyer, sellToken, buyToken, sellAmount, minBuyAmount, expiry);

        // Interaction: transfer sell tokens from seller to this contract.
        sellToken.safeTransferFrom(msg.sender, address(this), sellAmount);
    }

    /// @inheritdoc ISablierEscrow
    function acceptOrder(uint256 orderId, uint128 buyAmount) external override nonReentrant orderExists(orderId) {
        // Load the order from storage.
        Escrow.Order storage order = _orders[orderId];

        // Check: the order has not been accepted.
        if (order.wasAccepted) {
            revert Errors.SablierEscrow_OrderCompleted(orderId);
        }

        // Check: the order has not been canceled.
        if (order.wasCanceled) {
            revert Errors.SablierEscrow_OrderCancelled(orderId);
        }

        // Check: the order has not expired.
        if (block.timestamp >= order.expiry) {
            revert Errors.SablierEscrow_OrderExpired(orderId, order.expiry, uint40(block.timestamp));
        }

        // Check: if the order has a designated buyer, the caller must be that buyer.
        if (order.buyer != address(0) && msg.sender != order.buyer) {
            revert Errors.SablierEscrow_CallerNotBuyer(orderId, msg.sender, order.buyer);
        }

        // Check: the buy amount meets the minimum requirement.
        if (buyAmount < order.minBuyAmount) {
            revert Errors.SablierEscrow_BuyAmountBelowMinimum(buyAmount, order.minBuyAmount);
        }

        // Cache values for interactions.
        address seller = order.seller;
        IERC20 sellToken = order.sellToken;
        IERC20 buyToken = order.buyToken;
        uint128 sellAmount = order.sellAmount;

        // Effect: mark the order as accepted.
        order.wasAccepted = true;

        // Calculate fees and execute transfers.
        UD60x18 fee = protocolFee;

        if (fee.unwrap() > 0) {
            // Calculate fees on both tokens.
            // Seller receives: buyAmount - buyFee
            // Buyer receives: sellAmount - sellFee
            uint128 sellFee = ud(sellAmount).mul(fee).intoUint128();
            uint128 buyFee = ud(buyAmount).mul(fee).intoUint128();
            address feeRecipient = comptroller.admin();

            // Log the order acceptance with the actual buy amount paid.
            emit OrderAccepted(orderId, msg.sender, sellAmount - sellFee, buyAmount - buyFee);

            // Interactions: transfer buy tokens from buyer.
            if (buyFee > 0) {
                buyToken.safeTransferFrom(msg.sender, seller, buyAmount - buyFee);
                buyToken.safeTransferFrom(msg.sender, feeRecipient, buyFee);
            } else {
                buyToken.safeTransferFrom(msg.sender, seller, buyAmount);
            }

            // Interactions: transfer sell tokens to buyer.
            if (sellFee > 0) {
                sellToken.safeTransfer(msg.sender, sellAmount - sellFee);
                sellToken.safeTransfer(feeRecipient, sellFee);
            } else {
                sellToken.safeTransfer(msg.sender, sellAmount);
            }
        } else {
            // No fee: log and transfer full amounts.
            emit OrderAccepted(orderId, msg.sender, sellAmount, buyAmount);
            buyToken.safeTransferFrom(msg.sender, seller, buyAmount);
            sellToken.safeTransfer(msg.sender, sellAmount);
        }
    }

    /// @inheritdoc ISablierEscrow
    function cancelOrder(uint256 orderId) external override nonReentrant orderExists(orderId) {
        // Load the order from storage.
        Escrow.Order storage order = _orders[orderId];

        // Check: the caller is the seller.
        if (msg.sender != order.seller) {
            revert Errors.SablierEscrow_CallerNotSeller(orderId, msg.sender, order.seller);
        }

        // Check: the order has not been accepted.
        if (order.wasAccepted) {
            revert Errors.SablierEscrow_OrderCompleted(orderId);
        }

        // Check: the order has not been canceled.
        if (order.wasCanceled) {
            revert Errors.SablierEscrow_OrderCancelled(orderId);
        }

        // Cache values for interactions.
        IERC20 sellToken = order.sellToken;
        uint128 sellAmount = order.sellAmount;

        // Effect: mark the order as canceled.
        order.wasCanceled = true;

        // Log the order cancellation.
        emit OrderCancelled(orderId, msg.sender, sellAmount);

        // Interaction: return escrowed sell tokens to the seller.
        sellToken.safeTransfer(msg.sender, sellAmount);
    }

    /// @inheritdoc ISablierEscrow
    function setProtocolFee(UD60x18 newProtocolFee) external override {
        // Check: the caller is the comptroller admin.
        address admin = comptroller.admin();
        if (msg.sender != admin) {
            revert Errors.SablierEscrow_CallerNotAdmin(msg.sender, admin);
        }

        // Check: the new fee does not exceed the maximum.
        if (newProtocolFee.gt(MAX_FEE)) {
            revert Errors.SablierEscrow_FeeExceedsMax(newProtocolFee.unwrap(), MAX_FEE.unwrap());
        }

        // Cache the old fee for the event.
        UD60x18 oldProtocolFee = protocolFee;

        // Effect: set the new protocol fee.
        protocolFee = newProtocolFee;

        // Log the fee change.
        emit SetProtocolFee(admin, oldProtocolFee, newProtocolFee);
    }
}
