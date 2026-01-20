// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { NoDelegateCall } from "@sablier/evm-utils/src/NoDelegateCall.sol";

import { ISablierLockupLinear } from "../interfaces/ISablierLockupLinear.sol";
import { Helpers } from "../libraries/Helpers.sol";
import { Lockup } from "../types/Lockup.sol";
import { LockupLinear } from "../types/LockupLinear.sol";
import { SablierLockupState } from "./SablierLockupState.sol";

/// @title SablierLockupLinear
/// @notice See the documentation in {ISablierLockupLinear}.
abstract contract SablierLockupLinear is
    ISablierLockupLinear, // 1 inherited component
    NoDelegateCall, // 0 inherited components
    SablierLockupState // 1 inherited component
{
    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierLockupLinear
    function createWithDurationsLL(
        Lockup.CreateWithDurations calldata params,
        LockupLinear.UnlockAmounts calldata unlockAmounts,
        uint40 granularity,
        LockupLinear.Durations calldata durations
    )
        external
        payable
        override
        noDelegateCall
        returns (uint256 streamId)
    {
        // Set the current block timestamp as the stream's start time.
        Lockup.Timestamps memory timestamps = Lockup.Timestamps({ start: uint40(block.timestamp), end: 0 });

        uint40 cliffTime;

        // Calculate the cliff time and the end time.
        if (durations.cliff > 0) {
            cliffTime = timestamps.start + durations.cliff;
        }
        timestamps.end = timestamps.start + durations.total;

        // Checks, Effects and Interactions: create the stream.
        streamId = _createLL({
            cancelable: params.cancelable,
            cliffTime: cliffTime,
            depositAmount: params.depositAmount,
            recipient: params.recipient,
            sender: params.sender,
            shape: params.shape,
            timestamps: timestamps,
            token: params.token,
            transferable: params.transferable,
            unlockAmounts: unlockAmounts,
            granularity: granularity
        });
    }

    /// @inheritdoc ISablierLockupLinear
    function createWithTimestampsLL(
        Lockup.CreateWithTimestamps calldata params,
        LockupLinear.UnlockAmounts calldata unlockAmounts,
        uint40 granularity,
        uint40 cliffTime
    )
        external
        payable
        override
        noDelegateCall
        returns (uint256 streamId)
    {
        // Checks, Effects and Interactions: create the stream.
        streamId = _createLL({
            cancelable: params.cancelable,
            cliffTime: cliffTime,
            depositAmount: params.depositAmount,
            recipient: params.recipient,
            sender: params.sender,
            shape: params.shape,
            timestamps: params.timestamps,
            token: params.token,
            transferable: params.transferable,
            unlockAmounts: unlockAmounts,
            granularity: granularity
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                          PRIVATE STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the user-facing functions that call this private function.
    function _createLL(
        bool cancelable,
        uint40 cliffTime,
        uint128 depositAmount,
        address recipient,
        address sender,
        string memory shape,
        Lockup.Timestamps memory timestamps,
        IERC20 token,
        bool transferable,
        LockupLinear.UnlockAmounts memory unlockAmounts,
        uint40 granularity
    )
        private
        returns (uint256 streamId)
    {
        // If sentinel value of zero is used for granularity, change it to one second.
        if (granularity == 0) {
            granularity = 1;
        }

        // Check: validate the user-provided parameters.
        Helpers.checkCreateLL({
            cliffTime: cliffTime,
            depositAmount: depositAmount,
            granularity: granularity,
            nativeToken: nativeToken,
            sender: sender,
            shape: shape,
            timestamps: timestamps,
            token: address(token),
            unlockAmounts: unlockAmounts
        });

        // Load the stream ID in a variable.
        streamId = nextStreamId;

        // Effect: update cliff time.
        _cliffs[streamId] = cliffTime;

        // Effect: set the granularity.
        _granularities[streamId] = granularity;

        // Effect: set the start and cliff unlock amounts.
        _unlockAmounts[streamId] = unlockAmounts;

        // Effect: create the stream, mint the NFT and transfer the deposit amount.
        _create({
            cancelable: cancelable,
            depositAmount: depositAmount,
            lockupModel: Lockup.Model.LOCKUP_LINEAR,
            recipient: recipient,
            sender: sender,
            streamId: streamId,
            timestamps: timestamps,
            token: token,
            transferable: transferable
        });

        // Log the newly created stream.
        emit ISablierLockupLinear.CreateLockupLinearStream({
            streamId: streamId,
            commonParams: Lockup.CreateEventCommon({
                funder: msg.sender,
                sender: sender,
                recipient: recipient,
                depositAmount: depositAmount,
                token: token,
                cancelable: cancelable,
                transferable: transferable,
                timestamps: timestamps,
                shape: shape
            }),
            cliffTime: cliffTime,
            granularity: granularity,
            unlockAmounts: unlockAmounts
        });
    }
}
