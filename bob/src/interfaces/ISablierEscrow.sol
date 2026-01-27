// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";
import { IBatch } from "@sablier/evm-utils/src/interfaces/IBatch.sol";
import { IComptrollerable } from "@sablier/evm-utils/src/interfaces/IComptrollerable.sol";

import { ISablierEscrowState } from "./ISablierEscrowState.sol";

/// @title ISablierEscrow
/// @notice Interface for the Sablier Escrow OTC (over-the-counter) token swap protocol.
interface ISablierEscrow is IBatch, IComptrollerable, ISablierEscrowState {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a new order is created.
    /// @param orderId The unique identifier of the order.
    /// @param seller The address of the order creator (seller).
    /// @param buyer The designated counterparty address, or zero address for open orders.
    /// @param sellToken The ERC-20 token being sold.
    /// @param buyToken The ERC-20 token the seller wants to receive.
    /// @param sellAmount The amount of sell token escrowed.
    /// @param minBuyAmount The minimum amount of buy token the seller will accept.
    /// @param expiry The Unix timestamp when the order expires.
    event OrderCreated(
        uint256 indexed orderId,
        address indexed seller,
        address indexed buyer,
        IERC20 sellToken,
        IERC20 buyToken,
        uint128 sellAmount,
        uint128 minBuyAmount,
        uint40 expiry
    );

    /// @notice Emitted when an order is accepted and the trade is settled.
    /// @param orderId The unique identifier of the order.
    /// @param buyer The address that accepted the order.
    /// @param sellAmount The amount of sell token transferred to the buyer (after fees).
    /// @param buyAmount The actual amount of buy token paid by the buyer (after fees deducted to seller).
    event OrderAccepted(uint256 indexed orderId, address indexed buyer, uint128 sellAmount, uint128 buyAmount);

    /// @notice Emitted when an order is cancelled by the seller.
    /// @param orderId The unique identifier of the order.
    /// @param seller The address of the seller who cancelled.
    /// @param sellAmount The amount of sell token returned to the seller.
    event OrderCancelled(uint256 indexed orderId, address indexed seller, uint128 sellAmount);

    /// @notice Emitted when the protocol fee is updated.
    /// @param admin The address of the admin who updated the fee.
    /// @param oldProtocolFee The previous protocol fee.
    /// @param newProtocolFee The new protocol fee.
    event SetProtocolFee(address indexed admin, UD60x18 oldProtocolFee, UD60x18 newProtocolFee);

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a new OTC order with the specified parameters.
    ///
    /// @dev Emits an {OrderCreated} event.
    ///
    /// Notes:
    /// - The sell tokens are transferred to the escrow contract upon order creation.
    /// - The order ID is an incremental counter starting from 1.
    /// - If `buyer` is the zero address, anyone can accept the order (open order).
    /// - If `buyer` is a non-zero address, only that address can accept the order (private order).
    ///
    /// Requirements:
    /// - `sellToken` must not be the zero address.
    /// - `buyToken` must not be the zero address.
    /// - `sellToken` and `buyToken` must be different addresses.
    /// - `sellAmount` must be greater than zero.
    /// - `minBuyAmount` must be greater than zero.
    /// - `expiry` must be in the future.
    /// - The caller must have approved this contract to transfer `sellAmount` of `sellToken`.
    ///
    /// Supported Tokens:
    /// - Standard ERC-20 tokens
    /// - Fee-on-transfer and rebasing tokens are NOT supported
    ///
    /// @param sellToken The ERC-20 token to sell.
    /// @param sellAmount The amount of sell token to escrow.
    /// @param buyToken The ERC-20 token to receive.
    /// @param minBuyAmount The minimum amount of buy token to accept.
    /// @param buyer The designated counterparty address, or zero address for open orders.
    /// @param expiry The Unix timestamp when the order expires.
    /// @return orderId The unique identifier of the newly created order.
    function createOrder(
        IERC20 sellToken,
        uint128 sellAmount,
        IERC20 buyToken,
        uint128 minBuyAmount,
        address buyer,
        uint40 expiry
    )
        external
        returns (uint256 orderId);

    /// @notice Accepts an open order and settles the trade by exchanging tokens.
    ///
    /// @dev Emits an {OrderAccepted} event.
    ///
    /// Notes:
    /// - The escrowed sell tokens are transferred to the caller (buyer).
    /// - The buy tokens are transferred from the caller to the seller.
    /// - The order status becomes COMPLETED after acceptance.
    /// - Buyers can pay more than `minBuyAmount` for price improvement (offering a better deal to the seller).
    ///
    /// Requirements:
    /// - The order must exist.
    /// - The order must be in OPEN status (not completed, cancelled, or expired).
    /// - The order must not have expired (`block.timestamp < expiry`).
    /// - If the order has a designated buyer, the caller must be that buyer.
    /// - `buyAmount` must be greater than or equal to the order's `minBuyAmount`.
    /// - The caller must have approved this contract to transfer `buyAmount` of `buyToken`.
    ///
    /// @param orderId The unique identifier of the order to accept.
    /// @param buyAmount The amount of buy token to pay (must be >= minBuyAmount for price improvement).
    function acceptOrder(uint256 orderId, uint128 buyAmount) external;

    /// @notice Cancels an open order and returns the escrowed tokens to the seller.
    ///
    /// @dev Emits an {OrderCancelled} event.
    ///
    /// Notes:
    /// - The escrowed sell tokens are returned to the seller.
    /// - The order status becomes CANCELLED after cancellation.
    /// - Can be called at any time while the order is OPEN (even after expiry).
    ///
    /// Requirements:
    /// - The order must exist.
    /// - The order must be in OPEN status (not completed or already cancelled).
    /// - The caller must be the seller.
    ///
    /// @param orderId The unique identifier of the order to cancel.
    function cancelOrder(uint256 orderId) external;

    /// @notice Sets the protocol fee percentage.
    ///
    /// @dev Emits a {SetProtocolFee} event.
    ///
    /// Notes:
    /// - The fee is represented as a UD60x18 value where 1e18 = 100%.
    /// - The maximum fee is 1% (0.01e18 in UD60x18 format).
    ///
    /// Requirements:
    /// - The caller must be the comptroller admin.
    /// - `newProtocolFee` must not exceed {MAX_FEE}.
    ///
    /// @param newProtocolFee The new protocol fee to set.
    function setProtocolFee(UD60x18 newProtocolFee) external;
}
