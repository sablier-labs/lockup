// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud, UD60x18 } from "@prb/math/src/UD60x18.sol";
import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";

import { ISablierLidoAdapter } from "src/interfaces/ISablierLidoAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract SetSlippageTolerance_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_CallerNotComptroller() external {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                EvmUtilsErrors.Comptrollerable_CallerNotComptroller.selector, address(comptroller), users.depositor
            )
        );
        adapter.setSlippageTolerance(ud(0.01e18));
    }

    function test_RevertWhen_ToleranceExceedsMax() external whenCallerComptroller {
        // It should revert.
        UD60x18 maxTolerance = adapter.MAX_SLIPPAGE_TOLERANCE();
        UD60x18 invalidTolerance = maxTolerance.add(ud(1));

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLidoAdapter_SlippageToleranceTooHigh.selector,
                invalidTolerance.unwrap(),
                maxTolerance.unwrap()
            )
        );
        adapter.setSlippageTolerance(invalidTolerance);
    }

    function test_WhenToleranceWithinLimit() external whenCallerComptroller {
        // It should set the slippage tolerance and emit event.
        UD60x18 oldTolerance = adapter.slippageTolerance();
        UD60x18 newTolerance = ud(0.01e18); // 1%

        // Expect the SetSlippageTolerance event.
        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierLidoAdapter.SetSlippageTolerance({
            oldSlippageTolerance: oldTolerance,
            newSlippageTolerance: newTolerance
        });

        // Set the slippage tolerance.
        adapter.setSlippageTolerance(newTolerance);

        // Assert the slippage tolerance was updated.
        assertEq(adapter.slippageTolerance().unwrap(), newTolerance.unwrap(), "slippageTolerance should be updated");
    }

    function test_WhenToleranceAtMaximum() external whenCallerComptroller {
        // It should set the slippage tolerance to max.
        UD60x18 oldTolerance = adapter.slippageTolerance();
        UD60x18 maxTolerance = adapter.MAX_SLIPPAGE_TOLERANCE();

        // Expect the SetSlippageTolerance event.
        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierLidoAdapter.SetSlippageTolerance({
            oldSlippageTolerance: oldTolerance,
            newSlippageTolerance: maxTolerance
        });

        // Set the slippage tolerance to max.
        adapter.setSlippageTolerance(maxTolerance);

        // Assert the slippage tolerance was updated.
        assertEq(adapter.slippageTolerance().unwrap(), maxTolerance.unwrap(), "slippageTolerance should be max");
    }

    function test_WhenToleranceZero() external whenCallerComptroller {
        // It should set the slippage tolerance to zero.
        UD60x18 oldTolerance = adapter.slippageTolerance();
        UD60x18 zeroTolerance = ud(0);

        // Expect the SetSlippageTolerance event.
        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierLidoAdapter.SetSlippageTolerance({
            oldSlippageTolerance: oldTolerance,
            newSlippageTolerance: zeroTolerance
        });

        // Set the slippage tolerance to zero.
        adapter.setSlippageTolerance(zeroTolerance);

        // Assert the slippage tolerance was updated.
        assertEq(adapter.slippageTolerance().unwrap(), 0, "slippageTolerance should be zero");
    }
}
