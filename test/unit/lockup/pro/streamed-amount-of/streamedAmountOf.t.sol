// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Segment } from "src/types/Structs.sol";

import { Pro_Unit_Test } from "../Pro.t.sol";

contract StreamedAmountOf_Pro_Unit_Test is Pro_Unit_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override {
        Pro_Unit_Test.setUp();

        // Create the default stream.
        defaultStreamId = createDefaultStream();
    }

    modifier streamNotActive() {
        _;
    }

    /// @dev it should return zero.
    function test_StreamedAmountOf_StreamNull() external streamNotActive {
        uint256 nullStreamId = 1729;
        uint128 actualStreamedAmount = pro.streamedAmountOf(nullStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    /// @dev it should return zero.
    function test_StreamedAmountOf_StreamCanceled() external streamNotActive {
        lockup.cancel(defaultStreamId);
        uint256 actualStreamedAmount = pro.streamedAmountOf(defaultStreamId);
        uint256 expectedStreamedAmount = pro.getWithdrawnAmount(defaultStreamId);
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    /// @dev it should return the withdrawn amount.
    function test_StreamedAmountOf_StreamDepleted() external streamNotActive {
        vm.warp({ timestamp: DEFAULT_END_TIME });
        uint128 withdrawAmount = DEFAULT_NET_DEPOSIT_AMOUNT;
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });
        uint256 actualStreamedAmount = pro.streamedAmountOf(defaultStreamId);
        uint256 expectedStreamedAmount = withdrawAmount;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    modifier streamActive() {
        _;
    }

    /// @dev it should return zero.
    function test_StreamedAmountOf_StartTimeGreaterThanCurrentTime() external streamActive {
        vm.warp({ timestamp: 0 });
        uint128 actualStreamedAmount = pro.streamedAmountOf(defaultStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    /// @dev it should return zero.
    function test_StreamedAmountOf_StartTimeEqualToCurrentTime() external streamActive {
        vm.warp({ timestamp: DEFAULT_START_TIME });
        uint128 actualStreamedAmount = pro.streamedAmountOf(defaultStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    modifier startTimeLessThanCurrentTime() {
        _;
    }

    /// @dev it should return the correct streamed amount.
    function test_StreamedAmountOf_OneSegment() external streamActive startTimeLessThanCurrentTime {
        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + 2_000 seconds });

        // Create a single-element segment array.
        Segment[] memory segments = new Segment[](1);
        segments[0] = Segment({
            amount: DEFAULT_NET_DEPOSIT_AMOUNT,
            exponent: DEFAULT_SEGMENTS[1].exponent,
            milestone: DEFAULT_END_TIME
        });

        // Create the stream with the one-segment array.
        uint256 streamId = createDefaultStreamWithSegments(segments);

        // Run the test.
        uint128 actualStreamedAmount = pro.streamedAmountOf(streamId);
        uint128 expectedStreamedAmount = 4472.13595499957941e18; // (0.2^0.5)*10,000
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    modifier multipleSegments() {
        _;
    }

    /// @dev it should return the correct streamed amount.
    function test_StreamedAmountOf_CurrentMilestone1st()
        external
        streamActive
        multipleSegments
        startTimeLessThanCurrentTime
    {
        // Run the test.
        uint128 actualStreamedAmount = pro.streamedAmountOf(defaultStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    modifier currentMilestoneNot1st() {
        _;
    }

    /// @dev it should return the correct streamed amount.
    function test_StreamedAmountOf_CurrentMilestoneNot1st()
        external
        streamActive
        startTimeLessThanCurrentTime
        multipleSegments
        currentMilestoneNot1st
    {
        // Warp into the future. 750 seconds is ~10% of the way in the second segment.
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_CLIFF_DURATION + 750 seconds });

        // Run the test.
        uint128 actualStreamedAmount = pro.streamedAmountOf(defaultStreamId);
        uint128 expectedStreamedAmount = DEFAULT_SEGMENTS[0].amount + 2371.708245126284505e18; // ~7,500*0.1^{0.5}
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }
}
