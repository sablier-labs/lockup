// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Integration_Test } from "./../../Integration.t.sol";
import { LockupTranched_Integration_Shared_Test } from "./../../shared/lockup-tranched/LockupTranched.t.sol";
import { AllowToHook_Integration_Concrete_Test } from "./../lockup/allow-to-hook/allowToHook.t.sol";
import { Burn_Integration_Concrete_Test } from "./../lockup/burn/burn.t.sol";
import { CancelMultiple_Integration_Concrete_Test } from "./../lockup/cancel-multiple/cancelMultiple.t.sol";
import { Cancel_Integration_Concrete_Test } from "./../lockup/cancel/cancel.t.sol";
import { GetAsset_Integration_Concrete_Test } from "./../lockup/get-asset/getAsset.t.sol";
import { GetDepositedAmount_Integration_Concrete_Test } from "./../lockup/get-deposited-amount/getDepositedAmount.t.sol";
import { GetEndTime_Integration_Concrete_Test } from "./../lockup/get-end-time/getEndTime.t.sol";
import { GetRecipient_Integration_Concrete_Test } from "./../lockup/get-recipient/getRecipient.t.sol";
import { GetRefundedAmount_Integration_Concrete_Test } from "./../lockup/get-refunded-amount/getRefundedAmount.t.sol";
import { GetSender_Integration_Concrete_Test } from "./../lockup/get-sender/getSender.t.sol";
import { GetStartTime_Integration_Concrete_Test } from "./../lockup/get-start-time/getStartTime.t.sol";
import { GetWithdrawnAmount_Integration_Concrete_Test } from "./../lockup/get-withdrawn-amount/getWithdrawnAmount.t.sol";
import { IsAllowedToHook_Integration_Concrete_Test } from "./../lockup/is-allowed-to-hook/isAllowedToHook.t.sol";
import { IsCancelable_Integration_Concrete_Test } from "./../lockup/is-cancelable/isCancelable.t.sol";
import { IsCold_Integration_Concrete_Test } from "./../lockup/is-cold/isCold.t.sol";
import { IsDepleted_Integration_Concrete_Test } from "./../lockup/is-depleted/isDepleted.t.sol";
import { IsStream_Integration_Concrete_Test } from "./../lockup/is-stream/isStream.t.sol";
import { IsTransferable_Integration_Concrete_Test } from "./../lockup/is-transferable/isTransferable.t.sol";
import { IsWarm_Integration_Concrete_Test } from "./../lockup/is-warm/isWarm.t.sol";
import { RefundableAmountOf_Integration_Concrete_Test } from "./../lockup/refundable-amount-of/refundableAmountOf.t.sol";
import { Renounce_Integration_Concrete_Test } from "./../lockup/renounce/renounce.t.sol";
import { SetNFTDescriptor_Integration_Concrete_Test } from "./../lockup/set-nft-descriptor/setNFTDescriptor.t.sol";
import { StatusOf_Integration_Concrete_Test } from "./../lockup/status-of/statusOf.t.sol";
import { TransferFrom_Integration_Concrete_Test } from "./../lockup/transfer-from/transferFrom.t.sol";
import { WasCanceled_Integration_Concrete_Test } from "./../lockup/was-canceled/wasCanceled.t.sol";
import { WithdrawHooks_Integration_Concrete_Test } from "./../lockup/withdraw-hooks/withdrawHooks.t.sol";
import { WithdrawMaxAndTransfer_Integration_Concrete_Test } from
    "./../lockup/withdraw-max-and-transfer/withdrawMaxAndTransfer.t.sol";
import { WithdrawMax_Integration_Concrete_Test } from "./../lockup/withdraw-max/withdrawMax.t.sol";
import { WithdrawMultiple_Integration_Concrete_Test } from "./../lockup/withdraw-multiple/withdrawMultiple.t.sol";
import { Withdraw_Integration_Concrete_Test } from "./../lockup/withdraw/withdraw.t.sol";

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

contract AllowToHook_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Shared_Test,
    AllowToHook_Integration_Concrete_Test
{
    function setUp() public virtual override(LockupTranched_Integration_Shared_Test, Integration_Test) {
        LockupTranched_Integration_Shared_Test.setUp();
    }
}

