// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierBob } from "src/interfaces/ISablierBob.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Enter_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_NullVault() external {
        // It should revert.
        expectRevert_NullVault(abi.encodeCall(bob.enter, (vaultIds.nullVault, DEPOSIT_AMOUNT)), vaultIds.nullVault);
    }

    function test_RevertGiven_VaultSettled() external givenNotNullVault {
        // It should revert.
        expectRevert_VaultSettled(
            abi.encodeCall(bob.enter, (vaultIds.settledVault, DEPOSIT_AMOUNT)), vaultIds.settledVault
        );
    }

    function test_RevertWhen_AmountZero() external givenNotNullVault givenVaultNotSettled {
        // It should revert.
        expectRevert_DepositAmountZero(
            abi.encodeCall(bob.enter, (vaultIds.defaultVault, 0)), vaultIds.defaultVault, users.depositor
        );
    }

    function test_GivenFirstDeposit()
        external
        givenNotNullVault
        givenVaultNotSettled
        whenAmountNotZero
        givenVaultHasNoAdapter
    {
        // It should enter and set deposited at.
        uint256 vaultId = vaultIds.defaultVault;
        uint128 amount = DEPOSIT_AMOUNT;

        // Get initial state.
        address shareToken = address(bob.getShareToken(vaultId));
        uint256 shareBalanceBefore = IERC20(shareToken).balanceOf(users.depositor);

        // Expect the Enter event.
        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.Enter({
            vaultId: vaultId,
            user: users.depositor,
            amountReceived: amount,
            sharesMinted: amount
        });

        // Make the deposit.
        bob.enter(vaultId, amount);

        // Assert shares were minted (tracks deposit amount).
        uint256 shareBalanceAfter = IERC20(shareToken).balanceOf(users.depositor);
        assertEq(shareBalanceAfter - shareBalanceBefore, amount, "shares minted");

        // Assert depositedAt was set.
        uint40 depositedAt = bob.getDepositedAt(vaultId, users.depositor);
        assertEq(depositedAt, uint40(block.timestamp), "depositedAt should be set on first deposit");
    }

    function test_GivenSubsequentDeposit()
        external
        givenNotNullVault
        givenVaultNotSettled
        whenAmountNotZero
        givenVaultHasNoAdapter
    {
        // It should enter without updating deposited at.
        uint256 vaultId = vaultIds.defaultVault;
        uint128 firstAmount = DEPOSIT_AMOUNT;
        uint128 secondAmount = DEPOSIT_AMOUNT / 2;

        // Make first deposit.
        bob.enter(vaultId, firstAmount);
        uint40 firstDepositedAt = uint40(block.timestamp);

        // Warp forward 1 hour.
        vm.warp(block.timestamp + 1 hours);

        // Make second deposit.
        bob.enter(vaultId, secondAmount);

        // Assert share balance is cumulative (tracks deposit amount).
        uint256 shareBalance = IERC20(address(bob.getShareToken(vaultId))).balanceOf(users.depositor);
        assertEq(shareBalance, firstAmount + secondAmount, "share balance should be cumulative");

        // Assert depositedAt was NOT changed on subsequent deposit.
        uint40 depositedAt = bob.getDepositedAt(vaultId, users.depositor);
        assertEq(depositedAt, firstDepositedAt, "depositedAt should NOT change on subsequent deposit");
    }

    function test_GivenVaultHasAdapter() external givenNotNullVault givenVaultNotSettled whenAmountNotZero {
        // It should enter via adapter.
        uint256 vaultId = vaultIds.adapterVault;
        uint128 amount = WETH_DEPOSIT_AMOUNT;

        // Get initial state.
        address shareToken = address(bob.getShareToken(vaultId));
        uint256 shareBalanceBefore = IERC20(shareToken).balanceOf(users.depositor);

        // Make the deposit.
        bob.enter(vaultId, amount);

        // Assert shares were minted (tracks deposit amount).
        uint256 shareBalanceAfter = IERC20(shareToken).balanceOf(users.depositor);
        assertEq(shareBalanceAfter - shareBalanceBefore, amount, "shares minted");

        // Assert the adapter received the tokens (via stake).
        // wstETH amount is less than WETH due to exchange rate (0.9e18 = 90%).
        uint256 expectedWstETH = (amount * wsteth.exchangeRate()) / 1e18;
        assertEq(
            adapter.getYieldBearingTokenBalanceFor(vaultId, users.depositor),
            expectedWstETH,
            "adapter should track user wstETH"
        );
    }
}
