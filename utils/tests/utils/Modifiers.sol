// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { BaseTest } from "src/tests/BaseTest.sol";

abstract contract Modifiers is BaseTest {
    /*//////////////////////////////////////////////////////////////////////////
                                       GIVEN
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenNotInitialized() {
        _;
    }

    modifier givenOracleNotZero() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        WHEN
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenAccountHasRole() {
        _;
    }

    modifier whenAccountNotAdmin() {
        _;
    }

    modifier whenAccountNotHaveRole() {
        _;
    }

    modifier whenAddressesHaveFee() {
        _;
    }

    modifier whenCallerAdmin() {
        setMsgSender(admin);
        _;
    }

    modifier whenCallerNotAdmin() {
        _;
    }

    modifier whenCallerCurrentComptroller() {
        setMsgSender(address(comptroller));
        _;
    }

    modifier whenCalledOnProxy() {
        _;
    }

    modifier whenCallerWithoutFeeCollectorRole() {
        _;
    }

    modifier whenCallReverts() {
        _;
    }

    modifier whenCampaignImplementsSablierMerkle() {
        _;
    }

    modifier whenCampaignReturnsTrueForSablierMerkle() {
        _;
    }

    modifier whenComptrollerWithMinimalInterfaceId() {
        _;
    }

    modifier whenDecimalsCallNotFail() {
        _;
    }

    modifier whenFeeRecipientContract() {
        _;
    }

    modifier whenFeeRecipientNotZero() {
        _;
    }

    modifier whenFunctionExists() {
        _;
    }

    modifier whenFeeUSDNotZero() {
        _;
    }

    modifier whenInitialAirdropFeeNotExceedMaxFee() {
        _;
    }

    modifier whenInitialFlowFeeNotExceedMaxFee() {
        _;
    }

    modifier whenLatestRoundCallNotFail() {
        _;
    }

    modifier whenNewAdminNotSameAsCurrentAdmin() {
        _;
    }

    modifier whenNewFeeNotExceedMaxFee() {
        _;
    }

    modifier whenNewOracleNotZero() {
        _;
    }

    modifier whenNonStateChangingFunction() {
        _;
    }

    modifier whenNotPayable() {
        _;
    }

    modifier whenOracleAddressNotZero() {
        _;
    }

    modifier whenOracleDecimals8() {
        _;
    }

    modifier whenOracleNotMissDecimals() {
        _;
    }

    modifier whenOracleNotMissLatestRoundData() {
        _;
    }

    modifier whenOraclePriceNotExceedUint128Max() {
        _;
    }

    modifier whenOraclePriceNotOutdated() {
        _;
    }

    modifier whenOraclePricePositive() {
        _;
    }

    modifier whenOracleUpdatedTimeNotInFuture() {
        _;
    }

    modifier whenRecipientNotZeroAddress() {
        _;
    }

    modifier whenSafeOraclePriceNotZero() {
        _;
    }

    modifier whenPayable() {
        _;
    }

    modifier whenAddressesImplementIComptrollerable() {
        _;
    }

    modifier whenStateChangingFunction() {
        _;
    }

    modifier whenTargetContract() {
        _;
    }

    modifier givenTokenBalanceNotZero() {
        _;
    }
}
