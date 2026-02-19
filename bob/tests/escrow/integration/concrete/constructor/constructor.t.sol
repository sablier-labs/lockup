// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud, UD60x18 } from "@prb/math/src/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";
import { SablierEscrow } from "src/SablierEscrow.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Constructor_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_InitialTradeFeeTooHigh() external {
        UD60x18 initialTradeFee = MAX_TRADE_FEE.add(ud(1));

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierEscrowState_NewTradeFeeTooHigh.selector, initialTradeFee, MAX_TRADE_FEE
            )
        );
        new SablierEscrow(address(comptroller), initialTradeFee);
    }

    function test_Constructor() external {
        SablierEscrow newEscrow = new SablierEscrow(address(comptroller), DEFAULT_TRADE_FEE);

        // It should set the comptroller.
        assertEq(address(newEscrow.comptroller()), address(comptroller), "comptroller");

        // It should set the initial trade fee.
        assertEq(newEscrow.tradeFee(), DEFAULT_TRADE_FEE, "tradeFee");

        // It should set the next order ID to 1.
        assertEq(newEscrow.nextOrderId(), 1, "nextOrderId");

        // It should set the maximum trade fee.
        assertEq(newEscrow.MAX_TRADE_FEE(), MAX_TRADE_FEE, "MAX_TRADE_FEE");
    }
}
