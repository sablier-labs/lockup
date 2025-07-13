// SPDX-License-Identifier: UNLICENSED
// solhint-disable max-line-length
pragma solidity >=0.8.22 <0.9.0;

import { NFTSVG } from "src/libraries/NFTSVG.sol";
import { SVGElements } from "src/libraries/SVGElements.sol";

import { Base_Test } from "tests/Base.t.sol";

contract GenerateSVG_Unit_Concrete_Test is Base_Test {
    /// @dev If you need to update the hard-coded token URI:
    /// 1. Use "vm.writeFile" to log the strings to a file.
    /// 2. Remember to escape 'Courier New' with \'Courier New\'.
    function test_GenerateSVG_Pending() external view {
        string memory actualSVG = nftDescriptorMock.generateSVG_(
            NFTSVG.SVGParams({
                accentColor: "hsl(155,18%,30%)",
                amount: "100",
                tokenAddress: "0x03a6a84cd762d9707a21605b548aaab891562aab",
                tokenSymbol: "DAI",
                duration: "5 Days",
                progress: "0%",
                progressNumerical: 0,
                lockupAddress: "0xf3a045dc986015be9ae43bb3462ae5981b0816e0",
                status: "Pending"
            })
        );
        string memory expectedSVG1 = vm.readFile("tests/data/expected_svg_1.svg");
            
        assertEq(actualSVG, expectedSVG1, "SVG mismatch");
    }

    function test_GenerateSVG_Streaming() external view {
        string memory actualSVG = nftDescriptorMock.generateSVG_(
            NFTSVG.SVGParams({
                accentColor: "hsl(114,3%,53%)",
                amount: string.concat(SVGElements.SIGN_GE, " 1.23M"),
                tokenAddress: "0x03a6a84cd762d9707a21605b548aaab891562aab",
                tokenSymbol: "DAI",
                duration: "91 Days",
                progress: "42.35%",
                progressNumerical: 4235,
                lockupAddress: "0xf3a045dc986015be9ae43bb3462ae5981b0816e0",
                status: "Streaming"
            })
        );
        string memory expectedSVG2 = vm.readFile("tests/data/expected_svg_2.svg");
           
        assertEq(actualSVG, expectedSVG2, "SVG mismatch");
    }

    function test_GenerateSVG_Depleted() external view {
        string memory actualSVG = nftDescriptorMock.generateSVG_(
            NFTSVG.SVGParams({
                accentColor: "hsl(123,25%,44%)",
                amount: "100",
                tokenAddress: "0x03a6a84cd762d9707a21605b548aaab891562aab",
                tokenSymbol: "DAI",
                duration: "5 Days",
                progress: "100%",
                progressNumerical: 100,
                lockupAddress: "0xf3a045dc986015be9ae43bb3462ae5981b0816e0",
                status: "Depleted"
            })
        );
        string memory expectedSVG3 = vm.readFile("tests/data/expected_svg_3.svg");
           
            
        assertEq(actualSVG, expectedSVG3, "SVG mismatch");
    }
}
