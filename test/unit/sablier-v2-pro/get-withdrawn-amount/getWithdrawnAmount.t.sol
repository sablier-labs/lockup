// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2ProTest } from "../SablierV2ProTest.t.sol";

contract GetWithdrawnAmount__Test is SablierV2ProTest {
    uint256 internal daiStreamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        daiStreamId = createDefaultDaiStream();

        // Make the recipient the caller in this test suite.
        changePrank(users.recipient);
    }

    /// @dev it should return zero.
    function testGetWithdrawnAmount__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint128 actualDepositAmount = sablierV2Pro.getWithdrawnAmount(nonStreamId);
        uint128 expectedDepositAmount = 0;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return zero.
    function testGetWithdrawnAmount__NoWithdrawals() external StreamExistent {
        uint128 actualDepositAmount = sablierV2Pro.getWithdrawnAmount(daiStreamId);
        uint128 expectedDepositAmount = 0;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }

    /// @dev it should return the correct withdrawn amount.
    function testGetWithdrawnAmount__WithWithdrawals() external StreamExistent {
        vm.warp({ timestamp: daiStream.stopTime });
        uint128 withdrawAmount = 100e18;
        sablierV2Pro.withdraw(daiStreamId, users.recipient, withdrawAmount);
        uint128 actualDepositAmount = sablierV2Pro.getWithdrawnAmount(daiStreamId);
        uint128 expectedDepositAmount = withdrawAmount;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }
}
