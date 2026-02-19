// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";

import { Integration_Test } from "./../../Integration.t.sol";

contract CalculateMinFeeWei_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_Null() external {
        // It should revert.
        expectRevert_Null(abi.encodeCall(bob.calculateMinFeeWei, (vaultIds.nullVault)), vaultIds.nullVault);
    }

    function test_GivenAdapter() external view givenNotNull {
        // It should return zero.
        uint256 minFeeWei = bob.calculateMinFeeWei(vaultIds.adapterVault);
        assertEq(minFeeWei, 0, "adapter vault should return 0");
    }

    function test_GivenNoAdapter() external view givenNotNull {
        // It should return the minimum fee in wei.
        uint256 expected = comptroller.calculateMinFeeWei({ protocol: ISablierComptroller.Protocol.Bob });
        uint256 actual = bob.calculateMinFeeWei(vaultIds.defaultVault);
        assertEq(actual, expected, "non-adapter vault minFeeWei");
    }
}
