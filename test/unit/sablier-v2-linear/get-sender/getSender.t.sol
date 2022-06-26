// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__GetSender__StreamNonExistent is SablierV2LinearUnitTest {
    /// @dev it should return zero.
    function testGetSender() external {
        uint256 nonStreamId = 1729;
        address actualSender = sablierV2Linear.getSender(nonStreamId);
        address expectedSender = address(0);
        assertEq(actualSender, expectedSender);
    }
}

contract StreamExistent {}

contract SablierV2Linear__GetSender is SablierV2LinearUnitTest, StreamExistent {
    /// @dev it should return the correct sender.
    function testGetSender() external {
        uint256 daiStreamId = createDefaultDaiStream();
        address actualSender = sablierV2Linear.getSender(daiStreamId);
        address expectedSender = daiStream.sender;
        assertEq(actualSender, expectedSender);
    }
}