contract Burn_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Shared_Test,
    Burn_Integration_Concrete_Test
{
    function setUp() public virtual override(LockupTranched_Integration_Shared_Test, Integration_Test) {
        LockupTranched_Integration_Shared_Test.setUp();
    }
}

contract Cancel_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Shared_Test,
    Cancel_Integration_Concrete_Test
{
    function setUp() public virtual override(LockupTranched_Integration_Shared_Test, Integration_Test) {
        LockupTranched_Integration_Shared_Test.setUp();
    }
}

contract CancelMultiple_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Shared_Test,
    CancelMultiple_Integration_Concrete_Test
{
    function setUp()
        public
        virtual
        override(LockupTranched_Integration_Shared_Test, CancelMultiple_Integration_Concrete_Test)
    {
        LockupTranched_Integration_Shared_Test.setUp();
        CancelMultiple_Integration_Concrete_Test.setUp();
    }
}

contract GetAsset_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Shared_Test,
    GetAsset_Integration_Concrete_Test
{
    function setUp() public virtual override(LockupTranched_Integration_Shared_Test, Integration_Test) {
        LockupTranched_Integration_Shared_Test.setUp();
    }
}

contract GetDepositedAmount_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Shared_Test,
    GetDepositedAmount_Integration_Concrete_Test
{
    function setUp() public virtual override(LockupTranched_Integration_Shared_Test, Integration_Test) {
        LockupTranched_Integration_Shared_Test.setUp();
    }
}

contract GetEndTime_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Shared_Test,
    GetEndTime_Integration_Concrete_Test
{
    function setUp() public virtual override(LockupTranched_Integration_Shared_Test, Integration_Test) {
        LockupTranched_Integration_Shared_Test.setUp();
    }
}

contract GetRecipient_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Shared_Test,
    GetRecipient_Integration_Concrete_Test
{
    function setUp() public virtual override(LockupTranched_Integration_Shared_Test, Integration_Test) {
        LockupTranched_Integration_Shared_Test.setUp();
    }
}

contract GetRefundedAmount_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Shared_Test,
    GetRefundedAmount_Integration_Concrete_Test
{
    function setUp() public virtual override(LockupTranched_Integration_Shared_Test, Integration_Test) {
        LockupTranched_Integration_Shared_Test.setUp();
    }
}

contract GetSender_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Shared_Test,
    GetSender_Integration_Concrete_Test
{
    function setUp() public virtual override(LockupTranched_Integration_Shared_Test, Integration_Test) {
        LockupTranched_Integration_Shared_Test.setUp();
    }
}

contract GetStartTime_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Shared_Test,
    GetStartTime_Integration_Concrete_Test
{
    function setUp() public virtual override(LockupTranched_Integration_Shared_Test, Integration_Test) {
        LockupTranched_Integration_Shared_Test.setUp();
    }
}

contract GetWithdrawnAmount_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Shared_Test,
    GetWithdrawnAmount_Integration_Concrete_Test
{
    function setUp() public virtual override(LockupTranched_Integration_Shared_Test, Integration_Test) {
        LockupTranched_Integration_Shared_Test.setUp();
    }
}

contract IsAllowedToHook_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Shared_Test,
    IsAllowedToHook_Integration_Concrete_Test
{
    function setUp() public virtual override(LockupTranched_Integration_Shared_Test, Integration_Test) {
        LockupTranched_Integration_Shared_Test.setUp();
    }
}

contract IsCancelable_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Shared_Test,
    IsCancelable_Integration_Concrete_Test
{
    function setUp() public virtual override(LockupTranched_Integration_Shared_Test, Integration_Test) {
        LockupTranched_Integration_Shared_Test.setUp();
    }
}

contract IsCold_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Shared_Test,
    IsCold_Integration_Concrete_Test
{
    function setUp() public virtual override(LockupTranched_Integration_Shared_Test, Integration_Test) {
        LockupTranched_Integration_Shared_Test.setUp();
    }
}

contract IsDepleted_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Shared_Test,
    IsDepleted_Integration_Concrete_Test
{
    function setUp() public virtual override(LockupTranched_Integration_Shared_Test, Integration_Test) {
        LockupTranched_Integration_Shared_Test.setUp();
    }
}

