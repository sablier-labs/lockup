// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/// @title MockOracle
/// @notice Mock Chainlink oracle for testing the SablierBob protocol.
/// @dev Implements AggregatorV3Interface with configurable price and behavior.
contract MockOracle is AggregatorV3Interface {
    /*//////////////////////////////////////////////////////////////////////////
                                   PUBLIC STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    int256 public price;
    uint80 public roundId;
    uint256 public updatedAt;
    bool public shouldRevert;

    /*//////////////////////////////////////////////////////////////////////////
                                   CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialPrice The initial price to return from latestRoundData.
    constructor(uint128 initialPrice) {
        price = int256(uint256(initialPrice));
        roundId = 1;
        updatedAt = block.timestamp;
        shouldRevert = false;
    }

    /*//////////////////////////////////////////////////////////////////////////
                              AGGREGATOR V3 INTERFACE
    //////////////////////////////////////////////////////////////////////////*/

    function decimals() external pure override returns (uint8) {
        return 8;
    }

    function description() external pure override returns (string memory) {
        return "Mock Oracle";
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 _roundId)
        external
        view
        override
        returns (uint80 roundId_, int256 answer, uint256 startedAt, uint256 updatedAt_, uint80 answeredInRound)
    {
        if (shouldRevert) {
            revert("MockOracle: getRoundData");
        }
        return (_roundId, price, updatedAt, updatedAt, _roundId);
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId_, int256 answer, uint256 startedAt, uint256 updatedAt_, uint80 answeredInRound)
    {
        if (shouldRevert) {
            revert("MockOracle: latestRoundData");
        }
        return (roundId, price, updatedAt, updatedAt, roundId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  MOCK FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Sets the price returned by the oracle.
    function setPrice(uint128 newPrice) external {
        price = int256(uint256(newPrice));
        roundId++;
        updatedAt = block.timestamp;
    }

    /// @notice Sets the price returned by the oracle (allows negative values for testing).
    function setPrice(int256 newPrice) external {
        price = newPrice;
        roundId++;
        updatedAt = block.timestamp;
    }

    /// @notice Sets whether the oracle should revert on calls.
    function setShouldRevert(bool _shouldRevert) external {
        shouldRevert = _shouldRevert;
    }
}

/// @title MockOracleInvalidPrice
/// @notice Mock oracle that returns an invalid (zero or negative) price.
contract MockOracleInvalidPrice is AggregatorV3Interface {
    int256 private immutable INVALID_PRICE;

    constructor(int256 invalidPrice_) {
        INVALID_PRICE = invalidPrice_;
    }

    function decimals() external pure override returns (uint8) {
        return 8;
    }

    function description() external pure override returns (string memory) {
        return "Mock Oracle Invalid Price";
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 _roundId)
        external
        view
        override
        returns (uint80 roundId_, int256 answer, uint256 startedAt, uint256 updatedAt_, uint80 answeredInRound)
    {
        return (_roundId, INVALID_PRICE, block.timestamp, block.timestamp, _roundId);
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId_, int256 answer, uint256 startedAt, uint256 updatedAt_, uint80 answeredInRound)
    {
        return (1, INVALID_PRICE, block.timestamp, block.timestamp, 1);
    }
}

/// @title MockOracleInvalidDecimals
/// @notice Mock oracle that returns a non-8 decimal value.
contract MockOracleInvalidDecimals is AggregatorV3Interface {
    uint8 private immutable DECIMALS;

    constructor(uint8 decimals_) {
        DECIMALS = decimals_;
    }

    function decimals() external view override returns (uint8) {
        return DECIMALS;
    }

    function description() external pure override returns (string memory) {
        return "Mock Oracle Invalid Decimals";
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 _roundId)
        external
        view
        override
        returns (uint80 roundId_, int256 answer, uint256 startedAt, uint256 updatedAt_, uint80 answeredInRound)
    {
        return (_roundId, 50e8, block.timestamp, block.timestamp, _roundId);
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId_, int256 answer, uint256 startedAt, uint256 updatedAt_, uint80 answeredInRound)
    {
        return (1, 50e8, block.timestamp, block.timestamp, 1);
    }
}

/// @title MockOracleReverting
/// @notice Mock oracle that always reverts on decimals().
contract MockOracleReverting is AggregatorV3Interface {
    function decimals() external pure override returns (uint8) {
        revert("MockOracle: decimals");
    }

    function description() external pure override returns (string memory) {
        revert("MockOracle: description");
    }

    function version() external pure override returns (uint256) {
        revert("MockOracle: version");
    }

    function getRoundData(uint80) external pure override returns (uint80, int256, uint256, uint256, uint80) {
        revert("MockOracle: getRoundData");
    }

    function latestRoundData() external pure override returns (uint80, int256, uint256, uint256, uint80) {
        revert("MockOracle: latestRoundData");
    }
}

/// @title MockOracleRevertingOnLatestRoundData
/// @notice Mock oracle that only implements decimals(). Calls to latestRoundData() will revert.
contract MockOracleRevertingOnLatestRoundData {
    function decimals() external pure returns (uint8) {
        return 8;
    }
}
