// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { PRBMathAssertions } from "@prb/math/test/utils/Assertions.sol";

import { ISablierEscrow } from "src/interfaces/ISablierEscrow.sol";
import { Escrow } from "src/types/Escrow.sol";

abstract contract Assertions is PRBMathAssertions {
    /*//////////////////////////////////////////////////////////////////////////
                                    FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Compares two {Escrow.Status} enum values.
    function assertEq(Escrow.Status a, Escrow.Status b) internal pure {
        assertEq(uint256(a), uint256(b), "status");
    }

    /// @dev Compares two {Escrow.Status} enum values with a custom error message.
    function assertEq(Escrow.Status a, Escrow.Status b, string memory err) internal pure {
        assertEq(uint256(a), uint256(b), err);
    }

    /// @dev Compares two {IERC20} values.
    function assertEq(IERC20 a, IERC20 b, string memory err) internal pure {
        assertEq(address(a), address(b), err);
    }

    /// @dev Asserts that an order exists and has expected properties.
    function assertOrder(
        ISablierEscrow escrow,
        uint256 orderId,
        address expectedSeller,
        address expectedBuyer,
        IERC20 expectedSellToken,
        IERC20 expectedBuyToken,
        uint128 expectedSellAmount,
        uint128 expectedMinBuyAmount,
        uint40 expectedExpireAt
    )
        internal
        view
    {
        assertEq(escrow.getSeller(orderId), expectedSeller, "order.seller");
        assertEq(escrow.getBuyer(orderId), expectedBuyer, "order.buyer");
        assertEq(escrow.getSellToken(orderId), expectedSellToken, "order.sellToken");
        assertEq(escrow.getBuyToken(orderId), expectedBuyToken, "order.buyToken");
        assertEq(escrow.getSellAmount(orderId), expectedSellAmount, "order.sellAmount");
        assertEq(escrow.getMinBuyAmount(orderId), expectedMinBuyAmount, "order.minBuyAmount");
        assertEq(escrow.getExpireAt(orderId), expectedExpireAt, "order.expireAt");
    }

    /// @dev Asserts that an order has the expected status.
    function assertOrderStatus(ISablierEscrow escrow, uint256 orderId, Escrow.Status expectedStatus) internal view {
        assertEq(escrow.statusOf(orderId), expectedStatus, "order.status");
    }
}
