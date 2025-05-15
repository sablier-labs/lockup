// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { BaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";

import { LockupNFTDescriptor } from "../../src/LockupNFTDescriptor.sol";
import { SablierLockup } from "../../src/SablierLockup.sol";

/// @notice Deploys the Lockup Protocol.
contract DeployProtocol is BaseScript {
    /// @dev Deploys the protocol with the admin set in `adminMap`.
    function run() public returns (SablierLockup lockup, LockupNFTDescriptor nftDescriptor) {
        address initialAdmin = protocolAdmin();
        nftDescriptor = new LockupNFTDescriptor();
        lockup = new SablierLockup(initialAdmin, address(nftDescriptor));
    }
}
