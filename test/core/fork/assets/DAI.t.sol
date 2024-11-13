// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Lockup_Dynamic_Fork_Test } from "../LockupDynamic.t.sol";
import { Lockup_Linear_Fork_Test } from "../LockupLinear.t.sol";
import { Lockup_Tranched_Fork_Test } from "../LockupTranched.t.sol";

/// @dev A typical 18-decimal ERC-20 asset with a normal total supply.
IERC20 constant FORK_ASSET = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
address constant FORK_ASSET_HOLDER = 0x66F62574ab04989737228D18C3624f7FC1edAe14;

contract DAI_Lockup_Dynamic_Fork_Test is Lockup_Dynamic_Fork_Test(FORK_ASSET, FORK_ASSET_HOLDER) { }

contract DAI_Lockup_Linear_Fork_Test is Lockup_Linear_Fork_Test(FORK_ASSET, FORK_ASSET_HOLDER) { }

contract DAI_Lockup_Tranched_Fork_Test is Lockup_Tranched_Fork_Test(FORK_ASSET, FORK_ASSET_HOLDER) { }
