// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract CalculateMinFeeWeiFor_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_Null() external {
        expectRevert_Null({ callData: abi.encodeCall(lockup.calculateMinFeeWei, ids.nullStream) });
    }

    function test_GivenCustomFeeSet() external givenNotNull {
        setMsgSender(admin);

        uint256 customFeeUSD = 100e8; // 100 USD.

        // Set the custom fee.
        comptroller.setCustomFeeUSDFor({
            protocol: ISablierComptroller.Protocol.Lockup,
            user: users.sender,
            customFeeUSD: customFeeUSD
        });

        uint256 expectedFeeWei = (1e18 * customFeeUSD) / 3000e8; // at $3000 per ETH

        // It should return the custom fee in wei.
        assertEq(lockup.calculateMinFeeWei(ids.defaultStream), expectedFeeWei, "customFeeWei");
    }

    function test_GivenCustomFeeNotSet() external view givenNotNull {
        // It should return the minimum fee in wei.
        assertEq(lockup.calculateMinFeeWei(ids.defaultStream), LOCKUP_MIN_FEE_WEI, "minFeeWei");
    }
}
