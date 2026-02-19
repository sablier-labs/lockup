// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
    function expectRevert_Null(bytes memory callData, uint256 nullVaultId) internal {
        (bool success, bytes memory returnData) = address(bob).call(callData);
        assertFalse(success, "null vault call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierBobState_Null.selector, nullVaultId),
            "null vault call return data"
        );
    }
}
