// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

contract OracleMock {
    int256 internal _price = 1000e8;

    function decimals() external pure returns (uint8) {
        return 8;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (1, _price, block.timestamp, block.timestamp, 1);
    }

    function price() external view returns (int256) {
        return _price;
    }

    function setPrice(uint256 newPrice) external {
        _price = int256(newPrice);
    }
}

/// @notice A mock that returns 18 decimals instead of 8.
contract OracleWith18DecimalsMock {
    function decimals() external pure returns (uint8) {
        return 18;
    }
}

/// @notice A mock that returns a negative price.
contract OracleNegativePriceMock {
    function decimals() external pure returns (uint8) {
        return 8;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (1, -1, block.timestamp, block.timestamp, 1);
    }
}

/// @notice Oracle mock that doesn't implement the decimals() function.
contract OracleMissingDecimalsMock {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (1, -1, block.timestamp, block.timestamp, 1);
    }
}

/// @notice Oracle mock that doesn't implement the latestRoundData() function.
contract OracleMissingLatestRoundDataMock {
    function decimals() external pure returns (uint8) {
        return 8;
    }
}
