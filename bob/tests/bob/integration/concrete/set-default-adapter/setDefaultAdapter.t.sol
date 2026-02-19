// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";

import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { ISablierLidoAdapter } from "src/interfaces/ISablierLidoAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract SetDefaultAdapter_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_CallerNotComptroller() external {
        // It should revert.
        setMsgSender(users.eve);
        vm.expectRevert(
            abi.encodeWithSelector(
                EvmUtilsErrors.Comptrollerable_CallerNotComptroller.selector, address(comptroller), users.eve
            )
        );
        bob.setDefaultAdapter(IERC20(address(weth)), ISablierLidoAdapter(address(adapter)));
    }

    function test_RevertWhen_AdapterDoesNotSupportInterface() external whenCallerComptroller whenAdapterNotZeroAddress {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierBob_NewAdapterMissesInterface.selector, address(mockAdapterInvalid))
        );
        bob.setDefaultAdapter(IERC20(address(weth)), ISablierLidoAdapter(address(mockAdapterInvalid)));
    }

    function test_WhenAdapterSupportsInterface() external whenCallerComptroller whenAdapterNotZeroAddress {
        // It should set adapter for token.
        // Expect the SetDefaultAdapter event.
        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.SetDefaultAdapter({
            token: IERC20(address(weth)),
            adapter: ISablierLidoAdapter(address(adapter))
        });

        // Set the adapter.
        bob.setDefaultAdapter(IERC20(address(weth)), ISablierLidoAdapter(address(adapter)));

        // Assert the adapter was set.
        assertEq(address(bob.getDefaultAdapterFor(IERC20(address(weth)))), address(adapter), "adapter should be set");
    }

    function test_WhenAdapterZeroAddress() external whenCallerComptroller {
        // It should disable adapter for token.
        // First set an adapter.
        bob.setDefaultAdapter(IERC20(address(weth)), ISablierLidoAdapter(address(adapter)));
        assertEq(
            address(bob.getDefaultAdapterFor(IERC20(address(weth)))),
            address(adapter),
            "adapter should be set initially"
        );

        // Expect the SetDefaultAdapter event with zero address.
        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.SetDefaultAdapter({ token: IERC20(address(weth)), adapter: ISablierLidoAdapter(address(0)) });

        // Disable the adapter by setting to zero address.
        bob.setDefaultAdapter(IERC20(address(weth)), ISablierLidoAdapter(address(0)));

        // Assert the adapter was disabled.
        assertEq(
            address(bob.getDefaultAdapterFor(IERC20(address(weth)))), address(0), "adapter should be zero (disabled)"
        );
    }
}
