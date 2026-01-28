// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { IBobVaultShare } from "./interfaces/IBobVaultShare.sol";
import { ISablierBob } from "./interfaces/ISablierBob.sol";
import { Errors } from "./libraries/Errors.sol";

/// @title BobVaultShare
/// @notice ERC-20 token representing shares in a Bob vault.
/// @dev Each vault has its own BobVaultShare deployed. Only the SablierBob contract can mint and burn tokens.
/// When shares are transferred, wstETH attribution is updated proportionally via the adapter.
contract BobVaultShare is ERC20, IBobVaultShare {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBobVaultShare
    address public immutable override SABLIER_BOB;

    /// @inheritdoc IBobVaultShare
    uint256 public immutable override VAULT_ID;

    /*//////////////////////////////////////////////////////////////////////////
                                  INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev The number of decimals.
    uint8 internal immutable _DECIMALS;

    /*//////////////////////////////////////////////////////////////////////////
                                      MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Reverts if caller is not the Bob contract.
    modifier onlySablierBob() {
        if (msg.sender != SABLIER_BOB) {
            revert Errors.BobVaultShare_OnlySablierBob(msg.sender, SABLIER_BOB);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Deploys the vault share token.
    /// @param name_ The name of the token (e.g., "Sablier Bob WETH Vault #1").
    /// @param symbol_ The symbol of the token (e.g., "WETH-100-1792790393-1").
    /// @param decimals_ The number of decimals.
    /// @param sablierBob_ The address of the SablierBob contract.
    /// @param vaultId_ The ID of the vault this share token represents.
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address sablierBob_,
        uint256 vaultId_
    )
        ERC20(name_, symbol_)
    {
        _DECIMALS = decimals_;
        SABLIER_BOB = sablierBob_;
        VAULT_ID = vaultId_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the number of decimals used by the token.
    function decimals() public view override(ERC20, IERC20Metadata) returns (uint8) {
        return _DECIMALS;
    }

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBobVaultShare
    function mint(address to, uint256 amount) external override onlySablierBob {
        _mint(to, amount);
    }

    /// @inheritdoc IBobVaultShare
    function burn(address from, uint256 amount) external override onlySablierBob {
        _burn(from, amount);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL OVERRIDE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Override to notify SablierBob when shares are transferred (not minted/burned).
    /// This allows the adapter to update wstETH attribution proportionally.
    function _update(address from, address to, uint256 amount) internal override {
        // Get sender's balance before the transfer.
        uint256 fromBalanceBefore = balanceOf(from);

        // Perform the update.
        super._update(from, to, amount);

        // Notify SablierBob if the transfer is not a mint or burn.
        if (from != address(0) && to != address(0)) {
            ISablierBob(SABLIER_BOB).onShareTransfer(VAULT_ID, from, to, amount, fromBalanceBefore);
        }
    }
}
