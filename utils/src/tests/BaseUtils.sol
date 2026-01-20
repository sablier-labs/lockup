// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { CommonBase as StdBase } from "forge-std/src/Base.sol";
import { console2 } from "forge-std/src/console2.sol";
import { StdStyle } from "forge-std/src/StdStyle.sol";
import { StdUtils } from "forge-std/src/StdUtils.sol";

abstract contract BaseUtils is StdBase, StdUtils {
    /*//////////////////////////////////////////////////////////////////////////
                                       BOUNDS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Bounds a `uint128` number.
    function boundUint128(uint128 x, uint128 min, uint128 max) internal pure returns (uint128) {
        return uint128(_bound(x, min, max));
    }

    /// @dev Bounds a `uint40` number.
    function boundUint40(uint40 x, uint40 min, uint40 max) internal pure returns (uint40) {
        return uint40(_bound(x, min, max));
    }

    /// @dev Bounds a `uint64` number.
    function boundUint64(uint64 x, uint64 min, uint64 max) internal pure returns (uint64) {
        return uint64(_bound(x, min, max));
    }

    /// @dev Bounds a `uint8` number.
    function boundUint8(uint8 x, uint8 min, uint8 max) internal pure returns (uint8) {
        return uint8(_bound(x, min, max));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      LOGGING
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Logs a message in blue color.
    /// @param message The message to log.
    function logBlue(string memory message) internal pure {
        // solhint-disable-next-line no-console
        console2.log(StdStyle.blue(message));
    }

    /// @notice Logs a message in green color with a ✓ check mark.
    /// @param message The message to log.
    function logGreen(string memory message) internal pure {
        // solhint-disable-next-line no-console
        console2.log(StdStyle.green(string.concat(unicode"✓ ", message)));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        MISC
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Retrieves the current block timestamp as an `uint40`.
    function getBlockTimestamp() internal view returns (uint40) {
        return uint40(vm.getBlockTimestamp());
    }

    /// @dev Label forked token using try catch to handle tokens with missing `symbol`.
    function labelForkedToken(IERC20 forkedToken) internal {
        // Use try catch to handle tokens with missing `symbol` implementation.
        try IERC20Metadata(address(forkedToken)).symbol() returns (string memory symbol) {
            vm.label({ account: address(forkedToken), newLabel: symbol });
        } catch {
            vm.label({ account: address(forkedToken), newLabel: "FORK_TOKEN" });
        }
    }

    /// @dev Stops the active prank and sets a new one.
    function setMsgSender(address msgSender) internal {
        vm.stopPrank();
        vm.startPrank(msgSender);

        // Deal some ETH to the new caller.
        vm.deal(msgSender, 1 ether);
    }
}
