// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { BaseScript as EvmUtilsBaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";

import { ISablierMerkleExecute } from "../../src/interfaces/ISablierMerkleExecute.sol";
import { SablierFactoryMerkleExecute } from "../../src/SablierFactoryMerkleExecute.sol";
import { MerkleExecute } from "../../src/types/DataTypes.sol";

/// @dev Creates a dummy MerkleExecute campaign.
contract CreateMerkleExecute is EvmUtilsBaseScript {
    /// @dev Deploy via Forge.
    function run(SablierFactoryMerkleExecute factory) public broadcast returns (ISablierMerkleExecute merkleExecute) {
        // Prepare the constructor parameters.
        MerkleExecute.ConstructorParams memory campaignParams = MerkleExecute.ConstructorParams({
            approveTarget: true,
            campaignName: "The Boys Execute",
            campaignStartTime: uint40(block.timestamp),
            expiration: uint40(block.timestamp + 30 days),
            initialAdmin: 0x79Fb3e81aAc012c08501f41296CCC145a1E15844,
            ipfsCID: "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR",
            merkleRoot: 0x0000000000000000000000000000000000000000000000000000000000000000,
            selector: bytes4(keccak256("stake(uint256)")),
            target: 0x1234567890123456789012345678901234567890, // dummy address
            token: IERC20(0xf983A617DA60e88c112D52F00f9Fab17851D2feF)
        });

        // The total amount to airdrop through the campaign.
        uint256 aggregateAmount = 10_000e18;

        // The number of eligible users for the airdrop.
        uint256 recipientCount = 100;

        // Deploy the MerkleExecute contract.
        merkleExecute = factory.createMerkleExecute(campaignParams, aggregateAmount, recipientCount);
    }
}
