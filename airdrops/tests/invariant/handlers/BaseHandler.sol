// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { Store } from "./../stores/Store.sol";
import { Fuzzers } from "./../../utils/Fuzzers.sol";
import { LeafData } from "./../../utils/MerkleBuilder.sol";
import { Utils } from "./../../utils/Utils.sol";

/// @notice Base contract with common logic needed by all handler contracts.
abstract contract BaseHandler is Fuzzers, StdCheats, Utils {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal aggregateAmount;

    /// @dev The campaign token being used in the handler.
    IERC20 public campaignToken;

    address public comptroller;

    /// @dev Store leaves as `uint256` in storage so that we can use OpenZeppelin's {Arrays.findUpperBound}.
    uint256[] internal leaves;

    /// @dev Store leaves data in storage so that we can use it across functions.
    LeafData[] internal leavesData;

    /// @dev The total number of calls made to a specific function.
    mapping(string func => uint256 calls) public totalCalls;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierMerkleBase public campaign;

    Store public store;

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Simulates the passage of time.
    /// @param timeJump A fuzzed value for time warps.
    modifier adjustTimestamp(uint256 timeJump) {
        timeJump = bound(timeJump, 0, 30 days);
        skip(timeJump);
        _;
    }

    /// @dev Assume common deployment parameters.
    modifier assumeDeployParams(address campaignCreator, LeafData[] memory rawLeavesData) {
        // Deploy campaign only if it hasn't been deployed yet.
        vm.assume(totalCalls["deployCampaign"] == 0);

        // Ensure raw leaves data has more than one leaf.
        vm.assume(rawLeavesData.length > 1);

        // Ensure campaign creator is not the zero address.
        vm.assume(campaignCreator != address(0));

        _;
    }

    /// @dev Records a function call for instrumentation purposes.
    modifier instrument(string memory functionName) {
        _;
        totalCalls[functionName]++;
    }

    /// @dev Checks if the campaign has been deployed.
    modifier isDeployed() {
        vm.assume(totalCalls["deployCampaign"] == 1);
        _;
    }

    modifier useFuzzedToken(uint256 tokenIndex) {
        IERC20[] memory tokens = store.getTokens();
        tokenIndex = bound(tokenIndex, 0, tokens.length - 1);
        campaignToken = tokens[tokenIndex];
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(address comptroller_, Store store_) {
        comptroller = comptroller_;
        store = store_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     OVERRIDES
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev An internal claim function that must be overridden by the handler contract.
    function _claim(LeafData memory leafData, bytes32[] memory merkleProof) internal virtual;

    /// @dev An internal deploy campaign function that must be overridden by the handler contract.
    function _deployCampaign(address campaignCreator, bytes32 merkleRoot) internal virtual returns (address);

    /*//////////////////////////////////////////////////////////////////////////
                                 HANDLER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function claim(uint256 timeJump, uint256 pos) external adjustTimestamp(timeJump) instrument("claim") isDeployed {
        // Ensure the campaign has not expired.
        vm.assume(!campaign.hasExpired());

        // Bound pos within leaves array.
        pos = bound(pos, 0, leavesData.length - 1);

        // Get the leaf data at given position.
        LeafData memory leafData = leavesData[pos];

        // Ensure the leaf index is not claimed.
        vm.assume(!campaign.hasClaimed(leafData.index));

        // Ensure campaign is funded enough to claim the airdrop.
        vm.assume(leafData.amount <= campaignToken.balanceOf(address(campaign)));

        // Compute the Merkle proof.
        bytes32[] memory merkleProof = computeMerkleProof(leafData, leaves);

        // Change caller to the airdrop recipient.
        setMsgSender(leafData.recipient);

        // This must be overridden by the handler contract.
        _claim(leafData, merkleProof);

        // Add claimed index to store.
        store.addClaimedIndex(address(campaign), leafData.index);
    }

    function clawback(
        uint256 timeJump,
        uint128 amount
    )
        external
        adjustTimestamp(timeJump)
        instrument("clawback")
        isDeployed
    {
        // Ensure clawback conditions are met.
        bool noClaimMade = campaign.firstClaimTime() == 0;
        bool withinGracePeriod = getBlockTimestamp() <= campaign.firstClaimTime() + 7 days;
        bool hasExpired = campaign.hasExpired();
        vm.assume(noClaimMade || withinGracePeriod || hasExpired);

        // Bound amount to be less than the campaign balance.
        uint128 campaignBalance = uint128(campaignToken.balanceOf(address(campaign)));

        // If campaign is not funded, skip it.
        vm.assume(campaignBalance > 0);

        amount = boundUint128(amount, 1, campaignBalance);

        // Change caller to the campaign admin.
        setMsgSender(campaign.admin());

        // Clawback funds.
        campaign.clawback(address(this), amount);

        // Update clawback amount in store.
        store.updateTotalClawbackAmount(address(campaign), amount);
    }

    /// @notice Helper function to deploy a Merkle campaign with fuzzed leaves data and token.
    /// @dev This will be called only once.
    function deployCampaign(
        address campaignCreator,
        uint256 tokenIndex,
        LeafData[] memory rawLeavesData
    )
        external
        useFuzzedToken(tokenIndex)
        assumeDeployParams(campaignCreator, rawLeavesData)
        instrument("deployCampaign")
    {
        // Construct merkle root for the given tree leaves.
        bytes32 merkleRoot;
        (aggregateAmount, merkleRoot) =
            fuzzMerkleDataAndComputeRoot(leaves, leavesData, rawLeavesData, store.getExcludedAddresses());

        // This must be overridden by the handler contract.
        campaign = ISablierMerkleBase(_deployCampaign(campaignCreator, merkleRoot));

        // Add the campaign to store.
        store.addCampaign(address(campaign));
    }

    function fundCampaign(
        uint256 timeJump,
        uint256 amount
    )
        external
        adjustTimestamp(timeJump)
        instrument("fundCampaign")
        isDeployed
    {
        // Bound amount to be less than aggregate amount.
        amount = bound(amount, 1, aggregateAmount);

        // Fund the campaign using deal cheatcode.
        uint256 currentBalance = campaignToken.balanceOf(address(campaign));
        deal({ token: address(campaignToken), to: address(campaign), give: currentBalance + amount });

        // Update deposit amount in store.
        store.updateTotalDepositAmount(address(campaign), amount);
    }
}
