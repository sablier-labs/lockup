// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";

import { ISablierLockup } from "src/interfaces/ISablierLockup.sol";
import { ISablierLockupRecipient } from "src/interfaces/ISablierLockupRecipient.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Lockup } from "src/types/Lockup.sol";

import { Integration_Test } from "../../../Integration.t.sol";

abstract contract Withdraw_Integration_Concrete_Test is Integration_Test {
    address internal caller;

    function test_RevertWhen_DelegateCall() external {
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();
        expectRevert_DelegateCall({
            callData: abi.encodeCall(lockup.withdraw, (ids.defaultStream, users.recipient, withdrawAmount))
        });
    }

    function test_RevertGiven_Null() external whenNoDelegateCall {
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();
        expectRevert_Null({
            callData: abi.encodeCall(lockup.withdraw, (ids.nullStream, users.recipient, withdrawAmount))
        });
    }

    function test_RevertGiven_DEPLETEDStatus() external whenNoDelegateCall givenNotNull {
        expectRevert_DEPLETEDStatus({
            callData: abi.encodeCall(lockup.withdraw, (ids.defaultStream, users.recipient, defaults.WITHDRAW_AMOUNT()))
        });
    }

    function test_RevertWhen_WithdrawalAddressZero() external whenNoDelegateCall givenNotNull givenNotDEPLETEDStatus {
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_WithdrawToZeroAddress.selector, ids.defaultStream));
        lockup.withdraw{ value: LOCKUP_MIN_FEE_WEI }({
            streamId: ids.defaultStream,
            to: address(0),
            amount: withdrawAmount
        });
    }

    function test_RevertWhen_ZeroWithdrawAmount()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotDEPLETEDStatus
        whenWithdrawalAddressNotZero
    {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_WithdrawAmountZero.selector, ids.defaultStream));
        lockup.withdraw{ value: LOCKUP_MIN_FEE_WEI }({ streamId: ids.defaultStream, to: users.recipient, amount: 0 });
    }

    function test_RevertWhen_WithdrawAmountOverdraws()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotDEPLETEDStatus
        whenWithdrawalAddressNotZero
        whenNonZeroWithdrawAmount
    {
        uint128 withdrawableAmount = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockup_Overdraw.selector, ids.defaultStream, MAX_UINT128, withdrawableAmount
            )
        );
        lockup.withdraw{ value: LOCKUP_MIN_FEE_WEI }({
            streamId: ids.defaultStream,
            to: users.recipient,
            amount: MAX_UINT128
        });
    }

    modifier whenWithdrawalAddressNotRecipient(bool isCallerRecipient) {
        if (!isCallerRecipient) {
            // When caller is unknown.
            caller = users.eve;
            setMsgSender(caller);
            _;

            // When caller is sender.
            caller = users.sender;
            setMsgSender(caller);
            _;

            // When caller is a former recipient.
            caller = users.recipient;
            setMsgSender(caller);
            lockup.transferFrom(caller, users.eve, ids.defaultStream);
            _;
        } else {
            // When caller is approved third party.
            caller = users.operator;
            setMsgSender(caller);
            _;

            // When caller is recipient.
            caller = users.recipient;
            setMsgSender(caller);
            _;
        }
    }

    function test_RevertWhen_CallerNotApprovedThirdPartyOrRecipient()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotDEPLETEDStatus
        whenWithdrawalAddressNotZero
        whenNonZeroWithdrawAmount
        whenWithdrawAmountNotOverdraw
        whenWithdrawalAddressNotRecipient(false)
    {
        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // Set the withdraw amount to the default amount.
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockup_WithdrawalAddressNotRecipient.selector, ids.defaultStream, caller, users.alice
            )
        );
        lockup.withdraw{ value: LOCKUP_MIN_FEE_WEI }({
            streamId: ids.defaultStream,
            to: users.alice,
            amount: withdrawAmount
        });
    }

    function test_WhenCallerApprovedThirdPartyOrRecipient()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotDEPLETEDStatus
        whenWithdrawalAddressNotZero
        whenNonZeroWithdrawAmount
        whenWithdrawAmountNotOverdraw
        whenWithdrawalAddressNotRecipient(true)
    {
        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // Set the withdraw amount to the default amount.
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT() / 2;

        uint128 previousWithdrawnAmount = lockup.getWithdrawnAmount(ids.defaultStream);

        // It should emit {WithdrawFromLockupStream} and {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockup.WithdrawFromLockupStream({
            streamId: ids.defaultStream,
            to: users.alice,
            token: dai,
            amount: withdrawAmount
        });
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: ids.defaultStream });

        // Make the withdrawal.
        lockup.withdraw{ value: LOCKUP_MIN_FEE_WEI }({
            streamId: ids.defaultStream,
            to: users.alice,
            amount: withdrawAmount
        });

        // It should update the withdrawn amount.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(ids.defaultStream);
        uint128 expectedWithdrawnAmount = previousWithdrawnAmount + withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    function test_WhenCallerUnknown()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotDEPLETEDStatus
        whenWithdrawalAddressNotZero
        whenNonZeroWithdrawAmount
        whenWithdrawAmountNotOverdraw
        whenWithdrawalAddressRecipient
    {
        // Make the unknown address the caller in this test.
        setMsgSender(address(0xCAFE));

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // Make the withdrawal.
        lockup.withdraw{ value: LOCKUP_MIN_FEE_WEI }({
            streamId: ids.defaultStream,
            to: users.recipient,
            amount: defaults.WITHDRAW_AMOUNT()
        });

        // It should update the withdrawn amount.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(ids.defaultStream);
        uint128 expectedWithdrawnAmount = defaults.WITHDRAW_AMOUNT();
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    function test_WhenCallerRecipient()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotDEPLETEDStatus
        whenWithdrawalAddressNotZero
        whenNonZeroWithdrawAmount
        whenWithdrawAmountNotOverdraw
        whenWithdrawalAddressRecipient
    {
        setMsgSender(users.recipient);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // Make the withdrawal.
        lockup.withdraw{ value: LOCKUP_MIN_FEE_WEI }({
            streamId: ids.defaultStream,
            to: users.recipient,
            amount: defaults.WITHDRAW_AMOUNT()
        });

        // It should update the withdrawn amount.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(ids.defaultStream);
        uint128 expectedWithdrawnAmount = defaults.WITHDRAW_AMOUNT();
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    function test_RevertWhen_FeeLessThanMinFee()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotDEPLETEDStatus
        whenWithdrawalAddressNotZero
        whenNonZeroWithdrawAmount
        whenWithdrawAmountNotOverdraw
        whenWithdrawalAddressRecipient
        whenCallerSender
    {
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        uint256 fee = LOCKUP_MIN_FEE_WEI - 1;
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockup_InsufficientFeePayment.selector, fee, LOCKUP_MIN_FEE_WEI)
        );

        // Make the withdrawal.
        lockup.withdraw{ value: fee }({ streamId: ids.defaultStream, to: users.recipient, amount: withdrawAmount });
    }

    function test_GivenEndTimeNotInFuture()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotDEPLETEDStatus
        whenWithdrawalAddressNotZero
        whenNonZeroWithdrawAmount
        whenWithdrawAmountNotOverdraw
        whenWithdrawalAddressRecipient
        whenCallerSender
        whenFeeNotLessThanMinFee
    {
        // Warp to the stream's end.
        vm.warp({ newTimestamp: defaults.END_TIME() });

        // Make the withdrawal.
        lockup.withdraw{ value: LOCKUP_MIN_FEE_WEI }({
            streamId: ids.defaultStream,
            to: users.recipient,
            amount: defaults.DEPOSIT_AMOUNT()
        });

        // It should mark the stream as depleted.
        Lockup.Status actualStatus = lockup.statusOf(ids.defaultStream);
        Lockup.Status expectedStatus = Lockup.Status.DEPLETED;
        assertEq(actualStatus, expectedStatus);

        // It should make the stream not cancelable.
        bool isCancelable = lockup.isCancelable(ids.defaultStream);
        assertFalse(isCancelable, "isCancelable");

        // Assert that the not burned NFT.
        address actualNFTowner = lockup.ownerOf({ tokenId: ids.defaultStream });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTowner, expectedNFTOwner, "NFT owner");
    }

    function test_GivenCanceledStream()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotDEPLETEDStatus
        whenWithdrawalAddressNotZero
        whenNonZeroWithdrawAmount
        whenWithdrawAmountNotOverdraw
        whenWithdrawalAddressRecipient
        whenCallerSender
        whenFeeNotLessThanMinFee
        givenEndTimeInFuture
    {
        // Cancel the stream.
        lockup.cancel(ids.defaultStream);

        // Set the withdraw amount to the withdrawable amount.
        uint128 withdrawAmount = lockup.withdrawableAmountOf(ids.defaultStream);

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

        // It should update the withdrawn amount.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(ids.defaultStream);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");

        // Assert that the not burned NFT.
        address actualNFTowner = lockup.ownerOf({ tokenId: ids.defaultStream });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTowner, expectedNFTOwner, "NFT owner");
    }

    function test_GivenRecipientNotAllowedToHook()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotDEPLETEDStatus
        whenWithdrawalAddressNotZero
        whenNonZeroWithdrawAmount
        whenWithdrawAmountNotOverdraw
        whenWithdrawalAddressRecipient
        whenCallerSender
        whenFeeNotLessThanMinFee
        givenEndTimeInFuture
        givenNotCanceledStream
    {
        // It should not make Sablier run the recipient hook.
        uint128 withdrawAmount = lockup.withdrawableAmountOf(ids.notAllowedToHookStream);
        vm.expectCall({
            callee: address(recipientGood),
            data: abi.encodeCall(
                ISablierLockupRecipient.onSablierLockupWithdraw,
                (ids.notAllowedToHookStream, users.sender, address(recipientInterfaceIDIncorrect), withdrawAmount)
            ),
            count: 0
        });

        // Make the withdrawal.
        lockup.withdraw{ value: LOCKUP_MIN_FEE_WEI }({
            streamId: ids.notAllowedToHookStream,
            to: address(recipientInterfaceIDIncorrect),
            amount: withdrawAmount
        });

        // It should update the withdrawn amount.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(ids.notAllowedToHookStream);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    function test_RevertWhen_RevertingRecipient()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotDEPLETEDStatus
        whenWithdrawalAddressNotZero
        whenNonZeroWithdrawAmount
        whenWithdrawAmountNotOverdraw
        whenWithdrawalAddressRecipient
        whenCallerSender
        whenFeeNotLessThanMinFee
        givenEndTimeInFuture
        givenNotCanceledStream
        givenRecipientAllowedToHook
    {
        // Expect a revert.
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();
        vm.expectRevert("You shall not pass");

        // Make the withdrawal.
        lockup.withdraw{ value: LOCKUP_MIN_FEE_WEI }({
            streamId: ids.recipientRevertStream,
            to: address(recipientReverting),
            amount: withdrawAmount
        });
    }

    function test_RevertWhen_HookReturnsInvalidSelector()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotDEPLETEDStatus
        whenWithdrawalAddressNotZero
        whenNonZeroWithdrawAmount
        whenWithdrawAmountNotOverdraw
        whenWithdrawalAddressRecipient
        whenCallerSender
        whenFeeNotLessThanMinFee
        givenEndTimeInFuture
        givenNotCanceledStream
        givenRecipientAllowedToHook
        whenNonRevertingRecipient
    {
        // Expect a revert.
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockup_InvalidHookSelector.selector, address(recipientInvalidSelector))
        );

        // Cancel the stream.
        lockup.withdraw{ value: LOCKUP_MIN_FEE_WEI }({
            streamId: ids.recipientInvalidSelectorStream,
            to: address(recipientInvalidSelector),
            amount: withdrawAmount
        });
    }

    function test_WhenReentrancy()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotDEPLETEDStatus
        whenWithdrawalAddressNotZero
        whenNonZeroWithdrawAmount
        whenWithdrawAmountNotOverdraw
        whenWithdrawalAddressRecipient
        whenCallerSender
        whenFeeNotLessThanMinFee
        givenEndTimeInFuture
        givenNotCanceledStream
        givenRecipientAllowedToHook
        whenNonRevertingRecipient
        whenHookReturnsValidSelector
    {
        uint256 previousAggregateAmount = lockup.aggregateAmount(dai);

        // Halve the withdraw amount so that the recipient can re-entry and make another withdrawal.
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT() / 2;

        // It should make Sablier run the recipient hook.
        vm.expectCall(
            address(recipientReentrant),
            abi.encodeCall(
                ISablierLockupRecipient.onSablierLockupWithdraw,
                (ids.recipientReentrantStream, users.sender, address(recipientReentrant), withdrawAmount)
            )
        );

        // It should make multiple withdrawals.
        lockup.withdraw{ value: LOCKUP_MIN_FEE_WEI }({
            streamId: ids.recipientReentrantStream,
            to: address(recipientReentrant),
            amount: withdrawAmount
        });

        // Assert that the stream's status is still "STREAMING".
        Lockup.Status actualStatus = lockup.statusOf(ids.recipientReentrantStream);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);

        // It should update the withdrawn amounts.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(ids.recipientReentrantStream);
        uint128 expectedWithdrawnAmount = defaults.WITHDRAW_AMOUNT();
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");

        // It should update the aggregate amount.
        uint256 actualAggregateAmount = lockup.aggregateAmount(dai);
        uint256 expectedAggregateAmount = previousAggregateAmount - defaults.WITHDRAW_AMOUNT();
        assertEq(actualAggregateAmount, expectedAggregateAmount, "aggregateAmount");
    }

    function test_WhenNoReentrancy()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotDEPLETEDStatus
        whenWithdrawalAddressNotZero
        whenNonZeroWithdrawAmount
        whenWithdrawAmountNotOverdraw
        whenWithdrawalAddressRecipient
        whenCallerSender
        whenFeeNotLessThanMinFee
        givenEndTimeInFuture
        givenNotCanceledStream
        givenRecipientAllowedToHook
        whenNonRevertingRecipient
        whenHookReturnsValidSelector
    {
        uint256 previousAggregateAmount = lockup.aggregateAmount(dai);

        // Set the withdraw amount to the default amount.
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();

        // Expect the tokens to be transferred to the recipient contract.
        expectCallToTransfer({ to: address(recipientGood), value: withdrawAmount });

        // It should make Sablier run the recipient hook.
        vm.expectCall(
            address(recipientGood),
            abi.encodeCall(
                ISablierLockupRecipient.onSablierLockupWithdraw,
                (ids.recipientGoodStream, users.sender, address(recipientGood), withdrawAmount)
            )
        );

        // It should emit {WithdrawFromLockupStream} and {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockup.WithdrawFromLockupStream({
            streamId: ids.recipientGoodStream,
            to: address(recipientGood),
            token: dai,
            amount: withdrawAmount
        });
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: ids.recipientGoodStream });

        // Make the withdrawal.
        lockup.withdraw{ value: LOCKUP_MIN_FEE_WEI }({
            streamId: ids.recipientGoodStream,
            to: address(recipientGood),
            amount: withdrawAmount
        });

        // Assert that the stream's status is still "STREAMING".
        Lockup.Status actualStatus = lockup.statusOf(ids.recipientGoodStream);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);

        // It should update the withdrawn amount.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(ids.recipientGoodStream);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");

        // It should update the aggregate amount.
        uint256 actualAggregateAmount = lockup.aggregateAmount(dai);
        uint256 expectedAggregateAmount = previousAggregateAmount - defaults.WITHDRAW_AMOUNT();
        assertEq(actualAggregateAmount, expectedAggregateAmount, "aggregateAmount");
    }
}
