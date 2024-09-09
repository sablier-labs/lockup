// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IAdminable } from "../../core/interfaces/IAdminable.sol";
import { ISablierLockupLinear } from "../../core/interfaces/ISablierLockupLinear.sol";
import { ISablierLockupTranched } from "../../core/interfaces/ISablierLockupTranched.sol";

import { ISablierMerkleBase } from "../interfaces/ISablierMerkleBase.sol";
import { MerkleBase, MerkleLL, MerkleLT } from "../types/DataTypes.sol";
import { ISablierMerkleInstant } from "./ISablierMerkleInstant.sol";
import { ISablierMerkleLL } from "./ISablierMerkleLL.sol";
import { ISablierMerkleLT } from "./ISablierMerkleLT.sol";

/// @title ISablierMerkleFactory
/// @notice A contract that deploys Merkle Lockups and Merkle Instant campaigns. Both of these use Merkle proofs for
/// token distribution. Merkle Lockup enable Airstreams, a portmanteau of "airdrop" and "stream". This is an airdrop
/// model where the tokens are distributed over time, as opposed to all at once. On the other hand, Merkle Instant
/// enables instant airdrops where tokens are unlocked and distributed immediately. See the Sablier docs for more
/// guidance: https://docs.sablier.com
/// @dev Deploys Merkle Lockup and Merkle Instant campaigns with CREATE2.
interface ISablierMerkleFactory is IAdminable {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a {SablierMerkleInstant} campaign is created.
    event CreateMerkleInstant(
        ISablierMerkleInstant indexed merkleInstant,
        MerkleBase.ConstructorParams baseParams,
        uint256 aggregateAmount,
        uint256 recipientCount
    );

    /// @notice Emitted when a {SablierMerkleLL} campaign is created.
    event CreateMerkleLL(
        ISablierMerkleLL indexed merkleLL,
        MerkleBase.ConstructorParams baseParams,
        ISablierLockupLinear lockupLinear,
        bool cancelable,
        bool transferable,
        MerkleLL.Schedule schedule,
        uint256 aggregateAmount,
        uint256 recipientCount
    );

    /// @notice Emitted when a {SablierMerkleLT} campaign is created.
    event CreateMerkleLT(
        ISablierMerkleLT indexed merkleLT,
        MerkleBase.ConstructorParams baseParams,
        ISablierLockupTranched lockupTranched,
        bool cancelable,
        bool transferable,
        uint40 streamStartTime,
        MerkleLT.TrancheWithPercentage[] tranchesWithPercentages,
        uint256 totalDuration,
        uint256 aggregateAmount,
        uint256 recipientCount
    );

    /// @notice Emitted when the Sablier fee is set by the admin.
    event SetSablierFee(address indexed admin, uint256 sablierFee);

    /// @notice Emitted when the sablier fees are claimed by the sablier admin.
    event WithdrawSablierFees(address indexed admin, address indexed to, uint256 sablierFees);

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Verifies if the sum of percentages in `tranches` equals 100% , i.e. 1e18.
    /// @dev Reverts if the sum of percentages overflows.
    /// @param tranches The tranches with their respective unlock percentages.
    /// @return result True if the sum of percentages equals 100%, otherwise false.
    function isPercentagesSum100(MerkleLT.TrancheWithPercentage[] calldata tranches)
        external
        pure
        returns (bool result);

    /// @notice Retrieves the sablier fee required to claim an airstream.
    /// @dev A minimum of this fee must be paid in ETH during `claim`.
    function sablierFee() external view returns (uint256);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a new MerkleInstant campaign for instant distribution of assets.
    /// @dev Emits a {CreateMerkleInstant} event.
    /// @param baseParams Struct encapsulating the {SablierMerkleBase} parameters, which are documented in
    /// {DataTypes}.
    /// @param aggregateAmount The total amount of ERC-20 assets to be distributed to all recipients.
    /// @param recipientCount The total number of recipients who are eligible to claim.
    /// @return merkleInstant The address of the newly created MerkleInstant contract.
    function createMerkleInstant(
        MerkleBase.ConstructorParams memory baseParams,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        returns (ISablierMerkleInstant merkleInstant);

    /// @notice Creates a new Merkle Lockup campaign with a LockupLinear distribution.
    /// @dev Emits a {CreateMerkleLL} event.
    /// @param baseParams Struct encapsulating the {SablierMerkleBase} parameters, which are documented in
    /// {DataTypes}.
    /// @param lockupLinear The address of the {SablierLockupLinear} contract.
    /// @param cancelable Indicates if the stream will be cancelable after claiming.
    /// @param transferable Indicates if the stream will be transferable after claiming.
    /// @param schedule The time variables to construct the stream timestamps.
    /// @param aggregateAmount The total amount of ERC-20 assets to be distributed to all recipients.
    /// @param recipientCount The total number of recipients who are eligible to claim.
    /// @return merkleLL The address of the newly created Merkle Lockup contract.
    function createMerkleLL(
        MerkleBase.ConstructorParams memory baseParams,
        ISablierLockupLinear lockupLinear,
        bool cancelable,
        bool transferable,
        MerkleLL.Schedule memory schedule,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        returns (ISablierMerkleLL merkleLL);

    /// @notice Creates a new Merkle Lockup campaign with a LockupTranched distribution.
    /// @dev Emits a {CreateMerkleLT} event.
    ///
    /// @param baseParams Struct encapsulating the {SablierMerkleBase} parameters, which are documented in
    /// {DataTypes}.
    /// @param lockupTranched The address of the {SablierLockupTranched} contract.
    /// @param cancelable Indicates if the stream will be cancelable after claiming.
    /// @param transferable Indicates if the stream will be transferable after claiming.
    /// @param streamStartTime The start time of the streams created through `claim`.
    /// @param tranchesWithPercentages The tranches with their respective unlock percentages.
    /// @param aggregateAmount The total amount of ERC-20 assets to be distributed to all recipients.
    /// @param recipientCount The total number of recipients who are eligible to claim.
    /// @return merkleLT The address of the newly created Merkle Lockup contract.
    function createMerkleLT(
        MerkleBase.ConstructorParams memory baseParams,
        ISablierLockupTranched lockupTranched,
        bool cancelable,
        bool transferable,
        uint40 streamStartTime,
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        returns (ISablierMerkleLT merkleLT);

    /// @notice Sets the Sablier fee for claiming an airstream.
    /// @dev Emits a {SetSablierFee} event.
    ///
    /// Notes:
    /// - The new fee will only be applied to the future campaigns.
    ///
    /// Requiurements:
    /// - The caller must be the admin.
    ///
    /// @param fee The new fee to be set.
    function setSablierFee(uint256 fee) external;

    /// @notice Withdraws the Sablier fees accrued on `merkleLockup` to the provided address.
    /// @dev Emits a {WithdrawSablierFees} event.
    ///
    /// Notes:
    /// - This function transfers ETH to the provided address. If the receiver is a contract, it must be able to receive
    /// ETH.
    ///
    /// Requirements:
    /// - The caller must be the admin.
    ///
    /// @param to The address to receive the Sablier fees.
    function withdrawFees(address payable to, ISablierMerkleBase merkleLockup) external;
}
