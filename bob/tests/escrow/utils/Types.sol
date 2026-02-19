// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

/// @notice Struct with test users.
struct Users {
    // Impartial user.
    address payable alice;
    // Default buyer.
    address payable buyer;
    // Default seller.
    address payable seller;
}
