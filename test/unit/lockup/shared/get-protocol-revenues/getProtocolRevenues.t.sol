// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract GetProtocolRevenues_Unit_Test is Unit_Test, Lockup_Shared_Test {
    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {}

    /// @dev it should return zero.
    function test_GetProtocolRevenues_ProtocolRevenuesZero() external {
        uint128 actualProtocolRevenues = config.getProtocolRevenues(DEFAULT_ASSET);
        uint128 expectedProtocolRevenues = 0;
        assertEq(actualProtocolRevenues, expectedProtocolRevenues, "protocolRevenues");
    }

    modifier protocolRevenuesNotZero() {
        // Create the default stream, which will accrue revenues for the protocol.
        changePrank({ who: users.sender });
        createDefaultStream();
        changePrank({ who: users.admin });
        _;
    }

    /// @dev it should return the correct protocol revenues.
    function test_GetProtocolRevenues() external protocolRevenuesNotZero {
        uint128 actualProtocolRevenues = config.getProtocolRevenues(DEFAULT_ASSET);
        uint128 expectedProtocolRevenues = DEFAULT_PROTOCOL_FEE_AMOUNT;
        assertEq(actualProtocolRevenues, expectedProtocolRevenues, "protocolRevenues");
    }
}
