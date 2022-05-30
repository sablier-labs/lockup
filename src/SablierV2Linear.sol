// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { SafeERC20 } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { UD60x18, toUD60x18 } from "@prb/math/UD60x18.sol";

import { ISablierV2 } from "./interfaces/ISablierV2.sol";
import { ISablierV2Linear } from "./interfaces/ISablierV2Linear.sol";
import { SablierV2 } from "./SablierV2.sol";

/// @title SablierV2Linear
/// @author Sablier Labs Ltd.
contract SablierV2Linear is
    SablierV2, // two dependencies
    ISablierV2Linear // one dependency
{
    using SafeERC20 for IERC20;

    /// INTERNAL STORAGE ///

    /// @dev Sablier V2 linear streams mapped by unsigned integers.
    mapping(uint256 => Stream) internal streams;

    /// MODIFIERS ///

    /// @dev Checks that `streamId` points to a stream that exists.
    modifier streamExists(uint256 streamId) {
        if (streams[streamId].sender == address(0)) {
            revert SablierV2__StreamNonExistent(streamId);
        }
        _;
    }

    /// @notice Checks that `msg.sender` is either the sender or the recipient of the stream.
    modifier onlySenderOrRecipient(uint256 streamId) {
        if (msg.sender != streams[streamId].sender && msg.sender != streams[streamId].recipient) {
            revert SablierV2__Unauthorized(streamId, msg.sender);
        }
        _;
    }

    /// CONSTANT FUNCTIONS ///

    /// @inheritdoc ISablierV2
    function getReturnableAmount(uint256 streamId) public view returns (uint256 returnableAmount) {
        // If the stream does not exist, return zero.
        Stream memory stream = streams[streamId];
        if (stream.sender == address(0)) {
            return 0;
        }

        unchecked {
            uint256 withdrawableAmount = getWithdrawableAmount(streamId);
            returnableAmount = stream.depositAmount - stream.withdrawnAmount - withdrawableAmount;
        }
    }

    /// @inheritdoc ISablierV2Linear
    function getStream(uint256 streamId) external view override returns (Stream memory stream) {
        stream = streams[streamId];
    }

    /// @inheritdoc ISablierV2
    function getWithdrawableAmount(uint256 streamId) public view returns (uint256 withdrawableAmount) {
        // If the stream does not exist, return zero.
        Stream memory stream = streams[streamId];
        if (stream.sender == address(0)) {
            return 0;
        }

        // If the start time is greater than or equal to the block timestamp, return zero.
        uint256 currentTime = block.timestamp;
        if (stream.startTime >= currentTime) {
            return 0;
        }

        unchecked {
            // If the current time is greater than or equal to the stop time, return the deposit minus
            // the withdrawn amount.
            if (currentTime >= stream.stopTime) {
                return stream.depositAmount - stream.withdrawnAmount;
            }

            // In all other cases, calculate how much the recipient can withdraw.
            UD60x18 elapsedTime = toUD60x18(currentTime - stream.startTime);
            UD60x18 totalTime = toUD60x18(stream.stopTime - stream.startTime);
            UD60x18 quotient = elapsedTime.div(totalTime);
            UD60x18 depositAmount = UD60x18.wrap(stream.depositAmount);
            UD60x18 streamedAmount = quotient.mul(depositAmount);
            UD60x18 withdrawnAmount = UD60x18.wrap(stream.withdrawnAmount);
            withdrawableAmount = UD60x18.unwrap(streamedAmount.uncheckedSub(withdrawnAmount));
        }
    }

    /// NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc ISablierV2
    function cancel(uint256 streamId) external {
        cancelInternal(streamId);
    }

    /// @inheritdoc ISablierV2
    function cancelAll(uint256[] calldata streamIds) external {
        uint256 length = streamIds.length;

        if (length == 0) {
            revert SablierV2__ArrayLengthIsZero(length);
        }

        for (uint256 i = 0; i < length; ) {
            cancelInternal(streamIds[i]);

            unchecked {
                i += 1;
            }
        }
    }

    /// @inheritdoc ISablierV2Linear
    function create(
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 startTime,
        uint256 stopTime,
        bool cancelable
    ) external returns (uint256 streamId) {
        address from = msg.sender;
        streamId = createInternal(from, sender, recipient, depositAmount, token, startTime, stopTime, cancelable);
    }

    /// @inheritdoc ISablierV2Linear
    function createWithDuration(
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 duration,
        bool cancelable
    ) external override returns (uint256 streamId) {
        address from = msg.sender;
        uint256 startTime = block.timestamp;
        uint256 stopTime = startTime + duration;
        streamId = createInternal(from, sender, recipient, depositAmount, token, startTime, stopTime, cancelable);
    }

    /// @inheritdoc ISablierV2Linear
    function createFrom(
        address from,
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 startTime,
        uint256 stopTime,
        bool cancelable
    ) external returns (uint256 streamId) {
        // Checks: the funder is not the zero address.
        if (from == address(0)) {
            revert SablierV2__FromZeroAddress();
        }

        // Checks: the caller has sufficient authorization to create this stream on behalf of `from`.
        uint256 authorization = authorizations[from][msg.sender];
        if (authorization < depositAmount) {
            revert SablierV2__InsufficientAuthorization(from, msg.sender, authorization, depositAmount);
        }

        // Effects & Interactions: create the stream.
        streamId = createInternal(from, sender, recipient, depositAmount, token, startTime, stopTime, cancelable);

        // Effects: decrease the authorization since this stream has consumed part of it.
        unchecked {
            authorizeInternal(from, msg.sender, authorization - depositAmount);
        }
    }

    /// @inheritdoc ISablierV2Linear
    function createFromWithDuration(
        address from,
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 duration,
        bool cancelable
    ) external returns (uint256 streamId) {
        // Checks: the funder is not the zero address.
        if (from == address(0)) {
            revert SablierV2__FromZeroAddress();
        }

        // Checks: `msg.sender` has sufficient authorization to create this stream on behalf of `from`.
        uint256 authorization = authorizations[from][msg.sender];
        if (authorization < depositAmount) {
            revert SablierV2__InsufficientAuthorization(from, msg.sender, authorization, depositAmount);
        }

        // Effects & Interactions: create the stream.
        uint256 startTime = block.timestamp;
        uint256 stopTime = startTime + duration;
        streamId = createInternal(from, sender, recipient, depositAmount, token, startTime, stopTime, cancelable);

        // Effects: decrease the authorization since this stream has consumed part of it.
        unchecked {
            authorizeInternal(from, msg.sender, authorization - depositAmount);
        }
    }

    /// @inheritdoc ISablierV2
    function renounce(uint256 streamId) external streamExists(streamId) {
        Stream memory stream = streams[streamId];

        // Checks: the caller is the sender of the stream.
        if (msg.sender != stream.sender) {
            revert SablierV2__Unauthorized(streamId, msg.sender);
        }

        // Checks: the stream is not already non-cancelable.
        if (!stream.cancelable) {
            revert SablierV2__RenounceNonCancelableStream(streamId);
        }

        // Effects: make the stream non-cancelable.
        streams[streamId].cancelable = false;

        // Emit an event.
        emit Renounce(streamId);
    }

    /// @inheritdoc ISablierV2
    function withdraw(uint256 streamId, uint256 amount) external {
        address to = streams[streamId].recipient;

        withdrawInternal(streamId, amount, to);
    }

    /// @inheritdoc ISablierV2
    function withdrawAll(uint256[] calldata streamIds, uint256[] calldata amounts) external {
        address to;
        uint256 length = checkLengths(streamIds.length, amounts.length);

        for (uint256 i = 0; i < length; ) {
            to = streams[streamIds[i]].recipient;
            withdrawInternal(streamIds[i], amounts[i], to);

            unchecked {
                i += 1;
            }
        }
    }

    /// @inheritdoc ISablierV2
    function withdrawTo(
        uint256 streamId,
        uint256 amount,
        address to
    ) external streamExists(streamId) {
        // Checks: the `msg.sender` is the recipient of the stream.
        if (msg.sender != streams[streamId].recipient) {
            revert SablierV2__Unauthorized(streamId, msg.sender);
        }

        // Checks: the address that will receive the tokens is not zero.
        if (to == address(0)) {
            revert SablierV2__WithdrawToZeroAddress();
        }

        withdrawInternal(streamId, amount, to);
    }

    /// @inheritdoc ISablierV2
    function withdrawAllTo(
        uint256[] calldata streamIds,
        uint256[] calldata amounts,
        address to
    ) external {
        // Checks: the address that will receive the tokens is not zero.
        if (to == address(0)) {
            revert SablierV2__WithdrawToZeroAddress();
        }

        uint256 length = checkLengths(streamIds.length, amounts.length);

        for (uint256 i = 0; i < length; ) {
            // Checks: `streamId` points to a stream that exists.
            if (streams[streamIds[i]].sender == address(0)) {
                revert SablierV2__StreamNonExistent(streamIds[i]);
            }
            // Checks: the `msg.sender` is the recipient of all the streams.
            if (msg.sender != streams[streamIds[i]].recipient) {
                revert SablierV2__Unauthorized(streamIds[i], msg.sender);
            }

            withdrawInternal(streamIds[i], amounts[i], to);

            unchecked {
                i += 1;
            }
        }
    }

    /// INTERNAL FUNCTIONS ///

    /// @dev See the documentation for the public functions that call this internal function.
    function cancelInternal(uint256 streamId) internal streamExists(streamId) onlySenderOrRecipient(streamId) {
        Stream memory stream = streams[streamId];

        // Checks: the stream is cancelable.
        if (!stream.cancelable) {
            revert SablierV2__StreamNonCancelable(streamId);
        }

        // Calculate the pay and the return amounts.
        uint256 withdrawAmount = getWithdrawableAmount(streamId);
        uint256 returnAmount;
        unchecked {
            returnAmount = stream.depositAmount - stream.withdrawnAmount - withdrawAmount;
        }

        // Effects: delete the stream from storage.
        delete streams[streamId];

        // Interactions: withdraw the tokens to the recipient, if any.
        if (withdrawAmount > 0) {
            stream.token.safeTransfer(stream.recipient, withdrawAmount);
        }

        // Interactions: return the tokens to the sender, if any.
        if (returnAmount > 0) {
            stream.token.safeTransfer(stream.sender, returnAmount);
        }

        // Emit an event.
        emit Cancel(streamId, stream.recipient, withdrawAmount, returnAmount);
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function createInternal(
        address from,
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 startTime,
        uint256 stopTime,
        bool cancelable
    ) internal returns (uint256 streamId) {
        // See SablierV2 contract.
        checkBasicRequiremenets(sender, recipient, depositAmount, startTime, stopTime);

        // Effects: create and store the stream.
        streamId = nextStreamId;
        streams[streamId] = Stream({
            cancelable: cancelable,
            depositAmount: depositAmount,
            recipient: recipient,
            sender: sender,
            startTime: startTime,
            stopTime: stopTime,
            token: token,
            withdrawnAmount: 0
        });

        // Effects: bump the next stream id.
        // We're using unchecked arithmetic here because this cannot realistically overflow, ever.
        unchecked {
            nextStreamId = streamId + 1;
        }

        // Interactions: perform the ERC-20 transfer.
        token.safeTransferFrom(from, address(this), depositAmount);

        // Emit an event.
        emit CreateStream(streamId, sender, recipient, depositAmount, token, startTime, stopTime, cancelable);
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function withdrawInternal(
        uint256 streamId,
        uint256 amount,
        address to
    ) internal streamExists(streamId) onlySenderOrRecipient(streamId) {
        // Checks: the amount cannot be zero.
        if (amount == 0) {
            revert SablierV2__WithdrawAmountZero(streamId);
        }

        // Checks: the amount cannot be greater than what can be withdrawn.
        uint256 withdrawableAmount = getWithdrawableAmount(streamId);
        if (amount > withdrawableAmount) {
            revert SablierV2__WithdrawAmountGreaterThanWithdrawableAmount(streamId, amount, withdrawableAmount);
        }

        // Effects: update the withdrawn amount.
        unchecked {
            streams[streamId].withdrawnAmount += amount;
        }

        // Load the stream in memory, we will need it later.
        Stream memory stream = streams[streamId];

        // Effects: if this stream is done, save gas by deleting it from storage.
        if (stream.depositAmount == stream.withdrawnAmount) {
            delete streams[streamId];
        }

        // Interactions: perform the ERC-20 transfer.
        stream.token.safeTransfer(to, amount);

        // Emit an event.
        emit Withdraw(streamId, to, amount);
    }
}
