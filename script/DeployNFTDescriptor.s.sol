// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.19 <0.9.0;

import { SablierV2NFTDescriptor } from "../src/SablierV2NFTDescriptor.sol";

import { BaseScript } from "./Base.s.sol";

contract DeployNFTDescriptor is BaseScript {
    function run() public virtual broadcaster returns (SablierV2NFTDescriptor nftDescriptor) {
        nftDescriptor = new SablierV2NFTDescriptor();
    }
}
