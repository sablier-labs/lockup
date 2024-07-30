// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";
import { SablierLockupTranched } from "src/core/SablierLockupTranched.sol";

import { LockupTranched_Integration_Concrete_Test } from "./LockupTranched.t.sol";

contract Constructor_LockupTranched_Integration_Concrete_Test is LockupTranched_Integration_Concrete_Test {
    function test_Constructor() external {
        // Expect the relevant event to be emitted.
        vm.expectEmit();
        emit TransferAdmin({ oldAdmin: address(0), newAdmin: users.admin });

        // Construct the contract.
        SablierLockupTranched constructedLockupTranched = new SablierLockupTranched({
            initialAdmin: users.admin,
            initialNFTDescriptor: nftDescriptor,
            maxTrancheCount: defaults.MAX_TRANCHE_COUNT()
        });

        // {SablierLockup.constant}
        UD60x18 actualMaxBrokerFee = constructedLockupTranched.MAX_BROKER_FEE();
        UD60x18 expectedMaxBrokerFee = UD60x18.wrap(0.1e18);
        assertEq(actualMaxBrokerFee, expectedMaxBrokerFee, "MAX_BROKER_FEE");

        // {SablierLockup.constructor}
        address actualAdmin = constructedLockupTranched.admin();
        address expectedAdmin = users.admin;
        assertEq(actualAdmin, expectedAdmin, "admin");

        uint256 actualStreamId = constructedLockupTranched.nextStreamId();
        uint256 expectedStreamId = 1;
        assertEq(actualStreamId, expectedStreamId, "nextStreamId");

        address actualNFTDescriptor = address(constructedLockupTranched.nftDescriptor());
        address expectedNFTDescriptor = address(nftDescriptor);
        assertEq(actualNFTDescriptor, expectedNFTDescriptor, "nftDescriptor");

        // {SablierLockup.supportsInterface}
        assertTrue(constructedLockupTranched.supportsInterface(0x49064906), "ERC-4906 interface ID");

        // {SablierLockupTranched.constructor}
        uint256 actualMaxTrancheCount = constructedLockupTranched.MAX_TRANCHE_COUNT();
        uint256 expectedMaxTrancheCount = defaults.MAX_TRANCHE_COUNT();
        assertEq(actualMaxTrancheCount, expectedMaxTrancheCount, "MAX_TRANCHE_COUNT");
    }
}
