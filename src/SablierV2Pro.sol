// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SafeERC20 } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { PRBMathCastingUint128 as CastingUint128 } from "@prb/math/casting/Uint128.sol";
import { PRBMathCastingUint40 as CastingUint40 } from "@prb/math/casting/Uint40.sol";
import { sd, SD59x18 } from "@prb/math/SD59x18.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { ISablierV2 } from "./interfaces/ISablierV2.sol";
import { ISablierV2Comptroller } from "./interfaces/ISablierV2Comptroller.sol";
import { ISablierV2Pro } from "./interfaces/ISablierV2Pro.sol";
import { ISablierV2Recipient } from "./interfaces/hooks/ISablierV2Recipient.sol";
import { ISablierV2Sender } from "./interfaces/hooks/ISablierV2Sender.sol";
import { Errors } from "./libraries/Errors.sol";
import { Events } from "./libraries/Events.sol";
import { Helpers } from "./libraries/Helpers.sol";
import { Status } from "./types/Enums.sol";
import { Broker, CreateAmounts, ProStream, Segment } from "./types/Structs.sol";
import { SablierV2 } from "./SablierV2.sol";

/// @title SablierV2Pro
/// @dev This contract implements the ISablierV2Pro interface.
contract SablierV2Pro is
    ISablierV2Pro, // one dependency
    SablierV2, // two dependencies
    ERC721("Sablier V2 Pro NFT", "SAB-V2-PRO") // six dependencies
{
    using CastingUint128 for uint128;
    using CastingUint40 for uint40;
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                      CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Pro
    uint256 public immutable override MAX_SEGMENT_COUNT;

    /*//////////////////////////////////////////////////////////////////////////
                                  INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Sablier V2 pro streams mapped by unsigned integers.
    mapping(uint256 => ProStream) internal _streams;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialAdmin The address of the initial contract admin.
    /// @param initialComptroller The address of the initial comptroller.
    /// @param maxFee The maximum fee that can be charged by either the protocol or a broker, as an UD60x18 number
    /// where 100% = 1e18.
    /// @param maxSegmentCount The maximum number of segments permitted in a stream.
    constructor(
        address initialAdmin,
        ISablierV2Comptroller initialComptroller,
        UD60x18 maxFee,
        uint256 maxSegmentCount
    ) SablierV2(initialAdmin, initialComptroller, maxFee) {
        MAX_SEGMENT_COUNT = maxSegmentCount;
    }

    /*//////////////////////////////////////////////////////////////////////////
                              PUBLIC CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2
    function getDepositAmount(uint256 streamId) external view override returns (uint128 depositAmount) {
        depositAmount = _streams[streamId].amounts.deposit;
    }

    /// @inheritdoc ISablierV2
    function getERC20Token(uint256 streamId) external view override returns (IERC20 token) {
        token = _streams[streamId].token;
    }

    /// @inheritdoc ISablierV2
    function getRecipient(uint256 streamId) public view override(ISablierV2, SablierV2) returns (address recipient) {
        recipient = _ownerOf(streamId);
    }

    /// @inheritdoc ISablierV2
    function getReturnableAmount(uint256 streamId) external view returns (uint128 returnableAmount) {
        // If the stream is null, return zero.
        if (_streams[streamId].status == Status.NULL) {
            return 0;
        }

        // No need for an assertion here, since the `getStreamedAmount` function checks that the deposit amount
        // is greater than or equal to the streamed amount.
        unchecked {
            returnableAmount = _streams[streamId].amounts.deposit - getStreamedAmount(streamId);
        }
    }

    /// @inheritdoc ISablierV2Pro
    function getSegments(uint256 streamId) external view override returns (Segment[] memory segments) {
        segments = _streams[streamId].segments;
    }

    /// @inheritdoc ISablierV2
    function getSender(uint256 streamId) external view override returns (address sender) {
        sender = _streams[streamId].sender;
    }

    /// @inheritdoc ISablierV2
    function getStartTime(uint256 streamId) external view override returns (uint40 startTime) {
        startTime = _streams[streamId].startTime;
    }

    /// @inheritdoc ISablierV2
    function getStatus(uint256 streamId) public view virtual override(ISablierV2, SablierV2) returns (Status status) {
        status = _streams[streamId].status;
    }

    /// @inheritdoc ISablierV2
    function getStopTime(uint256 streamId) external view override returns (uint40 stopTime) {
        stopTime = _streams[streamId].stopTime;
    }

    /// @inheritdoc ISablierV2Pro
    function getStream(uint256 streamId) external view returns (ProStream memory stream) {
        stream = _streams[streamId];
    }

    /// @inheritdoc ISablierV2
    function getStreamedAmount(uint256 streamId) public view override returns (uint128 streamedAmount) {
        // If the stream is null, return zero.
        if (_streams[streamId].status == Status.NULL) {
            return 0;
        }

        // If the start time is greater than or equal to the block timestamp, return zero.
        uint40 currentTime = uint40(block.timestamp);
        if (_streams[streamId].startTime >= currentTime) {
            return 0;
        }

        uint256 segmentCount = _streams[streamId].segments.length;
        uint40 stopTime = _streams[streamId].stopTime;

        // If the current time is greater than or equal to the stop time, we simply return the deposit minus
        // the withdrawn amount.
        if (currentTime >= stopTime) {
            return _streams[streamId].amounts.deposit;
        }

        if (segmentCount > 1) {
            // If there's more than one segment, we have to iterate over all of them.
            streamedAmount = _calculateStreamedAmountForMultipleSegments(streamId);
        } else {
            // Otherwise, there is only one segment, and the calculation is simple.
            streamedAmount = _calculateStreamedAmountForOneSegment(streamId);
        }
    }

    /// @inheritdoc ISablierV2
    function getWithdrawableAmount(
        uint256 streamId
    ) public view override(ISablierV2, SablierV2) returns (uint128 withdrawableAmount) {
        unchecked {
            withdrawableAmount = getStreamedAmount(streamId) - _streams[streamId].amounts.withdrawn;
        }
    }

    /// @inheritdoc ISablierV2
    function getWithdrawnAmount(uint256 streamId) external view override returns (uint128 withdrawnAmount) {
        withdrawnAmount = _streams[streamId].amounts.withdrawn;
    }

    /// @inheritdoc ISablierV2
    function isCancelable(uint256 streamId) public view override(ISablierV2, SablierV2) returns (bool result) {
        if (_streams[streamId].status != Status.ACTIVE) {
            return false;
        }
        result = _streams[streamId].isCancelable;
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256 streamId) public pure override returns (string memory uri) {
        streamId;
        uri = "";
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PUBLIC NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Pro
    function createWithDeltas(
        address sender,
        address recipient,
        uint128 grossDepositAmount,
        Segment[] memory segments,
        IERC20 token,
        bool cancelable,
        uint40[] calldata deltas,
        Broker calldata broker
    ) external override returns (uint256 streamId) {
        // Checks: check the deltas and adjust the segments accordingly.
        Helpers.checkDeltasAndAdjustSegments(segments, deltas);

        // Safe Interactions: query the protocol fee. This is safe because we are querying a Sablier contract.
        UD60x18 protocolFee = comptroller.getProtocolFee(token);

        // Checks: check the fees and calculate the fee amounts.
        CreateAmounts memory amounts = Helpers.checkAndCalculateFees(
            grossDepositAmount,
            protocolFee,
            broker.fee,
            MAX_FEE
        );

        // Checks, Effects and Interactions: create the stream.
        streamId = _createWithMilestones(
            CreateWithMilestonesParams({
                amounts: amounts,
                broker: broker.addr,
                cancelable: cancelable,
                recipient: recipient,
                segments: segments,
                sender: sender,
                token: token,
                startTime: uint40(block.timestamp)
            })
        );
    }

    /// @inheritdoc ISablierV2Pro
    function createWithMilestones(
        address sender,
        address recipient,
        uint128 grossDepositAmount,
        Segment[] calldata segments,
        IERC20 token,
        bool cancelable,
        uint40 startTime,
        Broker calldata broker
    ) external returns (uint256 streamId) {
        // Safe Interactions: query the protocol fee. This is safe because we are querying a Sablier contract.
        UD60x18 protocolFee = comptroller.getProtocolFee(token);

        // Checks: check the fees and calculate the fee amounts.
        CreateAmounts memory amounts = Helpers.checkAndCalculateFees(
            grossDepositAmount,
            protocolFee,
            broker.fee,
            MAX_FEE
        );

        // Checks, Effects and Interactions: create the stream.
        streamId = _createWithMilestones(
            CreateWithMilestonesParams({
                amounts: amounts,
                broker: broker.addr,
                cancelable: cancelable,
                recipient: recipient,
                segments: segments,
                sender: sender,
                token: token,
                startTime: startTime
            })
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                             INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Calculates the withdrawable amount for a stream with multiple segments.
    function _calculateStreamedAmountForMultipleSegments(
        uint256 streamId
    ) internal view returns (uint128 streamedAmount) {
        unchecked {
            uint40 currentTime = uint40(block.timestamp);

            // Sum up the amounts found in all preceding segments.
            uint128 previousSegmentAmounts;
            uint40 currentSegmentMilestone = _streams[streamId].segments[0].milestone;
            uint256 index = 1;

            // Important: this function must be called only after checking that the current time is less than the last
            // segment's milestone, lest the loop below encounters an "index out of bounds" error.
            while (currentSegmentMilestone < currentTime) {
                previousSegmentAmounts += _streams[streamId].segments[index - 1].amount;
                currentSegmentMilestone = _streams[streamId].segments[index].milestone;
                index += 1;
            }

            // After the loop exits, the current segment is found at index `index - 1`, whereas the previous segment
            // is found at `index - 2` (if there are at least two segments).
            SD59x18 currentSegmentAmount = _streams[streamId].segments[index - 1].amount.intoSD59x18();
            SD59x18 currentSegmentExponent = _streams[streamId].segments[index - 1].exponent.intoSD59x18();
            currentSegmentMilestone = _streams[streamId].segments[index - 1].milestone;

            uint40 previousMilestone;
            if (index > 1) {
                // If the current segment is at an index that is >= 2, we use the previous segment's milestone.
                previousMilestone = _streams[streamId].segments[index - 2].milestone;
            } else {
                // Otherwise, there is only one segment, so we use the start of the stream as the previous milestone.
                previousMilestone = _streams[streamId].startTime;
            }

            // Calculate how much time has elapsed since the segment started, and the total time of the segment.
            SD59x18 elapsedSegmentTime = (currentTime - previousMilestone).intoSD59x18();
            SD59x18 totalSegmentTime = (currentSegmentMilestone - previousMilestone).intoSD59x18();

            // Calculate the streamed amount.
            SD59x18 elapsedSegmentTimePercentage = elapsedSegmentTime.div(totalSegmentTime);
            SD59x18 multiplier = elapsedSegmentTimePercentage.pow(currentSegmentExponent);
            SD59x18 segmentStreamedAmount = multiplier.mul(currentSegmentAmount);

            // Assert that the streamed amount is lower than or equal to the current segment amount.
            assert(segmentStreamedAmount.lte(currentSegmentAmount));

            // Finally, calculate the streamed amount by adding up the previous segment amounts and the amount
            // streamed in this segment. Casting to uint128 is safe thanks to the assertion above.
            streamedAmount = previousSegmentAmounts + uint128(segmentStreamedAmount.intoUint256());
        }
    }

    /// @dev Calculates the withdrawable amount for a stream with one segment.
    function _calculateStreamedAmountForOneSegment(uint256 streamId) internal view returns (uint128 streamedAmount) {
        unchecked {
            // Load the stream fields as SD59x18 numbers.
            SD59x18 depositAmount = _streams[streamId].amounts.deposit.intoSD59x18();
            SD59x18 exponent = _streams[streamId].segments[0].exponent.intoSD59x18();

            // Calculate how much time has elapsed since the stream started, and the total time of the stream.
            SD59x18 elapsedTime = (uint40(block.timestamp) - _streams[streamId].startTime).intoSD59x18();
            SD59x18 totalTime = (_streams[streamId].stopTime - _streams[streamId].startTime).intoSD59x18();

            // Calculate the streamed amount.
            SD59x18 elapsedTimePercentage = elapsedTime.div(totalTime);
            SD59x18 multiplier = elapsedTimePercentage.pow(exponent);
            SD59x18 streamedAmountUd = multiplier.mul(depositAmount);

            // Assert that the streamed amount is lower than or equal to the deposit amount.
            assert(streamedAmountUd.lte(depositAmount));

            // Casting to uint128 is safe thanks for the assertion above.
            streamedAmount = uint128(streamedAmountUd.intoUint256());
        }
    }

    /// @inheritdoc SablierV2
    function _isApprovedOrOwner(
        uint256 streamId,
        address spender
    ) internal view override returns (bool isApprovedOrOwner) {
        address owner = _ownerOf(streamId);
        isApprovedOrOwner = (spender == owner || isApprovedForAll(owner, spender) || getApproved(streamId) == spender);
    }

    /// @inheritdoc SablierV2
    function _isCallerStreamSender(uint256 streamId) internal view override returns (bool result) {
        result = msg.sender == _streams[streamId].sender;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the public functions that call this internal function.
    function _burn(uint256 tokenId) internal override(ERC721, SablierV2) {
        ERC721._burn(tokenId);
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _cancel(uint256 streamId) internal override onlySenderOrRecipient(streamId) {
        ProStream memory stream = _streams[streamId];

        // Calculate the recipient's and the sender's amount.
        uint128 recipientAmount = getWithdrawableAmount(streamId);
        uint128 senderAmount;
        unchecked {
            senderAmount = stream.amounts.deposit - stream.amounts.withdrawn - recipientAmount;
        }

        // Load the sender and the recipient in memory, we will need them below.
        address sender = _streams[streamId].sender;
        address recipient = _ownerOf(streamId);

        // Effects: mark the stream as canceled.
        _streams[streamId].status = Status.CANCELED;

        if (recipientAmount > 0) {
            // Effects: add the recipient's amount to the withdrawn amount.
            unchecked {
                _streams[streamId].amounts.withdrawn += recipientAmount;
            }

            // Interactions: withdraw the tokens to the recipient.
            stream.token.safeTransfer({ to: recipient, amount: recipientAmount });
        }

        // Interactions: return the tokens to the sender, if any.
        if (senderAmount > 0) {
            stream.token.safeTransfer({ to: sender, amount: senderAmount });
        }

        // Interactions: if the `msg.sender` is the sender and the recipient is a contract, try to invoke the cancel
        // hook on the recipient without reverting if the hook is not implemented, and without bubbling up any
        // potential revert.
        if (msg.sender == sender) {
            if (recipient.code.length > 0) {
                try
                    ISablierV2Recipient(recipient).onStreamCanceled({
                        streamId: streamId,
                        caller: msg.sender,
                        recipientAmount: recipientAmount,
                        senderAmount: senderAmount
                    })
                {} catch {}
            }
        }
        // Interactions: if the `msg.sender` is the recipient and the sender is a contract, try to invoke the cancel
        // hook on the sender without reverting if the hook is not implemented, and also without bubbling up any
        // potential revert.
        else {
            if (sender.code.length > 0) {
                try
                    ISablierV2Sender(sender).onStreamCanceled({
                        streamId: streamId,
                        caller: msg.sender,
                        recipientAmount: recipientAmount,
                        senderAmount: senderAmount
                    })
                {} catch {}
            }
        }

        // Emit an event.
        emit Events.Cancel(streamId, sender, recipient, senderAmount, recipientAmount);
    }

    /// @dev This struct is needed to avoid the "Stack Too Deep" error.
    struct CreateWithMilestonesParams {
        CreateAmounts amounts;
        Segment[] segments;
        address sender; // ──┐
        uint40 startTime; // │
        bool cancelable; // ─┘
        address recipient;
        IERC20 token;
        address broker;
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _createWithMilestones(CreateWithMilestonesParams memory params) internal returns (uint256 streamId) {
        // Checks: validate the arguments.
        Helpers.checkCreateProParams(params.amounts.netDeposit, params.segments, MAX_SEGMENT_COUNT, params.startTime);

        // Load the stream id.
        streamId = nextStreamId;

        // Load the segment count.
        uint256 segmentCount = params.segments.length;

        // Effects: create the stream.
        ProStream storage stream = _streams[streamId];
        stream.amounts.deposit = params.amounts.netDeposit;
        stream.isCancelable = params.cancelable;
        stream.sender = params.sender;
        stream.startTime = params.startTime;
        stream.status = Status.ACTIVE;
        stream.stopTime = params.segments[segmentCount - 1].milestone;
        stream.token = params.token;

        unchecked {
            // Effects: store the segments. Copying an array from memory to storage is not currently supported in
            // Solidity, so we have to do it manually. See https://github.com/ethereum/solidity/issues/12783
            for (uint256 i = 0; i < segmentCount; ++i) {
                stream.segments.push(params.segments[i]);
            }

            // Effects: bump the next stream id and record the protocol fee.
            // We're using unchecked arithmetic here because theses calculations cannot realistically overflow, ever.
            nextStreamId = streamId + 1;
            _protocolRevenues[params.token] += params.amounts.protocolFee;
        }

        // Effects: mint the NFT to the recipient.
        _mint({ to: params.recipient, tokenId: streamId });

        // Interactions: perform the ERC-20 transfer to deposit the gross amount of tokens.
        params.token.safeTransferFrom({ from: msg.sender, to: address(this), amount: params.amounts.netDeposit });

        // Interactions: perform the ERC-20 transfer to pay the broker fee, if not zero.
        if (params.amounts.brokerFee > 0) {
            params.token.safeTransferFrom({ from: msg.sender, to: params.broker, amount: params.amounts.brokerFee });
        }

        // Emit an event.
        emit Events.CreateProStream({
            streamId: streamId,
            funder: msg.sender,
            sender: params.sender,
            recipient: params.recipient,
            amounts: params.amounts,
            segments: params.segments,
            token: params.token,
            cancelable: params.cancelable,
            startTime: params.startTime,
            stopTime: stream.stopTime,
            broker: params.broker
        });
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _renounce(uint256 streamId) internal override {
        // Effects: make the stream non-cancelable.
        _streams[streamId].isCancelable = false;

        // Emit an event.
        emit Events.Renounce(streamId);
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _withdraw(uint256 streamId, address to, uint128 amount) internal override {
        // Checks: the amount is not zero.
        if (amount == 0) {
            revert Errors.SablierV2_WithdrawAmountZero(streamId);
        }

        // Checks: the amount is not greater than what can be withdrawn.
        uint128 withdrawableAmount = getWithdrawableAmount(streamId);
        if (amount > withdrawableAmount) {
            revert Errors.SablierV2_WithdrawAmountGreaterThanWithdrawableAmount(streamId, amount, withdrawableAmount);
        }

        // Effects: update the withdrawn amount.
        unchecked {
            _streams[streamId].amounts.withdrawn += amount;
        }

        // Load the stream and the recipient in memory, we will need them below.
        ProStream memory stream = _streams[streamId];
        address recipient = _ownerOf(streamId);

        // Assert that the withdrawn amount is greater than or equal to the deposit amount.
        assert(stream.amounts.deposit >= stream.amounts.withdrawn);

        // Effects: if the entire deposit amount is now withdrawn, we mark the stream as depleted.
        if (stream.amounts.deposit == stream.amounts.withdrawn) {
            _streams[streamId].status = Status.DEPLETED;
        }

        // Interactions: perform the ERC-20 transfer.
        stream.token.safeTransfer({ to: to, amount: amount });

        // Interactions: if the `msg.sender` is not the recipient and the recipient is a contract, try to invoke the
        // withdraw hook on it without reverting if the hook is not implemented, and also without bubbling up
        // any potential revert.
        if (msg.sender != recipient && recipient.code.length > 0) {
            try
                ISablierV2Recipient(recipient).onStreamWithdrawn({
                    streamId: streamId,
                    caller: msg.sender,
                    amount: amount
                })
            {} catch {}
        }

        // Emit an event.
        emit Events.Withdraw(streamId, to, amount);
    }
}
