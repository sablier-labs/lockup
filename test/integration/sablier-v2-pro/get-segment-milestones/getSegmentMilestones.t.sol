// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2ProTest } from "../SablierV2ProTest.t.sol";

contract GetSegmentMilestones__Test is SablierV2ProTest {
    /// @dev it should return zero.
    function testGetSegmentMilestones__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint64[] memory actualSegmentMilestones = sablierV2Pro.getSegmentMilestones(nonStreamId);
        uint64[] memory expectedSegmentMilestones;
        assertEqUint64Array(actualSegmentMilestones, expectedSegmentMilestones);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the correct segment milestones.
    function testGetSegmentMilestones() external StreamExistent {
        uint256 daiStreamId = createDefaultDaiStream();
        uint64[] memory actualSegmentMilestones = sablierV2Pro.getSegmentMilestones(daiStreamId);
        uint64[] memory expectedSegmentMilestones = daiStream.segmentMilestones;
        assertEqUint64Array(actualSegmentMilestones, expectedSegmentMilestones);
    }
}
