// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.19;

import { Script } from "forge-std/Script.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { ISablierV2Comptroller } from "../../src/interfaces/ISablierV2Comptroller.sol";
import { ISablierV2NftDescriptor } from "../../src/nft-descriptor/ISablierV2NftDescriptor.sol";
import { SablierV2LockupPro } from "../../src/SablierV2LockupPro.sol";

import { BaseScript } from "../shared/Base.s.sol";

/// @notice Deploys the {SablierV2LockupPro} contract.
contract DeployLockupPro is Script, BaseScript {
    function run(
        address initialAdmin,
        ISablierV2Comptroller initialComptroller,
        ISablierV2NftDescriptor nftDescriptor,
        UD60x18 maxFee,
        uint256 maxSegmentCount
    ) public virtual broadcaster returns (SablierV2LockupPro pro) {
        pro = new SablierV2LockupPro(initialAdmin, initialComptroller, nftDescriptor, maxFee, maxSegmentCount);
    }
}
