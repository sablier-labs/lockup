// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { BaseTest as EvmBase } from "@sablier/evm-utils/src/tests/BaseTest.sol";

import { ISablierEscrow } from "src/interfaces/ISablierEscrow.sol";
import { SablierEscrow } from "src/SablierEscrow.sol";

import { Assertions } from "./utils/Assertions.sol";
import { Defaults } from "./utils/Defaults.sol";
import { Modifiers } from "./utils/Modifiers.sol";
import { OrderIds } from "./utils/Types.sol";

/// @notice Base test contract with common logic needed by all Escrow tests.
abstract contract Base_Test is Assertions, Modifiers {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    OrderIds internal orderIds;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierEscrow internal escrow;

    // Token contracts.
    IERC20 internal sellToken;
    IERC20 internal buyToken;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        EvmBase.setUp();

        // Deploy the defaults contract.
        defaults = new Defaults();

        // Use DAI as sell token and create a second 18-decimal token for buy.
        // This ensures consistent decimals for test amounts.
        sellToken = dai;
        buyToken = createToken("Wrapped Ether", "WETH", 18);
        tokens.push(buyToken); // Add to tokens array for user funding
        defaults.setSellToken(sellToken);
        defaults.setBuyToken(buyToken);

        // Deploy the protocol.
        deployProtocol();

        // Create test users.
        createTestUsers();
        defaults.setUsers(users);

        // Set the variables in the Modifiers contract.
        setVariables(defaults, users);

        // Set seller as the default caller for the tests.
        setMsgSender(users.seller);

        // Warp to Feb 1, 2025 at 00:00 UTC to provide a more realistic testing environment.
        vm.warp({ newTimestamp: FEB_1_2025 });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Create users for testing.
    function createTestUsers() internal {
        address[] memory spenders = new address[](1);
        spenders[0] = address(escrow);

        // Create test users.
        users.alice = createUser("Alice", spenders);
        users.eve = createUser("Eve", spenders);
        users.seller = createUser("Seller", spenders);
        users.buyer = createUser("Buyer", spenders);
        users.buyer2 = createUser("Buyer2", spenders);
    }

    /// @dev Deploys the SablierEscrow protocol.
    function deployProtocol() internal {
        escrow = new SablierEscrow(address(comptroller), DEFAULT_TRADE_FEE);
        vm.label({ account: address(escrow), newLabel: "SablierEscrow" });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  ORDER CREATION
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Creates a default order (open to any buyer) and returns the order ID.
    function createDefaultOrder() internal returns (uint256 orderId) {
        orderId = escrow.createOrder({
            sellToken: sellToken,
            sellAmount: SELL_AMOUNT,
            buyToken: buyToken,
            minBuyAmount: MIN_BUY_AMOUNT,
            buyer: address(0), // Any buyer
            expiryTime: EXPIRY
        });
    }

    /// @dev Creates an order with a designated buyer.
    function createOrderWithDesignatedBuyer(address designatedBuyer) internal returns (uint256 orderId) {
        orderId = escrow.createOrder({
            sellToken: sellToken,
            sellAmount: SELL_AMOUNT,
            buyToken: buyToken,
            minBuyAmount: MIN_BUY_AMOUNT,
            buyer: designatedBuyer,
            expiryTime: EXPIRY
        });
    }

    /// @dev Creates an order that will be expired at the current block timestamp.
    function createExpiredOrder() internal returns (uint256 orderId) {
        // Create order with expiry in the future.
        orderId = escrow.createOrder({
            sellToken: sellToken,
            sellAmount: SELL_AMOUNT,
            buyToken: buyToken,
            minBuyAmount: MIN_BUY_AMOUNT,
            buyer: address(0),
            expiryTime: EXPIRY
        });

        // Warp past expiry to make it expired.
        vm.warp({ newTimestamp: EXPIRY + 1 });
    }

    /// @dev Creates an order that never expires (expiryTime = 0).
    function createNonExpiringOrder() internal returns (uint256 orderId) {
        orderId = escrow.createOrder({
            sellToken: sellToken,
            sellAmount: SELL_AMOUNT,
            buyToken: buyToken,
            minBuyAmount: MIN_BUY_AMOUNT,
            buyer: address(0),
            expiryTime: ZERO_EXPIRY // Never expires
        });
    }

    /// @dev Creates a canceled order.
    function createCanceledOrder() internal returns (uint256 orderId) {
        orderId = createDefaultOrder();
        escrow.cancelOrder(orderId);
    }

    /// @dev Creates a filled order.
    function createFilledOrder() internal returns (uint256 orderId) {
        orderId = createDefaultOrder();

        // Switch to buyer to fill the order.
        setMsgSender(users.buyer);
        escrow.fillOrder(orderId, MIN_BUY_AMOUNT);

        // Switch back to seller.
        setMsgSender(users.seller);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                COMMON-REVERT-TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Expects a revert for null order operations.
    function expectRevert_Null(bytes memory callData) internal {
        (bool success, bytes memory returnData) = address(escrow).call(callData);
        assertFalse(success, "null call success");
        // Check that it reverted with the expected error.
        assertTrue(returnData.length > 0, "null call should revert");
    }

    /// @dev Expects a revert when caller is not comptroller.
    function expectRevert_CallerNotComptroller(bytes memory callData) internal {
        setMsgSender(users.eve);
        (bool success, bytes memory returnData) = address(escrow).call(callData);
        assertFalse(success, "non-comptroller call success");
        assertTrue(returnData.length > 0, "non-comptroller call should revert");
    }
}
