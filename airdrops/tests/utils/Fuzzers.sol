// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ud2x18 } from "@prb/math/src/UD2x18.sol";
import { PRBMathUtils } from "@prb/math/test/utils/Utils.sol";
import { BaseConstants } from "@sablier/evm-utils/src/tests/BaseConstants.sol";
import { BaseUtils } from "@sablier/evm-utils/src/tests/BaseUtils.sol";
import { MerkleLT } from "src/types/DataTypes.sol";

import { LeafData, MerkleBuilder } from "./MerkleBuilder.sol";

abstract contract Fuzzers is BaseConstants, BaseUtils, MerkleBuilder, PRBMathUtils {
    /// @dev Construct a Merkle tree from the given raw leaves data.
    /// @param leaves Storage pointer where the final leaves will be stored.
    /// @param leavesData Storage pointer where the final leaves data will be stored.
    /// @param rawLeavesData Raw leaves data to be fuzzed.
    /// @param excludedAddresses Addresses to be excluded from the fuzzing.
    function fuzzMerkleDataAndComputeRoot(
        uint256[] storage leaves,
        LeafData[] storage leavesData,
        LeafData[] memory rawLeavesData,
        address[] memory excludedAddresses
    )
        internal
        returns (uint128 aggregateAmount, bytes32 merkleRoot)
    {
        // Fuzz the leaves data.
        aggregateAmount = fuzzMerkleData({ leavesData: rawLeavesData, excludedAddresses: excludedAddresses });

        // Construct the Merkle tree and return the Merkle root.
        merkleRoot = constructMerkleTree(leaves, leavesData, rawLeavesData);
    }

    /// @dev Fuzz merkle data and return the aggregate amount.
    function fuzzMerkleData(
        LeafData[] memory leavesData,
        address[] memory excludedAddresses
    )
        internal
        view
        returns (uint128 aggregateAmount)
    {
        for (uint256 i = 0; i < leavesData.length; ++i) {
            // Avoid zero recipient addresses.
            leavesData[i].recipient =
                address(uint160(bound(uint256(uint160(leavesData[i].recipient)), 1, type(uint160).max)));

            // Check that excluded addresses are not one of the recipients.
            for (uint256 j = 0; j < excludedAddresses.length; ++j) {
                if (leavesData[i].recipient == excludedAddresses[j]) {
                    leavesData[i].recipient = vm.randomAddress();
                }
            }

            // Bound each leaf amount so that `aggregateAmount` does not overflow.
            leavesData[i].amount = boundUint128(leavesData[i].amount, 1, uint128(MAX_UINT128 / leavesData.length - 1));

            aggregateAmount += leavesData[i].amount;
        }
    }

    /// @dev Fuzz tranches by making sure that total unlock percentage is 1e18 and total duration does not overflow the
    /// maximum timestamp.
    function fuzzTranchesMerkleLT(
        uint40 vestingStartTime,
        MerkleLT.TrancheWithPercentage[] memory tranches
    )
        internal
        view
        returns (uint40 totalDuration)
    {
        uint256 upperBoundDuration;

        // Set upper bound based on the vesting start time. Zero is used as a sentinel value for `block.timestamp`.
        if (vestingStartTime == 0) {
            vestingStartTime = getBlockTimestamp();
        }
        upperBoundDuration = (MAX_UNIX_TIMESTAMP - vestingStartTime) / tranches.length;

        uint64 upperBoundPercentage = 1e18;

        for (uint256 i; i < tranches.length; ++i) {
            tranches[i].unlockPercentage = bound(tranches[i].unlockPercentage, 0, upperBoundPercentage);
            tranches[i].duration = boundUint40(tranches[i].duration, 1, uint40(upperBoundDuration));

            totalDuration += tranches[i].duration;

            upperBoundPercentage -= tranches[i].unlockPercentage.unwrap();
        }

        // Add the remaining percentage to the last tranche.
        if (upperBoundPercentage > 0) {
            tranches[tranches.length - 1].unlockPercentage =
                ud2x18(tranches[tranches.length - 1].unlockPercentage.unwrap() + upperBoundPercentage);
        }
    }
}
