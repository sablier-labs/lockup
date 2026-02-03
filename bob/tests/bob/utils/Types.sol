// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

/// @notice Struct containing vault IDs used in tests.
struct VaultIds {
    // Default vault ID (no adapter).
    uint256 defaultVault;
    // A vault ID with an adapter configured.
    uint256 adapterVault;
    // A vault ID that does not exist.
    uint256 nullVault;
    // A settled vault (expired).
    uint256 settledVault;
}

/// @notice Struct containing test user addresses.
struct Users {
    // Impartial user.
    address payable alice;
    // Malicious user.
    address payable eve;
    // Default depositor.
    address payable depositor;
    // Another depositor.
    address payable depositor2;
}
