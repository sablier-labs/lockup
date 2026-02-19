// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";

import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract SetNativeToken_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_CallerNotComptroller() external {
        // It should revert.
        setMsgSender(users.eve);
        vm.expectRevert(
            abi.encodeWithSelector(
                EvmUtilsErrors.Comptrollerable_CallerNotComptroller.selector, address(comptroller), users.eve
            )
        );
        bob.setNativeToken(address(dai));
    }

    function test_RevertWhen_ProvidedAddressZero() external whenCallerComptroller {
        // It should revert.
        vm.expectRevert(Errors.SablierBob_NativeTokenZeroAddress.selector);
        bob.setNativeToken(address(0));
    }

    function test_RevertGiven_NativeTokenAlreadySet() external whenCallerComptroller whenProvidedAddressNotZero {
        // Set the native token first.
        address firstNativeToken = address(dai);
        bob.setNativeToken(firstNativeToken);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierBob_NativeTokenAlreadySet.selector, firstNativeToken)
        );
        bob.setNativeToken(address(weth));
    }

    function test_GivenNativeTokenNotSet() external whenCallerComptroller whenProvidedAddressNotZero {
        address newNativeToken = address(dai);

        // It should emit a {SetNativeToken} event.
        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.SetNativeToken({ comptroller: address(comptroller), nativeToken: newNativeToken });

        // Set the native token.
        bob.setNativeToken(newNativeToken);

        // It should set the native token.
        assertEq(bob.nativeToken(), newNativeToken, "nativeToken");
    }
}
