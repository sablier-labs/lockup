/* solhint-disable var-name-mixedcase */
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";
import { SablierV2Linear } from "@sablier/v2-core/SablierV2Linear.sol";

import { SablierV2UnitTest } from "../SablierV2UnitTest.t.sol";

/// @title SablierV2LinearUnitTest
/// @author Sablier Labs Ltd.
/// @notice Common contract members needed across Sablier V2 test contracts.
/// @dev Strictly for test purposes.
abstract contract SablierV2LinearUnitTest is SablierV2UnitTest {
    /// EVENTS ///

    event CreateStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 startTime,
        uint256 stopTime,
        bool cancelable
    );

    /// CONSTANTS ///

    uint256 internal constant DEFAULT_TIME_OFFSET = 100 seconds;
    uint256 internal immutable DEFAULT_WITHDRAW_AMOUNT = bn(100);

    /// OTHER TESTING VARIABLES ///

    SablierV2Linear internal sablierV2Linear = new SablierV2Linear();
    ISablierV2Linear.Stream internal stream;

    // SETUP FUNCTION ///

    /// @dev A setup function invoked before each test case.
    function setUp() public virtual {
        // Create the default stream to be used across many tests.
        stream = ISablierV2Linear.Stream({
            cancelable: true,
            depositAmount: DEFAULT_DEPOSIT_AMOUNT,
            recipient: users.recipient,
            sender: users.sender,
            startTime: DEFAULT_START_TIME,
            stopTime: DEFAULT_STOP_TIME,
            token: usd,
            withdrawnAmount: 0
        });

        // Approve the SablierV2Linear contract to spend $USD from the `sender` account.
        vm.prank(users.sender);
        usd.approve(address(sablierV2Linear), type(uint256).max);

        // Approve the SablierV2Linear contract to spend $USD from the `funder` account.
        vm.prank(users.funder);
        usd.approve(address(sablierV2Linear), type(uint256).max);

        // Sets all subsequent calls' `msg.sender` to be `sender`.
        vm.startPrank(users.sender);
    }

    /// NON-CONSTANT FUNCTIONS ///

    /// @dev Helper function to create a linear stream.
    function createDefaultStream() internal returns (uint256 streamId) {
        streamId = sablierV2Linear.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            stream.stopTime,
            stream.cancelable
        );
    }

    /// @dev Helper function to compare two `Stream` structs.
    function assertEq(ISablierV2Linear.Stream memory a, ISablierV2Linear.Stream memory b) internal {
        assertEq(a.depositAmount, b.depositAmount);
        assertEq(a.cancelable, b.cancelable);
        assertEq(a.recipient, b.recipient);
        assertEq(a.sender, b.sender);
        assertEq(a.startTime, b.startTime);
        assertEq(a.stopTime, b.stopTime);
        assertEq(a.token, b.token);
        assertEq(a.withdrawnAmount, b.withdrawnAmount);
    }
}
