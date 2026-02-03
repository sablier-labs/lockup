// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

/// @notice Struct containing order IDs used in tests.
struct OrderIds {
    // Default order ID (open order, any buyer).
    uint256 defaultOrder;
    // Order with designated buyer.
    uint256 designatedBuyerOrder;
    // A canceled order.
    uint256 canceledOrder;
    // A filled order.
    uint256 filledOrder;
    // An order ID that does not exist.
    uint256 nullOrder;
    // An expired order.
    uint256 expiredOrder;
}

/// @notice Struct containing test user addresses.
struct Users {
    // Impartial user.
    address payable alice;
    // Malicious user.
    address payable eve;
    // Default seller.
    address payable seller;
    // Default buyer.
    address payable buyer;
    // Another buyer.
    address payable buyer2;
}
