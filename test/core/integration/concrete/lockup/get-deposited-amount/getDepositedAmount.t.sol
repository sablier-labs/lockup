// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/core/libraries/Errors.sol";
import { Integration_Test } from "./../../../Integration.t.sol";
import { Lockup_Integration_Shared_Test } from "./../../../shared/lockup/Lockup.t.sol";

abstract contract GetDepositedAmount_Integration_Concrete_Test is Integration_Test, Lockup_Integration_Shared_Test {
    function setUp() public virtual override(Integration_Test, Lockup_Integration_Shared_Test) { }

    function test_RevertGiven_Null() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_Null.selector, nullStreamId));
        lockup.getDepositedAmount(nullStreamId);
    }

    function test_GivenNotNull() external {
        uint256 streamId = createDefaultStream();
        uint128 actualDepositedAmount = lockup.getDepositedAmount(streamId);
        uint128 expectedDepositedAmount = defaults.DEPOSIT_AMOUNT();
        assertEq(actualDepositedAmount, expectedDepositedAmount, "depositedAmount");
    }
}
