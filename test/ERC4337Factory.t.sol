// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {MockERC4337} from "./utils/mocks/MockERC4337.sol";
import {ERC4337Factory} from "../src/accounts/ERC4337Factory.sol";
import {LibClone} from "../src/utils/LibClone.sol";

contract ERC4337FactoryTest is SoladyTest {
    address internal constant _ENTRY_POINT = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;

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
        bytes32 ownSalt = bytes32(bytes20(owner)) | bytes32(uint256(uint96(_random())));
        address account = factory.createAccount{value: initialValue}(ownSalt);
        assertEq(address(account).balance, initialValue);
        assertEq(MockERC4337(payable(account)).owner(), owner);
        _checkImplementationSlot(account, address(erc4337));
    }

    function testCreateAccountRepeatedDeployment() public {
        address owner = address(0xABCD);
        bytes32 ownSalt = bytes32(bytes20(owner)) | bytes32(uint256(uint96(_random())));
        address expectedInstance = factory.getAddress(ownSalt);
        address instance = factory.createAccount{value: 123}(ownSalt);
        assertEq(instance.balance, 123);
        assertEq(factory.createAccount{value: 456}(ownSalt), instance);
        assertEq(factory.createAccount(ownSalt), instance);
        assertEq(instance.balance, 123 + 456);
        assertEq(expectedInstance, instance);
    }

    function testCreateAccountRepeatedDeployment(uint256) public {
        address owner = _randomNonZeroAddress();
        bytes32 ownSalt = bytes32(bytes20(owner)) | bytes32(uint256(uint96(_random())));
        address expectedInstance = factory.getAddress(ownSalt);
        address notOwner = _randomNonZeroAddress();
        while (owner == notOwner) notOwner = _randomNonZeroAddress();

        address instance = factory.createAccount{value: 123}(ownSalt);
        assertEq(instance.balance, 123);
        assertEq(factory.createAccount{value: 456}(ownSalt), instance);
        assertEq(factory.createAccount(ownSalt), instance);
        assertEq(instance.balance, 123 + 456);
        assertEq(expectedInstance, instance);
    }

    function _checkImplementationSlot(address proxy, address implementation_) internal {
        bytes32 slot = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
        assertEq(vm.load(proxy, slot), bytes32(uint256(uint160(implementation_))));
    }
}
