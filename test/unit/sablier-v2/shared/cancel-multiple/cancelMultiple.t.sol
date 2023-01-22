// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { console2 } from "forge-std/console2.sol";
import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { Solarray } from "solarray/Solarray.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";
import { Status } from "src/types/Enums.sol";

import { SharedTest } from "../SharedTest.t.sol";

abstract contract CancelMultiple_Test is SharedTest {
    uint256[] internal defaultStreamIds;

    function setUp() public virtual override {
        super.setUp();

        // Create the default streams, since most tests need them.
        defaultStreamIds.push(createDefaultStream());
        defaultStreamIds.push(createDefaultStream());

        // Make the recipient the caller in this test suite.
        changePrank(users.recipient);
    }

    /// @dev it should do nothing.
    function test_RevertWhen_OnlyNullStreams() external {
        uint256 nullStreamId = 1729;
        uint256[] memory streamIds = Solarray.uint256s(nullStreamId);
        sablierV2.cancelMultiple(streamIds);
    }

    /// @dev it should ignore the null streams and cancel the non-null ones.
    function test_RevertWhen_SomeNullStreams() external {
        uint256 nullStreamId = 1729;
        uint256[] memory streamIds = Solarray.uint256s(defaultStreamIds[0], nullStreamId);
        sablierV2.cancelMultiple(streamIds);
        Status actualStatus = sablierV2.getStatus(defaultStreamIds[0]);
        Status expectedStatus = Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    modifier onlyNonNullStreams() {
        _;
    }

    /// @dev it should do nothing.
    function test_RevertWhen_AllStreamsNonCancelable() external onlyNonNullStreams {
        // Create the non-cancelable stream.
        uint256 streamId = createDefaultStreamNonCancelable();

        // Run the test.
        uint256[] memory nonCancelableStreamIds = Solarray.uint256s(streamId);
        sablierV2.cancelMultiple(nonCancelableStreamIds);
    }

    /// @dev it should ignore the non-cancelable streams and cancel the cancelable streams.
    function test_RevertWhen_SomeStreamsNonCancelable() external onlyNonNullStreams {
        // Create the non-cancelable stream.
        uint256 streamId = createDefaultStreamNonCancelable();

        // Run the test.
        uint256[] memory streamIds = Solarray.uint256s(defaultStreamIds[0], streamId);
        sablierV2.cancelMultiple(streamIds);

        // Assert that the cancelable stream was canceled.
        Status actualStatus = sablierV2.getStatus(defaultStreamIds[0]);
        Status expectedStatus = Status.CANCELED;
        assertEq(actualStatus, expectedStatus);

        // Assert that the non-cancelable stream was not canceled.
        Status status = sablierV2.getStatus(defaultStreamIds[1]);
        assertEq(status, Status.ACTIVE);
    }

    modifier allStreamsCancelable() {
        _;
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_CallerUnauthorizedAllStreams_MaliciousThirdParty(
        address eve
    ) external onlyNonNullStreams allStreamsCancelable {
        vm.assume(eve != address(0) && eve != users.sender && eve != users.recipient);

        // Make Eve the caller in this test.
        changePrank(eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2_Unauthorized.selector, defaultStreamIds[0], eve));
        sablierV2.cancelMultiple(defaultStreamIds);
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_CallerUnauthorizedAllStreams_ApprovedOperator(
        address operator
    ) external onlyNonNullStreams allStreamsCancelable {
        vm.assume(operator != address(0) && operator != users.sender && operator != users.recipient);

        // Approve the operator for all streams.
        sablierV2.setApprovalForAll({ operator: operator, _approved: true });

        // Make the approved operator the caller in this test.
        changePrank(users.operator);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2_Unauthorized.selector, defaultStreamIds[0], users.operator)
        );
        sablierV2.cancelMultiple(defaultStreamIds);
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorizedAllStreams_FormerRecipient()
        external
        onlyNonNullStreams
        allStreamsCancelable
    {
        // Transfer the streams to Alice.
        sablierV2.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[0] });
        sablierV2.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[1] });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2_Unauthorized.selector, defaultStreamIds[0], users.recipient)
        );
        sablierV2.cancelMultiple(defaultStreamIds);
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_CallerUnauthorizedSomeStreams_MaliciousThirdParty(
        address eve
    ) external onlyNonNullStreams allStreamsCancelable {
        vm.assume(eve != address(0) && eve != users.sender && eve != users.recipient);

        // Make Eve the caller in this test.
        changePrank(users.eve);

        // Create a stream with Eve as the sender.
        uint256 eveStreamId = createDefaultStreamWithSender(users.eve);

        // Run the test.
        uint256[] memory streamIds = Solarray.uint256s(eveStreamId, defaultStreamIds[0]);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2_Unauthorized.selector, defaultStreamIds[0], users.eve));
        sablierV2.cancelMultiple(streamIds);
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_CallerUnauthorizedSomeStreams_ApprovedOperator(
        address operator
    ) external onlyNonNullStreams allStreamsCancelable {
        vm.assume(operator != address(0) && operator != users.sender && operator != users.recipient);

        // Approve the operator to handle the first stream.
        sablierV2.approve({ to: users.operator, tokenId: defaultStreamIds[0] });

        // Make the approved operator the caller in this test.
        changePrank(users.operator);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2_Unauthorized.selector, defaultStreamIds[0], users.operator)
        );
        sablierV2.cancelMultiple(defaultStreamIds);
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorizedSomeStreams_FormerRecipient()
        external
        onlyNonNullStreams
        allStreamsCancelable
    {
        // Transfer the first stream to Eve.
        sablierV2.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[0] });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2_Unauthorized.selector, defaultStreamIds[0], users.recipient)
        );
        sablierV2.cancelMultiple(defaultStreamIds);
    }

    modifier callerAuthorizedAllStreams() {
        _;
    }

    /// @dev it should perform the ERC-20 transfers, cancel the streams, update the withdrawn amounts, and emit
    /// Cancel events.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - All streams ended.
    /// - All streams ongoing.
    /// - Some streams ended, some streams ongoing.
    function testFuzz_CancelMultiple_Sender(
        uint256 timeWarp,
        uint40 stopTime
    ) external onlyNonNullStreams allStreamsCancelable callerAuthorizedAllStreams {
        timeWarp = bound(timeWarp, 0 seconds, DEFAULT_TOTAL_DURATION * 2);
        stopTime = boundUint40(stopTime, DEFAULT_CLIFF_TIME + 1, DEFAULT_STOP_TIME + DEFAULT_TOTAL_DURATION / 2);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Make the sender the caller in this test.
        changePrank(users.sender);

        // Create a new stream with a different stop time.
        uint256 streamId = createDefaultStreamWithStopTime(stopTime);

        // Create the stream ids array.
        uint256[] memory streamIds = Solarray.uint256s(defaultStreamIds[0], streamId);

        // Expect the tokens to be withdrawn to the recipients, if not zero.
        uint128 recipientAmount0 = sablierV2.getWithdrawableAmount(streamIds[0]);
        if (recipientAmount0 > 0) {
            vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (users.recipient, recipientAmount0)));
        }
        uint128 recipientAmount1 = sablierV2.getWithdrawableAmount(streamIds[1]);
        if (recipientAmount1 > 0) {
            vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (users.recipient, recipientAmount1)));
        }

        // Expect the tokens to be returned to the senders, if not zero.
        uint128 senderAmount0 = DEFAULT_NET_DEPOSIT_AMOUNT - recipientAmount0;
        if (senderAmount0 > 0) {
            vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (users.sender, senderAmount0)));
        }
        uint128 senderAmount1 = DEFAULT_NET_DEPOSIT_AMOUNT - recipientAmount1;
        if (senderAmount1 > 0) {
            vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (users.sender, senderAmount1)));
        }

        // Expect Cancel events to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.Cancel(streamIds[0], users.sender, users.recipient, senderAmount0, recipientAmount0);
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.Cancel(streamIds[1], users.sender, users.recipient, senderAmount1, recipientAmount1);

        // Cancel the streams.
        sablierV2.cancelMultiple(streamIds);

        // Assert that the streams were marked as canceled.
        Status actualStatus0 = sablierV2.getStatus(streamIds[0]);
        Status actualStatus1 = sablierV2.getStatus(streamIds[1]);
        Status expectedStatus = Status.CANCELED;
        assertEq(actualStatus0, expectedStatus);
        assertEq(actualStatus1, expectedStatus);

        // Assert that the withdrawn amounts were updated.
        uint128 actualWithdrawnAmount0 = sablierV2.getWithdrawnAmount(streamIds[0]);
        uint128 actualWithdrawnAmount1 = sablierV2.getWithdrawnAmount(streamIds[1]);
        uint128 expectedWithdrawnAmount0 = recipientAmount0;
        uint128 expectedWithdrawnAmount1 = recipientAmount1;
        assertEq(actualWithdrawnAmount0, expectedWithdrawnAmount0);
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount1);

        // Assert that the NFTs weren't burned.
        address actualNFTOwner0 = sablierV2.ownerOf({ tokenId: streamIds[0] });
        address actualNFTOwner1 = sablierV2.ownerOf({ tokenId: streamIds[1] });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner0, expectedNFTOwner);
        assertEq(actualNFTOwner1, expectedNFTOwner);
    }

    /// @dev it should perform the ERC-20 transfers, cancel the streams, update the withdrawn amounts, and emit
    /// Cancel events.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - All streams ended.
    /// - All streams ongoing.
    /// - Some streams ended, some streams ongoing.
    function testFuzz_CancelMultiple_Recipient(
        uint256 timeWarp,
        uint40 stopTime
    ) external onlyNonNullStreams allStreamsCancelable callerAuthorizedAllStreams {
        timeWarp = bound(timeWarp, 0 seconds, DEFAULT_TOTAL_DURATION * 2);
        stopTime = boundUint40(stopTime, DEFAULT_CLIFF_TIME + 1, DEFAULT_STOP_TIME + DEFAULT_TOTAL_DURATION / 2);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Make the recipient the caller in this test.
        changePrank(users.recipient);

        // Create a new stream with a different stop time.
        uint256 streamId = createDefaultStreamWithStopTime(stopTime);

        // Create the stream ids array.
        uint256[] memory streamIds = Solarray.uint256s(defaultStreamIds[0], streamId);

        // Expect the tokens to be withdrawn to the recipients, if not zero.
        uint128 recipientAmount0 = sablierV2.getWithdrawableAmount(streamIds[0]);
        if (recipientAmount0 > 0) {
            vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (users.recipient, recipientAmount0)));
        }
        uint128 recipientAmount1 = sablierV2.getWithdrawableAmount(streamIds[1]);
        if (recipientAmount1 > 0) {
            vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (users.recipient, recipientAmount1)));
        }

        // Expect the tokens to be returned to the senders, if not zero.
        uint128 senderAmount0 = DEFAULT_NET_DEPOSIT_AMOUNT - recipientAmount0;
        if (senderAmount0 > 0) {
            vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (users.sender, senderAmount0)));
        }
        uint128 senderAmount1 = DEFAULT_NET_DEPOSIT_AMOUNT - recipientAmount1;
        if (senderAmount1 > 0) {
            vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (users.sender, senderAmount1)));
        }

        // Expect Cancel events to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.Cancel(streamIds[0], users.sender, users.recipient, senderAmount0, recipientAmount0);
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.Cancel(streamIds[1], users.sender, users.recipient, senderAmount1, recipientAmount1);

        // Cancel the streams.
        sablierV2.cancelMultiple(streamIds);

        // Assert that the streams were marked as canceled.
        Status actualStatus0 = sablierV2.getStatus(streamIds[0]);
        Status actualStatus1 = sablierV2.getStatus(streamIds[1]);
        Status expectedStatus = Status.CANCELED;
        assertEq(actualStatus0, expectedStatus);
        assertEq(actualStatus1, expectedStatus);

        // Assert that the withdrawn amounts were updated.
        uint128 actualWithdrawnAmount0 = sablierV2.getWithdrawnAmount(streamIds[0]);
        uint128 actualWithdrawnAmount1 = sablierV2.getWithdrawnAmount(streamIds[1]);
        uint128 expectedWithdrawnAmount0 = recipientAmount0;
        uint128 expectedWithdrawnAmount1 = recipientAmount1;
        assertEq(actualWithdrawnAmount0, expectedWithdrawnAmount0);
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount1);

        // Assert that the NFTs weren't burned.
        address actualNFTOwner0 = sablierV2.getRecipient(streamIds[0]);
        address actualNFTOwner1 = sablierV2.getRecipient(streamIds[1]);
        address expectedRecipient = users.recipient;
        assertEq(actualNFTOwner0, expectedRecipient);
        assertEq(actualNFTOwner1, expectedRecipient);
    }
}
