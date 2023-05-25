// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";

import {ERC20, MockERC20} from "./utils/mocks/MockERC20.sol";
import {ERC4626, MockERC4626} from "./utils/mocks/MockERC4626.sol";
import {SafeTransferLib} from "../src/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "../src/utils/FixedPointMathLib.sol";

contract ERC4626Test is SoladyTest {
    MockERC20 underlying;
    MockERC4626 vault;

    event Deposit(address indexed by, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed by,
        address indexed to,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    function setUp() public {
        underlying = new MockERC20("Mock Token", "TKN", 18);
        vault = new MockERC4626(address(underlying), "Mock Token Vault", "vwTKN", false, 0);
    }

    function _replaceWithVirtualSharesVault(uint8 decimalsOffset) internal {
        vault = new MockERC4626(address(underlying), "VSV", "VSVTKN", true, decimalsOffset);
    }

    function _replaceWithVirtualSharesVault() internal {
        _replaceWithVirtualSharesVault(0);
    }

    function testDifferentialFullMulDiv(uint256 x, uint256 y, uint256 d) public {
        d = type(uint256).max - d % 4;
        (bool success0,) = address(this).call(
            abi.encodeWithSignature("fullMulDivChecked(uint256,uint256,uint256)", x, y, d)
        );
        (bool success1,) = address(this).call(
            abi.encodeWithSignature("fullMulDivUnchecked(uint256,uint256,uint256)", x, y, d)
        );
        if (d == type(uint256).max) {
            assertFalse(success0);
            assertFalse(success1);
        }
        assertEq(success0, success1);
    }

    function fullMulDivChecked(uint256 x, uint256 y, uint256 d) public pure {
        FixedPointMathLib.fullMulDiv(x, y, d + 1);
    }

    function fullMulDivUnchecked(uint256 x, uint256 y, uint256 d) public pure {
        unchecked {
            FixedPointMathLib.fullMulDiv(x, y, d + 1);
        }
    }

    function testMetadata() public {
        assertEq(vault.name(), "Mock Token Vault");
        assertEq(vault.symbol(), "vwTKN");
        assertEq(vault.decimals(), 18);
    }

    function testUseVirtualShares() public {
        assertEq(vault.useVirtualShares(), false);
        _replaceWithVirtualSharesVault();
        assertEq(vault.useVirtualShares(), true);
        assertEq(vault.decimals(), 18);
        _replaceWithVirtualSharesVault(1);
        assertEq(vault.decimals(), 19);
    }

    function testTryGetAssetDecimals() public {
        unchecked {
            for (uint256 i = 0; i < 5; ++i) {
                _testTryGetAssetDecimals(uint8(i));
            }
            for (uint256 i = 125; i < 130; ++i) {
                _testTryGetAssetDecimals(uint8(i));
            }
            for (uint256 i = 250; i < 256; ++i) {
                _testTryGetAssetDecimals(uint8(i));
            }
        }
        vault = new MockERC4626(address(this), "", "", false, 0);
        assertEq(vault.decimals(), 18);
    }

    function _testTryGetAssetDecimals(uint8 i) internal {
        underlying = new MockERC20("", "", i);
        assertEq(underlying.decimals(), i);
        vault = new MockERC4626(address(underlying), "", "", false, 0);
        assertEq(vault.decimals(), i);
    }

    function testSingleDepositWithdraw(uint128 amount) public {
        if (amount == 0) amount = 1;

        uint256 aliceUnderlyingAmount = amount;

        address alice = address(0xABCD);

        underlying.mint(alice, aliceUnderlyingAmount);

        vm.prank(alice);
        underlying.approve(address(vault), aliceUnderlyingAmount);
        assertEq(underlying.allowance(alice, address(vault)), aliceUnderlyingAmount);

        uint256 alicePreDepositBal = underlying.balanceOf(alice);

        vm.prank(alice);
        uint256 aliceShareAmount = vault.deposit(aliceUnderlyingAmount, alice);

        assertEq(vault.afterDepositHookCalledCounter(), 1);

        // Expect exchange rate to be 1:1 on initial deposit.
        assertEq(aliceUnderlyingAmount, aliceShareAmount);
        assertEq(vault.previewWithdraw(aliceShareAmount), aliceUnderlyingAmount);
        assertEq(vault.previewDeposit(aliceUnderlyingAmount), aliceShareAmount);
        assertEq(vault.totalSupply(), aliceShareAmount);
        assertEq(vault.totalAssets(), aliceUnderlyingAmount);
        assertEq(vault.balanceOf(alice), aliceShareAmount);
        assertEq(vault.convertToAssets(vault.balanceOf(alice)), aliceUnderlyingAmount);
        assertEq(underlying.balanceOf(alice), alicePreDepositBal - aliceUnderlyingAmount);

        vm.prank(alice);
        vault.withdraw(aliceUnderlyingAmount, alice, alice);

        assertEq(vault.beforeWithdrawHookCalledCounter(), 1);

        assertEq(vault.totalAssets(), 0);
        assertEq(vault.balanceOf(alice), 0);
        assertEq(vault.convertToAssets(vault.balanceOf(alice)), 0);
        assertEq(underlying.balanceOf(alice), alicePreDepositBal);
    }

    function testSingleMintRedeem(uint128 amount) public {
        if (amount == 0) amount = 1;

        uint256 aliceShareAmount = amount;

        address alice = address(0xABCD);

        underlying.mint(alice, aliceShareAmount);

        vm.prank(alice);
        underlying.approve(address(vault), aliceShareAmount);
        assertEq(underlying.allowance(alice, address(vault)), aliceShareAmount);

        uint256 alicePreDepositBal = underlying.balanceOf(alice);

        vm.prank(alice);
        uint256 aliceUnderlyingAmount = vault.mint(aliceShareAmount, alice);

        assertEq(vault.afterDepositHookCalledCounter(), 1);

        // Expect exchange rate to be 1:1 on initial mint.
        assertEq(aliceShareAmount, aliceUnderlyingAmount);
        assertEq(vault.previewWithdraw(aliceShareAmount), aliceUnderlyingAmount);
        assertEq(vault.previewDeposit(aliceUnderlyingAmount), aliceShareAmount);
        assertEq(vault.totalSupply(), aliceShareAmount);
        assertEq(vault.totalAssets(), aliceUnderlyingAmount);
        assertEq(vault.balanceOf(alice), aliceUnderlyingAmount);
        assertEq(vault.convertToAssets(vault.balanceOf(alice)), aliceUnderlyingAmount);
        assertEq(underlying.balanceOf(alice), alicePreDepositBal - aliceUnderlyingAmount);

        vm.prank(alice);
        vault.redeem(aliceShareAmount, alice, alice);

        assertEq(vault.beforeWithdrawHookCalledCounter(), 1);

        assertEq(vault.totalAssets(), 0);
        assertEq(vault.balanceOf(alice), 0);
        assertEq(vault.convertToAssets(vault.balanceOf(alice)), 0);
        assertEq(underlying.balanceOf(alice), alicePreDepositBal);
    }

    function testMultipleMintDepositRedeemWithdraw() public {
        _testMultipleMintDepositRedeemWithdraw(0);
    }

    function testVirtualSharesMultipleMintDepositRedeemWithdraw() public {
        _replaceWithVirtualSharesVault();
        _testMultipleMintDepositRedeemWithdraw(1);
    }

    function _testMultipleMintDepositRedeemWithdraw(uint256 slippage) public {
        // Scenario:
        // A = Alice, B = Bob
        //  ________________________________________________________
        // | Vault shares | A share | A assets | B share | B assets |
        // |========================================================|
        // | 1. Alice mints 2000 shares (costs 2000 tokens)         |
        // |--------------|---------|----------|---------|----------|
        // |         2000 |    2000 |     2000 |       0 |        0 |
        // |--------------|---------|----------|---------|----------|
        // | 2. Bob deposits 4000 tokens (mints 4000 shares)        |
        // |--------------|---------|----------|---------|----------|
        // |         6000 |    2000 |     2000 |    4000 |     4000 |
        // |--------------|---------|----------|---------|----------|
        // | 3. Vault mutates by +3000 tokens...                    |
        // |    (simulated yield returned from strategy)...         |
        // |--------------|---------|----------|---------|----------|
        // |         6000 |    2000 |     3000 |    4000 |     6000 |
        // |--------------|---------|----------|---------|----------|
        // | 4. Alice deposits 2000 tokens (mints 1333 shares)      |
        // |--------------|---------|----------|---------|----------|
        // |         7333 |    3333 |     4999 |    4000 |     6000 |
        // |--------------|---------|----------|---------|----------|
        // | 5. Bob mints 2000 shares (costs 3001 assets)           |
        // |    NOTE: Bob's assets spent got rounded up             |
        // |    NOTE: Alice's vault assets got rounded up           |
        // |--------------|---------|----------|---------|----------|
        // |         9333 |    3333 |     5000 |    6000 |     9000 |
        // |--------------|---------|----------|---------|----------|
        // | 6. Vault mutates by +3000 tokens...                    |
        // |    (simulated yield returned from strategy)            |
        // |    NOTE: Vault holds 17001 tokens, but sum of          |
        // |          assetsOf() is 17000.                          |
        // |--------------|---------|----------|---------|----------|
        // |         9333 |    3333 |     6071 |    6000 |    10929 |
        // |--------------|---------|----------|---------|----------|
        // | 7. Alice redeem 1333 shares (2428 assets)              |
        // |--------------|---------|----------|---------|----------|
        // |         8000 |    2000 |     3643 |    6000 |    10929 |
        // |--------------|---------|----------|---------|----------|
        // | 8. Bob withdraws 2928 assets (1608 shares)             |
        // |--------------|---------|----------|---------|----------|
        // |         6392 |    2000 |     3643 |    4392 |     8000 |
        // |--------------|---------|----------|---------|----------|
        // | 9. Alice withdraws 3643 assets (2000 shares)           |
        // |    NOTE: Bob's assets have been rounded back up        |
        // |--------------|---------|----------|---------|----------|
        // |         4392 |       0 |        0 |    4392 |     8001 |
        // |--------------|---------|----------|---------|----------|
        // | 10. Bob redeem 4392 shares (8001 tokens)               |
        // |--------------|---------|----------|---------|----------|
        // |            0 |       0 |        0 |       0 |        0 |
        // |______________|_________|__________|_________|__________|

        address alice = address(0x9988776655443322110000112233445566778899);
        address bob = address(0x1122334455667788990000998877665544332211);

        uint256 mutationUnderlyingAmount = 3000;

        underlying.mint(alice, 4000);

        vm.prank(alice);
        underlying.approve(address(vault), 4000);

        assertEq(underlying.allowance(alice, address(vault)), 4000);

        underlying.mint(bob, 7001);

        vm.prank(bob);
        underlying.approve(address(vault), 7001);

        assertEq(underlying.allowance(bob, address(vault)), 7001);

        // 1. Alice mints 2000 shares (costs 2000 tokens)
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit Deposit(alice, alice, 2000, 2000);
        uint256 aliceUnderlyingAmount = vault.mint(2000, alice);

        uint256 aliceShareAmount = vault.previewDeposit(aliceUnderlyingAmount);
        assertEq(vault.afterDepositHookCalledCounter(), 1);

        // Expect to have received the requested mint amount.
        assertEq(aliceShareAmount, 2000);
        assertEq(vault.balanceOf(alice), aliceShareAmount);
        assertEq(vault.convertToAssets(vault.balanceOf(alice)), aliceUnderlyingAmount);
        assertEq(vault.convertToShares(aliceUnderlyingAmount), vault.balanceOf(alice));

        // Expect a 1:1 ratio before mutation.
        assertEq(aliceUnderlyingAmount, 2000);

        // Sanity check.
        assertEq(vault.totalSupply(), aliceShareAmount);
        assertEq(vault.totalAssets(), aliceUnderlyingAmount);

        // 2. Bob deposits 4000 tokens (mints 4000 shares)
        vm.prank(bob);
        vm.expectEmit(true, true, true, true);
        emit Deposit(bob, bob, 4000, 4000);
        uint256 bobShareAmount = vault.deposit(4000, bob);
        uint256 bobUnderlyingAmount = vault.previewWithdraw(bobShareAmount);
        assertEq(vault.afterDepositHookCalledCounter(), 2);

        // Expect to have received the requested underlying amount.
        assertEq(bobUnderlyingAmount, 4000);
        assertEq(vault.balanceOf(bob), bobShareAmount);
        assertEq(vault.convertToAssets(vault.balanceOf(bob)), bobUnderlyingAmount);
        assertEq(vault.convertToShares(bobUnderlyingAmount), vault.balanceOf(bob));

        // Expect a 1:1 ratio before mutation.
        assertEq(bobShareAmount, bobUnderlyingAmount);

        // Sanity check.
        uint256 preMutationShareBal = aliceShareAmount + bobShareAmount;
        uint256 preMutationBal = aliceUnderlyingAmount + bobUnderlyingAmount;
        assertEq(vault.totalSupply(), preMutationShareBal);
        assertEq(vault.totalAssets(), preMutationBal);
        assertEq(vault.totalSupply(), 6000);
        assertEq(vault.totalAssets(), 6000);

        // 3. Vault mutates by +3000 tokens...                    |
        //    (simulated yield returned from strategy)...
        // The Vault now contains more tokens than deposited which causes the exchange rate to change.
        // Alice share is 33.33% of the Vault, Bob 66.66% of the Vault.
        // Alice's share count stays the same but the underlying amount changes from 2000 to 3000.
        // Bob's share count stays the same but the underlying amount changes from 4000 to 6000.
        underlying.mint(address(vault), mutationUnderlyingAmount);
        assertEq(vault.totalSupply(), preMutationShareBal);
        assertEq(vault.totalAssets(), preMutationBal + mutationUnderlyingAmount);
        assertEq(vault.balanceOf(alice), aliceShareAmount);
        assertEq(
            vault.convertToAssets(vault.balanceOf(alice)),
            aliceUnderlyingAmount + (mutationUnderlyingAmount / 3) * 1 - slippage
        );
        assertEq(vault.balanceOf(bob), bobShareAmount);
        assertEq(
            vault.convertToAssets(vault.balanceOf(bob)),
            bobUnderlyingAmount + (mutationUnderlyingAmount / 3) * 2 - slippage
        );

        // 4. Alice deposits 2000 tokens (mints 1333 shares)
        vm.prank(alice);
        vault.deposit(2000, alice);

        assertEq(vault.totalSupply(), 7333);
        assertEq(vault.balanceOf(alice), 3333);
        assertEq(vault.convertToAssets(vault.balanceOf(alice)), 4999);
        assertEq(vault.balanceOf(bob), 4000);
        assertEq(vault.convertToAssets(vault.balanceOf(bob)), 6000);

        // 5. Bob mints 2000 shares (costs 3001 assets)
        // NOTE: Bob's assets spent got rounded up
        // NOTE: Alices's vault assets got rounded up
        vm.prank(bob);
        vault.mint(2000, bob);

        assertEq(vault.totalSupply(), 9333);
        assertEq(vault.balanceOf(alice), 3333);
        assertEq(vault.convertToAssets(vault.balanceOf(alice)), 5000 - slippage);
        assertEq(vault.balanceOf(bob), 6000);
        assertEq(vault.convertToAssets(vault.balanceOf(bob)), 9000);

        // Sanity checks:
        // Alice and bob should have spent all their tokens now
        assertEq(underlying.balanceOf(alice), 0);
        assertEq(underlying.balanceOf(bob) - slippage, 0);
        // Assets in vault: 4k (alice) + 7k (bob) + 3k (yield) + 1 (round up)
        assertEq(vault.totalAssets(), 14001 - slippage);

        // 6. Vault mutates by +3000 tokens
        // NOTE: Vault holds 17001 tokens, but sum of assetsOf() is 17000.
        underlying.mint(address(vault), mutationUnderlyingAmount);
        assertEq(vault.convertToAssets(vault.balanceOf(alice)), 6071 - slippage);
        assertEq(vault.convertToAssets(vault.balanceOf(bob)), 10929 - slippage);
        assertEq(vault.totalSupply(), 9333);
        assertEq(vault.totalAssets(), 17001 - slippage);

        // 7. Alice redeem 1333 shares (2428 assets)
        vm.prank(alice);
        vault.redeem(1333, alice, alice);

        assertEq(underlying.balanceOf(alice), 2428 - slippage);
        assertEq(vault.totalSupply(), 8000);
        assertEq(vault.totalAssets(), 14573);
        assertEq(vault.balanceOf(alice), 2000);
        assertEq(vault.convertToAssets(vault.balanceOf(alice)), 3643);
        assertEq(vault.balanceOf(bob), 6000);
        assertEq(vault.convertToAssets(vault.balanceOf(bob)), 10929);

        // 8. Bob withdraws 2929 assets (1608 shares)
        vm.prank(bob);
        vault.withdraw(2929, bob, bob);

        assertEq(underlying.balanceOf(bob) - slippage, 2929);
        assertEq(vault.totalSupply(), 6392);
        assertEq(vault.totalAssets(), 11644);
        assertEq(vault.balanceOf(alice), 2000);
        assertEq(vault.convertToAssets(vault.balanceOf(alice)), 3643);
        assertEq(vault.balanceOf(bob), 4392);
        assertEq(vault.convertToAssets(vault.balanceOf(bob)), 8000);

        // 9. Alice withdraws 3643 assets (2000 shares)
        // NOTE: Bob's assets have been rounded back up
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit Withdraw(alice, alice, alice, 3643, 2000);
        vault.withdraw(3643, alice, alice);
        assertEq(underlying.balanceOf(alice), 6071 - slippage);
        assertEq(vault.totalSupply(), 4392);
        assertEq(vault.totalAssets(), 8001);
        assertEq(vault.balanceOf(alice), 0);
        assertEq(vault.convertToAssets(vault.balanceOf(alice)), 0);
        assertEq(vault.balanceOf(bob), 4392);
        assertEq(vault.convertToAssets(vault.balanceOf(bob)), 8001 - slippage);

        // 10. Bob redeem 4392 shares (8001 tokens)
        vm.prank(bob);
        vm.expectEmit(true, true, true, true);
        emit Withdraw(bob, bob, bob, 8001 - slippage, 4392);
        vault.redeem(4392, bob, bob);
        assertEq(underlying.balanceOf(bob), 10930);
        assertEq(vault.totalSupply(), 0);
        assertEq(vault.totalAssets() - slippage, 0);
        assertEq(vault.balanceOf(alice), 0);
        assertEq(vault.convertToAssets(vault.balanceOf(alice)), 0);
        assertEq(vault.balanceOf(bob), 0);
        assertEq(vault.convertToAssets(vault.balanceOf(bob)), 0);

        // Sanity check
        assertEq(underlying.balanceOf(address(vault)) - slippage, 0);
    }

    function testDepositWithNotEnoughApprovalReverts() public {
        underlying.mint(address(this), 0.5e18);
        underlying.approve(address(vault), 0.5e18);
        assertEq(underlying.allowance(address(this), address(vault)), 0.5e18);

        vm.expectRevert(SafeTransferLib.TransferFromFailed.selector);
        vault.deposit(1e18, address(this));
    }

    function testWithdrawWithNotEnoughUnderlyingAmountReverts() public {
        underlying.mint(address(this), 0.5e18);
        underlying.approve(address(vault), 0.5e18);

        vault.deposit(0.5e18, address(this));

        vm.expectRevert(ERC4626.WithdrawMoreThanMax.selector);
        vault.withdraw(1e18, address(this), address(this));
    }

    function testRedeemWithNotEnoughShareAmountReverts() public {
        underlying.mint(address(this), 0.5e18);
        underlying.approve(address(vault), 0.5e18);

        vault.deposit(0.5e18, address(this));

        vm.expectRevert(ERC4626.RedeemMoreThanMax.selector);
        vault.redeem(1e18, address(this), address(this));
    }

    function testWithdrawWithNoUnderlyingAmountReverts() public {
        vm.expectRevert(ERC4626.WithdrawMoreThanMax.selector);
        vault.withdraw(1e18, address(this), address(this));
    }

    function testRedeemWithNoShareAmountReverts() public {
        vm.expectRevert(ERC4626.RedeemMoreThanMax.selector);
        vault.redeem(1e18, address(this), address(this));
    }

    function testDepositWithNoApprovalReverts() public {
        vm.expectRevert(SafeTransferLib.TransferFromFailed.selector);
        vault.deposit(1e18, address(this));
    }

    function testMintWithNoApprovalReverts() public {
        vm.expectRevert(SafeTransferLib.TransferFromFailed.selector);
        vault.mint(1e18, address(this));
    }

    function testMintZero() public {
        vault.mint(0, address(this));

        assertEq(vault.balanceOf(address(this)), 0);
        assertEq(vault.convertToAssets(vault.balanceOf(address(this))), 0);
        assertEq(vault.totalSupply(), 0);
        assertEq(vault.totalAssets(), 0);
    }

    function testWithdrawZero() public {
        vault.withdraw(0, address(this), address(this));

        assertEq(vault.balanceOf(address(this)), 0);
        assertEq(vault.convertToAssets(vault.balanceOf(address(this))), 0);
        assertEq(vault.totalSupply(), 0);
        assertEq(vault.totalAssets(), 0);
    }

    function testVaultInteractionsForSomeoneElse() public {
        // init 2 users with a 1e18 balance
        address alice = address(0xABCD);
        address bob = address(0xDCBA);
        underlying.mint(alice, 1e18);
        underlying.mint(bob, 1e18);

        vm.prank(alice);
        underlying.approve(address(vault), 1e18);

        vm.prank(bob);
        underlying.approve(address(vault), 1e18);

        // alice deposits 1e18 for bob
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit Deposit(alice, bob, 1e18, 1e18);
        vault.deposit(1e18, bob);

        assertEq(vault.balanceOf(alice), 0);
        assertEq(vault.balanceOf(bob), 1e18);
        assertEq(underlying.balanceOf(alice), 0);

        // bob mint 1e18 for alice
        vm.prank(bob);
        vm.expectEmit(true, true, true, true);
        emit Deposit(bob, alice, 1e18, 1e18);
        vault.mint(1e18, alice);
        assertEq(vault.balanceOf(alice), 1e18);
        assertEq(vault.balanceOf(bob), 1e18);
        assertEq(underlying.balanceOf(bob), 0);

        // alice redeem 1e18 for bob
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit Withdraw(alice, bob, alice, 1e18, 1e18);
        vault.redeem(1e18, bob, alice);

        assertEq(vault.balanceOf(alice), 0);
        assertEq(vault.balanceOf(bob), 1e18);
        assertEq(underlying.balanceOf(bob), 1e18);

        // bob withdraw 1e18 for alice
        vm.prank(bob);
        vm.expectEmit(true, true, true, true);
        emit Withdraw(bob, alice, bob, 1e18, 1e18);
        vault.withdraw(1e18, alice, bob);

        assertEq(vault.balanceOf(alice), 0);
        assertEq(vault.balanceOf(bob), 0);
        assertEq(underlying.balanceOf(alice), 1e18);
    }
}
