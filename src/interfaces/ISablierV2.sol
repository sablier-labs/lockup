// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

/// @notice The common interface between all Sablier V2 streaming contracts.
/// @author Sablier Labs Ltd.
interface ISablierV2 {
    /// CUSTOM ERRORS ///

    /// @notice Emitted when attempting to approve the zero address as a would-be stream sender.
    error SablierV2__AuthorizeSenderZeroAddress();

    /// @notice Emitted when attempting to approve the zero address as a stream funder.
    error SablierV2__AuthorizeFunderZeroAddress();

    /// @notice Emitted when attempting to create a stream with a zero deposit amount.
    error SablierV2__DepositAmountZero();

    /// @notice Emitted when attempting to create a stream on behalf of the zero address.
    error SablierV2__FromZeroAddress();

    /// @notice Emitted when the funder does not have sufficient authorization to create a stream.
    error SablierV2__InsufficientAuthorization(
        address sender,
        address funder,
        uint256 authorization,
        uint256 depositAmount
    );

    /// @notice Emitted when attempting to create a stream with recipient as the zero address.
    error SablierV2__RecipientZeroAddress();

    /// @notice Emitted when attempting to renounce an already non-cancelable stream.
    error SablierV2__RenounceNonCancelableStream(uint256 streamId);

    /// @notice Emitted when attempting to create a stream with the sender as the zero address.
    error SablierV2__SenderZeroAddress();

    /// @notice Emitted when attempting to create a stream with the start time greater than the stop time.
    error SablierV2__StartTimeGreaterThanStopTime(uint256 startTime, uint256 stopTime);

    /// @notice Emitted when attempting to cancel a stream that is already non-cancelable.
    error SablierV2__StreamNonCancelable(uint256 streamId);

    /// @notice Emitted when the stream id points to a nonexistent stream.
    error SablierV2__StreamNonExistent(uint256 streamId);

    /// @notice Emitted when the caller is not authorized to perform some action.
    error SablierV2__Unauthorized(uint256 streamId, address caller);

    /// @notice Emitted when attempting to withdraw more than can be withdrawn.
    error SablierV2__WithdrawAmountGreaterThanWithdrawableAmount(
        uint256 streamId,
        uint256 withdrawAmount,
        uint256 withdrawableAmount
    );

    /// @notice Emitted when attempting to withdraw zero tokens from a stream.
    /// @notice The id of the stream.
    error SablierV2__WithdrawAmountZero(uint256 streamId);

    /// @notice Emitted when attempti to withdraw to a zero address.
    error SablierV2__WithdrawToZeroAddress();

    /// @notice Emitted when attempting to withdraw from multiple streams with different arrays length.
    error SablierV2__ArraysLengthIsNotEqual(uint256 streamIdsLength, uint256 amountsLength);

    /// @notice Emitted when attempting to withdraw or cancel from multiple streams with an empty array.
    error SablierV2__ArrayLengthIsZero(uint256 streamIdsLenght);

    /// EVENTS ///

    /// @notice Emitted when an authorization to create streams is granted.
    /// @param sender The address of the would-be stream sender.
    /// @param funder The address of the stream funder.
    /// @param amount The authorization that can be used for creating streams.
    event Authorize(address indexed sender, address indexed funder, uint256 amount);

    /// @notice Emitted when a stream is canceled.
    /// @param streamId The id of the stream.
    /// @param recipient The address of the recipient.
    /// @param withdrawAmount The amount of tokens withdrawn to the recipient.
    /// @param returnAmount The amount of tokens returned to the sender.
    event Cancel(uint256 indexed streamId, address indexed recipient, uint256 withdrawAmount, uint256 returnAmount);

    /// @notice Emitted when a sender makes a stream non-cancelable.
    /// @param streamId The id of the stream.
    event Renounce(uint256 indexed streamId);

    /// @notice Emitted when tokens are withdrawn from a stream.
    /// @param streamId The id of the stream.
    /// @param recipient The address of the recipient.
    /// @param amount The amount of tokens withdrawn.
    event Withdraw(uint256 indexed streamId, address indexed recipient, uint256 amount);

    /// CONSTANT FUNCTIONS ///

    /// @notice Rreturns the authorization amount that `sender` has given `funder` to create streams.
    /// @param sender The address of the would-be stream sender.
    /// @param funder The address of the funder.
    function getAuthorization(address sender, address funder) external view returns (uint256 authorization);

    /// @notice Calculates the amount that the sender would be returned if the stream was canceled.
    /// @param streamId The id of the stream to make the query for.
    /// @return returnableAmount The amount of tokens that would be returned if the stream was canceled.
    function getReturnableAmount(uint256 streamId) external view returns (uint256 returnableAmount);

