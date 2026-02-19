// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud, UD60x18, ZERO } from "@prb/math/src/UD60x18.sol";
import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";

import { ISablierEscrow } from "src/interfaces/ISablierEscrow.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract SetTradeFee_Integration_Concrete_Test is Integration_Test {
    UD60x18 public newTradeFee = ZERO;

    function test_RevertWhen_CallerNotComptroller() external {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                EvmUtilsErrors.Comptrollerable_CallerNotComptroller.selector, address(comptroller), users.seller
            )
        );
        escrow.setTradeFee(newTradeFee);
    }

    function test_RevertWhen_NewFeeExceedsMax() external whenCallerComptroller {
        newTradeFee = MAX_TRADE_FEE.add(ud(1));

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierEscrowState_NewTradeFeeTooHigh.selector, newTradeFee, MAX_TRADE_FEE)
        );
        escrow.setTradeFee(newTradeFee);
    }

    function test_WhenFeeNotExceedMax() external whenCallerComptroller {
        // It should emit a {SetTradeFee} event.
        vm.expectEmit({ emitter: address(escrow) });
        emit ISablierEscrow.SetTradeFee({
            caller: address(comptroller),
            previousTradeFee: DEFAULT_TRADE_FEE,
            newTradeFee: newTradeFee
        });

        // Set the new trade fee.
        escrow.setTradeFee(newTradeFee);

        // It should set the new trade fee.
        assertEq(escrow.tradeFee(), newTradeFee, "tradeFee");
    }
}
