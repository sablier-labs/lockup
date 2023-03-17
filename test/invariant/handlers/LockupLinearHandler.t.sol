// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { ISablierV2LockupLinear } from "src/interfaces/ISablierV2LockupLinear.sol";

import { LockupHandler } from "./LockupHandler.t.sol";
import { LockupHandlerStorage } from "./LockupHandlerStorage.t.sol";

/// @title LockupLinearHandler
/// @dev This contract and not {SablierV2LockupLinear} is exposed to Foundry for invariant testing. The point is
/// to bound and restrict the inputs that get passed to the real-world contract to avoid getting reverts.
contract LockupLinearHandler is LockupHandler {
    constructor(
        IERC20 asset_,
        ISablierV2LockupLinear linear_,
        LockupHandlerStorage store_
    )
        LockupHandler(asset_, linear_, store_)
    { }
}
