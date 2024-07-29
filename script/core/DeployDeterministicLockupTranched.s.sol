// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { ISablierV2NFTDescriptor } from "../../src/core/interfaces/ISablierV2NFTDescriptor.sol";
import { SablierV2LockupTranched } from "../../src/core/SablierV2LockupTranched.sol";

import { BaseScript } from "../Base.s.sol";

/// @dev Deploys {SablierV2LockupTranched} at a deterministic address across chains.
/// @dev Reverts if the contract has already been deployed.
contract DeployDeterministicLockupTranched is BaseScript {
    function run(
        address initialAdmin,
        ISablierV2NFTDescriptor initialNFTDescriptor
    )
        public
        virtual
        broadcast
        returns (SablierV2LockupTranched lockupTranched)
    {
        bytes32 salt = constructCreate2Salt();
        lockupTranched = new SablierV2LockupTranched{ salt: salt }(
            initialAdmin, initialNFTDescriptor, trancheCountMap[block.chainid]
        );
    }
}
