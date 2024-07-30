// SPDX-License-Identifier: UNLICENSED
// solhint-disable max-line-length,no-console,quotes
pragma solidity >=0.8.22 <0.9.0;

import { IERC721Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { console2 } from "forge-std/src/console2.sol";
import { StdStyle } from "forge-std/src/StdStyle.sol";
import { Base64 } from "solady/src/utils/Base64.sol";

import { LockupDynamic_Integration_Concrete_Test } from "../LockupDynamic.t.sol";

/// @dev Requirements for these tests to work:
/// - The stream ID must be 1
/// - The stream's sender must be `0x6332e7b1deb1f1a0b77b2bb18b144330c7291bca`, i.e. `makeAddr("Sender")`
/// - The stream asset must have the DAI symbol
/// - The contract deployer, i.e. the `sender` config option in `foundry.toml`, must have the default value
/// 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38 so that the deployed contracts have the same addresses as
/// the values hard coded in the tests below
contract TokenURI_LockupDynamic_Integration_Concrete_Test is LockupDynamic_Integration_Concrete_Test {
    address internal constant LOCKUP_DYNAMIC = 0xDB25A7b768311dE128BBDa7B8426c3f9C74f3240;
    uint256 internal defaultStreamId;

    /// @dev To make these tests noninvasive, they are run only when the contract address matches the hard coded value.
    modifier skipOnMismatch() {
        if (address(lockupDynamic) == LOCKUP_DYNAMIC) {
            _;
        } else {
            console2.log(StdStyle.yellow('Warning: "LockupDynamic.tokenURI" tests skipped due to address mismatch'));
        }
    }

    function test_RevertGiven_NFTDoesNotExist() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, nullStreamId));
        lockupDynamic.tokenURI({ tokenId: nullStreamId });
    }

    modifier givenNFTExists() {
        defaultStreamId = createDefaultStream();
        vm.warp({ newTimestamp: defaults.START_TIME() + defaults.TOTAL_DURATION() / 4 });
        _;
    }

    /// @dev If you need to update the hard-coded token URI:
    /// 1. Use "vm.writeFile" to log the strings to a file.
    /// 2. Remember to escape the EOL character \n with \\n.
    function test_TokenURI_Decoded() external skipOnMismatch givenNFTExists {
        string memory tokenURI = lockupDynamic.tokenURI(defaultStreamId);
        tokenURI = vm.replace({ input: tokenURI, from: "data:application/json;base64,", to: "" });
        string memory actualDecodedTokenURI = string(Base64.decode(tokenURI));
        string memory expectedDecodedTokenURI =
            unicode'{"attributes":[{"trait_type":"Asset","value":"DAI"},{"trait_type":"Sender","value":"0x6332e7b1deb1f1a0b77b2bb18b144330c7291bca"},{"trait_type":"Status","value":"Streaming"}],"description":"This NFT represents a payment stream in a Sablier Lockup Dynamic contract. The owner of this NFT can withdraw the streamed assets, which are denominated in DAI.\\n\\n- Stream ID: 1\\n- Lockup Dynamic Address: 0xdb25a7b768311de128bbda7b8426c3f9c74f3240\\n- DAI Address: 0x03a6a84cd762d9707a21605b548aaab891562aab\\n\\n⚠️ WARNING: Transferring the NFT makes the new owner the recipient of the stream. The funds are not automatically withdrawn for the previous recipient.","external_url":"https://sablier.com","name":"Sablier Lockup Dynamic #1","image":"data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxMDAwIiBoZWlnaHQ9IjEwMDAiIHZpZXdCb3g9IjAgMCAxMDAwIDEwMDAiPjxyZWN0IHdpZHRoPSIxMDAlIiBoZWlnaHQ9IjEwMCUiIGZpbHRlcj0idXJsKCNOb2lzZSkiLz48cmVjdCB4PSI3MCIgeT0iNzAiIHdpZHRoPSI4NjAiIGhlaWdodD0iODYwIiBmaWxsPSIjZmZmIiBmaWxsLW9wYWNpdHk9Ii4wMyIgcng9IjQ1IiByeT0iNDUiIHN0cm9rZT0iI2ZmZiIgc3Ryb2tlLW9wYWNpdHk9Ii4xIiBzdHJva2Utd2lkdGg9IjQiLz48ZGVmcz48Y2lyY2xlIGlkPSJHbG93IiByPSI1MDAiIGZpbGw9InVybCgjUmFkaWFsR2xvdykiLz48ZmlsdGVyIGlkPSJOb2lzZSI+PGZlRmxvb2QgeD0iMCIgeT0iMCIgd2lkdGg9IjEwMCUiIGhlaWdodD0iMTAwJSIgZmxvb2QtY29sb3I9ImhzbCgyMzAsMjElLDExJSkiIGZsb29kLW9wYWNpdHk9IjEiIHJlc3VsdD0iZmxvb2RGaWxsIi8+PGZlVHVyYnVsZW5jZSBiYXNlRnJlcXVlbmN5PSIuNCIgbnVtT2N0YXZlcz0iMyIgcmVzdWx0PSJOb2lzZSIgdHlwZT0iZnJhY3RhbE5vaXNlIi8+PGZlQmxlbmQgaW49Ik5vaXNlIiBpbjI9ImZsb29kRmlsbCIgbW9kZT0ic29mdC1saWdodCIvPjwvZmlsdGVyPjxwYXRoIGlkPSJMb2dvIiBmaWxsPSIjZmZmIiBmaWxsLW9wYWNpdHk9Ii4xIiBkPSJtMTMzLjU1OSwxMjQuMDM0Yy0uMDEzLDIuNDEyLTEuMDU5LDQuODQ4LTIuOTIzLDYuNDAyLTIuNTU4LDEuODE5LTUuMTY4LDMuNDM5LTcuODg4LDQuOTk2LTE0LjQ0LDguMjYyLTMxLjA0NywxMi41NjUtNDcuNjc0LDEyLjU2OS04Ljg1OC4wMzYtMTcuODM4LTEuMjcyLTI2LjMyOC0zLjY2My05LjgwNi0yLjc2Ni0xOS4wODctNy4xMTMtMjcuNTYyLTEyLjc3OC0xMy44NDItOC4wMjUsOS40NjgtMjguNjA2LDE2LjE1My0zNS4yNjVoMGMyLjAzNS0xLjgzOCw0LjI1Mi0zLjU0Niw2LjQ2My01LjIyNGgwYzYuNDI5LTUuNjU1LDE2LjIxOC0yLjgzNSwyMC4zNTgsNC4xNyw0LjE0Myw1LjA1Nyw4LjgxNiw5LjY0OSwxMy45MiwxMy43MzRoLjAzN2M1LjczNiw2LjQ2MSwxNS4zNTctMi4yNTMsOS4zOC04LjQ4LDAsMC0zLjUxNS0zLjUxNS0zLjUxNS0zLjUxNS0xMS40OS0xMS40NzgtNTIuNjU2LTUyLjY2NC02NC44MzctNjQuODM3bC4wNDktLjAzN2MtMS43MjUtMS42MDYtMi43MTktMy44NDctMi43NTEtNi4yMDRoMGMtLjA0Ni0yLjM3NSwxLjA2Mi00LjU4MiwyLjcyNi02LjIyOWgwbC4xODUtLjE0OGgwYy4wOTktLjA2MiwuMjIyLS4xNDgsLjM3LS4yNTloMGMyLjA2LTEuMzYyLDMuOTUxLTIuNjIxLDYuMDQ0LTMuODQyQzU3Ljc2My0zLjQ3Myw5Ny43Ni0yLjM0MSwxMjguNjM3LDE4LjMzMmMxNi42NzEsOS45NDYtMjYuMzQ0LDU0LjgxMy0zOC42NTEsNDAuMTk5LTYuMjk5LTYuMDk2LTE4LjA2My0xNy43NDMtMTkuNjY4LTE4LjgxMS02LjAxNi00LjA0Ny0xMy4wNjEsNC43NzYtNy43NTIsOS43NTFsNjguMjU0LDY4LjM3MWMxLjcyNCwxLjYwMSwyLjcxNCwzLjg0LDIuNzM4LDYuMTkyWiIvPjxwYXRoIGlkPSJGbG9hdGluZ1RleHQiIGZpbGw9Im5vbmUiIGQ9Ik0xMjUgNDVoNzUwczgwIDAgODAgODB2NzUwczAgODAgLTgwIDgwaC03NTBzLTgwIDAgLTgwIC04MHYtNzUwczAgLTgwIDgwIC04MCIvPjxyYWRpYWxHcmFkaWVudCBpZD0iUmFkaWFsR2xvdyI+PHN0b3Agb2Zmc2V0PSIwJSIgc3RvcC1jb2xvcj0iaHNsKDYxLDg4JSw0MCUpIiBzdG9wLW9wYWNpdHk9Ii42Ii8+PHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSJoc2woMjMwLDIxJSwxMSUpIiBzdG9wLW9wYWNpdHk9IjAiLz48L3JhZGlhbEdyYWRpZW50PjxsaW5lYXJHcmFkaWVudCBpZD0iU2FuZFRvcCIgeDE9IjAlIiB5MT0iMCUiPjxzdG9wIG9mZnNldD0iMCUiIHN0b3AtY29sb3I9ImhzbCg2MSw4OCUsNDAlKSIvPjxzdG9wIG9mZnNldD0iMTAwJSIgc3RvcC1jb2xvcj0iaHNsKDIzMCwyMSUsMTElKSIvPjwvbGluZWFyR3JhZGllbnQ+PGxpbmVhckdyYWRpZW50IGlkPSJTYW5kQm90dG9tIiB4MT0iMTAwJSIgeTE9IjEwMCUiPjxzdG9wIG9mZnNldD0iMTAlIiBzdG9wLWNvbG9yPSJoc2woMjMwLDIxJSwxMSUpIi8+PHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSJoc2woNjEsODglLDQwJSkiLz48YW5pbWF0ZSBhdHRyaWJ1dGVOYW1lPSJ4MSIgZHVyPSI2cyIgcmVwZWF0Q291bnQ9ImluZGVmaW5pdGUiIHZhbHVlcz0iMzAlOzYwJTsxMjAlOzYwJTszMCU7Ii8+PC9saW5lYXJHcmFkaWVudD48bGluZWFyR3JhZGllbnQgaWQ9IkhvdXJnbGFzc1N0cm9rZSIgZ3JhZGllbnRUcmFuc2Zvcm09InJvdGF0ZSg5MCkiIGdyYWRpZW50VW5pdHM9InVzZXJTcGFjZU9uVXNlIj48c3RvcCBvZmZzZXQ9IjUwJSIgc3RvcC1jb2xvcj0iaHNsKDYxLDg4JSw0MCUpIi8+PHN0b3Agb2Zmc2V0PSI4MCUiIHN0b3AtY29sb3I9ImhzbCgyMzAsMjElLDExJSkiLz48L2xpbmVhckdyYWRpZW50PjxnIGlkPSJIb3VyZ2xhc3MiPjxwYXRoIGQ9Ik0gNTAsMzYwIGEgMzAwLDMwMCAwIDEsMSA2MDAsMCBhIDMwMCwzMDAgMCAxLDEgLTYwMCwwIiBmaWxsPSIjZmZmIiBmaWxsLW9wYWNpdHk9Ii4wMiIgc3Ryb2tlPSJ1cmwoI0hvdXJnbGFzc1N0cm9rZSkiIHN0cm9rZS13aWR0aD0iNCIvPjxwYXRoIGQ9Im01NjYsMTYxLjIwMXYtNTMuOTI0YzAtMTkuMzgyLTIyLjUxMy0zNy41NjMtNjMuMzk4LTUxLjE5OC00MC43NTYtMTMuNTkyLTk0Ljk0Ni0yMS4wNzktMTUyLjU4Ny0yMS4wNzlzLTExMS44MzgsNy40ODctMTUyLjYwMiwyMS4wNzljLTQwLjg5MywxMy42MzYtNjMuNDEzLDMxLjgxNi02My40MTMsNTEuMTk4djUzLjkyNGMwLDE3LjE4MSwxNy43MDQsMzMuNDI3LDUwLjIyMyw0Ni4zOTR2Mjg0LjgwOWMtMzIuNTE5LDEyLjk2LTUwLjIyMywyOS4yMDYtNTAuMjIzLDQ2LjM5NHY1My45MjRjMCwxOS4zODIsMjIuNTIsMzcuNTYzLDYzLjQxMyw1MS4xOTgsNDAuNzYzLDEzLjU5Miw5NC45NTQsMjEuMDc5LDE1Mi42MDIsMjEuMDc5czExMS44MzEtNy40ODcsMTUyLjU4Ny0yMS4wNzljNDAuODg2LTEzLjYzNiw2My4zOTgtMzEuODE2LDYzLjM5OC01MS4xOTh2LTUzLjkyNGMwLTE3LjE5Ni0xNy43MDQtMzMuNDM1LTUwLjIyMy00Ni40MDFWMjA3LjYwM2MzMi41MTktMTIuOTY3LDUwLjIyMy0yOS4yMDYsNTAuMjIzLTQ2LjQwMVptLTM0Ny40NjIsNTcuNzkzbDEzMC45NTksMTMxLjAyNy0xMzAuOTU5LDEzMS4wMTNWMjE4Ljk5NFptMjYyLjkyNC4wMjJ2MjYyLjAxOGwtMTMwLjkzNy0xMzEuMDA2LDEzMC45MzctMTMxLjAxM1oiIGZpbGw9IiMxNjE4MjIiPjwvcGF0aD48cG9seWdvbiBwb2ludHM9IjM1MCAzNTAuMDI2IDQxNS4wMyAyODQuOTc4IDI4NSAyODQuOTc4IDM1MCAzNTAuMDI2IiBmaWxsPSJ1cmwoI1NhbmRCb3R0b20pIi8+PHBhdGggZD0ibTQxNi4zNDEsMjgxLjk3NWMwLC45MTQtLjM1NCwxLjgwOS0xLjAzNSwyLjY4LTUuNTQyLDcuMDc2LTMyLjY2MSwxMi40NS02NS4yOCwxMi40NS0zMi42MjQsMC01OS43MzgtNS4zNzQtNjUuMjgtMTIuNDUtLjY4MS0uODcyLTEuMDM1LTEuNzY3LTEuMDM1LTIuNjgsMC0uOTE0LjM1NC0xLjgwOCwxLjAzNS0yLjY3Niw1LjU0Mi03LjA3NiwzMi42NTYtMTIuNDUsNjUuMjgtMTIuNDUsMzIuNjE5LDAsNTkuNzM4LDUuMzc0LDY1LjI4LDEyLjQ1LjY4MS44NjcsMS4wMzUsMS43NjIsMS4wMzUsMi42NzZaIiBmaWxsPSJ1cmwoI1NhbmRUb3ApIi8+PHBhdGggZD0ibTQ4MS40Niw1MDQuMTAxdjU4LjQ0OWMtMi4zNS43Ny00LjgyLDEuNTEtNy4zOSwyLjIzLTMwLjMsOC41NC03NC42NSwxMy45Mi0xMjQuMDYsMTMuOTItNTMuNiwwLTEwMS4yNC02LjMzLTEzMS40Ny0xNi4xNnYtNTguNDM5aDI2Mi45MloiIGZpbGw9InVybCgjU2FuZEJvdHRvbSkiLz48ZWxsaXBzZSBjeD0iMzUwIiBjeT0iNTA0LjEwMSIgcng9IjEzMS40NjIiIHJ5PSIyOC4xMDgiIGZpbGw9InVybCgjU2FuZFRvcCkiLz48ZyBmaWxsPSJub25lIiBzdHJva2U9InVybCgjSG91cmdsYXNzU3Ryb2tlKSIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbWl0ZXJsaW1pdD0iMTAiIHN0cm9rZS13aWR0aD0iNCI+PHBhdGggZD0ibTU2NS42NDEsMTA3LjI4YzAsOS41MzctNS41NiwxOC42MjktMTUuNjc2LDI2Ljk3M2gtLjAyM2MtOS4yMDQsNy41OTYtMjIuMTk0LDE0LjU2Mi0zOC4xOTcsMjAuNTkyLTM5LjUwNCwxNC45MzYtOTcuMzI1LDI0LjM1NS0xNjEuNzMzLDI0LjM1NS05MC40OCwwLTE2Ny45NDgtMTguNTgyLTE5OS45NTMtNDQuOTQ4aC0uMDIzYy0xMC4xMTUtOC4zNDQtMTUuNjc2LTE3LjQzNy0xNS42NzYtMjYuOTczLDAtMzkuNzM1LDk2LjU1NC03MS45MjEsMjE1LjY1Mi03MS45MjFzMjE1LjYyOSwzMi4xODUsMjE1LjYyOSw3MS45MjFaIi8+PHBhdGggZD0ibTEzNC4zNiwxNjEuMjAzYzAsMzkuNzM1LDk2LjU1NCw3MS45MjEsMjE1LjY1Miw3MS45MjFzMjE1LjYyOS0zMi4xODYsMjE1LjYyOS03MS45MjEiLz48bGluZSB4MT0iMTM0LjM2IiB5MT0iMTYxLjIwMyIgeDI9IjEzNC4zNiIgeTI9IjEwNy4yOCIvPjxsaW5lIHgxPSI1NjUuNjQiIHkxPSIxNjEuMjAzIiB4Mj0iNTY1LjY0IiB5Mj0iMTA3LjI4Ii8+PGxpbmUgeDE9IjE4NC41ODQiIHkxPSIyMDYuODIzIiB4Mj0iMTg0LjU4NSIgeTI9IjUzNy41NzkiLz48bGluZSB4MT0iMjE4LjE4MSIgeTE9IjIxOC4xMTgiIHgyPSIyMTguMTgxIiB5Mj0iNTYyLjUzNyIvPjxsaW5lIHgxPSI0ODEuODE4IiB5MT0iMjE4LjE0MiIgeDI9IjQ4MS44MTkiIHkyPSI1NjIuNDI4Ii8+PGxpbmUgeDE9IjUxNS40MTUiIHkxPSIyMDcuMzUyIiB4Mj0iNTE1LjQxNiIgeTI9IjUzNy41NzkiLz48cGF0aCBkPSJtMTg0LjU4LDUzNy41OGMwLDUuNDUsNC4yNywxMC42NSwxMi4wMywxNS40MmguMDJjNS41MSwzLjM5LDEyLjc5LDYuNTUsMjEuNTUsOS40MiwzMC4yMSw5LjksNzguMDIsMTYuMjgsMTMxLjgzLDE2LjI4LDQ5LjQxLDAsOTMuNzYtNS4zOCwxMjQuMDYtMTMuOTIsMi43LS43Niw1LjI5LTEuNTQsNy43NS0yLjM1LDguNzctMi44NywxNi4wNS02LjA0LDIxLjU2LTkuNDNoMGM3Ljc2LTQuNzcsMTIuMDQtOS45NywxMi4wNC0xNS40MiIvPjxwYXRoIGQ9Im0xODQuNTgyLDQ5Mi42NTZjLTMxLjM1NCwxMi40ODUtNTAuMjIzLDI4LjU4LTUwLjIyMyw0Ni4xNDIsMCw5LjUzNiw1LjU2NCwxOC42MjcsMTUuNjc3LDI2Ljk2OWguMDIyYzguNTAzLDcuMDA1LDIwLjIxMywxMy40NjMsMzQuNTI0LDE5LjE1OSw5Ljk5OSwzLjk5MSwyMS4yNjksNy42MDksMzMuNTk3LDEwLjc4OCwzNi40NSw5LjQwNyw4Mi4xODEsMTUuMDAyLDEzMS44MzUsMTUuMDAyczk1LjM2My01LjU5NSwxMzEuODA3LTE1LjAwMmMxMC44NDctMi43OSwyMC44NjctNS45MjYsMjkuOTI0LTkuMzQ5LDEuMjQ0LS40NjcsMi40NzMtLjk0MiwzLjY3My0xLjQyNCwxNC4zMjYtNS42OTYsMjYuMDM1LTEyLjE2MSwzNC41MjQtMTkuMTczaC4wMjJjMTAuMTE0LTguMzQyLDE1LjY3Ny0xNy40MzMsMTUuNjc3LTI2Ljk2OSwwLTE3LjU2Mi0xOC44NjktMzMuNjY1LTUwLjIyMy00Ni4xNSIvPjxwYXRoIGQ9Im0xMzQuMzYsNTkyLjcyYzAsMzkuNzM1LDk2LjU1NCw3MS45MjEsMjE1LjY1Miw3MS45MjFzMjE1LjYyOS0zMi4xODYsMjE1LjYyOS03MS45MjEiLz48bGluZSB4MT0iMTM0LjM2IiB5MT0iNTkyLjcyIiB4Mj0iMTM0LjM2IiB5Mj0iNTM4Ljc5NyIvPjxsaW5lIHgxPSI1NjUuNjQiIHkxPSI1OTIuNzIiIHgyPSI1NjUuNjQiIHkyPSI1MzguNzk3Ii8+PHBvbHlsaW5lIHBvaW50cz0iNDgxLjgyMiA0ODEuOTAxIDQ4MS43OTggNDgxLjg3NyA0ODEuNzc1IDQ4MS44NTQgMzUwLjAxNSAzNTAuMDI2IDIxOC4xODUgMjE4LjEyOSIvPjxwb2x5bGluZSBwb2ludHM9IjIxOC4xODUgNDgxLjkwMSAyMTguMjMxIDQ4MS44NTQgMzUwLjAxNSAzNTAuMDI2IDQ4MS44MjIgMjE4LjE1MiIvPjwvZz48L2c+PGcgaWQ9IlByb2dyZXNzIiBmaWxsPSIjZmZmIj48cmVjdCB3aWR0aD0iMjA4IiBoZWlnaHQ9IjEwMCIgZmlsbC1vcGFjaXR5PSIuMDMiIHJ4PSIxNSIgcnk9IjE1IiBzdHJva2U9IiNmZmYiIHN0cm9rZS1vcGFjaXR5PSIuMSIgc3Ryb2tlLXdpZHRoPSI0Ii8+PHRleHQgeD0iMjAiIHk9IjM0IiBmb250LWZhbWlseT0iJ0NvdXJpZXIgTmV3JyxBcmlhbCxtb25vc3BhY2UiIGZvbnQtc2l6ZT0iMjJweCI+UHJvZ3Jlc3M8L3RleHQ+PHRleHQgeD0iMjAiIHk9IjcyIiBmb250LWZhbWlseT0iJ0NvdXJpZXIgTmV3JyxBcmlhbCxtb25vc3BhY2UiIGZvbnQtc2l6ZT0iMjZweCI+MjUlPC90ZXh0PjxnIGZpbGw9Im5vbmUiPjxjaXJjbGUgY3g9IjE2NiIgY3k9IjUwIiByPSIyMiIgc3Ryb2tlPSJoc2woMjMwLDIxJSwxMSUpIiBzdHJva2Utd2lkdGg9IjEwIi8+PGNpcmNsZSBjeD0iMTY2IiBjeT0iNTAiIHBhdGhMZW5ndGg9IjEwMDAwIiByPSIyMiIgc3Ryb2tlPSJoc2woNjEsODglLDQwJSkiIHN0cm9rZS1kYXNoYXJyYXk9IjEwMDAwIiBzdHJva2UtZGFzaG9mZnNldD0iNzUwMCIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2Utd2lkdGg9IjUiIHRyYW5zZm9ybT0icm90YXRlKC05MCkiIHRyYW5zZm9ybS1vcmlnaW49IjE2NiA1MCIvPjwvZz48L2c+PGcgaWQ9IlN0YXR1cyIgZmlsbD0iI2ZmZiI+PHJlY3Qgd2lkdGg9IjE4NCIgaGVpZ2h0PSIxMDAiIGZpbGwtb3BhY2l0eT0iLjAzIiByeD0iMTUiIHJ5PSIxNSIgc3Ryb2tlPSIjZmZmIiBzdHJva2Utb3BhY2l0eT0iLjEiIHN0cm9rZS13aWR0aD0iNCIvPjx0ZXh0IHg9IjIwIiB5PSIzNCIgZm9udC1mYW1pbHk9IidDb3VyaWVyIE5ldycsQXJpYWwsbW9ub3NwYWNlIiBmb250LXNpemU9IjIycHgiPlN0YXR1czwvdGV4dD48dGV4dCB4PSIyMCIgeT0iNzIiIGZvbnQtZmFtaWx5PSInQ291cmllciBOZXcnLEFyaWFsLG1vbm9zcGFjZSIgZm9udC1zaXplPSIyNnB4Ij5TdHJlYW1pbmc8L3RleHQ+PC9nPjxnIGlkPSJBbW91bnQiIGZpbGw9IiNmZmYiPjxyZWN0IHdpZHRoPSIxMjAiIGhlaWdodD0iMTAwIiBmaWxsLW9wYWNpdHk9Ii4wMyIgcng9IjE1IiByeT0iMTUiIHN0cm9rZT0iI2ZmZiIgc3Ryb2tlLW9wYWNpdHk9Ii4xIiBzdHJva2Utd2lkdGg9IjQiLz48dGV4dCB4PSIyMCIgeT0iMzQiIGZvbnQtZmFtaWx5PSInQ291cmllciBOZXcnLEFyaWFsLG1vbm9zcGFjZSIgZm9udC1zaXplPSIyMnB4Ij5BbW91bnQ8L3RleHQ+PHRleHQgeD0iMjAiIHk9IjcyIiBmb250LWZhbWlseT0iJ0NvdXJpZXIgTmV3JyxBcmlhbCxtb25vc3BhY2UiIGZvbnQtc2l6ZT0iMjZweCI+JiM4ODA1OyAxMEs8L3RleHQ+PC9nPjxnIGlkPSJEdXJhdGlvbiIgZmlsbD0iI2ZmZiI+PHJlY3Qgd2lkdGg9IjE1MiIgaGVpZ2h0PSIxMDAiIGZpbGwtb3BhY2l0eT0iLjAzIiByeD0iMTUiIHJ5PSIxNSIgc3Ryb2tlPSIjZmZmIiBzdHJva2Utb3BhY2l0eT0iLjEiIHN0cm9rZS13aWR0aD0iNCIvPjx0ZXh0IHg9IjIwIiB5PSIzNCIgZm9udC1mYW1pbHk9IidDb3VyaWVyIE5ldycsQXJpYWwsbW9ub3NwYWNlIiBmb250LXNpemU9IjIycHgiPkR1cmF0aW9uPC90ZXh0Pjx0ZXh0IHg9IjIwIiB5PSI3MiIgZm9udC1mYW1pbHk9IidDb3VyaWVyIE5ldycsQXJpYWwsbW9ub3NwYWNlIiBmb250LXNpemU9IjI2cHgiPiZsdDsgMSBEYXk8L3RleHQ+PC9nPjwvZGVmcz48dGV4dCB0ZXh0LXJlbmRlcmluZz0ib3B0aW1pemVTcGVlZCI+PHRleHRQYXRoIHN0YXJ0T2Zmc2V0PSItMTAwJSIgaHJlZj0iI0Zsb2F0aW5nVGV4dCIgZmlsbD0iI2ZmZiIgZm9udC1mYW1pbHk9IidDb3VyaWVyIE5ldycsQXJpYWwsbW9ub3NwYWNlIiBmaWxsLW9wYWNpdHk9Ii44IiBmb250LXNpemU9IjI2cHgiPjxhbmltYXRlIGFkZGl0aXZlPSJzdW0iIGF0dHJpYnV0ZU5hbWU9InN0YXJ0T2Zmc2V0IiBiZWdpbj0iMHMiIGR1cj0iNTBzIiBmcm9tPSIwJSIgcmVwZWF0Q291bnQ9ImluZGVmaW5pdGUiIHRvPSIxMDAlIi8+MHhkYjI1YTdiNzY4MzExZGUxMjhiYmRhN2I4NDI2YzNmOWM3NGYzMjQwIOKAoiBTYWJsaWVyIFYyIExvY2t1cCBEeW5hbWljPC90ZXh0UGF0aD48dGV4dFBhdGggc3RhcnRPZmZzZXQ9IjAlIiBocmVmPSIjRmxvYXRpbmdUZXh0IiBmaWxsPSIjZmZmIiBmb250LWZhbWlseT0iJ0NvdXJpZXIgTmV3JyxBcmlhbCxtb25vc3BhY2UiIGZpbGwtb3BhY2l0eT0iLjgiIGZvbnQtc2l6ZT0iMjZweCI+PGFuaW1hdGUgYWRkaXRpdmU9InN1bSIgYXR0cmlidXRlTmFtZT0ic3RhcnRPZmZzZXQiIGJlZ2luPSIwcyIgZHVyPSI1MHMiIGZyb209IjAlIiByZXBlYXRDb3VudD0iaW5kZWZpbml0ZSIgdG89IjEwMCUiLz4weGRiMjVhN2I3NjgzMTFkZTEyOGJiZGE3Yjg0MjZjM2Y5Yzc0ZjMyNDAg4oCiIFNhYmxpZXIgVjIgTG9ja3VwIER5bmFtaWM8L3RleHRQYXRoPjx0ZXh0UGF0aCBzdGFydE9mZnNldD0iLTUwJSIgaHJlZj0iI0Zsb2F0aW5nVGV4dCIgZmlsbD0iI2ZmZiIgZm9udC1mYW1pbHk9IidDb3VyaWVyIE5ldycsQXJpYWwsbW9ub3NwYWNlIiBmaWxsLW9wYWNpdHk9Ii44IiBmb250LXNpemU9IjI2cHgiPjxhbmltYXRlIGFkZGl0aXZlPSJzdW0iIGF0dHJpYnV0ZU5hbWU9InN0YXJ0T2Zmc2V0IiBiZWdpbj0iMHMiIGR1cj0iNTBzIiBmcm9tPSIwJSIgcmVwZWF0Q291bnQ9ImluZGVmaW5pdGUiIHRvPSIxMDAlIi8+MHgwM2E2YTg0Y2Q3NjJkOTcwN2EyMTYwNWI1NDhhYWFiODkxNTYyYWFiIOKAoiBEQUk8L3RleHRQYXRoPjx0ZXh0UGF0aCBzdGFydE9mZnNldD0iNTAlIiBocmVmPSIjRmxvYXRpbmdUZXh0IiBmaWxsPSIjZmZmIiBmb250LWZhbWlseT0iJ0NvdXJpZXIgTmV3JyxBcmlhbCxtb25vc3BhY2UiIGZpbGwtb3BhY2l0eT0iLjgiIGZvbnQtc2l6ZT0iMjZweCI+PGFuaW1hdGUgYWRkaXRpdmU9InN1bSIgYXR0cmlidXRlTmFtZT0ic3RhcnRPZmZzZXQiIGJlZ2luPSIwcyIgZHVyPSI1MHMiIGZyb209IjAlIiByZXBlYXRDb3VudD0iaW5kZWZpbml0ZSIgdG89IjEwMCUiLz4weDAzYTZhODRjZDc2MmQ5NzA3YTIxNjA1YjU0OGFhYWI4OTE1NjJhYWIg4oCiIERBSTwvdGV4dFBhdGg+PC90ZXh0Pjx1c2UgaHJlZj0iI0dsb3ciIGZpbGwtb3BhY2l0eT0iLjkiLz48dXNlIGhyZWY9IiNHbG93IiB4PSIxMDAwIiB5PSIxMDAwIiBmaWxsLW9wYWNpdHk9Ii45Ii8+PHVzZSBocmVmPSIjTG9nbyIgeD0iMTcwIiB5PSIxNzAiIHRyYW5zZm9ybT0ic2NhbGUoLjYpIi8+PHVzZSBocmVmPSIjSG91cmdsYXNzIiB4PSIxNTAiIHk9IjkwIiB0cmFuc2Zvcm09InJvdGF0ZSgxMCkiIHRyYW5zZm9ybS1vcmlnaW49IjUwMCA1MDAiLz48dXNlIGhyZWY9IiNQcm9ncmVzcyIgeD0iMTQ0IiB5PSI3OTAiLz48dXNlIGhyZWY9IiNTdGF0dXMiIHg9IjM2OCIgeT0iNzkwIi8+PHVzZSBocmVmPSIjQW1vdW50IiB4PSI1NjgiIHk9Ijc5MCIvPjx1c2UgaHJlZj0iI0R1cmF0aW9uIiB4PSI3MDQiIHk9Ijc5MCIvPjwvc3ZnPg=="}';
        assertEq(actualDecodedTokenURI, expectedDecodedTokenURI, "decoded token URI");
    }

    function test_TokenURI_Full() external skipOnMismatch givenNFTExists {
        string memory actualTokenURI = lockupDynamic.tokenURI(defaultStreamId);
        string memory expectedTokenURI =
            "data:application/json;base64,eyJhdHRyaWJ1dGVzIjpbeyJ0cmFpdF90eXBlIjoiQXNzZXQiLCJ2YWx1ZSI6IkRBSSJ9LHsidHJhaXRfdHlwZSI6IlNlbmRlciIsInZhbHVlIjoiMHg2MzMyZTdiMWRlYjFmMWEwYjc3YjJiYjE4YjE0NDMzMGM3MjkxYmNhIn0seyJ0cmFpdF90eXBlIjoiU3RhdHVzIiwidmFsdWUiOiJTdHJlYW1pbmcifV0sImRlc2NyaXB0aW9uIjoiVGhpcyBORlQgcmVwcmVzZW50cyBhIHBheW1lbnQgc3RyZWFtIGluIGEgU2FibGllciBWMiBMb2NrdXAgRHluYW1pYyBjb250cmFjdC4gVGhlIG93bmVyIG9mIHRoaXMgTkZUIGNhbiB3aXRoZHJhdyB0aGUgc3RyZWFtZWQgYXNzZXRzLCB3aGljaCBhcmUgZGVub21pbmF0ZWQgaW4gREFJLlxuXG4tIFN0cmVhbSBJRDogMVxuLSBMb2NrdXAgRHluYW1pYyBBZGRyZXNzOiAweGRiMjVhN2I3NjgzMTFkZTEyOGJiZGE3Yjg0MjZjM2Y5Yzc0ZjMyNDBcbi0gREFJIEFkZHJlc3M6IDB4MDNhNmE4NGNkNzYyZDk3MDdhMjE2MDViNTQ4YWFhYjg5MTU2MmFhYlxuXG7imqDvuI8gV0FSTklORzogVHJhbnNmZXJyaW5nIHRoZSBORlQgbWFrZXMgdGhlIG5ldyBvd25lciB0aGUgcmVjaXBpZW50IG9mIHRoZSBzdHJlYW0uIFRoZSBmdW5kcyBhcmUgbm90IGF1dG9tYXRpY2FsbHkgd2l0aGRyYXduIGZvciB0aGUgcHJldmlvdXMgcmVjaXBpZW50LiIsImV4dGVybmFsX3VybCI6Imh0dHBzOi8vc2FibGllci5jb20iLCJuYW1lIjoiU2FibGllciBWMiBMb2NrdXAgRHluYW1pYyAjMSIsImltYWdlIjoiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCNGJXeHVjejBpYUhSMGNEb3ZMM2QzZHk1M015NXZjbWN2TWpBd01DOXpkbWNpSUhkcFpIUm9QU0l4TURBd0lpQm9aV2xuYUhROUlqRXdNREFpSUhacFpYZENiM2c5SWpBZ01DQXhNREF3SURFd01EQWlQanh5WldOMElIZHBaSFJvUFNJeE1EQWxJaUJvWldsbmFIUTlJakV3TUNVaUlHWnBiSFJsY2owaWRYSnNLQ05PYjJselpTa2lMejQ4Y21WamRDQjRQU0kzTUNJZ2VUMGlOekFpSUhkcFpIUm9QU0k0TmpBaUlHaGxhV2RvZEQwaU9EWXdJaUJtYVd4c1BTSWpabVptSWlCbWFXeHNMVzl3WVdOcGRIazlJaTR3TXlJZ2NuZzlJalExSWlCeWVUMGlORFVpSUhOMGNtOXJaVDBpSTJabVppSWdjM1J5YjJ0bExXOXdZV05wZEhrOUlpNHhJaUJ6ZEhKdmEyVXRkMmxrZEdnOUlqUWlMejQ4WkdWbWN6NDhZMmx5WTJ4bElHbGtQU0pIYkc5M0lpQnlQU0kxTURBaUlHWnBiR3c5SW5WeWJDZ2pVbUZrYVdGc1IyeHZkeWtpTHo0OFptbHNkR1Z5SUdsa1BTSk9iMmx6WlNJK1BHWmxSbXh2YjJRZ2VEMGlNQ0lnZVQwaU1DSWdkMmxrZEdnOUlqRXdNQ1VpSUdobGFXZG9kRDBpTVRBd0pTSWdabXh2YjJRdFkyOXNiM0k5SW1oemJDZ3lNekFzTWpFbExERXhKU2tpSUdac2IyOWtMVzl3WVdOcGRIazlJakVpSUhKbGMzVnNkRDBpWm14dmIyUkdhV3hzSWk4K1BHWmxWSFZ5WW5Wc1pXNWpaU0JpWVhObFJuSmxjWFZsYm1ONVBTSXVOQ0lnYm5WdFQyTjBZWFpsY3owaU15SWdjbVZ6ZFd4MFBTSk9iMmx6WlNJZ2RIbHdaVDBpWm5KaFkzUmhiRTV2YVhObElpOCtQR1psUW14bGJtUWdhVzQ5SWs1dmFYTmxJaUJwYmpJOUltWnNiMjlrUm1sc2JDSWdiVzlrWlQwaWMyOW1kQzFzYVdkb2RDSXZQand2Wm1sc2RHVnlQanh3WVhSb0lHbGtQU0pNYjJkdklpQm1hV3hzUFNJalptWm1JaUJtYVd4c0xXOXdZV05wZEhrOUlpNHhJaUJrUFNKdE1UTXpMalUxT1N3eE1qUXVNRE0wWXkwdU1ERXpMREl1TkRFeUxURXVNRFU1TERRdU9EUTRMVEl1T1RJekxEWXVOREF5TFRJdU5UVTRMREV1T0RFNUxUVXVNVFk0TERNdU5ETTVMVGN1T0RnNExEUXVPVGsyTFRFMExqUTBMRGd1TWpZeUxUTXhMakEwTnl3eE1pNDFOalV0TkRjdU5qYzBMREV5TGpVMk9TMDRMamcxT0M0d016WXRNVGN1T0RNNExURXVNamN5TFRJMkxqTXlPQzB6TGpZMk15MDVMamd3TmkweUxqYzJOaTB4T1M0d09EY3ROeTR4TVRNdE1qY3VOVFl5TFRFeUxqYzNPQzB4TXk0NE5ESXRPQzR3TWpVc09TNDBOamd0TWpndU5qQTJMREUyTGpFMU15MHpOUzR5TmpWb01HTXlMakF6TlMweExqZ3pPQ3cwTGpJMU1pMHpMalUwTml3MkxqUTJNeTAxTGpJeU5HZ3dZell1TkRJNUxUVXVOalUxTERFMkxqSXhPQzB5TGpnek5Td3lNQzR6TlRnc05DNHhOeXcwTGpFME15dzFMakExTnl3NExqZ3hOaXc1TGpZME9Td3hNeTQ1TWl3eE15NDNNelJvTGpBek4yTTFMamN6Tml3MkxqUTJNU3d4TlM0ek5UY3RNaTR5TlRNc09TNHpPQzA0TGpRNExEQXNNQzB6TGpVeE5TMHpMalV4TlMwekxqVXhOUzB6TGpVeE5TMHhNUzQwT1MweE1TNDBOemd0TlRJdU5qVTJMVFV5TGpZMk5DMDJOQzQ0TXpjdE5qUXVPRE0zYkM0d05Ea3RMakF6TjJNdE1TNDNNalV0TVM0Mk1EWXRNaTQzTVRrdE15NDRORGN0TWk0M05URXROaTR5TURSb01HTXRMakEwTmkweUxqTTNOU3d4TGpBMk1pMDBMalU0TWl3eUxqY3lOaTAyTGpJeU9XZ3diQzR4T0RVdExqRTBPR2d3WXk0d09Ua3RMakEyTWl3dU1qSXlMUzR4TkRnc0xqTTNMUzR5TlRsb01HTXlMakEyTFRFdU16WXlMRE11T1RVeExUSXVOakl4TERZdU1EUTBMVE11T0RReVF6VTNMamMyTXkwekxqUTNNeXc1Tnk0M05pMHlMak0wTVN3eE1qZ3VOak0zTERFNExqTXpNbU14Tmk0Mk56RXNPUzQ1TkRZdE1qWXVNelEwTERVMExqZ3hNeTB6T0M0Mk5URXNOREF1TVRrNUxUWXVNams1TFRZdU1EazJMVEU0TGpBMk15MHhOeTQzTkRNdE1Ua3VOalk0TFRFNExqZ3hNUzAyTGpBeE5pMDBMakEwTnkweE15NHdOakVzTkM0M056WXROeTQzTlRJc09TNDNOVEZzTmpndU1qVTBMRFk0TGpNM01XTXhMamN5TkN3eExqWXdNU3d5TGpjeE5Dd3pMamcwTERJdU56TTRMRFl1TVRreVdpSXZQanh3WVhSb0lHbGtQU0pHYkc5aGRHbHVaMVJsZUhRaUlHWnBiR3c5SW01dmJtVWlJR1E5SWsweE1qVWdORFZvTnpVd2N6Z3dJREFnT0RBZ09EQjJOelV3Y3pBZ09EQWdMVGd3SURnd2FDMDNOVEJ6TFRnd0lEQWdMVGd3SUMwNE1IWXROelV3Y3pBZ0xUZ3dJRGd3SUMwNE1DSXZQanh5WVdScFlXeEhjbUZrYVdWdWRDQnBaRDBpVW1Ga2FXRnNSMnh2ZHlJK1BITjBiM0FnYjJabWMyVjBQU0l3SlNJZ2MzUnZjQzFqYjJ4dmNqMGlhSE5zS0RZeExEZzRKU3cwTUNVcElpQnpkRzl3TFc5d1lXTnBkSGs5SWk0MklpOCtQSE4wYjNBZ2IyWm1jMlYwUFNJeE1EQWxJaUJ6ZEc5d0xXTnZiRzl5UFNKb2Myd29Nak13TERJeEpTd3hNU1VwSWlCemRHOXdMVzl3WVdOcGRIazlJakFpTHo0OEwzSmhaR2xoYkVkeVlXUnBaVzUwUGp4c2FXNWxZWEpIY21Ga2FXVnVkQ0JwWkQwaVUyRnVaRlJ2Y0NJZ2VERTlJakFsSWlCNU1UMGlNQ1VpUGp4emRHOXdJRzltWm5ObGREMGlNQ1VpSUhOMGIzQXRZMjlzYjNJOUltaHpiQ2cyTVN3NE9DVXNOREFsS1NJdlBqeHpkRzl3SUc5bVpuTmxkRDBpTVRBd0pTSWdjM1J2Y0MxamIyeHZjajBpYUhOc0tESXpNQ3d5TVNVc01URWxLU0l2UGp3dmJHbHVaV0Z5UjNKaFpHbGxiblErUEd4cGJtVmhja2R5WVdScFpXNTBJR2xrUFNKVFlXNWtRbTkwZEc5dElpQjRNVDBpTVRBd0pTSWdlVEU5SWpFd01DVWlQanh6ZEc5d0lHOW1abk5sZEQwaU1UQWxJaUJ6ZEc5d0xXTnZiRzl5UFNKb2Myd29Nak13TERJeEpTd3hNU1VwSWk4K1BITjBiM0FnYjJabWMyVjBQU0l4TURBbElpQnpkRzl3TFdOdmJHOXlQU0pvYzJ3b05qRXNPRGdsTERRd0pTa2lMejQ4WVc1cGJXRjBaU0JoZEhSeWFXSjFkR1ZPWVcxbFBTSjRNU0lnWkhWeVBTSTJjeUlnY21Wd1pXRjBRMjkxYm5ROUltbHVaR1ZtYVc1cGRHVWlJSFpoYkhWbGN6MGlNekFsT3pZd0pUc3hNakFsT3pZd0pUc3pNQ1U3SWk4K1BDOXNhVzVsWVhKSGNtRmthV1Z1ZEQ0OGJHbHVaV0Z5UjNKaFpHbGxiblFnYVdROUlraHZkWEpuYkdGemMxTjBjbTlyWlNJZ1ozSmhaR2xsYm5SVWNtRnVjMlp2Y20wOUluSnZkR0YwWlNnNU1Da2lJR2R5WVdScFpXNTBWVzVwZEhNOUluVnpaWEpUY0dGalpVOXVWWE5sSWo0OGMzUnZjQ0J2Wm1aelpYUTlJalV3SlNJZ2MzUnZjQzFqYjJ4dmNqMGlhSE5zS0RZeExEZzRKU3cwTUNVcElpOCtQSE4wYjNBZ2IyWm1jMlYwUFNJNE1DVWlJSE4wYjNBdFkyOXNiM0k5SW1oemJDZ3lNekFzTWpFbExERXhKU2tpTHo0OEwyeHBibVZoY2tkeVlXUnBaVzUwUGp4bklHbGtQU0pJYjNWeVoyeGhjM01pUGp4d1lYUm9JR1E5SWswZ05UQXNNell3SUdFZ016QXdMRE13TUNBd0lERXNNU0EyTURBc01DQmhJRE13TUN3ek1EQWdNQ0F4TERFZ0xUWXdNQ3d3SWlCbWFXeHNQU0lqWm1abUlpQm1hV3hzTFc5d1lXTnBkSGs5SWk0d01pSWdjM1J5YjJ0bFBTSjFjbXdvSTBodmRYSm5iR0Z6YzFOMGNtOXJaU2tpSUhOMGNtOXJaUzEzYVdSMGFEMGlOQ0l2UGp4d1lYUm9JR1E5SW0wMU5qWXNNVFl4TGpJd01YWXROVE11T1RJMFl6QXRNVGt1TXpneUxUSXlMalV4TXkwek55NDFOak10TmpNdU16azRMVFV4TGpFNU9DMDBNQzQzTlRZdE1UTXVOVGt5TFRrMExqazBOaTB5TVM0d056a3RNVFV5TGpVNE55MHlNUzR3TnpsekxURXhNUzQ0TXpnc055NDBPRGN0TVRVeUxqWXdNaXd5TVM0d056bGpMVFF3TGpnNU15d3hNeTQyTXpZdE5qTXVOREV6TERNeExqZ3hOaTAyTXk0ME1UTXNOVEV1TVRrNGRqVXpMamt5TkdNd0xERTNMakU0TVN3eE55NDNNRFFzTXpNdU5ESTNMRFV3TGpJeU15dzBOaTR6T1RSMk1qZzBMamd3T1dNdE16SXVOVEU1TERFeUxqazJMVFV3TGpJeU15d3lPUzR5TURZdE5UQXVNakl6TERRMkxqTTVOSFkxTXk0NU1qUmpNQ3d4T1M0ek9ESXNNakl1TlRJc016Y3VOVFl6TERZekxqUXhNeXcxTVM0eE9UZ3NOREF1TnpZekxERXpMalU1TWl3NU5DNDVOVFFzTWpFdU1EYzVMREUxTWk0Mk1ESXNNakV1TURjNWN6RXhNUzQ0TXpFdE55NDBPRGNzTVRVeUxqVTROeTB5TVM0d056bGpOREF1T0RnMkxURXpMall6Tml3Mk15NHpPVGd0TXpFdU9ERTJMRFl6TGpNNU9DMDFNUzR4T1RoMkxUVXpMamt5TkdNd0xURTNMakU1TmkweE55NDNNRFF0TXpNdU5ETTFMVFV3TGpJeU15MDBOaTQwTURGV01qQTNMall3TTJNek1pNDFNVGt0TVRJdU9UWTNMRFV3TGpJeU15MHlPUzR5TURZc05UQXVNakl6TFRRMkxqUXdNVnB0TFRNME55NDBOaklzTlRjdU56a3piREV6TUM0NU5Ua3NNVE14TGpBeU55MHhNekF1T1RVNUxERXpNUzR3TVROV01qRTRMams1TkZwdE1qWXlMamt5TkM0d01qSjJNall5TGpBeE9Hd3RNVE13TGprek55MHhNekV1TURBMkxERXpNQzQ1TXpjdE1UTXhMakF4TTFvaUlHWnBiR3c5SWlNeE5qRTRNaklpUGp3dmNHRjBhRDQ4Y0c5c2VXZHZiaUJ3YjJsdWRITTlJak0xTUNBek5UQXVNREkySURReE5TNHdNeUF5T0RRdU9UYzRJREk0TlNBeU9EUXVPVGM0SURNMU1DQXpOVEF1TURJMklpQm1hV3hzUFNKMWNtd29JMU5oYm1SQ2IzUjBiMjBwSWk4K1BIQmhkR2dnWkQwaWJUUXhOaTR6TkRFc01qZ3hMamszTldNd0xDNDVNVFF0TGpNMU5Dd3hMamd3T1MweExqQXpOU3d5TGpZNExUVXVOVFF5TERjdU1EYzJMVE15TGpZMk1Td3hNaTQwTlMwMk5TNHlPQ3d4TWk0ME5TMHpNaTQyTWpRc01DMDFPUzQzTXpndE5TNHpOelF0TmpVdU1qZ3RNVEl1TkRVdExqWTRNUzB1T0RjeUxURXVNRE0xTFRFdU56WTNMVEV1TURNMUxUSXVOamdzTUMwdU9URTBMak0xTkMweExqZ3dPQ3d4TGpBek5TMHlMalkzTml3MUxqVTBNaTAzTGpBM05pd3pNaTQyTlRZdE1USXVORFVzTmpVdU1qZ3RNVEl1TkRVc016SXVOakU1TERBc05Ua3VOek00TERVdU16YzBMRFkxTGpJNExERXlMalExTGpZNE1TNDROamNzTVM0d016VXNNUzQzTmpJc01TNHdNelVzTWk0Mk56WmFJaUJtYVd4c1BTSjFjbXdvSTFOaGJtUlViM0FwSWk4K1BIQmhkR2dnWkQwaWJUUTRNUzQwTml3MU1EUXVNVEF4ZGpVNExqUTBPV010TWk0ek5TNDNOeTAwTGpneUxERXVOVEV0Tnk0ek9Td3lMakl6TFRNd0xqTXNPQzQxTkMwM05DNDJOU3d4TXk0NU1pMHhNalF1TURZc01UTXVPVEl0TlRNdU5pd3dMVEV3TVM0eU5DMDJMak16TFRFek1TNDBOeTB4Tmk0eE5uWXROVGd1TkRNNWFESTJNaTQ1TWxvaUlHWnBiR3c5SW5WeWJDZ2pVMkZ1WkVKdmRIUnZiU2tpTHo0OFpXeHNhWEJ6WlNCamVEMGlNelV3SWlCamVUMGlOVEEwTGpFd01TSWdjbmc5SWpFek1TNDBOaklpSUhKNVBTSXlPQzR4TURnaUlHWnBiR3c5SW5WeWJDZ2pVMkZ1WkZSdmNDa2lMejQ4WnlCbWFXeHNQU0p1YjI1bElpQnpkSEp2YTJVOUluVnliQ2dqU0c5MWNtZHNZWE56VTNSeWIydGxLU0lnYzNSeWIydGxMV3hwYm1WallYQTlJbkp2ZFc1a0lpQnpkSEp2YTJVdGJXbDBaWEpzYVcxcGREMGlNVEFpSUhOMGNtOXJaUzEzYVdSMGFEMGlOQ0krUEhCaGRHZ2daRDBpYlRVMk5TNDJOREVzTVRBM0xqSTRZekFzT1M0MU16Y3ROUzQxTml3eE9DNDJNamt0TVRVdU5qYzJMREkyTGprM00yZ3RMakF5TTJNdE9TNHlNRFFzTnk0MU9UWXRNakl1TVRrMExERTBMalUyTWkwek9DNHhPVGNzTWpBdU5Ua3lMVE01TGpVd05Dd3hOQzQ1TXpZdE9UY3VNekkxTERJMExqTTFOUzB4TmpFdU56TXpMREkwTGpNMU5TMDVNQzQwT0N3d0xURTJOeTQ1TkRndE1UZ3VOVGd5TFRFNU9TNDVOVE10TkRRdU9UUTRhQzB1TURJell5MHhNQzR4TVRVdE9DNHpORFF0TVRVdU5qYzJMVEUzTGpRek55MHhOUzQyTnpZdE1qWXVPVGN6TERBdE16a3VOek0xTERrMkxqVTFOQzAzTVM0NU1qRXNNakUxTGpZMU1pMDNNUzQ1TWpGek1qRTFMall5T1N3ek1pNHhPRFVzTWpFMUxqWXlPU3czTVM0NU1qRmFJaTgrUEhCaGRHZ2daRDBpYlRFek5DNHpOaXd4TmpFdU1qQXpZekFzTXprdU56TTFMRGsyTGpVMU5DdzNNUzQ1TWpFc01qRTFMalkxTWl3M01TNDVNakZ6TWpFMUxqWXlPUzB6TWk0eE9EWXNNakUxTGpZeU9TMDNNUzQ1TWpFaUx6NDhiR2x1WlNCNE1UMGlNVE0wTGpNMklpQjVNVDBpTVRZeExqSXdNeUlnZURJOUlqRXpOQzR6TmlJZ2VUSTlJakV3Tnk0eU9DSXZQanhzYVc1bElIZ3hQU0kxTmpVdU5qUWlJSGt4UFNJeE5qRXVNakF6SWlCNE1qMGlOVFkxTGpZMElpQjVNajBpTVRBM0xqSTRJaTgrUEd4cGJtVWdlREU5SWpFNE5DNDFPRFFpSUhreFBTSXlNRFl1T0RJeklpQjRNajBpTVRnMExqVTROU0lnZVRJOUlqVXpOeTQxTnpraUx6NDhiR2x1WlNCNE1UMGlNakU0TGpFNE1TSWdlVEU5SWpJeE9DNHhNVGdpSUhneVBTSXlNVGd1TVRneElpQjVNajBpTlRZeUxqVXpOeUl2UGp4c2FXNWxJSGd4UFNJME9ERXVPREU0SWlCNU1UMGlNakU0TGpFME1pSWdlREk5SWpRNE1TNDRNVGtpSUhreVBTSTFOakl1TkRJNElpOCtQR3hwYm1VZ2VERTlJalV4TlM0ME1UVWlJSGt4UFNJeU1EY3VNelV5SWlCNE1qMGlOVEUxTGpReE5pSWdlVEk5SWpVek55NDFOemtpTHo0OGNHRjBhQ0JrUFNKdE1UZzBMalU0TERVek55NDFPR013TERVdU5EVXNOQzR5Tnl3eE1DNDJOU3d4TWk0d015d3hOUzQwTW1ndU1ESmpOUzQxTVN3ekxqTTVMREV5TGpjNUxEWXVOVFVzTWpFdU5UVXNPUzQwTWl3ek1DNHlNU3c1TGprc056Z3VNRElzTVRZdU1qZ3NNVE14TGpnekxERTJMakk0TERRNUxqUXhMREFzT1RNdU56WXROUzR6T0N3eE1qUXVNRFl0TVRNdU9USXNNaTQzTFM0M05pdzFMakk1TFRFdU5UUXNOeTQzTlMweUxqTTFMRGd1TnpjdE1pNDROeXd4Tmk0d05TMDJMakEwTERJeExqVTJMVGt1TkROb01HTTNMamMyTFRRdU56Y3NNVEl1TURRdE9TNDVOeXd4TWk0d05DMHhOUzQwTWlJdlBqeHdZWFJvSUdROUltMHhPRFF1TlRneUxEUTVNaTQyTlRaakxUTXhMak0xTkN3eE1pNDBPRFV0TlRBdU1qSXpMREk0TGpVNExUVXdMakl5TXl3ME5pNHhORElzTUN3NUxqVXpOaXcxTGpVMk5Dd3hPQzQyTWpjc01UVXVOamMzTERJMkxqazJPV2d1TURJeVl6Z3VOVEF6TERjdU1EQTFMREl3TGpJeE15d3hNeTQwTmpNc016UXVOVEkwTERFNUxqRTFPU3c1TGprNU9Td3pMams1TVN3eU1TNHlOamtzTnk0Mk1Ea3NNek11TlRrM0xERXdMamM0T0N3ek5pNDBOU3c1TGpRd055dzRNaTR4T0RFc01UVXVNREF5TERFek1TNDRNelVzTVRVdU1EQXljemsxTGpNMk15MDFMalU1TlN3eE16RXVPREEzTFRFMUxqQXdNbU14TUM0NE5EY3RNaTQzT1N3eU1DNDROamN0TlM0NU1qWXNNamt1T1RJMExUa3VNelE1TERFdU1qUTBMUzQwTmpjc01pNDBOek10TGprME1pd3pMalkzTXkweExqUXlOQ3d4TkM0ek1qWXROUzQyT1RZc01qWXVNRE0xTFRFeUxqRTJNU3d6TkM0MU1qUXRNVGt1TVRjemFDNHdNakpqTVRBdU1URTBMVGd1TXpReUxERTFMalkzTnkweE55NDBNek1zTVRVdU5qYzNMVEkyTGprMk9Td3dMVEUzTGpVMk1pMHhPQzQ0TmprdE16TXVOalkxTFRVd0xqSXlNeTAwTmk0eE5TSXZQanh3WVhSb0lHUTlJbTB4TXpRdU16WXNOVGt5TGpjeVl6QXNNemt1TnpNMUxEazJMalUxTkN3M01TNDVNakVzTWpFMUxqWTFNaXczTVM0NU1qRnpNakUxTGpZeU9TMHpNaTR4T0RZc01qRTFMall5T1MwM01TNDVNakVpTHo0OGJHbHVaU0I0TVQwaU1UTTBMak0ySWlCNU1UMGlOVGt5TGpjeUlpQjRNajBpTVRNMExqTTJJaUI1TWowaU5UTTRMamM1TnlJdlBqeHNhVzVsSUhneFBTSTFOalV1TmpRaUlIa3hQU0kxT1RJdU56SWlJSGd5UFNJMU5qVXVOalFpSUhreVBTSTFNemd1TnprM0lpOCtQSEJ2Ykhsc2FXNWxJSEJ2YVc1MGN6MGlORGd4TGpneU1pQTBPREV1T1RBeElEUTRNUzQzT1RnZ05EZ3hMamczTnlBME9ERXVOemMxSURRNE1TNDROVFFnTXpVd0xqQXhOU0F6TlRBdU1ESTJJREl4T0M0eE9EVWdNakU0TGpFeU9TSXZQanh3YjJ4NWJHbHVaU0J3YjJsdWRITTlJakl4T0M0eE9EVWdORGd4TGprd01TQXlNVGd1TWpNeElEUTRNUzQ0TlRRZ016VXdMakF4TlNBek5UQXVNREkySURRNE1TNDRNaklnTWpFNExqRTFNaUl2UGp3dlp6NDhMMmMrUEdjZ2FXUTlJbEJ5YjJkeVpYTnpJaUJtYVd4c1BTSWpabVptSWo0OGNtVmpkQ0IzYVdSMGFEMGlNakE0SWlCb1pXbG5hSFE5SWpFd01DSWdabWxzYkMxdmNHRmphWFI1UFNJdU1ETWlJSEo0UFNJeE5TSWdjbms5SWpFMUlpQnpkSEp2YTJVOUlpTm1abVlpSUhOMGNtOXJaUzF2Y0dGamFYUjVQU0l1TVNJZ2MzUnliMnRsTFhkcFpIUm9QU0kwSWk4K1BIUmxlSFFnZUQwaU1qQWlJSGs5SWpNMElpQm1iMjUwTFdaaGJXbHNlVDBpSjBOdmRYSnBaWElnVG1WM0p5eEJjbWxoYkN4dGIyNXZjM0JoWTJVaUlHWnZiblF0YzJsNlpUMGlNakp3ZUNJK1VISnZaM0psYzNNOEwzUmxlSFErUEhSbGVIUWdlRDBpTWpBaUlIazlJamN5SWlCbWIyNTBMV1poYldsc2VUMGlKME52ZFhKcFpYSWdUbVYzSnl4QmNtbGhiQ3h0YjI1dmMzQmhZMlVpSUdadmJuUXRjMmw2WlQwaU1qWndlQ0krTWpVbFBDOTBaWGgwUGp4bklHWnBiR3c5SW01dmJtVWlQanhqYVhKamJHVWdZM2c5SWpFMk5pSWdZM2s5SWpVd0lpQnlQU0l5TWlJZ2MzUnliMnRsUFNKb2Myd29Nak13TERJeEpTd3hNU1VwSWlCemRISnZhMlV0ZDJsa2RHZzlJakV3SWk4K1BHTnBjbU5zWlNCamVEMGlNVFkySWlCamVUMGlOVEFpSUhCaGRHaE1aVzVuZEdnOUlqRXdNREF3SWlCeVBTSXlNaUlnYzNSeWIydGxQU0pvYzJ3b05qRXNPRGdsTERRd0pTa2lJSE4wY205clpTMWtZWE5vWVhKeVlYazlJakV3TURBd0lpQnpkSEp2YTJVdFpHRnphRzltWm5ObGREMGlOelV3TUNJZ2MzUnliMnRsTFd4cGJtVmpZWEE5SW5KdmRXNWtJaUJ6ZEhKdmEyVXRkMmxrZEdnOUlqVWlJSFJ5WVc1elptOXliVDBpY205MFlYUmxLQzA1TUNraUlIUnlZVzV6Wm05eWJTMXZjbWxuYVc0OUlqRTJOaUExTUNJdlBqd3ZaejQ4TDJjK1BHY2dhV1E5SWxOMFlYUjFjeUlnWm1sc2JEMGlJMlptWmlJK1BISmxZM1FnZDJsa2RHZzlJakU0TkNJZ2FHVnBaMmgwUFNJeE1EQWlJR1pwYkd3dGIzQmhZMmwwZVQwaUxqQXpJaUJ5ZUQwaU1UVWlJSEo1UFNJeE5TSWdjM1J5YjJ0bFBTSWpabVptSWlCemRISnZhMlV0YjNCaFkybDBlVDBpTGpFaUlITjBjbTlyWlMxM2FXUjBhRDBpTkNJdlBqeDBaWGgwSUhnOUlqSXdJaUI1UFNJek5DSWdabTl1ZEMxbVlXMXBiSGs5SWlkRGIzVnlhV1Z5SUU1bGR5Y3NRWEpwWVd3c2JXOXViM053WVdObElpQm1iMjUwTFhOcGVtVTlJakl5Y0hnaVBsTjBZWFIxY3p3dmRHVjRkRDQ4ZEdWNGRDQjRQU0l5TUNJZ2VUMGlOeklpSUdadmJuUXRabUZ0YVd4NVBTSW5RMjkxY21sbGNpQk9aWGNuTEVGeWFXRnNMRzF2Ym05emNHRmpaU0lnWm05dWRDMXphWHBsUFNJeU5uQjRJajVUZEhKbFlXMXBibWM4TDNSbGVIUStQQzluUGp4bklHbGtQU0pCYlc5MWJuUWlJR1pwYkd3OUlpTm1abVlpUGp4eVpXTjBJSGRwWkhSb1BTSXhNakFpSUdobGFXZG9kRDBpTVRBd0lpQm1hV3hzTFc5d1lXTnBkSGs5SWk0d015SWdjbmc5SWpFMUlpQnllVDBpTVRVaUlITjBjbTlyWlQwaUkyWm1aaUlnYzNSeWIydGxMVzl3WVdOcGRIazlJaTR4SWlCemRISnZhMlV0ZDJsa2RHZzlJalFpTHo0OGRHVjRkQ0I0UFNJeU1DSWdlVDBpTXpRaUlHWnZiblF0Wm1GdGFXeDVQU0luUTI5MWNtbGxjaUJPWlhjbkxFRnlhV0ZzTEcxdmJtOXpjR0ZqWlNJZ1ptOXVkQzF6YVhwbFBTSXlNbkI0SWo1QmJXOTFiblE4TDNSbGVIUStQSFJsZUhRZ2VEMGlNakFpSUhrOUlqY3lJaUJtYjI1MExXWmhiV2xzZVQwaUowTnZkWEpwWlhJZ1RtVjNKeXhCY21saGJDeHRiMjV2YzNCaFkyVWlJR1p2Ym5RdGMybDZaVDBpTWpad2VDSStKaU00T0RBMU95QXhNRXM4TDNSbGVIUStQQzluUGp4bklHbGtQU0pFZFhKaGRHbHZiaUlnWm1sc2JEMGlJMlptWmlJK1BISmxZM1FnZDJsa2RHZzlJakUxTWlJZ2FHVnBaMmgwUFNJeE1EQWlJR1pwYkd3dGIzQmhZMmwwZVQwaUxqQXpJaUJ5ZUQwaU1UVWlJSEo1UFNJeE5TSWdjM1J5YjJ0bFBTSWpabVptSWlCemRISnZhMlV0YjNCaFkybDBlVDBpTGpFaUlITjBjbTlyWlMxM2FXUjBhRDBpTkNJdlBqeDBaWGgwSUhnOUlqSXdJaUI1UFNJek5DSWdabTl1ZEMxbVlXMXBiSGs5SWlkRGIzVnlhV1Z5SUU1bGR5Y3NRWEpwWVd3c2JXOXViM053WVdObElpQm1iMjUwTFhOcGVtVTlJakl5Y0hnaVBrUjFjbUYwYVc5dVBDOTBaWGgwUGp4MFpYaDBJSGc5SWpJd0lpQjVQU0kzTWlJZ1ptOXVkQzFtWVcxcGJIazlJaWREYjNWeWFXVnlJRTVsZHljc1FYSnBZV3dzYlc5dWIzTndZV05sSWlCbWIyNTBMWE5wZW1VOUlqSTJjSGdpUGlac2REc2dNU0JFWVhrOEwzUmxlSFErUEM5blBqd3ZaR1ZtY3o0OGRHVjRkQ0IwWlhoMExYSmxibVJsY21sdVp6MGliM0IwYVcxcGVtVlRjR1ZsWkNJK1BIUmxlSFJRWVhSb0lITjBZWEowVDJabWMyVjBQU0l0TVRBd0pTSWdhSEpsWmowaUkwWnNiMkYwYVc1blZHVjRkQ0lnWm1sc2JEMGlJMlptWmlJZ1ptOXVkQzFtWVcxcGJIazlJaWREYjNWeWFXVnlJRTVsZHljc1FYSnBZV3dzYlc5dWIzTndZV05sSWlCbWFXeHNMVzl3WVdOcGRIazlJaTQ0SWlCbWIyNTBMWE5wZW1VOUlqSTJjSGdpUGp4aGJtbHRZWFJsSUdGa1pHbDBhWFpsUFNKemRXMGlJR0YwZEhKcFluVjBaVTVoYldVOUluTjBZWEowVDJabWMyVjBJaUJpWldkcGJqMGlNSE1pSUdSMWNqMGlOVEJ6SWlCbWNtOXRQU0l3SlNJZ2NtVndaV0YwUTI5MWJuUTlJbWx1WkdWbWFXNXBkR1VpSUhSdlBTSXhNREFsSWk4K01IaGtZakkxWVRkaU56WTRNekV4WkdVeE1qaGlZbVJoTjJJNE5ESTJZek5tT1dNM05HWXpNalF3SU9LQW9pQlRZV0pzYVdWeUlGWXlJRXh2WTJ0MWNDQkVlVzVoYldsalBDOTBaWGgwVUdGMGFENDhkR1Y0ZEZCaGRHZ2djM1JoY25SUFptWnpaWFE5SWpBbElpQm9jbVZtUFNJalJteHZZWFJwYm1kVVpYaDBJaUJtYVd4c1BTSWpabVptSWlCbWIyNTBMV1poYldsc2VUMGlKME52ZFhKcFpYSWdUbVYzSnl4QmNtbGhiQ3h0YjI1dmMzQmhZMlVpSUdacGJHd3RiM0JoWTJsMGVUMGlMamdpSUdadmJuUXRjMmw2WlQwaU1qWndlQ0krUEdGdWFXMWhkR1VnWVdSa2FYUnBkbVU5SW5OMWJTSWdZWFIwY21saWRYUmxUbUZ0WlQwaWMzUmhjblJQWm1aelpYUWlJR0psWjJsdVBTSXdjeUlnWkhWeVBTSTFNSE1pSUdaeWIyMDlJakFsSWlCeVpYQmxZWFJEYjNWdWREMGlhVzVrWldacGJtbDBaU0lnZEc4OUlqRXdNQ1VpTHo0d2VHUmlNalZoTjJJM05qZ3pNVEZrWlRFeU9HSmlaR0UzWWpnME1qWmpNMlk1WXpjMFpqTXlOREFnNG9DaUlGTmhZbXhwWlhJZ1ZqSWdURzlqYTNWd0lFUjVibUZ0YVdNOEwzUmxlSFJRWVhSb1BqeDBaWGgwVUdGMGFDQnpkR0Z5ZEU5bVpuTmxkRDBpTFRVd0pTSWdhSEpsWmowaUkwWnNiMkYwYVc1blZHVjRkQ0lnWm1sc2JEMGlJMlptWmlJZ1ptOXVkQzFtWVcxcGJIazlJaWREYjNWeWFXVnlJRTVsZHljc1FYSnBZV3dzYlc5dWIzTndZV05sSWlCbWFXeHNMVzl3WVdOcGRIazlJaTQ0SWlCbWIyNTBMWE5wZW1VOUlqSTJjSGdpUGp4aGJtbHRZWFJsSUdGa1pHbDBhWFpsUFNKemRXMGlJR0YwZEhKcFluVjBaVTVoYldVOUluTjBZWEowVDJabWMyVjBJaUJpWldkcGJqMGlNSE1pSUdSMWNqMGlOVEJ6SWlCbWNtOXRQU0l3SlNJZ2NtVndaV0YwUTI5MWJuUTlJbWx1WkdWbWFXNXBkR1VpSUhSdlBTSXhNREFsSWk4K01IZ3dNMkUyWVRnMFkyUTNOakprT1Rjd04yRXlNVFl3TldJMU5EaGhZV0ZpT0RreE5UWXlZV0ZpSU9LQW9pQkVRVWs4TDNSbGVIUlFZWFJvUGp4MFpYaDBVR0YwYUNCemRHRnlkRTltWm5ObGREMGlOVEFsSWlCb2NtVm1QU0lqUm14dllYUnBibWRVWlhoMElpQm1hV3hzUFNJalptWm1JaUJtYjI1MExXWmhiV2xzZVQwaUowTnZkWEpwWlhJZ1RtVjNKeXhCY21saGJDeHRiMjV2YzNCaFkyVWlJR1pwYkd3dGIzQmhZMmwwZVQwaUxqZ2lJR1p2Ym5RdGMybDZaVDBpTWpad2VDSStQR0Z1YVcxaGRHVWdZV1JrYVhScGRtVTlJbk4xYlNJZ1lYUjBjbWxpZFhSbFRtRnRaVDBpYzNSaGNuUlBabVp6WlhRaUlHSmxaMmx1UFNJd2N5SWdaSFZ5UFNJMU1ITWlJR1p5YjIwOUlqQWxJaUJ5WlhCbFlYUkRiM1Z1ZEQwaWFXNWtaV1pwYm1sMFpTSWdkRzg5SWpFd01DVWlMejR3ZURBellUWmhPRFJqWkRjMk1tUTVOekEzWVRJeE5qQTFZalUwT0dGaFlXSTRPVEUxTmpKaFlXSWc0b0NpSUVSQlNUd3ZkR1Y0ZEZCaGRHZytQQzkwWlhoMFBqeDFjMlVnYUhKbFpqMGlJMGRzYjNjaUlHWnBiR3d0YjNCaFkybDBlVDBpTGpraUx6NDhkWE5sSUdoeVpXWTlJaU5IYkc5M0lpQjRQU0l4TURBd0lpQjVQU0l4TURBd0lpQm1hV3hzTFc5d1lXTnBkSGs5SWk0NUlpOCtQSFZ6WlNCb2NtVm1QU0lqVEc5bmJ5SWdlRDBpTVRjd0lpQjVQU0l4TnpBaUlIUnlZVzV6Wm05eWJUMGljMk5oYkdVb0xqWXBJaTgrUEhWelpTQm9jbVZtUFNJalNHOTFjbWRzWVhOeklpQjRQU0l4TlRBaUlIazlJamt3SWlCMGNtRnVjMlp2Y20wOUluSnZkR0YwWlNneE1Da2lJSFJ5WVc1elptOXliUzF2Y21sbmFXNDlJalV3TUNBMU1EQWlMejQ4ZFhObElHaHlaV1k5SWlOUWNtOW5jbVZ6Y3lJZ2VEMGlNVFEwSWlCNVBTSTNPVEFpTHo0OGRYTmxJR2h5WldZOUlpTlRkR0YwZFhNaUlIZzlJak0yT0NJZ2VUMGlOemt3SWk4K1BIVnpaU0JvY21WbVBTSWpRVzF2ZFc1MElpQjRQU0kxTmpnaUlIazlJamM1TUNJdlBqeDFjMlVnYUhKbFpqMGlJMFIxY21GMGFXOXVJaUI0UFNJM01EUWlJSGs5SWpjNU1DSXZQand2YzNablBnPT0ifQ==";
        assertEq(actualTokenURI, expectedTokenURI, "token URI");
    }
}
