// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2ProUnitTest } from "../SablierV2ProUnitTest.t.sol";

contract SablierV2Pro__UnitTest__GetDepositAmount is SablierV2ProUnitTest {
    /// @dev it should return zero.
    function testGetDepositAmount__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256 actualDepositAmount = sablierV2Pro.getDepositAmount(nonStreamId);
        uint256 expectedDepositAmount = 0;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should the correct deposit amount.
    function testGetDepositAmount() external StreamExistent {
        uint256 daiStreamId = createDefaultDaiStream();
        uint256 actualDepositAmount = sablierV2Pro.getDepositAmount(daiStreamId);
        uint256 expectedDepositAmount = daiStream.depositAmount;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }
}
