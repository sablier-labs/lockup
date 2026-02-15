// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Bob } from "src/types/Bob.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Sync_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_NullVault() external {
        // It should revert.
        expectRevert_NullVault(abi.encodeCall(bob.syncPriceFromOracle, (vaultIds.nullVault)), vaultIds.nullVault);
    }

    function test_RevertGiven_VaultAlreadySettled() external givenNotNullVault {
        // It should revert.
        expectRevert_VaultSettled(
            abi.encodeCall(bob.syncPriceFromOracle, (vaultIds.settledVault)), vaultIds.settledVault
        );
    }

    function test_WhenSyncedPriceBelowTarget() external givenNotNullVault givenVaultNotSettled {
        // It should sync without settling.
        uint256 vaultId = vaultIds.defaultVault;

        // Set oracle price below target.
        mockOracle.setPrice(uint256(INITIAL_PRICE));

        // Expect the Sync event.
        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.SyncPriceFromOracle({
            vaultId: vaultId,
            oracle: AggregatorV3Interface(address(mockOracle)),
            latestPrice: INITIAL_PRICE,
            syncedAt: uint40(block.timestamp)
        });

        // Sync the vault.
        bob.syncPriceFromOracle(vaultId);

        // Assert the price was synced.
        assertEq(bob.getLastSyncedPrice(vaultId), INITIAL_PRICE, "lastSyncedPrice");
        assertEq(bob.getLastSyncedAt(vaultId), uint40(block.timestamp), "lastSyncedAt");

        // Assert vault is NOT settled (price below target).
        assertEq(bob.statusOf(vaultId), Bob.Status.ACTIVE, "status should be ACTIVE");
    }

    function test_WhenSyncedPriceAtOrAboveTarget() external givenNotNullVault givenVaultNotSettled {
        // It should sync and settle vault.
        uint256 vaultId = vaultIds.defaultVault;

        // Set oracle price at target.
        mockOracle.setPrice(uint256(SETTLED_PRICE));

        // Expect the Sync event.
        vm.expectEmit({ emitter: address(bob) });
        emit ISablierBob.SyncPriceFromOracle({
            vaultId: vaultId,
            oracle: AggregatorV3Interface(address(mockOracle)),
            latestPrice: SETTLED_PRICE,
            syncedAt: uint40(block.timestamp)
        });

        // Sync the vault.
        bob.syncPriceFromOracle(vaultId);

        // Assert the price was synced.
        assertEq(bob.getLastSyncedPrice(vaultId), SETTLED_PRICE, "lastSyncedPrice");
        assertEq(bob.getLastSyncedAt(vaultId), uint40(block.timestamp), "lastSyncedAt");

        // Assert vault IS settled (price at target).
        assertEq(bob.statusOf(vaultId), Bob.Status.SETTLED, "status should be SETTLED");
    }
}
