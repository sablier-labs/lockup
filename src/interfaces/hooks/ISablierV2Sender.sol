// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

/// @title ISablierV2Sender
/// @notice Interface for sender contracts capable of reacting to withdrawals.
/// @dev Implementation of this interface is optional. If a sender contract doesn't implement this
/// interface or implements it partially, function execution will not revert.
interface ISablierV2Sender {
    /// @notice Responds to withdrawals triggered by either the stream's recipient or an approved third party.
    ///
    /// @dev Notes:
    /// - This function may revert, but the Sablier contract will ignore the revert.
    ///
    /// @param streamId The id of the stream being withdrawn from.
    /// @param caller The original `msg.sender` address that triggered the withdrawal.
    /// @param to The address receiving the withdrawn assets.
    /// @param amount The amount of assets withdrawn, denoted in units of the asset's decimals.
    function onLockupStreamWithdrawn(uint256 streamId, address caller, address to, uint128 amount) external;
}
