// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";

import { ISablierLockupPriceGated } from "src/interfaces/ISablierLockupPriceGated.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Lockup } from "src/types/Lockup.sol";
import { LockupPriceGated } from "src/types/LockupPriceGated.sol";

import { Lockup_PriceGated_Integration_Concrete_Test } from "../LockupPriceGated.t.sol";

contract CreateWithTimestampsLPG_Integration_Concrete_Test is Lockup_PriceGated_Integration_Concrete_Test {
    Lockup.CreateWithTimestamps internal createParams;

    function setUp() public override {
        Lockup_PriceGated_Integration_Concrete_Test.setUp();
        createParams = Lockup.CreateWithTimestamps({
            sender: _defaultParams.createWithTimestamps.sender,
            recipient: _defaultParams.createWithTimestamps.recipient,
            depositAmount: _defaultParams.createWithTimestamps.depositAmount,
            token: _defaultParams.createWithTimestamps.token,
            cancelable: _defaultParams.createWithTimestamps.cancelable,
            transferable: _defaultParams.createWithTimestamps.transferable,
            timestamps: Lockup.Timestamps({
                start: getBlockTimestamp(),
                end: getBlockTimestamp() + defaults.TOTAL_DURATION()
            }),
            shape: _defaultParams.createWithTimestamps.shape
        });
    }

    function test_RevertWhen_DelegateCall() external {
        expectRevert_DelegateCall({
            callData: abi.encodeCall(lockup.createWithTimestampsLPG, (createParams, defaults.unlockParams()))
        });
    }

    function test_RevertWhen_TargetPriceNotExceedCurrentPrice()
        external
        whenNoDelegateCall
        whenOracleAddressNotZero
        whenOracleNotMissDecimals
        whenOracleDecimals8
        whenOracleNotMissLatestRoundData
        whenOraclePricePositive
    {
        uint128 currentOraclePrice = uint128(uint256(oracle.price()));
        LockupPriceGated.UnlockParams memory unlockParams = defaults.unlockParams(currentOraclePrice);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockup_TargetPriceTooLow.selector, currentOraclePrice, currentOraclePrice
            )
        );
        lockup.createWithTimestampsLPG(createParams, unlockParams);
    }

    function test_RevertWhen_StartTimeNotLessThanEndTime()
        external
        whenNoDelegateCall
        whenOracleAddressNotZero
        whenOracleNotMissDecimals
        whenOracleDecimals8
        whenOracleNotMissLatestRoundData
        whenOraclePricePositive
        whenTargetPriceExceedsCurrentPrice
    {
        LockupPriceGated.UnlockParams memory unlockParams = defaults.unlockParams();

        // Set start == end to trigger the revert.
        createParams.timestamps = Lockup.Timestamps({ start: getBlockTimestamp(), end: getBlockTimestamp() });

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockupHelpers_StartTimeNotLessThanEndTime.selector,
                getBlockTimestamp(),
                getBlockTimestamp()
            )
        );
        lockup.createWithTimestampsLPG(createParams, unlockParams);
    }

    function test_WhenStartTimeLessThanEndTime()
        external
        whenNoDelegateCall
        whenOracleAddressNotZero
        whenOracleNotMissDecimals
        whenOracleDecimals8
        whenOracleNotMissLatestRoundData
        whenOraclePricePositive
        whenTargetPriceExceedsCurrentPrice
    {
        uint256 expectedStreamId = lockup.nextStreamId();

        // It should perform the ERC-20 transfer.
        expectCallToTransferFrom({ from: users.sender, to: address(lockup), value: defaults.DEPOSIT_AMOUNT() });

        // It should emit {CreateLockupPriceGatedStream} and {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: expectedStreamId });
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupPriceGated.CreateLockupPriceGatedStream({
            streamId: expectedStreamId,
            oracle: AggregatorV3Interface(address(oracle)),
            targetPrice: defaults.LPG_TARGET_PRICE()
        });

        // Create the stream.
        uint256 streamId = lockup.createWithTimestampsLPG(createParams, defaults.unlockParams());

        // It should create the stream.
        assertEq(lockup.getEndTime(streamId), createParams.timestamps.end, "endTime");
        assertEq(lockup.isCancelable(streamId), true, "isCancelable");
        assertFalse(lockup.isDepleted(streamId), "isDepleted");
        assertTrue(lockup.isStream(streamId), "isStream");
        assertTrue(lockup.isTransferable(streamId), "isTransferable");
        assertEq(lockup.getLockupModel(streamId), Lockup.Model.LOCKUP_PRICE_GATED);
        assertEq(lockup.getRecipient(streamId), users.recipient, "recipient");
        assertEq(lockup.getSender(streamId), users.sender, "sender");
        assertEq(lockup.getStartTime(streamId), createParams.timestamps.start, "startTime");
        assertEq(lockup.getUnderlyingToken(streamId), dai, "underlyingToken");
        assertFalse(lockup.wasCanceled(streamId), "wasCanceled");

        // It should store the unlock params.
        LockupPriceGated.UnlockParams memory unlockParams = lockup.getPriceGatedUnlockParams(streamId);
        assertEq(address(unlockParams.oracle), address(oracle), "oracle");
        assertEq(unlockParams.targetPrice, defaults.LPG_TARGET_PRICE(), "targetPrice");

        // Assert that the stream's status is "STREAMING".
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);

        // It should bump the next stream ID.
        uint256 actualNextStreamId = lockup.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId, "nextStreamId");

        // It should mint the NFT.
        address actualNFTOwner = lockup.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
