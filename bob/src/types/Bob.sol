// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IBobVaultShare } from "../interfaces/IBobVaultShare.sol";
import { ISablierBobAdapter } from "../interfaces/ISablierBobAdapter.sol";

/// @notice Namespace for the structs and enums used in the Sablier Bob protocol.
library Bob {
    /// @notice Enum representing the different statuses of a vault.
    /// @custom:value0 ACTIVE Vault is open for deposits.
    /// @custom:value1 SETTLED Vault is settled; either target price reached or vault has expired.
    enum Status {
        ACTIVE,
        SETTLED
    }

    /// @notice Struct encapsulating all the configuration and state of a vault.
    /// @dev The fields are arranged for gas optimization via tight variable packing.
    /// @param token The ERC-20 token accepted for deposits in this vault.
    /// @param expiry The Unix timestamp when the vault expires.
    /// @param lastSyncedAt The Unix timestamp when the oracle price was last synced.
    /// @param shareToken The address of ERC-20 token representing shares in this vault.
    /// @param oracle The address of the price oracle for the deposit token, provided by the vault creator.
    /// @param adapter The adapter set for this vault, can be used to take action on the deposit token.
    /// @param isStakedWithAdapter Whether the deposit token is staked with the adapter or not.
    /// @param targetPrice The target price at which the vault settles, denoted in 8 decimals where 1e8 is $1.
    /// @param lastSyncedPrice The most recent price fetched from the oracle, denoted in 8 decimals where 1e8 is $1.
    struct Vault {
        // slot 0
        IERC20 token;
        uint40 expiry;
        uint40 lastSyncedAt;
        // slot 1
        IBobVaultShare shareToken;
        // slot 2
        AggregatorV3Interface oracle;
        // slot 3
        ISablierBobAdapter adapter;
        bool isStakedWithAdapter;
        // slot 4
        uint128 targetPrice;
        uint128 lastSyncedPrice;
    }
}
