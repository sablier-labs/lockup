// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { Errors } from "./libraries/Errors.sol";

/// @title SafeOracle
/// @notice Library with helper functions for validating oracle addresses.
library SafeOracle {
    using SafeCast for uint256;

    /// @dev Validates the oracle address and returns the latest price.
    function safeOraclePrice(AggregatorV3Interface oracle) public view returns (uint128 latestPrice) {
        // Check: oracle address is not zero. This is needed because calling a function on address(0) succeeds but
        // returns empty data, which causes the ABI decoder to fail.
        if (address(oracle) == address(0)) {
            revert Errors.SafeOracle_MissesInterface(address(oracle));
        }

        // Check: oracle implements the `decimals()` function and returns 8.
        try oracle.decimals() returns (uint8 oracleDecimals) {
            if (oracleDecimals != 8) {
                revert Errors.SafeOracle_DecimalsNotEight(address(oracle), oracleDecimals);
            }
        } catch {
            revert Errors.SafeOracle_MissesInterface(address(oracle));
        }

        // Check: oracle returns a positive price when `latestRoundData()` is called.
        try oracle.latestRoundData() returns (uint80, int256 price, uint256, uint256, uint80) {
            if (price <= 0) {
                revert Errors.SafeOracle_NegativePrice(address(oracle));
            }
            latestPrice = uint256(price).toUint128();
        } catch {
            revert Errors.SafeOracle_MissesInterface(address(oracle));
        }
    }
}
