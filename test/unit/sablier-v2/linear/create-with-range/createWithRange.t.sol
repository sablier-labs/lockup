// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { MAX_UD60x18, UD60x18, ud } from "@prb/math/UD60x18.sol";
import { SafeERC20_CallToNonContract } from "@prb/contracts/token/erc20/SafeERC20.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";
import { Status } from "src/types/Enums.sol";
import { Amounts, Broker, LinearStream, Range } from "src/types/Structs.sol";

import { LinearTest } from "../LinearTest.t.sol";

contract CreateWithRange_LinearTest is LinearTest {
    /// @dev it should revert.
    function test_RevertWhen_RecipientZeroAddress() external {
        vm.expectRevert("ERC721: mint to the zero address");
        createDefaultStreamWithRecipient({ recipient: address(0) });
    }

    modifier recipientNonZeroAddress() {
        _;
    }

    /// @dev it should revert.
    ///
    /// It is not possible to obtain a zero net deposit amount from a non-zero gross deposit amount, because the
    /// `MAX_FEE` is hard coded to 10%.
    function test_RevertWhen_NetDepositAmountZero() external recipientNonZeroAddress {
        vm.expectRevert(Errors.SablierV2_NetDepositAmountZero.selector);
        createDefaultStreamWithGrossDepositAmount(0);
    }

    modifier netDepositAmountNotZero() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_StartTimeGreaterThanCliffTime() external recipientNonZeroAddress netDepositAmountNotZero {
        uint40 startTime = params.createWithRange.range.cliff;
        uint40 cliffTime = params.createWithRange.range.start;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Linear_StartTimeGreaterThanCliffTime.selector, startTime, cliffTime)
        );
        linear.createWithRange(
            params.createWithRange.sender,
            params.createWithRange.recipient,
            params.createWithRange.grossDepositAmount,
            params.createWithRange.token,
            params.createWithRange.cancelable,
            Range({ start: startTime, cliff: cliffTime, stop: params.createWithRange.range.stop }),
            params.createWithRange.broker
        );
    }

    modifier startTimeLessThanOrEqualToCliffTime() {
        _;
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_CliffTimeGreaterThanStopTime(
        uint40 cliffTime,
        uint40 stopTime
    ) external recipientNonZeroAddress netDepositAmountNotZero startTimeLessThanOrEqualToCliffTime {
        vm.assume(cliffTime > stopTime);
        vm.assume(stopTime > params.createWithRange.range.start);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Linear_CliffTimeGreaterThanStopTime.selector, cliffTime, stopTime)
        );
        linear.createWithRange(
            params.createWithRange.sender,
            params.createWithRange.recipient,
            params.createWithRange.grossDepositAmount,
            params.createWithRange.token,
            params.createWithRange.cancelable,
            Range({ start: params.createWithRange.range.start, cliff: cliffTime, stop: stopTime }),
            params.createWithRange.broker
        );
    }

    modifier cliffLessThanOrEqualToStopTime() {
        _;
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_ProtocolFeeTooHigh(
        UD60x18 protocolFee
    )
        external
        recipientNonZeroAddress
        netDepositAmountNotZero
        startTimeLessThanOrEqualToCliffTime
        cliffLessThanOrEqualToStopTime
    {
        protocolFee = bound(protocolFee, DEFAULT_MAX_FEE.add(ud(1)), MAX_UD60x18);

        // Set the protocol fee.
        changePrank(users.admin);
        comptroller.setProtocolFee(params.createWithRange.token, protocolFee);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2_ProtocolFeeTooHigh.selector, protocolFee, DEFAULT_MAX_FEE)
        );
        createDefaultStream();
    }

    modifier protocolFeeNotTooHigh() {
        _;
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_BrokerFeeTooHigh(
        UD60x18 brokerFee
    )
        external
        recipientNonZeroAddress
        netDepositAmountNotZero
        startTimeLessThanOrEqualToCliffTime
        cliffLessThanOrEqualToStopTime
        protocolFeeNotTooHigh
    {
        brokerFee = bound(brokerFee, DEFAULT_MAX_FEE.add(ud(1)), MAX_UD60x18);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2_BrokerFeeTooHigh.selector, brokerFee, DEFAULT_MAX_FEE));
        linear.createWithRange(
            params.createWithRange.sender,
            params.createWithRange.recipient,
            params.createWithRange.grossDepositAmount,
            params.createWithRange.token,
            params.createWithRange.cancelable,
            params.createWithRange.range,
            Broker({ addr: users.broker, fee: brokerFee })
        );
    }

    modifier brokerFeeNotTooHigh() {
        _;
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_TokenNotContract(
        IERC20 nonToken
    )
        external
        recipientNonZeroAddress
        netDepositAmountNotZero
        startTimeLessThanOrEqualToCliffTime
        cliffLessThanOrEqualToStopTime
        protocolFeeNotTooHigh
        brokerFeeNotTooHigh
    {
        vm.assume(address(nonToken).code.length == 0);
        vm.expectRevert(abi.encodeWithSelector(SafeERC20_CallToNonContract.selector, address(nonToken)));
        linear.createWithRange(
            params.createWithRange.sender,
            params.createWithRange.recipient,
            params.createWithRange.grossDepositAmount,
            nonToken,
            params.createWithRange.cancelable,
            params.createWithRange.range,
            params.createWithRange.broker
        );
    }

    modifier tokenContract() {
        _;
    }

    /// @dev it should perform the ERC-20 transfers, create the stream, bump the next stream id, and mint the NFT.
    function test_CreateWithRange_TokenMissingReturnValue()
        external
        recipientNonZeroAddress
        netDepositAmountNotZero
        startTimeLessThanOrEqualToCliffTime
        cliffLessThanOrEqualToStopTime
        protocolFeeNotTooHigh
        brokerFeeNotTooHigh
        tokenContract
    {
        // Load the stream id.
        uint256 streamId = linear.nextStreamId();

        // Expect the tokens to be transferred from the funder to the SablierV2Linear contract.
        address funder = params.createWithRange.sender;
        vm.expectCall(
            address(nonCompliantToken),
            abi.encodeCall(IERC20.transferFrom, (funder, address(linear), DEFAULT_NET_DEPOSIT_AMOUNT))
        );

        // Expect the broker fee to be paid to the broker.
        vm.expectCall(
            address(nonCompliantToken),
            abi.encodeCall(IERC20.transferFrom, (funder, params.createWithRange.broker.addr, DEFAULT_BROKER_FEE_AMOUNT))
        );

        // Create the stream.
        linear.createWithRange(
            params.createWithRange.sender,
            params.createWithRange.recipient,
            params.createWithRange.grossDepositAmount,
            IERC20(address(nonCompliantToken)),
            params.createWithRange.cancelable,
            params.createWithRange.range,
            params.createWithRange.broker
        );

        // Assert that the stream was created.
        LinearStream memory actualStream = linear.getStream(streamId);
        assertEq(actualStream.amounts, defaultStream.amounts);
        assertEq(actualStream.isCancelable, defaultStream.isCancelable);
        assertEq(actualStream.sender, defaultStream.sender);
        assertEq(actualStream.range, defaultStream.range);
        assertEq(actualStream.token, IERC20(address(nonCompliantToken)));

        // Assert that the next stream id was bumped.
        uint256 actualNextStreamId = linear.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);

        // Assert that the NFT was minted.
        address actualNFTOwner = linear.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = params.createWithRange.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner);
    }

    modifier tokenERC20Compliant() {
        _;
    }

    /// @dev it should perform the ERC-20 transfers, create the stream, bump the next stream id, and mint the NFT.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - All possible permutations for the funder, recipient, sender, and broker.
    /// - Multiple values for the gross deposit amount.
    /// - Cancelable and non-cancelable.
    /// - Start time in the past, present and future.
    /// - Start time lower than and equal to cliff time.
    /// - Cliff time lower than and equal to stop time.
    /// - Broker fee zero and non-zero.
    function testFuzz_CreateWithRange(
        address funder,
        address recipient,
        uint128 grossDepositAmount,
        bool cancelable,
        Range memory range,
        UD60x18 protocolFee,
        Broker memory broker
    )
        external
        netDepositAmountNotZero
        startTimeLessThanOrEqualToCliffTime
        cliffLessThanOrEqualToStopTime
        protocolFeeNotTooHigh
        brokerFeeNotTooHigh
        tokenContract
        tokenERC20Compliant
    {
        vm.assume(funder != address(0) && recipient != address(0) && broker.addr != address(0));
        vm.assume(grossDepositAmount != 0);
        vm.assume(range.start <= range.cliff && range.cliff <= range.stop);
        broker.fee = bound(broker.fee, 0, DEFAULT_MAX_FEE);
        protocolFee = bound(protocolFee, 0, DEFAULT_MAX_FEE);

        // Make the fuzzed funder the caller in this test.
        changePrank(funder);

        // Mint enough tokens to the funder.
        deal({ token: address(params.createWithRange.token), to: funder, give: grossDepositAmount });

        // Approve the SablierV2Linear contract to transfer the tokens from the funder.
        params.createWithRange.token.approve({ spender: address(linear), value: UINT256_MAX });

        // Load the stream id.
        uint256 streamId = linear.nextStreamId();

        // Calculate the broker fee amount and the net deposit amount.
        uint128 protocolFeeAmount = uint128(ud(grossDepositAmount).mul(DEFAULT_PROTOCOL_FEE).unwrap());
        uint128 brokerFeeAmount = uint128(ud(grossDepositAmount).mul(broker.fee).unwrap());
        uint128 netDepositAmount = grossDepositAmount - protocolFeeAmount - brokerFeeAmount;

        // Expect the tokens to be transferred from the funder to the SablierV2Linear contract.
        vm.expectCall(
            address(params.createWithRange.token),
            abi.encodeCall(IERC20.transferFrom, (funder, address(linear), netDepositAmount))
        );

        // Expect the broker fee to be paid to the broker, if the fee amount is not zero.
        if (brokerFeeAmount > 0) {
            vm.expectCall(
                address(params.createWithRange.token),
                abi.encodeCall(IERC20.transferFrom, (funder, broker.addr, brokerFeeAmount))
            );
        }

        // Create the stream.
        linear.createWithRange(
            params.createWithRange.sender,
            recipient,
            grossDepositAmount,
            params.createWithRange.token,
            cancelable,
            range,
            broker
        );

        // Assert that the stream was created.
        LinearStream memory actualStream = linear.getStream(streamId);
        assertEq(actualStream.amounts, Amounts({ deposit: netDepositAmount, withdrawn: 0 }));
        assertEq(actualStream.isCancelable, cancelable);
        assertEq(actualStream.range, range);
        assertEq(actualStream.sender, defaultStream.sender);
        assertEq(actualStream.status, defaultStream.status);
        assertEq(actualStream.token, defaultStream.token);

        // Assert that the next stream id was bumped.
        uint256 actualNextStreamId = linear.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);

        // Assert that the NFT was minted.
        address actualNFTOwner = linear.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = recipient;
        assertEq(actualNFTOwner, expectedNFTOwner);
    }

    /// @dev it should record the protocol fee.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Multiple values for the gross deposit amount.
    /// - Protocol fee zero and non-zero.
    function testFuzz_CreateWithRange_ProtocolFee(
        uint128 grossDepositAmount,
        UD60x18 protocolFee
    )
        external
        netDepositAmountNotZero
        startTimeLessThanOrEqualToCliffTime
        cliffLessThanOrEqualToStopTime
        protocolFeeNotTooHigh
        brokerFeeNotTooHigh
        tokenContract
        tokenERC20Compliant
    {
        vm.assume(grossDepositAmount != 0);
        protocolFee = bound(protocolFee, 0, DEFAULT_MAX_FEE);

        // Set the fuzzed protocol fee.
        changePrank(users.admin);
        comptroller.setProtocolFee(params.createWithRange.token, protocolFee);

        // Make the sender the funder in this test.
        address funder = params.createWithRange.sender;

        // Make the funder the caller in the rest of this test.
        changePrank(funder);

        // Mint enough tokens to the funder.
        deal({ token: address(params.createWithRange.token), to: funder, give: grossDepositAmount });

        // Load the initial protocol revenues.
        uint128 initialProtocolRevenues = linear.getProtocolRevenues(params.createWithRange.token);

        // Create the stream with the fuzzed gross deposit amount.
        createDefaultStreamWithGrossDepositAmount(grossDepositAmount);

        // Calculate the protocol fee amount.
        uint128 protocolFeeAmount = uint128(ud(grossDepositAmount).mul(protocolFee).unwrap());

        // Assert that the protocol fee was recorded.
        uint128 actualProtocolRevenues = linear.getProtocolRevenues(params.createWithRange.token);
        uint128 expectedProtocolRevenues = initialProtocolRevenues + protocolFeeAmount;
        assertEq(actualProtocolRevenues, expectedProtocolRevenues);
    }

    /// @dev it should emit a CreateLinearStream event.
    function test_CreateWithRange_Event()
        external
        netDepositAmountNotZero
        startTimeLessThanOrEqualToCliffTime
        cliffLessThanOrEqualToStopTime
        protocolFeeNotTooHigh
        brokerFeeNotTooHigh
        tokenContract
        tokenERC20Compliant
    {
        uint256 streamId = linear.nextStreamId();
        address funder = params.createWithRange.sender;
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.CreateLinearStream({
            streamId: streamId,
            funder: funder,
            sender: params.createWithRange.sender,
            recipient: params.createWithRange.recipient,
            amounts: DEFAULT_CREATE_AMOUNTS,
            token: params.createWithRange.token,
            cancelable: params.createWithRange.cancelable,
            range: params.createWithRange.range,
            broker: params.createWithRange.broker.addr
        });
        createDefaultStream();
    }
}
