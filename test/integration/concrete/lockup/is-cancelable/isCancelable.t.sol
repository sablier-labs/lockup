// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Lockup_Integration_Shared_Test } from "../../../shared/lockup/Lockup.t.sol";
import { Integration_Test } from "../../../Integration.t.sol";

abstract contract IsCancelable_Integration_Concrete_Test is Integration_Test, Lockup_Integration_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Integration_Test, Lockup_Integration_Shared_Test) { }

    function test_RevertWhen_Null() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        lockup.isCancelable(nullStreamId);
    }

    modifier givenNotNull() {
        defaultStreamId = createDefaultStream();
        _;
    }

    function test_IsCancelable_Cold() external givenNotNull {
        vm.warp({ timestamp: defaults.END_TIME() }); // settled status
        bool isCancelable = lockup.isCancelable(defaultStreamId);
        assertFalse(isCancelable, "isCancelable");
    }

    modifier givenNotCold() {
        _;
    }

    function test_IsCancelable_StreamCancelable() external givenNotNull givenNotCold {
        bool isCancelable = lockup.isCancelable(defaultStreamId);
        assertTrue(isCancelable, "isCancelable");
    }

    modifier givenStreamNotCancelable() {
        _;
    }

    function test_IsCancelable() external givenNotNull givenNotCold givenStreamNotCancelable {
        uint256 streamId = createDefaultStreamNotCancelable();
        bool isCancelable = lockup.isCancelable(streamId);
        assertFalse(isCancelable, "isCancelable");
    }
}
