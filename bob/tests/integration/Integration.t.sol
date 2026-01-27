// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";

import { Errors } from "src/libraries/Errors.sol";

import { Base_Test } from "../Base.t.sol";

/// @notice Common logic needed by all integration tests, both concrete and fuzz tests.
abstract contract Integration_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Default vault parameters for quick access.
    struct DefaultVaultParams {
        IERC20 token;
        AggregatorV3Interface oracle;
        uint40 expiry;
        uint128 targetPrice;
    }

    DefaultVaultParams internal _defaultVaultParams;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        // Set default vault parameters.
        _defaultVaultParams.token = IERC20(address(dai));
        _defaultVaultParams.oracle = AggregatorV3Interface(address(mockOracle));
        _defaultVaultParams.expiry = EXPIRY;
        _defaultVaultParams.targetPrice = TARGET_PRICE;

        // Initialize default vaults for testing.
        initializeDefaultVaults();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INITIALIZE-FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Initializes the default vaults used in tests.
    function initializeDefaultVaults() internal {
        // Create a default vault (no adapter).
        vaultIds.defaultVault = createDefaultVault();

        // Create a vault with adapter.
        vaultIds.adapterVault = createVaultWithAdapter();

        // Set a null vault ID (one that doesn't exist).
        vaultIds.nullVault = 1729;

        // Create a settled vault (for testing redemptions).
        // Note: We create this last to avoid messing with oracle state.
        mockOracle.setPrice(INITIAL_PRICE); // Reset price.
        vaultIds.settledVault = createSettledVaultViaPrice();
        mockOracle.setPrice(INITIAL_PRICE); // Reset for other tests.
    }

    /*//////////////////////////////////////////////////////////////////////////
                                COMMON-REVERT-TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Expects a revert when the vault is null.
    function expectRevert_NullVault(bytes memory callData, uint256 nullVaultId) internal {
        (bool success, bytes memory returnData) = address(bob).call(callData);
        assertFalse(success, "null vault call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierBob_VaultNotFound.selector, nullVaultId),
            "null vault call return data"
        );
    }

    /// @dev Expects a revert when the vault is already settled.
    function expectRevert_VaultSettled(bytes memory callData, uint256 settledVaultId) internal {
        (bool success, bytes memory returnData) = address(bob).call(callData);
        assertFalse(success, "settled vault call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierBob_VaultSettled.selector, settledVaultId),
            "settled vault call return data"
        );
    }

    /// @dev Expects a revert when the vault is not yet settled.
    function expectRevert_VaultNotSettled(bytes memory callData, uint256 vaultId) internal {
        (bool success, bytes memory returnData) = address(bob).call(callData);
        assertFalse(success, "not settled vault call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierBob_VaultNotSettled.selector, vaultId),
            "not settled vault call return data"
        );
    }

    /// @dev Expects a revert when the caller is not the comptroller.
    function expectRevert_NotComptroller(bytes memory callData) internal {
        setMsgSender(users.eve);
        (bool success, bytes memory returnData) = address(bob).call(callData);
        assertFalse(success, "non-comptroller call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(
                EvmUtilsErrors.Comptrollerable_CallerNotComptroller.selector, address(comptroller), users.eve
            ),
            "non-comptroller call return data"
        );
    }

    /// @dev Expects a revert when deposit amount is zero.
    function expectRevert_DepositAmountZero(bytes memory callData, uint256 vaultId, address user) internal {
        (bool success, bytes memory returnData) = address(bob).call(callData);
        assertFalse(success, "zero amount call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierBob_DepositAmountZero.selector, vaultId, user),
            "zero amount call return data"
        );
    }

    /// @dev Expects a revert when the caller has no shares to redeem.
    function expectRevert_NoSharesToRedeem(bytes memory callData, uint256 vaultId, address user) internal {
        (bool success, bytes memory returnData) = address(bob).call(callData);
        assertFalse(success, "no shares call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierBob_NoSharesToRedeem.selector, vaultId, user),
            "no shares call return data"
        );
    }

    /// @dev Expects a revert when the grace period has expired.
    function expectRevert_GracePeriodExpired(
        bytes memory callData,
        uint256 vaultId,
        address user,
        uint40 depositedAt,
        uint40 gracePeriodEnd
    )
        internal
    {
        (bool success, bytes memory returnData) = address(bob).call(callData);
        assertFalse(success, "grace period expired call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(
                Errors.SablierBob_GracePeriodExpired.selector, vaultId, user, depositedAt, gracePeriodEnd
            ),
            "grace period expired call return data"
        );
    }

    /// @dev Expects a revert when the caller is not an original depositor.
    function expectRevert_CallerNotDepositor(bytes memory callData, uint256 vaultId, address user) internal {
        (bool success, bytes memory returnData) = address(bob).call(callData);
        assertFalse(success, "caller not depositor call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierBob_CallerNotDepositor.selector, vaultId, user),
            "caller not depositor call return data"
        );
    }

    /// @dev Expects a revert when the token address is zero.
    function expectRevert_TokenAddressZero(bytes memory callData) internal {
        (bool success, bytes memory returnData) = address(bob).call(callData);
        assertFalse(success, "token address zero call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierBob_TokenAddressZero.selector),
            "token address zero call return data"
        );
    }

    /// @dev Expects a revert when expiry is in the past.
    function expectRevert_ExpiryInPast(bytes memory callData, uint40 expiry, uint40 currentTime) internal {
        (bool success, bytes memory returnData) = address(bob).call(callData);
        assertFalse(success, "expiry in past call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierBob_ExpiryInPast.selector, expiry, currentTime),
            "expiry in past call return data"
        );
    }

    /// @dev Expects a revert when the oracle is invalid.
    function expectRevert_InvalidOracle(bytes memory callData, address oracleAddress) internal {
        (bool success, bytes memory returnData) = address(bob).call(callData);
        assertFalse(success, "invalid oracle call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierBob_InvalidOracle.selector, oracleAddress),
            "invalid oracle call return data"
        );
    }

    /// @dev Expects a revert when the oracle returns invalid decimals (not 8).
    function expectRevert_InvalidOracleDecimals(
        bytes memory callData,
        address oracleAddress,
        uint8 decimalsValue
    )
        internal
    {
        (bool success, bytes memory returnData) = address(bob).call(callData);
        assertFalse(success, "invalid oracle decimals call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierBob_InvalidOracleDecimals.selector, oracleAddress, decimalsValue),
            "invalid oracle decimals call return data"
        );
    }

    /// @dev Expects a revert when the target price is at or below the current oracle price.
    function expectRevert_TargetPriceTooLow(
        bytes memory callData,
        uint128 targetPriceValue,
        uint128 currentPriceValue
    )
        internal
    {
        (bool success, bytes memory returnData) = address(bob).call(callData);
        assertFalse(success, "target price too low call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierBob_TargetPriceTooLow.selector, targetPriceValue, currentPriceValue),
            "target price too low call return data"
        );
    }

    /// @dev Expects a revert when the new adapter does not implement the required interface.
    function expectRevert_NewAdapterMissesInterface(bytes memory callData, address adapterAddress) internal {
        (bool success, bytes memory returnData) = address(bob).call(callData);
        assertFalse(success, "new adapter misses interface call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierBob_NewAdapterMissesInterface.selector, adapterAddress),
            "new adapter misses interface call return data"
        );
    }

    /// @dev Expects a revert when the vault has no adapter.
    function expectRevert_VaultHasNoAdapter(bytes memory callData, uint256 vaultId) internal {
        (bool success, bytes memory returnData) = address(bob).call(callData);
        assertFalse(success, "vault has no adapter call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierBob_VaultHasNoAdapter.selector, vaultId),
            "vault has no adapter call return data"
        );
    }

    /// @dev Expects a revert when the vault is already unstaked.
    function expectRevert_VaultAlreadyUnstaked(bytes memory callData, uint256 vaultId) internal {
        (bool success, bytes memory returnData) = address(bob).call(callData);
        assertFalse(success, "vault already unstaked call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierBob_VaultAlreadyUnstaked.selector, vaultId),
            "vault already unstaked call return data"
        );
    }

    /// @dev Expects a revert when fee payment is insufficient.
    function expectRevert_InsufficientFeePayment(bytes memory callData, uint256 feePaid, uint256 feeRequired) internal {
        (bool success, bytes memory returnData) = address(bob).call(callData);
        assertFalse(success, "insufficient fee call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierBob_InsufficientFeePayment.selector, feePaid, feeRequired),
            "insufficient fee call return data"
        );
    }
}
