// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud2x18 } from "@prb/math/src/UD2x18.sol";
import { ud60x18 } from "@prb/math/src/UD60x18.sol";
import { Solarray } from "solarray/src/Solarray.sol";

import { ISablierLockup } from "../src/interfaces/ISablierLockup.sol";
import { Broker, Lockup, LockupDynamic, LockupLinear, LockupTranched } from "../src/types/DataTypes.sol";

import { BaseScript } from "./Base.s.sol";

interface IERC20Mint {
    function mint(address beneficiary, uint256 value) external;
}

/// @notice Initializes the protocol by creating some streams.
contract Init is BaseScript {
    function run(ISablierLockup lockup, IERC20 token) public broadcast {
        address sender = broadcaster;
        address recipient = vm.addr(vm.deriveKey({ mnemonic: mnemonic, index: 1 }));

        /*//////////////////////////////////////////////////////////////////////////
                                       LOCKUP-LINEAR
        //////////////////////////////////////////////////////////////////////////*/

        // Mint enough tokens to the sender.
        IERC20Mint(address(token)).mint({ beneficiary: sender, value: 131_601.1e18 + 10_000e18 });

        // Approve the Lockup contracts to transfer the ERC-20 tokens from the sender.
        token.approve({ spender: address(lockup), value: type(uint256).max });

        // Create 7 Lockup Linear streams with various amounts and durations.
        //
        // - 1st stream: meant to be depleted.
        // - 2th to 4th streams: pending or streaming.
        // - 5th stream: meant to be renounced.
        // - 6th stream: meant to canceled.
        // - 7th stream: meant to be transferred to a third party.
        uint128[] memory totalAmounts = Solarray.uint128s(0.1e18, 1e18, 100e18, 1000e18, 5000e18, 25_000e18, 100_000e18);
        uint40[] memory cliffDurations = Solarray.uint40s(0, 0, 0, 0, 24 hours, 1 weeks, 12 weeks);
        uint40[] memory totalDurations =
            Solarray.uint40s(1 seconds, 1 hours, 24 hours, 1 weeks, 4 weeks, 12 weeks, 48 weeks);
        for (uint256 i = 0; i < totalDurations.length; ++i) {
            lockup.createWithDurationsLL(
                Lockup.CreateWithDurations({
                    sender: sender,
                    recipient: recipient,
                    totalAmount: totalAmounts[i],
                    token: token,
                    cancelable: true,
                    transferable: true,
                    shape: "Cliff Linear",
                    broker: Broker(address(0), ud60x18(0))
                }),
                LockupLinear.UnlockAmounts({ start: 0, cliff: 0 }),
                LockupLinear.Durations({ cliff: cliffDurations[i], total: totalDurations[i] })
            );
        }

        // Renounce the 5th stream.
        lockup.renounce({ streamId: 5 });

        // Cancel the 6th stream.
        lockup.cancel({ streamId: 6 });

        /*//////////////////////////////////////////////////////////////////////////
                                       LOCKUP-DYNAMIC
        //////////////////////////////////////////////////////////////////////////*/

        // Create the default Lockup Dynamic stream.
        LockupDynamic.SegmentWithDuration[] memory segments = new LockupDynamic.SegmentWithDuration[](2);
        segments[0] =
            LockupDynamic.SegmentWithDuration({ amount: 2500e18, exponent: ud2x18(3.14e18), duration: 1 hours });
        segments[1] =
            LockupDynamic.SegmentWithDuration({ amount: 7500e18, exponent: ud2x18(0.5e18), duration: 1 weeks });
        lockup.createWithDurationsLD(
            Lockup.CreateWithDurations({
                sender: sender,
                recipient: recipient,
                totalAmount: 10_000e18,
                token: token,
                cancelable: true,
                transferable: true,
                shape: "Exponential Dynamic",
                broker: Broker(address(0), ud60x18(0))
            }),
            segments
        );

        /*//////////////////////////////////////////////////////////////////////////
                                       LOCKUP-TRANCHED
        //////////////////////////////////////////////////////////////////////////*/

        // Create the default Lockup Tranched stream.
        LockupTranched.TrancheWithDuration[] memory tranches = new LockupTranched.TrancheWithDuration[](2);
        tranches[0] = LockupTranched.TrancheWithDuration({ amount: 1e18, duration: 1 hours });
        tranches[1] = LockupTranched.TrancheWithDuration({ amount: 1.5e18, duration: 1 weeks });
        lockup.createWithDurationsLT(
            Lockup.CreateWithDurations({
                sender: sender,
                recipient: recipient,
                totalAmount: 2.5e18,
                token: token,
                cancelable: true,
                transferable: true,
                shape: "Two Tranches",
                broker: Broker(address(0), ud60x18(0))
            }),
            tranches
        );
    }
}
