// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { DeployComptroller } from "script/DeployComptroller.s.sol";
import { SablierV2Comptroller } from "src/SablierV2Comptroller.sol";
import { Events } from "src/libraries/Events.sol";

import { Comptroller_Unit_Test } from "../Comptroller.t.sol";

contract Constructor_Comptroller_Unit_Test is Comptroller_Unit_Test {
    /// @dev it should initialize all values correctly and emit a {TransferAdmin} event.
    function test_Constructor() external {
        // Expect a {TransferEvent} to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: false });
        emit Events.TransferAdmin({ oldAdmin: address(0), newAdmin: users.admin });

        // Construct the comptroller contract.
        SablierV2Comptroller constructedComptroller = new SablierV2Comptroller({ initialAdmin: users.admin });

        // Assert that the admin was initialized.
        address actualAdmin = constructedComptroller.admin();
        address expectedAdmin = users.admin;
        assertEq(actualAdmin, expectedAdmin, "admin");
    }
}
