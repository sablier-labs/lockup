// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { CreateTest } from "../CreateTest.t.sol";

/// @dev A token that has the missing return value bug.
contract USDT__Test is CreateTest {
    USDT internal usdt = USDT(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    function setUp() public override {
        super.setUp();

        usdt.approve(address(sablierV2Linear), UINT256_MAX);
        usdt.approve(address(sablierV2Pro), UINT256_MAX);
    }

    /// @dev random USDT holder
    function holder() internal pure override returns (address) {
        return 0xee5B5B923fFcE93A870B3104b7CA09c3db80047A;
    }

    function token() internal pure override returns (address) {
        return 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    }
}

/// @dev An interface for the Tether token, which doesn't return a bool value on `approve` function.
interface USDT {
    function approve(address spender, uint256 value) external;
}
