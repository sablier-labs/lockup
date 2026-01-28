// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";

abstract contract Constants {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    // Default sell amount (1,000 tokens with 18 decimals - for DAI).
    uint128 public constant SELL_AMOUNT = 1000e18;

    // Default min buy amount (900 tokens with 18 decimals - uses same decimals as sell for simplicity).
    uint128 public constant MIN_BUY_AMOUNT = 900e18;

    // Default buy amount used to fill orders (950 tokens with 18 decimals).
    uint128 public constant BUY_AMOUNT = 950e18;

    // Default trade fee (1% = 0.01e18).
    UD60x18 public constant DEFAULT_TRADE_FEE = UD60x18.wrap(0.01e18);

    // Maximum trade fee (2% = 0.02e18).
    UD60x18 public constant MAX_TRADE_FEE = UD60x18.wrap(0.02e18);

    // Trade fee exceeding maximum (3% = 0.03e18).
    UD60x18 public constant TRADE_FEE_EXCEEDS_MAX = UD60x18.wrap(0.03e18);

    // Zero trade fee.
    UD60x18 public constant ZERO_TRADE_FEE = UD60x18.wrap(0);

    // Feb 1, 2025 at 00:00 UTC.
    uint40 public constant FEB_1_2025 = 1_738_368_000;

    // Default expiry time (30 days from FEB_1_2025).
    uint40 public constant EXPIRY = FEB_1_2025 + 30 days;

    // Expired expiry time (in the past from FEB_1_2025).
    uint40 public constant EXPIRED_EXPIRY = FEB_1_2025 - 1;

    // Zero expiry (sentinel for orders that never expire).
    uint40 public constant ZERO_EXPIRY = 0;
}
