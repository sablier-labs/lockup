// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ISablierV2NFTDescriptor } from "src/interfaces/ISablierV2NFTDescriptor.sol";
import { Errors } from "src/libraries/Errors.sol";
import { SablierV2NFTDescriptor } from "src/SablierV2NFTDescriptor.sol";

import { Lockup_Integration_Shared_Test } from "../../../shared/lockup/Lockup.t.sol";
import { Integration_Test } from "../../../Integration.t.sol";

abstract contract SetNFTDescriptor_Integration_Basic_Test is Integration_Test, Lockup_Integration_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Integration_Test, Lockup_Integration_Shared_Test) {
        defaultStreamId = createDefaultStream();
    }

    function test_RevertWhen_CallerNotAdmin() external {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.admin, users.eve));
        lockup.setNFTDescriptor(ISablierV2NFTDescriptor(users.eve));
    }

    modifier whenCallerAdmin() {
        // Make the Admin the caller in the rest of this test suite.
        changePrank({ msgSender: users.admin });
        _;
    }

    function test_SetNFTDescriptor_SameNFTDescriptor() external whenCallerAdmin {
        // Expect a {SetNFTDescriptor} event to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit SetNFTDescriptor(users.admin, nftDescriptor, nftDescriptor);

        // Re-set the NFT descriptor.
        lockup.setNFTDescriptor(nftDescriptor);

        // Assert that the new NFT descriptor has been set.
        vm.expectCall(address(nftDescriptor), abi.encodeCall(ISablierV2NFTDescriptor.tokenURI, (lockup, 1)));
        lockup.tokenURI({ tokenId: defaultStreamId });
    }

    function test_SetNFTDescriptor_NewNFTDescriptor() external whenCallerAdmin {
        // Deploy the new NFT descriptor.
        ISablierV2NFTDescriptor newNFTDescriptor = new SablierV2NFTDescriptor();

        // Expect a {SetNFTDescriptor} event to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit SetNFTDescriptor(users.admin, nftDescriptor, newNFTDescriptor);

        // Set the new NFT descriptor.
        lockup.setNFTDescriptor(newNFTDescriptor);

        // Assert that the new NFT descriptor has been set.
        vm.expectCall(address(newNFTDescriptor), abi.encodeCall(ISablierV2NFTDescriptor.tokenURI, (lockup, 1)));
        lockup.tokenURI({ tokenId: defaultStreamId });
    }
}
