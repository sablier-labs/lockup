// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

/// @title MockAdapterInvalidInterface
/// @notice Mock adapter that does not support the required interface.
/// @dev Used to test the SablierBob_NewAdapterMissesInterface error.
contract MockAdapterInvalidInterface {
    function supportsInterface(bytes4) external pure returns (bool) {
        return false;
    }
}

/// @title MockRejectETH
/// @notice Mock contract that rejects ETH transfers.
/// @dev Used to test the SablierBob_NativeFeeTransferFailed error.
contract MockRejectETH {
    // Explicitly reject all ETH transfers.
    receive() external payable {
        revert("MockRejectETH: rejected");
    }

    fallback() external payable {
        revert("MockRejectETH: rejected");
    }
}
