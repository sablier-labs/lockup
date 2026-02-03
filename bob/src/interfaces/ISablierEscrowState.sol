// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { Escrow } from "../types/Escrow.sol";

/// @title ISablierEscrowState
/// @notice Interface containing state variables (storage and constants) for the {SablierEscrow} contract, along with
/// their respective getters.
interface ISablierEscrowState {
    /*//////////////////////////////////////////////////////////////////////////
                               USER-FACING CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the maximum trade fee that can be applied, denominated in UD60x18, where 1e18 = 100%.
    function MAX_TRADE_FEE() external view returns (UD60x18);

    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the buyer address for the given order. If its zero address, the order can be filled by any
    /// address.
    /// @dev Reverts if `orderId` references a null order.
    function getBuyer(uint256 orderId) external view returns (address buyer);

    /// @notice Retrieves the address of the ERC-20 token the seller wants to receive.
    /// @dev Reverts if `orderId` references a null order.
    function getBuyToken(uint256 orderId) external view returns (IERC20 buyToken);

    /// @notice Retrieves the time when the order expires and can no longer be filled. Zero is sentinel for orders that
    /// never expire.
    /// @dev Reverts if `orderId` references a null order.
    function getExpireAt(uint256 orderId) external view returns (uint40 expireAt);

    /// @notice Retrieves the minimum amount of buy token the seller is willing to accept.
    /// @dev Reverts if `orderId` references a null order.
    function getMinBuyAmount(uint256 orderId) external view returns (uint128 minBuyAmount);

    /// @notice Retrieves the amount of sell token that the seller is willing to sell.
    /// @dev Reverts if `orderId` references a null order.
    function getSellAmount(uint256 orderId) external view returns (uint128 sellAmount);

    /// @notice Retrieves the address of the seller who created the order.
    /// @dev Reverts if `orderId` references a null order.
    function getSeller(uint256 orderId) external view returns (address seller);

    /// @notice Retrieves the address of the ERC-20 token that the seller is willing to sell.
    /// @dev Reverts if `orderId` references a null order.
    function getSellToken(uint256 orderId) external view returns (IERC20 sellToken);

    /// @notice Counter for order IDs. It's incremented every time a new order is created.
    function nextOrderId() external view returns (uint256);

    /// @notice Returns the status of the order.
    /// @dev Reverts if `orderId` references a null order.
    function statusOf(uint256 orderId) external view returns (Escrow.Status status);

    /// @notice Returns the fee percentage, denominated in UD60x18, where 1e18 = 100%.
    /// @dev This trade fee is taken from both the sell and buy amounts in their respective tokens.
    function tradeFee() external view returns (UD60x18);

    /// @notice Retrieves a flag indicating whether the order was canceled.
    /// @dev Reverts if `orderId` references a null order.
    function wasCanceled(uint256 orderId) external view returns (bool);

    /// @notice Retrieves a flag indicating whether the order was filled.
    /// @dev Reverts if `orderId` references a null order.
    function wasFilled(uint256 orderId) external view returns (bool);
}
