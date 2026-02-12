// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { Errors } from "src/libraries/Errors.sol";
import {
    ChainlinkOracleMock,
    ChainlinkOracleNegativePrice,
    ChainlinkOracleWith18Decimals,
    ChainlinkOracleWithRevertingDecimals,
    ChainlinkOracleWithRevertingPrice
} from "src/mocks/ChainlinkMocks.sol";
import { SafeOracle } from "src/libraries/SafeOracle.sol";

import { Base_Test } from "../../../Base.t.sol";

contract SafeOraclePrice_Concrete_Test is Base_Test {
    function test_RevertWhen_OracleAddressZero() external {
        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SafeOracle_MissesInterface.selector, address(0)));
        SafeOracle.safeOraclePrice(AggregatorV3Interface(address(0)));
    }

    function test_RevertWhen_OracleMissesDecimals() external whenOracleAddressNotZero {
        ChainlinkOracleWithRevertingDecimals oracle = new ChainlinkOracleWithRevertingDecimals();

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SafeOracle_MissesInterface.selector, address(oracle)));
        SafeOracle.safeOraclePrice(AggregatorV3Interface(address(oracle)));
    }

    function test_RevertWhen_OracleDecimalsNot8() external whenOracleAddressNotZero whenOracleNotMissDecimals {
        ChainlinkOracleWith18Decimals oracle = new ChainlinkOracleWith18Decimals();

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SafeOracle_DecimalsNotEight.selector, address(oracle), 18));
        SafeOracle.safeOraclePrice(AggregatorV3Interface(address(oracle)));
    }

    function test_RevertWhen_OracleMissesLatestRoundData()
        external
        whenOracleAddressNotZero
        whenOracleNotMissDecimals
        whenOracleDecimals8
    {
        ChainlinkOracleWithRevertingPrice oracle = new ChainlinkOracleWithRevertingPrice();

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SafeOracle_MissesInterface.selector, address(oracle)));
        SafeOracle.safeOraclePrice(AggregatorV3Interface(address(oracle)));
    }

    function test_RevertWhen_OraclePriceNotPositive()
        external
        whenOracleAddressNotZero
        whenOracleNotMissDecimals
        whenOracleDecimals8
        whenOracleNotMissLatestRoundData
    {
        ChainlinkOracleNegativePrice oracle = new ChainlinkOracleNegativePrice();

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SafeOracle_NegativePrice.selector, address(oracle)));
        SafeOracle.safeOraclePrice(AggregatorV3Interface(address(oracle)));
    }

    function test_WhenOraclePricePositive()
        external
        whenOracleAddressNotZero
        whenOracleNotMissDecimals
        whenOracleDecimals8
        whenOracleNotMissLatestRoundData
    {
        ChainlinkOracleMock oracle = new ChainlinkOracleMock();

        // It should return the latest price.
        uint128 latestPrice = SafeOracle.safeOraclePrice(AggregatorV3Interface(address(oracle)));
        assertEq(latestPrice, 3000e8, "latestPrice");
    }
}
