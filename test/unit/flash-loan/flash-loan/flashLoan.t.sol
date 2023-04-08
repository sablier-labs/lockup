// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { IERC3156FlashBorrower } from "erc3156/interfaces/IERC3156FlashBorrower.sol";
import { IERC3156FlashLender } from "erc3156/interfaces/IERC3156FlashLender.sol";

import { Errors } from "src/libraries/Errors.sol";

import { FlashLoan_Unit_Test } from "../FlashLoan.t.sol";

contract FlashLoanFunction_Unit_Test is FlashLoan_Unit_Test {
    uint128 internal constant LIQUIDITY_AMOUNT = 8_755_001e18;

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(
            IERC3156FlashLender.flashLoan, (IERC3156FlashBorrower(address(0)), address(DEFAULT_ASSET), 0, bytes(""))
        );
        (bool success, bytes memory returnData) = address(flashLoan).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    modifier whenNoDelegateCall() {
        _;
    }

    function test_RevertWhen_AmountTooHigh() external whenNoDelegateCall {
        uint256 amount = uint256(UINT128_MAX) + 1;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2FlashLoan_AmountTooHigh.selector, amount));
        flashLoan.flashLoan({
            receiver: IERC3156FlashBorrower(address(0)),
            asset: address(DEFAULT_ASSET),
            amount: amount,
            data: bytes("")
        });
    }

    modifier whenAmountNotTooHigh() {
        _;
    }

    function test_RevertWhen_AssetNotFlashLoanable() external whenNoDelegateCall whenAmountNotTooHigh {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2FlashLoan_AssetNotFlashLoanable.selector, DEFAULT_ASSET));
        flashLoan.flashLoan({
            receiver: IERC3156FlashBorrower(address(0)),
            asset: address(DEFAULT_ASSET),
            amount: 0,
            data: bytes("")
        });
    }

    modifier whenAssetFlashLoanable() {
        comptroller.toggleFlashAsset(DEFAULT_ASSET);
        _;
    }

    function test_RevertWhen_CalculatedFeeTooHigh()
        external
        whenNoDelegateCall
        whenAmountNotTooHigh
        whenAssetFlashLoanable
    {
        // Set the comptroller flash fee so that the calculated fee ends up being greater than 2^128.
        comptroller.setFlashFee({ newFlashFee: ud(1.1e18) });

        uint256 fee = flashLoan.flashFee({ asset: address(DEFAULT_ASSET), amount: UINT128_MAX });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2FlashLoan_CalculatedFeeTooHigh.selector, fee));
        flashLoan.flashLoan({
            receiver: IERC3156FlashBorrower(address(0)),
            asset: address(DEFAULT_ASSET),
            amount: UINT128_MAX,
            data: bytes("")
        });
    }

    modifier whenCalculatedFeeNotTooHigh() {
        _;
    }

    function test_RevertWhen_InsufficientAssetLiquidity()
        external
        whenNoDelegateCall
        whenAmountNotTooHigh
        whenAssetFlashLoanable
        whenCalculatedFeeNotTooHigh
    {
        uint128 amount = 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2FlashLoan_InsufficientAssetLiquidity.selector, DEFAULT_ASSET, 0, amount
            )
        );
        flashLoan.flashLoan({
            receiver: IERC3156FlashBorrower(address(0)),
            asset: address(DEFAULT_ASSET),
            amount: amount,
            data: bytes("")
        });
    }

    modifier whenSufficientAssetLiquidity() {
        // Mint the flash loan amount to the contract.
        deal({ token: address(DEFAULT_ASSET), to: address(flashLoan), give: LIQUIDITY_AMOUNT });
        _;
    }

    function test_RevertWhen_BorrowFailed()
        external
        whenNoDelegateCall
        whenAmountNotTooHigh
        whenAssetFlashLoanable
        whenCalculatedFeeNotTooHigh
        whenSufficientAssetLiquidity
    {
        vm.expectRevert(Errors.SablierV2FlashLoan_FlashBorrowFail.selector);
        flashLoan.flashLoan({
            receiver: faultyFlashLoanReceiver,
            asset: address(DEFAULT_ASSET),
            amount: LIQUIDITY_AMOUNT,
            data: bytes("")
        });
    }

    modifier whenBorrowDoesNotFail() {
        _;
    }

    function test_RevertWhen_Reentrancy()
        external
        whenNoDelegateCall
        whenAmountNotTooHigh
        whenAssetFlashLoanable
        whenCalculatedFeeNotTooHigh
        whenSufficientAssetLiquidity
        whenBorrowDoesNotFail
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2FlashLoan_InsufficientAssetLiquidity.selector, DEFAULT_ASSET, 0, LIQUIDITY_AMOUNT / 4
            )
        );
        flashLoan.flashLoan({
            receiver: reentrantFlashLoanReceiver,
            asset: address(DEFAULT_ASSET),
            amount: LIQUIDITY_AMOUNT / 4,
            data: bytes("")
        });
    }

    modifier whenNoReentrancy() {
        _;
    }

    function test_FlashLoan()
        external
        whenNoDelegateCall
        whenAmountNotTooHigh
        whenAssetFlashLoanable
        whenCalculatedFeeNotTooHigh
        whenSufficientAssetLiquidity
        whenBorrowDoesNotFail
        whenNoReentrancy
    {
        // Load the initial protocol revenues.
        uint128 initialProtocolRevenues = flashLoan.protocolRevenues(DEFAULT_ASSET);

        // Load the flash fee.
        uint256 fee = flashLoan.flashFee({ asset: address(DEFAULT_ASSET), amount: LIQUIDITY_AMOUNT });

        // Mint the flash fee to the receiver so that they can repay the flash loan.
        deal({ token: address(DEFAULT_ASSET), to: address(goodFlashLoanReceiver), give: fee });

        // Expect `amount` of assets to be transferred from {SablierV2FlashLoan} to the receiver.
        expectTransferCall({ to: address(goodFlashLoanReceiver), amount: LIQUIDITY_AMOUNT });

        // Expect `amount+fee` of assets to be transferred back from the receiver.
        uint256 returnAmount = LIQUIDITY_AMOUNT + fee;
        expectTransferFromCall({ from: address(goodFlashLoanReceiver), to: address(flashLoan), amount: returnAmount });

        // Expect a {FlashLoan} event to be emitted.
        vm.expectEmit({ emitter: address(flashLoan) });
        bytes memory data = bytes("Hello World");
        emit FlashLoan({
            initiator: users.admin,
            receiver: goodFlashLoanReceiver,
            asset: DEFAULT_ASSET,
            amount: LIQUIDITY_AMOUNT,
            feeAmount: fee,
            data: data
        });

        // Execute the flash loan.
        bool response = flashLoan.flashLoan({
            receiver: goodFlashLoanReceiver,
            asset: address(DEFAULT_ASSET),
            amount: LIQUIDITY_AMOUNT,
            data: data
        });

        // Assert that the returned response is `true`.
        assertTrue(response, "flashLoan response");

        // Assert that the protocol fee has been recorded.
        uint128 actualProtocolRevenues = linear.protocolRevenues(DEFAULT_ASSET);
        uint128 expectedProtocolRevenues = initialProtocolRevenues + uint128(fee);
        assertEq(actualProtocolRevenues, expectedProtocolRevenues, "protocolRevenues");
    }
}
