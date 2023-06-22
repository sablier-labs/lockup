// SPDX-License-Identifier: UNLICENSED
// solhint-disable max-line-length,no-console,quotes
pragma solidity >=0.8.19 <0.9.0;

import { console2 } from "forge-std/console2.sol";
import { StdStyle } from "forge-std/StdStyle.sol";
import { Base64 } from "solady/utils/Base64.sol";

import { LockupLinear_Integration_Basic_Test } from "../LockupLinear.t.sol";

/// @dev Requirements for these tests to work:
/// - The stream id must be 1
/// - The stream's sender must be `0x6332e7b1deb1f1a0b77b2bb18b144330c7291bca`, i.e. `makeAddr("Sender")`
/// - The stream asset must have the DAI symbol
/// - The contract deployer, i.e. the `sender` config option in `foundry.toml`, must have the default value
/// 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38 so that the deployed contracts have the same addresses as
/// the values hard coded in the tests below
contract TokenURI_LockupLinear_Integration_Basic_Test is LockupLinear_Integration_Basic_Test {
    address internal constant LOCKUP_LINEAR = 0x3381cD18e2Fb4dB236BF0525938AB6E43Db0440f;
    uint256 internal defaultStreamId;

    /// @dev To make these tests noninvasive, they are run only when the contract address matches the hard coded value.
    modifier skipOnMismatch() {
        if (address(lockupLinear) == LOCKUP_LINEAR) {
            _;
        } else {
            console2.log(StdStyle.yellow('Warning: "LockupLinear.tokenURI" tests skipped due to address mismatch'));
        }
    }

    function test_RevertWhen_NFTDoesNotExist() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert("ERC721: invalid token ID");
        lockupLinear.tokenURI({ tokenId: nullStreamId });
    }

    modifier whenNFTExists() {
        defaultStreamId = createDefaultStream();
        vm.warp({ timestamp: defaults.START_TIME() + defaults.TOTAL_DURATION() / 4 });
        _;
    }

    /// @dev If you need to update the hard-coded token URI, remember to escape the "\n" character with "\\n".
    function test_TokenURI_Decoded() external skipOnMismatch whenNFTExists {
        string memory tokenURI = lockupLinear.tokenURI(defaultStreamId);
        string memory actualDecodedTokenURI = string(Base64.decode(tokenURI));
        string memory expectedDecodedTokenURI =
            unicode'data:application/json;base64,{"attributes":[{"trait_type":"Asset","value":"DAI"},{"trait_type":"Sender","value":"0x6332e7b1deb1f1a0b77b2bb18b144330c7291bca"},{"trait_type":"Status","value":"Streaming"}],"description":"This NFT represents a payment stream in a Sablier V2 Lockup Linear contract. The owner of this NFT can withdraw the streamed assets, which are denominated in DAI.\\n\\n- Stream ID: 1\\n- Lockup Linear Address: 0x3381cd18e2fb4db236bf0525938ab6e43db0440f\\n- DAI Address: 0x03a6a84cd762d9707a21605b548aaab891562aab\\n\\n⚠️ WARNING: Transferring the NFT makes the new owner the recipient of the stream. The funds are not automatically withdrawn for the previous recipient.","external_url":"https://sablier.com","name":"Sablier V2 Lockup Linear #1","image":"data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxMDAwIiBoZWlnaHQ9IjEwMDAiIHZpZXdCb3g9IjAgMCAxMDAwIDEwMDAiPjxyZWN0IHdpZHRoPSIxMDAlIiBoZWlnaHQ9IjEwMCUiIGZpbHRlcj0idXJsKCNOb2lzZSkiLz48cmVjdCB4PSI3MCIgeT0iNzAiIHdpZHRoPSI4NjAiIGhlaWdodD0iODYwIiBmaWxsPSIjZmZmIiBmaWxsLW9wYWNpdHk9Ii4wMyIgcng9IjQ1IiByeT0iNDUiIHN0cm9rZT0iI2ZmZiIgc3Ryb2tlLW9wYWNpdHk9Ii4xIiBzdHJva2Utd2lkdGg9IjQiLz48ZGVmcz48Y2lyY2xlIGlkPSJHbG93IiByPSI1MDAiIGZpbGw9InVybCgjUmFkaWFsR2xvdykiLz48ZmlsdGVyIGlkPSJOb2lzZSI+PGZlRmxvb2QgeD0iMCIgeT0iMCIgd2lkdGg9IjEwMCUiIGhlaWdodD0iMTAwJSIgZmxvb2QtY29sb3I9ImhzbCgyMzAsMjElLDExJSkiIGZsb29kLW9wYWNpdHk9IjEiIHJlc3VsdD0iZmxvb2RGaWxsIi8+PGZlVHVyYnVsZW5jZSBiYXNlRnJlcXVlbmN5PSIuNCIgbnVtT2N0YXZlcz0iMyIgcmVzdWx0PSJOb2lzZSIgdHlwZT0iZnJhY3RhbE5vaXNlIi8+PGZlQmxlbmQgaW49Ik5vaXNlIiBpbjI9ImZsb29kRmlsbCIgbW9kZT0ic29mdC1saWdodCIvPjwvZmlsdGVyPjxwYXRoIGlkPSJMb2dvIiBmaWxsPSIjZmZmIiBmaWxsLW9wYWNpdHk9Ii4xIiBkPSJtMTMzLjU1OSwxMjQuMDM0Yy0uMDEzLDIuNDEyLTEuMDU5LDQuODQ4LTIuOTIzLDYuNDAyLTIuNTU4LDEuODE5LTUuMTY4LDMuNDM5LTcuODg4LDQuOTk2LTE0LjQ0LDguMjYyLTMxLjA0NywxMi41NjUtNDcuNjc0LDEyLjU2OS04Ljg1OC4wMzYtMTcuODM4LTEuMjcyLTI2LjMyOC0zLjY2My05LjgwNi0yLjc2Ni0xOS4wODctNy4xMTMtMjcuNTYyLTEyLjc3OC0xMy44NDItOC4wMjUsOS40NjgtMjguNjA2LDE2LjE1My0zNS4yNjVoMGMyLjAzNS0xLjgzOCw0LjI1Mi0zLjU0Niw2LjQ2My01LjIyNGgwYzYuNDI5LTUuNjU1LDE2LjIxOC0yLjgzNSwyMC4zNTgsNC4xNyw0LjE0Myw1LjA1Nyw4LjgxNiw5LjY0OSwxMy45MiwxMy43MzRoLjAzN2M1LjczNiw2LjQ2MSwxNS4zNTctMi4yNTMsOS4zOC04LjQ4LDAsMC0zLjUxNS0zLjUxNS0zLjUxNS0zLjUxNS0xMS40OS0xMS40NzgtNTIuNjU2LTUyLjY2NC02NC44MzctNjQuODM3bC4wNDktLjAzN2MtMS43MjUtMS42MDYtMi43MTktMy44NDctMi43NTEtNi4yMDRoMGMtLjA0Ni0yLjM3NSwxLjA2Mi00LjU4MiwyLjcyNi02LjIyOWgwbC4xODUtLjE0OGgwYy4wOTktLjA2MiwuMjIyLS4xNDgsLjM3LS4yNTloMGMyLjA2LTEuMzYyLDMuOTUxLTIuNjIxLDYuMDQ0LTMuODQyQzU3Ljc2My0zLjQ3Myw5Ny43Ni0yLjM0MSwxMjguNjM3LDE4LjMzMmMxNi42NzEsOS45NDYtMjYuMzQ0LDU0LjgxMy0zOC42NTEsNDAuMTk5LTYuMjk5LTYuMDk2LTE4LjA2My0xNy43NDMtMTkuNjY4LTE4LjgxMS02LjAxNi00LjA0Ny0xMy4wNjEsNC43NzYtNy43NTIsOS43NTFsNjguMjU0LDY4LjM3MWMxLjcyNCwxLjYwMSwyLjcxNCwzLjg0LDIuNzM4LDYuMTkyWiIvPjxwYXRoIGlkPSJGbG9hdGluZ1RleHQiIGZpbGw9Im5vbmUiIGQ9Ik0xMjUgNDVoNzUwczgwIDAgODAgODB2NzUwczAgODAgLTgwIDgwaC03NTBzLTgwIDAgLTgwIC04MHYtNzUwczAgLTgwIDgwIC04MCIvPjxyYWRpYWxHcmFkaWVudCBpZD0iUmFkaWFsR2xvdyI+PHN0b3Agb2Zmc2V0PSIwJSIgc3RvcC1jb2xvcj0iaHNsKDE5LDIyJSw2MyUpIiBzdG9wLW9wYWNpdHk9Ii42Ii8+PHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSJoc2woMjMwLDIxJSwxMSUpIiBzdG9wLW9wYWNpdHk9IjAiLz48L3JhZGlhbEdyYWRpZW50PjxsaW5lYXJHcmFkaWVudCBpZD0iU2FuZFRvcCIgeDE9IjAlIiB5MT0iMCUiPjxzdG9wIG9mZnNldD0iMCUiIHN0b3AtY29sb3I9ImhzbCgxOSwyMiUsNjMlKSIvPjxzdG9wIG9mZnNldD0iMTAwJSIgc3RvcC1jb2xvcj0iaHNsKDIzMCwyMSUsMTElKSIvPjwvbGluZWFyR3JhZGllbnQ+PGxpbmVhckdyYWRpZW50IGlkPSJTYW5kQm90dG9tIiB4MT0iMTAwJSIgeTE9IjEwMCUiPjxzdG9wIG9mZnNldD0iMTAlIiBzdG9wLWNvbG9yPSJoc2woMjMwLDIxJSwxMSUpIi8+PHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSJoc2woMTksMjIlLDYzJSkiLz48YW5pbWF0ZSBhdHRyaWJ1dGVOYW1lPSJ4MSIgZHVyPSI2cyIgcmVwZWF0Q291bnQ9ImluZGVmaW5pdGUiIHZhbHVlcz0iMzAlOzYwJTsxMjAlOzYwJTszMCU7Ii8+PC9saW5lYXJHcmFkaWVudD48bGluZWFyR3JhZGllbnQgaWQ9IkhvdXJnbGFzc1N0cm9rZSIgZ3JhZGllbnRUcmFuc2Zvcm09InJvdGF0ZSg5MCkiIGdyYWRpZW50VW5pdHM9InVzZXJTcGFjZU9uVXNlIj48c3RvcCBvZmZzZXQ9IjUwJSIgc3RvcC1jb2xvcj0iaHNsKDE5LDIyJSw2MyUpIi8+PHN0b3Agb2Zmc2V0PSI4MCUiIHN0b3AtY29sb3I9ImhzbCgyMzAsMjElLDExJSkiLz48L2xpbmVhckdyYWRpZW50PjxnIGlkPSJIb3VyZ2xhc3MiPjxwYXRoIGQ9Ik0gNTAsMzYwIGEgMzAwLDMwMCAwIDEsMSA2MDAsMCBhIDMwMCwzMDAgMCAxLDEgLTYwMCwwIiBmaWxsPSIjZmZmIiBmaWxsLW9wYWNpdHk9Ii4wMiIgc3Ryb2tlPSJ1cmwoI0hvdXJnbGFzc1N0cm9rZSkiIHN0cm9rZS13aWR0aD0iNCIvPjxwYXRoIGQ9Im01NjYsMTYxLjIwMXYtNTMuOTI0YzAtMTkuMzgyLTIyLjUxMy0zNy41NjMtNjMuMzk4LTUxLjE5OC00MC43NTYtMTMuNTkyLTk0Ljk0Ni0yMS4wNzktMTUyLjU4Ny0yMS4wNzlzLTExMS44MzgsNy40ODctMTUyLjYwMiwyMS4wNzljLTQwLjg5MywxMy42MzYtNjMuNDEzLDMxLjgxNi02My40MTMsNTEuMTk4djUzLjkyNGMwLDE3LjE4MSwxNy43MDQsMzMuNDI3LDUwLjIyMyw0Ni4zOTR2Mjg0LjgwOWMtMzIuNTE5LDEyLjk2LTUwLjIyMywyOS4yMDYtNTAuMjIzLDQ2LjM5NHY1My45MjRjMCwxOS4zODIsMjIuNTIsMzcuNTYzLDYzLjQxMyw1MS4xOTgsNDAuNzYzLDEzLjU5Miw5NC45NTQsMjEuMDc5LDE1Mi42MDIsMjEuMDc5czExMS44MzEtNy40ODcsMTUyLjU4Ny0yMS4wNzljNDAuODg2LTEzLjYzNiw2My4zOTgtMzEuODE2LDYzLjM5OC01MS4xOTh2LTUzLjkyNGMwLTE3LjE5Ni0xNy43MDQtMzMuNDM1LTUwLjIyMy00Ni40MDFWMjA3LjYwM2MzMi41MTktMTIuOTY3LDUwLjIyMy0yOS4yMDYsNTAuMjIzLTQ2LjQwMVptLTM0Ny40NjIsNTcuNzkzbDEzMC45NTksMTMxLjAyNy0xMzAuOTU5LDEzMS4wMTNWMjE4Ljk5NFptMjYyLjkyNC4wMjJ2MjYyLjAxOGwtMTMwLjkzNy0xMzEuMDA2LDEzMC45MzctMTMxLjAxM1oiIGZpbGw9IiMxNjE4MjIiPjwvcGF0aD48cG9seWdvbiBwb2ludHM9IjM1MCAzNTAuMDI2IDQxNS4wMyAyODQuOTc4IDI4NSAyODQuOTc4IDM1MCAzNTAuMDI2IiBmaWxsPSJ1cmwoI1NhbmRCb3R0b20pIi8+PHBhdGggZD0ibTQxNi4zNDEsMjgxLjk3NWMwLC45MTQtLjM1NCwxLjgwOS0xLjAzNSwyLjY4LTUuNTQyLDcuMDc2LTMyLjY2MSwxMi40NS02NS4yOCwxMi40NS0zMi42MjQsMC01OS43MzgtNS4zNzQtNjUuMjgtMTIuNDUtLjY4MS0uODcyLTEuMDM1LTEuNzY3LTEuMDM1LTIuNjgsMC0uOTE0LjM1NC0xLjgwOCwxLjAzNS0yLjY3Niw1LjU0Mi03LjA3NiwzMi42NTYtMTIuNDUsNjUuMjgtMTIuNDUsMzIuNjE5LDAsNTkuNzM4LDUuMzc0LDY1LjI4LDEyLjQ1LjY4MS44NjcsMS4wMzUsMS43NjIsMS4wMzUsMi42NzZaIiBmaWxsPSJ1cmwoI1NhbmRUb3ApIi8+PHBhdGggZD0ibTQ4MS40Niw1MDQuMTAxdjU4LjQ0OWMtMi4zNS43Ny00LjgyLDEuNTEtNy4zOSwyLjIzLTMwLjMsOC41NC03NC42NSwxMy45Mi0xMjQuMDYsMTMuOTItNTMuNiwwLTEwMS4yNC02LjMzLTEzMS40Ny0xNi4xNnYtNTguNDM5aDI2Mi45MloiIGZpbGw9InVybCgjU2FuZEJvdHRvbSkiLz48ZWxsaXBzZSBjeD0iMzUwIiBjeT0iNTA0LjEwMSIgcng9IjEzMS40NjIiIHJ5PSIyOC4xMDgiIGZpbGw9InVybCgjU2FuZFRvcCkiLz48ZyBmaWxsPSJub25lIiBzdHJva2U9InVybCgjSG91cmdsYXNzU3Ryb2tlKSIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbWl0ZXJsaW1pdD0iMTAiIHN0cm9rZS13aWR0aD0iNCI+PHBhdGggZD0ibTU2NS42NDEsMTA3LjI4YzAsOS41MzctNS41NiwxOC42MjktMTUuNjc2LDI2Ljk3M2gtLjAyM2MtOS4yMDQsNy41OTYtMjIuMTk0LDE0LjU2Mi0zOC4xOTcsMjAuNTkyLTM5LjUwNCwxNC45MzYtOTcuMzI1LDI0LjM1NS0xNjEuNzMzLDI0LjM1NS05MC40OCwwLTE2Ny45NDgtMTguNTgyLTE5OS45NTMtNDQuOTQ4aC0uMDIzYy0xMC4xMTUtOC4zNDQtMTUuNjc2LTE3LjQzNy0xNS42NzYtMjYuOTczLDAtMzkuNzM1LDk2LjU1NC03MS45MjEsMjE1LjY1Mi03MS45MjFzMjE1LjYyOSwzMi4xODUsMjE1LjYyOSw3MS45MjFaIi8+PHBhdGggZD0ibTEzNC4zNiwxNjEuMjAzYzAsMzkuNzM1LDk2LjU1NCw3MS45MjEsMjE1LjY1Miw3MS45MjFzMjE1LjYyOS0zMi4xODYsMjE1LjYyOS03MS45MjEiLz48bGluZSB4MT0iMTM0LjM2IiB5MT0iMTYxLjIwMyIgeDI9IjEzNC4zNiIgeTI9IjEwNy4yOCIvPjxsaW5lIHgxPSI1NjUuNjQiIHkxPSIxNjEuMjAzIiB4Mj0iNTY1LjY0IiB5Mj0iMTA3LjI4Ii8+PGxpbmUgeDE9IjE4NC41ODQiIHkxPSIyMDYuODIzIiB4Mj0iMTg0LjU4NSIgeTI9IjUzNy41NzkiLz48bGluZSB4MT0iMjE4LjE4MSIgeTE9IjIxOC4xMTgiIHgyPSIyMTguMTgxIiB5Mj0iNTYyLjUzNyIvPjxsaW5lIHgxPSI0ODEuODE4IiB5MT0iMjE4LjE0MiIgeDI9IjQ4MS44MTkiIHkyPSI1NjIuNDI4Ii8+PGxpbmUgeDE9IjUxNS40MTUiIHkxPSIyMDcuMzUyIiB4Mj0iNTE1LjQxNiIgeTI9IjUzNy41NzkiLz48cGF0aCBkPSJtMTg0LjU4LDUzNy41OGMwLDUuNDUsNC4yNywxMC42NSwxMi4wMywxNS40MmguMDJjNS41MSwzLjM5LDEyLjc5LDYuNTUsMjEuNTUsOS40MiwzMC4yMSw5LjksNzguMDIsMTYuMjgsMTMxLjgzLDE2LjI4LDQ5LjQxLDAsOTMuNzYtNS4zOCwxMjQuMDYtMTMuOTIsMi43LS43Niw1LjI5LTEuNTQsNy43NS0yLjM1LDguNzctMi44NywxNi4wNS02LjA0LDIxLjU2LTkuNDNoMGM3Ljc2LTQuNzcsMTIuMDQtOS45NywxMi4wNC0xNS40MiIvPjxwYXRoIGQ9Im0xODQuNTgyLDQ5Mi42NTZjLTMxLjM1NCwxMi40ODUtNTAuMjIzLDI4LjU4LTUwLjIyMyw0Ni4xNDIsMCw5LjUzNiw1LjU2NCwxOC42MjcsMTUuNjc3LDI2Ljk2OWguMDIyYzguNTAzLDcuMDA1LDIwLjIxMywxMy40NjMsMzQuNTI0LDE5LjE1OSw5Ljk5OSwzLjk5MSwyMS4yNjksNy42MDksMzMuNTk3LDEwLjc4OCwzNi40NSw5LjQwNyw4Mi4xODEsMTUuMDAyLDEzMS44MzUsMTUuMDAyczk1LjM2My01LjU5NSwxMzEuODA3LTE1LjAwMmMxMC44NDctMi43OSwyMC44NjctNS45MjYsMjkuOTI0LTkuMzQ5LDEuMjQ0LS40NjcsMi40NzMtLjk0MiwzLjY3My0xLjQyNCwxNC4zMjYtNS42OTYsMjYuMDM1LTEyLjE2MSwzNC41MjQtMTkuMTczaC4wMjJjMTAuMTE0LTguMzQyLDE1LjY3Ny0xNy40MzMsMTUuNjc3LTI2Ljk2OSwwLTE3LjU2Mi0xOC44NjktMzMuNjY1LTUwLjIyMy00Ni4xNSIvPjxwYXRoIGQ9Im0xMzQuMzYsNTkyLjcyYzAsMzkuNzM1LDk2LjU1NCw3MS45MjEsMjE1LjY1Miw3MS45MjFzMjE1LjYyOS0zMi4xODYsMjE1LjYyOS03MS45MjEiLz48bGluZSB4MT0iMTM0LjM2IiB5MT0iNTkyLjcyIiB4Mj0iMTM0LjM2IiB5Mj0iNTM4Ljc5NyIvPjxsaW5lIHgxPSI1NjUuNjQiIHkxPSI1OTIuNzIiIHgyPSI1NjUuNjQiIHkyPSI1MzguNzk3Ii8+PHBvbHlsaW5lIHBvaW50cz0iNDgxLjgyMiA0ODEuOTAxIDQ4MS43OTggNDgxLjg3NyA0ODEuNzc1IDQ4MS44NTQgMzUwLjAxNSAzNTAuMDI2IDIxOC4xODUgMjE4LjEyOSIvPjxwb2x5bGluZSBwb2ludHM9IjIxOC4xODUgNDgxLjkwMSAyMTguMjMxIDQ4MS44NTQgMzUwLjAxNSAzNTAuMDI2IDQ4MS44MjIgMjE4LjE1MiIvPjwvZz48L2c+PGcgaWQ9IlByb2dyZXNzIiBmaWxsPSIjZmZmIj48cmVjdCB3aWR0aD0iMjA4IiBoZWlnaHQ9IjEwMCIgZmlsbC1vcGFjaXR5PSIuMDMiIHJ4PSIxNSIgcnk9IjE1IiBzdHJva2U9IiNmZmYiIHN0cm9rZS1vcGFjaXR5PSIuMSIgc3Ryb2tlLXdpZHRoPSI0Ii8+PHRleHQgeD0iMjAiIHk9IjM0IiBmb250LWZhbWlseT0iJ0NvdXJpZXIgTmV3JyxBcmlhbCxtb25vc3BhY2UiIGZvbnQtc2l6ZT0iMjJweCI+UHJvZ3Jlc3M8L3RleHQ+PHRleHQgeD0iMjAiIHk9IjcyIiBmb250LWZhbWlseT0iJ0NvdXJpZXIgTmV3JyxBcmlhbCxtb25vc3BhY2UiIGZvbnQtc2l6ZT0iMjZweCI+MjUlPC90ZXh0PjxnIGZpbGw9Im5vbmUiPjxjaXJjbGUgY3g9IjE2NiIgY3k9IjUwIiByPSIyMiIgc3Ryb2tlPSJoc2woMjMwLDIxJSwxMSUpIiBzdHJva2Utd2lkdGg9IjEwIi8+PGNpcmNsZSBjeD0iMTY2IiBjeT0iNTAiIHBhdGhMZW5ndGg9IjEwMDAwIiByPSIyMiIgc3Ryb2tlPSJoc2woMTksMjIlLDYzJSkiIHN0cm9rZS1kYXNoYXJyYXk9IjEwMDAwIiBzdHJva2UtZGFzaG9mZnNldD0iNzUwMCIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2Utd2lkdGg9IjUiIHRyYW5zZm9ybT0icm90YXRlKC05MCkiIHRyYW5zZm9ybS1vcmlnaW49IjE2NiA1MCIvPjwvZz48L2c+PGcgaWQ9IlN0YXR1cyIgZmlsbD0iI2ZmZiI+PHJlY3Qgd2lkdGg9IjE4NCIgaGVpZ2h0PSIxMDAiIGZpbGwtb3BhY2l0eT0iLjAzIiByeD0iMTUiIHJ5PSIxNSIgc3Ryb2tlPSIjZmZmIiBzdHJva2Utb3BhY2l0eT0iLjEiIHN0cm9rZS13aWR0aD0iNCIvPjx0ZXh0IHg9IjIwIiB5PSIzNCIgZm9udC1mYW1pbHk9IidDb3VyaWVyIE5ldycsQXJpYWwsbW9ub3NwYWNlIiBmb250LXNpemU9IjIycHgiPlN0YXR1czwvdGV4dD48dGV4dCB4PSIyMCIgeT0iNzIiIGZvbnQtZmFtaWx5PSInQ291cmllciBOZXcnLEFyaWFsLG1vbm9zcGFjZSIgZm9udC1zaXplPSIyNnB4Ij5TdHJlYW1pbmc8L3RleHQ+PC9nPjxnIGlkPSJTdHJlYW1lZCIgZmlsbD0iI2ZmZiI+PHJlY3Qgd2lkdGg9IjE1MiIgaGVpZ2h0PSIxMDAiIGZpbGwtb3BhY2l0eT0iLjAzIiByeD0iMTUiIHJ5PSIxNSIgc3Ryb2tlPSIjZmZmIiBzdHJva2Utb3BhY2l0eT0iLjEiIHN0cm9rZS13aWR0aD0iNCIvPjx0ZXh0IHg9IjIwIiB5PSIzNCIgZm9udC1mYW1pbHk9IidDb3VyaWVyIE5ldycsQXJpYWwsbW9ub3NwYWNlIiBmb250LXNpemU9IjIycHgiPlN0cmVhbWVkPC90ZXh0Pjx0ZXh0IHg9IjIwIiB5PSI3MiIgZm9udC1mYW1pbHk9IidDb3VyaWVyIE5ldycsQXJpYWwsbW9ub3NwYWNlIiBmb250LXNpemU9IjI2cHgiPiYjODgwNTsgMi41MEs8L3RleHQ+PC9nPjxnIGlkPSJEdXJhdGlvbiIgZmlsbD0iI2ZmZiI+PHJlY3Qgd2lkdGg9IjE1MiIgaGVpZ2h0PSIxMDAiIGZpbGwtb3BhY2l0eT0iLjAzIiByeD0iMTUiIHJ5PSIxNSIgc3Ryb2tlPSIjZmZmIiBzdHJva2Utb3BhY2l0eT0iLjEiIHN0cm9rZS13aWR0aD0iNCIvPjx0ZXh0IHg9IjIwIiB5PSIzNCIgZm9udC1mYW1pbHk9IidDb3VyaWVyIE5ldycsQXJpYWwsbW9ub3NwYWNlIiBmb250LXNpemU9IjIycHgiPkR1cmF0aW9uPC90ZXh0Pjx0ZXh0IHg9IjIwIiB5PSI3MiIgZm9udC1mYW1pbHk9IidDb3VyaWVyIE5ldycsQXJpYWwsbW9ub3NwYWNlIiBmb250LXNpemU9IjI2cHgiPiZsdDsgMSBEYXk8L3RleHQ+PC9nPjwvZGVmcz48dGV4dCB0ZXh0LXJlbmRlcmluZz0ib3B0aW1pemVTcGVlZCI+PHRleHRQYXRoIHN0YXJ0T2Zmc2V0PSItMTAwJSIgaHJlZj0iI0Zsb2F0aW5nVGV4dCIgZmlsbD0iI2ZmZiIgZm9udC1mYW1pbHk9IidDb3VyaWVyIE5ldycsQXJpYWwsbW9ub3NwYWNlIiBmaWxsLW9wYWNpdHk9Ii44IiBmb250LXNpemU9IjI2cHgiID48YW5pbWF0ZSBhZGRpdGl2ZT0ic3VtIiBhdHRyaWJ1dGVOYW1lPSJzdGFydE9mZnNldCIgYmVnaW49IjBzIiBkdXI9IjUwcyIgZnJvbT0iMCUiIHJlcGVhdENvdW50PSJpbmRlZmluaXRlIiB0bz0iMTAwJSIvPjB4MzM4MWNkMThlMmZiNGRiMjM2YmYwNTI1OTM4YWI2ZTQzZGIwNDQwZiDigKIgU2FibGllciBWMiBMb2NrdXAgTGluZWFyPC90ZXh0UGF0aD48dGV4dFBhdGggc3RhcnRPZmZzZXQ9IjAlIiBocmVmPSIjRmxvYXRpbmdUZXh0IiBmaWxsPSIjZmZmIiBmb250LWZhbWlseT0iJ0NvdXJpZXIgTmV3JyxBcmlhbCxtb25vc3BhY2UiIGZpbGwtb3BhY2l0eT0iLjgiIGZvbnQtc2l6ZT0iMjZweCIgPjxhbmltYXRlIGFkZGl0aXZlPSJzdW0iIGF0dHJpYnV0ZU5hbWU9InN0YXJ0T2Zmc2V0IiBiZWdpbj0iMHMiIGR1cj0iNTBzIiBmcm9tPSIwJSIgcmVwZWF0Q291bnQ9ImluZGVmaW5pdGUiIHRvPSIxMDAlIi8+MHgzMzgxY2QxOGUyZmI0ZGIyMzZiZjA1MjU5MzhhYjZlNDNkYjA0NDBmIOKAoiBTYWJsaWVyIFYyIExvY2t1cCBMaW5lYXI8L3RleHRQYXRoPjx0ZXh0UGF0aCBzdGFydE9mZnNldD0iLTUwJSIgaHJlZj0iI0Zsb2F0aW5nVGV4dCIgZmlsbD0iI2ZmZiIgZm9udC1mYW1pbHk9IidDb3VyaWVyIE5ldycsQXJpYWwsbW9ub3NwYWNlIiBmaWxsLW9wYWNpdHk9Ii44IiBmb250LXNpemU9IjI2cHgiID48YW5pbWF0ZSBhZGRpdGl2ZT0ic3VtIiBhdHRyaWJ1dGVOYW1lPSJzdGFydE9mZnNldCIgYmVnaW49IjBzIiBkdXI9IjUwcyIgZnJvbT0iMCUiIHJlcGVhdENvdW50PSJpbmRlZmluaXRlIiB0bz0iMTAwJSIvPjB4MDNhNmE4NGNkNzYyZDk3MDdhMjE2MDViNTQ4YWFhYjg5MTU2MmFhYiDigKIgREFJPC90ZXh0UGF0aD48dGV4dFBhdGggc3RhcnRPZmZzZXQ9IjUwJSIgaHJlZj0iI0Zsb2F0aW5nVGV4dCIgZmlsbD0iI2ZmZiIgZm9udC1mYW1pbHk9IidDb3VyaWVyIE5ldycsQXJpYWwsbW9ub3NwYWNlIiBmaWxsLW9wYWNpdHk9Ii44IiBmb250LXNpemU9IjI2cHgiID48YW5pbWF0ZSBhZGRpdGl2ZT0ic3VtIiBhdHRyaWJ1dGVOYW1lPSJzdGFydE9mZnNldCIgYmVnaW49IjBzIiBkdXI9IjUwcyIgZnJvbT0iMCUiIHJlcGVhdENvdW50PSJpbmRlZmluaXRlIiB0bz0iMTAwJSIvPjB4MDNhNmE4NGNkNzYyZDk3MDdhMjE2MDViNTQ4YWFhYjg5MTU2MmFhYiDigKIgREFJPC90ZXh0UGF0aD48L3RleHQ+PHVzZSBocmVmPSIjR2xvdyIgZmlsbC1vcGFjaXR5PSIuOSIvPjx1c2UgaHJlZj0iI0dsb3ciIHg9IjEwMDAiIHk9IjEwMDAiIGZpbGwtb3BhY2l0eT0iLjkiLz48dXNlIGhyZWY9IiNMb2dvIiB4PSIxNzAiIHk9IjE3MCIgdHJhbnNmb3JtPSJzY2FsZSguNikiIC8+PHVzZSBocmVmPSIjSG91cmdsYXNzIiB4PSIxNTAiIHk9IjkwIiB0cmFuc2Zvcm09InJvdGF0ZSgxMCkiIHRyYW5zZm9ybS1vcmlnaW49IjUwMCA1MDAiLz48dXNlIGhyZWY9IiNQcm9ncmVzcyIgeD0iMTI4IiB5PSI3OTAiLz48dXNlIGhyZWY9IiNTdGF0dXMiIHg9IjM1MiIgeT0iNzkwIi8+PHVzZSBocmVmPSIjU3RyZWFtZWQiIHg9IjU1MiIgeT0iNzkwIi8+PHVzZSBocmVmPSIjRHVyYXRpb24iIHg9IjcyMCIgeT0iNzkwIi8+PC9zdmc+"}';
        assertEq(actualDecodedTokenURI, expectedDecodedTokenURI, "decoded token URI");
    }

    function test_TokenURI_Full() external skipOnMismatch whenNFTExists {
        string memory actualTokenURI = lockupLinear.tokenURI(defaultStreamId);
        console2.log(actualTokenURI);
        string memory expectedTokenURI =
            "ZGF0YTphcHBsaWNhdGlvbi9qc29uO2Jhc2U2NCx7ImF0dHJpYnV0ZXMiOlt7InRyYWl0X3R5cGUiOiJBc3NldCIsInZhbHVlIjoiREFJIn0seyJ0cmFpdF90eXBlIjoiU2VuZGVyIiwidmFsdWUiOiIweDYzMzJlN2IxZGViMWYxYTBiNzdiMmJiMThiMTQ0MzMwYzcyOTFiY2EifSx7InRyYWl0X3R5cGUiOiJTdGF0dXMiLCJ2YWx1ZSI6IlN0cmVhbWluZyJ9XSwiZGVzY3JpcHRpb24iOiJUaGlzIE5GVCByZXByZXNlbnRzIGEgcGF5bWVudCBzdHJlYW0gaW4gYSBTYWJsaWVyIFYyIExvY2t1cCBMaW5lYXIgY29udHJhY3QuIFRoZSBvd25lciBvZiB0aGlzIE5GVCBjYW4gd2l0aGRyYXcgdGhlIHN0cmVhbWVkIGFzc2V0cywgd2hpY2ggYXJlIGRlbm9taW5hdGVkIGluIERBSS5cblxuLSBTdHJlYW0gSUQ6IDFcbi0gTG9ja3VwIExpbmVhciBBZGRyZXNzOiAweDMzODFjZDE4ZTJmYjRkYjIzNmJmMDUyNTkzOGFiNmU0M2RiMDQ0MGZcbi0gREFJIEFkZHJlc3M6IDB4MDNhNmE4NGNkNzYyZDk3MDdhMjE2MDViNTQ4YWFhYjg5MTU2MmFhYlxuXG7imqDvuI8gV0FSTklORzogVHJhbnNmZXJyaW5nIHRoZSBORlQgbWFrZXMgdGhlIG5ldyBvd25lciB0aGUgcmVjaXBpZW50IG9mIHRoZSBzdHJlYW0uIFRoZSBmdW5kcyBhcmUgbm90IGF1dG9tYXRpY2FsbHkgd2l0aGRyYXduIGZvciB0aGUgcHJldmlvdXMgcmVjaXBpZW50LiIsImV4dGVybmFsX3VybCI6Imh0dHBzOi8vc2FibGllci5jb20iLCJuYW1lIjoiU2FibGllciBWMiBMb2NrdXAgTGluZWFyICMxIiwiaW1hZ2UiOiJkYXRhOmltYWdlL3N2Zyt4bWw7YmFzZTY0LFBITjJaeUI0Yld4dWN6MGlhSFIwY0RvdkwzZDNkeTUzTXk1dmNtY3ZNakF3TUM5emRtY2lJSGRwWkhSb1BTSXhNREF3SWlCb1pXbG5hSFE5SWpFd01EQWlJSFpwWlhkQ2IzZzlJakFnTUNBeE1EQXdJREV3TURBaVBqeHlaV04wSUhkcFpIUm9QU0l4TURBbElpQm9aV2xuYUhROUlqRXdNQ1VpSUdacGJIUmxjajBpZFhKc0tDTk9iMmx6WlNraUx6NDhjbVZqZENCNFBTSTNNQ0lnZVQwaU56QWlJSGRwWkhSb1BTSTROakFpSUdobGFXZG9kRDBpT0RZd0lpQm1hV3hzUFNJalptWm1JaUJtYVd4c0xXOXdZV05wZEhrOUlpNHdNeUlnY25nOUlqUTFJaUJ5ZVQwaU5EVWlJSE4wY205clpUMGlJMlptWmlJZ2MzUnliMnRsTFc5d1lXTnBkSGs5SWk0eElpQnpkSEp2YTJVdGQybGtkR2c5SWpRaUx6NDhaR1ZtY3o0OFkybHlZMnhsSUdsa1BTSkhiRzkzSWlCeVBTSTFNREFpSUdacGJHdzlJblZ5YkNnalVtRmthV0ZzUjJ4dmR5a2lMejQ4Wm1sc2RHVnlJR2xrUFNKT2IybHpaU0krUEdabFJteHZiMlFnZUQwaU1DSWdlVDBpTUNJZ2QybGtkR2c5SWpFd01DVWlJR2hsYVdkb2REMGlNVEF3SlNJZ1pteHZiMlF0WTI5c2IzSTlJbWh6YkNneU16QXNNakVsTERFeEpTa2lJR1pzYjI5a0xXOXdZV05wZEhrOUlqRWlJSEpsYzNWc2REMGlabXh2YjJSR2FXeHNJaTgrUEdabFZIVnlZblZzWlc1alpTQmlZWE5sUm5KbGNYVmxibU41UFNJdU5DSWdiblZ0VDJOMFlYWmxjejBpTXlJZ2NtVnpkV3gwUFNKT2IybHpaU0lnZEhsd1pUMGlabkpoWTNSaGJFNXZhWE5sSWk4K1BHWmxRbXhsYm1RZ2FXNDlJazV2YVhObElpQnBiakk5SW1ac2IyOWtSbWxzYkNJZ2JXOWtaVDBpYzI5bWRDMXNhV2RvZENJdlBqd3ZabWxzZEdWeVBqeHdZWFJvSUdsa1BTSk1iMmR2SWlCbWFXeHNQU0lqWm1abUlpQm1hV3hzTFc5d1lXTnBkSGs5SWk0eElpQmtQU0p0TVRNekxqVTFPU3d4TWpRdU1ETTBZeTB1TURFekxESXVOREV5TFRFdU1EVTVMRFF1T0RRNExUSXVPVEl6TERZdU5EQXlMVEl1TlRVNExERXVPREU1TFRVdU1UWTRMRE11TkRNNUxUY3VPRGc0TERRdU9UazJMVEUwTGpRMExEZ3VNall5TFRNeExqQTBOeXd4TWk0MU5qVXRORGN1TmpjMExERXlMalUyT1MwNExqZzFPQzR3TXpZdE1UY3VPRE00TFRFdU1qY3lMVEkyTGpNeU9DMHpMalkyTXkwNUxqZ3dOaTB5TGpjMk5pMHhPUzR3T0RjdE55NHhNVE10TWpjdU5UWXlMVEV5TGpjM09DMHhNeTQ0TkRJdE9DNHdNalVzT1M0ME5qZ3RNamd1TmpBMkxERTJMakUxTXkwek5TNHlOalZvTUdNeUxqQXpOUzB4TGpnek9DdzBMakkxTWkwekxqVTBOaXcyTGpRMk15MDFMakl5Tkdnd1l6WXVOREk1TFRVdU5qVTFMREUyTGpJeE9DMHlMamd6TlN3eU1DNHpOVGdzTkM0eE55dzBMakUwTXl3MUxqQTFOeXc0TGpneE5pdzVMalkwT1N3eE15NDVNaXd4TXk0M016Um9MakF6TjJNMUxqY3pOaXcyTGpRMk1Td3hOUzR6TlRjdE1pNHlOVE1zT1M0ek9DMDRMalE0TERBc01DMHpMalV4TlMwekxqVXhOUzB6TGpVeE5TMHpMalV4TlMweE1TNDBPUzB4TVM0ME56Z3ROVEl1TmpVMkxUVXlMalkyTkMwMk5DNDRNemN0TmpRdU9ETTNiQzR3TkRrdExqQXpOMk10TVM0M01qVXRNUzQyTURZdE1pNDNNVGt0TXk0NE5EY3RNaTQzTlRFdE5pNHlNRFJvTUdNdExqQTBOaTB5TGpNM05Td3hMakEyTWkwMExqVTRNaXd5TGpjeU5pMDJMakl5T1dnd2JDNHhPRFV0TGpFME9HZ3dZeTR3T1RrdExqQTJNaXd1TWpJeUxTNHhORGdzTGpNM0xTNHlOVGxvTUdNeUxqQTJMVEV1TXpZeUxETXVPVFV4TFRJdU5qSXhMRFl1TURRMExUTXVPRFF5UXpVM0xqYzJNeTB6TGpRM015dzVOeTQzTmkweUxqTTBNU3d4TWpndU5qTTNMREU0TGpNek1tTXhOaTQyTnpFc09TNDVORFl0TWpZdU16UTBMRFUwTGpneE15MHpPQzQyTlRFc05EQXVNVGs1TFRZdU1qazVMVFl1TURrMkxURTRMakEyTXkweE55NDNORE10TVRrdU5qWTRMVEU0TGpneE1TMDJMakF4TmkwMExqQTBOeTB4TXk0d05qRXNOQzQzTnpZdE55NDNOVElzT1M0M05URnNOamd1TWpVMExEWTRMak0zTVdNeExqY3lOQ3d4TGpZd01Td3lMamN4TkN3ekxqZzBMREl1TnpNNExEWXVNVGt5V2lJdlBqeHdZWFJvSUdsa1BTSkdiRzloZEdsdVoxUmxlSFFpSUdacGJHdzlJbTV2Ym1VaUlHUTlJazB4TWpVZ05EVm9OelV3Y3pnd0lEQWdPREFnT0RCMk56VXdjekFnT0RBZ0xUZ3dJRGd3YUMwM05UQnpMVGd3SURBZ0xUZ3dJQzA0TUhZdE56VXdjekFnTFRnd0lEZ3dJQzA0TUNJdlBqeHlZV1JwWVd4SGNtRmthV1Z1ZENCcFpEMGlVbUZrYVdGc1IyeHZkeUkrUEhOMGIzQWdiMlptYzJWMFBTSXdKU0lnYzNSdmNDMWpiMnh2Y2owaWFITnNLREU1TERJeUpTdzJNeVVwSWlCemRHOXdMVzl3WVdOcGRIazlJaTQySWk4K1BITjBiM0FnYjJabWMyVjBQU0l4TURBbElpQnpkRzl3TFdOdmJHOXlQU0pvYzJ3b01qTXdMREl4SlN3eE1TVXBJaUJ6ZEc5d0xXOXdZV05wZEhrOUlqQWlMejQ4TDNKaFpHbGhiRWR5WVdScFpXNTBQanhzYVc1bFlYSkhjbUZrYVdWdWRDQnBaRDBpVTJGdVpGUnZjQ0lnZURFOUlqQWxJaUI1TVQwaU1DVWlQanh6ZEc5d0lHOW1abk5sZEQwaU1DVWlJSE4wYjNBdFkyOXNiM0k5SW1oemJDZ3hPU3d5TWlVc05qTWxLU0l2UGp4emRHOXdJRzltWm5ObGREMGlNVEF3SlNJZ2MzUnZjQzFqYjJ4dmNqMGlhSE5zS0RJek1Dd3lNU1VzTVRFbEtTSXZQand2YkdsdVpXRnlSM0poWkdsbGJuUStQR3hwYm1WaGNrZHlZV1JwWlc1MElHbGtQU0pUWVc1a1FtOTBkRzl0SWlCNE1UMGlNVEF3SlNJZ2VURTlJakV3TUNVaVBqeHpkRzl3SUc5bVpuTmxkRDBpTVRBbElpQnpkRzl3TFdOdmJHOXlQU0pvYzJ3b01qTXdMREl4SlN3eE1TVXBJaTgrUEhOMGIzQWdiMlptYzJWMFBTSXhNREFsSWlCemRHOXdMV052Ykc5eVBTSm9jMndvTVRrc01qSWxMRFl6SlNraUx6NDhZVzVwYldGMFpTQmhkSFJ5YVdKMWRHVk9ZVzFsUFNKNE1TSWdaSFZ5UFNJMmN5SWdjbVZ3WldGMFEyOTFiblE5SW1sdVpHVm1hVzVwZEdVaUlIWmhiSFZsY3owaU16QWxPell3SlRzeE1qQWxPell3SlRzek1DVTdJaTgrUEM5c2FXNWxZWEpIY21Ga2FXVnVkRDQ4YkdsdVpXRnlSM0poWkdsbGJuUWdhV1E5SWtodmRYSm5iR0Z6YzFOMGNtOXJaU0lnWjNKaFpHbGxiblJVY21GdWMyWnZjbTA5SW5KdmRHRjBaU2c1TUNraUlHZHlZV1JwWlc1MFZXNXBkSE05SW5WelpYSlRjR0ZqWlU5dVZYTmxJajQ4YzNSdmNDQnZabVp6WlhROUlqVXdKU0lnYzNSdmNDMWpiMnh2Y2owaWFITnNLREU1TERJeUpTdzJNeVVwSWk4K1BITjBiM0FnYjJabWMyVjBQU0k0TUNVaUlITjBiM0F0WTI5c2IzSTlJbWh6YkNneU16QXNNakVsTERFeEpTa2lMejQ4TDJ4cGJtVmhja2R5WVdScFpXNTBQanhuSUdsa1BTSkliM1Z5WjJ4aGMzTWlQanh3WVhSb0lHUTlJazBnTlRBc016WXdJR0VnTXpBd0xETXdNQ0F3SURFc01TQTJNREFzTUNCaElETXdNQ3d6TURBZ01DQXhMREVnTFRZd01Dd3dJaUJtYVd4c1BTSWpabVptSWlCbWFXeHNMVzl3WVdOcGRIazlJaTR3TWlJZ2MzUnliMnRsUFNKMWNtd29JMGh2ZFhKbmJHRnpjMU4wY205clpTa2lJSE4wY205clpTMTNhV1IwYUQwaU5DSXZQanh3WVhSb0lHUTlJbTAxTmpZc01UWXhMakl3TVhZdE5UTXVPVEkwWXpBdE1Ua3VNemd5TFRJeUxqVXhNeTB6Tnk0MU5qTXROak11TXprNExUVXhMakU1T0MwME1DNDNOVFl0TVRNdU5Ua3lMVGswTGprME5pMHlNUzR3TnprdE1UVXlMalU0TnkweU1TNHdOemx6TFRFeE1TNDRNemdzTnk0ME9EY3RNVFV5TGpZd01pd3lNUzR3TnpsakxUUXdMamc1TXl3eE15NDJNell0TmpNdU5ERXpMRE14TGpneE5pMDJNeTQwTVRNc05URXVNVGs0ZGpVekxqa3lOR013TERFM0xqRTRNU3d4Tnk0M01EUXNNek11TkRJM0xEVXdMakl5TXl3ME5pNHpPVFIyTWpnMExqZ3dPV010TXpJdU5URTVMREV5TGprMkxUVXdMakl5TXl3eU9TNHlNRFl0TlRBdU1qSXpMRFEyTGpNNU5IWTFNeTQ1TWpSak1Dd3hPUzR6T0RJc01qSXVOVElzTXpjdU5UWXpMRFl6TGpReE15dzFNUzR4T1Rnc05EQXVOell6TERFekxqVTVNaXc1TkM0NU5UUXNNakV1TURjNUxERTFNaTQyTURJc01qRXVNRGM1Y3pFeE1TNDRNekV0Tnk0ME9EY3NNVFV5TGpVNE55MHlNUzR3Tnpsak5EQXVPRGcyTFRFekxqWXpOaXcyTXk0ek9UZ3RNekV1T0RFMkxEWXpMak01T0MwMU1TNHhPVGgyTFRVekxqa3lOR013TFRFM0xqRTVOaTB4Tnk0M01EUXRNek11TkRNMUxUVXdMakl5TXkwME5pNDBNREZXTWpBM0xqWXdNMk16TWk0MU1Ua3RNVEl1T1RZM0xEVXdMakl5TXkweU9TNHlNRFlzTlRBdU1qSXpMVFEyTGpRd01WcHRMVE0wTnk0ME5qSXNOVGN1TnpremJERXpNQzQ1TlRrc01UTXhMakF5TnkweE16QXVPVFU1TERFek1TNHdNVE5XTWpFNExqazVORnB0TWpZeUxqa3lOQzR3TWpKMk1qWXlMakF4T0d3dE1UTXdMamt6TnkweE16RXVNREEyTERFek1DNDVNemN0TVRNeExqQXhNMW9pSUdacGJHdzlJaU14TmpFNE1qSWlQand2Y0dGMGFENDhjRzlzZVdkdmJpQndiMmx1ZEhNOUlqTTFNQ0F6TlRBdU1ESTJJRFF4TlM0d015QXlPRFF1T1RjNElESTROU0F5T0RRdU9UYzRJRE0xTUNBek5UQXVNREkySWlCbWFXeHNQU0oxY213b0kxTmhibVJDYjNSMGIyMHBJaTgrUEhCaGRHZ2daRDBpYlRReE5pNHpOREVzTWpneExqazNOV013TEM0NU1UUXRMak0xTkN3eExqZ3dPUzB4TGpBek5Td3lMalk0TFRVdU5UUXlMRGN1TURjMkxUTXlMalkyTVN3eE1pNDBOUzAyTlM0eU9Dd3hNaTQwTlMwek1pNDJNalFzTUMwMU9TNDNNemd0TlM0ek56UXROalV1TWpndE1USXVORFV0TGpZNE1TMHVPRGN5TFRFdU1ETTFMVEV1TnpZM0xURXVNRE0xTFRJdU5qZ3NNQzB1T1RFMExqTTFOQzB4TGpnd09Dd3hMakF6TlMweUxqWTNOaXcxTGpVME1pMDNMakEzTml3ek1pNDJOVFl0TVRJdU5EVXNOalV1TWpndE1USXVORFVzTXpJdU5qRTVMREFzTlRrdU56TTRMRFV1TXpjMExEWTFMakk0TERFeUxqUTFMalk0TVM0NE5qY3NNUzR3TXpVc01TNDNOaklzTVM0d016VXNNaTQyTnpaYUlpQm1hV3hzUFNKMWNtd29JMU5oYm1SVWIzQXBJaTgrUEhCaGRHZ2daRDBpYlRRNE1TNDBOaXcxTURRdU1UQXhkalU0TGpRME9XTXRNaTR6TlM0M055MDBMamd5TERFdU5URXROeTR6T1N3eUxqSXpMVE13TGpNc09DNDFOQzAzTkM0Mk5Td3hNeTQ1TWkweE1qUXVNRFlzTVRNdU9USXROVE11Tml3d0xURXdNUzR5TkMwMkxqTXpMVEV6TVM0ME55MHhOaTR4Tm5ZdE5UZ3VORE01YURJMk1pNDVNbG9pSUdacGJHdzlJblZ5YkNnalUyRnVaRUp2ZEhSdmJTa2lMejQ4Wld4c2FYQnpaU0JqZUQwaU16VXdJaUJqZVQwaU5UQTBMakV3TVNJZ2NuZzlJakV6TVM0ME5qSWlJSEo1UFNJeU9DNHhNRGdpSUdacGJHdzlJblZ5YkNnalUyRnVaRlJ2Y0NraUx6NDhaeUJtYVd4c1BTSnViMjVsSWlCemRISnZhMlU5SW5WeWJDZ2pTRzkxY21kc1lYTnpVM1J5YjJ0bEtTSWdjM1J5YjJ0bExXeHBibVZqWVhBOUluSnZkVzVrSWlCemRISnZhMlV0YldsMFpYSnNhVzFwZEQwaU1UQWlJSE4wY205clpTMTNhV1IwYUQwaU5DSStQSEJoZEdnZ1pEMGliVFUyTlM0Mk5ERXNNVEEzTGpJNFl6QXNPUzQxTXpjdE5TNDFOaXd4T0M0Mk1qa3RNVFV1TmpjMkxESTJMamszTTJndExqQXlNMk10T1M0eU1EUXNOeTQxT1RZdE1qSXVNVGswTERFMExqVTJNaTB6T0M0eE9UY3NNakF1TlRreUxUTTVMalV3TkN3eE5DNDVNell0T1RjdU16STFMREkwTGpNMU5TMHhOakV1TnpNekxESTBMak0xTlMwNU1DNDBPQ3d3TFRFMk55NDVORGd0TVRndU5UZ3lMVEU1T1M0NU5UTXRORFF1T1RRNGFDMHVNREl6WXkweE1DNHhNVFV0T0M0ek5EUXRNVFV1TmpjMkxURTNMalF6TnkweE5TNDJOell0TWpZdU9UY3pMREF0TXprdU56TTFMRGsyTGpVMU5DMDNNUzQ1TWpFc01qRTFMalkxTWkwM01TNDVNakZ6TWpFMUxqWXlPU3d6TWk0eE9EVXNNakUxTGpZeU9TdzNNUzQ1TWpGYUlpOCtQSEJoZEdnZ1pEMGliVEV6TkM0ek5pd3hOakV1TWpBell6QXNNemt1TnpNMUxEazJMalUxTkN3M01TNDVNakVzTWpFMUxqWTFNaXczTVM0NU1qRnpNakUxTGpZeU9TMHpNaTR4T0RZc01qRTFMall5T1MwM01TNDVNakVpTHo0OGJHbHVaU0I0TVQwaU1UTTBMak0ySWlCNU1UMGlNVFl4TGpJd015SWdlREk5SWpFek5DNHpOaUlnZVRJOUlqRXdOeTR5T0NJdlBqeHNhVzVsSUhneFBTSTFOalV1TmpRaUlIa3hQU0l4TmpFdU1qQXpJaUI0TWowaU5UWTFMalkwSWlCNU1qMGlNVEEzTGpJNElpOCtQR3hwYm1VZ2VERTlJakU0TkM0MU9EUWlJSGt4UFNJeU1EWXVPREl6SWlCNE1qMGlNVGcwTGpVNE5TSWdlVEk5SWpVek55NDFOemtpTHo0OGJHbHVaU0I0TVQwaU1qRTRMakU0TVNJZ2VURTlJakl4T0M0eE1UZ2lJSGd5UFNJeU1UZ3VNVGd4SWlCNU1qMGlOVFl5TGpVek55SXZQanhzYVc1bElIZ3hQU0kwT0RFdU9ERTRJaUI1TVQwaU1qRTRMakUwTWlJZ2VESTlJalE0TVM0NE1Ua2lJSGt5UFNJMU5qSXVOREk0SWk4K1BHeHBibVVnZURFOUlqVXhOUzQwTVRVaUlIa3hQU0l5TURjdU16VXlJaUI0TWowaU5URTFMalF4TmlJZ2VUSTlJalV6Tnk0MU56a2lMejQ4Y0dGMGFDQmtQU0p0TVRnMExqVTRMRFV6Tnk0MU9HTXdMRFV1TkRVc05DNHlOeXd4TUM0Mk5Td3hNaTR3TXl3eE5TNDBNbWd1TURKak5TNDFNU3d6TGpNNUxERXlMamM1TERZdU5UVXNNakV1TlRVc09TNDBNaXd6TUM0eU1TdzVMamtzTnpndU1ESXNNVFl1TWpnc01UTXhMamd6TERFMkxqSTRMRFE1TGpReExEQXNPVE11TnpZdE5TNHpPQ3d4TWpRdU1EWXRNVE11T1RJc01pNDNMUzQzTml3MUxqSTVMVEV1TlRRc055NDNOUzB5TGpNMUxEZ3VOemN0TWk0NE55d3hOaTR3TlMwMkxqQTBMREl4TGpVMkxUa3VORE5vTUdNM0xqYzJMVFF1Tnpjc01USXVNRFF0T1M0NU55d3hNaTR3TkMweE5TNDBNaUl2UGp4d1lYUm9JR1E5SW0weE9EUXVOVGd5TERRNU1pNDJOVFpqTFRNeExqTTFOQ3d4TWk0ME9EVXROVEF1TWpJekxESTRMalU0TFRVd0xqSXlNeXcwTmk0eE5ESXNNQ3c1TGpVek5pdzFMalUyTkN3eE9DNDJNamNzTVRVdU5qYzNMREkyTGprMk9XZ3VNREl5WXpndU5UQXpMRGN1TURBMUxESXdMakl4TXl3eE15NDBOak1zTXpRdU5USTBMREU1TGpFMU9TdzVMams1T1N3ekxqazVNU3d5TVM0eU5qa3NOeTQyTURrc016TXVOVGszTERFd0xqYzRPQ3d6Tmk0ME5TdzVMalF3Tnl3NE1pNHhPREVzTVRVdU1EQXlMREV6TVM0NE16VXNNVFV1TURBeWN6azFMak0yTXkwMUxqVTVOU3d4TXpFdU9EQTNMVEUxTGpBd01tTXhNQzQ0TkRjdE1pNDNPU3d5TUM0NE5qY3ROUzQ1TWpZc01qa3VPVEkwTFRrdU16UTVMREV1TWpRMExTNDBOamNzTWk0ME56TXRMamswTWl3ekxqWTNNeTB4TGpReU5Dd3hOQzR6TWpZdE5TNDJPVFlzTWpZdU1ETTFMVEV5TGpFMk1Td3pOQzQxTWpRdE1Ua3VNVGN6YUM0d01qSmpNVEF1TVRFMExUZ3VNelF5TERFMUxqWTNOeTB4Tnk0ME16TXNNVFV1TmpjM0xUSTJMamsyT1N3d0xURTNMalUyTWkweE9DNDROamt0TXpNdU5qWTFMVFV3TGpJeU15MDBOaTR4TlNJdlBqeHdZWFJvSUdROUltMHhNelF1TXpZc05Ua3lMamN5WXpBc016a3VOek0xTERrMkxqVTFOQ3czTVM0NU1qRXNNakUxTGpZMU1pdzNNUzQ1TWpGek1qRTFMall5T1Mwek1pNHhPRFlzTWpFMUxqWXlPUzAzTVM0NU1qRWlMejQ4YkdsdVpTQjRNVDBpTVRNMExqTTJJaUI1TVQwaU5Ua3lMamN5SWlCNE1qMGlNVE0wTGpNMklpQjVNajBpTlRNNExqYzVOeUl2UGp4c2FXNWxJSGd4UFNJMU5qVXVOalFpSUhreFBTSTFPVEl1TnpJaUlIZ3lQU0kxTmpVdU5qUWlJSGt5UFNJMU16Z3VOemszSWk4K1BIQnZiSGxzYVc1bElIQnZhVzUwY3owaU5EZ3hMamd5TWlBME9ERXVPVEF4SURRNE1TNDNPVGdnTkRneExqZzNOeUEwT0RFdU56YzFJRFE0TVM0NE5UUWdNelV3TGpBeE5TQXpOVEF1TURJMklESXhPQzR4T0RVZ01qRTRMakV5T1NJdlBqeHdiMng1YkdsdVpTQndiMmx1ZEhNOUlqSXhPQzR4T0RVZ05EZ3hMamt3TVNBeU1UZ3VNak14SURRNE1TNDROVFFnTXpVd0xqQXhOU0F6TlRBdU1ESTJJRFE0TVM0NE1qSWdNakU0TGpFMU1pSXZQand2Wno0OEwyYytQR2NnYVdROUlsQnliMmR5WlhOeklpQm1hV3hzUFNJalptWm1JajQ4Y21WamRDQjNhV1IwYUQwaU1qQTRJaUJvWldsbmFIUTlJakV3TUNJZ1ptbHNiQzF2Y0dGamFYUjVQU0l1TURNaUlISjRQU0l4TlNJZ2NuazlJakUxSWlCemRISnZhMlU5SWlObVptWWlJSE4wY205clpTMXZjR0ZqYVhSNVBTSXVNU0lnYzNSeWIydGxMWGRwWkhSb1BTSTBJaTgrUEhSbGVIUWdlRDBpTWpBaUlIazlJak0wSWlCbWIyNTBMV1poYldsc2VUMGlKME52ZFhKcFpYSWdUbVYzSnl4QmNtbGhiQ3h0YjI1dmMzQmhZMlVpSUdadmJuUXRjMmw2WlQwaU1qSndlQ0krVUhKdlozSmxjM004TDNSbGVIUStQSFJsZUhRZ2VEMGlNakFpSUhrOUlqY3lJaUJtYjI1MExXWmhiV2xzZVQwaUowTnZkWEpwWlhJZ1RtVjNKeXhCY21saGJDeHRiMjV2YzNCaFkyVWlJR1p2Ym5RdGMybDZaVDBpTWpad2VDSStNalVsUEM5MFpYaDBQanhuSUdacGJHdzlJbTV2Ym1VaVBqeGphWEpqYkdVZ1kzZzlJakUyTmlJZ1kzazlJalV3SWlCeVBTSXlNaUlnYzNSeWIydGxQU0pvYzJ3b01qTXdMREl4SlN3eE1TVXBJaUJ6ZEhKdmEyVXRkMmxrZEdnOUlqRXdJaTgrUEdOcGNtTnNaU0JqZUQwaU1UWTJJaUJqZVQwaU5UQWlJSEJoZEdoTVpXNW5kR2c5SWpFd01EQXdJaUJ5UFNJeU1pSWdjM1J5YjJ0bFBTSm9jMndvTVRrc01qSWxMRFl6SlNraUlITjBjbTlyWlMxa1lYTm9ZWEp5WVhrOUlqRXdNREF3SWlCemRISnZhMlV0WkdGemFHOW1abk5sZEQwaU56VXdNQ0lnYzNSeWIydGxMV3hwYm1WallYQTlJbkp2ZFc1a0lpQnpkSEp2YTJVdGQybGtkR2c5SWpVaUlIUnlZVzV6Wm05eWJUMGljbTkwWVhSbEtDMDVNQ2tpSUhSeVlXNXpabTl5YlMxdmNtbG5hVzQ5SWpFMk5pQTFNQ0l2UGp3dlp6NDhMMmMrUEdjZ2FXUTlJbE4wWVhSMWN5SWdabWxzYkQwaUkyWm1aaUkrUEhKbFkzUWdkMmxrZEdnOUlqRTROQ0lnYUdWcFoyaDBQU0l4TURBaUlHWnBiR3d0YjNCaFkybDBlVDBpTGpBeklpQnllRDBpTVRVaUlISjVQU0l4TlNJZ2MzUnliMnRsUFNJalptWm1JaUJ6ZEhKdmEyVXRiM0JoWTJsMGVUMGlMakVpSUhOMGNtOXJaUzEzYVdSMGFEMGlOQ0l2UGp4MFpYaDBJSGc5SWpJd0lpQjVQU0l6TkNJZ1ptOXVkQzFtWVcxcGJIazlJaWREYjNWeWFXVnlJRTVsZHljc1FYSnBZV3dzYlc5dWIzTndZV05sSWlCbWIyNTBMWE5wZW1VOUlqSXljSGdpUGxOMFlYUjFjend2ZEdWNGRENDhkR1Y0ZENCNFBTSXlNQ0lnZVQwaU56SWlJR1p2Ym5RdFptRnRhV3g1UFNJblEyOTFjbWxsY2lCT1pYY25MRUZ5YVdGc0xHMXZibTl6Y0dGalpTSWdabTl1ZEMxemFYcGxQU0l5Tm5CNElqNVRkSEpsWVcxcGJtYzhMM1JsZUhRK1BDOW5QanhuSUdsa1BTSlRkSEpsWVcxbFpDSWdabWxzYkQwaUkyWm1aaUkrUEhKbFkzUWdkMmxrZEdnOUlqRTFNaUlnYUdWcFoyaDBQU0l4TURBaUlHWnBiR3d0YjNCaFkybDBlVDBpTGpBeklpQnllRDBpTVRVaUlISjVQU0l4TlNJZ2MzUnliMnRsUFNJalptWm1JaUJ6ZEhKdmEyVXRiM0JoWTJsMGVUMGlMakVpSUhOMGNtOXJaUzEzYVdSMGFEMGlOQ0l2UGp4MFpYaDBJSGc5SWpJd0lpQjVQU0l6TkNJZ1ptOXVkQzFtWVcxcGJIazlJaWREYjNWeWFXVnlJRTVsZHljc1FYSnBZV3dzYlc5dWIzTndZV05sSWlCbWIyNTBMWE5wZW1VOUlqSXljSGdpUGxOMGNtVmhiV1ZrUEM5MFpYaDBQangwWlhoMElIZzlJakl3SWlCNVBTSTNNaUlnWm05dWRDMW1ZVzFwYkhrOUlpZERiM1Z5YVdWeUlFNWxkeWNzUVhKcFlXd3NiVzl1YjNOd1lXTmxJaUJtYjI1MExYTnBlbVU5SWpJMmNIZ2lQaVlqT0Rnd05Uc2dNaTQxTUVzOEwzUmxlSFErUEM5blBqeG5JR2xrUFNKRWRYSmhkR2x2YmlJZ1ptbHNiRDBpSTJabVppSStQSEpsWTNRZ2QybGtkR2c5SWpFMU1pSWdhR1ZwWjJoMFBTSXhNREFpSUdacGJHd3RiM0JoWTJsMGVUMGlMakF6SWlCeWVEMGlNVFVpSUhKNVBTSXhOU0lnYzNSeWIydGxQU0lqWm1abUlpQnpkSEp2YTJVdGIzQmhZMmwwZVQwaUxqRWlJSE4wY205clpTMTNhV1IwYUQwaU5DSXZQangwWlhoMElIZzlJakl3SWlCNVBTSXpOQ0lnWm05dWRDMW1ZVzFwYkhrOUlpZERiM1Z5YVdWeUlFNWxkeWNzUVhKcFlXd3NiVzl1YjNOd1lXTmxJaUJtYjI1MExYTnBlbVU5SWpJeWNIZ2lQa1IxY21GMGFXOXVQQzkwWlhoMFBqeDBaWGgwSUhnOUlqSXdJaUI1UFNJM01pSWdabTl1ZEMxbVlXMXBiSGs5SWlkRGIzVnlhV1Z5SUU1bGR5Y3NRWEpwWVd3c2JXOXViM053WVdObElpQm1iMjUwTFhOcGVtVTlJakkyY0hnaVBpWnNkRHNnTVNCRVlYazhMM1JsZUhRK1BDOW5Qand2WkdWbWN6NDhkR1Y0ZENCMFpYaDBMWEpsYm1SbGNtbHVaejBpYjNCMGFXMXBlbVZUY0dWbFpDSStQSFJsZUhSUVlYUm9JSE4wWVhKMFQyWm1jMlYwUFNJdE1UQXdKU0lnYUhKbFpqMGlJMFpzYjJGMGFXNW5WR1Y0ZENJZ1ptbHNiRDBpSTJabVppSWdabTl1ZEMxbVlXMXBiSGs5SWlkRGIzVnlhV1Z5SUU1bGR5Y3NRWEpwWVd3c2JXOXViM053WVdObElpQm1hV3hzTFc5d1lXTnBkSGs5SWk0NElpQm1iMjUwTFhOcGVtVTlJakkyY0hnaUlENDhZVzVwYldGMFpTQmhaR1JwZEdsMlpUMGljM1Z0SWlCaGRIUnlhV0oxZEdWT1lXMWxQU0p6ZEdGeWRFOW1abk5sZENJZ1ltVm5hVzQ5SWpCeklpQmtkWEk5SWpVd2N5SWdabkp2YlQwaU1DVWlJSEpsY0dWaGRFTnZkVzUwUFNKcGJtUmxabWx1YVhSbElpQjBiejBpTVRBd0pTSXZQakI0TXpNNE1XTmtNVGhsTW1aaU5HUmlNak0yWW1Zd05USTFPVE00WVdJMlpUUXpaR0l3TkRRd1ppRGlnS0lnVTJGaWJHbGxjaUJXTWlCTWIyTnJkWEFnVEdsdVpXRnlQQzkwWlhoMFVHRjBhRDQ4ZEdWNGRGQmhkR2dnYzNSaGNuUlBabVp6WlhROUlqQWxJaUJvY21WbVBTSWpSbXh2WVhScGJtZFVaWGgwSWlCbWFXeHNQU0lqWm1abUlpQm1iMjUwTFdaaGJXbHNlVDBpSjBOdmRYSnBaWElnVG1WM0p5eEJjbWxoYkN4dGIyNXZjM0JoWTJVaUlHWnBiR3d0YjNCaFkybDBlVDBpTGpnaUlHWnZiblF0YzJsNlpUMGlNalp3ZUNJZ1BqeGhibWx0WVhSbElHRmtaR2wwYVhabFBTSnpkVzBpSUdGMGRISnBZblYwWlU1aGJXVTlJbk4wWVhKMFQyWm1jMlYwSWlCaVpXZHBiajBpTUhNaUlHUjFjajBpTlRCeklpQm1jbTl0UFNJd0pTSWdjbVZ3WldGMFEyOTFiblE5SW1sdVpHVm1hVzVwZEdVaUlIUnZQU0l4TURBbElpOCtNSGd6TXpneFkyUXhPR1V5Wm1JMFpHSXlNelppWmpBMU1qVTVNemhoWWpabE5ETmtZakEwTkRCbUlPS0FvaUJUWVdKc2FXVnlJRll5SUV4dlkydDFjQ0JNYVc1bFlYSThMM1JsZUhSUVlYUm9QangwWlhoMFVHRjBhQ0J6ZEdGeWRFOW1abk5sZEQwaUxUVXdKU0lnYUhKbFpqMGlJMFpzYjJGMGFXNW5WR1Y0ZENJZ1ptbHNiRDBpSTJabVppSWdabTl1ZEMxbVlXMXBiSGs5SWlkRGIzVnlhV1Z5SUU1bGR5Y3NRWEpwWVd3c2JXOXViM053WVdObElpQm1hV3hzTFc5d1lXTnBkSGs5SWk0NElpQm1iMjUwTFhOcGVtVTlJakkyY0hnaUlENDhZVzVwYldGMFpTQmhaR1JwZEdsMlpUMGljM1Z0SWlCaGRIUnlhV0oxZEdWT1lXMWxQU0p6ZEdGeWRFOW1abk5sZENJZ1ltVm5hVzQ5SWpCeklpQmtkWEk5SWpVd2N5SWdabkp2YlQwaU1DVWlJSEpsY0dWaGRFTnZkVzUwUFNKcGJtUmxabWx1YVhSbElpQjBiejBpTVRBd0pTSXZQakI0TUROaE5tRTROR05rTnpZeVpEazNNRGRoTWpFMk1EVmlOVFE0WVdGaFlqZzVNVFUyTW1GaFlpRGlnS0lnUkVGSlBDOTBaWGgwVUdGMGFENDhkR1Y0ZEZCaGRHZ2djM1JoY25SUFptWnpaWFE5SWpVd0pTSWdhSEpsWmowaUkwWnNiMkYwYVc1blZHVjRkQ0lnWm1sc2JEMGlJMlptWmlJZ1ptOXVkQzFtWVcxcGJIazlJaWREYjNWeWFXVnlJRTVsZHljc1FYSnBZV3dzYlc5dWIzTndZV05sSWlCbWFXeHNMVzl3WVdOcGRIazlJaTQ0SWlCbWIyNTBMWE5wZW1VOUlqSTJjSGdpSUQ0OFlXNXBiV0YwWlNCaFpHUnBkR2wyWlQwaWMzVnRJaUJoZEhSeWFXSjFkR1ZPWVcxbFBTSnpkR0Z5ZEU5bVpuTmxkQ0lnWW1WbmFXNDlJakJ6SWlCa2RYSTlJalV3Y3lJZ1puSnZiVDBpTUNVaUlISmxjR1ZoZEVOdmRXNTBQU0pwYm1SbFptbHVhWFJsSWlCMGJ6MGlNVEF3SlNJdlBqQjRNRE5oTm1FNE5HTmtOell5WkRrM01EZGhNakUyTURWaU5UUTRZV0ZoWWpnNU1UVTJNbUZoWWlEaWdLSWdSRUZKUEM5MFpYaDBVR0YwYUQ0OEwzUmxlSFErUEhWelpTQm9jbVZtUFNJalIyeHZkeUlnWm1sc2JDMXZjR0ZqYVhSNVBTSXVPU0l2UGp4MWMyVWdhSEpsWmowaUkwZHNiM2NpSUhnOUlqRXdNREFpSUhrOUlqRXdNREFpSUdacGJHd3RiM0JoWTJsMGVUMGlMamtpTHo0OGRYTmxJR2h5WldZOUlpTk1iMmR2SWlCNFBTSXhOekFpSUhrOUlqRTNNQ0lnZEhKaGJuTm1iM0p0UFNKelkyRnNaU2d1TmlraUlDOCtQSFZ6WlNCb2NtVm1QU0lqU0c5MWNtZHNZWE56SWlCNFBTSXhOVEFpSUhrOUlqa3dJaUIwY21GdWMyWnZjbTA5SW5KdmRHRjBaU2d4TUNraUlIUnlZVzV6Wm05eWJTMXZjbWxuYVc0OUlqVXdNQ0ExTURBaUx6NDhkWE5sSUdoeVpXWTlJaU5RY205bmNtVnpjeUlnZUQwaU1USTRJaUI1UFNJM09UQWlMejQ4ZFhObElHaHlaV1k5SWlOVGRHRjBkWE1pSUhnOUlqTTFNaUlnZVQwaU56a3dJaTgrUEhWelpTQm9jbVZtUFNJalUzUnlaV0Z0WldRaUlIZzlJalUxTWlJZ2VUMGlOemt3SWk4K1BIVnpaU0JvY21WbVBTSWpSSFZ5WVhScGIyNGlJSGc5SWpjeU1DSWdlVDBpTnprd0lpOCtQQzl6ZG1jKyJ9";
        assertEq(actualTokenURI, expectedTokenURI, "token URI");
    }
}
