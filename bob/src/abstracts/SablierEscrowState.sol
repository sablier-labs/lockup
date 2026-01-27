// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { UD60x18, ud } from "@prb/math/src/UD60x18.sol";
import { Comptrollerable } from "@sablier/evm-utils/src/Comptrollerable.sol";

import { ISablierEscrowState } from "../interfaces/ISablierEscrowState.sol";
import { Errors } from "../libraries/Errors.sol";
import { Escrow } from "../types/Escrow.sol";

/// @title SablierEscrowState
/// @notice Abstract contract containing state variables, modifiers, and view functions for the SablierEscrow contract.
abstract contract SablierEscrowState is Comptrollerable, ISablierEscrowState {
    /*//////////////////////////////////////////////////////////////////////////
                                      CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierEscrowState
    UD60x18 public constant override MAX_FEE = UD60x18.wrap(0.01e18);

    /*//////////////////////////////////////////////////////////////////////////
                                   STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierEscrowState
    uint256 public override nextOrderId;

    /// @inheritdoc ISablierEscrowState
    UD60x18 public override protocolFee;

    /// @dev Orders mapped by order ID.
    mapping(uint256 orderId => Escrow.Order order) internal _orders;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialComptroller The address of the initial comptroller contract.
    constructor(address initialComptroller) Comptrollerable(initialComptroller) {
        // Set the next order ID to 1 (order IDs start from 1).
        nextOrderId = 1;

        // Protocol fee defaults to 0.
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks that `orderId` references an existing order.
    modifier orderExists(uint256 orderId) {
        _orderExists(orderId);
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierEscrowState
    function getOrder(uint256 orderId) external view override orderExists(orderId) returns (Escrow.Order memory order) {
        order = _orders[orderId];
    }

    /// @inheritdoc ISablierEscrowState
    function statusOf(uint256 orderId) external view override orderExists(orderId) returns (Escrow.Status status) {
        status = _statusOf(orderId);
    }

    /// @inheritdoc ISablierEscrowState
    function wasAccepted(uint256 orderId) external view override orderExists(orderId) returns (bool result) {
        result = _orders[orderId].wasAccepted;
    }

    /// @inheritdoc ISablierEscrowState
    function wasCanceled(uint256 orderId) external view override orderExists(orderId) returns (bool result) {
        result = _orders[orderId].wasCanceled;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Derives the current status of an order from boolean flags and timestamps.
    function _statusOf(uint256 orderId) internal view returns (Escrow.Status) {
        Escrow.Order storage order = _orders[orderId];

        if (order.wasAccepted) {
            return Escrow.Status.COMPLETED;
        }
        if (order.wasCanceled) {
            return Escrow.Status.CANCELLED;
        }
        if (block.timestamp >= order.expiry) {
            return Escrow.Status.EXPIRED;
        }
        return Escrow.Status.OPEN;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PRIVATE READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Reverts if `orderId` references a non-existent order.
    /// @dev A private function is used instead of inlining this logic in a modifier because Solidity copies modifiers
    /// into every function that uses them.
    function _orderExists(uint256 orderId) private view {
        // An order is considered non-existent if its seller address is zero (seller is always set on creation).
        if (_orders[orderId].seller == address(0)) {
            revert Errors.SablierEscrow_OrderNotFound(orderId);
        }
    }
}
