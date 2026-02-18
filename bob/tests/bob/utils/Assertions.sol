// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { PRBMathAssertions } from "@prb/math/test/utils/Assertions.sol";

import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { Bob } from "src/types/Bob.sol";

abstract contract Assertions is PRBMathAssertions {
    /*//////////////////////////////////////////////////////////////////////////
                                    FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Compares two {Bob.Status} enum values.
    function assertEq(Bob.Status a, Bob.Status b) internal pure {
        assertEq(uint256(a), uint256(b), "status");
    }

    /// @dev Compares two {Bob.Status} enum values with a custom error message.
    function assertEq(Bob.Status a, Bob.Status b, string memory err) internal pure {
        assertEq(uint256(a), uint256(b), err);
    }

    /// @dev Compares two {IERC20} values.
    function assertEq(IERC20 a, IERC20 b, string memory err) internal pure {
        assertEq(address(a), address(b), err);
    }

    /// @dev Asserts that a vault exists and has expected properties.
    function assertVault(
        ISablierBob bob,
        uint256 vaultId,
        IERC20 expectedToken,
        uint40 expectedExpiry,
        uint128 expectedTargetPrice
    )
        internal
        view
    {
        assertEq(bob.getUnderlyingToken(vaultId), expectedToken, "vault.token");
        assertEq(bob.getExpiry(vaultId), expectedExpiry, "vault.expiry");
        assertEq(bob.getTargetPrice(vaultId), expectedTargetPrice, "vault.targetPrice");
    }

    /// @dev Asserts that a deposit exists with expected properties.
    /// @dev The amount is tracked via share token balance.
    function assertDeposit(
        ISablierBob bob,
        uint256 vaultId,
        address user,
        uint128 expectedAmount,
        uint40 expectedDepositedAt
    )
        internal
        view
    {
        uint40 depositedAt = bob.getFirstDepositTime(vaultId, user);
        uint256 shareBalance = bob.getShareToken(vaultId).balanceOf(user);
        assertEq(shareBalance, expectedAmount, "shareToken.balanceOf");
        assertEq(depositedAt, expectedDepositedAt, "depositedAt");
    }
}
