// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";
import { Lockup } from "src/types/DataTypes.sol";

import { Invariant_Test } from "../Invariant.t.sol";
import { FlashLoanHandler } from "../handlers/FlashLoanHandler.t.sol";
import { LockupHandler } from "../handlers/LockupHandler.t.sol";
import { LockupHandlerStorage } from "../handlers/LockupHandlerStorage.t.sol";

/// @title Lockup_Invariant_Test
/// @notice Common invariant test logic needed across contracts that inherit from {SablierV2Lockup}.
abstract contract Lockup_Invariant_Test is Invariant_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    FlashLoanHandler internal flashLoanHandler;
    ISablierV2Lockup internal lockup;
    LockupHandler internal lockupHandler;
    LockupHandlerStorage internal lockupHandlerStorage;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Invariant_Test.setUp();

        // Deploy the lockupHandlerStorage.
        lockupHandlerStorage = new LockupHandlerStorage();

        // Exclude the lockup handler store from being `msg.sender`.
        excludeSender(address(lockupHandlerStorage));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     INVARIANTS
    //////////////////////////////////////////////////////////////////////////*/

    function invariant_CanceledStreamsNonZeroWithdrawableAmounts() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            if (lockup.getStatus(streamId) == Lockup.Status.CANCELED) {
                assertGt(
                    lockup.withdrawableAmountOf(streamId),
                    0,
                    "Invariant violated: canceled stream has zero withdrawable amount"
                );
            }
        }
    }

    // solhint-disable max-line-length
    function invariant_ContractBalance() external {
        uint256 contractBalance = DEFAULT_ASSET.balanceOf(address(lockup));
        uint256 protocolRevenues = lockup.protocolRevenues(DEFAULT_ASSET);

        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        uint256 depositedAmountsSum;
        uint256 returnedAmountsSum;
        uint256 withdrawnAmountsSum;
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            depositedAmountsSum += uint256(lockup.getDepositedAmount(streamId));
            returnedAmountsSum += uint256(lockup.getReturnedAmount(streamId));
            withdrawnAmountsSum += uint256(lockup.getWithdrawnAmount(streamId));
        }

        assertGte(
            contractBalance,
            depositedAmountsSum + protocolRevenues - returnedAmountsSum - withdrawnAmountsSum,
            unicode"Invariant violated: contract balances < Σ deposited amounts + protocol revenues - Σ returned amounts - Σ withdrawn amounts"
        );
    }

    function invariant_DepositedAmountGteStreamedAmount() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            assertGte(
                lockup.getDepositedAmount(streamId),
                lockup.streamedAmountOf(streamId),
                "Invariant violated: deposited amount < streamed amount"
            );
        }
    }

    function invariant_DepositedAmountGteWithdrawableAmount() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            assertGte(
                lockup.getDepositedAmount(streamId),
                lockup.withdrawableAmountOf(streamId),
                "Invariant violated: deposited amount < withdrawable amount"
            );
        }
    }

    function invariant_DepositedAmountGteWithdrawnAmount() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            assertGte(
                lockup.getDepositedAmount(streamId),
                lockup.getWithdrawnAmount(streamId),
                "Invariant violated: deposited amount < withdrawn amount"
            );
        }
    }

    function invariant_EndTimeGtStartTime() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            assertGt(
                lockup.getEndTime(streamId), lockup.getStartTime(streamId), "Invariant violated: end time <= start time"
            );
        }
    }

    function invariant_NextStreamIdIncrement() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 nextStreamId = lockup.nextStreamId();
            assertEq(nextStreamId, lastStreamId + 1, "Invariant violated: the next stream id not bumped");
        }
    }

    function invariant_StreamedAmountGteWithdrawableAmount() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            assertGte(
                lockup.streamedAmountOf(streamId),
                lockup.withdrawableAmountOf(streamId),
                "Invariant violated: streamed amount < withdrawable amount"
            );
        }
    }

    function invariant_StreamedAmountGteWithdrawnAmount() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            assertGte(
                lockup.streamedAmountOf(streamId),
                lockup.getWithdrawnAmount(streamId),
                "Invariant violated: streamed amount < withdrawn amount"
            );
        }
    }
}
