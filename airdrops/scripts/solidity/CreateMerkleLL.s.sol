// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud60x18 } from "@prb/math/src/UD60x18.sol";
import { BaseScript as EvmUtilsBaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";

import { ISablierMerkleLL } from "../../src/interfaces/ISablierMerkleLL.sol";
import { SablierFactoryMerkleLL } from "../../src/SablierFactoryMerkleLL.sol";
import { MerkleLL } from "../../src/types/DataTypes.sol";

/// @dev Creates a dummy campaign to airdrop tokens through Lockup Linear.
contract CreateMerkleLL is EvmUtilsBaseScript {
    /// @dev Deploy via Forge.
    function run(
        SablierFactoryMerkleLL factory,
        ISablierLockup lockup,
        IERC20 token
    )
        public
        broadcast
        returns (ISablierMerkleLL merkleLL)
    {
        // Prepare the constructor parameters.
        MerkleLL.ConstructorParams memory campaignParams;
        campaignParams.campaignName = "The Boys LL";
        campaignParams.campaignStartTime = uint40(block.timestamp);
        campaignParams.cancelable = true;
        campaignParams.cliffDuration = 30 days;
        campaignParams.cliffUnlockPercentage = ud60x18(0.01e18);
        campaignParams.expiration = uint40(block.timestamp + 30 days);
        campaignParams.initialAdmin = 0x79Fb3e81aAc012c08501f41296CCC145a1E15844;
        campaignParams.ipfsCID = "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR";
        campaignParams.lockup = lockup;
        campaignParams.merkleRoot = 0x0000000000000000000000000000000000000000000000000000000000000000;
        campaignParams.shape = "LL";
        campaignParams.startUnlockPercentage = ud60x18(0.01e18);
        campaignParams.vestingStartTime = 0; // i.e. block.timestamp
        campaignParams.token = token;
        campaignParams.totalDuration = 90 days;
        campaignParams.transferable = true;

        uint256 aggregateAmount = 10_000e18;
        uint256 recipientCount = 100;

        // Deploy the MerkleLL contract.
        merkleLL = factory.createMerkleLL(campaignParams, aggregateAmount, recipientCount);
    }
}
