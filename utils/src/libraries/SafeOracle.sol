// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { Errors } from "./Errors.sol";

/// @title SafeOracle
/// @notice Library with helper functions for fetching and validating oracle prices.
library SafeOracle {
    using SafeCast for uint256;

    /// @dev Fetches the latest price from the oracle without reverting. Returns 0 if the oracle address is zero, the
    /// call fails, the price is non-positive, the `updatedAt` timestamp is in the future, or the price is outdated
    /// (older than 24 hours).
    function safeOraclePrice(AggregatorV3Interface oracle) internal view returns (uint128 price) {
        // If the oracle is not set, return 0.
        if (address(oracle) == address(0)) {
            return 0;
        }

        uint256 updatedAt;

        // Interactions: query the oracle price and the time at which it was updated.
        try AggregatorV3Interface(oracle).latestRoundData() returns (
            uint80, int256 _price, uint256, uint256 _updatedAt, uint80
        ) {
            // If the price is not greater than 0, skip the calculations.
            if (_price <= 0) {
                return 0;
            }

            price = uint256(_price).toUint128();
            updatedAt = _updatedAt;
        } catch {
            // If the oracle call fails, return 0.
            return 0;
        }

        // Due to reorgs and latency issues, the oracle can have an `updatedAt` timestamp that is in the future. In
        // this case, we ignore the price and return 0.
        if (block.timestamp < updatedAt) {
            return 0;
        }

        // If the oracle hasn't been updated in the last 24 hours, we ignore the price and return 0. This is a safety
        // check to avoid using outdated prices.
        unchecked {
            if (block.timestamp - updatedAt > 24 hours) {
                return 0;
            }
        }
    }

    /// @dev Validates the oracle address by checking that it is not zero, implements the `decimals()` function
    /// returning 8, and returns a positive price via `latestRoundData()`. Reverts on any validation failure.
    function validateOracle(AggregatorV3Interface oracle) internal view returns (uint128 price) {
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
        try oracle.latestRoundData() returns (uint80, int256 _price, uint256, uint256, uint80) {
            // Because users may not always use Chainlink oracles, we do not check for the staleness of the price.
            if (_price <= 0) {
                revert Errors.SafeOracle_NegativePrice(address(oracle));
            }
            price = uint256(_price).toUint128();
        } catch {
            revert Errors.SafeOracle_MissesInterface(address(oracle));
        }
    }
}
