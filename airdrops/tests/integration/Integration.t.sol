// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ISablierMerkleExecute } from "src/interfaces/ISablierMerkleExecute.sol";
import { ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";
import { ISablierMerkleLL } from "src/interfaces/ISablierMerkleLL.sol";
import { ISablierMerkleLT } from "src/interfaces/ISablierMerkleLT.sol";
import { ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";
import { MerkleExecute, MerkleInstant, MerkleLL, MerkleLT, MerkleVCA } from "src/types/DataTypes.sol";

import { Base_Test } from "../Base.t.sol";

abstract contract Integration_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Type of the campaign, e.g., "instant", "ll", "lt", or "vca".
    string internal campaignType;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        // Make campaign creator the caller.
        setMsgSender(users.campaignCreator);

        // Create the default Merkle contracts and fund them.
        merkleExecute = createMerkleExecute();
        merkleInstant = createMerkleInstant();
        merkleLL = createMerkleLL();
        merkleLT = createMerkleLT();
        merkleVCA = createMerkleVCA();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   MERKLE-CLAIMS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Claim to `users.recipient` address using {claim} function.
    function claim() internal virtual {
        claim({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            recipient: users.recipient,
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof()
        });
    }

    function claim(
        uint256 msgValue,
        uint256 index,
        address recipient,
        uint128 amount,
        bytes32[] memory merkleProof
    )
        internal
        virtual
    {
        if (claimIfMerkleExecute(msgValue, index, amount, merkleProof)) return;
        ISablierMerkleInstant(address(merkleBase)).claim{ value: msgValue }(index, recipient, amount, merkleProof);
    }

    /// @dev Claim to Eve address on behalf of `users.recipient` using {claimTo} function.
    function claimTo() internal virtual {
        claimTo({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            to: users.eve,
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof()
        });
    }

    function claimTo(
        uint256 msgValue,
        uint256 index,
        address to,
        uint128 amount,
        bytes32[] memory merkleProof
    )
        internal
    {
        if (claimIfMerkleExecute(msgValue, index, amount, merkleProof)) return;
        ISablierMerkleInstant(address(merkleBase)).claimTo{ value: msgValue }(index, to, amount, merkleProof);
    }

    /// @dev Claim using default values for {claimViaSig} function.
    function claimViaSig() internal {
        claimViaSig(users.recipient, CLAIM_AMOUNT);
    }

    /// @dev Claim using recipient and amount parameters for {claimViaSig} function.
    function claimViaSig(address recipient, uint128 amount) internal {
        claimViaSig({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(recipient),
            recipient: recipient,
            to: users.eve,
            amount: amount,
            validFrom: VALID_FROM,
            merkleProof: getMerkleProof(recipient),
            signature: generateSignature(recipient, address(merkleBase))
        });
    }

    function claimViaSig(
        uint256 msgValue,
        uint256 index,
        address recipient,
        address to,
        uint128 amount,
        uint40 validFrom,
        bytes32[] memory merkleProof,
        bytes memory signature
    )
        internal
    {
        // Using `ISablierMerkleInstant` interface over `merkleBase` works for all Merkle contracts due to similarity in
        // claimViaSig function signature.
        address campaignAddr = address(merkleBase);
        ISablierMerkleInstant(campaignAddr).claimViaSig{ value: msgValue }(
            index, recipient, to, amount, validFrom, merkleProof, signature
        );
    }

    /// @dev Generate the EIP-712 signature to claim with default parameters.
    function generateSignature(address user, address merkleContract) internal view returns (bytes memory) {
        return generateEIP712Signature({
            signerPrivateKey: recipientPrivateKey,
            merkleContract: merkleContract,
            index: getIndexInMerkleTree(user),
            recipient: user,
            to: users.eve,
            amount: CLAIM_AMOUNT,
            validFrom: VALID_FROM
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-EXECUTE
    //////////////////////////////////////////////////////////////////////////*/

    function createMerkleExecute() internal returns (ISablierMerkleExecute) {
        return createMerkleExecute(merkleExecuteConstructorParams());
    }

    function createMerkleExecute(MerkleExecute.ConstructorParams memory params)
        internal
        returns (ISablierMerkleExecute campaignAddress)
    {
        campaignAddress = factoryMerkleExecute.createMerkleExecute(params, AGGREGATE_AMOUNT, RECIPIENT_COUNT);

        // Fund the campaign.
        fundCampaignWithDai(address(campaignAddress));
    }

    /// @dev Claim and execute using default values.
    function claimAndExecute() internal {
        claimAndExecute({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof(),
            arguments: abi.encode(CLAIM_AMOUNT)
        });
    }

    function claimAndExecute(
        uint256 msgValue,
        uint256 index,
        uint128 amount,
        bytes32[] memory merkleProof,
        bytes memory arguments
    )
        internal
    {
        merkleExecute.claimAndExecute{ value: msgValue }(index, amount, merkleProof, arguments);
    }

    /// @dev Helper to call claimAndExecute for MerkleExecute campaigns.
    function claimIfMerkleExecute() internal returns (bool) {
        if (Strings.equal(campaignType, "execute")) {
            claimAndExecute();
            return true;
        }
        return false;
    }

    function claimIfMerkleExecute(
        uint256 msgValue,
        uint256 index,
        uint128 amount,
        bytes32[] memory merkleProof
    )
        internal
        returns (bool)
    {
        if (Strings.equal(campaignType, "execute")) {
            ISablierMerkleExecute(address(merkleBase)).claimAndExecute{ value: msgValue }(
                index, amount, merkleProof, abi.encode(amount)
            );
            return true;
        }
        return false;
    }
    
    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-INSTANT
    //////////////////////////////////////////////////////////////////////////*/

    function createMerkleInstant() internal returns (ISablierMerkleInstant) {
        return createMerkleInstant(merkleInstantConstructorParams());
    }

    function createMerkleInstant(MerkleInstant.ConstructorParams memory params)
        internal
        returns (ISablierMerkleInstant campaignAddress)
    {
        campaignAddress = factoryMerkleInstant.createMerkleInstant(params, AGGREGATE_AMOUNT, RECIPIENT_COUNT);

        // Fund the campaign.
        fundCampaignWithDai(address(campaignAddress));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-LL
    //////////////////////////////////////////////////////////////////////////*/

    function createMerkleLL() internal returns (ISablierMerkleLL) {
        return createMerkleLL(merkleLLConstructorParams());
    }

    function createMerkleLL(MerkleLL.ConstructorParams memory params)
        internal
        returns (ISablierMerkleLL campaignAddress)
    {
        campaignAddress = factoryMerkleLL.createMerkleLL(params, AGGREGATE_AMOUNT, RECIPIENT_COUNT);

        // Fund the campaign.
        fundCampaignWithDai(address(campaignAddress));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-LT
    //////////////////////////////////////////////////////////////////////////*/

    function createMerkleLT() internal returns (ISablierMerkleLT) {
        return createMerkleLT(merkleLTConstructorParams());
    }

    function createMerkleLT(MerkleLT.ConstructorParams memory params)
        internal
        returns (ISablierMerkleLT campaignAddress)
    {
        campaignAddress = factoryMerkleLT.createMerkleLT(params, AGGREGATE_AMOUNT, RECIPIENT_COUNT);

        // Fund the campaign.
        fundCampaignWithDai(address(campaignAddress));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-VCA
    //////////////////////////////////////////////////////////////////////////*/

    function createMerkleVCA() internal returns (ISablierMerkleVCA) {
        return createMerkleVCA(merkleVCAConstructorParams());
    }

    function createMerkleVCA(MerkleVCA.ConstructorParams memory params)
        internal
        returns (ISablierMerkleVCA campaignAddress)
    {
        campaignAddress = factoryMerkleVCA.createMerkleVCA(params, RECIPIENT_COUNT);

        // Fund the campaign.
        fundCampaignWithDai(address(campaignAddress));
    }
}
