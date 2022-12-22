// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SD1x18 } from "@prb/math/SD1x18.sol";

import { DataTypes } from "src/libraries/DataTypes.sol";
import { SablierV2Pro } from "src/SablierV2Pro.sol";

import { UnitTest } from "../UnitTest.t.sol";

/// @title ProTest
/// @notice Common contract members needed across SablierV2Pro unit tests.
abstract contract ProTest is UnitTest {
    /*//////////////////////////////////////////////////////////////////////////
                                      CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_SEGMENT_COUNT = 200;
    uint128[] internal SEGMENT_AMOUNTS_DAI = [2_000e18, 8_000e18];
    uint128[] internal SEGMENT_AMOUNTS_USDC = [2_000e6, 8_000e6];
    uint40[] internal SEGMENT_DELTAS = [2_000 seconds, 8_000 seconds];
    SD1x18[] internal SEGMENT_EXPONENTS = [SD1x18.wrap(3.14e18), SD1x18.wrap(0.5e18)];
    uint40[] internal SEGMENT_MILESTONES = [2_100 seconds, 10_100 seconds];

    /*//////////////////////////////////////////////////////////////////////////
                                  TESTING VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    DataTypes.ProStream internal daiStream;
    SablierV2Pro internal pro;
    DataTypes.ProStream internal usdcStream;

    /*//////////////////////////////////////////////////////////////////////////
                                   SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev A setup function invoked before each test case.
    function setUp() public virtual {
        pro = new SablierV2Pro({
            initialComptroller: comptroller,
            maxFee: MAX_FEE,
            maxSegmentCount: MAX_SEGMENT_COUNT
        });

        // Create the default streams to be used across the tests.
        daiStream = DataTypes.ProStream({
            cancelable: true,
            depositAmount: DEFAULT_GROSS_DEPOSIT_AMOUNT,
            isEntity: true,
            segmentAmounts: SEGMENT_AMOUNTS_DAI,
            segmentExponents: SEGMENT_EXPONENTS,
            segmentMilestones: SEGMENT_MILESTONES,
            sender: users.sender,
            startTime: DEFAULT_START_TIME,
            stopTime: SEGMENT_MILESTONES[1],
            token: address(dai),
            withdrawnAmount: 0
        });

        // Approve the SablierV2Pro contract to spend tokens from the sender, recipient, Alice and Eve.
        approveMax({ caller: users.sender, spender: address(pro) });
        approveMax({ caller: users.recipient, spender: address(pro) });
        approveMax({ caller: users.alice, spender: address(pro) });
        approveMax({ caller: users.eve, spender: address(pro) });

        // Make the sender the caller for all subsequent calls.
        changePrank(users.sender);
    }

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Helper function to create a default stream with $DAI used as streaming currency.
    function createDefaultDaiStream() internal returns (uint256 daiStreamId) {
        daiStreamId = pro.create(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.cancelable,
            daiStream.startTime,
            daiStream.segmentAmounts,
            daiStream.segmentExponents,
            daiStream.segmentMilestones
        );
    }

    /// @dev Helper function to create a default stream with $USDC used as streaming currency.
    function createDefaultUsdcStream() internal returns (uint256 usdcStreamId) {
        usdcStreamId = pro.create(
            usdcStream.sender,
            users.recipient,
            usdcStream.depositAmount,
            usdcStream.token,
            usdcStream.cancelable,
            usdcStream.startTime,
            usdcStream.segmentAmounts,
            usdcStream.segmentExponents,
            usdcStream.segmentMilestones
        );
    }

    /// @dev Helper function to create a non-cancelable stream.
    function createNonCancelableDaiStream() internal returns (uint256 nonCancelableDaiStreamId) {
        bool cancelable = false;
        nonCancelableDaiStreamId = pro.create(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            cancelable,
            daiStream.startTime,
            daiStream.segmentAmounts,
            daiStream.segmentExponents,
            daiStream.segmentMilestones
        );
    }
}
