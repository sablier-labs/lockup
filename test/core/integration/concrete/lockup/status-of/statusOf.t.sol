// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/core/libraries/Errors.sol";
import { Lockup } from "src/core/types/DataTypes.sol";
import { Integration_Test } from "./../../../Integration.t.sol";
import { Lockup_Integration_Shared_Test } from "./../../../shared/lockup/Lockup.t.sol";

abstract contract StatusOf_Integration_Concrete_Test is Integration_Test, Lockup_Integration_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Integration_Test, Lockup_Integration_Shared_Test) { }

    function test_RevertGiven_Null() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_Null.selector, nullStreamId));
        lockup.statusOf(nullStreamId);
    }

    modifier givenNotNull() {
        defaultStreamId = createDefaultStream();
        _;
    }

    function test_GivenAssetsFullyWithdrawn() external givenNotNull {
        vm.warp({ newTimestamp: defaults.END_TIME() });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });

        // It should return DEPLETED.
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.DEPLETED;
        assertEq(actualStatus, expectedStatus);
    }

    modifier givenAssetsNotFullyWithdrawn() {
        _;
    }

    function test_GivenCanceledStream() external givenNotNull givenAssetsNotFullyWithdrawn {
        vm.warp({ newTimestamp: defaults.CLIFF_TIME() });
        lockup.cancel(defaultStreamId);

        // It should return CANCELED.
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    modifier givenNotCanceledStream() {
        _;
    }

    function test_GivenStartTimeInFuture() external givenNotNull givenAssetsNotFullyWithdrawn givenNotCanceledStream {
        vm.warp({ newTimestamp: getBlockTimestamp() - 1 seconds });

        // It should return PENDING.
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.PENDING;
        assertEq(actualStatus, expectedStatus);
    }

    modifier givenStartTimeNotInFuture() {
        _;
    }

    function test_GivenZeroRefundableAmount()
        external
        givenNotNull
        givenAssetsNotFullyWithdrawn
        givenNotCanceledStream
        givenStartTimeNotInFuture
    {
        vm.warp({ newTimestamp: defaults.END_TIME() });

        // It should return SETTLED.
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.SETTLED;
        assertEq(actualStatus, expectedStatus);
    }

    function test_GivenNonZeroRefundableAmount()
        external
        givenNotNull
        givenAssetsNotFullyWithdrawn
        givenNotCanceledStream
        givenStartTimeNotInFuture
    {
        vm.warp({ newTimestamp: defaults.START_TIME() + 1 seconds });

        // It should return STREAMING.
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);
    }
}
