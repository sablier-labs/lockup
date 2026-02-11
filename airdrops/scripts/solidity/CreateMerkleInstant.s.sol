// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { BaseScript as EvmUtilsBaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";

import { ISablierMerkleInstant } from "../../src/interfaces/ISablierMerkleInstant.sol";
import { SablierFactoryMerkleInstant } from "../../src/SablierFactoryMerkleInstant.sol";
import { ClaimType } from "../../src/types/MerkleBase.sol";
import { MerkleInstant } from "../../src/types/MerkleInstant.sol";

/// @dev Creates a dummy MerkleInstant campaign.
contract CreateMerkleInstant is EvmUtilsBaseScript {
    /// @dev Deploy via Forge.
    function run(SablierFactoryMerkleInstant factory) public broadcast returns (ISablierMerkleInstant merkleInstant) {
        // Prepare the constructor parameters.
        MerkleInstant.ConstructorParams memory campaignParams = MerkleInstant.ConstructorParams({
            campaignName: "The Boys Instant",
            campaignStartTime: uint40(block.timestamp),
            claimType: ClaimType.DEFAULT,
            expiration: uint40(block.timestamp + 30 days),
            initialAdmin: 0x79Fb3e81aAc012c08501f41296CCC145a1E15844,
            ipfsCID: "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR",
            merkleRoot: 0x0000000000000000000000000000000000000000000000000000000000000000,
            token: IERC20(0xf983A617DA60e88c112D52F00f9Fab17851D2feF)
        });

        // The total amount to airdrop through the campaign.
        uint256 aggregateAmount = 10_000e18;

        // The number of eligible users for the airdrop.
        uint256 recipientCount = 100;

        // Deploy the MerkleInstant contract.
        merkleInstant = factory.createMerkleInstant(campaignParams, aggregateAmount, recipientCount);
    }
}
