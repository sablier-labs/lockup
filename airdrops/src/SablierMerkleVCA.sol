// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ud, UD60x18, ZERO } from "@prb/math/src/UD60x18.sol";

import { SablierMerkleBase } from "./abstracts/SablierMerkleBase.sol";
import { ISablierMerkleVCA } from "./interfaces/ISablierMerkleVCA.sol";
import { Errors } from "./libraries/Errors.sol";
import { MerkleVCA } from "./types/DataTypes.sol";

/*

███████╗ █████╗ ██████╗ ██╗     ██╗███████╗██████╗
██╔════╝██╔══██╗██╔══██╗██║     ██║██╔════╝██╔══██╗
███████╗███████║██████╔╝██║     ██║█████╗  ██████╔╝
╚════██║██╔══██║██╔══██╗██║     ██║██╔══╝  ██╔══██╗
███████║██║  ██║██████╔╝███████╗██║███████╗██║  ██║
╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝

███╗   ███╗███████╗██████╗ ██╗  ██╗██╗     ███████╗    ██╗   ██╗ ██████╗ █████╗
████╗ ████║██╔════╝██╔══██╗██║ ██╔╝██║     ██╔════╝    ██║   ██║██╔════╝██╔══██╗
██╔████╔██║█████╗  ██████╔╝█████╔╝ ██║     █████╗      ██║   ██║██║     ███████║
██║╚██╔╝██║██╔══╝  ██╔══██╗██╔═██╗ ██║     ██╔══╝      ╚██╗ ██╔╝██║     ██╔══██║
██║ ╚═╝ ██║███████╗██║  ██║██║  ██╗███████╗███████╗     ╚████╔╝ ╚██████╗██║  ██║
╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝      ╚═══╝   ╚═════╝╚═╝  ╚═╝

*/

