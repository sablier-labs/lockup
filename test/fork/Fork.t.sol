// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { Base_Test } from "../Base.t.sol";

/// @notice Common logic needed by all fork tests.
abstract contract Fork_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 internal immutable ASSET;
    address internal immutable HOLDER;

    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal initialHolderBalance;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 asset, address holder) {
        ASSET = asset;
        HOLDER = holder;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        // Fork Blast sepolia testnet at a specific block number.
        vm.createSelectFork({ blockNumber: 1_620_391, urlOrAlias: "blast_sepolia" });

        // The base is set up after the fork is selected so that the base test contracts are deployed on the fork.
        Base_Test.setUp();

        // Deploy V2 Core.
        deployCoreConditionally();

        // Label the contracts.
        labelContracts();

        // Make the ASSET HOLDER the caller in this test suite.
        vm.startPrank({ msgSender: HOLDER });

        // Query the initial balance of the ASSET HOLDER.
        initialHolderBalance = ASSET.balanceOf(HOLDER);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks the user assumptions.
    function checkUsers(address sender, address recipient, address broker, address sablierContract) internal virtual {
        // The protocol does not allow the zero address to interact with it.
        vm.assume(sender != address(0) && recipient != address(0) && broker != address(0));

        // The goal is to not have overlapping users because the ASSET balance tests would fail otherwise.
        vm.assume(sender != recipient && sender != broker && recipient != broker);
        vm.assume(sender != HOLDER && recipient != HOLDER && broker != HOLDER);
        vm.assume(sender != sablierContract && recipient != sablierContract && broker != sablierContract);

        // Avoid users blacklisted by USDC or USDT.
        assumeNoBlacklisted(address(ASSET), sender);
        assumeNoBlacklisted(address(ASSET), recipient);
        assumeNoBlacklisted(address(ASSET), broker);
    }

    /// @dev Checks if forked `ASSET` is a Blast L2 asset.
    function isBlastAsset() internal view returns (bool) {
        return address(ASSET) == 0x4200000000000000000000000000000000000022
            || address(ASSET) == 0x4200000000000000000000000000000000000023;
    }

    /// @dev Labels the most relevant contracts.
    function labelContracts() internal {
        vm.label({ account: address(ASSET), newLabel: IERC20Metadata(address(ASSET)).symbol() });
        vm.label({ account: HOLDER, newLabel: "HOLDER" });
    }
}
