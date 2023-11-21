// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";

import {ERC6909, MockERC6909} from "./utils/mocks/MockERC6909.sol";

contract ERC6909Test is SoladyTest {
    MockERC6909 token;

    event Transfer(
        address by, address indexed from, address indexed to, uint256 indexed id, uint256 amount
    );

    event OperatorSet(address indexed owner, address indexed spender, bool approved);

    event Approval(
        address indexed owner, address indexed spender, uint256 indexed id, uint256 amount
    );

    function setUp() public {
        token = new MockERC6909();
    }

    function testMetadata() public {
        assertEq(token.name(), "Solady Token");
        assertEq(token.symbol(), "ST");
    }

    function testMint() public {
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), address(0), address(0xBEEF), 1, 1e18);

        token.mint(address(0xBEEF), 1, 1e18);
        assertEq(token.balanceOf(address(0xBEEF), 1), 1e18);
    }

    function testDecimals() public {
        assertEq(token.decimals(1), 18);
    }

    function testBurn() public {
        token.mint(address(0xBEEF), 1, 1e18);

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), address(0xBEEF), address(0), 1, 0.9e18);
        token.burn(address(0xBEEF), 1, 0.9e18);

        assertEq(token.balanceOf(address(0xBEEF), 1), 0.1e18);
    }

    function testApprove() public {
        vm.expectEmit(true, true, true, true);
        emit Approval(address(this), address(0xBEEF), 1, 1e18);
        assertTrue(token.approve(address(0xBEEF), 1, 1e18));

        assertEq(token.allowance(address(this), address(0xBEEF), 1), 1e18);
    }

    function testTransfer() public {
        token.mint(address(this), 1, 1e18);

        assertEq(token.balanceOf(address(this), 1), 1e18);

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), address(this), address(0xBEEF), 1, 1e18);
        assertTrue(token.transfer(address(0xBEEF), 1, 1e18));
        assertEq(token.balanceOf(address(this), 1), 0);
        assertEq(token.balanceOf(address(0xBEEF), 1), 1e18);
    }

    function testTransferFrom() public {
        address from = address(0xABCD);

        token.mint(from, 1, 1e18);

        _approve(from, address(this), 1, 1e18);

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), from, address(0xBEEF), 1, 1e18);
        assertTrue(token.transferFrom(from, address(0xBEEF), 1, 1e18));

        assertEq(token.allowance(from, address(this), 1), 0);

        assertEq(token.balanceOf(from, 1), 0);
        assertEq(token.balanceOf(address(0xBEEF), 1), 1e18);
    }

    function testInfiniteApproveTransferFrom() public {
        address from = address(0xABCD);

        token.mint(from, 1, 1e18);

        _approve(from, address(this), 1, type(uint256).max);

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), from, address(0xBEEF), 1, 1e18);
        assertTrue(token.transferFrom(from, address(0xBEEF), 1, 1e18));

        assertEq(token.allowance(from, address(this), 1), type(uint256).max);

        assertEq(token.balanceOf(from, 1), 0);
        assertEq(token.balanceOf(address(0xBEEF), 1), 1e18);
    }

    function testOperatorTransferFrom() public {
        address from = address(0xABcD);

        token.mint(from, 1, 1e18);

        _setOperator(from, address(this), true);

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), from, address(0xBEEF), 1, 1e18);
        assertTrue(token.transferFrom(from, address(0xBEEF), 1, 1e18));

        assertEq(token.balanceOf(from, 1), 0);
        assertEq(token.balanceOf(address(0xBEEF), 1), 1e18);
    }

    function testSetOperator() public {
        assertEq(token.isOperator(address(this), address(0xBEEF)), false);

        vm.expectEmit(true, true, true, true);
        emit OperatorSet(address(this), address(0xBEEF), true);
        token.setOperator(address(0xBEEF), true);
        assertEq(token.isOperator(address(this), address(0xBEEF)), true);
    }

    function testTokenURI() public {
        token.mint(address(0xBEEF), 1, 1e18);
        assertEq(token.tokenURI(1), "http://solady.org/1");
    }

    function testMintOverMaxUintReverts() public {
        token.mint(address(this), 1, type(uint256).max);
        vm.expectRevert(ERC6909.BalanceOverflow.selector);
        token.mint(address(this), 1, 1);
    }

    function testTransferOverMaxUintReverts() public {
        token.mint(address(this), 1, type(uint256).max);
        token.transfer(address(0xBEEF), 1, type(uint256).max);
        token.mint(address(this), 1, 1);
        vm.expectRevert(ERC6909.BalanceOverflow.selector);
        token.transfer(address(0xBEEF), 1, 1);
    }

    function testTransferFromOverMaxUintReverts() public {
        address from = address(0xABCD);

        _approve(from, address(this), 1, type(uint256).max);

        token.mint(from, 1, type(uint256).max);
        token.transferFrom(from, address(0xBEEF), 1, type(uint256).max);

        token.mint(from, 1, 1);
        vm.expectRevert(ERC6909.BalanceOverflow.selector);
        token.transferFrom(from, address(0xBEEF), 1, 1);
    }

    function testTransferInsufficientBalanceReverts() public {
        token.mint(address(this), 1, 0.9e18);
        _expectInsufficientBalanceRevert();
        token.transfer(address(0xBEEF), 1, 1e18);
    }

    function testTransferFromInsufficientPermission() public {
        address from = address(0xABCD);

        token.mint(from, 1, 1e18);

        _approve(from, address(this), 1, 0.9e18);

        _expectInsufficientPermissionRevert();
        token.transferFrom(from, address(0xBEEF), 1, 1e18);
    }

    function testTransferFromInsufficientBalanceReverts() public {
        address from = address(0xABCD);

        token.mint(from, 1, 0.9e18);

        _approve(from, address(this), 1, 1e18);

        _expectInsufficientBalanceRevert();
        token.transferFrom(from, address(0xBEEF), 1, 1e18);
    }

    function testMint(address to, uint256 id, uint256 amount) public {
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), address(0), to, id, amount);
        token.mint(to, id, amount);

        assertEq(token.balanceOf(to, id), amount);
    }

    function testBurn(address from, uint256 id, uint256 mintAmount, uint256 burnAmount) public {
        burnAmount = _bound(burnAmount, 0, mintAmount);

        token.mint(from, id, mintAmount);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), from, address(0), id, burnAmount);
        token.burn(from, id, burnAmount);

        assertEq(token.balanceOf(from, id), mintAmount - burnAmount);
    }

    function testApprove(address to, uint256 id, uint256 amount) public {
        _approve(address(this), to, id, amount);
    }

    function testTransfer(address to, uint256 id, uint256 amount) public {
        token.mint(address(this), id, amount);

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), address(this), to, id, amount);
        assertTrue(token.transfer(to, id, amount));

        if (address(this) == to) {
            assertEq(token.balanceOf(address(this), id), amount);
        } else {
            assertEq(token.balanceOf(address(this), id), 0);
            assertEq(token.balanceOf(to, id), amount);
        }
    }

    function testTransferFrom(
        address spender,
        address from,
        address to,
        uint256 id,
        uint256 approval,
        uint256 amount
    ) public {
        amount = _bound(amount, 0, approval);

        token.mint(from, id, amount);
        assertEq(token.balanceOf(from, id), amount);

        _approve(from, spender, id, approval);

        vm.expectEmit(true, true, true, true);
        emit Transfer(spender, from, to, id, amount);
        vm.prank(spender);
        assertTrue(token.transferFrom(from, to, id, amount));

        if (approval == type(uint256).max) {
            assertEq(token.allowance(from, spender, id), approval);
        } else {
            assertEq(token.allowance(from, spender, id), approval - amount);
        }

        if (from == to) {
            assertEq(token.balanceOf(from, id), amount);
        } else {
            assertEq(token.balanceOf(from, id), 0);
            assertEq(token.balanceOf(to, id), amount);
        }
    }

    function testSetOperator(address owner, address spender, bool approved) public {
        _setOperator(owner, spender, approved);
    }

    function testMintOverMaxUintReverts(
        address to,
        uint256 id,
        uint256 amount0,
        uint256 amount1
    ) public {
        amount0 = _bound(amount0, 1, type(uint256).max);
        amount1 = _bound(amount1, type(uint256).max - amount0 + 1, type(uint256).max);
        token.mint(to, id, amount0);

        vm.expectRevert(ERC6909.BalanceOverflow.selector);
        token.mint(to, id, amount1);
    }

    function testBurnInsufficientBalanceReverts(
        address to,
        uint256 mintAmount,
        uint256 id,
        uint256 burnAmount
    ) public {
        if (mintAmount == type(uint256).max) mintAmount--;
        burnAmount = _bound(burnAmount, mintAmount + 1, type(uint256).max);

        token.mint(to, id, mintAmount);

        _expectInsufficientBalanceRevert();
        token.burn(to, id, burnAmount);
    }

    function testTransferOverMaxUintReverts(
        address to,
        uint256 id,
        uint256 amount0,
        uint256 amount1
    ) public {
        amount0 = _bound(amount0, 1, type(uint256).max);
        amount1 = _bound(amount1, type(uint256).max - amount0 + 1, type(uint256).max);

        token.mint(address(this), id, amount0);
        token.transfer(to, id, amount0);
        token.mint(address(this), id, amount1);

        vm.expectRevert(ERC6909.BalanceOverflow.selector);
        token.transfer(to, id, amount1);
    }

    function testTransferInsufficientBalanceReverts(
        address to,
        uint256 id,
        uint256 mintAmount,
        uint256 sendAmount
    ) public {
        if (mintAmount == type(uint256).max) mintAmount--;
        sendAmount = _bound(sendAmount, mintAmount + 1, type(uint256).max);

        token.mint(address(this), id, mintAmount);

        _expectInsufficientBalanceRevert();
        token.transfer(to, id, sendAmount);
    }

    function testTransferFromOverMaxUintReverts(
        address to,
        uint256 id,
        uint256 amount0,
        uint256 amount1
    ) public {
        amount0 = _bound(amount0, 1, type(uint256).max);
        amount1 = _bound(amount1, type(uint256).max - amount0 + 1, type(uint256).max);

        address from = address(0xABCD);

        token.mint(from, id, amount0);
        _approve(from, address(this), id, amount0);

        token.transferFrom(from, to, id, amount0);

        token.mint(from, id, amount1);
        _approve(from, address(this), id, amount1);

        vm.expectRevert(ERC6909.BalanceOverflow.selector);
        token.transferFrom(from, to, id, amount1);
    }

    function testTransferFromInsufficientAllowanceReverts(
        address to,
        uint256 id,
        uint256 approval,
        uint256 amount
    ) public {
        if (approval == type(uint256).max) approval--;
        amount = _bound(amount, approval + 1, type(uint256).max);

        address from = address(0xABCD);

        token.mint(from, amount, id);

        _approve(from, address(this), id, approval);

        _expectInsufficientPermissionRevert();
        token.transferFrom(from, to, id, amount);
    }

    function testTransferFromInsufficientBalanceReverts(
        address to,
        uint256 id,
        uint256 mintAmount,
        uint256 sendAmount
    ) public {
        if (mintAmount == type(uint256).max) mintAmount--;
        sendAmount = _bound(sendAmount, mintAmount + 1, type(uint256).max);

        address from = address(0xABCD);

        token.mint(from, id, mintAmount);

        _approve(from, address(this), id, sendAmount);

        _expectInsufficientBalanceRevert();
        token.transferFrom(from, to, id, sendAmount);
    }

    function testTransferFromCallerIsNotOperator(address to, uint256 id, uint256 amount) public {
        amount = _bound(amount, 1, type(uint256).max);

        address from = address(0xABCD);

        token.mint(from, id, amount);

        _expectInsufficientPermissionRevert();
        token.transferFrom(from, to, id, amount);
    }

    struct _TestTemps {
        uint256 id;
        uint256 allowance;
        bool isOperator;
        uint256 balance;
        uint256 amount;
        address by;
        address from;
        address to;
        bool success;
    }

    function testDirectSetOperator() public {
        _directSetOperator(address(1), address(2), true);
    }

    function testDirectApprove() public {
        _directApprove(address(1), address(2), 1, 123);
    }

    function testDirectTransfer() public {
        token.mint(address(2), 1, 1);
        vm.prank(address(2));
        token.approve(address(1), 1, 1);
        token.directTransferFrom(address(1), address(2), address(3), 1, 1);
    }

    function testDirectFunctions(uint256) public {
        _TestTemps memory t;
        t.id = _random();
        t.by = _random() % 16 == 0 ? address(0) : _randomAddress();
        t.from = _randomAddress();
        t.to = _randomAddress();

        for (uint256 q; q != 2; ++q) {
            t.success = false;
            t.allowance = _random();
            t.balance = _random();
            t.amount = _random();
            t.isOperator = _random() % 4 == 0;
            t.id ^= 1;

            token.mint(t.from, t.id, t.balance);
            if (_random() % 2 == 0) {
                _directSetOperator(t.from, t.by, t.isOperator);
                _directApprove(t.from, t.by, t.id, t.allowance);
            } else {
                _setOperator(t.from, t.by, t.isOperator);
                _directApprove(t.from, t.by, t.id, t.allowance);
            }

            if (t.balance >= t.amount) {
                if (t.by == address(0) || t.isOperator || t.allowance >= t.amount) {
                    t.success = true;
                } else {
                    _expectInsufficientPermissionRevert();
                }
            } else {
                if (t.by == address(0) || t.isOperator || t.allowance >= t.amount) {
                    _expectInsufficientBalanceRevert();
                } else {
                    _expectInsufficientPermissionRevert();
                }
            }

            if (t.by == address(0) && _random() % 4 == 0) {
                if (t.success) {
                    vm.expectEmit(true, true, true, true);
                    emit Transfer(t.from, t.from, t.to, t.id, t.amount);
                }
                vm.prank(t.from);
                token.transfer(t.to, t.id, t.amount);
            } else if (t.by != address(0) && _random() % 4 == 0) {
                if (t.success) {
                    vm.expectEmit(true, true, true, true);
                    emit Transfer(t.by, t.from, t.to, t.id, t.amount);
                }
                vm.prank(t.by);
                token.transferFrom(t.from, t.to, t.id, t.amount);
            } else {
                if (t.success) {
                    vm.expectEmit(true, true, true, true);
                    emit Transfer(t.by, t.from, t.to, t.id, t.amount);
                }
                token.directTransferFrom(t.by, t.from, t.to, t.id, t.amount);
            }

            if (t.by == address(0) || t.isOperator || t.allowance == type(uint256).max) {
                assertEq(token.allowance(t.from, t.by, t.id), t.allowance);
            }

            if (t.success) {
                if (t.to == t.from) {
                    assertEq(token.balanceOf(t.to, t.id), t.balance);
                } else {
                    assertEq(token.balanceOf(t.from, t.id), t.balance - t.amount);
                    assertEq(token.balanceOf(t.to, t.id), t.amount);
                }
            }
        }
    }

    function _expectInsufficientBalanceRevert() internal {
        vm.expectRevert(ERC6909.InsufficientBalance.selector);
    }

    function _expectInsufficientPermissionRevert() internal {
        vm.expectRevert(ERC6909.InsufficientPermission.selector);
    }

    function _approve(address owner, address spender, uint256 id, uint256 amount) internal {
        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit Approval(owner, spender, id, amount);
        token.approve(spender, id, amount);
        assertEq(token.allowance(owner, spender, id), amount);
    }

    function _setOperator(address owner, address operator, bool approved) internal {
        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit OperatorSet(owner, operator, approved);
        token.directSetOperator(owner, operator, approved);
        assertEq(token.isOperator(owner, operator), approved);
    }

    function _directApprove(address owner, address spender, uint256 id, uint256 amount) internal {
        vm.expectEmit(true, true, true, true);
        emit Approval(owner, spender, id, amount);
        token.directApprove(owner, spender, id, amount);
        assertEq(token.allowance(owner, spender, id), amount);
    }

    function _directSetOperator(address owner, address operator, bool approved) internal {
        vm.expectEmit(true, true, true, true);
        emit OperatorSet(owner, operator, approved);
        token.directSetOperator(owner, operator, approved);
        assertEq(token.isOperator(owner, operator), approved);
    }
}
