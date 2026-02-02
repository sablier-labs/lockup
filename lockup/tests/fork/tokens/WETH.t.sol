// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Lockup_PriceGated_Fork_Test } from "../LockupPriceGated.t.sol";

/// @dev For testing price-gated streams.
IERC20 constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

/// @dev The Chainlink ETH/USD price feed on Ethereum mainnet.
AggregatorV3Interface constant CHAINLINK_ETH_USD = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

contract WETH_Lockup_PriceGated_Fork_Test is Lockup_PriceGated_Fork_Test(WETH, CHAINLINK_ETH_USD) { }
