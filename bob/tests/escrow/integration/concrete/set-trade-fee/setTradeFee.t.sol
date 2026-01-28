// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { ISablierEscrow } from "src/interfaces/ISablierEscrow.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract SetTradeFee_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_CallerNotComptroller() external {
        // It should revert.
        UD60x18 newFee = UD60x18.wrap(0.005e18);
        expectRevert_NotComptroller(abi.encodeCall(escrow.setTradeFee, (newFee)));
    }

    function test_RevertWhen_FeeExceedsMax() external whenCallerComptroller {
        // It should revert.
        expectRevert_TradeFeeExceedsMax(
            abi.encodeCall(escrow.setTradeFee, (TRADE_FEE_EXCEEDS_MAX)),
            TRADE_FEE_EXCEEDS_MAX.unwrap(),
            MAX_TRADE_FEE.unwrap()
        );
    }

    function test_WhenFeeWithinLimit() external whenCallerComptroller whenFeeWithinLimit {
        // It should set the new trade fee.
        UD60x18 previousFee = escrow.tradeFee();
        UD60x18 newFee = UD60x18.wrap(0.015e18); // 1.5%

        // Expect the SetTradeFee event.
        vm.expectEmit({ emitter: address(escrow) });
        emit ISablierEscrow.SetTradeFee({
            caller: address(comptroller),
            previousTradeFee: previousFee,
            newTradeFee: newFee
        });

        escrow.setTradeFee(newFee);

        // Assert the fee was updated.
        assertEq(escrow.tradeFee().unwrap(), newFee.unwrap(), "tradeFee");
    }

    function test_SetTradeFeeToZero() external whenCallerComptroller whenFeeWithinLimit {
        // It should set the trade fee to zero.
        UD60x18 previousFee = escrow.tradeFee();

        // Expect the SetTradeFee event.
        vm.expectEmit({ emitter: address(escrow) });
        emit ISablierEscrow.SetTradeFee({
            caller: address(comptroller),
            previousTradeFee: previousFee,
            newTradeFee: ZERO_TRADE_FEE
        });

        escrow.setTradeFee(ZERO_TRADE_FEE);

        // Assert the fee was updated.
        assertEq(escrow.tradeFee().unwrap(), 0, "tradeFee should be zero");
    }

    function test_SetTradeFeeToMax() external whenCallerComptroller whenFeeWithinLimit {
        // It should set the trade fee to max.
        UD60x18 previousFee = escrow.tradeFee();

        // Expect the SetTradeFee event.
        vm.expectEmit({ emitter: address(escrow) });
        emit ISablierEscrow.SetTradeFee({
            caller: address(comptroller),
            previousTradeFee: previousFee,
            newTradeFee: MAX_TRADE_FEE
        });

        escrow.setTradeFee(MAX_TRADE_FEE);

        // Assert the fee was updated.
        assertEq(escrow.tradeFee().unwrap(), MAX_TRADE_FEE.unwrap(), "tradeFee should be max");
    }

    function test_SetSameTradeFee() external whenCallerComptroller whenFeeWithinLimit {
        // It should allow setting the same fee (no-op).
        UD60x18 currentFee = escrow.tradeFee();

        // Expect the SetTradeFee event.
        vm.expectEmit({ emitter: address(escrow) });
        emit ISablierEscrow.SetTradeFee({
            caller: address(comptroller),
            previousTradeFee: currentFee,
            newTradeFee: currentFee
        });

        escrow.setTradeFee(currentFee);

        // Assert the fee is unchanged.
        assertEq(escrow.tradeFee().unwrap(), currentFee.unwrap(), "tradeFee should be unchanged");
    }
}
