// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { BobVaultShare } from "src/BobVaultShare.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Constructor_BobVaultShare_Integration_Concrete_Test is Integration_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    string internal constant TEST_NAME = "Sablier Bob Test Share";
    string internal constant TEST_SYMBOL = "TEST-100-1234567890-1";
    uint8 internal constant TEST_DECIMALS = 18;
    uint256 internal constant TEST_VAULT_ID = 42;

    /*//////////////////////////////////////////////////////////////////////////
                                       TESTS
    //////////////////////////////////////////////////////////////////////////*/

    function test_Constructor() external {
        // Construct the contract.
        BobVaultShare shareToken = new BobVaultShare({
            name_: TEST_NAME,
            symbol_: TEST_SYMBOL,
            decimals_: TEST_DECIMALS,
            sablierBob: address(bob),
            vaultId: TEST_VAULT_ID
        });

        // Check SABLIER_BOB is set correctly.
        address actualSablierBob = shareToken.SABLIER_BOB();
        address expectedSablierBob = address(bob);
        assertEq(actualSablierBob, expectedSablierBob, "SABLIER_BOB");

        // Check VAULT_ID is set correctly.
        uint256 actualVaultId = shareToken.VAULT_ID();
        uint256 expectedVaultId = TEST_VAULT_ID;
        assertEq(actualVaultId, expectedVaultId, "VAULT_ID");

        // Check decimals is set correctly.
        uint8 actualDecimals = shareToken.decimals();
        uint8 expectedDecimals = TEST_DECIMALS;
        assertEq(actualDecimals, expectedDecimals, "decimals");

        // Check name is set correctly (inherited from ERC20).
        string memory actualName = shareToken.name();
        string memory expectedName = TEST_NAME;
        assertEq(actualName, expectedName, "name");

        // Check symbol is set correctly (inherited from ERC20).
        string memory actualSymbol = shareToken.symbol();
        string memory expectedSymbol = TEST_SYMBOL;
        assertEq(actualSymbol, expectedSymbol, "symbol");

        // Check initial total supply is zero.
        uint256 actualTotalSupply = shareToken.totalSupply();
        uint256 expectedTotalSupply = 0;
        assertEq(actualTotalSupply, expectedTotalSupply, "totalSupply");
    }

    /// @dev Test constructor with different decimals values.
    function test_Constructor_DifferentDecimals() external {
        // Test with 6 decimals (like USDC).
        BobVaultShare shareToken6 = new BobVaultShare({
            name_: TEST_NAME,
            symbol_: TEST_SYMBOL,
            decimals_: 6,
            sablierBob: address(bob),
            vaultId: TEST_VAULT_ID
        });
        assertEq(shareToken6.decimals(), 6, "decimals should be 6");

        // Test with 8 decimals (like WBTC).
        BobVaultShare shareToken8 = new BobVaultShare({
            name_: TEST_NAME,
            symbol_: TEST_SYMBOL,
            decimals_: 8,
            sablierBob: address(bob),
            vaultId: TEST_VAULT_ID
        });
        assertEq(shareToken8.decimals(), 8, "decimals should be 8");
    }

    /// @dev Test constructor with vault ID of 1 (first vault).
    function test_Constructor_VaultIdOne() external {
        BobVaultShare shareToken = new BobVaultShare({
            name_: TEST_NAME,
            symbol_: TEST_SYMBOL,
            decimals_: TEST_DECIMALS,
            sablierBob: address(bob),
            vaultId: 1
        });
        assertEq(shareToken.VAULT_ID(), 1, "VAULT_ID should be 1");
    }

    /// @dev Test constructor with large vault ID.
    function test_Constructor_LargeVaultId() external {
        uint256 largeVaultId = type(uint256).max;

        BobVaultShare shareToken = new BobVaultShare({
            name_: TEST_NAME,
            symbol_: TEST_SYMBOL,
            decimals_: TEST_DECIMALS,
            sablierBob: address(bob),
            vaultId: largeVaultId
        });
        assertEq(shareToken.VAULT_ID(), largeVaultId, "VAULT_ID should be max uint256");
    }
}
