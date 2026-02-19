// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { BobVaultShare } from "src/BobVaultShare.sol";

import { Integration_Test } from "../../Integration.t.sol";

/// @notice Tests for ERC-20 metadata functions in BobVaultShare.
contract Metadata_BobVaultShare_Integration_Concrete_Test is Integration_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                      NAME
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Tests that name() returns the value set in constructor.
    function test_Name_ReturnsConstructorValue() external {
        string memory expectedName = "Sablier Bob WETH Vault #1";

        BobVaultShare shareToken = new BobVaultShare({
            name_: expectedName,
            symbol_: "WETH-100-1792790393-1",
            decimals_: 18,
            sablierBob: address(bob),
            vaultId: 1
        });

        assertEq(shareToken.name(), expectedName, "name");
    }

    /// @dev Tests name with empty string.
    function test_Name_EmptyString() external {
        BobVaultShare shareToken =
            new BobVaultShare({ name_: "", symbol_: "TST", decimals_: 18, sablierBob: address(bob), vaultId: 1 });

        assertEq(shareToken.name(), "", "name should be empty string");
    }

    /// @dev Tests name with long string.
    function test_Name_LongString() external {
        string memory longName =
            "This is a very long token name that exceeds normal expectations for ERC20 token names but should still work";

        BobVaultShare shareToken =
            new BobVaultShare({ name_: longName, symbol_: "TST", decimals_: 18, sablierBob: address(bob), vaultId: 1 });

        assertEq(shareToken.name(), longName, "name should match long string");
    }

    /// @dev Tests name with special characters.
    function test_Name_SpecialCharacters() external {
        string memory specialName = unicode"Sablier Bob - Test #1 (100$) \u2764";

        BobVaultShare shareToken = new BobVaultShare({
            name_: specialName,
            symbol_: "TST",
            decimals_: 18,
            sablierBob: address(bob),
            vaultId: 1
        });

        assertEq(shareToken.name(), specialName, "name should match special characters");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      SYMBOL
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Tests that symbol() returns the value set in constructor.
    function test_Symbol_ReturnsConstructorValue() external {
        string memory expectedSymbol = "WETH-100-1792790393-1";

        BobVaultShare shareToken = new BobVaultShare({
            name_: "Test Token",
            symbol_: expectedSymbol,
            decimals_: 18,
            sablierBob: address(bob),
            vaultId: 1
        });

        assertEq(shareToken.symbol(), expectedSymbol, "symbol");
    }

    /// @dev Tests symbol with standard format: {token}-{targetPrice}-{expiry}-{vaultId}.
    function test_Symbol_StandardFormat() external {
        // POL token, target price $100, expiry 1792790393, vault ID 12.
        string memory expectedSymbol = "POL-100-1792790393-12";

        BobVaultShare shareToken = new BobVaultShare({
            name_: "Sablier Bob POL Vault #12",
            symbol_: expectedSymbol,
            decimals_: 18,
            sablierBob: address(bob),
            vaultId: 12
        });

        assertEq(shareToken.symbol(), expectedSymbol, "symbol should follow standard format");
    }

    /// @dev Tests symbol with empty string.
    function test_Symbol_EmptyString() external {
        BobVaultShare shareToken = new BobVaultShare({
            name_: "Test Token",
            symbol_: "",
            decimals_: 18,
            sablierBob: address(bob),
            vaultId: 1
        });

        assertEq(shareToken.symbol(), "", "symbol should be empty string");
    }

    /// @dev Tests symbol with short string.
    function test_Symbol_ShortString() external {
        BobVaultShare shareToken = new BobVaultShare({
            name_: "Test Token",
            symbol_: "T",
            decimals_: 18,
            sablierBob: address(bob),
            vaultId: 1
        });

        assertEq(shareToken.symbol(), "T", "symbol should be single character");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     DECIMALS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Tests that decimals() returns the value set in constructor.
    function test_Decimals_ReturnsConstructorValue() external {
        uint8 expectedDecimals = 18;

        BobVaultShare shareToken = new BobVaultShare({
            name_: "Test Token",
            symbol_: "TST",
            decimals_: expectedDecimals,
            sablierBob: address(bob),
            vaultId: 1
        });

        assertEq(shareToken.decimals(), expectedDecimals, "decimals");
    }

    /// @dev Tests decimals with 6 (USDC-style).
    function test_Decimals_Six() external {
        BobVaultShare shareToken = new BobVaultShare({
            name_: "Test Token",
            symbol_: "TST",
            decimals_: 6,
            sablierBob: address(bob),
            vaultId: 1
        });

        assertEq(shareToken.decimals(), 6, "decimals should be 6");
    }

    /// @dev Tests decimals with 8 (WBTC-style).
    function test_Decimals_Eight() external {
        BobVaultShare shareToken = new BobVaultShare({
            name_: "Test Token",
            symbol_: "TST",
            decimals_: 8,
            sablierBob: address(bob),
            vaultId: 1
        });

        assertEq(shareToken.decimals(), 8, "decimals should be 8");
    }

    /// @dev Tests decimals with 0.
    function test_Decimals_Zero() external {
        BobVaultShare shareToken = new BobVaultShare({
            name_: "Test Token",
            symbol_: "TST",
            decimals_: 0,
            sablierBob: address(bob),
            vaultId: 1
        });

        assertEq(shareToken.decimals(), 0, "decimals should be 0");
    }

    /// @dev Tests that decimals overrides the default ERC20 behavior (which returns 18 by default).
    function test_Decimals_OverridesERC20Default() external {
        // Create token with non-18 decimals to verify override works.
        BobVaultShare shareToken = new BobVaultShare({
            name_: "Test Token",
            symbol_: "TST",
            decimals_: 12,
            sablierBob: address(bob),
            vaultId: 1
        });

        // ERC20 default is 18, but our override should return 12.
        assertEq(shareToken.decimals(), 12, "decimals should override ERC20 default");
    }

    /*//////////////////////////////////////////////////////////////////////////
                              COMBINED METADATA TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Tests all metadata functions together for a realistic vault share token.
    function test_AllMetadata_RealisticVaultShare() external {
        // Simulate a real vault share token for WETH with target price $5000, expiry Jan 1 2026, vault #42.
        string memory expectedName = "Sablier Bob WETH Vault #42";
        string memory expectedSymbol = "WETH-5000-1767225600-42";
        uint8 expectedDecimals = 18;

        BobVaultShare shareToken = new BobVaultShare({
            name_: expectedName,
            symbol_: expectedSymbol,
            decimals_: expectedDecimals,
            sablierBob: address(bob),
            vaultId: 42
        });

        assertEq(shareToken.name(), expectedName, "name");
        assertEq(shareToken.symbol(), expectedSymbol, "symbol");
        assertEq(shareToken.decimals(), expectedDecimals, "decimals");
        assertEq(shareToken.VAULT_ID(), 42, "VAULT_ID");
    }

    /// @dev Tests metadata for a USDC-based vault (6 decimals).
    function test_AllMetadata_USDCVault() external {
        string memory expectedName = "Sablier Bob USDC Vault #1";
        string memory expectedSymbol = "USDC-2-1800000000-1";
        uint8 expectedDecimals = 6;

        BobVaultShare shareToken = new BobVaultShare({
            name_: expectedName,
            symbol_: expectedSymbol,
            decimals_: expectedDecimals,
            sablierBob: address(bob),
            vaultId: 1
        });

        assertEq(shareToken.name(), expectedName, "name");
        assertEq(shareToken.symbol(), expectedSymbol, "symbol");
        assertEq(shareToken.decimals(), expectedDecimals, "decimals");
    }
}
