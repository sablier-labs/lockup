// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { DataTypes } from "src/libraries/DataTypes.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { SablierV2LinearTest } from "../SablierV2LinearTest.t.sol";

contract WithdrawAll__Test is SablierV2LinearTest {
    uint128[] internal defaultAmounts;
    uint256[] internal defaultStreamIds;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Define the default amounts, since most tests need them.
        defaultAmounts.push(WITHDRAW_AMOUNT_DAI);
        defaultAmounts.push(WITHDRAW_AMOUNT_DAI);

        // Create the default streams, since most tests need them.
        defaultStreamIds.push(createDefaultDaiStream());
        defaultStreamIds.push(createDefaultDaiStream());

        // Make the recipient the caller in this test suite.
        changePrank(users.recipient);
    }

    /// @dev it should revert.
    function testCannotWithdrawAll__ArraysNotEqual() external {
        uint256[] memory streamIds = new uint256[](2);
        uint128[] memory amounts = new uint128[](1);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2__WithdrawAllArraysNotEqual.selector,
                streamIds.length,
                amounts.length
            )
        );
        sablierV2Linear.withdrawAll(streamIds, users.recipient, amounts);
    }

    modifier ArraysEqual() {
        _;
    }

    /// @dev it should do nothing.
    function testCannotWithdrawAll__OnlyNonExistentStreams() external ArraysEqual {
        uint256 nonStreamId = 1729;
        uint256[] memory nonStreamIds = createDynamicArray(nonStreamId);
        uint128[] memory amounts = createDynamicUint128Array(WITHDRAW_AMOUNT_DAI);
        sablierV2Linear.withdrawAll(nonStreamIds, users.recipient, amounts);
    }

    /// @dev it should make the withdrawals for the existent streams.
    function testCannotWithdrawAll__SomeNonExistentStreams() external ArraysEqual {
        uint256 nonStreamId = 1729;
        uint256[] memory streamIds = createDynamicArray(nonStreamId, defaultStreamIds[0]);

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: daiStream.startTime + TIME_OFFSET });

        // Run the test.
        sablierV2Linear.withdrawAll(streamIds, users.recipient, defaultAmounts);
        uint128 actualWithdrawnAmount = sablierV2Linear.getWithdrawnAmount(defaultStreamIds[0]);
        uint128 expectedWithdrawnAmount = WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    modifier OnlyExistentStreams() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdrawAll__CallerUnauthorizedAllStreams__MaliciousThirdParty()
        external
        ArraysEqual
        OnlyExistentStreams
    {
        // Make Eve the caller in this test.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.eve)
        );
        sablierV2Linear.withdrawAll(defaultStreamIds, users.recipient, defaultAmounts);
    }

    /// @dev it should revert.
    function testCannotWithdrawAll__CallerUnauthorizedAllStreams__Sender() external ArraysEqual OnlyExistentStreams {
        // Make the sender the caller in this test.
        changePrank(users.sender);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.sender)
        );
        sablierV2Linear.withdrawAll(defaultStreamIds, users.sender, defaultAmounts);
    }

    /// @dev it should revert.
    function testCannotWithdrawAll__CallerUnauthorizedSomeStreams() external ArraysEqual OnlyExistentStreams {
        // Make Eve the caller in this test.
        changePrank(users.eve);

        // Create a stream with Eve as the recipient.
        uint256 eveStreamId = sablierV2Linear.create(
            users.sender,
            users.eve,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.cliffTime,
            daiStream.stopTime,
            daiStream.cancelable
        );

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: daiStream.startTime + TIME_OFFSET });

        // Run the test.
        uint256[] memory streamIds = createDynamicArray(eveStreamId, defaultStreamIds[0]);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.eve)
        );
        sablierV2Linear.withdrawAll(streamIds, users.recipient, defaultAmounts);
    }

    modifier CallerAuthorizedAllStreams() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdrawAll__ToZeroAddress()
        external
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        CallerRecipientAllStreams
        OriginalRecipientAllStreams
        AllAmountsNotZero
        AllAmountsLessThanOrEqualToWithdrawableAmounts
    {
        vm.expectRevert(Errors.SablierV2__WithdrawToZeroAddress.selector);
        sablierV2Linear.withdrawAll(defaultStreamIds, address(0), defaultAmounts);
    }

    modifier ToNonZeroAddress() {
        _;
    }

    /// @dev it should make the withdrawals to the provided address and update the withdrawn amounts.
    function testWithdrawAll__CallerApprovedOperatorAllStreams()
        external
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        ToNonZeroAddress
    {
        // Approve the operator for all streams.
        sablierV2Linear.setApprovalForAll(users.operator, true);

        // Make the operator the caller in this test.
        changePrank(users.operator);

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: daiStream.startTime + TIME_OFFSET });

        // Run the test.
        sablierV2Linear.withdrawAll(defaultStreamIds, users.recipient, defaultAmounts);
        uint128 actualWithdrawnAmount0 = sablierV2Linear.getWithdrawnAmount(defaultStreamIds[0]);
        uint128 actualWithdrawnAmount1 = sablierV2Linear.getWithdrawnAmount(defaultStreamIds[1]);
        uint128 expectedWithdrawnAmount0 = WITHDRAW_AMOUNT_DAI;
        uint128 expectedWithdrawnAmount1 = WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawnAmount0, expectedWithdrawnAmount0);
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount1);
    }

    modifier CallerRecipientAllStreams() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdrawAllTo__OriginalRecipientTransferredOwnershipAllStreams()
        external
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        ToNonZeroAddress
        CallerRecipientAllStreams
    {
        // Transfer the streams to Alice.
        sablierV2Linear.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[0] });
        sablierV2Linear.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[1] });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.recipient)
        );
        sablierV2Linear.withdrawAll(defaultStreamIds, users.recipient, defaultAmounts);
    }

    /// @dev it should revert.
    function testCannotWithdrawAll__OriginalRecipientTransferredOwnershipSomeStreams()
        external
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        ToNonZeroAddress
        CallerRecipientAllStreams
    {
        // Transfer one of the streams to eve.
        sablierV2Linear.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[0] });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.recipient)
        );
        sablierV2Linear.withdrawAll(defaultStreamIds, users.recipient, defaultAmounts);
    }

    modifier OriginalRecipientAllStreams() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdrawAll__SomeAmountsZero()
        external
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        ToNonZeroAddress
        CallerRecipientAllStreams
        OriginalRecipientAllStreams
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: daiStream.startTime + TIME_OFFSET });

        // Run the test.
        uint128[] memory amounts = createDynamicUint128Array(WITHDRAW_AMOUNT_DAI, 0);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__WithdrawAmountZero.selector, defaultStreamIds[1]));
        sablierV2Linear.withdrawAll(defaultStreamIds, users.recipient, amounts);
    }

    modifier AllAmountsNotZero() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdrawAll__SomeAmountsGreaterThanWithdrawableAmount()
        external
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        ToNonZeroAddress
        CallerRecipientAllStreams
        OriginalRecipientAllStreams
        AllAmountsNotZero
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: daiStream.startTime + TIME_OFFSET });

        // Run the test.
        uint128 withdrawableAmount = WITHDRAW_AMOUNT_DAI;
        uint128[] memory amounts = createDynamicUint128Array(withdrawableAmount, UINT128_MAX);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2__WithdrawAmountGreaterThanWithdrawableAmount.selector,
                defaultStreamIds[1],
                UINT128_MAX,
                withdrawableAmount
            )
        );
        sablierV2Linear.withdrawAll(defaultStreamIds, users.recipient, amounts);
    }

    modifier AllAmountsLessThanOrEqualToWithdrawableAmounts() {
        _;
    }

    /// @dev it should make the withdrawals to the recipient's and update the withdrawn amounts.
    function testWithdrawAll__ToRecipient()
        external
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        ToNonZeroAddress
        CallerRecipientAllStreams
        OriginalRecipientAllStreams
        AllAmountsNotZero
        AllAmountsLessThanOrEqualToWithdrawableAmounts
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: daiStream.startTime + TIME_OFFSET });

        // Run the test.
        sablierV2Linear.withdrawAll(defaultStreamIds, users.recipient, defaultAmounts);
        uint128 actualWithdrawnAmount0 = sablierV2Linear.getWithdrawnAmount(defaultStreamIds[0]);
        uint128 actualWithdrawnAmount1 = sablierV2Linear.getWithdrawnAmount(defaultStreamIds[1]);
        uint128 expectedWithdrawnAmount0 = WITHDRAW_AMOUNT_DAI;
        uint128 expectedWithdrawnAmount1 = WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawnAmount0, expectedWithdrawnAmount0);
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount1);
    }

    modifier ToThirdParty() {
        _;
    }

    /// @dev it should make the withdrawals to the provided address, delete the streams.
    function testWithdrawAll__AllStreamsEnded()
        external
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        ToNonZeroAddress
        CallerRecipientAllStreams
        OriginalRecipientAllStreams
        AllAmountsNotZero
        AllAmountsLessThanOrEqualToWithdrawableAmounts
        ToThirdParty
    {
        // Warp to the end of the stream.
        vm.warp({ timestamp: daiStream.stopTime });

        // Run the test.
        uint128[] memory amounts = createDynamicUint128Array(daiStream.depositAmount, daiStream.depositAmount);
        sablierV2Linear.withdrawAll(defaultStreamIds, users.alice, amounts);

        DataTypes.LinearStream memory actualStream0 = sablierV2Linear.getStream(defaultStreamIds[0]);
        DataTypes.LinearStream memory actualStream1 = sablierV2Linear.getStream(defaultStreamIds[1]);
        DataTypes.LinearStream memory expectedStream;
        assertEq(actualStream0, expectedStream);
        assertEq(actualStream1, expectedStream);

        address actualRecipient0 = sablierV2Linear.getRecipient(defaultStreamIds[0]);
        address actualRecipient1 = sablierV2Linear.getRecipient(defaultStreamIds[1]);
        address expectedRecipient = users.recipient;
        assertEq(actualRecipient0, expectedRecipient);
        assertEq(actualRecipient1, expectedRecipient);
    }

    /// @dev it should emit multiple Withdraw events.
    function testWithdrawAll__AllStreamsEnded__Events()
        external
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        ToNonZeroAddress
        CallerRecipientAllStreams
        OriginalRecipientAllStreams
        AllAmountsNotZero
        AllAmountsLessThanOrEqualToWithdrawableAmounts
        ToThirdParty
    {
        // Warp to the end of the stream.
        vm.warp({ timestamp: daiStream.stopTime });

        // Run the test.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({ streamId: defaultStreamIds[0], to: users.alice, amount: daiStream.depositAmount });
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({ streamId: defaultStreamIds[1], to: users.alice, amount: daiStream.depositAmount });
        uint128[] memory amounts = createDynamicUint128Array(daiStream.depositAmount, daiStream.depositAmount);
        sablierV2Linear.withdrawAll(defaultStreamIds, users.alice, amounts);
    }

    /// @dev it should make the withdrawals to the provided address and update the withdrawn amounts.
    function testWithdrawAll__AllStreamsOngoing()
        external
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        ToNonZeroAddress
        CallerRecipientAllStreams
        OriginalRecipientAllStreams
        AllAmountsNotZero
        AllAmountsLessThanOrEqualToWithdrawableAmounts
        ToThirdParty
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: daiStream.startTime + TIME_OFFSET });

        // Run the test.
        sablierV2Linear.withdrawAll(defaultStreamIds, users.alice, defaultAmounts);
        uint128 actualWithdrawnAmount0 = sablierV2Linear.getWithdrawnAmount(defaultStreamIds[0]);
        uint128 actualWithdrawnAmount1 = sablierV2Linear.getWithdrawnAmount(defaultStreamIds[1]);
        uint128 expectedWithdrawnAmount0 = WITHDRAW_AMOUNT_DAI;
        uint128 expectedWithdrawnAmount1 = WITHDRAW_AMOUNT_DAI;

        assertEq(actualWithdrawnAmount0, expectedWithdrawnAmount0);
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount1);
    }

    /// @dev it should emit multiple Withdraw events.
    function testWithdrawAll__AllStreamsOngoing__Events()
        external
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        ToNonZeroAddress
        CallerRecipientAllStreams
        OriginalRecipientAllStreams
        AllAmountsNotZero
        AllAmountsLessThanOrEqualToWithdrawableAmounts
        ToThirdParty
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: daiStream.startTime + TIME_OFFSET });

        // Run the test.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({ streamId: defaultStreamIds[0], to: users.alice, amount: WITHDRAW_AMOUNT_DAI });
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({ streamId: defaultStreamIds[1], to: users.alice, amount: WITHDRAW_AMOUNT_DAI });
        sablierV2Linear.withdrawAll(defaultStreamIds, users.alice, defaultAmounts);
    }

    /// @dev it should make the withdrawals to the provided address, delete the ended streams,
    /// and update the withdrawn amounts.
    function testWithdrawAll__SomeStreamsEndedSomeStreamsOngoing()
        external
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        ToNonZeroAddress
        CallerRecipientAllStreams
        OriginalRecipientAllStreams
        AllAmountsNotZero
        AllAmountsLessThanOrEqualToWithdrawableAmounts
        ToThirdParty
    {
        // Create the ended dai stream.
        changePrank(daiStream.sender);
        uint40 earlyStopTime = daiStream.startTime + TIME_OFFSET;
        uint256 endedDaiStreamId = sablierV2Linear.create(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.cliffTime,
            earlyStopTime,
            daiStream.cancelable
        );
        changePrank(users.recipient);

        // Use the first default stream as the ongoing DAI stream.
        uint256 ongoingStreamId = defaultStreamIds[0];

        // Warp to the end of the early DAI stream.
        vm.warp({ timestamp: earlyStopTime });

        // Run the test.
        uint128 endedWithdrawAmount = daiStream.depositAmount;
        uint128 ongoingWithdrawAmount = WITHDRAW_AMOUNT_DAI;
        uint256[] memory streamIds = createDynamicArray(endedDaiStreamId, ongoingStreamId);
        uint128[] memory amounts = createDynamicUint128Array(endedWithdrawAmount, ongoingWithdrawAmount);
        sablierV2Linear.withdrawAll(streamIds, users.alice, amounts);

        DataTypes.LinearStream memory actualEndedStream = sablierV2Linear.getStream(endedDaiStreamId);
        DataTypes.LinearStream memory expectedEndedStream;
        assertEq(actualEndedStream, expectedEndedStream);

        address actualEndedRecipient = sablierV2Linear.getRecipient(endedDaiStreamId);
        address expectedEndedRecipient = users.recipient;
        assertEq(actualEndedRecipient, expectedEndedRecipient);

        uint128 actualWithdrawnAmount = sablierV2Linear.getWithdrawnAmount(ongoingStreamId);
        uint128 expectedWithdrawnAmount = WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    /// @dev it should emit multiple Withdraw events.
    function testWithdrawAll__SomeStreamsEndedSomeStreamsOngoing__Events()
        external
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        ToNonZeroAddress
        CallerRecipientAllStreams
        OriginalRecipientAllStreams
        AllAmountsNotZero
        AllAmountsLessThanOrEqualToWithdrawableAmounts
        ToThirdParty
    {
        // Create the ended dai stream.
        changePrank(daiStream.sender);
        uint40 earlyStopTime = daiStream.startTime + TIME_OFFSET;
        uint256 endedDaiStreamId = sablierV2Linear.create(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.cliffTime,
            earlyStopTime,
            daiStream.cancelable
        );
        changePrank(users.recipient);

        // Use the first default stream as the ongoing DAI stream.
        uint256 ongoingStreamId = defaultStreamIds[0];

        // Warp to the end of the early DAI stream.
        vm.warp({ timestamp: earlyStopTime });

        // Run the test.
        uint128 endedWithdrawAmount = daiStream.depositAmount;
        uint128 ongoingWithdrawAmount = WITHDRAW_AMOUNT_DAI;

        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({ streamId: endedDaiStreamId, to: users.alice, amount: endedWithdrawAmount });
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({ streamId: ongoingStreamId, to: users.alice, amount: ongoingWithdrawAmount });

        uint256[] memory streamIds = createDynamicArray(endedDaiStreamId, ongoingStreamId);
        uint128[] memory amounts = createDynamicUint128Array(endedWithdrawAmount, ongoingWithdrawAmount);
        sablierV2Linear.withdrawAll(streamIds, users.alice, amounts);
    }
}
