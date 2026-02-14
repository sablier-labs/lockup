// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";
import { SablierLidoAdapter } from "src/SablierLidoAdapter.sol";

import { Integration_Test } from "../../Integration.t.sol";

/// @title Constructor_LidoAdapter_Integration_Concrete_Test
/// @notice Integration tests for the SablierLidoAdapter constructor.
contract Constructor_LidoAdapter_Integration_Concrete_Test is Integration_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Maximum slippage tolerance (5%) - matches the contract constant.
    UD60x18 internal constant MAX_SLIPPAGE_TOLERANCE = UD60x18.wrap(0.05e18);

    /// @dev Maximum yield fee (20%) - matches the contract constant.
    UD60x18 internal constant MAX_FEE = UD60x18.wrap(0.2e18);

    /*//////////////////////////////////////////////////////////////////////////
                                       TESTS
    //////////////////////////////////////////////////////////////////////////*/

    function test_RevertWhen_SlippageToleranceExceedsMaximum() external {
        // Prepare slippage tolerance that exceeds maximum (5% + 1 wei).
        UD60x18 excessiveSlippage = UD60x18.wrap(MAX_SLIPPAGE_TOLERANCE.unwrap() + 1);

        // Expect revert with the correct error.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLidoAdapter_SlippageToleranceTooHigh.selector,
                excessiveSlippage.unwrap(),
                MAX_SLIPPAGE_TOLERANCE.unwrap()
            )
        );

        // Attempt to deploy with excessive slippage tolerance.
        new SablierLidoAdapter({
            initialComptroller: address(comptroller),
            sablierBob_: address(bob),
            curvePool_: address(curvePool),
            stETH_: address(steth),
            wETH_: address(weth),
            wstETH_: address(wsteth),
            initialSlippageTolerance: excessiveSlippage,
            initialYieldFee: DEFAULT_YIELD_FEE
        });
    }

    function test_RevertWhen_YieldFeeExceedsMaximum() external {
        // Prepare yield fee that exceeds maximum (20% + 1 wei).
        UD60x18 excessiveFee = UD60x18.wrap(MAX_FEE.unwrap() + 1);

        // Expect revert with the correct error.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLidoAdapter_YieldFeeTooHigh.selector, excessiveFee.unwrap(), MAX_FEE.unwrap()
            )
        );

        // Attempt to deploy with excessive yield fee.
        new SablierLidoAdapter({
            initialComptroller: address(comptroller),
            sablierBob_: address(bob),
            curvePool_: address(curvePool),
            stETH_: address(steth),
            wETH_: address(weth),
            wstETH_: address(wsteth),
            initialSlippageTolerance: DEFAULT_SLIPPAGE_TOLERANCE,
            initialYieldFee: excessiveFee
        });
    }

    function test_WhenParametersAreValid() external {
        // Deploy adapter with valid parameters.
        SablierLidoAdapter newAdapter = new SablierLidoAdapter({
            initialComptroller: address(comptroller),
            sablierBob_: address(bob),
            curvePool_: address(curvePool),
            stETH_: address(steth),
            wETH_: address(weth),
            wstETH_: address(wsteth),
            initialSlippageTolerance: DEFAULT_SLIPPAGE_TOLERANCE,
            initialYieldFee: DEFAULT_YIELD_FEE
        });

        // Verify comptroller is set correctly.
        assertEq(address(newAdapter.comptroller()), address(comptroller), "comptroller");

        // Verify SABLIER_BOB is set correctly.
        assertEq(newAdapter.SABLIER_BOB(), address(bob), "SABLIER_BOB");

        // Verify slippage tolerance is set correctly.
        assertEq(newAdapter.slippageTolerance().unwrap(), DEFAULT_SLIPPAGE_TOLERANCE.unwrap(), "slippageTolerance");

        // Verify yield fee is set correctly.
        assertEq(newAdapter.feeOnYield().unwrap(), DEFAULT_YIELD_FEE.unwrap(), "feeOnYield");
    }
}
