// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierLockupBase } from "src/interfaces/ISablierLockupBase.sol";
import { Errors } from "src/libraries/Errors.sol";

import { RecipientGood } from "../../../../mocks/Hooks.sol";
import { Integration_Test } from "../../../Integration.t.sol";

contract AllowToHook_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        // Make Eve the caller in this test.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.admin, users.eve));
        lockup.allowToHook(users.eve);
    }

    function test_RevertWhen_ProvidedAddressNotContract() external whenCallerAdmin {
        address eoa = vm.addr({ privateKey: 1 });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockupBase_AllowToHookZeroCodeSize.selector, eoa));
        lockup.allowToHook(eoa);
    }

    function test_RevertWhen_ProvidedAddressNotReturnInterfaceId()
        external
        whenCallerAdmin
        whenProvidedAddressContract
    {
        // Incorrect interface ID.
        address recipient = address(recipientInterfaceIDIncorrect);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockupBase_AllowToHookUnsupportedInterface.selector, recipient)
        );
        lockup.allowToHook(recipient);

        // Missing interface ID.
        recipient = address(recipientInterfaceIDMissing);
        vm.expectRevert(bytes(""));
        lockup.allowToHook(recipient);
    }

    function test_WhenProvidedAddressReturnsInterfaceId() external whenCallerAdmin whenProvidedAddressContract {
        // Define a recipient that implementes the interface correctly.
        RecipientGood recipientWithInterfaceId = new RecipientGood();

        // It should emit a {AllowToHook} event.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupBase.AllowToHook(users.admin, address(recipientWithInterfaceId));

        // Allow the provided address to hook.
        lockup.allowToHook(address(recipientWithInterfaceId));

        // It should put the address on the allowlist.
        bool isAllowedToHook = lockup.isAllowedToHook(address(recipientWithInterfaceId));
        assertTrue(isAllowedToHook, "address not put on the allowlist");
    }
}
