// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ISablierV2Lockup } from "../../../../src/interfaces/ISablierV2Lockup.sol";
import { ISablierV2LockupRecipient } from "../../../../src/interfaces/hooks/ISablierV2LockupRecipient.sol";

contract GoodRecipient is ISablierV2LockupRecipient {
    function onStreamCanceled(
        ISablierV2Lockup lockup,
        uint256 streamId,
        address sender,
        uint128 senderAmount,
        uint128 recipientAmount
    )
        external
        pure
    {
        lockup;
        streamId;
        sender;
        senderAmount;
        recipientAmount;
    }

    function onStreamRenounced(ISablierV2Lockup lockup, uint256 streamId) external pure {
        lockup;
        streamId;
    }

    function onStreamWithdrawn(
        ISablierV2Lockup lockup,
        uint256 streamId,
        address caller,
        address to,
        uint128 amount
    )
        external
        pure
    {
        lockup;
        streamId;
        caller;
        to;
        amount;
    }
}
