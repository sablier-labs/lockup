// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { BaseTest as EvmUtilsBase } from "@sablier/evm-utils/src/tests/BaseTest.sol";

import { Constants } from "./Constants.sol";

abstract contract Modifiers is Constants, EvmUtilsBase {
    /*//////////////////////////////////////////////////////////////////////////
                                   VAULT EXISTENCE
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenNotNull() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   VAULT STATUS
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenActive() {
        _;
    }

    modifier givenNotSettled() {
        _;
    }

    modifier givenSettled() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   VAULT ADAPTER
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenAdapter() {
        _;
    }

    modifier givenAlreadyUnstaked() {
        _;
    }

    modifier givenNoAdapter() {
        _;
    }

    modifier givenNothingToUnstake() {
        _;
    }

    modifier givenNotUnstaked() {
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

    modifier whenExpiryInFuture() {
        _;
    }

    modifier whenExpiryInPast() {
        _;
    }

    modifier whenOracleDoesNotRevert() {
        _;
    }

    modifier whenOracleDoesNotRevertOnDecimals() {
        _;
    }

    modifier whenOracleNotZeroAddress() {
        _;
    }

    modifier whenOracleReturnsEightDecimals() {
        _;
    }

    modifier whenOracleReturnsInvalidDecimals() {
        _;
    }

    modifier whenOracleReturnsInvalidPrice() {
        _;
    }

    modifier whenOracleReturnsValidPrice() {
        _;
    }

    modifier whenOracleRevertsOnLatestRoundData() {
        _;
    }

    modifier whenOracleZeroAddress() {
        _;
    }

    modifier whenTargetPriceAboveCurrentPrice() {
        _;
    }

    modifier whenTargetPriceAtOrBelowCurrentPrice() {
        _;
    }

    modifier whenTargetPriceNotZero() {
        _;
    }

    modifier whenTargetPriceZero() {
        _;
    }

    modifier whenTokenAddressNotZero() {
        _;
    }

    modifier whenTokenAddressZero() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       ENTER
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenFirstDeposit() {
        _;
    }

    modifier givenSubsequentDeposit() {
        _;
    }

    modifier whenAmountNotZero() {
        _;
    }

    modifier whenAmountZero() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                               EXIT WITHIN GRACE PERIOD
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenCallerHasShares() {
        _;
    }

    modifier whenCallerIsOriginalDepositor() {
        _;
    }

    modifier whenGracePeriodExpired() {
        _;
    }

    modifier whenNoSharesToRedeem() {
        _;
    }

    modifier whenWithinGracePeriod() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       REDEEM
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenNoPositiveYield() {
        _;
    }

    modifier givenPositiveYield() {
        _;
    }

    modifier whenFeePaymentInsufficient() {
        _;
    }

    modifier whenFeePaymentSufficient() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        SYNC
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenSyncedPriceAtOrAboveTarget() {
        _;
    }

    modifier whenSyncedPriceBelowTarget() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    SET NATIVE TOKEN
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenNativeTokenAlreadySet() {
        _;
    }

    modifier givenNativeTokenNotSet() {
        _;
    }

    modifier whenProvidedAddressNotZero() {
        _;
    }

    modifier whenTokenNotNativeToken() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET DEFAULT ADAPTER
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenAdapterDoesNotSupportInterface() {
        _;
    }

    modifier whenAdapterNotZeroAddress() {
        _;
    }

    modifier whenAdapterSupportsInterface() {
        _;
    }

    modifier whenAdapterZeroAddress() {
        _;
    }

    modifier whenCallerComptroller() {
        setMsgSender(address(comptroller));
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
