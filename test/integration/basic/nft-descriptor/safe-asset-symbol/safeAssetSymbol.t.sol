// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { ERC20Bytes32 } from "../../../../mocks/erc20/ERC20Bytes32.sol";
import { NFTDescriptor_Integration_Basic_Test } from "../NFTDescriptor.t.sol";

contract SafeAssetSymbol_Integration_Basic_Test is NFTDescriptor_Integration_Basic_Test {
    function test_SafeAssetSymbol_Bytes32() external {
        ERC20Bytes32 asset = new ERC20Bytes32();
        string memory actualSymbol = nftDescriptorMock.safeAssetSymbol_(address(asset));
        string memory expectedSymbol = "ERC20";
        assertEq(actualSymbol, expectedSymbol, "symbol");
    }

    function test_SafeAssetSymbol_EOA() external {
        address eoa = vm.addr({ privateKey: 1 });
        string memory actualSymbol = nftDescriptorMock.safeAssetSymbol_(address(eoa));
        string memory expectedSymbol = "ERC20";
        assertEq(actualSymbol, expectedSymbol, "symbol");
    }

    function test_SafeAssetSymbol_SymbolNotImplemented() external {
        string memory actualSymbol = nftDescriptorMock.safeAssetSymbol_(address(noop));
        string memory expectedSymbol = "ERC20";
        assertEq(actualSymbol, expectedSymbol, "symbol");
    }

    modifier whenNotReverted() {
        _;
    }

    function test_SafeAssetSymbol_LongSymbol() external whenNotReverted {
        ERC20 asset = new ERC20("DAI", "This symbol is too long and it should be ignored");
        string memory actualSymbol = nftDescriptorMock.safeAssetSymbol_(address(asset));
        string memory expectedSymbol = "Symbol too long";
        assertEq(actualSymbol, expectedSymbol, "symbol");
    }

    function test_SafeAssetSymbol() external whenNotReverted {
        string memory actualSymbol = nftDescriptorMock.safeAssetSymbol_(address(dai));
        string memory expectedSymbol = dai.symbol();
        assertEq(actualSymbol, expectedSymbol, "symbol");
    }
}
