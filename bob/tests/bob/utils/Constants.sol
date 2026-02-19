// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";
import { BaseConstants } from "@sablier/evm-utils/src/tests/BaseConstants.sol";

abstract contract Constants is BaseConstants {
    UD60x18 public constant DEFAULT_SLIPPAGE_TOLERANCE = UD60x18.wrap(0.005e18); // 0.5%
    UD60x18 public constant DEFAULT_YIELD_FEE = UD60x18.wrap(0.1e18); // 10%
    uint128 public constant DEPOSIT_AMOUNT = 10_000e18;
    uint40 public constant EXPIRED_EXPIRY = FEB_1_2025 - 1;
    uint40 public constant EXPIRY = FEB_1_2025 + 30 days;
    uint40 public constant FEB_1_2025 = 1_738_368_000;
    uint128 public constant INITIAL_PRICE = 50e8;
    UD60x18 public constant MAX_YIELD_FEE = UD60x18.wrap(0.2e18); // 20%
    uint128 public constant SETTLED_PRICE = 100e8;
    uint128 public constant TARGET_PRICE = 100e8;
    uint128 public constant WETH_DEPOSIT_AMOUNT = 1e18;
}
