// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { BaseScript as EvmUtilsBaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";

import { SablierFactoryMerkleInstant } from "../../src/SablierFactoryMerkleInstant.sol";
import { SablierFactoryMerkleLL } from "../../src/SablierFactoryMerkleLL.sol";
import { SablierFactoryMerkleLT } from "../../src/SablierFactoryMerkleLT.sol";
import { SablierFactoryMerkleVCA } from "../../src/SablierFactoryMerkleVCA.sol";

/// @notice Deploys the FactoryMerkle contracts.
contract DeployFactories is EvmUtilsBaseScript {
    function run()
        public
        broadcast
        returns (
            SablierFactoryMerkleInstant factoryMerkleInstant,
            SablierFactoryMerkleLL factoryMerkleLL,
            SablierFactoryMerkleLT factoryMerkleLT,
            SablierFactoryMerkleVCA factoryMerkleVCA
        )
    {
        factoryMerkleInstant = new SablierFactoryMerkleInstant(address(0), getComptroller());
        factoryMerkleLL = new SablierFactoryMerkleLL(address(0), getComptroller());
        factoryMerkleLT = new SablierFactoryMerkleLT(address(0), getComptroller());
        factoryMerkleVCA = new SablierFactoryMerkleVCA(address(0), getComptroller());
    }
}
