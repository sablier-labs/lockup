// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ERC721Mock } from "../../../../mocks/erc721/ERC721Mock.sol";

import { Errors } from "src/libraries/Errors.sol";

import { NFTDescriptor_Integration_Concrete_Test } from "../NFTDescriptor.t.sol";

contract MapSymbol_Integration_Concrete_Test is NFTDescriptor_Integration_Concrete_Test {
    function test_RevertGiven_UnknownNFT() external {
        ERC721Mock nft = new ERC721Mock("Foo NFT", "FOO");
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2NFTDescriptor_UnknownNFT.selector, nft, "FOO"));
        nftDescriptorMock.mapSymbol_(nft);
    }

    modifier givenKnownNFT() {
        _;
    }

    function test_MapSymbol_LockupDynamic() external view givenKnownNFT {
        string memory actualSablierModel = nftDescriptorMock.mapSymbol_(lockupDynamic);
        string memory expectedSablierModel = "Lockup Dynamic";
        assertEq(actualSablierModel, expectedSablierModel, "sablierModel");
    }

    function test_MapSymbol_LockupLinear() external view givenKnownNFT {
        string memory actualSablierModel = nftDescriptorMock.mapSymbol_(lockupLinear);
        string memory expectedSablierModel = "Lockup Linear";
        assertEq(actualSablierModel, expectedSablierModel, "sablierModel");
    }

    function test_MapSymbol_LockupTranched() external view givenKnownNFT {
        string memory actualSablierModel = nftDescriptorMock.mapSymbol_(lockupTranched);
        string memory expectedSablierModel = "Lockup Tranched";
        assertEq(actualSablierModel, expectedSablierModel, "sablierModel");
    }
}
