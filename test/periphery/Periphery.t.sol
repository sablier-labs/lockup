// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierLockup } from "src/core/interfaces/ISablierLockup.sol";
import { Lockup, LockupDynamic, LockupLinear, LockupTranched } from "src/core/types/DataTypes.sol";

import { ISablierMerkleBase } from "src/periphery/interfaces/ISablierMerkleBase.sol";
import { SablierMerkleInstant } from "src/periphery/SablierMerkleInstant.sol";
import { SablierMerkleLL } from "src/periphery/SablierMerkleLL.sol";
import { SablierMerkleLT } from "src/periphery/SablierMerkleLT.sol";

import { Base_Test } from "../Base.t.sol";
import { ContractWithoutReceiveEth, ContractWithReceiveEth } from "../mocks/ReceiveEth.sol";

contract Periphery_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ContractWithoutReceiveEth internal contractWithoutReceiveEth;
    ContractWithReceiveEth internal contractWithReceiveEth;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        contractWithoutReceiveEth = new ContractWithoutReceiveEth();
        contractWithReceiveEth = new ContractWithReceiveEth();
        vm.label({ account: address(contractWithoutReceiveEth), newLabel: "Contract Without Receive Eth" });
        vm.label({ account: address(contractWithReceiveEth), newLabel: "Contract With Receive Eth" });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                CALL EXPECTS - LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Expects multiple calls to {ISablierLockup.createWithDurationsLD}, each with the specified `params`.
    function expectMultipleCallsToCreateWithDurationsLD(
        uint64 count,
        Lockup.CreateWithDurations memory params,
        LockupDynamic.SegmentWithDuration[] memory segments
    )
        internal
    {
        vm.expectCall({
            callee: address(lockup),
            count: count,
            data: abi.encodeCall(ISablierLockup.createWithDurationsLD, (params, segments))
        });
    }

    /// @dev Expects multiple calls to {ISablierLockup.createWithDurationsLL}, each with the specified `params`.
    function expectMultipleCallsToCreateWithDurationsLL(
        uint64 count,
        Lockup.CreateWithDurations memory params,
        LockupLinear.Durations memory durations
    )
        internal
    {
        vm.expectCall({
            callee: address(lockup),
            count: count,
            data: abi.encodeCall(ISablierLockup.createWithDurationsLL, (params, durations))
        });
    }

    /// @dev Expects multiple calls to {ISablierLockup.createWithDurationsLT}, each with the specified `params`.
    function expectMultipleCallsToCreateWithDurationsLT(
        uint64 count,
        Lockup.CreateWithDurations memory params,
        LockupTranched.TrancheWithDuration[] memory tranches
    )
        internal
    {
        vm.expectCall({
            callee: address(lockup),
            count: count,
            data: abi.encodeCall(ISablierLockup.createWithDurationsLT, (params, tranches))
        });
    }

    /// @dev Expects multiple calls to {ISablierLockup.createWithTimestampsLD}, each with the specified `params`.
    function expectMultipleCallsToCreateWithTimestampsLD(
        uint64 count,
        Lockup.CreateWithTimestamps memory params,
        LockupDynamic.Segment[] memory segments
    )
        internal
    {
        vm.expectCall({
            callee: address(lockup),
            count: count,
            data: abi.encodeCall(ISablierLockup.createWithTimestampsLD, (params, segments))
        });
    }

    /// @dev Expects multiple calls to {ISablierLockup.createWithTimestampsLL}, each with the specified
    /// `params`.
    function expectMultipleCallsToCreateWithTimestampsLL(
        uint64 count,
        Lockup.CreateWithTimestamps memory params,
        uint40 cliff
    )
        internal
    {
        vm.expectCall({
            callee: address(lockup),
            count: count,
            data: abi.encodeCall(ISablierLockup.createWithTimestampsLL, (params, cliff))
        });
    }

    /// @dev Expects multiple calls to {ISablierLockup.createWithTimestampsLT}, each with the specified
    /// `params`.
    function expectMultipleCallsToCreateWithTimestampsLT(
        uint64 count,
        Lockup.CreateWithTimestamps memory params,
        LockupTranched.Tranche[] memory tranches
    )
        internal
    {
        vm.expectCall({
            callee: address(lockup),
            count: count,
            data: abi.encodeCall(ISablierLockup.createWithTimestampsLT, (params, tranches))
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                            CALL EXPECTS - MERKLE LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Expects a call to {ISablierMerkleBase.claim} with data provided.
    function expectCallToClaimWithData(
        address merkleLockup,
        uint256 sablierFee,
        uint256 index,
        address recipient,
        uint128 amount,
        bytes32[] memory merkleProof
    )
        internal
    {
        vm.expectCall(
            merkleLockup, sablierFee, abi.encodeCall(ISablierMerkleBase.claim, (index, recipient, amount, merkleProof))
        );
    }

    /// @dev Expects a call to {ISablierMerkleBase.claim} with msgValue as `msg.value`.
    function expectCallToClaimWithMsgValue(address merkleLockup, uint256 msgValue) internal {
        vm.expectCall(
            merkleLockup,
            msgValue,
            abi.encodeCall(
                ISablierMerkleBase.claim,
                (defaults.INDEX1(), users.recipient1, defaults.CLAIM_AMOUNT(), defaults.index1Proof())
            )
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   MERKLE-BASE
    //////////////////////////////////////////////////////////////////////////*/

    function computeMerkleInstantAddress(
        address caller,
        address campaignOwner,
        IERC20 asset_,
        bytes32 merkleRoot,
        uint40 expiration,
        uint256 sablierFee
    )
        internal
        view
        returns (address)
    {
        bytes32 salt = keccak256(
            abi.encodePacked(
                caller,
                address(asset_),
                expiration,
                campaignOwner,
                abi.encode(defaults.IPFS_CID()),
                merkleRoot,
                defaults.NAME_BYTES32()
            )
        );
        bytes32 creationBytecodeHash =
            keccak256(getMerkleInstantBytecode(campaignOwner, asset_, merkleRoot, expiration, sablierFee));
        return vm.computeCreate2Address({
            salt: salt,
            initCodeHash: creationBytecodeHash,
            deployer: address(merkleFactory)
        });
    }

    function computeMerkleLLAddress(
        address caller,
        address campaignOwner,
        IERC20 asset_,
        bytes32 merkleRoot,
        uint40 expiration,
        uint256 sablierFee
    )
        internal
        view
        returns (address)
    {
        bytes32 salt = keccak256(
            abi.encodePacked(
                caller,
                address(asset_),
                expiration,
                campaignOwner,
                abi.encode(defaults.IPFS_CID()),
                merkleRoot,
                defaults.NAME_BYTES32(),
                lockup,
                defaults.CANCELABLE(),
                defaults.TRANSFERABLE(),
                abi.encode(defaults.schedule())
            )
        );
        bytes32 creationBytecodeHash =
            keccak256(getMerkleLLBytecode(campaignOwner, asset_, merkleRoot, expiration, sablierFee));
        return vm.computeCreate2Address({
            salt: salt,
            initCodeHash: creationBytecodeHash,
            deployer: address(merkleFactory)
        });
    }

    function computeMerkleLTAddress(
        address caller,
        address campaignOwner,
        IERC20 asset_,
        bytes32 merkleRoot,
        uint40 expiration,
        uint256 sablierFee
    )
        internal
        view
        returns (address)
    {
        bytes32 salt = keccak256(
            abi.encodePacked(
                caller,
                address(asset_),
                expiration,
                campaignOwner,
                abi.encode(defaults.IPFS_CID()),
                merkleRoot,
                defaults.NAME_BYTES32(),
                lockup,
                defaults.CANCELABLE(),
                defaults.TRANSFERABLE(),
                defaults.STREAM_START_TIME_ZERO(),
                abi.encode(defaults.tranchesWithPercentages())
            )
        );
        bytes32 creationBytecodeHash =
            keccak256(getMerkleLTBytecode(campaignOwner, asset_, merkleRoot, expiration, sablierFee));
        return vm.computeCreate2Address({
            salt: salt,
            initCodeHash: creationBytecodeHash,
            deployer: address(merkleFactory)
        });
    }

    function getMerkleInstantBytecode(
        address campaignOwner,
        IERC20 asset_,
        bytes32 merkleRoot,
        uint40 expiration,
        uint256 sablierFee
    )
        internal
        view
        returns (bytes memory)
    {
        bytes memory constructorArgs =
            abi.encode(defaults.baseParams(campaignOwner, asset_, expiration, merkleRoot), sablierFee);
        if (!isTestOptimizedProfile()) {
            return bytes.concat(type(SablierMerkleInstant).creationCode, constructorArgs);
        } else {
            return bytes.concat(
                vm.getCode("out-optimized/SablierMerkleInstant.sol/SablierMerkleInstant.json"), constructorArgs
            );
        }
    }

    function getMerkleLLBytecode(
        address campaignOwner,
        IERC20 asset_,
        bytes32 merkleRoot,
        uint40 expiration,
        uint256 sablierFee
    )
        internal
        view
        returns (bytes memory)
    {
        bytes memory constructorArgs = abi.encode(
            defaults.baseParams(campaignOwner, asset_, expiration, merkleRoot),
            lockup,
            defaults.CANCELABLE(),
            defaults.TRANSFERABLE(),
            defaults.schedule(),
            sablierFee
        );
        if (!isTestOptimizedProfile()) {
            return bytes.concat(type(SablierMerkleLL).creationCode, constructorArgs);
        } else {
            return bytes.concat(vm.getCode("out-optimized/SablierMerkleLL.sol/SablierMerkleLL.json"), constructorArgs);
        }
    }

    function getMerkleLTBytecode(
        address campaignOwner,
        IERC20 asset_,
        bytes32 merkleRoot,
        uint40 expiration,
        uint256 sablierFee
    )
        internal
        view
        returns (bytes memory)
    {
        bytes memory constructorArgs = abi.encode(
            defaults.baseParams(campaignOwner, asset_, expiration, merkleRoot),
            lockup,
            defaults.CANCELABLE(),
            defaults.TRANSFERABLE(),
            defaults.STREAM_START_TIME_ZERO(),
            defaults.tranchesWithPercentages(),
            sablierFee
        );
        if (!isTestOptimizedProfile()) {
            return bytes.concat(type(SablierMerkleLT).creationCode, constructorArgs);
        } else {
            return bytes.concat(vm.getCode("out-optimized/SablierMerkleLT.sol/SablierMerkleLT.json"), constructorArgs);
        }
    }
}
