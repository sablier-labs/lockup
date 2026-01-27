// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Namespace for the structs and enums used in the Sablier Escrow protocol.
library Escrow {
    /// @notice Enum representing the different statuses of an order.
    /// @dev The status is derived at runtime from boolean flags and timestamps, not stored directly.
    /// @custom:value0 OPEN Order is open and can be accepted or cancelled.
    /// @custom:value1 COMPLETED Order has been successfully completed (tokens exchanged).
    /// @custom:value2 CANCELLED Order has been cancelled by the seller.
    /// @custom:value3 EXPIRED Order has expired without being accepted.
    enum Status {
        OPEN,
        COMPLETED,
        CANCELLED,
        EXPIRED
    }

    /// @notice Struct encapsulating all the configuration and state of an order.
    /// @dev The fields are arranged for gas optimization via tight variable packing.
    /// @param seller The address that created the order and deposited the sell token.
    /// @param buyer The designated counterparty address, or zero address for open orders.
    /// @param sellToken The ERC-20 token being sold (escrowed in the contract).
    /// @param buyToken The ERC-20 token the seller wants to receive.
    /// @param sellAmount The amount of sell token escrowed.
    /// @param minBuyAmount The minimum amount of buy token the seller is willing to accept.
    /// @param expiry The Unix timestamp when the order expires.
    /// @param wasCanceled Boolean indicating if the order was canceled.
    /// @param wasAccepted Boolean indicating if the order was accepted/completed.
    struct Order {
        // slot 0
        address seller;
        uint40 expiry;
        bool wasCanceled;
        bool wasAccepted;
        // slot 1
        address buyer;
        // slot 2
        IERC20 sellToken;
        // slot 3
        IERC20 buyToken;
        // slot 4
        uint128 sellAmount;
        uint128 minBuyAmount;
    }
}
