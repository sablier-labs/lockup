// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";

abstract contract Constants {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    // Default deposit amount (10,000 tokens with 18 decimals).
    uint128 public constant DEPOSIT_AMOUNT = 10_000e18;

    // Default deposit amount for WETH (1 WETH).
    uint128 public constant WETH_DEPOSIT_AMOUNT = 1e18;

    // Default target price (100 USD with 8 decimals, Chainlink format).
    uint128 public constant TARGET_PRICE = 100e8;

    // Default initial price below target (50 USD with 8 decimals).
    uint128 public constant INITIAL_PRICE = 50e8;

    // Price at or above target (100 USD with 8 decimals).
    uint128 public constant SETTLED_PRICE = 100e8;

    // Default slippage tolerance (0.5%).
    UD60x18 public constant DEFAULT_SLIPPAGE_TOLERANCE = UD60x18.wrap(0.005e18);

    // Maximum yield fee (20%).
    UD60x18 public constant MAX_YIELD_FEE = UD60x18.wrap(0.2e18);

    // Default yield fee (10%).
    UD60x18 public constant DEFAULT_YIELD_FEE = UD60x18.wrap(0.1e18);

    // Feb 1, 2025 at 00:00 UTC.
    uint40 public constant FEB_1_2025 = 1_738_368_000;

    // Default expiry time (30 days from FEB_1_2025).
    uint40 public constant EXPIRY = FEB_1_2025 + 30 days;

    // Expired expiry time (in the past from FEB_1_2025).
    uint40 public constant EXPIRED_EXPIRY = FEB_1_2025 - 1;
}
