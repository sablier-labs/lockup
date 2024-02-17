// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19 <0.9.0;

import { ISablierV2Comptroller } from "../src/interfaces/ISablierV2Comptroller.sol";
import { SablierV2NFTDescriptor } from "../src/SablierV2NFTDescriptor.sol";
import { SablierV2LockupDynamic } from "../src/SablierV2LockupDynamic.sol";
import { SablierV2LockupLinear } from "../src/SablierV2LockupLinear.sol";

import { BaseScript } from "./Base.s.sol";

/// @notice Deploys these contracts at deterministic addresses across chains, in the following order:
///
/// 1. {SablierV2NFTDescriptor}
/// 2. {SablierV2LockupDynamic}
/// 3. {SablierV2LockupLinear}
///
/// @dev Reverts if any contract has already been deployed.
contract DeployDeterministicCore3 is BaseScript {
    function run(
        address initialAdmin,
        ISablierV2Comptroller comptroller
    )
        public
        virtual
        broadcast
        returns (
            SablierV2NFTDescriptor nftDescriptor,
            SablierV2LockupDynamic lockupDynamic,
            SablierV2LockupLinear lockupLinear
        )
    {
        bytes32 salt = constructCreate2Salt();
        nftDescriptor = new SablierV2NFTDescriptor{ salt: salt }();
        lockupDynamic = new SablierV2LockupDynamic{ salt: salt }(initialAdmin, comptroller, nftDescriptor, maxCount);
        lockupLinear = new SablierV2LockupLinear{ salt: salt }(initialAdmin, comptroller, nftDescriptor);
    }
}
