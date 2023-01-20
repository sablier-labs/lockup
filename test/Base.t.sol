// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ERC20 } from "@prb/contracts/token/erc20/ERC20.sol";
import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { NonCompliantERC20 } from "@prb/contracts/token/erc20/NonCompliantERC20.sol";
import { ud2x18 } from "@prb/math/UD2x18.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { eqString } from "@prb/test/Helpers.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import { DeployComptroller } from "script/DeployComptroller.s.sol";
import { DeployLockupLinear } from "script/DeployLockupLinear.s.sol";
import { DeployLockupPro } from "script/DeployLockupPro.s.sol";
import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";
import { ISablierV2LockupLinear } from "src/interfaces/ISablierV2LockupLinear.sol";
import { ISablierV2LockupPro } from "src/interfaces/ISablierV2LockupPro.sol";
import { SablierV2Comptroller } from "src/SablierV2Comptroller.sol";
import { SablierV2LockupPro } from "src/SablierV2LockupPro.sol";
import { SablierV2LockupLinear } from "src/SablierV2LockupLinear.sol";
import { Range, Segment } from "src/types/Structs.sol";

import { Assertions } from "./helpers/Assertions.t.sol";
import { Constants } from "./helpers/Constants.t.sol";
import { Utils } from "./helpers/Utils.t.sol";

