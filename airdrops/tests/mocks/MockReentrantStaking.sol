// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierMerkleExecute } from "src/interfaces/ISablierMerkleExecute.sol";

/// @notice A malicious staking contract that attempts to re-enter the MerkleExecute campaign.
contract MockReentrantStaking {
    ISablierMerkleExecute public campaign;
    IERC20 public token;

    uint256 public reentrancyIndex;
    uint128 public reentrancyAmount;
    bytes32[] public reentrancyMerkleProof;
    bytes public reentrancyArguments;

    constructor(IERC20 token_) {
        token = token_;
    }

    /// @dev Set the campaign to re-enter.
    function setCampaign(ISablierMerkleExecute campaign_) external {
        campaign = campaign_;
    }

    /// @dev Set the parameters for the reentrancy attack.
    function setReentrancyParams(
        uint256 index,
        uint128 amount,
        bytes32[] calldata merkleProof,
        bytes calldata arguments
    )
        external
    {
        reentrancyIndex = index;
        reentrancyAmount = amount;
        reentrancyMerkleProof = merkleProof;
        reentrancyArguments = arguments;
    }

    /// @dev This function attempts to re-enter the MerkleExecute campaign when called.
    function stake(uint128 amount) external {
        // Transfer tokens from the campaign to this contract.
        token.transferFrom(msg.sender, address(this), amount);

        // Attempt reentrancy attack by calling claimAndExecute again.
        campaign.claimAndExecute(reentrancyIndex, reentrancyAmount, reentrancyMerkleProof, reentrancyArguments);
    }
}
