// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { BaseTest as EvmUtilsBase } from "@sablier/evm-utils/src/tests/BaseTest.sol";

import { Constants } from "./Constants.sol";
import { Defaults } from "./Defaults.sol";
import { Users } from "./Types.sol";

abstract contract Modifiers is Constants, EvmUtilsBase {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Defaults internal defaults;
    Users internal users;

    function setVariables(Defaults _defaults, Users memory _users) public {
        defaults = _defaults;
        users = _users;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   VAULT EXISTENCE
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenNotNullVault() {
        _;
    }

    modifier givenNullVault() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   VAULT STATUS
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenVaultSettled() {
        _;
    }

    modifier givenVaultExpired() {
        _;
    }

    modifier givenVaultActive() {
        _;
    }

    modifier givenVaultNotSettled() {
        _;
    }

    modifier givenVaultAlreadySettled() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   VAULT ADAPTER
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenVaultHasAdapter() {
        _;
    }

    modifier givenVaultHasNoAdapter() {
        _;
    }

    modifier givenVaultAlreadyUnstaked() {
        _;
    }

    modifier givenVaultNotUnstaked() {
        _;
    }

    modifier givenNothingToUnstake() {
        _;
    }

    modifier givenSomethingToUnstake() {
        _;
    }

    modifier whenSlippageExceeded() {
        _;
    }

    modifier whenSlippageWithinTolerance() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CREATE VAULT
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenTokenAddressNotZero() {
        _;
    }

    modifier whenTokenAddressZero() {
        _;
    }

    modifier whenExpiryInFuture() {
        _;
    }

    modifier whenExpiryInPast() {
        _;
    }

    modifier whenOracleNotZeroAddress() {
        _;
    }

    modifier whenOracleZeroAddress() {
        _;
    }

    modifier whenOracleReturnsValidPrice() {
        _;
    }

    modifier whenOracleReturnsInvalidPrice() {
        _;
    }

    modifier whenOracleDoesNotRevert() {
        _;
    }

    modifier whenOracleReturnsEightDecimals() {
        _;
    }

    modifier whenOracleReturnsInvalidDecimals() {
        _;
    }

    modifier whenOracleRevertsOnLatestRoundData() {
        _;
    }

    modifier whenOracleDoesNotRevertOnDecimals() {
        _;
    }

    modifier whenTargetPriceNotZero() {
        _;
    }

    modifier whenTargetPriceZero() {
        _;
    }

    modifier whenTargetPriceAboveCurrentPrice() {
        _;
    }

    modifier whenTargetPriceAtOrBelowCurrentPrice() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       ENTER
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenAmountNotZero() {
        _;
    }

    modifier whenAmountZero() {
        _;
    }

    modifier givenFirstDeposit() {
        _;
    }

    modifier givenSubsequentDeposit() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                               EXIT WITHIN GRACE PERIOD
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenNoSharesToRedeem() {
        _;
    }

    modifier whenCallerHasShares() {
        _;
    }

    modifier whenWithinGracePeriod() {
        _;
    }

    modifier whenGracePeriodExpired() {
        _;
    }

    modifier whenCallerIsOriginalDepositor() {
        _;
    }

    modifier whenCallerNotOriginalDepositor() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       REDEEM
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenFeePaymentSufficient() {
        _;
    }

    modifier whenFeePaymentInsufficient() {
        _;
    }

    modifier givenPositiveYield() {
        _;
    }

    modifier givenNoPositiveYield() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        SYNC
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenSyncedPriceBelowTarget() {
        _;
    }

    modifier whenSyncedPriceAtOrAboveTarget() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET DEFAULT ADAPTER
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenCallerComptroller() {
        setMsgSender(address(comptroller));
        _;
    }

    modifier whenCallerNotComptroller() {
        _;
    }

    modifier whenAdapterNotZeroAddress() {
        _;
    }

    modifier whenAdapterZeroAddress() {
        _;
    }

    modifier whenAdapterSupportsInterface() {
        _;
    }

    modifier whenAdapterDoesNotSupportInterface() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   SET YIELD FEE
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenFeeExceedsMax() {
        _;
    }

    modifier whenFeeWithinLimit() {
        _;
    }
}
