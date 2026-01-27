// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { ISablierBobAdapter } from "./ISablierBobAdapter.sol";

/// @title ISablierLidoAdapter
/// @notice Interface for the Lido yield adapter that stakes WETH as wstETH and unstakes it via Curve.
/// @dev Extends the base adapter interface with Lido and Curve specific functionalities.
interface ISablierLidoAdapter is ISablierBobAdapter {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the comptroller sets a new slippage tolerance.
    /// @param oldSlippageTolerance The previous slippage tolerance as UD60x18.
    /// @param newSlippageTolerance The new slippage tolerance as UD60x18.
    event SetSlippageTolerance(UD60x18 oldSlippageTolerance, UD60x18 newSlippageTolerance);

    /*//////////////////////////////////////////////////////////////////////////
                               USER-FACING CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the address of the Curve stETH/ETH pool.
    function CURVE_POOL() external view returns (address);

    /// @notice Returns the maximum slippage tolerance that can be set, denominated in UD60x18, where 1e18 = 100%.
    function MAX_SLIPPAGE_TOLERANCE() external view returns (UD60x18);

    /// @notice Returns the address of the stETH contract.
    function STETH() external view returns (address);

    /// @notice Returns the address of the WETH contract.
    function WETH() external view returns (address);

    /// @notice Returns the address of the wstETH contract.
    function WSTETH() external view returns (address);

    /// @notice Returns the current slippage tolerance for Curve swaps, denominated in UD60x18, where 1e18 = 100%.
    function slippageTolerance() external view returns (UD60x18);

    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the total WETH received after unstaking for a vault.
    /// @param vaultId The ID of the vault.
    /// @return The total WETH received after unstaking.
    function getWethReceivedAfterUnstaking(uint256 vaultId) external view returns (uint256);

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Sets the slippage tolerance for Curve swaps.
    ///
    /// @dev Emits a {SetSlippageTolerance} event.
    ///
    /// Notes:
    /// - This affects all vaults.
    ///
    /// Requirements:
    /// - The caller must be the comptroller.
    /// - `newSlippageTolerance` must not exceed MAX_SLIPPAGE_TOLERANCE.
    ///
    /// @param newTolerance The new slippage tolerance as UD60x18.
    function setSlippageTolerance(UD60x18 newTolerance) external;
}
