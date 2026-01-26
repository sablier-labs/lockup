// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

/// @notice A mock staking contract that always reverts on stake attempts.
contract MockStakingRevert {
    function stake(uint128) external pure {
        revert("Shall not pass!");
    }
}
