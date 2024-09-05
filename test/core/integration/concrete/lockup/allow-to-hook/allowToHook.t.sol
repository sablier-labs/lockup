// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/core/libraries/Errors.sol";
import { Integration_Test } from "./../../../Integration.t.sol";
import { Lockup_Integration_Shared_Test } from "./../../../shared/lockup/Lockup.t.sol";

abstract contract AllowToHook_Integration_Concrete_Test is Integration_Test, Lockup_Integration_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Integration_Test, Lockup_Integration_Shared_Test) {
        defaultStreamId = createDefaultStream();
    }

    function test_RevertWhen_CallerNotAdmin() external {
        // Make Eve the caller in this test.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.admin, users.eve));
        lockup.allowToHook(users.eve);
    }

    modifier whenCallerAdmin() {
        // Make the Admin the caller in the rest of this test suite.
        resetPrank({ msgSender: users.admin });
        _;
    }

    function test_RevertWhen_ProvidedAddressNotContract() external whenCallerAdmin {
        address eoa = vm.addr({ privateKey: 1 });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_AllowToHookZeroCodeSize.selector, eoa));
        lockup.allowToHook(eoa);
    }

    modifier whenProvidedAddressContract() {
        _;
    }

    function test_RevertWhen_ProvidedAddressNotReturnInterfaceId()
        external
        whenCallerAdmin
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

    function test_WhenProvidedAddressReturnsInterfaceId() external whenCallerAdmin whenProvidedAddressContract {
        // It should emit a {AllowToHook} event.
        vm.expectEmit({ emitter: address(lockup) });
        emit AllowToHook(users.admin, address(recipientGood));

        // Allow the provided address to hook.
        lockup.allowToHook(address(recipientGood));

        // It should put the address on the allowlist.
        bool isAllowedToHook = lockup.isAllowedToHook(address(recipientGood));
        assertTrue(isAllowedToHook, "address not put on the allowlist");
    }
}
