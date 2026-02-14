// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import {
    ChainlinkOracleFutureDatedPrice,
    ChainlinkOracleMock,
    ChainlinkOracleNegativePrice,
    ChainlinkOracleOutdatedPrice,
    ChainlinkOracleWithRevertingPrice,
    ChainlinkOracleZeroPrice,
    SafeOracleMock
} from "src/mocks/ChainlinkMocks.sol";

import { Base_Test } from "../../../../Base.t.sol";

contract SafeOraclePrice_Concrete_Test is Base_Test {
    SafeOracleMock internal safeOracleMock;

    function setUp() public override {
        Base_Test.setUp();
        safeOracleMock = new SafeOracleMock();
    }

    function test_WhenOracleAddressZero() external {
        // It should return zero.
        uint128 price = safeOracleMock.safeOraclePrice(AggregatorV3Interface(address(0)));
        assertEq(price, 0, "zero oracle");
    }

    function test_WhenLatestRoundCallFails() external whenOracleAddressNotZero {
        ChainlinkOracleWithRevertingPrice oracle = new ChainlinkOracleWithRevertingPrice();

        // It should return zero.
        uint128 price = safeOracleMock.safeOraclePrice(AggregatorV3Interface(address(oracle)));
        assertEq(price, 0, "reverting oracle");
    }

    function test_WhenOraclePriceNegative() external whenOracleAddressNotZero whenLatestRoundCallNotFail {
        ChainlinkOracleNegativePrice oracle = new ChainlinkOracleNegativePrice();

        // It should return zero.
        uint128 price = safeOracleMock.safeOraclePrice(AggregatorV3Interface(address(oracle)));
        assertEq(price, 0, "negative price");
    }

    function test_WhenOracleUpdatedTimeInFuture()
        external
        whenOracleAddressNotZero
        whenLatestRoundCallNotFail
        whenOraclePriceNotNegative
    {
        ChainlinkOracleFutureDatedPrice oracle = new ChainlinkOracleFutureDatedPrice();

        // It should return zero.
        uint128 price = safeOracleMock.safeOraclePrice(AggregatorV3Interface(address(oracle)));
        assertEq(price, 0, "future oracle");
    }

    function test_WhenOraclePriceOutdated()
        external
        whenOracleAddressNotZero
        whenLatestRoundCallNotFail
        whenOraclePriceNotNegative
        whenOracleUpdatedTimeNotInFuture
    {
        ChainlinkOracleOutdatedPrice oracle = new ChainlinkOracleOutdatedPrice();

        // It should return zero.
        uint128 price = safeOracleMock.safeOraclePrice(AggregatorV3Interface(address(oracle)));
        assertEq(price, 0, "outdated oracle");
    }

    function test_WhenOraclePriceZero()
        external
        whenOracleAddressNotZero
        whenLatestRoundCallNotFail
        whenOraclePriceNotNegative
        whenOracleUpdatedTimeNotInFuture
        whenOraclePriceNotOutdated
    {
        ChainlinkOracleZeroPrice oracle = new ChainlinkOracleZeroPrice();

        // It should return zero.
        uint128 price = safeOracleMock.safeOraclePrice(AggregatorV3Interface(address(oracle)));
        assertEq(price, 0, "zero price");
    }

    function test_WhenOraclePriceNotZero()
        external
        whenOracleAddressNotZero
        whenLatestRoundCallNotFail
        whenOraclePriceNotNegative
        whenOracleUpdatedTimeNotInFuture
        whenOraclePriceNotOutdated
    {
        ChainlinkOracleMock oracle = new ChainlinkOracleMock();

        // It should return the latest price.
        uint128 price = safeOracleMock.safeOraclePrice(AggregatorV3Interface(address(oracle)));
        assertEq(price, 3000e8, "latestPrice");
    }
}
