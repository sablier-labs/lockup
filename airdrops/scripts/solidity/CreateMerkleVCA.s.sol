// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud } from "@prb/math/src/UD60x18.sol";
import { BaseScript as EvmUtilsBaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";

import { ISablierMerkleVCA } from "../../src/interfaces/ISablierMerkleVCA.sol";
import { SablierFactoryMerkleVCA } from "../../src/SablierFactoryMerkleVCA.sol";
import { ClaimType, MerkleVCA } from "../../src/types/DataTypes.sol";

/// @dev Creates a dummy MerkleVCA campaign.
contract CreateMerkleVCA is EvmUtilsBaseScript {
    /// @dev Deploy via Forge.
    function run(SablierFactoryMerkleVCA factory) public broadcast returns (ISablierMerkleVCA merkleVCA) {
        // Prepare the constructor parameters.
        MerkleVCA.ConstructorParams memory campaignParams = MerkleVCA.ConstructorParams({
            aggregateAmount: 10_000e18,
            campaignName: "The Boys VCA",
            campaignStartTime: uint40(block.timestamp),
            claimType: ClaimType.DEFAULT,
            enableRedistribution: false,
            expiration: uint40(block.timestamp + 400 days),
            initialAdmin: 0x79Fb3e81aAc012c08501f41296CCC145a1E15844,
            ipfsCID: "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR",
            merkleRoot: 0x0000000000000000000000000000000000000000000000000000000000000000,
            token: IERC20(0xf983A617DA60e88c112D52F00f9Fab17851D2feF),
            unlockPercentage: ud(0.1e18),
            vestingEndTime: uint40(block.timestamp + 365 days),
            vestingStartTime: uint40(block.timestamp)
        });

        // The number of eligible users for the airdrop.
        uint256 recipientCount = 100;

        // Deploy the MerkleVCA contract.
        merkleVCA = factory.createMerkleVCA(campaignParams, recipientCount);
    }
}
