// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { BaseTest as EvmBase } from "@sablier/evm-utils/src/tests/BaseTest.sol";
import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { ISablierLidoAdapter } from "src/interfaces/ISablierLidoAdapter.sol";
import { SablierBob } from "src/SablierBob.sol";
import { SablierLidoAdapter } from "src/SablierLidoAdapter.sol";
import {
    ChainlinkOracleMock,
    ChainlinkOracleWith18Decimals,
    ChainlinkOracleWithRevertingDecimals,
    ChainlinkOracleWithRevertingPrice,
    ChainlinkOracleZeroPrice
} from "@sablier/evm-utils/src/mocks/ChainlinkMocks.sol";

import { MockAdapterInvalidInterface } from "./mocks/MockAdapter.sol";
import { MockCurvePool, MockStETH, MockWETH9, MockWstETH } from "./mocks/MockLido.sol";
import { Assertions } from "./utils/Assertions.sol";
import { Defaults } from "./utils/Defaults.sol";
import { Modifiers } from "./utils/Modifiers.sol";
import { VaultIds } from "./utils/Types.sol";

/// @notice Base test contract with common logic needed by all tests.
abstract contract Base_Test is Assertions, Modifiers {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    VaultIds internal vaultIds;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierBob internal bob;
    SablierLidoAdapter internal adapter;
    MockAdapterInvalidInterface internal mockAdapterInvalid;
    ChainlinkOracleMock internal mockOracle;
    ChainlinkOracleWith18Decimals internal mockOracleInvalidDecimals;
    ChainlinkOracleZeroPrice internal mockOracleInvalidPrice;
    ChainlinkOracleWithRevertingDecimals internal mockOracleReverting;
    ChainlinkOracleWithRevertingPrice internal mockOracleRevertingOnLatestRoundData;

    // External protocol mocks (Lido ecosystem).
    MockWETH9 internal weth;
    MockStETH internal steth;
    MockWstETH internal wsteth;
    MockCurvePool internal curvePool;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        EvmBase.setUp();

        // Deploy mock oracles.
        mockOracle = new ChainlinkOracleMock();
        mockOracle.setPrice(uint256(INITIAL_PRICE));
        mockOracleInvalidDecimals = new ChainlinkOracleWith18Decimals();
        mockOracleInvalidPrice = new ChainlinkOracleZeroPrice();
        mockOracleReverting = new ChainlinkOracleWithRevertingDecimals();
        mockOracleRevertingOnLatestRoundData = new ChainlinkOracleWithRevertingPrice();

        // Label the mock oracles.
        vm.label({ account: address(mockOracle), newLabel: "ChainlinkOracleMock" });
        vm.label({ account: address(mockOracleInvalidDecimals), newLabel: "ChainlinkOracleWith18Decimals" });
        vm.label({ account: address(mockOracleInvalidPrice), newLabel: "ChainlinkOracleZeroPrice" });
        vm.label({ account: address(mockOracleReverting), newLabel: "ChainlinkOracleWithRevertingDecimals" });
        vm.label({
            account: address(mockOracleRevertingOnLatestRoundData),
            newLabel: "ChainlinkOracleWithRevertingPrice"
        });

        // Deploy the defaults contract.
        defaults = new Defaults();
        defaults.setToken(dai);
        defaults.setOracle(AggregatorV3Interface(address(mockOracle)));

        // Deploy the protocol.
        deployProtocol();

        // Deploy external Lido/Curve mocks.
        deployExternalMocks();

        // Deploy the real adapter with external mocks.
        deployAdapter();

        // Deploy invalid adapter for error testing.
        mockAdapterInvalid = new MockAdapterInvalidInterface();
        vm.label({ account: address(mockAdapterInvalid), newLabel: "MockAdapterInvalid" });

        // Create test users.
        createTestUsers();
        defaults.setUsers(users);

        // Set the variables in the Modifiers contract.
        setVariables(defaults, users);

        // Set depositor as the default caller for the tests.
        setMsgSender(users.depositor);

        // Warp to Feb 1, 2025 at 00:00 UTC to provide a more realistic testing environment.
        vm.warp({ newTimestamp: FEB_1_2025 });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Create users for testing.
    function createTestUsers() internal {
        address[] memory spenders = new address[](1);
        spenders[0] = address(bob);

        // Create test users.
        users.alice = createUser("Alice", spenders);
        users.eve = createUser("Eve", spenders);
        users.depositor = createUser("Depositor", spenders);
        users.depositor2 = createUser("Depositor2", spenders);

        // Give ETH to users and deposit into WETH (so WETH contract has ETH backing).
        vm.deal(users.depositor, 1000 ether);
        vm.deal(users.depositor2, 1000 ether);
        vm.deal(users.alice, 1000 ether);

        // Deposit ETH to get WETH (this ensures WETH contract has ETH to return on withdraw).
        vm.startPrank(users.depositor);
        weth.deposit{ value: 1000 ether }();
        IERC20(address(weth)).approve(address(bob), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(users.depositor2);
        weth.deposit{ value: 1000 ether }();
        IERC20(address(weth)).approve(address(bob), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(users.alice);
        weth.deposit{ value: 1000 ether }();
        IERC20(address(weth)).approve(address(bob), type(uint256).max);
        vm.stopPrank();
    }

    /// @dev Deploys the SablierBob protocol.
    function deployProtocol() internal {
        bob = new SablierBob(address(comptroller));
        vm.label({ account: address(bob), newLabel: "SablierBob" });
    }

    /// @dev Deploys external Lido/Curve protocol mocks at the mainnet constant addresses.
    function deployExternalMocks() internal {
        // Mainnet addresses used as constants in SablierLidoAdapter.
        address payable wethMainnet = payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        address payable stethMainnet = payable(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
        address payable wstethMainnet = payable(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
        address payable curvePoolMainnet = payable(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);

        // Deploy WETH mock at mainnet address using deployCodeTo.
        deployCodeTo("MockLido.sol:MockWETH9", wethMainnet);
        weth = MockWETH9(wethMainnet);
        vm.label({ account: wethMainnet, newLabel: "WETH" });
        defaults.setWeth(IERC20(wethMainnet));

        // Deploy stETH mock at mainnet address.
        deployCodeTo("MockLido.sol:MockStETH", stethMainnet);
        steth = MockStETH(stethMainnet);
        vm.label({ account: stethMainnet, newLabel: "stETH" });

        // Deploy wstETH mock at mainnet address with mainnet stETH constructor arg.
        deployCodeTo("MockLido.sol:MockWstETH", abi.encode(stethMainnet), wstethMainnet);
        wsteth = MockWstETH(wstethMainnet);
        vm.label({ account: wstethMainnet, newLabel: "wstETH" });

        // Deploy Curve pool mock at mainnet address with mainnet stETH constructor arg.
        deployCodeTo("MockLido.sol:MockCurvePool", abi.encode(stethMainnet), curvePoolMainnet);
        curvePool = MockCurvePool(curvePoolMainnet);
        vm.label({ account: curvePoolMainnet, newLabel: "CurvePool" });

        // Fund Curve pool with ETH for swaps.
        vm.deal(curvePoolMainnet, 10_000 ether);
    }

    /// @dev Deploys the real SablierLidoAdapter.
    function deployAdapter() internal {
        adapter = new SablierLidoAdapter({
            initialComptroller: address(comptroller),
            sablierBob: address(bob),
            curvePool: address(curvePool),
            stETH: address(steth),
            wETH: address(weth),
            wstETH: address(wsteth),
            initialSlippageTolerance: DEFAULT_SLIPPAGE_TOLERANCE,
            initialYieldFee: DEFAULT_YIELD_FEE
        });
        vm.label({ account: address(adapter), newLabel: "SablierLidoAdapter" });
        defaults.setAdapter(ISablierLidoAdapter(address(adapter)));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  VAULT CREATION
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Creates a default vault with DAI and returns the vault ID.
    function createDefaultVault() internal returns (uint256 vaultId) {
        vaultId = bob.createVault({
            token: IERC20(address(dai)),
            oracle: AggregatorV3Interface(address(mockOracle)),
            expiry: EXPIRY,
            targetPrice: TARGET_PRICE
        });
    }

    /// @dev Creates a vault with the specified token.
    function createVaultWithToken(IERC20 token) internal returns (uint256 vaultId) {
        vaultId = bob.createVault({
            token: token,
            oracle: AggregatorV3Interface(address(mockOracle)),
            expiry: EXPIRY,
            targetPrice: TARGET_PRICE
        });
    }

    /// @dev Creates a vault with an adapter configured.
    function createVaultWithAdapter() internal returns (uint256 vaultId) {
        // Set the default adapter for WETH.
        setMsgSender(address(comptroller));
        bob.setDefaultAdapter(IERC20(address(weth)), ISablierLidoAdapter(address(adapter)));

        setMsgSender(users.depositor);
        vaultId = bob.createVault({
            token: IERC20(address(weth)),
            oracle: AggregatorV3Interface(address(mockOracle)),
            expiry: EXPIRY,
            targetPrice: TARGET_PRICE
        });
    }

    /// @dev Creates a vault that will be expired at the current block timestamp.
    function createExpiredVault() internal returns (uint256 vaultId) {
        // Create vault with expiry in the future.
        vaultId = bob.createVault({
            token: IERC20(address(dai)),
            oracle: AggregatorV3Interface(address(mockOracle)),
            expiry: EXPIRY,
            targetPrice: TARGET_PRICE
        });

        // Warp past expiry to make it settled.
        vm.warp({ newTimestamp: EXPIRY + 1 });
    }

    /// @dev Creates a vault that is settled via price reaching target.
    function createSettledVaultViaPrice() internal returns (uint256 vaultId) {
        vaultId = createDefaultVault();

        // Set oracle price to target.
        mockOracle.setPrice(SETTLED_PRICE);

        // Sync the vault to update the price.
        bob.syncPriceFromOracle(vaultId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    DEPOSITS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Makes a deposit into a vault.
    function depositIntoVault(uint256 vaultId, uint128 amount) internal {
        bob.enter(vaultId, amount);
    }

    /// @dev Makes a deposit into a vault from a specific user.
    function depositIntoVaultFrom(uint256 vaultId, uint128 amount, address user) internal {
        setMsgSender(user);
        bob.enter(vaultId, amount);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                COMMON-REVERT-TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Expects a revert for null vault operations.
    function expectRevert_Null(bytes memory callData) internal {
        (bool success, bytes memory returnData) = address(bob).call(callData);
        assertFalse(success, "null call success");
        // Check that it reverted with the expected error.
        assertTrue(returnData.length > 0, "null call should revert");
    }

    /// @dev Expects a revert when caller is not comptroller.
    function expectRevert_CallerNotComptroller(bytes memory callData) internal {
        setMsgSender(users.eve);
        (bool success, bytes memory returnData) = address(bob).call(callData);
        assertFalse(success, "non-comptroller call success");
        assertTrue(returnData.length > 0, "non-comptroller call should revert");
    }
}
