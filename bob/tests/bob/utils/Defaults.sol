// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierLidoAdapter } from "src/interfaces/ISablierLidoAdapter.sol";

import { Constants } from "./Constants.sol";
import { Users } from "./Types.sol";

/// @notice Contract with default values used throughout the tests.
contract Defaults is Constants {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 public token;
    IERC20 public weth;
    AggregatorV3Interface public oracle;
    ISablierLidoAdapter public adapter;
    Users public users;

    /*//////////////////////////////////////////////////////////////////////////
                                      SETTERS
    //////////////////////////////////////////////////////////////////////////*/

    function setToken(IERC20 token_) public {
        token = token_;
    }

    function setWeth(IERC20 weth_) public {
        weth = weth_;
    }

    function setOracle(AggregatorV3Interface oracle_) public {
        oracle = oracle_;
    }

    function setAdapter(ISablierLidoAdapter adapter_) public {
        adapter = adapter_;
    }

    function setUsers(Users memory users_) public {
        users = users_;
    }
}
