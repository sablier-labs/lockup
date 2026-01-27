// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { Escrow } from "../types/Escrow.sol";

/// @title ISablierEscrowState
/// @notice Interface containing state variables (storage and constants) for the {SablierEscrow} contract, along with
/// their respective getters.
interface ISablierEscrowState {
    /*//////////////////////////////////////////////////////////////////////////
                               USER-FACING CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the maximum protocol fee that can be set (1% = 0.01e18 in UD60x18 format).
    /// @dev In UD60x18 format, 1e18 = 100%, so 0.01e18 = 1%.
    function MAX_FEE() external view returns (UD60x18);

    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the order information for a specific order ID.
    /// @dev Reverts if `orderId` references a non-existent order.
    /// @param orderId The unique identifier of the order.
    /// @return order The order struct containing all configuration and state.
    function getOrder(uint256 orderId) external view returns (Escrow.Order memory order);

    /// @notice Counter for order IDs. It's incremented every time a new order is created.
    function nextOrderId() external view returns (uint256);

    /// @notice Returns the current protocol fee.
    /// @dev The fee is represented as a UD60x18 value where 1e18 = 100%.
    function protocolFee() external view returns (UD60x18);

    /// @notice Returns the current status of an order.
    /// @dev If the order is OPEN but has expired, returns EXPIRED.
    /// Reverts if `orderId` references a non-existent order.
    /// @param orderId The unique identifier of the order.
    /// @return status The current status of the order.
    function statusOf(uint256 orderId) external view returns (Escrow.Status status);

    /// @notice Retrieves a flag indicating whether the order was accepted.
    /// @dev Reverts if `orderId` references a non-existent order.
    /// @param orderId The order ID for the query.
    function wasAccepted(uint256 orderId) external view returns (bool result);

    /// @notice Retrieves a flag indicating whether the order was canceled.
    /// @dev Reverts if `orderId` references a non-existent order.
    /// @param orderId The order ID for the query.
    function wasCanceled(uint256 orderId) external view returns (bool result);
}
