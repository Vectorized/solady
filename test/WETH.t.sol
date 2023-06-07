// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import "./utils/InvariantTest.sol";

import {SafeTransferLib} from "../src/utils/SafeTransferLib.sol";
import {LibClone} from "../src/utils/LibClone.sol";
import {WETH} from "../src/tokens/WETH.sol";

contract ContractWithoutReceive {}

contract WETHTest is SoladyTest {
    bytes32 constant PERMIT_TYPEHASH = keccak256(
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

    WETH weth;

    address alice = vm.addr(uint256(keccak256(abi.encode(string("solady")))));

    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    function setUp() public {
        weth = new WETH();
    }

    function _expectDepositEvent(address from, uint256 amount) internal {
        vm.expectEmit(true, true, true, true);
        emit Deposit(from, amount);
    }

    function _expectDepositEvent(uint256 amount) internal {
        _expectDepositEvent(address(this), amount);
    }

    function _expectWithdrawalEvent(address to, uint256 amount) internal {
        vm.expectEmit(true, true, true, true);
        emit Withdrawal(to, amount);
    }

    function _expectWithdrawalEvent(uint256 amount) internal {
        _expectWithdrawalEvent(address(this), amount);
    }

    function testMetdata() public {
        assertEq(weth.name(), "Wrapped Ether");
        assertEq(weth.symbol(), "WETH");
        assertEq(weth.decimals(), 18);
    }

    function testFallbackDeposit() public {
        assertEq(weth.balanceOf(address(this)), 0);
        assertEq(weth.totalSupply(), 0);

        _expectDepositEvent(1 ether);
        SafeTransferLib.safeTransferETH(address(weth), 1 ether);

        assertEq(weth.balanceOf(address(this)), 1 ether);
        assertEq(weth.totalSupply(), 1 ether);
    }

    function testDeposit() public {
        assertEq(weth.balanceOf(address(this)), 0);
        assertEq(weth.totalSupply(), 0);

        _expectDepositEvent(1 ether);
        weth.deposit{value: 1 ether}();

        assertEq(weth.balanceOf(address(this)), 1 ether);
        assertEq(weth.totalSupply(), 1 ether);
    }

    function testDepositTo() public {
        assertEq(weth.balanceOf(address(this)), 0);
        assertEq(weth.totalSupply(), 0);

        _expectDepositEvent(alice, 1 ether);
        weth.depositTo{value: 1 ether}(alice);

        assertEq(weth.totalSupply(), 1 ether);
        assertEq(weth.balanceOf(alice), 1 ether);
    }

    function testWithdraw() public {
        uint256 startingBalance = address(this).balance;

        _expectDepositEvent(1 ether);
        weth.deposit{value: 1 ether}();

        _expectWithdrawalEvent(1 ether);
        weth.withdraw(1 ether);

        uint256 balanceAfterWithdraw = address(this).balance;

        assertEq(balanceAfterWithdraw, startingBalance);
        assertEq(weth.balanceOf(address(this)), 0);
        assertEq(weth.totalSupply(), 0);
    }

    function testWithdrawTo() public {
        uint256 startingBalance = address(alice).balance;
        _expectDepositEvent(1 ether);

        weth.deposit{value: 1 ether}();
        _expectWithdrawalEvent(alice, 1 ether);
        weth.withdrawTo(alice, 1 ether);

        uint256 afterbalance = address(alice).balance;

        assertEq(afterbalance - startingBalance, 1 ether);
    }

    function testPartialWithdraw() public {
        _expectDepositEvent(1 ether);
        weth.deposit{value: 1 ether}();

        uint256 balanceBeforeWithdraw = address(this).balance;

        _expectWithdrawalEvent(0.5 ether);
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
        _expectDepositEvent(owner, 1 ether);
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

        _expectDepositEvent(amount);
        SafeTransferLib.safeTransferETH(address(weth), amount);

        assertEq(weth.balanceOf(address(this)), amount);
        assertEq(weth.totalSupply(), amount);
    }

    function testDeposit(uint256 amount) public {
        amount = _bound(amount, 0, address(this).balance);

        assertEq(weth.balanceOf(address(this)), 0);
        assertEq(weth.totalSupply(), 0);

        _expectDepositEvent(amount);
        weth.deposit{value: amount}();

        assertEq(weth.balanceOf(address(this)), amount);
        assertEq(weth.totalSupply(), amount);
    }

    function testDepositTo(address to, uint256 amount) public {
        amount = _bound(amount, 0, address(this).balance);

        assertEq(weth.balanceOf(to), 0);
        assertEq(weth.totalSupply(), 0);

        _expectDepositEvent(to, amount);
        weth.depositTo{value: amount}(to);

        assertEq(weth.balanceOf(to), amount);
        assertEq(weth.totalSupply(), amount);
    }

    function testWithdraw(uint256 depositAmount, uint256 withdrawAmount) public {
        depositAmount = _bound(depositAmount, 0, address(this).balance);
        withdrawAmount = _bound(withdrawAmount, 0, depositAmount);

        _expectDepositEvent(depositAmount);
        weth.deposit{value: depositAmount}();

        uint256 balanceBeforeWithdraw = address(this).balance;

        _expectWithdrawalEvent(withdrawAmount);
        weth.withdraw(withdrawAmount);

        uint256 balanceAfterWithdraw = address(this).balance;

        assertEq(balanceAfterWithdraw, balanceBeforeWithdraw + withdrawAmount);
        assertEq(weth.balanceOf(address(this)), depositAmount - withdrawAmount);
        assertEq(weth.totalSupply(), depositAmount - withdrawAmount);
    }

    function testWithdrawTo(uint256 depositAmount, uint256 withdrawAmount) public {
        depositAmount = _bound(depositAmount, 0, address(this).balance);
        withdrawAmount = _bound(withdrawAmount, 0, depositAmount);

        _expectDepositEvent(depositAmount);
        weth.deposit{value: depositAmount}();

        uint256 balanceBeforeWithdraw = address(alice).balance;

        _expectWithdrawalEvent(alice, withdrawAmount);
        weth.withdrawTo(alice, withdrawAmount);

        uint256 balanceAfterWithdraw = address(alice).balance;

        assertEq(balanceAfterWithdraw, balanceBeforeWithdraw + withdrawAmount);
        assertEq(weth.balanceOf(address(this)), depositAmount - withdrawAmount);
        assertEq(weth.totalSupply(), depositAmount - withdrawAmount);
    }

    function testDomainSeparator() public {
        assertEq(weth.DOMAIN_SEPARATOR(), _buildDomainSeparator(weth));
        WETH clone = WETH(payable(LibClone.clone(address(weth))));
        assertEq(clone.DOMAIN_SEPARATOR(), _buildDomainSeparator(clone));
        vm.chainId(2);
        assertEq(weth.DOMAIN_SEPARATOR(), _buildDomainSeparator(weth));
        assertEq(clone.DOMAIN_SEPARATOR(), _buildDomainSeparator(clone));
    }

    function _buildDomainSeparator(WETH token) internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256("Wrapped Ether"),
                keccak256("1"),
                block.chainid,
                address(token)
            )
        );
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

    receive() external payable {}
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
