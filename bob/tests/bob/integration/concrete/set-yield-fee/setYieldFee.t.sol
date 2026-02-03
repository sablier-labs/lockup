// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud, UD60x18 } from "@prb/math/src/UD60x18.sol";
import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";

import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract SetYieldFee_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_CallerNotComptroller() external {
        // It should revert.
        // Cache the yield fee before expectRevert, since DEFAULT_YIELD_FEE is a view call
        // that would be interpreted as the "next call" by expectRevert.
        UD60x18 newFee = DEFAULT_YIELD_FEE;

        vm.expectRevert(
            abi.encodeWithSelector(
                EvmUtilsErrors.Comptrollerable_CallerNotComptroller.selector, address(comptroller), users.depositor
            )
        );
        adapter.setYieldFee(newFee);
    }

    function test_RevertWhen_FeeExceedsMax() external whenCallerComptroller {
        // It should revert.
        UD60x18 maxFee = adapter.MAX_FEE();
        UD60x18 excessiveFee = maxFee.add(ud(1));

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLidoAdapter_YieldFeeTooHigh.selector, excessiveFee.unwrap(), maxFee.unwrap()
            )
        );
        adapter.setYieldFee(excessiveFee);
    }

    function test_WhenFeeWithinLimit() external whenCallerComptroller {
        // It should set yield fee.
        UD60x18 oldFee = adapter.feeOnYield();
        UD60x18 newFee = DEFAULT_YIELD_FEE;

        // Expect the SetYieldFee event.
        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierBobAdapter.SetYieldFee({ oldFee: oldFee, newFee: newFee });

        // Set the yield fee.
        adapter.setYieldFee(newFee);

        // Assert the yield fee was set.
        assertEq(adapter.feeOnYield().unwrap(), newFee.unwrap(), "yieldFee");
    }

    function test_WhenFeeAtMaximum() external whenCallerComptroller {
        // It should set yield fee.
        UD60x18 oldFee = adapter.feeOnYield();
        UD60x18 maxFee = adapter.MAX_FEE();

        // Expect the SetYieldFee event.
        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierBobAdapter.SetYieldFee({ oldFee: oldFee, newFee: maxFee });

        // Set the yield fee to maximum.
        adapter.setYieldFee(maxFee);

        // Assert the yield fee was set to maximum.
        assertEq(adapter.feeOnYield().unwrap(), maxFee.unwrap(), "yieldFee at max");
    }

    function test_WhenFeeZero() external whenCallerComptroller {
        // It should set yield fee.
        // First set a non-zero fee.
        adapter.setYieldFee(DEFAULT_YIELD_FEE);

        UD60x18 oldFee = adapter.feeOnYield();
        UD60x18 zeroFee = ud(0);

        // Expect the SetYieldFee event.
        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierBobAdapter.SetYieldFee({ oldFee: oldFee, newFee: zeroFee });

        // Set the yield fee to zero.
        adapter.setYieldFee(zeroFee);

        // Assert the yield fee was set to zero.
        assertEq(adapter.feeOnYield().unwrap(), 0, "yieldFee should be zero");
    }
}
