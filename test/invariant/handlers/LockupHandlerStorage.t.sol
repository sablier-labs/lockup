// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

/// @title LockupHandlerStorage
/// @dev Storage contract for the lockup handler streams.
contract LockupHandlerStorage {
    /*//////////////////////////////////////////////////////////////////////////
                               PUBLIC TEST VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint256 public lastStreamId;
    uint128 public returnedAmountsSum;
    mapping(uint256 => address) public streamIdsToRecipients;
    mapping(uint256 => address) public streamIdsToSenders;
    uint256[] public streamIds;

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function addReturnedAmount(uint128 returnedAmount) external {
        returnedAmountsSum += returnedAmount;
    }

    function pushStreamId(uint256 streamId, address sender, address recipient) external {
        // Store the stream id in the ids array and the reverse mappings.
        streamIds.push(streamId);
        streamIdsToSenders[streamId] = sender;
        streamIdsToRecipients[streamId] = recipient;

        // Update the last stream id.
        lastStreamId = streamId;
    }

    function updateRecipient(uint256 streamId, address newRecipient) external {
        streamIdsToRecipients[streamId] = newRecipient;
    }
}
