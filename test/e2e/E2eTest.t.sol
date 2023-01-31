// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { SablierV2Comptroller } from "src/SablierV2Comptroller.sol";
import { SablierV2LockupLinear } from "src/SablierV2LockupLinear.sol";
import { SablierV2LockupPro } from "src/SablierV2LockupPro.sol";

import { Base_Test } from "../Base.t.sol";

/// @title E2eTest
/// @notice Collections of tests that run against a fork of Ethereum Mainnet.
abstract contract E2eTest is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 internal immutable asset;
    address internal immutable holder;

    /*//////////////////////////////////////////////////////////////////////////
                                    TEST VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal initialHolderBalance;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 asset_, address holder_) {
        asset = asset_;
        holder = holder_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        // Fork Ethereum Mainnet.
        vm.createSelectFork({ urlOrAlias: "ethereum", blockNumber: 16_126_000 });

        // Deploy the entire protocol.
        deployProtocol();

        // Make the asset holder the caller in this test suite.
        vm.startPrank(holder);

        // Query the initial balance of the asset holder.
        initialHolderBalance = asset.balanceOf(holder);
    }
}
