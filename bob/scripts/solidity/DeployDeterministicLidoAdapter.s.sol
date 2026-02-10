// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";
import { BaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";

import { ISablierBob } from "../../src/interfaces/ISablierBob.sol";
import { SablierLidoAdapter } from "../../src/SablierLidoAdapter.sol";

/// @notice Deploys {SablierLidoAdapter} at a deterministic address across chains.
/// @dev Reverts if the contract has already been deployed.
contract DeployDeterministicLidoAdapter is BaseScript {
    function run(
        ISablierBob sablierBob,
        UD60x18 initialSlippageTolerance,
        UD60x18 initialYieldFee
    )
        public
        broadcast
        returns (SablierLidoAdapter lidoAdapter)
    {
        lidoAdapter = new SablierLidoAdapter{ salt: SALT }(
            getComptroller(), address(sablierBob), initialSlippageTolerance, initialYieldFee
        );
    }
}
