// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2ProTest } from "../SablierV2ProTest.t.sol";

contract GetReturnableAmount__Test is SablierV2ProTest {
    uint256 internal daiStreamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default dai stream, since most tests need it.
        daiStreamId = createDefaultDaiStream();
    }

    /// @dev it should return zero.
    function testGetReturnableAmount__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256 actualReturnableAmount = sablierV2Pro.getReturnableAmount(nonStreamId);
        uint256 expectedReturnableAmount = 0;
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the deposit amount.
    function testGetReturnableAmount__WithdrawableAmountZero__NoWithdrawals() external StreamExistent {
        uint256 actualReturnableAmount = sablierV2Pro.getReturnableAmount(daiStreamId);
        uint256 expectedReturnableAmount = daiStream.depositAmount;
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }

    /// @dev it should return the correct returnable amount.
    function testGetReturnableAmount__WithdrawableAmountZero__WithWithdrawals() external StreamExistent {
        vm.warp({ timestamp: daiStream.startTime + TIME_OFFSET });
        sablierV2Pro.withdraw(daiStreamId, SEGMENT_AMOUNTS_DAI[0]);
        uint256 actualReturnableAmount = sablierV2Pro.getReturnableAmount(daiStreamId);
        uint256 expectedReturnableAmount = daiStream.depositAmount - SEGMENT_AMOUNTS_DAI[0];
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }

    /// @dev it should return the correct returnable amount.
    function testGetReturnableAmount__WithdrawableAmountNotZero__NoWithdrawals() external StreamExistent {
        vm.warp({ timestamp: daiStream.startTime + TIME_OFFSET });
        uint256 actualReturnableAmount = sablierV2Pro.getReturnableAmount(daiStreamId);
        uint256 expectedReturnableAmount = daiStream.depositAmount - SEGMENT_AMOUNTS_DAI[0];
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }

    /// @dev it should return the correct returnable amount.
    function testGetReturnableAmount__WithdrawableAmountNotZero__WithWithdrawals() external StreamExistent {
        vm.warp({ timestamp: daiStream.startTime + TIME_OFFSET + 1 seconds });
        sablierV2Pro.withdraw(daiStreamId, SEGMENT_AMOUNTS_DAI[0]);
        uint256 actualReturnableAmount = sablierV2Pro.getReturnableAmount(daiStreamId);
        // TIME_OFFSET + 1 seconds is 0.0125% of the way in the second segment => ~8,000*0.000125^{0.5}
        uint256 expectedReturnableAmount = daiStream.depositAmount - SEGMENT_AMOUNTS_DAI[0] - 89.442719099991584e18;
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }
}
