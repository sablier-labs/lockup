// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierLockup } from "src/core/interfaces/ISablierLockup.sol";
import { Errors } from "src/core/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

abstract contract AllowToHook_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        // Make Eve the caller in this test.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.admin, users.eve));
        lockup.allowToHook(users.eve);
    }

    function test_RevertWhen_ProvidedAddressNotContract() external whenCallerRecipient(users.admin) {
        address eoa = vm.addr({ privateKey: 1 });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_AllowToHookZeroCodeSize.selector, eoa));
        lockup.allowToHook(eoa);
    }

    function test_RevertWhen_ProvidedAddressNotReturnInterfaceId()
        external
        whenCallerRecipient(users.admin)
        whenProvidedAddressContract
    {
        // Incorrect interface ID.
        address recipient = address(recipientInterfaceIDIncorrect);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockup_AllowToHookUnsupportedInterface.selector, recipient)
        );
        lockup.allowToHook(recipient);

        // Missing interface ID.
        recipient = address(recipientInterfaceIDMissing);
        vm.expectRevert(bytes(""));
        lockup.allowToHook(recipient);
    }

    function test_WhenProvidedAddressReturnsInterfaceId()
        external
        whenCallerRecipient(users.admin)
        whenProvidedAddressContract
    {
        // It should emit a {AllowToHook} event.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockup.AllowToHook(users.admin, address(recipientGood));

        // Allow the provided address to hook.
        lockup.allowToHook(address(recipientGood));

        // It should put the address on the allowlist.
        bool isAllowedToHook = lockup.isAllowedToHook(address(recipientGood));
        assertTrue(isAllowedToHook, "address not put on the allowlist");
    }
}
