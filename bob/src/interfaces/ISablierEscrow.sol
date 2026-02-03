// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";
import { IBatch } from "@sablier/evm-utils/src/interfaces/IBatch.sol";
import { IComptrollerable } from "@sablier/evm-utils/src/interfaces/IComptrollerable.sol";

import { ISablierEscrowState } from "./ISablierEscrowState.sol";

/// @title ISablierEscrow
/// @notice Interface for the Sablier Escrow protocol.
interface ISablierEscrow is IBatch, IComptrollerable, ISablierEscrowState {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when an order is cancelled by the seller.
    event CancelOrder(uint256 indexed orderId, address indexed seller, uint128 sellAmount);

    /// @notice Emitted when a new order is created.
    event CreateOrder(
        uint256 indexed orderId,
        address indexed seller,
        address indexed buyer,
        IERC20 sellToken,
        IERC20 buyToken,
        uint128 sellAmount,
        uint128 minBuyAmount,
        uint40 expireAt
    );

    /// @notice Emitted when an order is filled.
    event FillOrder(
        uint256 indexed orderId,
        address indexed buyer,
        address indexed seller,
        uint128 sellAmount,
        uint128 buyAmount,
        uint128 feeDeductedFromBuyerAmount,
        uint128 feeDeductedFromSellerAmount
    );

    /// @notice Emitted when the trade fee is updated.
    event SetTradeFee(address indexed caller, UD60x18 previousTradeFee, UD60x18 newTradeFee);

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Cancels an order and returns the escrowed tokens to the caller.
    ///
    /// @dev Emits a {CancelOrder} event.
    ///
    /// Requirements:
    /// - The order must exist.
    /// - The order status must either be OPEN or EXPIRED.
    /// - The caller must be the seller of the order.
    ///
    /// @param orderId The order ID to cancel.
    function cancelOrder(uint256 orderId) external;

    /// @notice Creates a new order for a peer-to-peer token swap.
    ///
    /// @dev Emits a {CreateOrder} event.
    ///
    /// Requirements:
    /// - `sellToken` must not be the zero address.
    /// - `buyToken` must not be the zero address.
    /// - `sellToken` and `buyToken` must not be the same token.
    /// - `sellAmount` must be greater than zero.
    /// - `minBuyAmount` must be greater than zero.
    /// - If `expireAt` is non-zero, it must be in the future. Zero is sentinel for orders that never expire.
    /// - The caller must have approved this contract to transfer atleast `sellAmount` of `sellToken`.
    ///
    /// @param sellToken The address of the ERC-20 token to sell.
    /// @param sellAmount The amount of sell token to exchange.
    /// @param buyToken The address of the ERC-20 token to receive.
    /// @param minBuyAmount The minimum amount of buy token to fill this trade.
    /// @param buyer The designated counterparty address specified by the seller. If its zero address, the order can be
    /// filled by anyone.
    /// @param expireAt The Unix timestamp when the order expires. Zero is sentinel for orders that never expire.
    /// @return orderId The order ID of the newly created order.
    function createOrder(
        IERC20 sellToken,
        uint128 sellAmount,
        IERC20 buyToken,
        uint128 minBuyAmount,
        address buyer,
        uint40 expireAt
    )
        external
        returns (uint256 orderId);

    /// @notice Fill an open order.
    ///
    /// @dev Emits an {FillOrder} event.
    ///
    /// Requirements:
    /// - The order must exist.
    /// - The order must be in OPEN status.
    /// - If the order has buyer specified, the caller must be the buyer.
    /// - `buyAmount` must be greater than or equal to the `minBuyAmount`.
    /// - The caller must have approved this contract to transfer atleast `buyAmount` of `buyToken`.
    ///
    /// @param orderId The order ID to fill.
    /// @param buyAmount The amount of buy token to exchange.
    function fillOrder(uint256 orderId, uint128 buyAmount) external;

    /// @notice Sets the fee to apply on each trade.
    ///
    /// @dev Emits a {SetTradeFee} event.
    ///
    /// Requirements:
    /// - The caller must be the comptroller admin.
    /// - `newTradeFee` must not exceed the maximum trade fee.
    ///
    /// @param newTradeFee The new trade fee to set, denominated in UD60x18, where 1e18 = 100%.
    function setTradeFee(UD60x18 newTradeFee) external;
}
