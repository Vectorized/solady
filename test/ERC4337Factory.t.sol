// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {MockERC4337} from "./utils/mocks/MockERC4337.sol";
import {ERC4337Factory} from "../src/accounts/ERC4337Factory.sol";
import {LibClone} from "../src/utils/LibClone.sol";

contract ERC4337FactoryTest is SoladyTest {
    address internal constant _ENTRY_POINT = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;

    ERC4337Factory factory;

    MockERC4337 erc4337;

    function setUp() public {
        // Etch something onto `_ENTRY_POINT` such that we can deploy the account implementation.
        vm.etch(_ENTRY_POINT, hex"00");
        erc4337 = new MockERC4337();
        factory = new ERC4337Factory(address(erc4337));
    }

    function testDeployDeterministic(uint256) public {
        vm.deal(address(this), 100 ether);
        address owner = _randomNonZeroAddress();
        uint256 initialValue = _random() % 100 ether;
        bytes32 salt = _random() % 8 == 0 ? bytes32(_random()) : bytes32(uint256(uint96(_random())));
        address account;
        if (uint256(salt) >> 96 != uint160(owner) && uint256(salt) >> 96 != 0) {
            vm.expectRevert(LibClone.SaltDoesNotStartWith.selector);
            account = factory.createAccount{value: initialValue}(owner, salt);
            return;
        } else {
            account = factory.createAccount{value: initialValue}(owner, salt);
        }
        assertEq(address(account).balance, initialValue);
        assertEq(MockERC4337(payable(account)).owner(), owner);
        _checkImplementationSlot(account, address(erc4337));
    }

    function testCreateAccountRepeatedDeployment() public {
        bytes32 salt = bytes32(_random() & uint256(type(uint96).max));
        address expectedInstance = factory.getAddress(salt);
        address instanceA = factory.createAccount{value: 123}(address(0xABCD), salt);
        assertEq(instanceA.balance, 123);
        assertEq(factory.createAccount{value: 456}(address(0xABCD), salt), instanceA);
        assertEq(factory.createAccount(address(0xABCD), salt), instanceA);
        assertEq(instanceA.balance, 123 + 456);
        assertEq(expectedInstance, instanceA);
    }

    function _checkImplementationSlot(address proxy, address implementation_) internal {
        bytes32 slot = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
        assertEq(vm.load(proxy, slot), bytes32(uint256(uint160(implementation_))));
    }
}
