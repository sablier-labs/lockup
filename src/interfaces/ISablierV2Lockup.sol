// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.13;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { IERC721Metadata } from "@openzeppelin/token/ERC721/extensions/IERC721Metadata.sol";

import { Lockup } from "../types/DataTypes.sol";
import { ISablierV2Base } from "./ISablierV2Base.sol";
import { ISablierV2NFTDescriptor } from "./ISablierV2NFTDescriptor.sol";

/// @title ISablierV2Lockup
/// @notice The common interface between all Sablier V2 lockup streaming contracts.
interface ISablierV2Lockup is
    ISablierV2Base, // no dependencies
    IERC721Metadata // two dependencies
{
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a stream is canceled.
    /// @param streamId The id of the stream.
    /// @param sender The address of the stream's sender.
    /// @param recipient The address of the stream's recipient.
    /// @param senderAmount The amount of assets returned to the sender, denoted in units of the asset's decimals.
    /// @param recipientAmount The amount of assets left to be withdrawn by the recipient, denoted in units of the
    /// asset's decimals.
    event CancelLockupStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint128 senderAmount,
        uint128 recipientAmount
    );

    /// @notice Emitted when a sender makes a stream non-cancelable.
    /// @param streamId The id of the stream.
    event RenounceLockupStream(uint256 indexed streamId);

    /// @notice Emitted when the admin sets a new NFT descriptor contract.
    /// @param admin The address of the current contract admin.
    /// @param oldNFTDescriptor The address of the old NFT descriptor contract.
    /// @param newNFTDescriptor The address of the new NFT descriptor contract.
    event SetNFTDescriptor(
        address indexed admin, ISablierV2NFTDescriptor oldNFTDescriptor, ISablierV2NFTDescriptor newNFTDescriptor
    );

    /// @notice Emitted when assets are withdrawn from a stream.
    /// @param streamId The id of the stream.
    /// @param to The address that has received the withdrawn assets.
    /// @param amount The amount of assets withdrawn, denoted in units of the asset's decimals.
    event WithdrawFromLockupStream(uint256 indexed streamId, address indexed to, uint128 amount);

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the address of the ERC-20 asset used for streaming.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream id for the query.
    function getAsset(uint256 streamId) external view returns (IERC20 asset);

    /// @notice Retrieves the amount deposited in the stream, denoted in units of the asset's decimals.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream id for the query.
    function getDepositedAmount(uint256 streamId) external view returns (uint128 depositedAmount);

    /// @notice Retrieves the stream's end time, which is a Unix timestamp.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream id for the query.
    function getEndTime(uint256 streamId) external view returns (uint40 endTime);

    /// @notice Retrieves the stream's recipient.
    /// @dev Reverts if the NFT has been burned.
    /// @param streamId The stream id for the query.
    function getRecipient(uint256 streamId) external view returns (address recipient);

    /// @notice Retrieves the amount returned to the sender, denoted in units of the asset's decimals. This amount is
    /// always zero unless the stream is canceled.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream id for the query.
    function getReturnedAmount(uint256 streamId) external view returns (uint128 returnedAmount);

    /// @notice Retrieves the stream's sender.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream id for the query.
    function getSender(uint256 streamId) external view returns (address sender);

    /// @notice Retrieves the stream's start time, which is a Unix timestamp.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream id for the query.
    function getStartTime(uint256 streamId) external view returns (uint40 startTime);

    /// @notice Retrieves the stream's status.
    /// @param streamId The stream id for the query.
    function getStatus(uint256 streamId) external view returns (Lockup.Status status);

    /// @notice Retrieves the amount withdrawn from the stream, denoted in units of the asset's decimals.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream id for the query.
    function getWithdrawnAmount(uint256 streamId) external view returns (uint128 withdrawnAmount);

    /// @notice Determines whether the stream is cancelable. Always returns `false` when the stream is not active.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream id for the query.
    function isCancelable(uint256 streamId) external view returns (bool result);

    /// @notice Counter for stream ids, used in the create functions.
    function nextStreamId() external view returns (uint256);

    /// @notice Calculates the amount that the sender would receive if the stream were canceled, denoted in units
    /// of the asset's decimals.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream id for the query.
    function returnableAmountOf(uint256 streamId) external view returns (uint128 returnableAmount);

    /// @notice Calculates the amount streamed to the recipient, denoted in units of the asset's decimals.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream id for the query.
    function streamedAmountOf(uint256 streamId) external view returns (uint128 streamedAmount);

    /// @notice Calculates the amount that the recipient can withdraw from the stream, denoted in units of the asset's
    /// decimals.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream id for the query.
    function withdrawableAmountOf(uint256 streamId) external view returns (uint128 withdrawableAmount);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Burns the NFT associated with the stream.
    ///
    /// @dev Emits a {Transfer} event.
    ///
    /// Requirements:
    /// - The call must not be a delegate call.
    /// - `streamId` must reference a depleted stream.
    /// - The NFT must exist.
    /// - `msg.sender` must be either the NFT owner or an approved third party.
    ///
    /// @param streamId The id of the stream NFT to burn.
    function burn(uint256 streamId) external;

    /// @notice Cancels the stream and transfers any remaining assets to the sender.
    ///
    /// @dev Emits a {CancelLockupStream} event and a {Transfer} event.
    ///
    /// Notes:
    /// - This function will attempt to call a hook on either the sender or the recipient, depending on who
    /// `msg.sender` is, and if the resolved address is a contract.
    ///
    /// Requirements:
    /// - The call must not be a delegate call.
    /// - The stream must be active, cancelable, and not settled.
    /// - `msg.sender` must be either the sender or the stream's recipient (a.k.a the NFT owner).
    ///
    /// @param streamId The id of the stream to cancel.
    function cancel(uint256 streamId) external;

    /// @notice Cancels multiple streams and transfers any remaining assets to the sender.
    ///
    /// @dev Emits multiple {CancelLockupStream} and {Transfer} events.
    ///
    /// Notes:
    /// - This function will attempt to call a hook on either the sender or the recipient of each stream.
    ///
    /// Requirements:
    /// - The call must not be a delegate call.
    /// - Each value in `streamIds` must reference a stream that is active, cancelable, and not settled.
    /// - `msg.sender` must be either the sender or the recipient of each stream.
    ///
    /// @param streamIds The ids of the streams to cancel.
    function cancelMultiple(uint256[] calldata streamIds) external;

    /// @notice Makes the stream non-cancelable.
    ///
    /// @dev Emits a {RenounceLockupStream} event.
    ///
    /// Notes:
    /// - This is an irreversible operation.
    /// - This function will attempt to call a hook on the stream's recipient, if the recipient is a contract.
    ///
    /// Requirements:
    /// - The call must not be a delegate call.
    /// - `streamId` must reference an active stream.
    /// - `msg.sender` must be the stream's sender.
    /// - The stream must be cancelable.
    ///
    /// @param streamId The id of the stream to renounce.
    function renounce(uint256 streamId) external;

    /// @notice Sets a new NFT descriptor contract, which produces the URI describing the Sablier stream NFTs.
    ///
    /// @dev Emits a {SetNFTDescriptor} event.
    ///
    /// Notes:
    /// - Does not revert if the NFT descriptor is the same.
    ///
    /// Requirements:
    /// - `msg.sender` must be the contract admin.
    ///
    /// @param newNFTDescriptor The address of the new NFT descriptor contract.
    function setNFTDescriptor(ISablierV2NFTDescriptor newNFTDescriptor) external;

    /// @notice Withdraws the provided amount of assets from the stream to the specified address `to`.
    ///
    /// @dev Emits a {WithdrawFromLockupStream} and a {Transfer} event.
    ///
    /// Notes:
    /// - This function will attempt to call a hook on the recipient of the stream, if the recipient is a contract,
    /// and if the caller is either the sender or an approved operator.
    ///
    /// Requirements:
    /// - The call must not be a delegate call.
    /// - `streamId` must reference a stream that is either active or canceled.
    /// - `msg.sender` must be the stream's sender, the stream's recipient or an
    /// approved third party.
    /// - `to` must be the recipient if `msg.sender` is the sender of the stream.
    /// - `to` must not be the zero address.
    /// - `amount` must be greater than zero and must not exceed the withdrawable amount.
    ///
    /// @param streamId The id of the stream to withdraw from.
    /// @param to The address that receives the withdrawn assets.
    /// @param amount The amount to withdraw, denoted in units of the asset's decimals.
    function withdraw(uint256 streamId, address to, uint128 amount) external;

    /// @notice Withdraws the maximum withdrawable amount from the stream to the specified address `to`.
    ///
    /// @dev Emits a {WithdrawFromLockupStream} and a {Transfer} event.
    ///
    /// Notes:
    /// - All from {withdraw}.
    ///
    /// Requirements:
    /// - All from {withdraw}.
    ///
    /// @param streamId The id of the stream to withdraw from.
    /// @param to The address that receives the withdrawn assets.
    function withdrawMax(uint256 streamId, address to) external;

    /// @notice Withdraws assets from streams to the provided address `to`.
    ///
    /// @dev Emits multiple {WithdrawFromLockupStream} and {Transfer} events.
    ///
    /// Notes:
    /// - This function will attempt to call a hook on the recipient of each stream,
    /// unless the caller is the recipient.
    ///
    /// Requirements:
    /// - The call must not be a delegate call.
    /// - `to` must not be the zero address.
    /// - There must be an equal number of `streamIds` and `amounts`.
    /// - `msg.sender` must be either the recipient or an approved third party of each stream.
    /// - Each value in `streamId` must reference a stream that is neither null nor depleted.
    /// - Each value in `amounts` must be greater than zero and must not exceed the corresponding maximum withdrawable
    /// amount.
    ///
    /// @param streamIds The ids of the streams to withdraw from.
    /// @param to The address that receives the withdrawn assets.
    /// @param amounts The amounts to withdraw, denoted in units of the asset's decimals.
    function withdrawMultiple(uint256[] calldata streamIds, address to, uint128[] calldata amounts) external;
}
