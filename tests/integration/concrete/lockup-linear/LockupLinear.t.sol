// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Lockup } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../Integration.t.sol";
import { Cancel_Integration_Concrete_Test } from "../lockup-base/cancel/cancel.t.sol";
import { RefundableAmountOf_Integration_Concrete_Test } from
    "../lockup-base/refundable-amount-of/refundableAmountOf.t.sol";
import { Renounce_Integration_Concrete_Test } from "../lockup-base/renounce/renounce.t.sol";
import { Withdraw_Integration_Concrete_Test } from "../lockup-base/withdraw/withdraw.t.sol";

abstract contract Lockup_Linear_Integration_Concrete_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();

        lockupModel = Lockup.Model.LOCKUP_LINEAR;
        initializeDefaultStreams();
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

contract Cancel_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Concrete_Test,
    Cancel_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Concrete_Test, Integration_Test) {
        Lockup_Linear_Integration_Concrete_Test.setUp();
    }
}

contract RefundableAmountOf_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Concrete_Test,
    RefundableAmountOf_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Concrete_Test, Integration_Test) {
        Lockup_Linear_Integration_Concrete_Test.setUp();
    }
}

contract Renounce_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Concrete_Test,
    Renounce_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Concrete_Test, Integration_Test) {
        Lockup_Linear_Integration_Concrete_Test.setUp();
    }
}

contract Withdraw_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Concrete_Test,
    Withdraw_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Concrete_Test, Integration_Test) {
        Lockup_Linear_Integration_Concrete_Test.setUp();
    }
}