/// @title SablierMerkleVCA
/// @notice See the documentation in {ISablierMerkleVCA}.
contract SablierMerkleVCA is
    ISablierMerkleVCA, // 2 inherited components
    SablierMerkleBase // 3 inherited components
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleVCA
    uint256 public immutable override AGGREGATE_AMOUNT;

    /// @inheritdoc ISablierMerkleVCA
    UD60x18 public immutable override UNLOCK_PERCENTAGE;

    /// @inheritdoc ISablierMerkleVCA
    uint40 public immutable override VESTING_END_TIME;

    /// @inheritdoc ISablierMerkleVCA
    uint40 public immutable override VESTING_START_TIME;

    /// @inheritdoc ISablierMerkleVCA
    bool public override isRedistributionEnabled;

    /// @inheritdoc ISablierMerkleVCA
    uint256 public override totalForgoneAmount;

    /// @dev Tracks the full amount allocated to the recipients who claimed before the vesting end time.
    uint256 private _fullAmountAllocatedToEarlyClaimers;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Constructs the contract by initializing the immutable state variables.
    constructor(
        MerkleVCA.ConstructorParams memory params,
        address campaignCreator,
        address comptroller
    )
        SablierMerkleBase(
            campaignCreator,
            params.campaignName,
            params.campaignStartTime,
            comptroller,
            params.expiration,
            params.initialAdmin,
            params.ipfsCID,
            params.merkleRoot,
            params.token
        )
    {
        // Effect: set the immutable variables.
        AGGREGATE_AMOUNT = params.aggregateAmount;
        UNLOCK_PERCENTAGE = params.unlockPercentage;
        VESTING_END_TIME = params.vestingEndTime;
        VESTING_START_TIME = params.vestingStartTime;

        // Effect: enable redistribution if true.
        if (params.enableRedistribution) {
            isRedistributionEnabled = true;
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleVCA
    function calculateClaimAmount(uint128 fullAmount, uint40 claimTime) external view override returns (uint128) {
        // Zero is a sentinel value for `block.timestamp`.
        if (claimTime == 0) {
            claimTime = uint40(block.timestamp);
        }

        // Calculate and return the claim amount.
        return _calculateClaimAmount(fullAmount, claimTime);
    }

    /// @inheritdoc ISablierMerkleVCA
    function calculateForgoneAmount(uint128 fullAmount, uint40 claimTime) external view override returns (uint128) {
        // Zero is a sentinel value for `block.timestamp`.
        if (claimTime == 0) {
            claimTime = uint40(block.timestamp);
        }

        // Check: the claim time is not less than the vesting start time.
        if (claimTime < VESTING_START_TIME) {
            revert Errors.SablierMerkleVCA_VestingNotStarted({
                claimTime: claimTime,
                vestingStartTime: VESTING_START_TIME
            });
        }

        return fullAmount - _calculateClaimAmount(fullAmount, claimTime);
    }

    /// @inheritdoc ISablierMerkleVCA
    function calculateRedistributionRewardsPerToken() external view override returns (UD60x18) {
        // Check: redistribution is enabled.
        if (!isRedistributionEnabled) {
            revert Errors.SablierMerkleVCA_RedistributionNotEnabled();
        }

        // Calculate and return the redistribution rewards per token.
        return _calculateRedistributionRewardsPerToken();
    }

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleVCA
    function claimTo(
        uint256 index,
        address to,
        uint128 fullAmount,
        bytes32[] calldata merkleProof
    )
        external
        payable
        override
        notZeroAddress(to)
    {
        // Check, Effect and Interaction: Pre-process the claim parameters on behalf of `msg.sender`.
        _preProcessClaim({ index: index, recipient: msg.sender, amount: fullAmount, merkleProof: merkleProof });

        // Check, Effect and Interaction: Post-process the claim parameters on behalf of `msg.sender`.
        _postProcessClaim({ index: index, recipient: msg.sender, to: to, fullAmount: fullAmount, viaSig: false });
    }

    /// @inheritdoc ISablierMerkleVCA
    function claimViaSig(
        uint256 index,
        address recipient,
        address to,
        uint128 fullAmount,
        uint40 validFrom,
        bytes32[] calldata merkleProof,
        bytes calldata signature
    )
        external
        payable
        override
        notZeroAddress(to)
    {
        // Check: the signature is valid and the recovered signer matches the recipient.
        _checkSignature(index, recipient, to, fullAmount, validFrom, signature);

        // Check, Effect and Interaction: Pre-process the claim parameters on behalf of the recipient.
        _preProcessClaim(index, recipient, fullAmount, merkleProof);

        // Check, Effect and Interaction: Post-process the claim parameters on behalf of the recipient.
        _postProcessClaim({ index: index, recipient: recipient, to: to, fullAmount: fullAmount, viaSig: true });
    }

    /// @inheritdoc ISablierMerkleVCA
    function enableRedistribution() external override onlyAdmin {
        // Check: the redistribution is not already enabled.
        if (isRedistributionEnabled) {
            revert Errors.SablierMerkleVCA_RedistributionAlreadyEnabled();
        }

        // Effect: set the value to true.
        isRedistributionEnabled = true;

        // Log the event.
        emit RedistributionEnabled();
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PRIVATE READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _calculateClaimAmount(uint128 fullAmount, uint40 claimTime) private view returns (uint128) {
        // If the claim time is less than the vesting start time, there's nothing to calculate, so we return zero.
        if (claimTime < VESTING_START_TIME) {
            return 0;
        }

        // If the vesting period has ended, the full amount can be claimed.
        if (claimTime >= VESTING_END_TIME) {
            return fullAmount;
        }
        // Otherwise, calculate the claim amount based on the elapsed time.
        else {
            // Calculate the initial unlock amount.
            uint128 unlockAmount = ud(fullAmount).mul(UNLOCK_PERCENTAGE).intoUint128();

            uint40 elapsedTime;
            uint40 totalDuration;

            // Safe because overflows are prevented by the checks above.
            unchecked {
                elapsedTime = claimTime - VESTING_START_TIME;
                totalDuration = VESTING_END_TIME - VESTING_START_TIME;
            }

            // Safe to cast because the result is less than `remainderAmount`, which fits within `uint128`.
            uint256 remainderAmount = uint256(fullAmount - unlockAmount);
            uint128 vestedAmount = uint128((remainderAmount * elapsedTime) / totalDuration);
            return unlockAmount + vestedAmount;
        }
    }

    /// @notice Calculates the redistribution rewards per token.
    function _calculateRedistributionRewardsPerToken() private view returns (UD60x18 rewardsPerToken) {
        // Return zero if amount allocated to early claimers is less than aggregate amount.
        if (AGGREGATE_AMOUNT <= _fullAmountAllocatedToEarlyClaimers) {
            return ZERO;
        }

        // Calculate the total amount allocated to the remaining claimers.
        uint256 fullAmountAllocatedToRemainingClaimers;
        unchecked {
            // Safe to use unchecked because it cannot overflow due to above check.
            fullAmountAllocatedToRemainingClaimers = AGGREGATE_AMOUNT - _fullAmountAllocatedToEarlyClaimers;
        }

        // Get the token balance of the contract.
        uint256 actualTokenBalance = TOKEN.balanceOf(address(this));

        // Calculate the balance that is expected for the correct distribution of tokens.
        uint256 expectedTokenBalance = totalForgoneAmount + fullAmountAllocatedToRemainingClaimers;

        // For the correct distribution of tokens, the token balance must not be less than the sum of the total amount
        // allocated to the remaining claimers and the total rewards to distribute. No rewards will be distributed if
        // the contract has insufficient balance.
        if (actualTokenBalance < expectedTokenBalance) {
            return ZERO;
        }

        // Calculate the rewards per token.
        rewardsPerToken = ud(totalForgoneAmount).div(ud(fullAmountAllocatedToRemainingClaimers));
    }

    /*//////////////////////////////////////////////////////////////////////////
                          PRIVATE STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Post-processes the claim execution by handling the tokens transfer and emitting an event.
    function _postProcessClaim(uint256 index, address recipient, address to, uint128 fullAmount, bool viaSig) private {
        // Calculate the claim amount.
        uint128 claimAmount = _calculateClaimAmount(fullAmount, uint40(block.timestamp));

        // Check: the claim amount is not zero.
        if (claimAmount == 0) {
            revert Errors.SablierMerkleVCA_ClaimAmountZero(recipient);
        }

        uint128 forgoneAmount;
        uint256 rewardAmount;
        uint256 transferAmount = claimAmount;

        // Effect: update the total forgone amount and the total amount claimed by early claimers.
        if (claimAmount < fullAmount) {
            unchecked {
                forgoneAmount = fullAmount - claimAmount;
                totalForgoneAmount += forgoneAmount;
                _fullAmountAllocatedToEarlyClaimers += fullAmount;
            }
        } else {
            // Although the claim amount should never exceed the full amount, this assertion prevents excessive claiming
            // in case of a calculation error.
            assert(claimAmount == fullAmount);

            // If redistribution is enabled and there are forgone tokens, calculate and transfer the reward amount.
            if (isRedistributionEnabled && totalForgoneAmount > 0) {
                // Calculate the reward amount proportional to the full amount.
                UD60x18 rewardsPerToken = _calculateRedistributionRewardsPerToken();

                if (rewardsPerToken != ZERO) {
                    // Calculate the reward amount proportional to the full amount.
                    rewardAmount = ud(fullAmount).mul(rewardsPerToken).intoUint128();

                    // Update the transfer amount.
                    transferAmount = claimAmount + rewardAmount;

                    // Log the event.
                    emit RedistributionReward(index, recipient, rewardAmount, to);
                }
            }
        }

        // Interaction: transfer the tokens to the recipient.
        TOKEN.safeTransfer({ to: to, value: transferAmount });

        // Emit claim event.
        emit ClaimVCA(index, recipient, claimAmount, forgoneAmount, to, viaSig);
    }
}
