// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import {
    ChainlinkOracleWith18Decimals,
    ChainlinkOracleWith6Decimals,
    ChainlinkOracleWithRevertingDecimals,
    ChainlinkOracleZeroPrice
} from "src/mocks/ChainlinkMocks.sol";

import { Base_Test } from "tests/Base.t.sol";

contract ConvertUSDFeeToWei_Comptroller_Concrete_Test is Base_Test {
    function test_GivenOracleZero(uint128 feeUSD) external {
        comptroller.setOracle(address(0));

        // It should return zero.
        assertEq(comptroller.convertUSDFeeToWei(feeUSD), 0, "zero oracle");
    }

    function test_WhenFeeUSDZero() external view givenOracleNotZero {
        // It should return zero.
        assertEq(comptroller.convertUSDFeeToWei(0), 0, "zero fee");
    }

    /// @dev SafeOracle failure modes (reverting oracle, negative price, future-dated, outdated, zero price) are
    /// tested in {SafeOraclePrice_Concrete_Test}. Here we only verify the pass-through: when safeOraclePrice returns
    /// 0, convertUSDFeeToWei returns 0.
    function test_WhenSafeOraclePriceZero(uint128 feeUSD) external givenOracleNotZero whenFeeUSDNotZero {
        comptroller.setOracle(address(new ChainlinkOracleZeroPrice()));

        // It should return zero.
        assertEq(comptroller.convertUSDFeeToWei(feeUSD), 0, "safe oracle price zero");
    }

    function test_WhenDecimalsCallFails(uint128 feeUSD)
        external
        givenOracleNotZero
        whenFeeUSDNotZero
        whenSafeOraclePriceNotZero
    {
        comptroller.setOracle(address(new ChainlinkOracleWithRevertingDecimals()));

        // It should return zero.
        assertEq(comptroller.convertUSDFeeToWei(feeUSD), 0, "decimals call failed");
    }

    function test_WhenOracleReturnsEightDecimals(uint128 feeUSD)
        external
        view
        givenOracleNotZero
        whenFeeUSDNotZero
        whenSafeOraclePriceNotZero
        whenDecimalsCallNotFail
    {
        // It should convert the fee to wei.
        uint256 actualFeeInWei = comptroller.convertUSDFeeToWei(feeUSD);
        uint256 expectedFeeInWei = convertUSDToWei(feeUSD);
        assertEq(actualFeeInWei, expectedFeeInWei, "eight decimals");
    }

    function test_WhenOracleReturnsMoreThanEightDecimals(uint128 feeUSD)
        external
        givenOracleNotZero
        whenFeeUSDNotZero
        whenSafeOraclePriceNotZero
        whenDecimalsCallNotFail
    {
        comptroller.setOracle(address(new ChainlinkOracleWith18Decimals()));

        // It should convert the fee to wei.
        uint256 actualFeeInWei = comptroller.convertUSDFeeToWei(feeUSD);
        uint256 expectedFeeInWei = convertUSDToWei(feeUSD);
        assertEq(actualFeeInWei, expectedFeeInWei, "more than eight decimals");
    }

    function test_WhenOracleReturnsLessThanEightDecimals(uint128 feeUSD)
        external
        givenOracleNotZero
        whenFeeUSDNotZero
        whenSafeOraclePriceNotZero
        whenDecimalsCallNotFail
    {
        comptroller.setOracle(address(new ChainlinkOracleWith6Decimals()));

        // It should convert the fee to wei.
        uint256 actualFeeInWei = comptroller.convertUSDFeeToWei(feeUSD);
        uint256 expectedFeeInWei = convertUSDToWei(feeUSD);
        assertEq(actualFeeInWei, expectedFeeInWei, "less than eight decimals");
    }
}
