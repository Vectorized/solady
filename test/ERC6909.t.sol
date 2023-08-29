// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";

import {ERC6909, MockERC6909} from "./utils/mocks/MockERC6909.sol";

contract ERC6909Test is SoladyTest {
    MockERC6909 token;

    event Transfer(address indexed from, address indexed to, uint256 indexed id, uint256 amount);

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
        emit Transfer(address(0), address(0xBEEF), 1, 1e18);

        token.mint(address(0xBEEF), 1, 1e18);
        assertEq(token.totalSupply(1), 1e18);
        assertEq(token.balanceOf(address(0xBEEF), 1), 1e18);
    }

    function testDecimals() public {
        assertEq(token.decimals(1), 18);
    }

    function testBurn() public {
        token.mint(address(0xBEEF), 1, 1e18);

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0xBEEF), address(0), 1, 0.9e18);
        token.burn(address(0xBEEF), 1, 0.9e18);

        assertEq(token.totalSupply(1), 1e18 - 0.9e18);
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
        emit Transfer(address(this), address(0xBEEF), 1, 1e18);
        assertTrue(token.transfer(address(0xBEEF), 1, 1e18));
        assertEq(token.totalSupply(1), 1e18);
        assertEq(token.balanceOf(address(this), 1), 0);
        assertEq(token.balanceOf(address(0xBEEF), 1), 1e18);
    }

    function testTransferFrom() public {
        address from = address(0xABCD);

        token.mint(from, 1, 1e18);

        vm.prank(from);
        token.approve(address(this), 1, 1e18);

        vm.expectEmit(true, true, true, true);
        emit Transfer(from, address(0xBEEF), 1, 1e18);
        assertTrue(token.transferFrom(from, address(0xBEEF), 1, 1e18));
        assertEq(token.totalSupply(1), 1e18);

        assertEq(token.allowance(from, address(this), 1), 0);

        assertEq(token.balanceOf(from, 1), 0);
        assertEq(token.balanceOf(address(0xBEEF), 1), 1e18);
    }

    function testInfiniteApproveTransferFrom() public {
        address from = address(0xABCD);

        token.mint(from, 1, 1e18);

        vm.prank(from);
        token.approve(address(this), 1, type(uint256).max);

        vm.expectEmit(true, true, true, true);
        emit Transfer(from, address(0xBEEF), 1, 1e18);
        assertTrue(token.transferFrom(from, address(0xBEEF), 1, 1e18));
        assertEq(token.totalSupply(1), 1e18);

        assertEq(token.allowance(from, address(this), 1), type(uint256).max);

        assertEq(token.balanceOf(from, 1), 0);
        assertEq(token.balanceOf(address(0xBEEF), 1), 1e18);
    }

    function testOperatorTransferFrom() public {
        address from = address(0xABcD);

        token.mint(from, 1, 1e18);

        vm.prank(from);
        token.setOperator(address(this), true);

        vm.expectEmit(true, true, true, true);
        emit Transfer(from, address(0xBEEF), 1, 1e18);
        assertTrue(token.transferFrom(from, address(0xBEEF), 1, 1e18));
        assertEq(token.totalSupply(1), 1e18);

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
        vm.expectRevert(ERC6909.TotalSupplyOverflow.selector);
        token.mint(address(this), 1, 1);
    }

    function testTransferInsufficientBalanceReverts() public {
        token.mint(address(this), 1, 0.9e18);
        vm.expectRevert(
            abi.encodeWithSelector(ERC6909.InsufficientBalance.selector, address(this), 1)
        );
        token.transfer(address(0xBEEF), 1, 1e18);
    }

    function testTransferFromInsufficientPermission() public {
        address from = address(0xABCD);

        token.mint(from, 1, 1e18);

        vm.prank(from);
        token.approve(address(this), 1, 0.9e18);

        vm.expectRevert(
            abi.encodeWithSelector(ERC6909.InsufficientPermission.selector, address(this), 1)
        );
        token.transferFrom(from, address(0xBEEF), 1, 1e18);
    }

    function testTransferFromInsufficientBalanceReverts() public {
        address from = address(0xABCD);

        token.mint(from, 1, 0.9e18);

        vm.prank(from);
        token.approve(address(this), 1, 1e18);

        vm.expectRevert(abi.encodeWithSelector(ERC6909.InsufficientBalance.selector, from, 1));
        token.transferFrom(from, address(0xBEEF), 1, 1e18);
    }

    function testMint(address to, uint256 id, uint256 amount) public {
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), to, id, amount);
        token.mint(to, id, amount);

        assertEq(token.totalSupply(id), amount);
        assertEq(token.balanceOf(to, id), amount);
    }

    function testBurn(address from, uint256 id, uint256 mintAmount, uint256 burnAmount) public {
        burnAmount = _bound(burnAmount, 0, mintAmount);

        token.mint(from, id, mintAmount);
        vm.expectEmit(true, true, true, true);
        emit Transfer(from, address(0), id, burnAmount);
        token.burn(from, id, burnAmount);

        assertEq(token.totalSupply(id), mintAmount - burnAmount);
        assertEq(token.balanceOf(from, id), mintAmount - burnAmount);
    }

    function testApprove(address to, uint256 id, uint256 amount) public {
        assertTrue(token.approve(to, id, amount));

        assertEq(token.allowance(address(this), to, id), amount);
    }

    function testTransfer(address to, uint256 id, uint256 amount) public {
        token.mint(address(this), id, amount);

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), to, id, amount);
        assertTrue(token.transfer(to, id, amount));
        assertEq(token.totalSupply(id), amount);

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

        vm.prank(from);
        token.approve(spender, id, approval);

        vm.expectEmit(true, true, true, true);
        emit Transfer(from, to, id, amount);
        vm.prank(spender);
        assertTrue(token.transferFrom(from, to, id, amount));
        assertEq(token.totalSupply(id), amount);

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
        vm.expectEmit(true, true, true, true);
        emit OperatorSet(owner, spender, approved);
        vm.prank(owner);
        assertTrue(token.setOperator(spender, approved));

        assertEq(token.isOperator(owner, spender), approved);
    }

    function testMintTotalSupplyOverFlowReverts(address to, uint256 id, uint256 amount) public {
        token.mint(to, id, amount);
        assertEq(token.totalSupply(id), amount);

        if (amount != 0) {
            vm.expectRevert(ERC6909.TotalSupplyOverflow.selector);
            token.mint(to, id, type(uint256).max);
        }
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
        vm.expectRevert(abi.encodeWithSelector(ERC6909.InsufficientBalance.selector, to, id));
        token.burn(to, id, burnAmount);
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
        vm.expectRevert(
            abi.encodeWithSelector(ERC6909.InsufficientBalance.selector, address(this), id)
        );
        token.transfer(to, id, sendAmount);
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

        vm.prank(from);
        token.approve(address(this), id, approval);

        vm.expectRevert(
            abi.encodeWithSelector(ERC6909.InsufficientPermission.selector, address(this), id)
        );
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

        vm.prank(from);
        token.approve(address(this), id, sendAmount);

        vm.expectRevert(abi.encodeWithSelector(ERC6909.InsufficientBalance.selector, from, id));
        token.transferFrom(from, to, id, sendAmount);
    }

    function testTransferFromCallerIsNotOperator(address to, uint256 id, uint256 amount) public {
        amount = _bound(amount, 1, type(uint256).max);

        address from = address(0xABCD);

        token.mint(from, id, amount);

        vm.expectRevert(
            abi.encodeWithSelector(ERC6909.InsufficientPermission.selector, address(this), id)
        );
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
        bool sufficientPermission;
        bool success;
    }

    function testDirectFunctions(uint256) public {
        _TestTemps memory t;
        t.id = _random();
        t.allowance = _random();
        t.balance = _random();
        t.amount = _random();
        t.isOperator = _random() % 2 == 0;
        t.by = _randomAddress();
        t.from = _randomAddress();
        while (t.to == t.from) t.to = _randomAddress();

        token.mint(t.from, t.id, t.balance);
        _directSetOperator(t.from, t.by, t.isOperator);
        _directApprove(t.from, t.by, t.id, t.allowance);

        t.sufficientPermission = t.by == address(0) || t.isOperator || t.allowance >= t.amount;
        if (t.balance >= t.amount) {
            if (t.sufficientPermission) {
                t.success = true;
                vm.expectEmit(true, true, true, true);
                emit Transfer(t.from, t.to, t.id, t.amount);
            } else {
                vm.expectRevert(
                    abi.encodeWithSelector(ERC6909.InsufficientPermission.selector, t.by, t.id)
                );
            }
        } else {
            if (t.sufficientPermission) {
                vm.expectRevert(
                    abi.encodeWithSelector(ERC6909.InsufficientBalance.selector, t.from, t.id)
                );
            } else {
                vm.expectRevert(
                    abi.encodeWithSelector(ERC6909.InsufficientPermission.selector, t.by, t.id)
                );
            }
        }

        token.directTransferFrom(t.by, t.from, t.to, t.id, t.amount);
        if (t.isOperator || t.by == address(0) || t.allowance == type(uint256).max) {
            assertEq(token.allowance(t.from, t.by, t.id), t.allowance);
        }

        if (t.success) {
            assertEq(token.balanceOf(t.from, t.id), t.balance - t.amount);
            assertEq(token.balanceOf(t.to, t.id), t.amount);
        }
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
