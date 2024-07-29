// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { SablierV2NFTDescriptor } from "../src/core/SablierV2NFTDescriptor.sol";

import { BaseScript } from "./Base.s.sol";

contract DeployNFTDescriptor is BaseScript {
    function run() public virtual broadcast returns (SablierV2NFTDescriptor nftDescriptor) {
        nftDescriptor = new SablierV2NFTDescriptor();
    }
}
