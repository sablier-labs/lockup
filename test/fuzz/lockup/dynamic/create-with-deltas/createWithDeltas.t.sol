// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { Solarray } from "solarray/Solarray.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Lockup, LockupDynamic } from "src/types/DataTypes.sol";

import { Dynamic_Fuzz_Test } from "../Dynamic.t.sol";

contract CreateWithDeltas_Dynamic_Fuzz_Test is Dynamic_Fuzz_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        Dynamic_Fuzz_Test.setUp();

        // Load the stream id.
        streamId = dynamic.nextStreamId();
    }

    modifier whenLoopCalculationsDoNotOverflowBlockGasLimit() {
        _;
    }

    modifier whenDeltasNotZero() {
        _;
    }

    modifier whenMilestonesCalculationsDoNotOverflow() {
        _;
    }

    struct Vars {
        uint256 actualNextStreamId;
        address actualNFTOwner;
        uint256 actualProtocolRevenues;
        Lockup.CreateAmounts createAmounts;
        uint256 expectedNextStreamId;
        address expectedNFTOwner;
        uint256 expectedProtocolRevenues;
        address funder;
        uint128 initialProtocolRevenues;
        LockupDynamic.Segment[] segmentsWithMilestones;
        uint128 totalAmount;
    }

    /// @dev it should perform the ERC-20 transfers, create the stream, bump the next stream id, mint the NFT,
    /// record the protocol fee, and emit a {CreateLockupDynamicStream} event.
    function testFuzz_CreateWithDeltas(LockupDynamic.SegmentWithDelta[] memory segments)
        external
        whenLoopCalculationsDoNotOverflowBlockGasLimit
        whenDeltasNotZero
        whenMilestonesCalculationsDoNotOverflow
    {
        vm.assume(segments.length != 0);

        // Fuzz the deltas.
        Vars memory vars;
        fuzzSegmentDeltas(segments);

        // Fuzz the segment amounts and calculate the create amounts (total, deposit, protocol fee, and broker fee).
        (vars.totalAmount, vars.createAmounts) = fuzzSegmentAmountsAndCalculateCreateAmounts(segments);

        // Make the sender the funder of the stream.
        vars.funder = users.sender;

        // Load the initial protocol revenues.
        vars.initialProtocolRevenues = dynamic.protocolRevenues(DEFAULT_ASSET);

        // Mint enough ERC-20 assets to the fuzzed funder.
        deal({ token: address(DEFAULT_ASSET), to: vars.funder, give: vars.totalAmount });

        // Expect the ERC-20 assets to be transferred from the funder to {SablierV2LockupDynamic}.
        expectTransferFromCall({
            from: vars.funder,
            to: address(dynamic),
            amount: vars.createAmounts.deposit + vars.createAmounts.protocolFee
        });

        // Expect the broker fee to be paid to the broker, if not zero.
        if (vars.createAmounts.brokerFee > 0) {
            expectTransferFromCall({ from: vars.funder, to: users.broker, amount: vars.createAmounts.brokerFee });
        }

        // Create the range struct.
        vars.segmentsWithMilestones = getSegmentsWithMilestones(segments);
        LockupDynamic.Range memory range = LockupDynamic.Range({
            start: getBlockTimestamp(),
            end: vars.segmentsWithMilestones[vars.segmentsWithMilestones.length - 1].milestone
        });

        // Expect a {CreateLockupDynamicStream} event to be emitted.
        vm.expectEmit();
        emit CreateLockupDynamicStream({
            streamId: streamId,
            funder: vars.funder,
            sender: defaultParams.createWithDeltas.sender,
            recipient: defaultParams.createWithDeltas.recipient,
            amounts: vars.createAmounts,
            asset: DEFAULT_ASSET,
            cancelable: defaultParams.createWithDeltas.cancelable,
            segments: vars.segmentsWithMilestones,
            range: range,
            broker: defaultParams.createWithDeltas.broker.account
        });

        // Create the stream.
        LockupDynamic.CreateWithDeltas memory params = defaultParams.createWithDeltas;
        params.totalAmount = vars.totalAmount;
        params.segments = segments;
        dynamic.createWithDeltas(params);

        // Assert that the stream has been created.
        LockupDynamic.Stream memory actualStream = dynamic.getStream(streamId);
        assertEq(actualStream.amounts, Lockup.Amounts({ deposit: vars.createAmounts.deposit, withdrawn: 0 }));
        assertEq(actualStream.asset, defaultStream.asset, "asset");
        assertEq(actualStream.endTime, range.end, "endTime");
        assertEq(actualStream.isCancelable, defaultStream.isCancelable, "isCancelable");
        assertEq(actualStream.segments, vars.segmentsWithMilestones);
        assertEq(actualStream.sender, defaultStream.sender, "sender");
        assertEq(actualStream.startTime, range.start, "startTime");
        assertEq(actualStream.status, defaultStream.status);

        // Assert that the next stream id has been bumped.
        vars.actualNextStreamId = dynamic.nextStreamId();
        vars.expectedNextStreamId = streamId + 1;
        assertEq(vars.actualNextStreamId, vars.expectedNextStreamId, "nextStreamId");

        // Assert that the protocol fee has been recorded.
        vars.actualProtocolRevenues = dynamic.protocolRevenues(DEFAULT_ASSET);
        vars.expectedProtocolRevenues = vars.initialProtocolRevenues + vars.createAmounts.protocolFee;
        assertEq(vars.actualProtocolRevenues, vars.expectedProtocolRevenues, "protocolRevenues");

        // Assert that the NFT has been minted.
        vars.actualNFTOwner = dynamic.ownerOf({ tokenId: streamId });
        vars.expectedNFTOwner = defaultParams.createWithDeltas.recipient;
        assertEq(vars.actualNFTOwner, vars.expectedNFTOwner, "NFT owner");
    }
}
