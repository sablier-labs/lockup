// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud2x18 } from "@prb/math/src/UD2x18.sol";
import { BaseScript as EvmUtilsBaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import { ISablierMerkleLT } from "../../src/interfaces/ISablierMerkleLT.sol";
import { SablierFactoryMerkleLT } from "../../src/SablierFactoryMerkleLT.sol";

import { ClaimType } from "../../src/types/MerkleBase.sol";
import { MerkleLT } from "../../src/types/MerkleLT.sol";

/// @dev Creates a dummy campaign to airdrop tokens through Lockup Tranched.
contract CreateMerkleLT is EvmUtilsBaseScript {
    /// @dev Deploy via Forge.
    function run(
        SablierFactoryMerkleLT factory,
        ISablierLockup lockup,
        IERC20 token
    )
        public
        broadcast
        returns (ISablierMerkleLT merkleLT)
    {
        // The tranches with their unlock percentages and durations.
        MerkleLT.TrancheWithPercentage[] memory tranches = new MerkleLT.TrancheWithPercentage[](2);
        tranches[0] = MerkleLT.TrancheWithPercentage({ unlockPercentage: ud2x18(0.5e18), duration: 3600 });
        tranches[1] = MerkleLT.TrancheWithPercentage({ unlockPercentage: ud2x18(0.5e18), duration: 7200 });

        // Prepare the constructor parameters.
        MerkleLT.ConstructorParams memory campaignParams = MerkleLT.ConstructorParams({
            campaignName: "The Boys LT",
            campaignStartTime: uint40(block.timestamp),
            cancelable: true,
            claimType: ClaimType.DEFAULT,
            expiration: uint40(block.timestamp + 30 days),
            initialAdmin: 0x79Fb3e81aAc012c08501f41296CCC145a1E15844,
            ipfsCID: "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR",
            lockup: lockup,
            merkleRoot: 0x0000000000000000000000000000000000000000000000000000000000000000,
            shape: "LT",
            token: token,
            tranchesWithPercentages: tranches,
            transferable: true,
            vestingStartTime: 0 // i.e. block.timestamp
        });

        uint256 aggregateAmount = 10_000e18;
        uint256 recipientCount = 100;

        // Deploy the MerkleLT contract.
        merkleLT = factory.createMerkleLT(campaignParams, aggregateAmount, recipientCount);
    }
}
