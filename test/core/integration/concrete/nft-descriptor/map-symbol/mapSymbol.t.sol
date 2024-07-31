// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { MockERC721 } from "forge-std/src/mocks/MockERC721.sol";

import { Errors } from "src/core/libraries/Errors.sol";

import { NFTDescriptor_Integration_Shared_Test } from "../../../shared/nft-descriptor/NFTDescriptor.t.sol";

contract MapSymbol_Integration_Concrete_Test is NFTDescriptor_Integration_Shared_Test {
    function test_RevertGiven_UnknownNFT() external {
        MockERC721 nft = new MockERC721();
        nft.initialize("Foo", "FOO");
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierNFTDescriptor_UnknownNFT.selector, nft, "FOO"));
        nftDescriptorMock.mapSymbol_(IERC721Metadata(address(nft)));
    }

    modifier givenKnownNFT() {
        _;
    }

    function test_MapSymbol_LockupDynamic() external view givenKnownNFT {
        string memory actualLockupModel = nftDescriptorMock.mapSymbol_(lockupDynamic);
        string memory expectedLockupModel = "Sablier Lockup Dynamic";
        assertEq(actualLockupModel, expectedLockupModel, "lockupModel");
    }

    function test_MapSymbol_LockupLinear() external view givenKnownNFT {
        string memory actualLockupModel = nftDescriptorMock.mapSymbol_(lockupLinear);
        string memory expectedLockupModel = "Sablier Lockup Linear";
        assertEq(actualLockupModel, expectedLockupModel, "lockupModel");
    }

    function test_MapSymbol_LockupTranched() external view givenKnownNFT {
        string memory actualLockupModel = nftDescriptorMock.mapSymbol_(lockupTranched);
        string memory expectedLockupModel = "Sablier Lockup Tranched";
        assertEq(actualLockupModel, expectedLockupModel, "lockupModel");
    }
}
