// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Escrow } from "src/types/Escrow.sol";

import { Base_Test } from "../Base.t.sol";

/// @notice Common logic needed by all integration tests, both concrete and fuzz tests.
abstract contract Integration_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        // Initialize default orders for testing.
        initializeDefaultOrders();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INITIALIZE-FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Initializes the default orders used in tests.
    function initializeDefaultOrders() internal {
        // Create a default order (open to any buyer).
        orderIds.defaultOrder = createDefaultOrder();

        // Create an order with designated buyer.
        orderIds.designatedBuyerOrder = createOrderWithDesignatedBuyer(users.buyer);

        // Create a canceled order.
        orderIds.canceledOrder = createCanceledOrder();

        // Create a filled order.
        orderIds.filledOrder = createFilledOrder();

        // Set a null order ID (one that doesn't exist).
        orderIds.nullOrder = 1729;

        // Create an expired order.
        // Note: This warps time forward, so create it last.
        vm.warp({ newTimestamp: FEB_1_2025 }); // Reset time first.
        setMsgSender(users.seller);
        orderIds.expiredOrder = createExpiredOrder();
        vm.warp({ newTimestamp: FEB_1_2025 }); // Reset time for other tests.
    }

    /*//////////////////////////////////////////////////////////////////////////
                                COMMON-REVERT-TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Expects a revert when the order is null.
    function expectRevert_NullOrder(bytes memory callData, uint256 nullOrderId) internal {
        (bool success, bytes memory returnData) = address(escrow).call(callData);
        assertFalse(success, "null order call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierEscrowState_Null.selector, nullOrderId),
            "null order call return data"
        );
    }

    /// @dev Expects a revert when the order is not open.
    function expectRevert_OrderNotOpen(bytes memory callData, uint256 orderId, Escrow.Status status) internal {
        (bool success, bytes memory returnData) = address(escrow).call(callData);
        assertFalse(success, "order not open call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierEscrow_OrderNotOpen.selector, orderId, status),
            "order not open call return data"
        );
    }

    /// @dev Expects a revert when the order is already filled.
    function expectRevert_OrderFilled(bytes memory callData, uint256 orderId) internal {
        (bool success, bytes memory returnData) = address(escrow).call(callData);
        assertFalse(success, "order filled call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierEscrow_OrderFilled.selector, orderId),
            "order filled return"
        );
    }

    /// @dev Expects a revert when the order is already canceled.
    function expectRevert_OrderCancelled(bytes memory callData, uint256 orderId) internal {
        (bool success, bytes memory returnData) = address(escrow).call(callData);
        assertFalse(success, "order cancelled call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierEscrow_OrderCancelled.selector, orderId),
            "order cancelled return"
        );
    }

    /// @dev Expects a revert when the caller is not authorized.
    function expectRevert_CallerNotAuthorized(
        bytes memory callData,
        uint256 orderId,
        address caller,
        address expectedCaller
    )
        internal
    {
        (bool success, bytes memory returnData) = address(escrow).call(callData);
        assertFalse(success, "caller not authorized call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierEscrow_CallerNotAuthorized.selector, orderId, caller, expectedCaller),
            "caller not authorized return data"
        );
    }

    /// @dev Expects a revert when the caller is not the comptroller.
    function expectRevert_NotComptroller(bytes memory callData) internal {
        setMsgSender(users.eve);
        (bool success, bytes memory returnData) = address(escrow).call(callData);
        assertFalse(success, "non-comptroller call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(
                EvmUtilsErrors.Comptrollerable_CallerNotComptroller.selector, address(comptroller), users.eve
            ),
            "non-comptroller call return data"
        );
    }

    /// @dev Expects a revert when the sell token is zero address.
    function expectRevert_SellTokenZero(bytes memory callData) internal {
        (bool success, bytes memory returnData) = address(escrow).call(callData);
        assertFalse(success, "sell token zero call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierEscrow_SellTokenZero.selector),
            "sell token zero return data"
        );
    }

    /// @dev Expects a revert when the buy token is zero address.
    function expectRevert_BuyTokenZero(bytes memory callData) internal {
        (bool success, bytes memory returnData) = address(escrow).call(callData);
        assertFalse(success, "buy token zero call success");
        assertEq(
            returnData, abi.encodeWithSelector(Errors.SablierEscrow_BuyTokenZero.selector), "buy token zero return data"
        );
    }

    /// @dev Expects a revert when sell and buy tokens are the same.
    function expectRevert_SameToken(bytes memory callData, IERC20 token) internal {
        (bool success, bytes memory returnData) = address(escrow).call(callData);
        assertFalse(success, "same token call success");
        assertEq(
            returnData, abi.encodeWithSelector(Errors.SablierEscrow_SameToken.selector, token), "same token return data"
        );
    }

    /// @dev Expects a revert when sell amount is zero.
    function expectRevert_SellAmountZero(bytes memory callData) internal {
        (bool success, bytes memory returnData) = address(escrow).call(callData);
        assertFalse(success, "sell amount zero call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierEscrow_SellAmountZero.selector),
            "sell amount zero return data"
        );
    }

    /// @dev Expects a revert when min buy amount is zero.
    function expectRevert_MinBuyAmountZero(bytes memory callData) internal {
        (bool success, bytes memory returnData) = address(escrow).call(callData);
        assertFalse(success, "min buy amount zero call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierEscrow_MinBuyAmountZero.selector),
            "min buy amount zero return data"
        );
    }

    /// @dev Expects a revert when expiryTime is in the past.
    function expectRevert_ExpiryTimeInPast(bytes memory callData, uint40 expiryTime, uint40 currentTime) internal {
        (bool success, bytes memory returnData) = address(escrow).call(callData);
        assertFalse(success, "expire at in past call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierEscrow_ExpiryTimeInPast.selector, expiryTime, currentTime),
            "expire at in past return data"
        );
    }

    /// @dev Expects a revert when buy amount is insufficient.
    function expectRevert_InsufficientBuyAmount(
        bytes memory callData,
        uint128 buyAmount,
        uint128 minBuyAmount
    )
        internal
    {
        (bool success, bytes memory returnData) = address(escrow).call(callData);
        assertFalse(success, "insufficient buy amount call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierEscrow_InsufficientBuyAmount.selector, buyAmount, minBuyAmount),
            "insufficient buy amount return data"
        );
    }

    /// @dev Expects a revert when trade fee exceeds max.
    function expectRevert_TradeFeeExceedsMax(bytes memory callData, uint256 tradeFee, uint256 maxTradeFee) internal {
        (bool success, bytes memory returnData) = address(escrow).call(callData);
        assertFalse(success, "trade fee exceeds max call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierEscrow_TradeFeeExceedsMax.selector, tradeFee, maxTradeFee),
            "trade fee exceeds max return data"
        );
    }
}
