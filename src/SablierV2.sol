// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { ISablierV2 } from "./interfaces/ISablierV2.sol";

/// @title SablierV2
/// @author Sablier Labs Ltd.
/// @notice Abstract contract implementing common logic.
abstract contract SablierV2 is ISablierV2 {
    /// PUBLIC STORAGE ///

    /// @inheritdoc ISablierV2
    uint256 public override nextStreamId;

    /// INTERNAL STORAGE ///

    /// @dev Mapping from owners to creators to stream creation authorizations.
    mapping(address => mapping(address => uint256)) internal authorizations;

    /// CONSTRUCTOR ///

    constructor() {
        nextStreamId = 1;
    }

    /// CONSTANT FUNCTIONS ///

    /// @inheritdoc ISablierV2
    function getAuthorization(address sender, address funder) external view returns (uint256 authorization) {
        return authorizations[sender][funder];
    }

    /// NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc ISablierV2
    function decreaseAuthorization(address funder, uint256 amount) public virtual override {
        address sender = msg.sender;
        uint256 newAuthorization = authorizations[sender][funder] - amount;
        authorizeInternal(sender, funder, newAuthorization);
    }

    /// @inheritdoc ISablierV2
    function increaseAuthorization(address funder, uint256 amount) public virtual override {
        address sender = msg.sender;
        uint256 newAuthorization = authorizations[sender][funder] + amount;
        authorizeInternal(sender, funder, newAuthorization);
    }

    /// INTERNAL FUNCTIONS ///

    /// @dev See the documentation for the public functions that call this internal function.
    function authorizeInternal(
        address sender,
        address funder,
        uint256 amount
    ) internal virtual {
        // Checks: the would-be stream sender is not the zero address.
        if (sender == address(0)) {
            revert SablierV2__AuthorizeSenderZeroAddress();
        }

        // Checks: the funder is not the zero address.
        if (funder == address(0)) {
            revert SablierV2__AuthorizeFunderZeroAddress();
        }

        // Effects: update the authorization for the given sender and funder pair.
        authorizations[sender][funder] = amount;

        // Emit an event.
        emit Authorize(sender, funder, amount);
    }

    /// HELPER FUNCTION ///

    /// @dev This function checks basic requiremenets for `create` function.
    function checkRequiremenets(
        address sender,
        address recipient,
        uint256 depositAmount,
        uint256 startTime,
        uint256 stopTime
    ) internal pure {
        // Checks: the sender is not the zero address.
        if (sender == address(0)) {
            revert SablierV2__SenderZeroAddress();
        }

        // Checks: the recipient is not the zero address.
        if (recipient == address(0)) {
            revert SablierV2__RecipientZeroAddress();
        }

        // Checks: the deposit amount is not zero.
        if (depositAmount == 0) {
            revert SablierV2__DepositAmountZero();
        }

        // Checks: the start time is not greater than the stop time.
        if (startTime > stopTime) {
            revert SablierV2__StartTimeGreaterThanStopTime(startTime, stopTime);
        }
    }

    /// @dev This function checks if two numbers are equal to each other and greater than zero.
    function checkLengths(uint256 lengthOne, uint256 lengthTwo) internal pure returns (uint256 length) {
        if (lengthOne != lengthTwo) {
            revert SablierV2__ArraysLengthIsNotEqual(lengthOne, lengthTwo);
        }

        if (lengthOne == 0) {
            revert SablierV2__ArrayLengthIsZero(lengthOne);
        }

        length = lengthOne;
    }
}
