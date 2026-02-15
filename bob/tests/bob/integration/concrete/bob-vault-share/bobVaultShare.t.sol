// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { BobVaultShare as BobVaultShareContract } from "src/BobVaultShare.sol";
import { IBobVaultShare } from "src/interfaces/IBobVaultShare.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract BobVaultShare is Integration_Test {
    IBobVaultShare internal shareToken;
    uint8 internal constant TEST_DECIMALS = 18;
    uint256 internal constant TEST_VAULT_ID = 1;

    function setUp() public override {
        Integration_Test.setUp();

        // Deploy a BobVaultShare directly for testing.
        shareToken = new BobVaultShareContract({
            name_: "Test Share Token",
            symbol_: "TST-100-12345-1",
            decimals_: TEST_DECIMALS,
            sablierBob: address(bob),
            vaultId: TEST_VAULT_ID
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      DECIMALS
    //////////////////////////////////////////////////////////////////////////*/

    function test_Decimals_ShouldReturnTheDecimalsSetInConstructor() external view {
        // It should return the decimals set in constructor.
        assertEq(shareToken.decimals(), TEST_DECIMALS, "decimals");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        MINT
    //////////////////////////////////////////////////////////////////////////*/

    function test_Mint_RevertWhen_CallerIsNotSablierBob() external {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.BobVaultShare_OnlySablierBob.selector, users.depositor, address(bob))
        );
        shareToken.mint(users.depositor, 100e18);
    }

    function test_Mint_WhenCallerIsSablierBob() external {
        // It should mint tokens.
        uint256 amount = 100e18;
        uint256 balanceBefore = shareToken.balanceOf(users.depositor);

        // Stop existing prank and prank as SablierBob to mint.
        vm.stopPrank();
        vm.prank(address(bob));
        shareToken.mint(users.depositor, amount);

        uint256 balanceAfter = shareToken.balanceOf(users.depositor);
        assertEq(balanceAfter - balanceBefore, amount, "mint amount");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        BURN
    //////////////////////////////////////////////////////////////////////////*/

    function test_Burn_RevertWhen_CallerIsNotSablierBob() external {
        // First mint some tokens.
        vm.stopPrank();
        vm.prank(address(bob));
        shareToken.mint(users.depositor, 100e18);

        // It should revert.
        vm.prank(users.depositor);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.BobVaultShare_OnlySablierBob.selector, users.depositor, address(bob))
        );
        shareToken.burn(users.depositor, 100e18);
    }

    function test_Burn_WhenCallerIsSablierBob() external {
        // First mint some tokens.
        uint256 amount = 100e18;
        vm.stopPrank();
        vm.prank(address(bob));
        shareToken.mint(users.depositor, amount);

        uint256 balanceBefore = shareToken.balanceOf(users.depositor);

        // It should burn tokens.
        vm.prank(address(bob));
        shareToken.burn(users.depositor, amount);

        uint256 balanceAfter = shareToken.balanceOf(users.depositor);
        assertEq(balanceBefore - balanceAfter, amount, "burn amount");
    }
}
