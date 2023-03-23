// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/TestPlus.sol";
import {MockImplementation} from "./utils/mocks/MockImplementation.sol";
import {ERC1967Factory} from "../src/utils/ERC1967Factory.sol";

contract ERC1967FactoryTest is TestPlus {
    event AdminSet(address indexed proxy, address indexed admin);
    event ProxyUpgraded(address indexed proxy, address indexed implementation);

    ERC1967Factory factory;
    address impl0;
    address impl1;

    function setUp() public {
        factory = new ERC1967Factory();
        impl0 = address(new MockImplementation());
        impl1 = address(new MockImplementation());
    }

    function testDeployProxy() public {
        (address admin,) = _randomSigner();
        bytes32 key = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
        bytes32 value = bytes32(uint256(uint160(impl0)));

        vm.prank(admin);
        address proxy = factory.deploy(impl0, admin);

        assertEq(factory.adminOf(proxy), admin);
        assertTrue(proxy != address(0));
        assertTrue(proxy.code.length > 0);
        assertEq(vm.load(proxy, key), value);
    }

    function testProxySucceeds() public {
        (address admin,) = _randomSigner();
        uint256 a = 1;

        MockImplementation proxy = MockImplementation(factory.deploy(impl0, admin));

        assertEq(proxy.succeeds(a), a);
    }

    function testProxyFails() public {
        (address admin,) = _randomSigner();
        bool success;
        bytes memory retdata;

        address proxy = factory.deploy(impl0, admin);

        (success, retdata) = proxy.call(abi.encodeCall(MockImplementation.fails, ()));

        assertFalse(success);
        assertEq(retdata.length, 4);
        assertEq(keccak256(retdata), keccak256(hex"552670ff"));
    }

    function testSetAdminFor() public {
        (address admin,) = _randomSigner();
        (address newAdmin,) = _randomSigner();

        vm.prank(admin);
        address proxy = factory.deploy(impl0, admin);

        vm.expectEmit(true, true, true, true, address(factory));
        emit AdminSet(proxy, newAdmin);

        vm.prank(admin);
        factory.setAdmin(proxy, newAdmin);

        assertEq(factory.adminOf(proxy), newAdmin);
    }

    function testSetAdminForUnauthorized() public {
        (address admin,) = _randomSigner();
        (address sussyAccount,) = _randomSigner();

        vm.prank(admin);
        address proxy = factory.deploy(impl0, admin);

        vm.expectRevert();

        vm.prank(sussyAccount);
        factory.setAdmin(proxy, sussyAccount);
    }

    function testUpgrade() public {
        (address admin,) = _randomSigner();
        bytes32 key = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
        bytes32 value = bytes32(uint256(uint160(impl1)));

        vm.prank(admin);
        address proxy = factory.deploy(impl0, admin);

        vm.expectEmit(true, true, true, true, address(factory));
        emit ProxyUpgraded(proxy, impl1);

        vm.prank(admin);
        factory.upgrade(proxy, impl1);

        assertEq(vm.load(proxy, key), value);
    }

    function testUpgradeAndCall() public {
        (address admin,) = _randomSigner();
        bytes32 key = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
        bytes32 value = bytes32(uint256(uint160(impl1)));

        vm.prank(admin);
        address proxy = factory.deploy(impl0, admin);

        vm.expectEmit(true, true, true, true, address(factory));
        emit ProxyUpgraded(proxy, impl1);

        vm.prank(admin);
        uint256 x = 123;
        factory.upgradeAndCall(proxy, impl1, abi.encodeWithSignature("setX(uint256)", x));

        assertEq(vm.load(proxy, key), value);
        assertEq(MockImplementation(proxy).x(), x);
    }

    function testUpgradeUnauthorized() public {
        (address admin,) = _randomSigner();
        (address sussyAccount,) = _randomSigner();

        vm.prank(admin);
        address proxy = factory.deploy(impl0, admin);

        vm.expectRevert();

        vm.prank(sussyAccount);
        factory.upgrade(proxy, impl1);
    }
}
