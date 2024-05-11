// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { UD60x18, ud } from "@prb/math/src/UD60x18.sol";
import { ISablierV2Lockup } from "../src/interfaces/ISablierV2Lockup.sol";

import { Base_Test } from "../test/Base.t.sol";

/// @notice Benchmark contract with common logic needed by all tests.
abstract contract Benchmark_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint128 internal immutable AMOUNT_PER_SEGMENT = 100e18;
    uint128 internal immutable AMOUNT_PER_TRANCHE = 100e18;
    uint256 internal immutable STREAM_1 = 50;
    uint256 internal immutable STREAM_2 = 51;
    uint256 internal immutable STREAM_3 = 52;
    uint256 internal immutable STREAM_4 = 53;
    uint256 internal immutable STREAM_5 = 54;
    uint256 internal immutable STREAM_6 = 55;
    uint256 internal immutable STREAM_7 = 56;

    /// @dev The directory where the benchmark files are stored.
    string internal benchmarkResults = "benchmark/results/";

    /// @dev The path to the file where the benchmark results are stored.
    string internal benchmarkResultsFile;

    string internal contentToAppend;

    ISablierV2Lockup internal lockup;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();

        deal({ token: address(dai), to: users.sender, give: type(uint256).max });
        resetPrank({ msgSender: users.sender });

        // Create the first streams in each Lockup contract to initialize all the variables.
        _createFewStreams();
    }

    /*//////////////////////////////////////////////////////////////////////////
                    GAS BENCHMARKS FOR COMMON IMPLEMENTATIONS
    //////////////////////////////////////////////////////////////////////////*/

    function gasBurn() internal {
        // Set the caller to the Recipient for `burn` and change timestamp to the end time.
        resetPrank({ msgSender: users.recipient });

        vm.warp({ newTimestamp: defaults.END_TIME() });

        lockup.withdrawMax(STREAM_1, users.recipient);

        uint256 beforeGas = gasleft();
        lockup.burn(STREAM_1);

        string memory gasUsed = vm.toString(beforeGas - gasleft());
        contentToAppend = string.concat("| `burn` | ", gasUsed, " |");

        // Append the content to the file.
        _appendToFile(benchmarkResultsFile, contentToAppend);
    }

    function gasCancel() internal {
        // Set the caller to the Sender for the next calls and change timestamp to before end time
        resetPrank({ msgSender: users.sender });

        uint256 beforeGas = gasleft();
        lockup.cancel(STREAM_2);

        string memory gasUsed = vm.toString(beforeGas - gasleft());

        contentToAppend = string.concat("| `cancel` | ", gasUsed, " |");

        // Append the content to the file.
        _appendToFile(benchmarkResultsFile, contentToAppend);
    }

    function gasRenounce() internal {
        // Set the caller to the Sender for the next calls and change timestamp to before end time.
        resetPrank({ msgSender: users.sender });

        uint256 beforeGas = gasleft();
        lockup.renounce(STREAM_3);

        string memory gasUsed = vm.toString(beforeGas - gasleft());
        contentToAppend = string.concat("| `renounce` | ", gasUsed, " |");

        // Append the content to the file.
        _appendToFile(benchmarkResultsFile, contentToAppend);
    }

    function gasWithdraw_ByRecipient(uint256 streamId1, uint256 streamId2, string memory extraInfo) internal {
        gasWithdraw_AfterEndTime(streamId1, users.recipient, users.alice, extraInfo);
        gasWithdraw_BeforeEndTime(streamId2, users.recipient, users.alice, extraInfo);
    }

    function gasWithdraw_ByAnyone(uint256 streamId1, uint256 streamId2, string memory extraInfo) internal {
        gasWithdraw_AfterEndTime(streamId1, users.sender, users.recipient, extraInfo);
        gasWithdraw_BeforeEndTime(streamId2, users.sender, users.recipient, extraInfo);
    }

    function gasWithdraw_AfterEndTime(uint256 streamId, address caller, address to, string memory extraInfo) internal {
        extraInfo = string.concat(extraInfo, " (After End Time)");
        uint256 warpTime = lockup.getEndTime(streamId) + 1;
        vm.warp({ newTimestamp: warpTime });
        gasWithdraw(streamId, caller, to, extraInfo);
    }

    function gasWithdraw_BeforeEndTime(
        uint256 streamId,
        address caller,
        address to,
        string memory extraInfo
    )
        internal
    {
        extraInfo = string.concat(extraInfo, " (Before End Time)");
        uint256 warpTime = lockup.getEndTime(streamId) - 1;
        vm.warp({ newTimestamp: warpTime });
        gasWithdraw(streamId, caller, to, extraInfo);
    }

    function gasWithdraw(uint256 streamId, address caller, address to, string memory extraInfo) internal {
        resetPrank({ msgSender: caller });

        uint128 withdrawAmount = lockup.withdrawableAmountOf(streamId);

        uint256 beforeGas = gasleft();
        lockup.withdraw(streamId, to, withdrawAmount);
        string memory gasUsed = vm.toString(beforeGas - gasleft());

        bool isCallerRecipient = caller == users.recipient;
        string memory s = isCallerRecipient
            ? string.concat("| `withdraw` ", extraInfo, " (by Recipient) | ")
            : string.concat("| `withdraw` ", extraInfo, " (by Anyone) | ");

        contentToAppend = string.concat(s, gasUsed, " |");

        // Append the data to the file
        _appendToFile(benchmarkResultsFile, contentToAppend);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Append a line to the file at given path.
    function _appendToFile(string memory path, string memory line) internal {
        vm.writeLine({ path: path, data: line });
    }

    // /// @dev Calculates the total amount to be deposited in the stream, by accounting for the broker fee.
    // function _calculateTotalAmount(uint128 depositAmount) internal view returns (uint128) {
    //     return _calculateTotalAmount(depositAmount, defaults.BROKER_FEE());
    // }

    /// @dev Calculates the total amount to be deposited in the stream, by accounting for the broker fee.
    function _calculateTotalAmount(uint128 depositAmount, UD60x18 brokerFee) internal pure returns (uint128) {
        UD60x18 factor = ud(1e18);
        UD60x18 totalAmount = ud(depositAmount).mul(factor).div(factor.sub(brokerFee));
        return totalAmount.intoUint128();
    }

    function _createFewStreams() internal {
        for (uint128 i = 0; i < 100; ++i) {
            lockupDynamic.createWithTimestamps(defaults.createWithTimestampsLD());
            lockupLinear.createWithTimestamps(defaults.createWithTimestampsLL());
            lockupTranched.createWithTimestamps(defaults.createWithTimestampsLT());
        }
    }
}
