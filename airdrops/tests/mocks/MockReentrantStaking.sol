// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierMerkleExecute } from "src/interfaces/ISablierMerkleExecute.sol";

/// @notice A malicious staking contract that attempts to re-enter the MerkleExecute campaign.
contract MockReentrantStaking {
    IERC20 public token;

    constructor(IERC20 token_) {
        token = token_;
    }

    /// @dev This function attempts to re-enter the MerkleExecute campaign when called.
    function stake(uint256 index, uint128 amount, bytes32[] calldata merkleProof, bytes calldata arguments) external {
        // Attempt reentrancy attack by calling claimAndExecute again.
        ISablierMerkleExecute(msg.sender).claimAndExecute(index, amount, merkleProof, arguments);
    }
}