contract IsStream_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Shared_Test,
    IsStream_Integration_Concrete_Test
{
    function setUp() public virtual override(LockupTranched_Integration_Shared_Test, Integration_Test) {
        LockupTranched_Integration_Shared_Test.setUp();
    }
}

contract IsTransferable_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Shared_Test,
    IsTransferable_Integration_Concrete_Test
{
    function setUp() public virtual override(LockupTranched_Integration_Shared_Test, Integration_Test) {
        LockupTranched_Integration_Shared_Test.setUp();
    }
}

contract IsWarm_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Shared_Test,
    IsWarm_Integration_Concrete_Test
{
    function setUp() public virtual override(LockupTranched_Integration_Shared_Test, Integration_Test) {
        LockupTranched_Integration_Shared_Test.setUp();
    }
}

contract RefundableAmountOf_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Shared_Test,
    RefundableAmountOf_Integration_Concrete_Test
{
    function setUp() public virtual override(LockupTranched_Integration_Shared_Test, Integration_Test) {
        LockupTranched_Integration_Shared_Test.setUp();
    }
}

contract Renounce_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Shared_Test,
    Renounce_Integration_Concrete_Test
{
    function setUp() public virtual override(LockupTranched_Integration_Shared_Test, Integration_Test) {
        LockupTranched_Integration_Shared_Test.setUp();
    }
}

contract SetNFTDescriptor_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Shared_Test,
    SetNFTDescriptor_Integration_Concrete_Test
{
    function setUp() public virtual override(LockupTranched_Integration_Shared_Test, Integration_Test) {
        LockupTranched_Integration_Shared_Test.setUp();
    }
}

contract StatusOf_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Shared_Test,
    StatusOf_Integration_Concrete_Test
{
    function setUp() public virtual override(LockupTranched_Integration_Shared_Test, Integration_Test) {
        LockupTranched_Integration_Shared_Test.setUp();
    }
}

contract TransferFrom_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Shared_Test,
    TransferFrom_Integration_Concrete_Test
{
    function setUp()
        public
        virtual
        override(LockupTranched_Integration_Shared_Test, TransferFrom_Integration_Concrete_Test)
    {
        LockupTranched_Integration_Shared_Test.setUp();
        TransferFrom_Integration_Concrete_Test.setUp();
    }
}

contract WasCanceled_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Shared_Test,
    WasCanceled_Integration_Concrete_Test
{
    function setUp() public virtual override(LockupTranched_Integration_Shared_Test, Integration_Test) {
        LockupTranched_Integration_Shared_Test.setUp();
    }
}

contract Withdraw_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Shared_Test,
    Withdraw_Integration_Concrete_Test
{
    function setUp() public virtual override(LockupTranched_Integration_Shared_Test, Integration_Test) {
        LockupTranched_Integration_Shared_Test.setUp();
    }
}

contract WithdrawHooks_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Shared_Test,
    WithdrawHooks_Integration_Concrete_Test
{
    function setUp()
        public
        virtual
        override(LockupTranched_Integration_Shared_Test, WithdrawHooks_Integration_Concrete_Test)
    {
        LockupTranched_Integration_Shared_Test.setUp();
        WithdrawHooks_Integration_Concrete_Test.setUp();
    }
}

contract WithdrawMax_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Shared_Test,
    WithdrawMax_Integration_Concrete_Test
{
    function setUp() public virtual override(LockupTranched_Integration_Shared_Test, Integration_Test) {
        LockupTranched_Integration_Shared_Test.setUp();
    }
}

contract WithdrawMaxAndTransfer_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Shared_Test,
    WithdrawMaxAndTransfer_Integration_Concrete_Test
{
    function setUp() public virtual override(LockupTranched_Integration_Shared_Test, Integration_Test) {
        LockupTranched_Integration_Shared_Test.setUp();
    }
}

contract WithdrawMultiple_LockupTranched_Integration_Concrete_Test is
    LockupTranched_Integration_Shared_Test,
    WithdrawMultiple_Integration_Concrete_Test
{
    function setUp()
        public
        virtual
        override(LockupTranched_Integration_Shared_Test, WithdrawMultiple_Integration_Concrete_Test)
    {
        LockupTranched_Integration_Shared_Test.setUp();
        WithdrawMultiple_Integration_Concrete_Test.setUp();
    }
}
