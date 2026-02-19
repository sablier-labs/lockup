// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";

import { ISablierEscrow } from "src/interfaces/ISablierEscrow.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract SetNativeToken_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_CallerNotComptroller() external {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                EvmUtilsErrors.Comptrollerable_CallerNotComptroller.selector, address(comptroller), users.seller
            )
        );
        escrow.setNativeToken(address(sellToken));
    }

    function test_RevertWhen_ProvidedAddressZero() external whenCallerComptroller {
        // It should revert.
        vm.expectRevert(Errors.SablierEscrow_NativeTokenZeroAddress.selector);
        escrow.setNativeToken(address(0));
    }

    function test_RevertGiven_NativeTokenAlreadySet() external whenCallerComptroller whenProvidedAddressNotZero {
        // Set the native token first.
        address firstNativeToken = address(sellToken);
        escrow.setNativeToken(firstNativeToken);

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierEscrow_NativeTokenAlreadySet.selector, firstNativeToken));
        escrow.setNativeToken(address(buyToken));
    }

    function test_GivenNativeTokenNotSet() external whenCallerComptroller whenProvidedAddressNotZero {
        address newNativeToken = address(sellToken);

        // It should emit a {SetNativeToken} event.
        vm.expectEmit({ emitter: address(escrow) });
        emit ISablierEscrow.SetNativeToken({ comptroller: address(comptroller), nativeToken: newNativeToken });

        // Set the native token.
        escrow.setNativeToken(newNativeToken);

        // It should set the native token.
        assertEq(escrow.nativeToken(), newNativeToken, "nativeToken");
    }
}
