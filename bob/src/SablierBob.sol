// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Batch } from "@sablier/evm-utils/src/Batch.sol";
import { SafeOracle } from "@sablier/evm-utils/src/libraries/SafeOracle.sol";
import { Comptrollerable } from "@sablier/evm-utils/src/Comptrollerable.sol";
import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";

import { SablierBobState } from "./abstracts/SablierBobState.sol";
import { BobVaultShare } from "./BobVaultShare.sol";
import { IBobVaultShare } from "./interfaces/IBobVaultShare.sol";
import { ISablierBob } from "./interfaces/ISablierBob.sol";
import { ISablierBobAdapter } from "./interfaces/ISablierBobAdapter.sol";
import { Errors } from "./libraries/Errors.sol";
import { Bob } from "./types/Bob.sol";

/*

███████╗ █████╗ ██████╗ ██╗     ██╗███████╗██████╗     ██████╗  ██████╗ ██████╗
██╔════╝██╔══██╗██╔══██╗██║     ██║██╔════╝██╔══██╗    ██╔══██╗██╔═══██╗██╔══██╗
███████╗███████║██████╔╝██║     ██║█████╗  ██████╔╝    ██████╔╝██║   ██║██████╔╝
╚════██║██╔══██║██╔══██╗██║     ██║██╔══╝  ██╔══██╗    ██╔══██╗██║   ██║██╔══██╗
███████║██║  ██║██████╔╝███████╗██║███████╗██║  ██║    ██████╔╝╚██████╔╝██████╔╝
╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝    ╚═════╝  ╚═════╝ ╚═════╝

*/

