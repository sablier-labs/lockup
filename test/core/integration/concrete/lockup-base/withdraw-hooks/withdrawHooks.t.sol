// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierLockupRecipient } from "src/core/interfaces/ISablierLockupRecipient.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract WithdrawHooks_Integration_Concrete_Test is Integration_Test {
    uint128 internal withdrawAmount;

    function setUp() public virtual override {
        Integration_Test.setUp();

        withdrawAmount = defaults.WITHDRAW_AMOUNT();

        // Allow the good recipient to hook.
        resetPrank({ msgSender: users.admin });
        lockup.allowToHook(address(recipientGood));
        resetPrank({ msgSender: users.sender });
    }

    function test_GivenRecipientSameAsSender() external {
        uint256 identicalSenderRecipientStreamId = createDefaultStreamWithUsers(users.sender, users.sender);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // It should not make Sablier run the user hook.
        vm.expectCall({
            callee: users.sender,
            data: abi.encodeCall(
                ISablierLockupRecipient.onSablierLockupWithdraw,
                (identicalSenderRecipientStreamId, users.sender, users.sender, withdrawAmount)
            ),
            count: 0
        });

        // Make the withdrawal.
        lockup.withdraw({ streamId: identicalSenderRecipientStreamId, to: users.sender, amount: withdrawAmount });
    }

    function test_WhenCallerUnknown() external givenRecipientNotSameAsSender {
        // Make the unknown address the caller in this test.
        address unknownCaller = address(0xCAFE);
        resetPrank({ msgSender: unknownCaller });

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // It should make Sablier run the recipient hook.
        vm.expectCall({
            callee: address(recipientGood),
            data: abi.encodeCall(
                ISablierLockupRecipient.onSablierLockupWithdraw,
                (differentRecipientStreamId, unknownCaller, address(recipientGood), withdrawAmount)
            ),
            count: 1
        });

        // Make the withdrawal.
        lockup.withdraw({ streamId: differentRecipientStreamId, to: address(recipientGood), amount: withdrawAmount });
    }

    function test_WhenCallerApprovedThirdParty() external givenRecipientNotSameAsSender {
        // Approve the operator to handle the stream.
        resetPrank({ msgSender: address(recipientGood) });
        lockup.approve({ to: users.operator, tokenId: differentRecipientStreamId });

        // Make the operator the caller in this test.
        resetPrank({ msgSender: users.operator });

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // It should make Sablier run the recipient hook.
        vm.expectCall({
            callee: address(recipientGood),
            data: abi.encodeCall(
                ISablierLockupRecipient.onSablierLockupWithdraw,
                (differentRecipientStreamId, users.operator, address(recipientGood), withdrawAmount)
            ),
            count: 1
        });

        // Make the withdrawal.
        lockup.withdraw({ streamId: differentRecipientStreamId, to: address(recipientGood), amount: withdrawAmount });
    }

    function test_WhenCallerSender() external givenRecipientNotSameAsSender {
        // Make the Sender the caller in this test.
        resetPrank({ msgSender: users.sender });

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // It should make Sablier run the recipient hook.
        vm.expectCall({
            callee: address(recipientGood),
            data: abi.encodeCall(
                ISablierLockupRecipient.onSablierLockupWithdraw,
                (differentRecipientStreamId, users.sender, address(recipientGood), withdrawAmount)
            ),
            count: 1
        });

        // Make the withdrawal.
        lockup.withdraw({ streamId: differentRecipientStreamId, to: address(recipientGood), amount: withdrawAmount });
    }

    function test_WhenCallerRecipient() external givenRecipientNotSameAsSender {
        // Make the recipient contract the caller in this test.
        resetPrank({ msgSender: address(recipientGood) });

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // It should make Sablier run the recipient hook.
        vm.expectCall({
            callee: address(recipientGood),
            data: abi.encodeCall(
                ISablierLockupRecipient.onSablierLockupWithdraw,
                (differentRecipientStreamId, address(recipientGood), address(recipientGood), withdrawAmount)
            ),
            count: 0
        });

        // Make the withdrawal.
        lockup.withdraw({ streamId: differentRecipientStreamId, to: address(recipientGood), amount: withdrawAmount });
    }
}
