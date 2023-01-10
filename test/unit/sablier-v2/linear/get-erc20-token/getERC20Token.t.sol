// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";

import { LinearTest } from "test/unit/sablier-v2/linear/LinearTest.t.sol";
import { GetERC20Token__Test } from "test/unit/sablier-v2/shared/get-erc20-token/getERC20Token.t.sol";
import { UnitTest } from "test/unit/UnitTest.t.sol";

contract GetERC20Token__LinearTest is LinearTest, GetERC20Token__Test {
    function setUp() public virtual override(UnitTest, LinearTest) {
        LinearTest.setUp();
        sablierV2 = ISablierV2(linear);
    }
}
