// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleFactory } from "../../src/periphery/SablierMerkleFactory.sol";

import { BaseScript } from "../Base.s.sol";

contract DeployMerkleFactory is BaseScript {
    /// @dev Deploy via Forge.
    function run() public virtual broadcast returns (SablierMerkleFactory merkleFactory) {
        merkleFactory = new SablierMerkleFactory();
    }
}
