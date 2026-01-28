// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { UD60x18, uUNIT } from "@prb/math/src/UD60x18.sol";
import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";

import { SablierFactoryMerkleBase } from "./abstracts/SablierFactoryMerkleBase.sol";
import { ISablierFactoryMerkleVCA } from "./interfaces/ISablierFactoryMerkleVCA.sol";
import { ISablierMerkleVCA } from "./interfaces/ISablierMerkleVCA.sol";
import { Errors } from "./libraries/Errors.sol";
import { SablierMerkleVCA } from "./SablierMerkleVCA.sol";
import { MerkleVCA } from "./types/DataTypes.sol";

/*

███████╗ █████╗ ██████╗ ██╗     ██╗███████╗██████╗     ███████╗ █████╗  ██████╗████████╗ ██████╗ ██████╗ ██╗   ██╗
██╔════╝██╔══██╗██╔══██╗██║     ██║██╔════╝██╔══██╗    ██╔════╝██╔══██╗██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗╚██╗ ██╔╝
███████╗███████║██████╔╝██║     ██║█████╗  ██████╔╝    █████╗  ███████║██║        ██║   ██║   ██║██████╔╝ ╚████╔╝
╚════██║██╔══██║██╔══██╗██║     ██║██╔══╝  ██╔══██╗    ██╔══╝  ██╔══██║██║        ██║   ██║   ██║██╔══██╗  ╚██╔╝
███████║██║  ██║██████╔╝███████╗██║███████╗██║  ██║    ██║     ██║  ██║╚██████╗   ██║   ╚██████╔╝██║  ██║   ██║
╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝   ╚═╝

███╗   ███╗███████╗██████╗ ██╗  ██╗██╗     ███████╗    ██╗   ██╗ ██████╗ █████╗
████╗ ████║██╔════╝██╔══██╗██║ ██╔╝██║     ██╔════╝    ██║   ██║██╔════╝██╔══██╗
██╔████╔██║█████╗  ██████╔╝█████╔╝ ██║     █████╗      ██║   ██║██║     ███████║
██║╚██╔╝██║██╔══╝  ██╔══██╗██╔═██╗ ██║     ██╔══╝      ╚██╗ ██╔╝██║     ██╔══██║
██║ ╚═╝ ██║███████╗██║  ██║██║  ██╗███████╗███████╗     ╚████╔╝ ╚██████╗██║  ██║
╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝      ╚═══╝   ╚═════╝╚═╝  ╚═╝

*/

/// @title SablierFactoryMerkleVCA
/// @notice See the documentation in {ISablierFactoryMerkleVCA}.
contract SablierFactoryMerkleVCA is ISablierFactoryMerkleVCA, SablierFactoryMerkleBase {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialAttestor The address of the initial attestor.
    /// @param initialComptroller The address of the initial comptroller contract.
    constructor(
        address initialAttestor,
        address initialComptroller
    )
        SablierFactoryMerkleBase(initialAttestor, initialComptroller)
    { }

    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierFactoryMerkleVCA
    function computeMerkleVCA(
        address campaignCreator,
        MerkleVCA.ConstructorParams calldata campaignParams
    )
        external
        view
        override
        returns (address merkleVCA)
    {
        // Check: validate the deployment parameters.
        _checkDeploymentParams(
            campaignParams.aggregateAmount,
            campaignParams.expiration,
            address(campaignParams.token),
            campaignParams.unlockPercentage,
            campaignParams.vestingEndTime,
            campaignParams.vestingStartTime
        );

        // Hash the parameters to generate a salt.
        bytes32 salt = keccak256(abi.encodePacked(campaignCreator, attestor, comptroller, abi.encode(campaignParams)));

        // Get the bytecode hash for the {SablierMerkleVCA} contract.
        bytes32 bytecodeHash = keccak256(
            abi.encodePacked(
                type(SablierMerkleVCA).creationCode,
                abi.encode(campaignParams, attestor, campaignCreator, address(comptroller))
            )
        );

        // Compute CREATE2 address using `keccak256(0xff + deployer + salt + bytecodeHash)`.
        merkleVCA =
            address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, bytecodeHash)))));
    }

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierFactoryMerkleVCA
    function createMerkleVCA(
        MerkleVCA.ConstructorParams calldata campaignParams,
        uint256 recipientCount
    )
        external
        returns (ISablierMerkleVCA merkleVCA)
    {
        // Check: validate the deployment parameters.
        _checkDeploymentParams(
            campaignParams.aggregateAmount,
            campaignParams.expiration,
            address(campaignParams.token),
            campaignParams.unlockPercentage,
            campaignParams.vestingEndTime,
            campaignParams.vestingStartTime
        );

        // Hash the parameters to generate a salt.
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, attestor, comptroller, abi.encode(campaignParams)));

        // Deploy the MerkleVCA contract with CREATE2.
        merkleVCA = new SablierMerkleVCA{ salt: salt }({
            campaignParams: campaignParams,
            attestor_: attestor,
            campaignCreator: msg.sender,
            comptroller: address(comptroller)
        });

        // Log the creation of the MerkleVCA contract, including some metadata that is not stored on-chain.
        emit CreateMerkleVCA({
            merkleVCA: merkleVCA,
            campaignParams: campaignParams,
            recipientCount: recipientCount,
            attestor: attestor,
            comptroller: address(comptroller),
            minFeeUSD: comptroller.getMinFeeUSDFor({
                protocol: ISablierComptroller.Protocol.Airdrops,
                user: msg.sender
            })
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PRIVATE READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Validate the deployment parameters.
    function _checkDeploymentParams(
        uint256 aggregateAmount,
        uint40 expiration,
        address token,
        UD60x18 unlockPercentage,
        uint40 vestingEndTime,
        uint40 vestingStartTime
    )
        private
        view
    {
        // Check: user-provided token is not the native token.
        _forbidNativeToken(token);

        // Check: aggregate amount is not zero.
        if (aggregateAmount == 0) {
            revert Errors.SablierFactoryMerkleVCA_AggregateAmountZero();
        }

        // Check: vesting start time is not zero.
        if (vestingStartTime == 0) {
            revert Errors.SablierFactoryMerkleVCA_StartTimeZero();
        }

        // Check: vesting end time is greater than the vesting start time.
        if (vestingEndTime <= vestingStartTime) {
            revert Errors.SablierFactoryMerkleVCA_VestingEndTimeNotGreaterThanVestingStartTime(
                vestingStartTime,
                vestingEndTime
            );
        }

        // Check: campaign expiration is not zero.
        if (expiration == 0) {
            revert Errors.SablierFactoryMerkleVCA_ExpirationTimeZero();
        }

        // Check: campaign expiration is at least 1 week later than the vesting end time.
        if (expiration < vestingEndTime + 1 weeks) {
            revert Errors.SablierFactoryMerkleVCA_ExpirationTooEarly(vestingEndTime, expiration);
        }

        // Check: unlock percentage is not greater than 100%.
        if (unlockPercentage.unwrap() > uUNIT) {
            revert Errors.SablierFactoryMerkleVCA_UnlockPercentageTooHigh(unlockPercentage);
        }
    }
}
