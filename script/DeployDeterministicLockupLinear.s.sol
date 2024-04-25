// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19 <0.9.0;

import { ISablierV2Comptroller } from "../contracts/interfaces/ISablierV2Comptroller.sol";
import { ISablierV2NFTDescriptor } from "../contracts/interfaces/ISablierV2NFTDescriptor.sol";
import { SablierV2LockupLinear } from "../contracts/SablierV2LockupLinear.sol";

import { BaseScript } from "./Base.s.sol";

/// @dev Deploys {SablierV2LockupLinear} at a deterministic address across chains.
/// @dev Reverts if the contract has already been deployed.
contract DeployDeterministicLockupLinear is BaseScript {
    function run(
        address initialAdmin,
        ISablierV2Comptroller initialComptroller,
        ISablierV2NFTDescriptor initialNFTDescriptor
    )
        public
        virtual
        broadcast
        returns (SablierV2LockupLinear lockupLinear)
    {
        bytes32 salt = constructCreate2Salt();
        lockupLinear = new SablierV2LockupLinear{ salt: salt }(initialAdmin, initialComptroller, initialNFTDescriptor);
    }
}
