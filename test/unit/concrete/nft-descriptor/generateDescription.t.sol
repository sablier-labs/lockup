// SPDX-License-Identifier: UNLICENSED
// solhint-disable max-line-length,quotes
pragma solidity >=0.8.20 <0.9.0;

import { NFTDescriptor_Unit_Concrete_Test } from "./NFTDescriptor.t.sol";

contract GenerateDescription_Unit_Concrete_Test is NFTDescriptor_Unit_Concrete_Test {
    string internal constant DISCLAIMER =
        unicode"⚠️ WARNING: Transferring the NFT makes the new owner the recipient of the stream. The funds are not automatically withdrawn for the previous recipient.";

    function test_GenerateDescription_Empty() external {
        string memory actualDescription = nftDescriptorMock.generateDescription_("", "", "", "", "");
        string memory expectedDescription = string.concat(
            "This NFT represents a payment stream in a Sablier V2 ",
            " contract. The owner of this NFT can withdraw the streamed assets, which are denominated in ",
            ".\\n\\n",
            "- Stream ID: ",
            "\\n- ",
            " Address: ",
            "\\n- ",
            " Address: ",
            "\\n\\n",
            DISCLAIMER
        );
        assertEq(actualDescription, expectedDescription, "metadata description");
    }

    function test_GenerateDescription() external {
        string memory actualDescription = nftDescriptorMock.generateDescription_(
            "Lockup Linear",
            dai.symbol(),
            "42",
            "0x78B190C1E493752f85E02b00a0C98851A5638A30",
            "0xFEbD67A34821d1607a57DD31aae5f246D7dE2ca2"
        );
        string memory expectedDescription = string.concat(
            "This NFT represents a payment stream in a Sablier V2 ",
            "Lockup Linear",
            " contract. The owner of this NFT can withdraw the streamed assets, which are denominated in ",
            dai.symbol(),
            ".\\n\\n",
            "- Stream ID: ",
            "42",
            "\\n- ",
            "Lockup Linear",
            " Address: ",
            "0x78B190C1E493752f85E02b00a0C98851A5638A30",
            "\\n- ",
            "DAI",
            " Address: ",
            "0xFEbD67A34821d1607a57DD31aae5f246D7dE2ca2",
            "\\n\\n",
            DISCLAIMER
        );
        assertEq(actualDescription, expectedDescription, "metadata description");
    }
}
