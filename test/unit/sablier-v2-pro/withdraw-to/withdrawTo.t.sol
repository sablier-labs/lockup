// solhint-disable max-line-length
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Pro } from "@sablier/v2-core/interfaces/ISablierV2Pro.sol";

import { SablierV2ProUnitTest } from "../SablierV2ProUnitTest.t.sol";

contract SablierV2Pro__WithdrawTo is SablierV2ProUnitTest {
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
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonExistent.selector, nonStreamId));
        uint256 withdrawAmount = 0;
        sablierV2Pro.withdrawTo(nonStreamId, toAlice, withdrawAmount);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev When the to address is zero, it should revert.
    function testCannotWithdrawTo__ToZeroAddress() external StreamExistent {
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__WithdrawZeroAddress.selector));
        address toZero = address(0);
        uint256 withdrawAmount = 0;
        sablierV2Pro.withdrawTo(daiStreamId, toZero, withdrawAmount);
    }

    modifier ToNonZeroAddress() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdrawTo__CallerSender() external StreamExistent ToNonZeroAddress {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.sender);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, daiStreamId, users.sender));
        uint256 withdrawAmount = 0;
        sablierV2Pro.withdrawTo(daiStreamId, toAlice, withdrawAmount);
    }

    /// @dev it should revert.
    function testCannotWithdrawTo__CallerThirdParty() external StreamExistent ToNonZeroAddress {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, daiStreamId, users.eve));
        uint256 withdrawAmount = 0;
        sablierV2Pro.withdrawTo(daiStreamId, toAlice, withdrawAmount);
    }

    modifier CallerRecipient() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdrawTo__WithdrawAmountZero() external StreamExistent ToNonZeroAddress CallerRecipient {
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__WithdrawAmountZero.selector, daiStreamId));
        uint256 withdrawAmount = 0;
        sablierV2Pro.withdrawTo(daiStreamId, toAlice, withdrawAmount);
    }

    modifier WithdrawAmountNotZero() {
        _;
    }

    /// @dev When the amount is greater than the withdrawable amount, it should revert.
    function testCannotWithdrawTo__WithdrawAmountGreaterThanWithdrawableAmount()
        external
        StreamExistent
        ToNonZeroAddress
        CallerRecipient
        WithdrawAmountNotZero
    {
        uint256 withdrawAmountMaxUint256 = UINT256_MAX;
        uint256 withdrawableAmount = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2.SablierV2__WithdrawAmountGreaterThanWithdrawableAmount.selector,
                daiStreamId,
                withdrawAmountMaxUint256,
                withdrawableAmount
            )
        );
        sablierV2Pro.withdrawTo(daiStreamId, toAlice, withdrawAmountMaxUint256);
    }

    modifier WithdrawAmountLessThanOrEqualToWithdrawableAmount() {
        _;
    }

    /// @dev When the to address is the recipient, it should make the withdrawal.
    function testWithdrawTo__ToRecipient()
        external
        StreamExistent
        ToNonZeroAddress
        CallerRecipient
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Pro.withdrawTo(daiStreamId, toAlice, SEGMENT_AMOUNTS_DAI[0]);
    }

    modifier ToThirdParty() {
        _;
    }

    /// @dev it should make the withdrawal and delete the stream.
    function testWithdrawTo__StreamEnded()
        external
        StreamExistent
        ToNonZeroAddress
        CallerRecipient
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
        ToThirdParty
    {
        // Warp to the end of the stream.
        vm.warp(daiStream.stopTime);

        // Run the test.
        uint256 withdrawAmount = daiStream.depositAmount;
        sablierV2Pro.withdrawTo(daiStreamId, toAlice, withdrawAmount);
        ISablierV2Pro.Stream memory deletedStream = sablierV2Pro.getStream(daiStreamId);
        ISablierV2Pro.Stream memory expectedStream;
        assertEq(deletedStream, expectedStream);
    }

    /// @dev it should emit a Withdraw event.
    function testWithdrawTo__StreamEnded__Event()
        external
        StreamExistent
        ToNonZeroAddress
        CallerRecipient
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
        ToThirdParty
    {
        // Warp to the end of the stream.
        vm.warp(daiStream.stopTime);

        // Run the test.
        vm.expectEmit(true, true, false, true);
        uint256 withdrawAmount = daiStream.depositAmount;
        emit Withdraw(daiStreamId, toAlice, withdrawAmount);
        sablierV2Pro.withdrawTo(daiStreamId, toAlice, withdrawAmount);
    }

    /// @dev it should make the withdrawal and update the withdrawn amount.
    function testWithdrawTo__StreamOngoing()
        external
        StreamExistent
        ToNonZeroAddress
        CallerRecipient
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
        ToThirdParty
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Pro.withdrawTo(daiStreamId, toAlice, SEGMENT_AMOUNTS_DAI[0]);
        ISablierV2Pro.Stream memory actualStream = sablierV2Pro.getStream(daiStreamId);
        uint256 actualWithdrawnAmount = actualStream.withdrawnAmount;
        uint256 expectedWithdrawnAmount = SEGMENT_AMOUNTS_DAI[0];
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    /// @dev it should emit a Withdraw event.
    function testWithdrawTo__StreamOngoing__Event()
        external
        StreamExistent
        ToNonZeroAddress
        CallerRecipient
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
        ToThirdParty
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        uint256 withdrawAmount = SEGMENT_AMOUNTS_DAI[0];
        vm.expectEmit(true, true, false, true);
        emit Withdraw(daiStreamId, toAlice, withdrawAmount);
        sablierV2Pro.withdrawTo(daiStreamId, toAlice, withdrawAmount);
    }
}
