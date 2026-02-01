// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { NoDelegateCall } from "@sablier/evm-utils/src/NoDelegateCall.sol";

import { ISablierLockupPriceGated } from "../interfaces/ISablierLockupPriceGated.sol";
import { Errors } from "../libraries/Errors.sol";
import { LockupHelpers } from "../libraries/LockupHelpers.sol";
import { Lockup } from "../types/Lockup.sol";
import { LockupPriceGated } from "../types/LockupPriceGated.sol";
import { SablierLockupState } from "./SablierLockupState.sol";

/// @title SablierLockupPriceGated
/// @notice See the documentation in {ISablierLockupPriceGated}.
abstract contract SablierLockupPriceGated is
    ISablierLockupPriceGated, // 1 inherited component
    NoDelegateCall, // 0 inherited components
    SablierLockupState // 1 inherited component
{
    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierLockupPriceGated
    function createWithDurationsLPG(
        Lockup.CreateWithDurations calldata params,
        AggregatorV3Interface oracle,
        uint128 targetPrice,
        uint40 duration
    )
        external
        payable
        override
        noDelegateCall
        returns (uint256 streamId)
    {
        // Check: validate that the oracle implements the {AggregatorV3Interface} interface.
        uint128 latestPrice = LockupHelpers.validateOracle(oracle);

        // Check: the target price is greater than the latest price.
        if (targetPrice <= latestPrice) revert Errors.SablierLockup_TargetPriceTooLow();

        // Checks, Effects and Interactions: create the stream.
        streamId = _createLPG(params, oracle, targetPrice, duration);
    }

    /*//////////////////////////////////////////////////////////////////////////
                          PRIVATE STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the user-facing functions that call this private function.
    function _createLPG(
        Lockup.CreateWithDurations calldata params,
        AggregatorV3Interface oracle,
        uint128 targetPrice,
        uint40 duration
    )
        private
        returns (uint256 streamId)
    {
        // Set timestamps.
        Lockup.Timestamps memory timestamps =
            Lockup.Timestamps({ start: uint40(block.timestamp), end: uint40(block.timestamp) + duration });

        // Check: validate the user-provided parameters.
        LockupHelpers.checkCreateLPG(
            params.sender, timestamps, params.depositAmount, address(params.token), nativeToken, params.shape
        );

        // Load the stream ID in a variable.
        streamId = nextStreamId;

        // Effect: store unlock params.
        _priceGatedUnlockParams[streamId] = LockupPriceGated.UnlockParams(oracle, targetPrice);

        // Effect: create the stream, mint the NFT and transfer the deposit amount.
        _create({
            cancelable: params.cancelable,
            depositAmount: params.depositAmount,
            lockupModel: Lockup.Model.LOCKUP_PRICE_GATED,
            recipient: params.recipient,
            sender: params.sender,
            streamId: streamId,
            timestamps: timestamps,
            token: params.token,
            transferable: params.transferable
        });

        // Log the newly created stream.
        emit CreateLockupPriceGatedStream(streamId, oracle, targetPrice);
    }
}
