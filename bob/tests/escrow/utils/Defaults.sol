// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Constants } from "./Constants.sol";
import { Users } from "./Types.sol";

/// @notice Contract with default values used throughout the tests.
contract Defaults is Constants {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 public sellToken;
    IERC20 public buyToken;
    Users public users;

    /*//////////////////////////////////////////////////////////////////////////
                                      SETTERS
    //////////////////////////////////////////////////////////////////////////*/

    function setSellToken(IERC20 token_) public {
        sellToken = token_;
    }

    function setBuyToken(IERC20 token_) public {
        buyToken = token_;
    }

    function setUsers(Users memory users_) public {
        users = users_;
    }
}
