// solhint-disable max-line-length
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { Errors } from "@sablier/v2-core/libraries/Errors.sol";
import { Events } from "@sablier/v2-core/libraries/Events.sol";
import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__WithdrawTo is SablierV2LinearUnitTest {
    uint256 internal daiStreamId;
    address internal toAlice;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        daiStreamId = createDefaultDaiStream();

        // Make the recipient the `msg.sender` in this test suite.
        changePrank(users.recipient);

        // Make Alice the address that will receive the tokens.
        toAlice = users.alice;
    }

    /// @dev it should revert.
    function testCannotWithdrawTo__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__StreamNonExistent.selector, nonStreamId));
        uint256 withdrawAmountZero = 0;
        sablierV2Linear.withdrawTo(nonStreamId, toAlice, withdrawAmountZero);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev When the to address is zero, it should revert.
    function testCannotWithdrawTo__ToZeroAddress() external StreamExistent {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__WithdrawZeroAddress.selector));
        address toZero = address(0);
        uint256 withdrawAmountZero = 0;
        sablierV2Linear.withdrawTo(daiStreamId, toZero, withdrawAmountZero);
    }

    modifier ToNonZeroAddress() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdrawTo__CallerSender() external StreamExistent ToNonZeroAddress {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.sender);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, daiStreamId, users.sender));
        uint256 withdrawAmountZero = 0;
        sablierV2Linear.withdrawTo(daiStreamId, toAlice, withdrawAmountZero);
    }

    /// @dev it should revert.
    function testCannotWithdrawTo__CallerThirdParty() external StreamExistent ToNonZeroAddress {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, daiStreamId, users.eve));
        uint256 withdrawAmountZero = 0;
        sablierV2Linear.withdrawTo(daiStreamId, toAlice, withdrawAmountZero);
    }

    modifier CallerAuthorized() {
        _;
    }

    /// @dev it should make the withdrawal.
    function testWithdrawTo__CallerApprovedThirdParty() external StreamExistent ToNonZeroAddress CallerAuthorized {
        // Approve Alice for the stream.
        sablierV2Linear.approve(users.alice, daiStreamId);

        // Make Alice the `msg.sender` in this test case.
        changePrank(users.alice);

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Linear.withdrawTo(daiStreamId, toAlice, WITHDRAW_AMOUNT_DAI);
        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(daiStreamId);
        uint256 actualWithdrawnAmount = actualStream.withdrawnAmount;
        uint256 expectedWithdrawnAmount = WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    modifier CallerRecipient() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdraw__RecipientNotOwner()
        external
        StreamExistent
        ToNonZeroAddress
        CallerAuthorized
        CallerRecipient
    {
        // Transfer the stream to eve.
        sablierV2Linear.safeTransferFrom(users.recipient, users.eve, daiStreamId);

        // Warp to the end of the stream.
        vm.warp(daiStream.stopTime);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, daiStreamId, users.recipient));
        sablierV2Linear.withdrawTo(daiStreamId, toAlice, daiStream.depositAmount);
    }

    modifier RecipientOwner() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdrawTo__WithdrawAmountZero()
        external
        StreamExistent
        ToNonZeroAddress
        CallerAuthorized
        CallerRecipient
        RecipientOwner
    {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__WithdrawAmountZero.selector, daiStreamId));
        uint256 withdrawAmountZero = 0;
        sablierV2Linear.withdrawTo(daiStreamId, toAlice, withdrawAmountZero);
    }

    modifier WithdrawAmountNotZero() {
        _;
    }

    /// @dev When the amount is greater than the withdrawable amount, it should revert.
    function testCannotWithdrawTo__WithdrawAmountGreaterThanWithdrawableAmount()
        external
        StreamExistent
        ToNonZeroAddress
        CallerAuthorized
        CallerRecipient
        RecipientOwner
        WithdrawAmountNotZero
    {
        uint256 withdrawAmountMaxUint256 = UINT256_MAX;
        uint256 withdrawableAmount = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2__WithdrawAmountGreaterThanWithdrawableAmount.selector,
                daiStreamId,
                withdrawAmountMaxUint256,
                withdrawableAmount
            )
        );
        sablierV2Linear.withdrawTo(daiStreamId, toAlice, withdrawAmountMaxUint256);
    }

    modifier WithdrawAmountLessThanOrEqualToWithdrawableAmount() {
        _;
    }

    /// @dev When the to address is the recipient, it should make the withdrawal.
    function testWithdrawTo__ToRecipient()
        external
        StreamExistent
        ToNonZeroAddress
        CallerAuthorized
        CallerRecipient
        RecipientOwner
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Linear.withdrawTo(daiStreamId, users.recipient, WITHDRAW_AMOUNT_DAI);
        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(daiStreamId);
        uint256 actualWithdrawnAmount = actualStream.withdrawnAmount;
        uint256 expectedWithdrawnAmount = WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    modifier ToThirdParty() {
        _;
    }

    /// @dev it should make the withdrawal and delete the stream.
    function testWithdrawTo__StreamEnded()
        external
        StreamExistent
        ToNonZeroAddress
        CallerAuthorized
        CallerRecipient
        RecipientOwner
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
        ToThirdParty
    {
        // Warp to the end of the stream.
        vm.warp(daiStream.stopTime);

        // Run the test.
        sablierV2Linear.withdrawTo(daiStreamId, toAlice, daiStream.depositAmount);
        ISablierV2Linear.Stream memory deletedStream = sablierV2Linear.getStream(daiStreamId);
        ISablierV2Linear.Stream memory expectedStream;
        assertEq(deletedStream, expectedStream);
    }

    /// @dev it should emit a Withdraw event.
    function testWithdrawTo__StreamEnded__Event()
        external
        StreamExistent
        ToNonZeroAddress
        CallerAuthorized
        CallerRecipient
        RecipientOwner
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
        ToThirdParty
    {
        // Warp to the end of the stream.
        vm.warp(daiStream.stopTime);

        // Run the test.
        vm.expectEmit(true, true, false, true);
        emit Events.Withdraw(daiStreamId, toAlice, daiStream.depositAmount);
        sablierV2Linear.withdrawTo(daiStreamId, toAlice, daiStream.depositAmount);
    }

    /// @dev it should make the withdrawal and update the withdrawn amount.
    function testWithdrawTo__StreamOngoing()
        external
        StreamExistent
        ToNonZeroAddress
        CallerAuthorized
        CallerRecipient
        RecipientOwner
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
        ToThirdParty
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Linear.withdrawTo(daiStreamId, toAlice, WITHDRAW_AMOUNT_DAI);
        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(daiStreamId);
        uint256 actualWithdrawnAmount = actualStream.withdrawnAmount;
        uint256 expectedWithdrawnAmount = WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    /// @dev it should emit a Withdraw event.
    function testWithdrawTo__StreamOngoing__Event()
        external
        StreamExistent
        ToNonZeroAddress
        CallerAuthorized
        CallerRecipient
        RecipientOwner
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
        ToThirdParty
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        vm.expectEmit(true, true, false, true);
        emit Events.Withdraw(daiStreamId, toAlice, WITHDRAW_AMOUNT_DAI);
        sablierV2Linear.withdrawTo(daiStreamId, toAlice, WITHDRAW_AMOUNT_DAI);
    }
}
