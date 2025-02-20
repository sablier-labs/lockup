// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { LockupNFTDescriptor } from "../src/LockupNFTDescriptor.sol";
import { SablierBatchLockup } from "../src/SablierBatchLockup.sol";
import { SablierLockup } from "../src/SablierLockup.sol";

import { MaxCountScript } from "./MaxCount.s.sol";

/// @notice Deploys the Lockup Protocol at deterministic addresses across chains.
contract DeployDeterministicProtocol is MaxCountScript {
    /// @dev Deploys the protocol with the admin set in `adminMap`.
    function run()
        public
        returns (SablierLockup lockup, SablierBatchLockup batchLockup, LockupNFTDescriptor nftDescriptor)
    {
        address initialAdmin = protocolAdmin();
        (lockup, batchLockup, nftDescriptor) = _run(initialAdmin);
    }

    /// @dev Deploys the protocol with the given `initialAdmin`.
    function run(address initialAdmin)
        public
        returns (SablierLockup lockup, SablierBatchLockup batchLockup, LockupNFTDescriptor nftDescriptor)
    {
        (lockup, batchLockup, nftDescriptor) = _run(initialAdmin);
    }

    /// @dev Common logic for the run functions.
    function _run(address initialAdmin)
        internal
        broadcast
        returns (SablierLockup lockup, SablierBatchLockup batchLockup, LockupNFTDescriptor nftDescriptor)
    {
        batchLockup = new SablierBatchLockup{ salt: SALT }();
        nftDescriptor = new LockupNFTDescriptor{ salt: SALT }();
        lockup = new SablierLockup{ salt: SALT }(initialAdmin, nftDescriptor, maxCountMap[block.chainid]);
    }
}
