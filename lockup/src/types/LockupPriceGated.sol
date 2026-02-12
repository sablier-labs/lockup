// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/// @notice Namespace for the structs used only in LPG streams.
library LockupPriceGated {
    /// @notice Struct encapsulating the unlock parameters for LPG streams.
    /// @param oracle The price feed oracle address used to retrieve the latest price.
    /// @param targetPrice The price that must be reached to unlock the tokens, denominated in Chainlink's 8-decimal,
    /// where 1e8 = $1.
    struct UnlockParams {
        AggregatorV3Interface oracle;
        uint128 targetPrice;
    }
}
