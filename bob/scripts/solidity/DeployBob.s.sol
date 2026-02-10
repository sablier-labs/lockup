// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { BaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";

import { SablierBob } from "../../src/SablierBob.sol";

/// @notice Deploys {SablierBob} contract.
contract DeployBob is BaseScript {
    function run() public broadcast returns (SablierBob bob) {
        bob = new SablierBob(getComptroller());
    }
}
