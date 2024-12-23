// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

/// @notice This contract implements logic to batch call any function.
interface IBatch {
    /// @notice Allows batched call to self, `this` contract.
    /// @param calls An array of inputs for each call.
    /// @return results An array of results from each call. Store empty bytes for calls that do not return anything.
    function batch(bytes[] calldata calls) external payable returns (bytes[] memory results);
}
