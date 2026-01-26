// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice A mock staking contract for testing MerkleExecute campaigns.
contract MockStaking {
    IERC20 public token;

    constructor(IERC20 token_) {
        token = token_;
    }

    function stake(uint128 amount) external {
        token.transferFrom(msg.sender, address(this), amount);
    }

    function stakeFor(address user, uint128 amount) external {
        user;
        token.transferFrom(msg.sender, address(this), amount);
    }

    function revertingFunction(uint128) external pure {
        revert("Shall not pass!");
    }
}