    /// @notice Calculates the amount that the recipient can withdraw from the stream.
    /// @param streamId The id of the stream to make the query for.
    /// @return withdrawableAmount The amount of tokens that can be withdrawn.
    function getWithdrawableAmount(uint256 streamId) external view returns (uint256 withdrawableAmount);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Cancels the stream and transfers any remaining amounts to the sender and the recipient.
    ///
    /// @dev Emits a {Cancel} event.
    ///
    /// Requiremenets:
    /// - `streamId` must point to an existing stream.
    /// - `msg.sender` must be either the sender or recipient.
    /// - The stream must be cancelable.
    ///
    /// @param streamId The id of the stream to cancel.
    function cancel(uint256 streamId) external;

    /// @notice Cancels multiple streams and transfers any remaining amounts to the sender and the recipient.
    ///
    /// @dev Emits a {Cancel} event.
    ///
    /// Requiremenets:
    /// - `streamIds` must be non-empty and each element must point to an existing stream.
    /// - `msg.sender` must be either the sender or recipient.
    /// - The stream must be cancelable.
    ///
    /// @param streamIds The ids of the streams to cancel.
    function cancelAll(uint256[] calldata streamIds) external;

    /// @notice Makes the stream non-cancelable.
    ///
    /// @dev Emits a {Renounce} event.
    ///
    /// Requiremenets:
    /// - `streamId` must point to an existing stream.
    /// - `msg.sender` must be the sender.
    /// - The stream cannot be already non-cancelable.
    ///
    /// @param streamId The id of the stream to renounce.
    function renounce(uint256 streamId) external;

    /// @notice Counter for stream ids.
    /// @return The next stream id;
    function nextStreamId() external view returns (uint256);

    /// @notice Withdraws tokens from the stream to the recipient's account.
    ///
    /// @dev Emits a {Withdraw} event.
    ///
    /// Requirements:
    /// - `streamId` must point to an existing stream.
    /// - `msg.sender` must be either the sender or recipient.
    /// - `amount` cannot execeed the withdrawable amount.
    /// @param streamId The id of the stream to withdraw.
    /// @param amount The amount to withdraw.
    function withdraw(uint256 streamId, uint256 amount) external;

    /// @notice Withdraws tokens from multiple streams to the recipient's account.
    ///
    /// @dev Emits a {Withdraw} event.
    ///
    /// Requirements:
    /// - `streamIds` must be non-empty and each element of the array must point to an existing stream.
    /// - `msg.sender` must be either the sender or recipient.
    /// - `amounts` must be non-empty and each element cannot execeed the withdrawable amount.
    /// @param streamIds The ids of the streams to withdraw.
    /// @param amounts The amounts to withdraw.
    function withdrawAll(uint256[] calldata streamIds, uint256[] calldata amounts) external;

    /// @notice Withdraws tokens from the stream to `to` address.
    ///
    /// @dev Emits a {Withdraw} event.
    ///
    /// Requirements:
    /// - `streamId` must point to an existing stream.
    /// - `msg.sender` must be the recipient.
    /// - `amount` cannot execeed the withdrawable amount.
    /// - `to` cannot be the zero address.
    /// @param streamId The id of the stream to withdraw.
    /// @param amount The amount to withdraw.
    /// @param to The address that will receive the withdrawn tokens.
    function withdrawTo(
        uint256 streamId,
        uint256 amount,
        address to
    ) external;

    /// @notice Withdraws tokens from multiple streams to `to` address.
    ///
    /// @dev Emits a {Withdraw} event.
    ///
    /// Requirements:
    /// - `streamIds` must be non-empty and each element of the array must point to an existing stream.
    /// - `msg.sender` must be the recipient.
    /// - `amounts` must be non-empty and each element cannot execeed the withdrawable amount.
    /// @param streamIds The ids of the streams to withdraw.
    /// @param amounts The amounts to withdraw.
    /// @param to The address that will receive the withdrawn tokens.
    function withdrawAllTo(
        uint256[] calldata streamIds,
        uint256[] calldata amounts,
        address to
    ) external;

    /// @notice Atomically decreases the authorization given by `msg.sender` to `funder` to create streams.
    ///
    /// @dev Emits an {Authorize} event indicating the updated authorization.
    ///
    /// Requirements:
    /// - `funder` cannot be the zero address.
    /// - `funder` must have set an authorization to `msg.sender` of at least `amount`.
    /// @param funder The address of the stream funder.
    /// @param amount The authorization to decrease for creating streams.
    function decreaseAuthorization(address funder, uint256 amount) external;

    /// @notice Atomically increases the authorization to create streams given by `msg.sender` to `funder`.
    ///
    /// @dev Emits an {Authorize} event indicating the updated authorization.
    ///
    /// Requirements:
    /// - `funder` cannot be the zero address.
    /// - The updated authorization cannot overflow uint256.
    /// @param funder The address of the stream funder.
    /// @param amount The authorization that can be used for creating streams.
    function increaseAuthorization(address funder, uint256 amount) external;
}
