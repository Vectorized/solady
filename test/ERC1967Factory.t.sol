// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/TestPlus.sol";
import {MockImplementation} from "./utils/mocks/MockImplementation.sol";
import {ERC1967Factory} from "../src/utils/ERC1967Factory.sol";

contract ERC1967FactoryTest is TestPlus {
    event AdminSet(address indexed proxy, address indexed admin);
    event ProxyUpgraded(address indexed proxy, address indexed implementation);

    ERC1967Factory factory;
    address[2] implentation;

    function setUp() public {
        factory = new ERC1967Factory();
        implentation[0] = address(new MockImplementation());
        implentation[1] = address(new MockImplementation());
    }

    function testDeployProxy() public {
        (address admin,) = _randomSigner();

        vm.prank(admin);
        address proxy = factory.deploy(implentation[0], admin);

        assertEq(factory.adminOf(proxy), admin);
        assertTrue(proxy != address(0));
        assertTrue(proxy.code.length > 0);
        _checkImplementationSlot(proxy, implentation[0]);
    }

    function testDeployProxyAndCall(uint256 key, uint256 value, uint96 msgValue) public {
        (address admin,) = _randomSigner();

        bytes memory data = abi.encodeWithSignature("setValue(uint256,uint256)", key, value);
        vm.deal(admin, type(uint128).max);
        vm.prank(admin);
        address proxy = factory.deployAndCall{value: msgValue}(implentation[0], admin, data);

        assertEq(factory.adminOf(proxy), admin);
        assertTrue(proxy != address(0));
        assertTrue(proxy.code.length > 0);
        _checkImplementationSlot(proxy, implentation[0]);
        assertEq(MockImplementation(proxy).getValue(key), value);
        assertEq(proxy.balance, msgValue);
    }

    function testDeployAndCallWithRevert() public {
        (address admin,) = _randomSigner();

        bytes memory data = abi.encodeWithSignature("fails()");
        vm.expectRevert(MockImplementation.Fail.selector);
        factory.deployAndCall(implentation[0], admin, data);
    }

    function testProxySucceeds() public {
        (address admin,) = _randomSigner();
        uint256 a = 1;

        MockImplementation proxy = MockImplementation(factory.deploy(implentation[0], admin));

        assertEq(proxy.succeeds(a), a);
    }

    function testProxyFails() public {
        (address admin,) = _randomSigner();

        address proxy = factory.deploy(implentation[0], admin);

        vm.expectRevert(MockImplementation.Fail.selector);
        MockImplementation(proxy).fails();
    }

    function testSetAdminFor() public {
        (address admin,) = _randomSigner();
        (address newAdmin,) = _randomSigner();

        vm.prank(admin);
        address proxy = factory.deploy(implentation[0], admin);

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
        address proxy = factory.deploy(implentation[0], admin);

        vm.expectRevert();

        vm.prank(sussyAccount);
        factory.setAdmin(proxy, sussyAccount);
    }

    function testUpgrade() public {
        (address admin,) = _randomSigner();

        vm.prank(admin);
        address proxy = factory.deploy(implentation[0], admin);

        vm.expectEmit(true, true, true, true, address(factory));
        emit ProxyUpgraded(proxy, implentation[1]);

        vm.prank(admin);
        factory.upgrade(proxy, implentation[1]);

        _checkImplementationSlot(proxy, implentation[1]);
    }

    function testUpgradeAndCall(uint256 key, uint256 value, uint96 msgValue) public {
        (address admin,) = _randomSigner();

        vm.prank(admin);
        address proxy = factory.deploy(implentation[0], admin);

        vm.expectEmit(true, true, true, true, address(factory));
        emit ProxyUpgraded(proxy, implentation[1]);

        vm.prank(admin);
        vm.deal(admin, type(uint128).max);
        bytes memory data = abi.encodeWithSignature("setValue(uint256,uint256)", key, value);
        factory.upgradeAndCall{value: msgValue}(proxy, implentation[1], data);

        _checkImplementationSlot(proxy, implentation[1]);
        assertEq(MockImplementation(proxy).getValue(key), value);
        assertEq(proxy.balance, msgValue);
    }

    function testUpgradeAndCallWithRevert() public {
        (address admin,) = _randomSigner();

        vm.prank(admin);
        address proxy = factory.deploy(implentation[0], admin);

        vm.prank(admin);
        vm.expectRevert(MockImplementation.Fail.selector);
        factory.upgradeAndCall(proxy, implentation[1], abi.encodeWithSignature("fails()"));
    }

    function testUpgradeUnauthorized() public {
        (address admin,) = _randomSigner();
        (address sussyAccount,) = _randomSigner();

        vm.prank(admin);
        address proxy = factory.deploy(implentation[0], admin);

        vm.expectRevert();

        vm.prank(sussyAccount);
        factory.upgrade(proxy, implentation[1]);
    }

    function _checkImplementationSlot(address proxy, address implementation) internal {
        bytes32 slot = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
        assertEq(vm.load(proxy, slot), bytes32(uint256(uint160(implementation))));
    }
}
