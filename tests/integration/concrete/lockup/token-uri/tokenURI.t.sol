// SPDX-License-Identifier: UNLICENSED
// solhint-disable max-line-length,no-console,quotes
pragma solidity >=0.8.22 <0.9.0;

import { IERC721Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { console2 } from "forge-std/src/console2.sol";
import { StdStyle } from "forge-std/src/StdStyle.sol";
import { Base64 } from "solady/src/utils/Base64.sol";

import { Integration_Test } from "../../../Integration.t.sol";

/// @dev Requirements for these tests to work:
/// - The stream ID must be 1
/// - The stream's sender must be `0x6332e7b1deb1f1a0b77b2bb18b144330c7291bca`, i.e. `makeAddr("Sender")`
/// - The stream token must have the DAI symbol
/// - The contract deployer, i.e. the `sender` config option in `foundry.toml`, must have the default value
/// 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38 so that the deployed contracts have the same addresses as
/// the values hard coded in the tests below
contract TokenURI_Lockup_Integration_Concrete_Test is Integration_Test {
    address internal constant LOCKUP = 0x923b5Ab3714FD343316aF5A5434582Fd16722523;

    /// @dev To make these tests noninvasive, they are run only when the contract address matches the hard coded value.
    modifier skipOnMismatch() {
        if (address(lockup) == LOCKUP) {
            _;
        } else {
            console2.log(StdStyle.yellow('Warning: "Lockup.tokenURI" tests skipped due to address mismatch'));
        }
    }

    function test_RevertGiven_NFTNotExist() external {
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, ids.nullStream));
        lockup.tokenURI({ tokenId: ids.nullStream });
    }

    /// @dev If you need to update the hard-coded token URI:
    /// 1. Use "vm.writeFile" to log the strings to a file.
    /// 2. Remember to escape the EOL character \n with \\n.
    function test_WhenTokenURIDecoded() external skipOnMismatch givenNFTExists {
        vm.warp({ newTimestamp: defaults.START_TIME() + defaults.TOTAL_DURATION() / 4 });

        string memory tokenURI = lockup.tokenURI(ids.defaultStream);
        tokenURI = vm.replace({ input: tokenURI, from: "data:application/json;base64,", to: "" });
        string memory actualDecodedTokenURI = string(Base64.decode(tokenURI));
        string memory expectedDecodedTokenURI = vm.readFile("tests/data/token_uri.json");
        assertEq(actualDecodedTokenURI, expectedDecodedTokenURI, "decoded token URI");
    }

    function test_WhenTokenURINotDecoded() external skipOnMismatch givenNFTExists {
        vm.warp({ newTimestamp: defaults.START_TIME() + defaults.TOTAL_DURATION() / 4 });

        string memory actualTokenURI = lockup.tokenURI(ids.defaultStream);
        console2.log("actualTokenURI", actualTokenURI);
        string memory json = vm.readFile("tests/data/token_uri.json");
        string memory expectedTokenURI = string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
        assertEq(actualTokenURI, expectedTokenURI, "token URI");
    }
}
