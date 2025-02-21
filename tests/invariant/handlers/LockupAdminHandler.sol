// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISablierLockup } from "src/interfaces/ISablierLockup.sol";
import { BaseHandler } from "./BaseHandler.sol";

contract LockupAdminHandler is BaseHandler {
    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Since all admin-related functions are rarely called compared to core lockup functionalities,
    /// we limit the number of calls to 10.
    modifier limitNumberOfCalls(string memory name) {
        vm.assume(calls[name] < 10);
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 token_, ISablierLockup lockup_) BaseHandler(token_, lockup_) { }

    /*//////////////////////////////////////////////////////////////////////////
                                 SABLIER-LOCKUP-BASE
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Function to increase the lockup contract balance for the fuzzed token.
    function randomTransfer(uint256 amount) external {
        vm.assume(amount > 0 && amount < 100e18);

        deal({ token: address(token), to: address(lockup), give: token.balanceOf(address(lockup)) + amount });
    }

    function recover() external limitNumberOfCalls("recover") instrument("recover") {
        vm.assume(token.balanceOf(address(lockup)) > lockup.aggregateBalance(token));

        resetPrank(lockup.admin());

        lockup.recover(token, lockup.admin());
    }
}
