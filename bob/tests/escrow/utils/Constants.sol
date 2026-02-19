// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";
import { BaseConstants } from "@sablier/evm-utils/src/tests/BaseConstants.sol";

abstract contract Constants is BaseConstants {
    // Amounts
    uint128 public constant MIN_BUY_AMOUNT = 900e6; // Representing USDC
    uint128 public constant SELL_AMOUNT = 1000e18; // Representing DAI

    // Fees
    UD60x18 public constant DEFAULT_TRADE_FEE = UD60x18.wrap(0.01e18); // 1%
    UD60x18 public constant MAX_TRADE_FEE = UD60x18.wrap(0.02e18); // 2%

    // Timestamps
    uint40 public constant FEB_1_2026 = 1_769_904_000;
    uint40 public constant ORDER_EXPIRY_TIME = FEB_1_2026 + 30 days;
}
