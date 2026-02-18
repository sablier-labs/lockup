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
                                   ORDER EXISTENCE
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenNotNullOrder() {
        _;
    }

    modifier givenNullOrder() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    ORDER STATUS
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenOrderCanceled() {
        _;
    }

    modifier givenOrderExpired() {
        _;
    }

    modifier givenOrderFilled() {
        _;
    }

    modifier givenOrderNotOpen() {
        _;
    }

    modifier givenOrderOpen() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   CREATE ORDER
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenBuyTokenNotZero() {
        _;
    }

    modifier whenBuyTokenZero() {
        _;
    }

    modifier whenExpiryTimeInPast() {
        _;
    }

    modifier whenExpiryTimeValidOrZero() {
        _;
    }

    modifier whenMinBuyAmountNotZero() {
        _;
    }

    modifier whenMinBuyAmountZero() {
        _;
    }

    modifier whenSellAmountNotZero() {
        _;
    }

    modifier whenSellAmountZero() {
        _;
    }

    modifier whenSellTokenNotZero() {
        _;
    }

    modifier whenSellTokenZero() {
        _;
    }

    modifier whenTokensNotSame() {
        _;
    }

    modifier whenTokensSame() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    FILL ORDER
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenOrderHasDesignatedBuyer() {
        _;
    }

    modifier givenOrderHasNoBuyer() {
        _;
    }

    modifier givenTradeFeeNonZero() {
        _;
    }

    modifier givenTradeFeeZero() {
        _;
    }

    modifier whenBuyAmountInsufficient() {
        _;
    }

    modifier whenBuyAmountSufficient() {
        _;
    }

    modifier whenCallerDesignatedBuyer() {
        _;
    }

    modifier whenCallerNotDesignatedBuyer() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   CANCEL ORDER
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenCallerNotSeller() {
        _;
    }

    modifier whenCallerSeller() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET TRADE FEE
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenCallerComptroller() {
        setMsgSender(address(comptroller));
        _;
    }

    modifier whenCallerNotComptroller() {
        _;
    }

    modifier whenFeeExceedsMax() {
        _;
    }

    modifier whenFeeWithinLimit() {
        _;
    }
}
