// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

/// @title Errors
/// @notice Library containing all custom errors emitted by the Sablier Bob protocol.
library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                                     SABLIER BOB
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when the caller is not an original depositor (required for grace period exit).
    /// @param vaultId The ID of the vault.
    /// @param user The address of the caller.
    error SablierBob_CallerNotDepositor(uint256 vaultId, address user);

    /// @notice Thrown when the caller is not the share token contract for a vault.
    /// @param vaultId The ID of the vault.
    /// @param caller The address that attempted to call the function.
    error SablierBob_CallerNotShareToken(uint256 vaultId, address caller);

    /// @notice Thrown when trying to deposit zero amount in a vault.
    /// @param vaultId The ID of the vault.
    /// @param user The address of the user attempting to deposit.
    error SablierBob_DepositAmountZero(uint256 vaultId, address user);

    /// @notice Thrown when the provided expiry timestamp is in the past.
    /// @param expiry The provided expiry timestamp.
    /// @param currentTime The current block timestamp.
    error SablierBob_ExpiryInPast(uint40 expiry, uint40 currentTime);

    /// @notice Thrown when the user's grace period has expired and they cannot exit without settlement.
    /// @param vaultId The ID of the vault.
    /// @param user The address of the user.
    /// @param depositedAt The timestamp when the user deposited.
    /// @param gracePeriodEnd The timestamp when the grace period ended.
    error SablierBob_GracePeriodExpired(uint256 vaultId, address user, uint40 depositedAt, uint40 gracePeriodEnd);

    /// @notice Thrown when the fee payment is insufficient for redemption.
    /// @param feePaid The amount of native token paid.
    /// @param feeRequired The minimum fee required.
    error SablierBob_InsufficientFeePayment(uint256 feePaid, uint256 feeRequired);

    /// @notice Thrown when the new adapter does not implement the required interface.
    /// @param adapter The address of the adapter that misses the interface.
    error SablierBob_NewAdapterMissesInterface(address adapter);

    /// @notice Thrown when the oracle is invalid (zero address or fails basic validation).
    /// @param oracle The address of the invalid oracle.
    error SablierBob_InvalidOracle(address oracle);

    /// @notice Thrown when the oracle does not return 8 decimals.
    /// @param oracle The address of the oracle.
    /// @param decimals The decimals returned by the oracle.
    error SablierBob_InvalidOracleDecimals(address oracle, uint8 decimals);

    /// @notice Thrown when the native token fee transfer to the comptroller fails.
    error SablierBob_NativeFeeTransferFailed();

    /// @notice Thrown when trying to unstake from a vault that has no staked tokens.
    /// @param vaultId The ID of the vault with nothing to unstake.
    error SablierBob_UnstakeAmountZero(uint256 vaultId);

    /// @notice Thrown when trying to exit or redeem with zero share balance.
    /// @param vaultId The ID of the vault.
    /// @param user The address of the user with no shares.
    error SablierBob_NoSharesToRedeem(uint256 vaultId, address user);

    /// @notice Thrown when the oracle returns an invalid price (zero or negative).
    /// @param vaultId The ID of the vault.
    /// @param oraclePrice The invalid price returned by the oracle.
    error SablierBob_OraclePriceInvalid(uint256 vaultId, int256 oraclePrice);

    /// @notice Thrown when the target price is not greater than the current oracle price.
    /// @param targetPrice The provided target price.
    /// @param currentPrice The current price from the oracle.
    error SablierBob_TargetPriceTooLow(uint128 targetPrice, uint128 currentPrice);

    /// @notice Thrown when the token address is zero.
    error SablierBob_TokenAddressZero();

    /// @notice Thrown when trying to unstake from a vault that has already been unstaked.
    /// @param vaultId The ID of the vault that has already been unstaked.
    error SablierBob_VaultAlreadyUnstaked(uint256 vaultId);

    /// @notice Thrown when trying to unstake from a vault that has no adapter configured.
    /// @param vaultId The ID of the vault without an adapter.
    error SablierBob_VaultHasNoAdapter(uint256 vaultId);

    /// @notice Thrown when trying to interact with a non-existent vault.
    /// @param vaultId The ID of the vault that does not exist.
    error SablierBob_VaultNotFound(uint256 vaultId);

    /// @notice Thrown when trying to redeem from a vault that has not yet settled.
    /// @param vaultId The ID of the vault that has not settled.
    error SablierBob_VaultNotSettled(uint256 vaultId);

    /// @notice Thrown when trying to deposit into a vault that has already settled.
    /// @param vaultId The ID of the settled vault.
    error SablierBob_VaultSettled(uint256 vaultId);

    /*//////////////////////////////////////////////////////////////////////////
                                SABLIER LIDO ADAPTER
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when a function is called by an address other than SablierBob.
    /// @param caller The address that attempted to call the function.
    /// @param expectedCaller The expected caller (SablierBob contract).
    error SablierLidoAdapter_OnlySablierBob(address caller, address expectedCaller);

    /// @notice Thrown when the Curve swap output is below the minimum acceptable amount due to slippage.
    /// @param expected The expected minimum output amount.
    /// @param actual The actual output amount received.
    error SablierLidoAdapter_SlippageExceeded(uint256 expected, uint256 actual);

    /// @notice Thrown when the slippage tolerance exceeds the maximum allowed (5%).
    /// @param tolerance The provided slippage tolerance (raw UD60x18 value).
    /// @param maxTolerance The maximum allowed slippage tolerance (raw UD60x18 value).
    error SablierLidoAdapter_SlippageToleranceTooHigh(uint256 tolerance, uint256 maxTolerance);

    /// @notice Thrown when trying to unstake from a vault that has not yet settled.
    /// @param vaultId The ID of the vault that has not settled.
    error SablierLidoAdapter_VaultNotSettled(uint256 vaultId);

    /// @notice Thrown when the yield fee exceeds the maximum allowed (20%).
    /// @param fee The provided yield fee (raw UD60x18 value).
    /// @param maxFee The maximum allowed yield fee (raw UD60x18 value).
    error SablierLidoAdapter_YieldFeeTooHigh(uint256 fee, uint256 maxFee);

    /*//////////////////////////////////////////////////////////////////////////
                                   SABLIER ESCROW
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when the buy amount is below the minimum buy amount required by the order.
    /// @param buyAmount The provided buy amount.
    /// @param minBuyAmount The minimum buy amount required.
    error SablierEscrow_BuyAmountBelowMinimum(uint128 buyAmount, uint128 minBuyAmount);

    /// @notice Thrown when the buy token address is zero.
    error SablierEscrow_BuyTokenZero();

    /// @notice Thrown when the caller is not the comptroller admin.
    /// @param caller The address that attempted to call the function.
    /// @param admin The comptroller admin address.
    error SablierEscrow_CallerNotAdmin(address caller, address admin);

    /// @notice Thrown when the caller is not authorized to accept an order (restricted counterparty).
    /// @param orderId The ID of the order.
    /// @param caller The address that attempted to accept.
    /// @param expectedBuyer The designated buyer address.
    error SablierEscrow_CallerNotBuyer(uint256 orderId, address caller, address expectedBuyer);

    /// @notice Thrown when the caller is not the seller of an order.
    /// @param orderId The ID of the order.
    /// @param caller The address that attempted the action.
    /// @param seller The seller address.
    error SablierEscrow_CallerNotSeller(uint256 orderId, address caller, address seller);

    /// @notice Thrown when the provided expiry timestamp is in the past.
    /// @param expiry The provided expiry timestamp.
    /// @param currentTime The current block timestamp.
    error SablierEscrow_ExpiryInPast(uint40 expiry, uint40 currentTime);

    /// @notice Thrown when trying to set a protocol fee that exceeds the maximum allowed.
    /// @param fee The provided fee.
    /// @param maxFee The maximum allowed fee.
    error SablierEscrow_FeeExceedsMax(uint256 fee, uint256 maxFee);

    /// @notice Thrown when the minimum buy amount is zero.
    error SablierEscrow_MinBuyAmountZero();

    /// @notice Thrown when trying to interact with an order that has already been cancelled.
    /// @param orderId The ID of the order.
    error SablierEscrow_OrderCancelled(uint256 orderId);

    /// @notice Thrown when trying to interact with an order that has already been completed.
    /// @param orderId The ID of the order.
    error SablierEscrow_OrderCompleted(uint256 orderId);

    /// @notice Thrown when trying to accept an order that has expired.
    /// @param orderId The ID of the order.
    /// @param expiry The expiry timestamp.
    /// @param currentTime The current block timestamp.
    error SablierEscrow_OrderExpired(uint256 orderId, uint40 expiry, uint40 currentTime);

    /// @notice Thrown when trying to interact with a non-existent order.
    /// @param orderId The ID of the order that does not exist.
    error SablierEscrow_OrderNotFound(uint256 orderId);

    /// @notice Thrown when the sell and buy tokens are the same.
    /// @param token The token address.
    error SablierEscrow_SameToken(address token);

    /// @notice Thrown when the sell amount is zero.
    error SablierEscrow_SellAmountZero();

    /// @notice Thrown when the sell token address is zero.
    error SablierEscrow_SellTokenZero();
}