/// @title Base_Test
/// @notice Base test contract that contains common logic needed by all test contracts.
abstract contract Base_Test is Assertions, Constants, Utils, StdCheats {
    /*//////////////////////////////////////////////////////////////////////////
                                       STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct Users {
        // Default admin of all Sablier V2 contracts.
        address payable admin;
        // Neutral user.
        address payable alice;
        // Default stream broker.
        address payable broker;
        // Malicious user.
        address payable eve;
        // Default NFT operator.
        address payable operator;
        // Default stream recipient.
        address payable recipient;
        // Default stream sender.
        address payable sender;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 internal immutable DEFAULT_ASSET;
    uint40 internal immutable DEFAULT_CLIFF_TIME;
    Range internal DEFAULT_RANGE;
    Segment[] internal DEFAULT_SEGMENTS;
    uint40 internal immutable DEFAULT_START_TIME;
    uint40 internal immutable DEFAULT_STOP_TIME;

    /*//////////////////////////////////////////////////////////////////////////
                                    TEST VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Users internal users;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierV2Comptroller internal comptroller;
    IERC20 internal dai = new ERC20("Dai Stablecoin", "DAI", 18);
    ISablierV2LockupLinear internal linear;
    NonCompliantERC20 internal nonCompliantAsset = new NonCompliantERC20("Non-Compliant ERC-20 Asset", "NCT", 18);
    ISablierV2LockupPro internal pro;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {
        DEFAULT_ASSET = dai;
        DEFAULT_START_TIME = getBlockTimestamp();
        DEFAULT_CLIFF_TIME = DEFAULT_START_TIME + DEFAULT_CLIFF_DURATION;
        DEFAULT_STOP_TIME = DEFAULT_START_TIME + DEFAULT_TOTAL_DURATION;
        DEFAULT_RANGE = Range({ start: DEFAULT_START_TIME, cliff: DEFAULT_CLIFF_TIME, stop: DEFAULT_STOP_TIME });

        DEFAULT_SEGMENTS.push(
            Segment({
                amount: 2_500e18,
                exponent: ud2x18(3.14e18),
                milestone: DEFAULT_START_TIME + DEFAULT_CLIFF_DURATION
            })
        );
        DEFAULT_SEGMENTS.push(
            Segment({
                amount: 7_500e18,
                exponent: ud2x18(0.5e18),
                milestone: DEFAULT_START_TIME + DEFAULT_TOTAL_DURATION
            })
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        // Create users for testing.
        users = Users({
            admin: createUser("Admin"),
            alice: createUser("Alice"),
            broker: createUser("Broker"),
            eve: createUser("Eve"),
            operator: createUser("Operator"),
            recipient: createUser("Recipient"),
            sender: createUser("Sender")
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Adjust the amounts in the default segments as two fractions of the provided net deposit amount,
    /// one 20%, the other 80%.
    function adjustSegmentAmounts(Segment[] memory segments, uint128 netDepositAmount) internal pure {
        segments[0].amount = ud(netDepositAmount).mul(ud(0.2e18)).intoUint128();
        segments[1].amount = netDepositAmount - segments[0].amount;
    }

    /// @dev Retrieves the current block timestamp as an `uint40`.
    function getBlockTimestamp() internal view returns (uint40 blockTimestamp) {
        blockTimestamp = uint40(block.timestamp);
    }

    /// @dev Checks if the Foundry profile is "test-optimized".
    function isTestOptimizedProfile() internal returns (bool result) {
        string memory profile = vm.envOr("FOUNDRY_PROFILE", string(""));
        result = eqString(profile, "test-optimized");
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Approves all Sablier contracts to spend ERC-20 assets from the sender, recipient, Alice and Eve,
    /// and then change the active prank back to the admin.
    function approveProtocol() internal {
        changePrank(users.sender);
        dai.approve({ spender: address(linear), value: UINT256_MAX });
        dai.approve({ spender: address(pro), value: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(linear), value: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(pro), value: UINT256_MAX });

        changePrank(users.recipient);
        dai.approve({ spender: address(linear), value: UINT256_MAX });
        dai.approve({ spender: address(pro), value: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(linear), value: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(pro), value: UINT256_MAX });

        changePrank(users.alice);
        dai.approve({ spender: address(linear), value: UINT256_MAX });
        dai.approve({ spender: address(pro), value: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(linear), value: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(pro), value: UINT256_MAX });

        changePrank(users.eve);
        dai.approve({ spender: address(linear), value: UINT256_MAX });
        dai.approve({ spender: address(pro), value: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(linear), value: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(pro), value: UINT256_MAX });

        // Finally, change the active prank back to the admin.
        changePrank(users.admin);
    }

    /// @dev Generates an address by hashing the name, labels the address and funds it with 100 ETH, 1 million DAI,
    /// and 1 million non-compliant assets.
    function createUser(string memory name) internal returns (address payable addr) {
        addr = payable(address(uint160(uint256(keccak256(abi.encodePacked(name))))));
        vm.label({ account: addr, newLabel: name });
        vm.deal({ account: addr, newBalance: 100 ether });
        deal({ token: address(dai), to: addr, give: 1_000_000e18 });
        deal({ token: address(nonCompliantAsset), to: addr, give: 1_000_000e18 });
    }

    /// @dev Conditionally deploy contracts normally or from precompiled source.
    function deployProtocol() internal {
        // We deploy from precompiled source if the profile is "test-optimized".
        if (isTestOptimizedProfile()) {
            comptroller = ISablierV2Comptroller(
                deployCode("optimized-out/SablierV2Comptroller.sol/SablierV2Comptroller.json", abi.encode(users.admin))
            );
            linear = ISablierV2LockupLinear(
                deployCode(
                    "optimized-out/SablierV2LockupLinear.sol/SablierV2LockupLinear.json",
                    abi.encode(users.admin, address(comptroller), DEFAULT_MAX_FEE)
                )
            );
            pro = ISablierV2LockupPro(
                deployCode(
                    "optimized-out/SablierV2LockupPro.sol/SablierV2LockupPro.json",
                    abi.encode(users.admin, address(comptroller), DEFAULT_MAX_FEE, DEFAULT_MAX_SEGMENT_COUNT)
                )
            );
        }
        // We deploy normally in all other cases.
        else {
            comptroller = new DeployComptroller().run({ initialAdmin: users.admin });
            linear = new DeployLockupLinear().run({
                initialAdmin: users.admin,
                initialComptroller: comptroller,
                maxFee: DEFAULT_MAX_FEE
            });
            pro = new DeployLockupPro().run({
                initialAdmin: users.admin,
                initialComptroller: comptroller,
                maxFee: DEFAULT_MAX_FEE,
                maxSegmentCount: DEFAULT_MAX_SEGMENT_COUNT
            });
        }

        // Finally, label all the contracts just deployed.
        vm.label({ account: address(comptroller), newLabel: "SablierV2Comptroller" });
        vm.label({ account: address(linear), newLabel: "SablierV2LockupLinear" });
        vm.label({ account: address(pro), newLabel: "SablierV2LockupPro" });
    }
}
