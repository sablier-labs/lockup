// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { Lockup } from "src/types/Lockup.sol";
import { LockupPriceGated } from "src/types/LockupPriceGated.sol";

import { Lockup_PriceGated_Integration_Concrete_Test } from "../LockupPriceGated.t.sol";

contract GetPriceGatedUnlockParams_Integration_Concrete_Test is Lockup_PriceGated_Integration_Concrete_Test {
    function test_RevertGiven_Null() external {
        expectRevert_Null({ callData: abi.encodeCall(lockup.getPriceGatedUnlockParams, ids.nullStream) });
    }

    function test_RevertGiven_NotPriceGatedModel() external givenNotNull {
        // Create a stream with the linear model.
        lockupModel = Lockup.Model.LOCKUP_LINEAR;
        uint256 streamId = createDefaultStreamWithDurations();

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockupState_NotExpectedModel.selector,
                Lockup.Model.LOCKUP_LINEAR,
                Lockup.Model.LOCKUP_PRICE_GATED
            )
        );
        lockup.getPriceGatedUnlockParams(streamId);
    }

    function test_GivenPriceGatedModel() external view givenNotNull {
        LockupPriceGated.UnlockParams memory unlockParams = lockup.getPriceGatedUnlockParams(ids.defaultStream);
        assertEq(address(unlockParams.oracle), address(oracle), "oracle");
        assertEq(unlockParams.targetPrice, defaults.LPG_TARGET_PRICE(), "targetPrice");
    }
}