/// @title SablierBob
/// @notice See the documentation in {ISablierBob}.
contract SablierBob is
    Batch, // 1 inherited component
    Comptrollerable, // 1 inherited component
    ISablierBob, // 2 inherited components
    ReentrancyGuard, // 1 inherited component
    SablierBobState // 1 inherited component
{
    using SafeCast for uint256;
    using SafeERC20 for IERC20;
    using Strings for uint256;

    /*//////////////////////////////////////////////////////////////////////////
                                      CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierBob
    uint40 public constant override GRACE_PERIOD = 4 hours;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialComptroller The address of the initial comptroller contract.
    constructor(address initialComptroller) Comptrollerable(initialComptroller) SablierBobState() { }

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierBob
    function createVault(
        IERC20 token,
        AggregatorV3Interface oracle,
        uint40 expiry,
        uint128 targetPrice
    )
        external
        override
        returns (uint256 vaultId)
    {
        // Check: token is not the zero address.
        if (address(token) == address(0)) {
            revert Errors.SablierBob_TokenAddressZero();
        }

        uint40 currentTimestamp = uint40(block.timestamp);

        // Check: expiry is in the future.
        if (expiry <= currentTimestamp) {
            revert Errors.SablierBob_ExpiryInPast(expiry, currentTimestamp);
        }

        // Check: target price is not zero.
        if (targetPrice == 0) {
            revert Errors.SablierBob_TargetPriceZero();
        }

        // Check: oracle implements the Chainlink {AggregatorV3Interface} interface.
        uint128 latestPrice = SafeOracle.validateOracle(oracle);

        // Check: target price is greater than latest oracle price.
        if (targetPrice <= latestPrice) {
            revert Errors.SablierBob_TargetPriceTooLow(targetPrice, latestPrice);
        }

        // Load the vault ID from storage.
        vaultId = nextVaultId;

        // Effect: bump the next vault ID.
        unchecked {
            nextVaultId = vaultId + 1;
        }

        // Retrieve token symbol and token decimal.
        string memory tokenSymbol = IERC20Metadata(address(token)).symbol();
        uint8 tokenDecimals = IERC20Metadata(address(token)).decimals();

        // Effect: deploy the share token for this vault.
        IBobVaultShare shareToken = new BobVaultShare({
            name_: string.concat("Sablier Bob ", tokenSymbol, " Vault #", vaultId.toString()),
            symbol_: string.concat(
                tokenSymbol,
                "-",
                uint256(targetPrice).toString(),
                "-",
                uint256(expiry).toString(),
                "-",
                vaultId.toString()
            ),
            decimals_: tokenDecimals,
            sablierBob: address(this),
            vaultId: vaultId
        });

        // Copy the adapter from storage to memory.
        ISablierBobAdapter adapter = defaultAdapters[token];

        // Effect: create the vault.
        _vaults[vaultId] = Bob.Vault({
            token: token,
            expiry: expiry,
            lastSyncedAt: currentTimestamp,
            shareToken: shareToken,
            oracle: oracle,
            adapter: adapter,
            isStakedWithAdapter: true,
            targetPrice: targetPrice,
            lastSyncedPrice: latestPrice
        });

        // Interaction: register the vault with the adapter.
        if (address(adapter) != address(0)) {
            adapter.registerVault(vaultId);
        }

        // Log the event.
        emit CreateVault(vaultId, token, oracle, adapter, shareToken, targetPrice, expiry);
    }

    /// @inheritdoc ISablierBob
    function enter(uint256 vaultId, uint128 amount) external override nonReentrant notNull(vaultId) {
        // Check: the vault is not already settled (e.g. via expiry or a previous sync).
        if (_statusOf(vaultId) == Bob.Status.SETTLED) {
            revert Errors.SablierBob_VaultSettled(vaultId);
        }

        // Effect: sync the oracle price.
        _syncPriceFromOracle(vaultId);

        // Check: the vault has not become settled after the sync.
        if (_statusOf(vaultId) == Bob.Status.SETTLED) {
            revert Errors.SablierBob_VaultSettled(vaultId);
        }

        // Check: the deposit amount is not zero.
        if (amount == 0) {
            revert Errors.SablierBob_DepositAmountZero(vaultId, msg.sender);
        }

        // Load the vault from storage.
        Bob.Vault memory vault = _vaults[vaultId];

        // Effect: set `_firstDepositTimes` on the first deposit for grace period tracking.
        if (_firstDepositTimes[vaultId][msg.sender] == 0) {
            _firstDepositTimes[vaultId][msg.sender] = uint40(block.timestamp);
        }

        // Interaction: transfer tokens from caller to this contract or the adapter.
        if (address(vault.adapter) != address(0)) {
            // Interaction: Transfer token from caller to the adapter.
            vault.token.safeTransferFrom(msg.sender, address(vault.adapter), amount);

            // Interaction: stake the tokens via the adapter.
            vault.adapter.stake(vaultId, msg.sender, amount);
        } else {
            // Interaction: Transfer tokens from caller to this contract.
            vault.token.safeTransferFrom(msg.sender, address(this), amount);
        }

        // Interaction: mint share tokens to the caller.
        vault.shareToken.mint(msg.sender, amount);

        // Log the deposit.
        emit Enter(vaultId, msg.sender, amount, amount);
    }

    /// @inheritdoc ISablierBob
    function exitWithinGracePeriod(uint256 vaultId) external override nonReentrant notNull(vaultId) {
        // Check: the vault is not settled.
        if (_statusOf(vaultId) == Bob.Status.SETTLED) {
            revert Errors.SablierBob_VaultSettled(vaultId);
        }

        // Load the vault from storage.
        Bob.Vault storage vault = _vaults[vaultId];

        // Get the caller's share balance.
        uint128 amount = vault.shareToken.balanceOf(msg.sender).toUint128();

        // Check: the share balance is not zero.
        if (amount == 0) {
            revert Errors.SablierBob_NoSharesToRedeem(vaultId, msg.sender);
        }

        // Retrieve the timestamp when the caller made the first deposit in this vault.
        uint40 firstDepositTime = _firstDepositTimes[vaultId][msg.sender];

        // Check: the caller is a depositor and does not hold shares because of a transfer.
        if (firstDepositTime == 0) {
            revert Errors.SablierBob_CallerNotDepositor(vaultId, msg.sender);
        }

        // Calculate the grace period end time.
        uint40 gracePeriodEndsAt = firstDepositTime + GRACE_PERIOD;

        // Check: the current timestamp is within the grace period.
        if (block.timestamp >= gracePeriodEndsAt) {
            revert Errors.SablierBob_GracePeriodExpired(vaultId, msg.sender, firstDepositTime, gracePeriodEndsAt);
        }

        // Effect: clear the deposit record.
        delete _firstDepositTimes[vaultId][msg.sender];

        // Effect: burn share tokens from the caller.
        vault.shareToken.burn(msg.sender, amount);

        // Interaction: return tokens to the caller.
        if (address(vault.adapter) != address(0)) {
            // Unstake the tokens for the user via the adapter.
            vault.adapter.unstakeForUserWithinGracePeriod(vaultId, msg.sender);
        } else {
            vault.token.safeTransfer(msg.sender, amount);
        }

        // Log the event.
        emit ExitWithinGracePeriod(vaultId, msg.sender, amount, amount);
    }

    /// @inheritdoc ISablierBob
    function redeem(uint256 vaultId)
        external
        payable
        override
        nonReentrant
        notNull(vaultId)
        returns (uint128 amountToTransfer, uint128 feeAmount)
    {
        // Check: the vault is settled.
        if (_statusOf(vaultId) != Bob.Status.SETTLED) {
            // Effect: sync the oracle price.
            _syncPriceFromOracle(vaultId);

            // If it's still not settled after the sync, revert.
            if (_statusOf(vaultId) != Bob.Status.SETTLED) {
                revert Errors.SablierBob_VaultNotSettled(vaultId);
            }
        }

        // Load the vault from storage.
        Bob.Vault storage vault = _vaults[vaultId];

        // Get the caller's share balance.
        uint128 shareBalance = vault.shareToken.balanceOf(msg.sender).toUint128();

        // Check: the share balance is not zero.
        if (shareBalance == 0) {
            revert Errors.SablierBob_NoSharesToRedeem(vaultId, msg.sender);
        }

        // Effect: burn share tokens from the caller.
        vault.shareToken.burn(msg.sender, shareBalance);

        // Check if the vault has an adapter.
        if (address(vault.adapter) != address(0)) {
            // Check: the deposit token is staked with the adapter.
            if (vault.isStakedWithAdapter) {
                // Interaction: unstake all tokens via the adapter.
                // TODO: transfer entire fee to comptroller admin instead of transferring when user redeems.
                _unstakeFullAmountViaAdapter(vaultId);

                // Effect: set isStakedWithAdapter to false.
                vault.isStakedWithAdapter = false;
            }

            // Calculate the amount to transfer and the fee.
            (amountToTransfer, feeAmount) =
                vault.adapter.calculateAmountToTransferWithYield(vaultId, msg.sender, shareBalance);

            // Interaction: transfer the fee to the comptroller address.
            if (feeAmount > 0) {
                vault.token.safeTransfer(address(comptroller), feeAmount);
            }
        }
        // Otherwise, check that `msg.value` is greater than or equal to the minimum fee required.
        else {
            // Get the minimum fee from the comptroller.
            uint256 minFeeWei = comptroller.calculateMinFeeWei({ protocol: ISablierComptroller.Protocol.Bob });

            // Check: `msg.value` is greater than or equal to the minimum fee.
            if (msg.value < minFeeWei) {
                revert Errors.SablierBob_InsufficientFeePayment(msg.value, minFeeWei);
            }

            // Interaction: forward native token fee to comptroller.
            if (msg.value > 0) {
                (bool success,) = address(comptroller).call{ value: msg.value }("");
                if (!success) {
                    revert Errors.SablierBob_NativeFeeTransferFailed();
                }
            }

            // Return the transferred amount.
            amountToTransfer = shareBalance;
        }

        // Interaction: transfer tokens to the caller.
        vault.token.safeTransfer(msg.sender, amountToTransfer);

        // Log the event.
        emit Redeem(vaultId, msg.sender, amountToTransfer, shareBalance, feeAmount);
    }

    /// @inheritdoc ISablierBob
    function setDefaultAdapter(IERC20 token, ISablierBobAdapter newAdapter) external override onlyComptroller {
        // Check: the new adapter implements the {ISablierBobAdapter} interface.
        if (address(newAdapter) != address(0)) {
            bytes4 interfaceId = type(ISablierBobAdapter).interfaceId;
            if (!IERC165(address(newAdapter)).supportsInterface(interfaceId)) {
                revert Errors.SablierBob_NewAdapterMissesInterface(address(newAdapter));
            }
        }

        // Effect: set the default adapter for the token.
        defaultAdapters[token] = newAdapter;

        // Log the adapter change.
        emit SetDefaultAdapter(token, newAdapter);
    }

    /// @inheritdoc ISablierBob
    function syncPriceFromOracle(uint256 vaultId)
        external
        override
        nonReentrant
        notNull(vaultId)
        returns (uint128 latestPrice)
    {
        // Check: the vault is not already settled.
        if (_statusOf(vaultId) == Bob.Status.SETTLED) {
            revert Errors.SablierBob_VaultSettled(vaultId);
        }

        // Effect: sync the oracle price.
        latestPrice = _syncPriceFromOracle(vaultId);
    }

    /// @inheritdoc ISablierBob
    function unstakeTokensViaAdapter(uint256 vaultId)
        external
        override
        nonReentrant
        notNull(vaultId)
        returns (uint128 amountReceivedFromAdapter)
    {
        Bob.Vault storage vault = _vaults[vaultId];

        // Check: the vault is settled.
        if (_statusOf(vaultId) != Bob.Status.SETTLED) {
            // Effect: sync the oracle price.
            _syncPriceFromOracle(vaultId);

            // If it's still not settled after the sync, revert.
            if (_statusOf(vaultId) != Bob.Status.SETTLED) {
                revert Errors.SablierBob_VaultNotSettled(vaultId);
            }
        }

        // Check: the vault has an adapter.
        if (address(vault.adapter) == address(0)) {
            revert Errors.SablierBob_VaultHasNoAdapter(vaultId);
        }

        // Check: the vault has not already been unstaked.
        if (!vault.isStakedWithAdapter) {
            revert Errors.SablierBob_VaultAlreadyUnstaked(vaultId);
        }

        // Check: there is something to unstake.
        if (vault.adapter.getTotalYieldBearingTokenBalance(vaultId) == 0) {
            revert Errors.SablierBob_UnstakeAmountZero(vaultId);
        }

        // Effect: mark the vault as not staked with the adapter.
        _vaults[vaultId].isStakedWithAdapter = false;

        // Interaction: unstake all tokens via the adapter.
        amountReceivedFromAdapter = _unstakeFullAmountViaAdapter(vaultId);
    }

    /// @inheritdoc ISablierBob
    function onShareTransfer(
        uint256 vaultId,
        address from,
        address to,
        uint256 amount,
        uint256 fromBalanceBefore
    )
        external
        override
    {
        // Check: caller is the share token for this vault.
        if (msg.sender != address(_vaults[vaultId].shareToken)) {
            revert Errors.SablierBob_CallerNotShareToken(vaultId, msg.sender);
        }

        if (address(_vaults[vaultId].adapter) != address(0)) {
            // Interaction: update staked token holding of the user in the adapter.
            _vaults[vaultId].adapter.updateStakedTokenBalance(vaultId, from, to, amount, fromBalanceBefore);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                         INTERNAL STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Internal function to fetch the latest oracle price and update it in the vault storage.
    /// @param vaultId The ID of the vault.
    /// @return latestPrice The latest price from the oracle.
    function _syncPriceFromOracle(uint256 vaultId) internal returns (uint128 latestPrice) {
        AggregatorV3Interface oracleAddress = _vaults[vaultId].oracle;

        // Get the latest price from the oracle with safety checks.
        latestPrice = SafeOracle.safeOraclePrice(oracleAddress);

        // Effect: update the last synced price and timestamp if the latest price is greater than zero.
        if (latestPrice > 0) {
            _vaults[vaultId].lastSyncedPrice = latestPrice;
            _vaults[vaultId].lastSyncedAt = uint40(block.timestamp);
        }

        // Log the event.
        emit SyncPriceFromOracle(vaultId, oracleAddress, latestPrice, uint40(block.timestamp));
    }

    /// @dev Internal function to unstake all tokens using the adapter.
    /// @param vaultId The ID of the vault.
    /// @return amountReceivedFromAdapter The amount of tokens received from the adapter after unstaking.
    function _unstakeFullAmountViaAdapter(uint256 vaultId) internal returns (uint128 amountReceivedFromAdapter) {
        Bob.Vault storage vault = _vaults[vaultId];

        // Get the total amount staked via the adapter.
        uint128 amountStakedViaAdapter = vault.adapter.getTotalYieldBearingTokenBalance(vaultId);

        // Interaction: unstake all tokens via the adapter.
        amountReceivedFromAdapter = vault.adapter.unstakeFullAmount(vaultId);

        // Log the event.
        emit UnstakeFromAdapter(vaultId, vault.adapter, amountStakedViaAdapter, amountReceivedFromAdapter);
    }
}
