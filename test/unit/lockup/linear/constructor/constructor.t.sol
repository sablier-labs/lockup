// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { UD60x18 } from "@prb/math/UD60x18.sol";

import { SablierV2LockupLinear } from "src/SablierV2LockupLinear.sol";
import { Events } from "src/libraries/Events.sol";

import { Linear_Unit_Test } from "../Linear.t.sol";

contract Constructor_Linear_Unit_Test is Linear_Unit_Test {
    /// @dev it should initialize all values correctly and emit a {TransferAdmin} event.
    function test_Constructor() external {
        // Expect a {TransferEvent} to be emitted.
        expectEmit();
        emit Events.TransferAdmin({ oldAdmin: address(0), newAdmin: users.admin });

        // Construct the linear contract.
        SablierV2LockupLinear constructedLinear = new SablierV2LockupLinear({
            initialAdmin: users.admin,
            initialComptroller: comptroller,
            nftDescriptor: nftDescriptor,
            maxFee: DEFAULT_MAX_FEE
        });

        // {SablierV2-constructor}
        address actualAdmin = constructedLinear.admin();
        address expectedAdmin = users.admin;
        assertEq(actualAdmin, expectedAdmin, "admin");

        address actualComptroller = address(constructedLinear.comptroller());
        address expectedComptroller = address(comptroller);
        assertEq(actualComptroller, expectedComptroller, "comptroller");

        UD60x18 actualMaxFee = constructedLinear.MAX_FEE();
        UD60x18 expectedMaxFee = DEFAULT_MAX_FEE;
        assertEq(actualMaxFee, expectedMaxFee, "MAX_FEE");

        // {SablierV2Lockup-constructor}
        uint256 actualStreamId = constructedLinear.nextStreamId();
        uint256 expectedStreamId = 1;
        assertEq(actualStreamId, expectedStreamId, "nextStreamId");
    }
}
