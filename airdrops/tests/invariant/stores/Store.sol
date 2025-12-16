// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev Storage variables needed for handlers.
contract Store {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev List of merkle campaigns created during the test.
    address[] internal campaigns;

    /// @dev List of addresses to be excluded from being fuzzed as `msg.sender`.
    address[] internal excludedAddresses;

    /// @dev Track redistribution rewards per 1e18 for VCA campaign before a claim is made.
    uint256 public previousVcaRedistributionRewardsPer1e18;

    /// @dev Track total forgone amounts for VCA campaign before a claim is made.
    uint256 public previousVcaTotalForgoneAmount;

    IERC20[] public tokens;

    /// @dev Tracks VCA campaign.
    address public vcaCampaign;

    /// @dev Track total full amounts requested by users for VCA campaign.
    uint256 public vcaTotalFullAmountRequested;

    /// @dev Track total rewards distributed for VCA campaign.
    uint256 public vcaTotalRewardsDistributed;

    /// @dev Track claimed indexes for each campaign.
    mapping(address campaign => uint256[] indexes) public claimedIndexes;

    /// @dev Track min fee in USD for each campaign.
    mapping(address campaign => uint256 fee) public minFeeUSD;

    /// @dev Track total claimed amounts from each campaign.
    mapping(address campaign => uint256 amount) public totalClaimAmount;

    /// @dev Track total clawback amounts from each campaign.
    mapping(address campaign => uint256 amount) public totalClawbackAmount;

    /// @dev Track total deposit amounts into each campaign.
    mapping(address campaign => uint256 amount) public totalDepositAmount;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20[] memory tokens_) {
        for (uint256 i = 0; i < tokens_.length; ++i) {
            tokens.push(tokens_[i]);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function addCampaign(address campaign) public {
        campaigns.push(campaign);
    }

    function addClaimedIndex(address campaign, uint256 index) public {
        claimedIndexes[campaign].push(index);
    }

    function addExcludeAddresses(address[] memory addresses) public {
        for (uint256 i = 0; i < addresses.length; ++i) {
            excludedAddresses.push(addresses[i]);
        }
    }

    function getCampaigns() public view returns (address[] memory) {
        return campaigns;
    }

    function getClaimedIndexes(address campaign) public view returns (uint256[] memory) {
        return claimedIndexes[campaign];
    }

    function getExcludedAddresses() public view returns (address[] memory) {
        return excludedAddresses;
    }

    function getTokens() public view returns (IERC20[] memory) {
        return tokens;
    }

    function updateMinFeeUSD(address campaign, uint256 feeUSD) public {
        minFeeUSD[campaign] = feeUSD;
    }

    function updatePreviousVcaRedistributionRewardsPer1e18(uint256 rewardsPer1e18) public {
        previousVcaRedistributionRewardsPer1e18 = rewardsPer1e18;
    }

    function updatePreviousVcaTotalForgoneAmount(uint256 amount) public {
        previousVcaTotalForgoneAmount += amount;
    }

    function updateTotalClaimAmount(address campaign, uint256 amount) public {
        totalClaimAmount[campaign] += amount;
    }

    function updateTotalClawbackAmount(address campaign, uint256 amount) public {
        totalClawbackAmount[campaign] += amount;
    }

    function updateTotalDepositAmount(address campaign, uint256 amount) public {
        totalDepositAmount[campaign] += amount;
    }

    function updateVcaCampaign(address campaign) public {
        vcaCampaign = campaign;
    }

    function updateVcaTotalFullAmountRequested(uint256 amount) public {
        vcaTotalFullAmountRequested += amount;
    }

    function updateTotalRewardsDistributed(uint256 amount) public {
        vcaTotalRewardsDistributed += amount;
    }
}
