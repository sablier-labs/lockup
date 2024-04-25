// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19 <0.9.0;

import { ISablierV2Comptroller } from "../contracts/interfaces/ISablierV2Comptroller.sol";
import { SablierV2NFTDescriptor } from "../contracts/SablierV2NFTDescriptor.sol";
import { SablierV2LockupDynamic } from "../contracts/SablierV2LockupDynamic.sol";
import { SablierV2LockupLinear } from "../contracts/SablierV2LockupLinear.sol";

import { BaseScript } from "./Base.s.sol";

/// @notice Deploys these contracts in the following order:
///
/// 1. {SablierV2NFTDescriptor}
/// 2. {SablierV2LockupDynamic}
/// 3. {SablierV2LockupLinear}
contract DeployCore3 is BaseScript {
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
        nftDescriptor = new SablierV2NFTDescriptor();
        lockupDynamic = new SablierV2LockupDynamic(initialAdmin, comptroller, nftDescriptor, maxCount);
        lockupLinear = new SablierV2LockupLinear(initialAdmin, comptroller, nftDescriptor);
    }
}
