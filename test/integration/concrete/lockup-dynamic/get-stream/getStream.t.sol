// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "contracts/libraries/Errors.sol";
import { LockupDynamic } from "contracts/types/DataTypes.sol";

import { LockupDynamic_Integration_Concrete_Test } from "../LockupDynamic.t.sol";

contract GetStream_LockupDynamic_Integration_Concrete_Test is LockupDynamic_Integration_Concrete_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override {
        LockupDynamic_Integration_Concrete_Test.setUp();
        defaultStreamId = createDefaultStream();
    }

    function test_RevertGiven_Null() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        lockupDynamic.getStream(nullStreamId);
    }

    modifier givenNotNull() {
        _;
    }

    function test_GetStream_StatusSettled() external givenNotNull {
        vm.warp({ timestamp: defaults.END_TIME() });
        LockupDynamic.Stream memory actualStream = lockupDynamic.getStream(defaultStreamId);
        LockupDynamic.Stream memory expectedStream = defaults.lockupDynamicStream();
        expectedStream.isCancelable = false;
        assertEq(actualStream, expectedStream);
    }

    modifier givenStatusNotSettled() {
        _;
    }

    function test_GetStream() external givenNotNull givenStatusNotSettled {
        uint256 streamId = createDefaultStream();
        LockupDynamic.Stream memory actualStream = lockupDynamic.getStream(streamId);
        LockupDynamic.Stream memory expectedStream = defaults.lockupDynamicStream();
        assertEq(actualStream, expectedStream);
    }
}
