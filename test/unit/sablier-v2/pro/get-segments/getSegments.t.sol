// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Segment } from "src/types/Structs.sol";

import { ProTest } from "../ProTest.t.sol";

contract GetSegments_ProTest is ProTest {
    /// @dev it should return an empty array.
    function test_GetSegments_StreamNulls() external {
        uint256 nullStreamId = 1729;
        Segment[] memory actualSegments = pro.getSegments(nullStreamId);
        Segment[] memory expectedSegments;
        assertEq(actualSegments, expectedSegments);
    }

    modifier streamNonNull() {
        _;
    }

    /// @dev it should return the correct segments.
    function test_GetSegments() external streamNonNull {
        uint256 streamId = createDefaultStream();
        Segment[] memory actualSegments = pro.getSegments(streamId);
        Segment[] memory expectedSegments = DEFAULT_SEGMENTS;
        assertEq(actualSegments, expectedSegments);
    }
}
