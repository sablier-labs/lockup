// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Lockup } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../Integration.t.sol";
import { Cancel_Integration_Fuzz_Test } from "./../lockup-base/cancel.t.sol";
import { RefundableAmountOf_Integration_Fuzz_Test } from "./../lockup-base/refundableAmountOf.t.sol";
import { Withdraw_Integration_Fuzz_Test } from "./../lockup-base/withdraw.t.sol";

abstract contract Lockup_Linear_Integration_Fuzz_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();

        lockupModel = Lockup.Model.LOCKUP_LINEAR;
        initializeDefaultStreams();
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

contract Cancel_Lockup_Linear_Integration_Fuzz_Test is
    Lockup_Linear_Integration_Fuzz_Test,
    Cancel_Integration_Fuzz_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Fuzz_Test, Integration_Test) {
        Lockup_Linear_Integration_Fuzz_Test.setUp();
    }
}

contract RefundableAmountOf_Lockup_Linear_Integration_Fuzz_Test is
    Lockup_Linear_Integration_Fuzz_Test,
    RefundableAmountOf_Integration_Fuzz_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Fuzz_Test, Integration_Test) {
        Lockup_Linear_Integration_Fuzz_Test.setUp();
    }
}

contract Withdraw_Lockup_Linear_Integration_Fuzz_Test is
    Lockup_Linear_Integration_Fuzz_Test,
    Withdraw_Integration_Fuzz_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Fuzz_Test, Integration_Test) {
        Lockup_Linear_Integration_Fuzz_Test.setUp();
    }
}
