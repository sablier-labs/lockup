// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { Solarray } from "solarray/Solarray.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { SharedTest } from "../SharedTest.t.sol";

abstract contract WithdrawMultiple__Test is SharedTest {
    uint128[] internal defaultAmounts;
    uint256[] internal defaultStreamIds;

    function setUp() public virtual override {
        super.setUp();

        // Define the default amounts, since most tests need them.
        defaultAmounts.push(DEFAULT_WITHDRAW_AMOUNT);
        defaultAmounts.push(DEFAULT_WITHDRAW_AMOUNT);

        // Create the default streams, since most tests need them.
        defaultStreamIds.push(createDefaultStream());
        defaultStreamIds.push(createDefaultStream());

        // Make the recipient the caller in this test suite.
        changePrank(users.recipient);
    }

    /// @dev it should revert.
    function testCannotWithdrawMultiple__ToZeroAddress() external {
        vm.expectRevert(Errors.SablierV2__WithdrawToZeroAddress.selector);
        sablierV2.withdrawMultiple({ streamIds: defaultStreamIds, to: address(0), amounts: defaultAmounts });
    }

    modifier ToNonZeroAddress() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdrawMultiple__ArraysNotEqual() external ToNonZeroAddress {
        uint256[] memory streamIds = new uint256[](2);
        uint128[] memory amounts = new uint128[](1);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__WithdrawArraysNotEqual.selector, streamIds.length, amounts.length)
        );
        sablierV2.withdrawMultiple({ streamIds: streamIds, to: users.recipient, amounts: amounts });
    }

    modifier ArraysEqual() {
        _;
    }

    /// @dev it should do nothing.
    function testCannotWithdrawMultiple__OnlyNonExistentStreams() external ToNonZeroAddress ArraysEqual {
        uint256 nonStreamId = 1729;
        uint256[] memory nonStreamIds = Solarray.uint256s(nonStreamId);
        uint128[] memory amounts = Solarray.uint128s(DEFAULT_WITHDRAW_AMOUNT);
        sablierV2.withdrawMultiple({ streamIds: nonStreamIds, to: users.recipient, amounts: amounts });
    }

    /// @dev it should ignore the non-existent streams and make the withdrawals for the existent streams.
    function testCannotWithdrawMultiple__SomeNonExistentStreams() external ToNonZeroAddress ArraysEqual {
        uint256 nonStreamId = 1729;
        uint256[] memory streamIds = Solarray.uint256s(nonStreamId, defaultStreamIds[0]);

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Run the test.
        sablierV2.withdrawMultiple({ streamIds: streamIds, to: users.recipient, amounts: defaultAmounts });
        uint128 actualWithdrawnAmount = sablierV2.getWithdrawnAmount(defaultStreamIds[0]);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    modifier OnlyExistentStreams() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdrawMultiple__CallerUnauthorizedAllStreams__MaliciousThirdParty(
        address eve
    ) external ToNonZeroAddress ArraysEqual OnlyExistentStreams {
        vm.assume(eve != address(0) && eve != users.sender && eve != users.recipient);

        // Make Eve the caller in this test.
        changePrank(eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], eve));
        sablierV2.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: defaultAmounts });
    }

    /// @dev it should revert.
    function testCannotWithdrawMultiple__CallerUnauthorizedAllStreams__Sender()
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
    {
        // Make the sender the caller in this test.
        changePrank(users.sender);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.sender)
        );
        sablierV2.withdrawMultiple({ streamIds: defaultStreamIds, to: users.sender, amounts: defaultAmounts });
    }

    /// @dev it should revert.
    function testCannotWithdrawMultiple__CallerUnauthorizedAllStreams__FormerRecipient()
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
    {
        // Transfer all streams to Alice.
        sablierV2.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[0] });
        sablierV2.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[1] });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.recipient)
        );
        sablierV2.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: defaultAmounts });
    }

    /// @dev it should revert.
    function testCannotWithdrawMultiple__CallerUnauthorizedSomeStreams__MaliciousThirdParty(
        address eve
    ) external ToNonZeroAddress ArraysEqual OnlyExistentStreams {
        vm.assume(eve != address(0) && eve != users.sender && eve != users.recipient);

        // Create a stream with Eve as the recipient.
        uint256 eveStreamId = createDefaultStreamWithRecipient(eve);

        // Make Eve the caller in this test.
        changePrank(eve);

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Run the test.
        uint256[] memory streamIds = Solarray.uint256s(eveStreamId, defaultStreamIds[0]);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], eve));
        sablierV2.withdrawMultiple({ streamIds: streamIds, to: users.recipient, amounts: defaultAmounts });
    }

    /// @dev it should revert.
    function testCannotWithdrawMultiple__CallerUnauthorizedSomeStreams__FormerRecipient()
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
    {
        // Transfer one of the streams to Eve.
        sablierV2.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[0] });

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.recipient)
        );
        sablierV2.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: defaultAmounts });
    }

    modifier CallerAuthorizedAllStreams() {
        _;
    }

    /// @dev it should make the withdrawals and update the withdrawn amounts.
    function testWithdrawMultiple__CallerApprovedOperator(
        address to
    ) external ToNonZeroAddress ArraysEqual OnlyExistentStreams CallerAuthorizedAllStreams {
        vm.assume(to != address(0));

        // Approve the operator for all streams.
        sablierV2.setApprovalForAll(users.operator, true);

        // Make the operator the caller in this test.
        changePrank(users.operator);

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Expect the withdrawals to be made.
        uint128 withdrawAmount = DEFAULT_WITHDRAW_AMOUNT;
        vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (to, withdrawAmount)));
        vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (to, withdrawAmount)));

        // Make the withdrawals.
        sablierV2.withdrawMultiple({ streamIds: defaultStreamIds, to: to, amounts: defaultAmounts });

        // Assert that the withdrawn amounts were updated.
        uint128 actualWithdrawnAmount0 = sablierV2.getWithdrawnAmount(defaultStreamIds[0]);
        uint128 actualWithdrawnAmount1 = sablierV2.getWithdrawnAmount(defaultStreamIds[1]);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount0, expectedWithdrawnAmount);
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount);
    }

    modifier CallerRecipient() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdrawMultiple__SomeAmountsZero()
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        CallerRecipient
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Run the test.
        uint128[] memory amounts = Solarray.uint128s(DEFAULT_WITHDRAW_AMOUNT, 0);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__WithdrawAmountZero.selector, defaultStreamIds[1]));
        sablierV2.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: amounts });
    }

    modifier AllAmountsNotZero() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdrawMultiple__SomeAmountsGreaterThanWithdrawableAmount()
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        CallerRecipient
        AllAmountsNotZero
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Run the test.
        uint128 withdrawableAmount = sablierV2.getWithdrawableAmount(defaultStreamIds[1]);
        uint128[] memory amounts = Solarray.uint128s(withdrawableAmount, UINT128_MAX);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2__WithdrawAmountGreaterThanWithdrawableAmount.selector,
                defaultStreamIds[1],
                UINT128_MAX,
                withdrawableAmount
            )
        );
        sablierV2.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: amounts });
    }

    modifier AllAmountsLessThanOrEqualToWithdrawableAmounts() {
        _;
    }

    /// @dev it should make the withdrawals, emit multiple Withdraw events, and delete the streams.
    function testWithdrawMultiple__AllStreamsEnded(
        uint256 timeWarp,
        address to
    )
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        CallerRecipient
        AllAmountsNotZero
        AllAmountsLessThanOrEqualToWithdrawableAmounts
    {
        timeWarp = bound(timeWarp, 0 seconds, DEFAULT_TOTAL_DURATION);
        vm.assume(to != address(0));

        // Warp into the future, past the stop time.
        vm.warp({ timestamp: DEFAULT_STOP_TIME + timeWarp });

        // Expect Withdraw events to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({ streamId: defaultStreamIds[0], to: to, amount: DEFAULT_NET_DEPOSIT_AMOUNT });
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({ streamId: defaultStreamIds[1], to: to, amount: DEFAULT_NET_DEPOSIT_AMOUNT });

        // Expect the withdrawals to be made.
        vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (to, DEFAULT_NET_DEPOSIT_AMOUNT)));
        vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (to, DEFAULT_NET_DEPOSIT_AMOUNT)));

        // Make the withdrawals.
        uint128[] memory amounts = Solarray.uint128s(DEFAULT_NET_DEPOSIT_AMOUNT, DEFAULT_NET_DEPOSIT_AMOUNT);
        sablierV2.withdrawMultiple({ streamIds: defaultStreamIds, to: to, amounts: amounts });

        // Assert that the streams were deleted.
        assertDeleted(Solarray.uint256s(defaultStreamIds[0], defaultStreamIds[1]));

        // Assert that the NFTs weren't burned.
        address actualNFTOwner0 = sablierV2.ownerOf(defaultStreamIds[0]);
        address actualNFTOwner1 = sablierV2.ownerOf(defaultStreamIds[1]);
        address actualNFTOwner = users.recipient;
        assertEq(actualNFTOwner0, actualNFTOwner);
        assertEq(actualNFTOwner1, actualNFTOwner);
    }

    /// @dev it should make the withdrawals, emit multiple Withdraw events, and update the withdrawn amounts.
    function testWithdrawMultiple__AllStreamsOngoing(
        uint256 timeWarp,
        address to,
        uint128 withdrawAmount
    )
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        CallerRecipient
        AllAmountsNotZero
        AllAmountsLessThanOrEqualToWithdrawableAmounts
    {
        timeWarp = bound(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION - 1);
        vm.assume(to != address(0));

        // Warp into the future, before the stop time of the stream.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Bound the withdraw amount.
        uint128 withdrawableAmount = sablierV2.getWithdrawableAmount(defaultStreamIds[0]);
        withdrawAmount = boundUint128(withdrawAmount, 1, withdrawableAmount);

        // Expect the withdrawals to be made.
        vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (to, withdrawAmount)));
        vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (to, withdrawAmount)));

        // Expect Withdraw events to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({ streamId: defaultStreamIds[0], to: to, amount: withdrawAmount });
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({ streamId: defaultStreamIds[1], to: to, amount: withdrawAmount });

        // Make the withdrawals.
        uint128[] memory amounts = Solarray.uint128s(withdrawAmount, withdrawAmount);
        sablierV2.withdrawMultiple({ streamIds: defaultStreamIds, to: to, amounts: amounts });

        // Assert that the withdrawn amounts were updated.
        uint128 actualWithdrawnAmount0 = sablierV2.getWithdrawnAmount(defaultStreamIds[0]);
        uint128 actualWithdrawnAmount1 = sablierV2.getWithdrawnAmount(defaultStreamIds[1]);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount0, expectedWithdrawnAmount);
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount);
    }

    /// @dev it should make the withdrawals, emit multiple Withdraw events, delete the ended streams, and update
    /// the withdrawn amounts.
    function testWithdrawMultiple__SomeStreamsEndedSomeStreamsOngoing(
        uint256 timeWarp,
        address to,
        uint128 ongoingWithdrawAmount
    )
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        CallerRecipient
        AllAmountsNotZero
        AllAmountsLessThanOrEqualToWithdrawableAmounts
    {
        timeWarp = bound(timeWarp, DEFAULT_TOTAL_DURATION, DEFAULT_TOTAL_DURATION * 2 - 1);
        vm.assume(to != address(0));

        // Use the first default stream as the ended stream.
        uint256 endedStreamId = defaultStreamIds[0];
        uint128 endedWithdrawAmount = DEFAULT_NET_DEPOSIT_AMOUNT;

        // Create a new stream with a stop time nearly double that of the default stream.
        uint40 ongoingStopTime = DEFAULT_STOP_TIME + DEFAULT_TOTAL_DURATION;
        uint256 ongoingStreamId = createDefaultStreamWithStopTime(ongoingStopTime);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Bound the ongoing withdraw amount.
        uint128 ongoingWithdrawableAmount = sablierV2.getWithdrawableAmount(ongoingStreamId);
        ongoingWithdrawAmount = boundUint128(ongoingWithdrawAmount, 1, ongoingWithdrawableAmount);

        // Expect Withdraw events to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({ streamId: endedStreamId, to: to, amount: endedWithdrawAmount });
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({ streamId: ongoingStreamId, to: to, amount: ongoingWithdrawAmount });

        // Run the test.
        uint256[] memory streamIds = Solarray.uint256s(endedStreamId, ongoingStreamId);
        uint128[] memory amounts = Solarray.uint128s(endedWithdrawAmount, ongoingWithdrawAmount);
        sablierV2.withdrawMultiple({ streamIds: streamIds, to: to, amounts: amounts });

        // Assert that the ended stream was deleted.
        assertDeleted(endedStreamId);

        // Assert that the ended stream NFT was not burned.
        address actualEndedNFTOwner = sablierV2.getRecipient(endedStreamId);
        address expectedEndedNFTOwner = users.recipient;
        assertEq(actualEndedNFTOwner, expectedEndedNFTOwner);

        // Assert that the withdrawn amount was updated for the ongoing stream.
        uint128 actualWithdrawnAmount = sablierV2.getWithdrawnAmount(ongoingStreamId);
        uint128 expectedWithdrawnAmount = ongoingWithdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }
}
