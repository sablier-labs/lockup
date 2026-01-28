// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { SablierEscrow } from "src/SablierEscrow.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Constructor_Integration_Concrete_Test is Integration_Test {
    function test_WhenDeployed() external {
        // Deploy a new instance with custom parameters.
        UD60x18 customTradeFee = UD60x18.wrap(0.005e18); // 0.5%
        SablierEscrow newEscrow = new SablierEscrow(address(comptroller), customTradeFee);

        // It should set the comptroller.
        assertEq(address(newEscrow.comptroller()), address(comptroller), "comptroller");

        // It should set the initial trade fee.
        assertEq(newEscrow.tradeFee().unwrap(), customTradeFee.unwrap(), "tradeFee");

        // It should set the next order ID to 1.
        assertEq(newEscrow.nextOrderId(), 1, "nextOrderId");
    }

    function test_WhenDeployedWithZeroTradeFee() external {
        // Deploy with zero trade fee.
        SablierEscrow newEscrow = new SablierEscrow(address(comptroller), ZERO_TRADE_FEE);

        // It should set the comptroller.
        assertEq(address(newEscrow.comptroller()), address(comptroller), "comptroller");

        // It should set the trade fee to zero.
        assertEq(newEscrow.tradeFee().unwrap(), 0, "tradeFee should be zero");

        // It should set the next order ID to 1.
        assertEq(newEscrow.nextOrderId(), 1, "nextOrderId");
    }

    function test_WhenDeployedWithMaxTradeFee() external {
        // Deploy with max trade fee.
        SablierEscrow newEscrow = new SablierEscrow(address(comptroller), MAX_TRADE_FEE);

        // It should set the comptroller.
        assertEq(address(newEscrow.comptroller()), address(comptroller), "comptroller");

        // It should set the trade fee to max.
        assertEq(newEscrow.tradeFee().unwrap(), MAX_TRADE_FEE.unwrap(), "tradeFee should be max");

        // It should set the next order ID to 1.
        assertEq(newEscrow.nextOrderId(), 1, "nextOrderId");
    }
}
