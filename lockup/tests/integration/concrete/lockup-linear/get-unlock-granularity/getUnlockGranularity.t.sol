// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { Lockup } from "src/types/Lockup.sol";

import { Lockup_Linear_Integration_Concrete_Test } from "../LockupLinear.t.sol";

contract GetGranularity_Integration_Concrete_Test is Lockup_Linear_Integration_Concrete_Test {
    function test_RevertGiven_Null() external {
        expectRevert_Null({ callData: abi.encodeCall(lockup.getGranularity, ids.nullStream) });
    }

    function test_RevertGiven_NotLinearModel() external givenNotNull {
        lockupModel = Lockup.Model.LOCKUP_TRANCHED;
        uint256 streamId = createDefaultStream();
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockupState_NotExpectedModel.selector,
                Lockup.Model.LOCKUP_TRANCHED,
                Lockup.Model.LOCKUP_LINEAR
            )
        );
        lockup.getGranularity(streamId);
    }

    function test_GivenLinearModel() external view givenNotNull {
        uint40 actualGranularity = lockup.getGranularity(ids.defaultStream);
        uint40 expectedGranularity = defaults.GRANULARITY();
        assertEq(actualGranularity, expectedGranularity, "granularity");
    }
}
