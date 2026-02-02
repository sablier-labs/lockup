// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";

import { ISablierLockupPriceGated } from "src/interfaces/ISablierLockupPriceGated.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Lockup } from "src/types/Lockup.sol";
import { LockupPriceGated } from "src/types/LockupPriceGated.sol";

import {
    OracleMissingDecimalsMock,
    OracleMissingLatestRoundDataMock,
    OracleNegativePriceMock,
    OracleWith18DecimalsMock
} from "../../../../mocks/OracleMock.sol";
import { Lockup_PriceGated_Integration_Concrete_Test } from "../LockupPriceGated.t.sol";

contract CreateWithDurationsLPG_Integration_Concrete_Test is Lockup_PriceGated_Integration_Concrete_Test {
    uint128 internal targetPrice;
    uint40 internal totalDuration;

    function setUp() public override {
        Lockup_PriceGated_Integration_Concrete_Test.setUp();

        targetPrice = defaults.LPG_TARGET_PRICE();
        totalDuration = defaults.TOTAL_DURATION();
    }

    function test_RevertWhen_DelegateCall() external {
        expectRevert_DelegateCall({
            callData: abi.encodeCall(
                lockup.createWithDurationsLPG,
                (
                    _defaultParams.createWithDurations,
                    AggregatorV3Interface(address(oracleMock)),
                    defaults.LPG_TARGET_PRICE(),
                    defaults.TOTAL_DURATION()
                )
            )
        });
    }

    function test_RevertWhen_OracleAddressZero() external whenNoDelegateCall {
        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_OracleMissesInterface.selector, address(0)));
        lockup.createWithDurationsLPG(
            _defaultParams.createWithDurations, AggregatorV3Interface(address(0)), targetPrice, totalDuration
        );
    }

    function test_RevertWhen_OracleMissesDecimals() external whenNoDelegateCall whenOracleAddressNotZero {
        OracleMissingDecimalsMock oracleMissingDecimalsMock = new OracleMissingDecimalsMock();

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockup_OracleMissesInterface.selector, address(oracleMissingDecimalsMock)
            )
        );
        lockup.createWithDurationsLPG(
            _defaultParams.createWithDurations,
            AggregatorV3Interface(address(oracleMissingDecimalsMock)),
            targetPrice,
            totalDuration
        );
    }

    function test_RevertWhen_OracleDecimalsNot8()
        external
        whenNoDelegateCall
        whenOracleAddressNotZero
        whenOracleNotMissDecimals
    {
        OracleWith18DecimalsMock oracleWith18DecimalsMock = new OracleWith18DecimalsMock();

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockup_OracleDecimalsNotEight.selector, address(oracleWith18DecimalsMock), 18
            )
        );
        lockup.createWithDurationsLPG(
            _defaultParams.createWithDurations,
            AggregatorV3Interface(address(oracleWith18DecimalsMock)),
            targetPrice,
            totalDuration
        );
    }

    function test_RevertWhen_OracleMissesLatestRoundData()
        external
        whenNoDelegateCall
        whenOracleAddressNotZero
        whenOracleNotMissDecimals
        whenOracleDecimals8
    {
        OracleMissingLatestRoundDataMock oracleMissingLatestRoundDataMock = new OracleMissingLatestRoundDataMock();

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockup_OracleMissesInterface.selector, address(oracleMissingLatestRoundDataMock)
            )
        );
        lockup.createWithDurationsLPG(
            _defaultParams.createWithDurations,
            AggregatorV3Interface(address(oracleMissingLatestRoundDataMock)),
            targetPrice,
            totalDuration
        );
    }

    function test_RevertWhen_OraclePriceNotPositive()
        external
        whenNoDelegateCall
        whenOracleAddressNotZero
        whenOracleNotMissDecimals
        whenOracleDecimals8
        whenOracleNotMissLatestRoundData
    {
        OracleNegativePriceMock oracleNegativePriceMock = new OracleNegativePriceMock();

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockup_OracleReturnsNegativePrice.selector, address(oracleNegativePriceMock)
            )
        );
        lockup.createWithDurationsLPG(
            _defaultParams.createWithDurations,
            AggregatorV3Interface(address(oracleNegativePriceMock)),
            targetPrice,
            totalDuration
        );
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
        uint128 currentOraclePrice = uint128(uint256(oracleMock.price()));

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockup_TargetPriceTooLow.selector, currentOraclePrice, currentOraclePrice
            )
        );
        lockup.createWithDurationsLPG(
            _defaultParams.createWithDurations,
            AggregatorV3Interface(address(oracleMock)),
            currentOraclePrice,
            totalDuration
        );
    }

    function test_RevertWhen_DurationZero()
        external
        whenNoDelegateCall
        whenOracleAddressNotZero
        whenOracleNotMissDecimals
        whenOracleDecimals8
        whenOracleNotMissLatestRoundData
        whenOraclePricePositive
        whenTargetPriceExceedsCurrentPrice
    {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockupHelpers_StartTimeNotLessThanEndTime.selector,
                uint40(block.timestamp),
                uint40(block.timestamp)
            )
        );
        lockup.createWithDurationsLPG(
            _defaultParams.createWithDurations, AggregatorV3Interface(address(oracleMock)), targetPrice, 0
        );
    }

    function test_WhenDurationNotZero()
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

        Lockup.Timestamps memory expectedTimestamps =
            Lockup.Timestamps({ start: getBlockTimestamp(), end: getBlockTimestamp() + defaults.TOTAL_DURATION() });

        // It should perform the ERC-20 transfer.
        expectCallToTransferFrom({ from: users.sender, to: address(lockup), value: defaults.DEPOSIT_AMOUNT() });

        // It should emit {CreateLockupPriceGatedStream} and {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: expectedStreamId });
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupPriceGated.CreateLockupPriceGatedStream({
            streamId: expectedStreamId,
            oracle: AggregatorV3Interface(address(oracleMock)),
            targetPrice: defaults.LPG_TARGET_PRICE()
        });

        // Create the stream.
        uint256 streamId = lockup.createWithDurationsLPG(
            _defaultParams.createWithDurations,
            AggregatorV3Interface(address(oracleMock)),
            defaults.LPG_TARGET_PRICE(),
            defaults.TOTAL_DURATION()
        );

        // It should create the stream.
        assertEq(lockup.getEndTime(streamId), expectedTimestamps.end, "endTime");
        assertEq(lockup.isCancelable(streamId), true, "isCancelable");
        assertFalse(lockup.isDepleted(streamId), "isDepleted");
        assertTrue(lockup.isStream(streamId), "isStream");
        assertTrue(lockup.isTransferable(streamId), "isTransferable");
        assertEq(lockup.getLockupModel(streamId), Lockup.Model.LOCKUP_PRICE_GATED);
        assertEq(lockup.getRecipient(streamId), users.recipient, "recipient");
        assertEq(lockup.getSender(streamId), users.sender, "sender");
        assertEq(lockup.getStartTime(streamId), expectedTimestamps.start, "startTime");
        assertEq(lockup.getUnderlyingToken(streamId), dai, "underlyingToken");
        assertFalse(lockup.wasCanceled(streamId), "wasCanceled");

        // It should store the unlock params.
        LockupPriceGated.UnlockParams memory unlockParams = lockup.getPriceGatedUnlockParams(streamId);
        assertEq(address(unlockParams.oracle), address(oracleMock), "oracle");
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
