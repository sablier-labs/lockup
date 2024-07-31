// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierLockupDynamic } from "src/core/interfaces/ISablierLockupDynamic.sol";
import { ISablierLockupLinear } from "src/core/interfaces/ISablierLockupLinear.sol";
import { ISablierLockupTranched } from "src/core/interfaces/ISablierLockupTranched.sol";

import { Fork_Test } from "./Fork.t.sol";

contract NFTDescriptor_Fork_Test is Fork_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 internal constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address internal constant DAI_HOLDER = 0x66F62574ab04989737228D18C3624f7FC1edAe14;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() Fork_Test(DAI, DAI_HOLDER) { }

    /*//////////////////////////////////////////////////////////////////////////
                                      MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Loads the Lockup v1.0.0 contracts pre-deployed on Mainnet.
    modifier loadDeployments_v1_0_0() {
        lockupDynamic = ISablierLockupDynamic(0x39EFdC3dbB57B2388CcC4bb40aC4CB1226Bc9E44);
        lockupLinear = ISablierLockupLinear(0xB10daee1FCF62243aE27776D7a92D39dC8740f95);
        _;
    }

    /// @dev Loads the Lockup v1.1.2 contracts pre-deployed on Mainnet.
    modifier loadDeployments_v1_1_2() {
        lockupDynamic = ISablierLockupDynamic(0x7CC7e125d83A581ff438608490Cc0f7bDff79127);
        lockupLinear = ISablierLockupLinear(0xAFb979d9afAd1aD27C5eFf4E27226E3AB9e5dCC9);
        _;
    }

    /// @dev Loads the Lockup v1.2.0 contracts pre-deployed on Mainnet.
    modifier loadDeployments_v1_2_0() {
        lockupDynamic = ISablierLockupDynamic(0x9DeaBf7815b42Bf4E9a03EEc35a486fF74ee7459);
        lockupLinear = ISablierLockupLinear(0x3962f6585946823440d274aD7C719B02b49DE51E);
        lockupTranched = ISablierLockupTranched(0xf86B359035208e4529686A1825F2D5BeE38c28A8);
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Fork_Test.setUp();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev The following test checks whether the new NFT descriptor is compatible with Lockup Dynamic v1.0.0.
    ///
    /// Checklist:
    /// - It should expect a call to {ISablierLockupDynamic.tokenURI}.
    /// - The test would fail if the call to {ISablierLockupDynamic.tokenURI} reverts.
    ///
    /// Given enough fuzz runs, all the following scenarios will be fuzzed:
    /// - Multiple values of streamId.
    function testForkFuzz_TokenURI_LockupDynamic_v1_0_0(uint256 streamId) external loadDeployments_v1_0_0 {
        streamId = _bound(streamId, 1, lockupDynamic.nextStreamId() - 1);

        // Set the new NFT descriptor for the previous version of Lockup Dynamic.
        resetPrank({ msgSender: lockupDynamic.admin() });
        lockupDynamic.setNFTDescriptor(nftDescriptor);

        // Expects a successful call to the new NFT Descriptor.
        vm.expectCall({
            callee: address(nftDescriptor),
            data: abi.encodeCall(nftDescriptor.tokenURI, (lockupDynamic, streamId)),
            count: 1
        });

        // Generate the token URI using the new NFT Descriptor.
        lockupDynamic.tokenURI(streamId);
    }

    /// @dev The following test checks whether the new NFT descriptor is compatible with Lockup Dynamic v1.1.2.
    ///
    /// Checklist:
    /// - It should expect a call to {ISablierLockupDynamic.tokenURI}.
    /// - The test would fail if the call to {ISablierLockupDynamic.tokenURI} reverts.
    ///
    /// Given enough fuzz runs, all the following scenarios will be fuzzed:
    /// - Multiple values of streamId.
    function testForkFuzz_TokenURI_LockupDynamic_v1_1_2(uint256 streamId) external loadDeployments_v1_1_2 {
        streamId = _bound(streamId, 1, lockupDynamic.nextStreamId() - 1);

        // Set the new NFT descriptor for the previous version of Lockup Dynamic.
        resetPrank({ msgSender: lockupDynamic.admin() });
        lockupDynamic.setNFTDescriptor(nftDescriptor);

        // Expects a successful call to the new NFT Descriptor.
        vm.expectCall({
            callee: address(nftDescriptor),
            data: abi.encodeCall(nftDescriptor.tokenURI, (lockupDynamic, streamId)),
            count: 1
        });

        // Generate the token URI using the new NFT Descriptor.
        lockupDynamic.tokenURI(streamId);
    }

    /// @dev The following test checks whether the new NFT descriptor is compatible with Lockup Dynamic v1.2.0.
    ///
    /// Checklist:
    /// - It should expect a call to {ISablierLockupDynamic.tokenURI}.
    /// - The test would fail if the call to {ISablierLockupDynamic.tokenURI} reverts.
    ///
    /// Given enough fuzz runs, all the following scenarios will be fuzzed:
    /// - Multiple values of streamId.
    function testForkFuzz_TokenURI_LockupDynamic_v1_2_0(uint256 streamId) external loadDeployments_v1_2_0 {
        streamId = _bound(streamId, 1, lockupDynamic.nextStreamId() - 1);

        // Set the new NFT descriptor for the previous version of Lockup Dynamic.
        resetPrank({ msgSender: lockupDynamic.admin() });
        lockupDynamic.setNFTDescriptor(nftDescriptor);

        // Expects a successful call to the new NFT Descriptor.
        vm.expectCall({
            callee: address(nftDescriptor),
            data: abi.encodeCall(nftDescriptor.tokenURI, (lockupDynamic, streamId)),
            count: 1
        });

        // Generate the token URI using the new NFT Descriptor.
        lockupDynamic.tokenURI(streamId);
    }

    /// @dev The following test checks whether the new NFT descriptor is compatible with Lockup Linear v1.0.0.
    ///
    /// Checklist:
    /// - It should expect a call to {ISablierLockupLinear.tokenURI}.
    /// - The test would fail if the call to {ISablierLockupLinear.tokenURI} reverts.
    ///
    /// Given enough fuzz runs, all the following scenarios will be fuzzed:
    /// - Multiple values of streamId.
    function testForkFuzz_TokenURI_LockupLinear_v1_0_0(uint256 streamId) external loadDeployments_v1_0_0 {
        streamId = _bound(streamId, 1, lockupLinear.nextStreamId() - 1);

        // Set the new NFT descriptor for the previous version of Lockup Linear.
        resetPrank({ msgSender: lockupLinear.admin() });
        lockupLinear.setNFTDescriptor(nftDescriptor);

        // Expects a successful call to the new NFT Descriptor.
        vm.expectCall({
            callee: address(nftDescriptor),
            data: abi.encodeCall(nftDescriptor.tokenURI, (lockupLinear, streamId)),
            count: 1
        });

        // Generate the token URI using the new NFT Descriptor.
        lockupLinear.tokenURI(streamId);
    }

    /// @dev The following test checks whether the new NFT descriptor is compatible with Lockup Linear v1.1.2.
    ///
    /// Checklist:
    /// - It should expect a call to {ISablierLockupLinear.tokenURI}.
    /// - The test would fail if the call to {ISablierLockupLinear.tokenURI} reverts.
    ///
    /// Given enough fuzz runs, all the following scenarios will be fuzzed:
    /// - Multiple values of streamId.
    function testForkFuzz_TokenURI_LockupLinear_v1_1_2(uint256 streamId) external loadDeployments_v1_1_2 {
        streamId = _bound(streamId, 1, lockupLinear.nextStreamId() - 1);

        // Set the new NFT descriptor for the previous version of Lockup Linear.
        resetPrank({ msgSender: lockupLinear.admin() });
        lockupLinear.setNFTDescriptor(nftDescriptor);

        // Expects a successful call to the new NFT Descriptor.
        vm.expectCall({
            callee: address(nftDescriptor),
            data: abi.encodeCall(nftDescriptor.tokenURI, (lockupLinear, streamId)),
            count: 1
        });

        // Generate the token URI using the new NFT Descriptor.
        lockupLinear.tokenURI(streamId);
    }

    /// @dev The following test checks whether the new NFT descriptor is compatible with Lockup Linear v1.2.0.
    ///
    /// Checklist:
    /// - It should expect a call to {ISablierLockupLinear.tokenURI}.
    /// - The test would fail if the call to {ISablierLockupLinear.tokenURI} reverts.
    ///
    /// Given enough fuzz runs, all the following scenarios will be fuzzed:
    /// - Multiple values of streamId.
    function testForkFuzz_TokenURI_LockupLinear_v1_2_0(uint256 streamId) external loadDeployments_v1_2_0 {
        streamId = _bound(streamId, 1, lockupLinear.nextStreamId() - 1);

        // Set the new NFT descriptor for the previous version of Lockup Linear.
        resetPrank({ msgSender: lockupLinear.admin() });
        lockupLinear.setNFTDescriptor(nftDescriptor);

        // Expects a successful call to the new NFT Descriptor.
        vm.expectCall({
            callee: address(nftDescriptor),
            data: abi.encodeCall(nftDescriptor.tokenURI, (lockupLinear, streamId)),
            count: 1
        });

        // Generate the token URI using the new NFT Descriptor.
        lockupLinear.tokenURI(streamId);
    }

    /// @dev The following test checks whether the new NFT descriptor is compatible with Lockup Tranched v1.2.0.
    ///
    /// Checklist:
    /// - It should expect a call to {ISablierLockupTranched.tokenURI}.
    /// - The test would fail if the call to {ISablierLockupTranched.tokenURI} reverts.
    ///
    /// Given enough fuzz runs, all the following scenarios will be fuzzed:
    /// - Multiple values of streamId.
    function testForkFuzz_TokenURI_LockupTranched_v1_2_0(uint256 streamId) external loadDeployments_v1_2_0 {
        streamId = _bound(streamId, 1, lockupTranched.nextStreamId() - 1);

        // Set the new NFT descriptor for the previous version of Lockup Tranched.
        resetPrank({ msgSender: lockupTranched.admin() });
        lockupTranched.setNFTDescriptor(nftDescriptor);

        // Expects a successful call to the new NFT Descriptor.
        vm.expectCall({
            callee: address(nftDescriptor),
            data: abi.encodeCall(nftDescriptor.tokenURI, (lockupTranched, streamId)),
            count: 1
        });

        // Generate the token URI using the new NFT Descriptor.
        lockupTranched.tokenURI(streamId);
    }
}
