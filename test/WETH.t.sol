// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import "./utils/InvariantTest.sol";

import {SafeTransferLib} from "../src/utils/SafeTransferLib.sol";

import {WETH} from "../src/tokens/WETH.sol";

contract ContractWithoutReceive {}

contract WETHTest is SoladyTest {
    WETH weth;

    function setUp() public {
        weth = new WETH();
    }

    function testMetadata() public {
        assertEq(weth.name(), "Wrapped Ether");
        assertEq(weth.symbol(), "WETH");
        assertEq(weth.decimals(), 18);
    }

    function testFallbackDeposit() public {
        assertEq(weth.balanceOf(address(this)), 0);
        assertEq(weth.totalSupply(), 0);

        SafeTransferLib.safeTransferETH(address(weth), 1 ether);

        assertEq(weth.balanceOf(address(this)), 1 ether);
        assertEq(weth.totalSupply(), 1 ether);
    }

    function testDeposit() public {
        assertEq(weth.balanceOf(address(this)), 0);
        assertEq(weth.totalSupply(), 0);

        weth.deposit{value: 1 ether}();

        assertEq(weth.balanceOf(address(this)), 1 ether);
        assertEq(weth.totalSupply(), 1 ether);
    }

    function testWithdraw() public {
        uint256 startingBalance = address(this).balance;

        weth.deposit{value: 1 ether}();

        weth.withdraw(1 ether);

        uint256 balanceAfterWithdraw = address(this).balance;

        assertEq(balanceAfterWithdraw, startingBalance);
        assertEq(weth.balanceOf(address(this)), 0);
        assertEq(weth.totalSupply(), 0);
    }

    function testPartialWithdraw() public {
        weth.deposit{value: 1 ether}();

        uint256 balanceBeforeWithdraw = address(this).balance;

        weth.withdraw(0.5 ether);

        uint256 balanceAfterWithdraw = address(this).balance;

        assertEq(balanceAfterWithdraw, balanceBeforeWithdraw + 0.5 ether);
        assertEq(weth.balanceOf(address(this)), 0.5 ether);
        assertEq(weth.totalSupply(), 0.5 ether);
    }

    function testWithdrawToContractWithoutReceiveReverts() public {
        address owner = address(new ContractWithoutReceive());

        vm.deal(owner, 1 ether);

        vm.prank(owner);
        weth.deposit{value: 1 ether}();

        assertEq(weth.balanceOf(owner), 1 ether);

        vm.expectRevert(WETH.ETHTransferFailed.selector);
        vm.prank(owner);
        weth.withdraw(1 ether);
    }

    function testFallbackDeposit(uint256 amount) public {
        amount = _bound(amount, 0, address(this).balance);

        assertEq(weth.balanceOf(address(this)), 0);
        assertEq(weth.totalSupply(), 0);

        SafeTransferLib.safeTransferETH(address(weth), amount);

        assertEq(weth.balanceOf(address(this)), amount);
        assertEq(weth.totalSupply(), amount);
    }

    function testDeposit(uint256 amount) public {
        amount = _bound(amount, 0, address(this).balance);

        assertEq(weth.balanceOf(address(this)), 0);
        assertEq(weth.totalSupply(), 0);

        weth.deposit{value: amount}();

        assertEq(weth.balanceOf(address(this)), amount);
        assertEq(weth.totalSupply(), amount);
    }

    function testWithdraw(uint256 depositAmount, uint256 withdrawAmount) public {
        depositAmount = _bound(depositAmount, 0, address(this).balance);
        withdrawAmount = _bound(withdrawAmount, 0, depositAmount);

        weth.deposit{value: depositAmount}();

        uint256 balanceBeforeWithdraw = address(this).balance;

        weth.withdraw(withdrawAmount);

        uint256 balanceAfterWithdraw = address(this).balance;

        assertEq(balanceAfterWithdraw, balanceBeforeWithdraw + withdrawAmount);
        assertEq(weth.balanceOf(address(this)), depositAmount - withdrawAmount);
        assertEq(weth.totalSupply(), depositAmount - withdrawAmount);
    }

    receive() external payable {}
}

contract WETHInvariants is SoladyTest, InvariantTest {
    WETHTester wethTester;
    WETH weth;

    function setUp() public {
        weth = new WETH();
        wethTester = new WETHTester{value: address(this).balance}(weth);

        _addTargetContract(address(wethTester));
    }

    function invariantTotalSupplyEqualsBalance() public {
        assertEq(address(weth).balance, weth.totalSupply());
    }
}

contract WETHTester {
    WETH weth;

    constructor(WETH _weth) payable {
        weth = _weth;
    }

    function deposit(uint256 amount) public {
        weth.deposit{value: amount}();
    }

    function fallbackDeposit(uint256 amount) public {
        SafeTransferLib.safeTransferETH(address(weth), amount);
    }

    function withdraw(uint256 amount) public {
        weth.withdraw(amount);
    }

    receive() external payable {}
}
