// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Lockup } from "src/types/DataTypes.sol";

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract GetStatus_Unit_Test is Unit_Test, Lockup_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) { }

    /// @dev it should return the NULL status.
    function test_GetStatus_Null() external {
        uint256 nullStreamId = 1729;
        Lockup.Status actualStatus = lockup.getStatus(nullStreamId);
        Lockup.Status expectedStatus = Lockup.Status.NULL;
        assertEq(actualStatus, expectedStatus);
    }

    modifier whenStreamCreated() {
        defaultStreamId = createDefaultStream();
        _;
    }

    /// @dev it should return the ACTIVE status.
    function test_GetStatus_Active() external whenStreamCreated {
        Lockup.Status actualStatus = lockup.getStatus(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.ACTIVE;
        assertEq(actualStatus, expectedStatus);
    }

    modifier whenStreamCanceled() {
        lockup.cancel(defaultStreamId);
        _;
    }

    /// @dev it should return the CANCELED status.
    function test_GetStatus_Canceled() external whenStreamCreated whenStreamCanceled {
        Lockup.Status actualStatus = lockup.getStatus(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    modifier whenStreamDepleted() {
        vm.warp({ timestamp: DEFAULT_END_TIME });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        _;
    }

    /// @dev it should return the DEPLETED status.
    function test_GetStatus_Depleted() external whenStreamCreated whenStreamDepleted {
        Lockup.Status actualStatus = lockup.getStatus(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.DEPLETED;
        assertEq(actualStatus, expectedStatus);
    }
}
