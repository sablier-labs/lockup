// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

/// @notice A mock staking contract that tracks stakes internally without token transfers.
contract MockStakingNoTransfer {
    mapping(address user => uint256 stakedAmount) public stakedBalance;

    /// @dev Adds the amount to the caller's staked balance. No token transfers involved.
    function stake(uint256 amount) external {
        stakedBalance[msg.sender] += amount;
    }
}
