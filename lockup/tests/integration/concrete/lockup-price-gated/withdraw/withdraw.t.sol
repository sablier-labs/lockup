// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";

import { ISablierLockup } from "src/interfaces/ISablierLockup.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Lockup } from "src/types/Lockup.sol";

import { Lockup_PriceGated_Integration_Concrete_Test } from "../LockupPriceGated.t.sol";

contract Withdraw_Lockup_PriceGated_Integration_Concrete_Test is Lockup_PriceGated_Integration_Concrete_Test {
    function test_RevertWhen_LatestPriceBelowTarget() external givenEndTimeInFuture {
        uint128 withdrawAmount = defaults.DEPOSIT_AMOUNT();
        uint128 withdrawableAmount = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockup_Overdraw.selector, ids.defaultStream, withdrawAmount, withdrawableAmount
            )
        );
        lockup.withdraw{ value: LOCKUP_MIN_FEE_WEI }({
            streamId: ids.defaultStream,
            to: users.recipient,
            amount: withdrawAmount
        });
    }

    function test_WhenLatestPriceNotBelowTarget() external givenEndTimeInFuture {
        // Update oracle to return target price.
        oracle.setPrice(defaults.LPG_TARGET_PRICE());

        uint128 withdrawAmount = defaults.DEPOSIT_AMOUNT();

        // It should emit {WithdrawFromLockupStream} and {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockup.WithdrawFromLockupStream({
            streamId: ids.defaultStream,
            to: users.recipient,
            token: dai,
            amount: withdrawAmount
        });
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: ids.defaultStream });

        // Make the withdrawal.
        lockup.withdraw{ value: LOCKUP_MIN_FEE_WEI }({
            streamId: ids.defaultStream,
            to: users.recipient,
            amount: withdrawAmount
        });

        // It should mark the stream as depleted.
        Lockup.Status actualStatus = lockup.statusOf(ids.defaultStream);
        Lockup.Status expectedStatus = Lockup.Status.DEPLETED;
        assertEq(actualStatus, expectedStatus);
    }

    function test_WhenLatestPriceBelowTarget() external givenEndTimeNotInFuture {
        uint128 withdrawAmount = defaults.DEPOSIT_AMOUNT();

        // It should emit {WithdrawFromLockupStream} and {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockup.WithdrawFromLockupStream({
            streamId: ids.defaultStream,
            to: users.recipient,
            token: dai,
            amount: withdrawAmount
        });
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: ids.defaultStream });

        // Make the withdrawal.
        lockup.withdraw{ value: LOCKUP_MIN_FEE_WEI }({
            streamId: ids.defaultStream,
            to: users.recipient,
            amount: withdrawAmount
        });

        // It should mark the stream as depleted.
        Lockup.Status actualStatus = lockup.statusOf(ids.defaultStream);
        Lockup.Status expectedStatus = Lockup.Status.DEPLETED;
        assertEq(actualStatus, expectedStatus);
    }

    function test_WhenLatestPriceNotBelowTarget_GivenEndTimeNotInFuture() external givenEndTimeNotInFuture {
        // Update oracle to return target price.
        oracle.setPrice(defaults.LPG_TARGET_PRICE());

        uint128 withdrawAmount = defaults.DEPOSIT_AMOUNT();

        // It should emit {WithdrawFromLockupStream} and {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockup.WithdrawFromLockupStream({
            streamId: ids.defaultStream,
            to: users.recipient,
            token: dai,
            amount: withdrawAmount
        });
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: ids.defaultStream });

        // Make the withdrawal.
        lockup.withdraw{ value: LOCKUP_MIN_FEE_WEI }({
            streamId: ids.defaultStream,
            to: users.recipient,
            amount: withdrawAmount
        });

        // It should mark the stream as depleted.
        Lockup.Status actualStatus = lockup.statusOf(ids.defaultStream);
        Lockup.Status expectedStatus = Lockup.Status.DEPLETED;
        assertEq(actualStatus, expectedStatus);
    }
}
