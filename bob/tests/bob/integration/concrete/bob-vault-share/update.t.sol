// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { BobVaultShare } from "src/BobVaultShare.sol";
import { IBobVaultShare } from "src/interfaces/IBobVaultShare.sol";

import { Integration_Test } from "../../Integration.t.sol";

/// @notice Tests for the `_update` internal function override in BobVaultShare.
/// @dev The `_update` function is called on every token operation (mint, burn, transfer).
/// It should call `onShareTransfer` on the SablierBob contract ONLY for transfers (not mint/burn).
contract Update_BobVaultShare_Integration_Concrete_Test is Integration_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    uint8 internal constant TEST_DECIMALS = 18;

    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    IBobVaultShare internal shareToken;
    MockSablierBobForShareTransfer internal mockBob;
    uint256 internal testVaultId;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public override {
        Integration_Test.setUp();

        // Stop any ongoing prank from base setup.
        vm.stopPrank();

        // Deploy a mock SablierBob that tracks onShareTransfer calls.
        mockBob = new MockSablierBobForShareTransfer();

        // Deploy BobVaultShare with the mock SablierBob.
        testVaultId = 1;
        shareToken = new BobVaultShare({
            name_: "Test Share",
            symbol_: "TST-100-12345-1",
            decimals_: TEST_DECIMALS,
            sablierBob: address(mockBob),
            vaultId: testVaultId
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                              TRANSFER BETWEEN USERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Tests that `onShareTransfer` IS called when shares are transferred between users.
    function test_Update_Transfer_CallsOnShareTransfer() external {
        uint256 mintAmount = 100e18;
        uint256 transferAmount = 40e18;

        // Mint tokens to depositor (onShareTransfer should NOT be called for mint).
        vm.prank(address(mockBob));
        BobVaultShare(address(shareToken)).mint(testVaultId, users.depositor, mintAmount);

        // Reset the mock state.
        mockBob.reset();

        // Transfer tokens from depositor to alice.
        vm.prank(users.depositor);
        IERC20(address(shareToken)).transfer(users.alice, transferAmount);

        // Verify onShareTransfer WAS called.
        assertTrue(mockBob.wasOnShareTransferCalled(), "onShareTransfer should be called on transfer");

        // Verify the parameters passed to onShareTransfer.
        assertEq(mockBob.lastVaultId(), testVaultId, "vaultId mismatch");
        assertEq(mockBob.lastFrom(), users.depositor, "from mismatch");
        assertEq(mockBob.lastTo(), users.alice, "to mismatch");
        assertEq(mockBob.lastAmount(), transferAmount, "amount mismatch");
        assertEq(mockBob.lastFromBalanceBefore(), mintAmount, "fromBalanceBefore mismatch");
    }

    /// @dev Tests that `fromBalanceBefore` is captured BEFORE the transfer occurs.
    function test_Update_Transfer_FromBalanceBeforeIsCapturedCorrectly() external {
        uint256 initialBalance = 100e18;
        uint256 transferAmount = 30e18;

        // Mint initial tokens.
        vm.prank(address(mockBob));
        BobVaultShare(address(shareToken)).mint(testVaultId, users.depositor, initialBalance);

        mockBob.reset();

        // Transfer tokens.
        vm.prank(users.depositor);
        IERC20(address(shareToken)).transfer(users.alice, transferAmount);

        // The fromBalanceBefore should be the balance BEFORE transfer (initialBalance).
        assertEq(mockBob.lastFromBalanceBefore(), initialBalance, "fromBalanceBefore should be pre-transfer balance");

        // After transfer, actual balance should be reduced.
        assertEq(shareToken.balanceOf(users.depositor), initialBalance - transferAmount, "post-transfer balance");
    }

    /// @dev Tests multiple sequential transfers update fromBalanceBefore correctly each time.
    function test_Update_Transfer_MultipleTransfersTrackBalanceCorrectly() external {
        uint256 initialBalance = 100e18;

        // Mint initial tokens.
        vm.prank(address(mockBob));
        BobVaultShare(address(shareToken)).mint(testVaultId, users.depositor, initialBalance);

        // First transfer: 30 tokens.
        mockBob.reset();
        vm.prank(users.depositor);
        IERC20(address(shareToken)).transfer(users.alice, 30e18);

        assertEq(mockBob.lastFromBalanceBefore(), 100e18, "first transfer: fromBalanceBefore");

        // Second transfer: 20 tokens.
        mockBob.reset();
        vm.prank(users.depositor);
        IERC20(address(shareToken)).transfer(users.alice, 20e18);

        // fromBalanceBefore should now be 70e18 (100 - 30).
        assertEq(mockBob.lastFromBalanceBefore(), 70e18, "second transfer: fromBalanceBefore");

        // Third transfer: 10 tokens.
        mockBob.reset();
        vm.prank(users.depositor);
        IERC20(address(shareToken)).transfer(users.alice, 10e18);

        // fromBalanceBefore should now be 50e18 (70 - 20).
        assertEq(mockBob.lastFromBalanceBefore(), 50e18, "third transfer: fromBalanceBefore");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       MINT
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Tests that `onShareTransfer` is NOT called when tokens are minted.
    function test_Update_Mint_DoesNotCallOnShareTransfer() external {
        uint256 mintAmount = 100e18;

        // Mint tokens (from = address(0)).
        vm.prank(address(mockBob));
        BobVaultShare(address(shareToken)).mint(testVaultId, users.depositor, mintAmount);

        // Verify onShareTransfer was NOT called.
        assertFalse(mockBob.wasOnShareTransferCalled(), "onShareTransfer should NOT be called on mint");
    }

    /// @dev Tests multiple mints do not trigger onShareTransfer.
    function test_Update_Mint_MultipleMints_DoesNotCallOnShareTransfer() external {
        // First mint.
        vm.prank(address(mockBob));
        BobVaultShare(address(shareToken)).mint(testVaultId, users.depositor, 50e18);
        assertFalse(mockBob.wasOnShareTransferCalled(), "first mint: onShareTransfer should NOT be called");

        mockBob.reset();

        // Second mint.
        vm.prank(address(mockBob));
        BobVaultShare(address(shareToken)).mint(testVaultId, users.depositor, 30e18);
        assertFalse(mockBob.wasOnShareTransferCalled(), "second mint: onShareTransfer should NOT be called");

        mockBob.reset();

        // Mint to different user.
        vm.prank(address(mockBob));
        BobVaultShare(address(shareToken)).mint(testVaultId, users.alice, 20e18);
        assertFalse(mockBob.wasOnShareTransferCalled(), "mint to different user: onShareTransfer should NOT be called");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       BURN
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Tests that `onShareTransfer` is NOT called when tokens are burned.
    function test_Update_Burn_DoesNotCallOnShareTransfer() external {
        uint256 mintAmount = 100e18;
        uint256 burnAmount = 40e18;

        // First mint tokens.
        vm.prank(address(mockBob));
        BobVaultShare(address(shareToken)).mint(testVaultId, users.depositor, mintAmount);

        // Reset mock state.
        mockBob.reset();

        // Burn tokens (to = address(0)).
        vm.prank(address(mockBob));
        BobVaultShare(address(shareToken)).burn(testVaultId, users.depositor, burnAmount);

        // Verify onShareTransfer was NOT called.
        assertFalse(mockBob.wasOnShareTransferCalled(), "onShareTransfer should NOT be called on burn");
    }

    /// @dev Tests multiple burns do not trigger onShareTransfer.
    function test_Update_Burn_MultipleBurns_DoesNotCallOnShareTransfer() external {
        // Mint tokens first.
        vm.prank(address(mockBob));
        BobVaultShare(address(shareToken)).mint(testVaultId, users.depositor, 100e18);

        mockBob.reset();

        // First burn.
        vm.prank(address(mockBob));
        BobVaultShare(address(shareToken)).burn(testVaultId, users.depositor, 30e18);
        assertFalse(mockBob.wasOnShareTransferCalled(), "first burn: onShareTransfer should NOT be called");

        mockBob.reset();

        // Second burn.
        vm.prank(address(mockBob));
        BobVaultShare(address(shareToken)).burn(testVaultId, users.depositor, 20e18);
        assertFalse(mockBob.wasOnShareTransferCalled(), "second burn: onShareTransfer should NOT be called");
    }

    /*//////////////////////////////////////////////////////////////////////////
                               COMBINED OPERATIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Tests a sequence of mint, transfer, burn operations to verify selective callback behavior.
    function test_Update_MintTransferBurn_SelectiveCallback() external {
        // Step 1: Mint - should NOT call onShareTransfer.
        vm.prank(address(mockBob));
        BobVaultShare(address(shareToken)).mint(testVaultId, users.depositor, 100e18);
        assertFalse(mockBob.wasOnShareTransferCalled(), "mint: should NOT call onShareTransfer");

        mockBob.reset();

        // Step 2: Transfer - should call onShareTransfer.
        vm.prank(users.depositor);
        IERC20(address(shareToken)).transfer(users.alice, 30e18);
        assertTrue(mockBob.wasOnShareTransferCalled(), "transfer: should call onShareTransfer");

        mockBob.reset();

        // Step 3: Burn from alice - should NOT call onShareTransfer.
        vm.prank(address(mockBob));
        BobVaultShare(address(shareToken)).burn(testVaultId, users.alice, 10e18);
        assertFalse(mockBob.wasOnShareTransferCalled(), "burn: should NOT call onShareTransfer");

        mockBob.reset();

        // Step 4: Another transfer - should call onShareTransfer.
        vm.prank(users.alice);
        IERC20(address(shareToken)).transfer(users.depositor, 5e18);
        assertTrue(mockBob.wasOnShareTransferCalled(), "second transfer: should call onShareTransfer");
    }

    /*//////////////////////////////////////////////////////////////////////////
                               TRANSFER FROM (APPROVAL)
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Tests that `onShareTransfer` is called for transferFrom operations.
    function test_Update_TransferFrom_CallsOnShareTransfer() external {
        uint256 mintAmount = 100e18;
        uint256 transferAmount = 25e18;

        // Mint tokens.
        vm.prank(address(mockBob));
        BobVaultShare(address(shareToken)).mint(testVaultId, users.depositor, mintAmount);

        // Approve alice to spend depositor's tokens.
        vm.prank(users.depositor);
        IERC20(address(shareToken)).approve(users.alice, transferAmount);

        mockBob.reset();

        // Alice transfers depositor's tokens to eve using transferFrom.
        vm.prank(users.alice);
        IERC20(address(shareToken)).transferFrom(users.depositor, users.eve, transferAmount);

        // Verify onShareTransfer WAS called.
        assertTrue(mockBob.wasOnShareTransferCalled(), "onShareTransfer should be called on transferFrom");

        // Verify parameters.
        assertEq(mockBob.lastFrom(), users.depositor, "from should be depositor");
        assertEq(mockBob.lastTo(), users.eve, "to should be eve");
        assertEq(mockBob.lastAmount(), transferAmount, "amount mismatch");
        assertEq(mockBob.lastFromBalanceBefore(), mintAmount, "fromBalanceBefore mismatch");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  SELF-TRANSFER
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Tests that `onShareTransfer` is called even for self-transfers.
    function test_Update_SelfTransfer_CallsOnShareTransfer() external {
        uint256 mintAmount = 100e18;
        uint256 transferAmount = 10e18;

        // Mint tokens.
        vm.prank(address(mockBob));
        BobVaultShare(address(shareToken)).mint(testVaultId, users.depositor, mintAmount);

        mockBob.reset();

        // Self-transfer: depositor transfers to themselves.
        vm.prank(users.depositor);
        IERC20(address(shareToken)).transfer(users.depositor, transferAmount);

        // Verify onShareTransfer WAS called (from == to, but neither is address(0)).
        assertTrue(mockBob.wasOnShareTransferCalled(), "onShareTransfer should be called on self-transfer");

        // Verify parameters.
        assertEq(mockBob.lastFrom(), users.depositor, "from should be depositor");
        assertEq(mockBob.lastTo(), users.depositor, "to should be depositor");
        assertEq(mockBob.lastAmount(), transferAmount, "amount mismatch");
    }

    /*//////////////////////////////////////////////////////////////////////////
                               ZERO AMOUNT TRANSFER
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Tests that `onShareTransfer` is called for zero amount transfers.
    function test_Update_ZeroAmountTransfer_CallsOnShareTransfer() external {
        uint256 mintAmount = 100e18;

        // Mint tokens.
        vm.prank(address(mockBob));
        BobVaultShare(address(shareToken)).mint(testVaultId, users.depositor, mintAmount);

        mockBob.reset();

        // Transfer zero tokens.
        vm.prank(users.depositor);
        IERC20(address(shareToken)).transfer(users.alice, 0);

        // Verify onShareTransfer WAS called (even for zero amount).
        assertTrue(mockBob.wasOnShareTransferCalled(), "onShareTransfer should be called for zero amount transfer");

        // Verify parameters.
        assertEq(mockBob.lastAmount(), 0, "amount should be zero");
        assertEq(mockBob.lastFromBalanceBefore(), mintAmount, "fromBalanceBefore should be unchanged");
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                    MOCK
//////////////////////////////////////////////////////////////////////////*/

/// @notice Mock contract that tracks calls to `onShareTransfer`.
contract MockSablierBobForShareTransfer {
    bool private _wasOnShareTransferCalled;
    uint256 private _lastVaultId;
    address private _lastFrom;
    address private _lastTo;
    uint256 private _lastAmount;
    uint256 private _lastFromBalanceBefore;

    function onShareTransfer(
        uint256 vaultId,
        address from,
        address to,
        uint256 amount,
        uint256 fromBalanceBefore
    )
        external
    {
        _wasOnShareTransferCalled = true;
        _lastVaultId = vaultId;
        _lastFrom = from;
        _lastTo = to;
        _lastAmount = amount;
        _lastFromBalanceBefore = fromBalanceBefore;
    }

    function wasOnShareTransferCalled() external view returns (bool) {
        return _wasOnShareTransferCalled;
    }

    function lastVaultId() external view returns (uint256) {
        return _lastVaultId;
    }

    function lastFrom() external view returns (address) {
        return _lastFrom;
    }

    function lastTo() external view returns (address) {
        return _lastTo;
    }

    function lastAmount() external view returns (uint256) {
        return _lastAmount;
    }

    function lastFromBalanceBefore() external view returns (uint256) {
        return _lastFromBalanceBefore;
    }

    function reset() external {
        _wasOnShareTransferCalled = false;
        _lastVaultId = 0;
        _lastFrom = address(0);
        _lastTo = address(0);
        _lastAmount = 0;
        _lastFromBalanceBefore = 0;
    }
}
