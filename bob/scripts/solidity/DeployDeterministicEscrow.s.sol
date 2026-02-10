// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";
import { BaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";

import { SablierEscrow } from "../../src/SablierEscrow.sol";

/// @notice Deploys {SablierEscrow} at a deterministic address across chains.
/// @dev Reverts if the contract has already been deployed.
contract DeployDeterministicEscrow is BaseScript {
    function run(UD60x18 initialTradeFee) public broadcast returns (SablierEscrow escrow) {
        escrow = new SablierEscrow{ salt: SALT }(getComptroller(), initialTradeFee);
    }
}
