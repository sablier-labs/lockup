// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable no-console
pragma solidity >=0.8.22 <0.9.0;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { console2 } from "forge-std/src/console2.sol";
import { Script } from "forge-std/src/Script.sol";
import { stdJson } from "forge-std/src/StdJson.sol";

contract BaseScript is Script {
    using Strings for uint256;
    using stdJson for string;

    /// @dev The default value for `maxCountMap`.
    uint256 internal constant DEFAULT_MAX_COUNT = 500;

    /// @dev The address of the default Sablier admin.
    address internal constant DEFAULT_SABLIER_ADMIN = 0xb1bEF51ebCA01EB12001a639bDBbFF6eEcA12B9F;

    /// @dev The salt used for deterministic deployments.
    bytes32 internal immutable SALT;

    /// @dev Included to enable compilation of the script without a $MNEMONIC environment variable.
    string internal constant TEST_MNEMONIC = "test test test test test test test test test test test junk";

    /// @dev Admin address mapped by the chain Id.
    mapping(uint256 chainId => address admin) internal adminMap;

    /// @dev The address of the transaction broadcaster.
    address internal broadcaster;

    /// @dev Used to derive the broadcaster's address if $EOA is not defined.
    string internal mnemonic;

    /// @dev Maximum count for segments and tranches mapped by the chain Id.
    mapping(uint256 chainId => uint256 count) internal maxCountMap;

    /// @dev Initializes the transaction broadcaster like this:
    ///
    /// - If $EOA is defined, use it.
    /// - Otherwise, derive the broadcaster address from $MNEMONIC.
    /// - If $MNEMONIC is not defined, default to a test mnemonic.
    ///
    /// The use case for $EOA is to specify the broadcaster key and its address via the command line.
    constructor() {
        address from = vm.envOr({ name: "EOA", defaultValue: address(0) });
        if (from != address(0)) {
            broadcaster = from;
        } else {
            mnemonic = vm.envOr({ name: "MNEMONIC", defaultValue: TEST_MNEMONIC });
            (broadcaster,) = deriveRememberKey({ mnemonic: mnemonic, index: 0 });
        }

        // Construct the salt for deterministic deployments.
        SALT = constructCreate2Salt();

        // Populate the admin map.
        populateAdminMap();

        // Populate the max count map for segments and tranches.
        populateMaxCountMap();

        // If there is no admin set for a specific chain, use the default Sablier admin.
        if (adminMap[block.chainid] == address(0)) {
            adminMap[block.chainid] = DEFAULT_SABLIER_ADMIN;
        }

        // If there is no maximum value set for a specific chain, use the default value.
        if (maxCountMap[block.chainid] == 0) {
            maxCountMap[block.chainid] = DEFAULT_MAX_COUNT;
        }
    }

    modifier broadcast() {
        vm.startBroadcast(broadcaster);
        _;
        vm.stopBroadcast();
    }

    /// @dev The presence of the salt instructs Forge to deploy contracts via this deterministic CREATE2 factory:
    /// https://github.com/Arachnid/deterministic-deployment-proxy
    ///
    /// Notes:
    /// - The salt format is "ChainID <chainid>, Version <version>".
    function constructCreate2Salt() public view returns (bytes32) {
        string memory chainId = block.chainid.toString();
        string memory version = getVersion();
        string memory create2Salt = string.concat("ChainID ", chainId, ", Version ", version);
        console2.log("The CREATE2 salt is \"%s\"", create2Salt);
        return bytes32(abi.encodePacked(create2Salt));
    }

    /// @dev The version is obtained from `package.json`.
    function getVersion() internal view returns (string memory) {
        string memory json = vm.readFile("package.json");
        return json.readString(".version");
    }

    /// @dev Populates the admin map. The reason the chain IDs configured for the admin map do not match the other
    /// maps is that we only have multisigs for the chains listed below, otherwise, the default admin is used.​
    function populateAdminMap() internal {
        adminMap[42_161] = 0xF34E41a6f6Ce5A45559B1D3Ee92E141a3De96376; // Arbitrum
        adminMap[43_114] = 0x4735517616373c5137dE8bcCDc887637B8ac85Ce; // Avalanche
        adminMap[8453] = 0x83A6fA8c04420B3F9C7A4CF1c040b63Fbbc89B66; // Base
        adminMap[56] = 0x6666cA940D2f4B65883b454b7Bc7EEB039f64fa3; // BNB
        adminMap[100] = 0x72ACB57fa6a8fa768bE44Db453B1CDBa8B12A399; // Gnosis
        adminMap[1] = 0x79Fb3e81aAc012c08501f41296CCC145a1E15844; // Mainnet
        adminMap[59_144] = 0x72dCfa0483d5Ef91562817C6f20E8Ce07A81319D; // Linea
        adminMap[10] = 0x43c76FE8Aec91F63EbEfb4f5d2a4ba88ef880350; // Optimism
        adminMap[137] = 0x40A518C5B9c1d3D6d62Ba789501CE4D526C9d9C6; // Polygon
        adminMap[534_352] = 0x0F7Ad835235Ede685180A5c611111610813457a9; // Scroll
    }

    /// @dev Updates max values for segments and tranches. Values can be updated using the `update-counts.sh` script.
    function populateMaxCountMap() internal {
        // forgefmt: disable-start

        // Arbitrum chain ID
        maxCountMap[42161] = 1090;

        // Avalanche chain ID.
        maxCountMap[43114] = 490;

        // Base chain ID.
        maxCountMap[8453] = 2030;

        // Blast chain ID.
        maxCountMap[81457] = 1020;

        // BNB chain ID.
        maxCountMap[56] = 4460;

        // Ethereum chain ID.
        maxCountMap[1] = 1020;

        // Gnosis chain ID.
        maxCountMap[100] = 560;

        // Optimism chain ID.
        maxCountMap[10] = 1020;

        // Polygon chain ID.
        maxCountMap[137] = 1020;

        // Scroll chain ID.
        maxCountMap[534352] = 320;

        // Sepolia chain ID.
        maxCountMap[11155111] = 1020;

        // forgefmt: disable-end
    }
}
