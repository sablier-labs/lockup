// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SafeERC20__CallToNonContract } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Cliff } from "@sablier/v2-core/interfaces/ISablierV2Cliff.sol";
import { SablierV2Cliff } from "@sablier/v2-core/SablierV2Cliff.sol";

import { SablierV2CliffUnitTest } from "../SablierV2CliffUnitTest.t.sol";

contract SablierV2Cliff__UnitTest__Create is SablierV2CliffUnitTest {
    /// @dev When the recipient is the zero address, it should revert.
    function testCannotCreate__RecipientZeroAddress() external {
        vm.expectRevert(ISablierV2.SablierV2__RecipientZeroAddress.selector);
        address recipient = address(0);
        sablierV2Cliff.create(
            stream.sender,
            recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            stream.cliffTime,
            stream.stopTime,
            stream.cancelable
        );
    }

    /// @dev When the deposit amount is zero, it should revert.
    function testCannotCreate__DepositAmountZero() external {
        vm.expectRevert(ISablierV2.SablierV2__DepositAmountZero.selector);
        uint256 depositAmount = 0;
        sablierV2Cliff.create(
            stream.sender,
            stream.recipient,
            depositAmount,
            stream.token,
            stream.startTime,
            stream.cliffTime,
            stream.stopTime,
            stream.cancelable
        );
    }

    /// @dev When the start time is greater than the stop time, it should revert.
    function testCannotCreate__StartTimeGreaterThanStopTime() external {
        uint256 startTime = stream.stopTime;
        uint256 stopTime = stream.startTime;
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2.SablierV2__StartTimeGreaterThanStopTime.selector, startTime, stopTime)
        );
        sablierV2Cliff.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            startTime,
            stream.cliffTime,
            stopTime,
            stream.cancelable
        );
    }

    /// @dev When the start time is equal to the stop time, it should create the stream.
    function testCreate__StartTimeEqualToStopTime() external {
        uint256 cliffTime = stream.startTime;
        uint256 stopTime = stream.startTime;
        uint256 streamId = sablierV2Cliff.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            cliffTime,
            stopTime,
            stream.cancelable
        );
        ISablierV2Cliff.Stream memory createdStream = sablierV2Cliff.getStream(streamId);
        assertEq(stream.sender, createdStream.sender);
        assertEq(stream.recipient, createdStream.recipient);
        assertEq(stream.depositAmount, createdStream.depositAmount);
        assertEq(stream.token, createdStream.token);
        assertEq(stream.startTime, createdStream.startTime);
        assertEq(cliffTime, createdStream.cliffTime);
        assertEq(stopTime, createdStream.stopTime);
        assertEq(stream.cancelable, createdStream.cancelable);
        assertEq(stream.withdrawnAmount, createdStream.withdrawnAmount);
    }

    /// @dev When the start time is greater than the cliff time, is should revert.
    function testCannotCreate__StartTimeGreaterThanCliffTime() external {
        uint256 startTime = stream.cliffTime;
        uint256 cliffTime = stream.startTime;
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Cliff.SablierV2Cliff__StartTimeGreaterThanCliffTime.selector,
                startTime,
                cliffTime
            )
        );
        sablierV2Cliff.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            startTime,
            cliffTime,
            stream.stopTime,
            stream.cancelable
        );
    }

    /// @dev When the cliff time is equal to the stop time, it should create the stream.
    function testCreate__CliffTimeEqualStopTime() external {
        uint256 cliffTime = stream.stopTime;
        uint256 streamId = sablierV2Cliff.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            cliffTime,
            stream.stopTime,
            stream.cancelable
        );
        ISablierV2Cliff.Stream memory createdStream = sablierV2Cliff.getStream(streamId);
        assertEq(stream.sender, createdStream.sender);
        assertEq(stream.recipient, createdStream.recipient);
        assertEq(stream.depositAmount, createdStream.depositAmount);
        assertEq(stream.token, createdStream.token);
        assertEq(stream.startTime, createdStream.startTime);
        assertEq(cliffTime, createdStream.cliffTime);
        assertEq(stream.stopTime, createdStream.stopTime);
        assertEq(stream.cancelable, createdStream.cancelable);
        assertEq(stream.withdrawnAmount, createdStream.withdrawnAmount);
    }

    /// @dev When the cliff time is greater than the stop time, is should revert.
    function testCannotCreate__CliffTimeGreaterThanStopTime() external {
        uint256 cliffTime = stream.stopTime;
        uint256 stopTime = stream.cliffTime;
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Cliff.SablierV2Cliff__CliffTimeGreaterThanStopTime.selector,
                cliffTime,
                stopTime
            )
        );
        sablierV2Cliff.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            cliffTime,
            stopTime,
            stream.cancelable
        );
    }

    /// @dev When the cliff time is the equal to the stop time, it should create the stream.
    function testCreate__CliffTimeEqualToStopTime() external {
        uint256 cliffTime = stream.stopTime;
        uint256 streamId = sablierV2Cliff.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            stream.stopTime,
            cliffTime,
            stream.cancelable
        );
        ISablierV2Cliff.Stream memory createdStream = sablierV2Cliff.getStream(streamId);
        assertEq(stream.sender, createdStream.sender);
        assertEq(stream.recipient, createdStream.recipient);
        assertEq(stream.depositAmount, createdStream.depositAmount);
        assertEq(stream.token, createdStream.token);
        assertEq(stream.startTime, createdStream.startTime);
        assertEq(cliffTime, createdStream.cliffTime);
        assertEq(stream.stopTime, createdStream.stopTime);
        assertEq(stream.cancelable, createdStream.cancelable);
        assertEq(stream.withdrawnAmount, createdStream.withdrawnAmount);
    }

    /// @dev When the token is not a contract, it should revert.
    function testCannotCreate__TokenNotContract() external {
        vm.expectRevert(abi.encodeWithSelector(SafeERC20__CallToNonContract.selector, address(6174)));
        IERC20 token = IERC20(address(6174));
        sablierV2Cliff.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            token,
            stream.startTime,
            stream.cliffTime,
            stream.stopTime,
            stream.cancelable
        );
    }

    /// @dev When the token is missing the return value, it should create the stream.
    function testCreate__TokenMissingReturnValue() external {
        IERC20 token = IERC20(address(nonStandardToken));

        uint256 streamId = sablierV2Cliff.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            token,
            stream.startTime,
            stream.cliffTime,
            stream.stopTime,
            stream.cancelable
        );

        ISablierV2Cliff.Stream memory createdStream = sablierV2Cliff.getStream(streamId);
        assertEq(stream.sender, createdStream.sender);
        assertEq(stream.recipient, createdStream.recipient);
        assertEq(stream.depositAmount, createdStream.depositAmount);
        assertEq(address(nonStandardToken), address(createdStream.token));
        assertEq(stream.startTime, createdStream.startTime);
        assertEq(stream.cliffTime, createdStream.cliffTime);
        assertEq(stream.stopTime, createdStream.stopTime);
        assertEq(stream.cancelable, createdStream.cancelable);
        assertEq(stream.withdrawnAmount, createdStream.withdrawnAmount);
    }

    /// @dev When all checks pass, it should create the stream.
    function testCreate() external {
        uint256 streamId = createDefaultStream();
        ISablierV2Cliff.Stream memory createdStream = sablierV2Cliff.getStream(streamId);
        assertEq(stream, createdStream);
    }

    /// @dev When all checks pass, it should bump the next stream id.
    function testCreate__NextStreamId() external {
        uint256 nextStreamId = sablierV2Cliff.nextStreamId();
        createDefaultStream();
        uint256 actualNextStreamId = sablierV2Cliff.nextStreamId();
        uint256 expectedNextStreamId = nextStreamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);
    }

    /// @dev When all checks pass, it should emit a CreateStream event.
    function testCreate__Event() external {
        uint256 streamId = sablierV2Cliff.nextStreamId();
        vm.expectEmit(true, true, true, true);
        emit CreateStream(
            streamId,
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            stream.cliffTime,
            stream.stopTime,
            stream.cancelable
        );
        createDefaultStream();
    }
}
