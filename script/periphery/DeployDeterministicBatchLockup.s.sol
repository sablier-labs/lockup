// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { SablierV2BatchLockup } from "../../src/periphery/SablierV2BatchLockup.sol";

import { BaseScript } from "../Base.s.sol";

/// @notice Deploys {SablierV2BatchLockup} at a deterministic address across chains.
/// @dev Reverts if the contract has already been deployed.
contract DeployDeterministicBatchLockup is BaseScript {
    /// @dev Deploy via Forge.
    function run() public virtual broadcast returns (SablierV2BatchLockup batchLockup) {
        bytes32 salt = constructCreate2Salt();
        batchLockup = new SablierV2BatchLockup{ salt: salt }();
    }
}
