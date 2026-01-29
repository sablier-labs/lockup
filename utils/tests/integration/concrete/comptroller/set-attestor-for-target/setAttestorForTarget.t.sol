// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Errors } from "src/libraries/Errors.sol";

import { Base_Test } from "tests/Base.t.sol";
import { MerkleMock, MerkleMockReverting } from "tests/mocks/MerkleMock.sol";

contract SetAttestorForTarget_Comptroller_Concrete_Test is Base_Test {
    MerkleMock internal merkleMock;
    MerkleMockReverting internal merkleMockReverting;
    address internal newAttestor = makeAddr("newAttestor");

    function setUp() public override {
        Base_Test.setUp();

        // Deploy mock contracts.
        merkleMock = new MerkleMock();
        merkleMockReverting = new MerkleMockReverting();
    }

    function test_RevertWhen_CallerWithoutFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.eve);

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.UnauthorizedAccess.selector, users.eve, FEE_MANAGEMENT_ROLE));
        comptroller.setAttestorForTarget(address(merkleMock), newAttestor);
    }

    function test_WhenCallerWithFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.accountant);

        // It should not revert.
        comptroller.setAttestorForTarget(address(merkleMock), newAttestor);
    }

    function test_RevertWhen_CallReverts() external whenCallerAdmin {
        // It should revert.
        vm.expectRevert("Not gonna happen");
        comptroller.setAttestorForTarget(address(merkleMockReverting), newAttestor);
    }

    function test_WhenCallDoesNotRevert() external whenCallerAdmin {
        // It should succeed.
        comptroller.setAttestorForTarget(address(merkleMock), newAttestor);
    }
}
