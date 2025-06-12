// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";

import { ISablierLockup } from "src/interfaces/ISablierLockup.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Integration_Test } from "./../../../Integration.t.sol";

contract TransferFeesToComptroller_Lockup_Integration_Concrete_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });
    }

    function test_RevertGiven_ComptrollerNotImplementReceive() external {
        setMsgSender(address(comptroller));
        lockup.setComptroller(ISablierComptroller(address(contractWithoutReceive)));

        // Fund the lockup with fees to transfer.
        vm.deal(address(lockup), 1 ether);

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockup_FeeTransferFailed.selector,
                address(contractWithoutReceive),
                address(lockup).balance
            )
        );
        lockup.transferFeesToComptroller();
    }

    function test_GivenNoFeesToTransfer() external givenComptrollerImplementsReceive {
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockup.TransferFeesToComptroller(address(comptroller), 0);
        lockup.transferFeesToComptroller();
    }

    function test_GivenFeesToTransfer() external givenComptrollerImplementsReceive {
        lockup.withdrawMax{ value: LOCKUP_MIN_FEE_WEI }(ids.defaultStream, users.recipient);

        uint256 balanceBefore = address(comptroller).balance;

        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockup.TransferFeesToComptroller(address(comptroller), LOCKUP_MIN_FEE_WEI);
        lockup.transferFeesToComptroller();

        assertEq(
            address(comptroller).balance, balanceBefore + LOCKUP_MIN_FEE_WEI, "Fees not transferred to comptroller"
        );
    }
}
