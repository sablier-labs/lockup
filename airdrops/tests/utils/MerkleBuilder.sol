// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable reason-string
pragma solidity >=0.8.22;

import { Arrays } from "@openzeppelin/contracts/utils/Arrays.sol";
import { Merkle } from "murky/src/Merkle.sol";
import { LibSort } from "solady/src/utils/LibSort.sol";

/// @dev Encapsulates the data needed to compute a Merkle tree leaf.
struct LeafData {
    uint256 index;
    address recipient;
    uint128 amount;
}

/// @dev A helper contract for building Merkle leaves, roots, and proofs.
abstract contract MerkleBuilder is Merkle {
    /// @dev Double hashes the data needed for a Merkle tree leaf.
    function computeLeaf(LeafData memory leafData) internal pure returns (uint256 leaf) {
        leaf = uint256(
            keccak256(bytes.concat(keccak256(abi.encode(leafData.index, leafData.recipient, leafData.amount))))
        );
    }

    /// @dev Compute leaves for given data and sort them in ascending order.
    function computeLeaves(uint256[] storage leaves, LeafData[] memory leafData) internal {
        for (uint256 i = 0; i < leafData.length; ++i) {
            leaves.push(computeLeaf(leafData[i]));
        }

        // Sort the leaves in ascending order to match the production environment.
        sort(leaves);
    }

    /// @dev Computes the Merkle proof for the given leaf data and an array of leaves.
    function computeMerkleProof(
        LeafData memory leafData,
        uint256[] storage leaves
    )
        internal
        view
        returns (bytes32[] memory merkleProof)
    {
        uint256 leaf = computeLeaf(leafData);
        uint256 pos = Arrays.findUpperBound(leaves, leaf);

        merkleProof = leaves.length == 1 ? new bytes32[](0) : getProof(toBytes32(leaves), pos);
    }

    /// @dev Construct a Merkle tree from the given raw leaves data.
    /// @param leaves Storage pointer where the final leaves will be stored.
    /// @param leavesData Storage pointer where the final leaves data will be stored.
    /// @param rawLeavesData Raw leaves data to be fuzzed.
    /// @return merkleRoot The Merkle root of the constructed Merkle tree.
    function constructMerkleTree(
        uint256[] storage leaves,
        LeafData[] storage leavesData,
        LeafData[] memory rawLeavesData
    )
        internal
        returns (bytes32 merkleRoot)
    {
        // Store the merkle tree leaves in storage.
        for (uint256 i = 0; i < rawLeavesData.length; ++i) {
            leavesData.push(rawLeavesData[i]);
        }

        // Compute the Merkle leaves.
        computeLeaves(leaves, rawLeavesData);

        // If there is only one leaf, the Merkle root is the hash of the leaf itself.
        merkleRoot = leaves.length == 1 ? bytes32(leaves[0]) : getRoot(toBytes32(leaves));
    }

    /// @dev Convert a storage array to memory and sorts it in ascending order. We need this because `LibSort` does not
    /// support storage arrays.
    function sort(uint256[] storage leaves) internal {
        uint256 leavesCount = leaves.length;

        // Declare the memory array.
        uint256[] memory _leaves = new uint256[](leavesCount);
        for (uint256 i = 0; i < leavesCount; ++i) {
            _leaves[i] = leaves[i];
        }

        // Sort the memory array.
        LibSort.sort(_leaves);

        // Copy the memory array back to storage.
        for (uint256 i = 0; i < leavesCount; ++i) {
            leaves[i] = _leaves[i];
        }
    }

    /// @dev Converts an array of `uint256` to an array of `bytes32`.
    function toBytes32(uint256[] storage arr_) internal view returns (bytes32[] memory arr) {
        arr = new bytes32[](arr_.length);
        for (uint256 i = 0; i < arr_.length; ++i) {
            arr[i] = bytes32(arr_[i]);
        }
    }
}
