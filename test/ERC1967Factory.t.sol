// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/TestPlus.sol";
import {MockImplementation} from "./utils/mocks/MockImplementation.sol";
import {ERC1967Factory} from "../src/utils/ERC1967Factory.sol";

contract ERC1967FactoryTest is TestPlus {
    event AdminChanged(address indexed proxy, address indexed admin);

    event Upgraded(address indexed proxy, address indexed implementation);

    event Deployed(address indexed proxy, address indexed implementation, address indexed admin);

    ERC1967Factory factory;
    address[2] implentation;

    function setUp() public {
        factory = new ERC1967Factory();
        implentation[0] = address(new MockImplementation());
        implentation[1] = address(new MockImplementation());
    }

    function testDeploy() public {
        (address admin,) = _randomSigner();

        vm.prank(admin);
        address proxy = factory.deploy(implentation[0], admin);

        assertEq(factory.adminOf(proxy), admin);
        assertTrue(proxy != address(0));
        assertTrue(proxy.code.length > 0);
        _checkImplementationSlot(proxy, implentation[0]);
    }

    function testDeployAndCall(uint256 key, uint256 value, uint96 msgValue) public {
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

    function testDeployDeterministicAndCall(
        uint256 key,
        uint256 value,
        uint96 msgValue,
        bytes32 salt
    ) public {
        (address admin,) = _randomSigner();

        salt = bytes32(uint256(salt) & (2 ** 96 - 1));
        address predictedProxy = factory.predictDeterministicAddress(salt);
        bytes memory data = abi.encodeWithSignature("setValue(uint256,uint256)", key, value);
        vm.deal(admin, type(uint128).max);
        vm.prank(admin);
        address proxy;
        if (_random() % 8 == 0) {
            salt = keccak256(abi.encode(key, value, salt));
            vm.expectRevert(ERC1967Factory.SaltDoesNotStartWithCaller.selector);
            proxy = factory.deployDeterministicAndCall{value: msgValue}(
                implentation[0], admin, salt, data
            );
            return;
        } else {
            vm.expectEmit(true, true, true, true);
            emit Deployed(predictedProxy, implentation[0], admin);
            proxy = factory.deployDeterministicAndCall{value: msgValue}(
                implentation[0], admin, salt, data
            );
            assertEq(proxy, predictedProxy);
        }

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

    function testChangeAdmin() public {
        (address admin,) = _randomSigner();
        (address newAdmin,) = _randomSigner();

        vm.prank(admin);
        address proxy = factory.deploy(implentation[0], admin);

        vm.expectEmit(true, true, true, true, address(factory));
        emit AdminChanged(proxy, newAdmin);

        vm.prank(admin);
        factory.changeAdmin(proxy, newAdmin);

        assertEq(factory.adminOf(proxy), newAdmin);
    }

    function testChangeAdminUnauthorized() public {
        (address admin,) = _randomSigner();
        (address sussyAccount,) = _randomSigner();

        vm.prank(admin);
        address proxy = factory.deploy(implentation[0], admin);

        vm.expectRevert();

        vm.prank(sussyAccount);
        factory.changeAdmin(proxy, sussyAccount);
    }

    function testUpgrade() public {
        (address admin,) = _randomSigner();

        vm.prank(admin);
        address proxy = factory.deploy(implentation[0], admin);

        vm.expectEmit(true, true, true, true, address(factory));
        emit Upgraded(proxy, implentation[1]);

        vm.prank(admin);
        factory.upgrade(proxy, implentation[1]);

        _checkImplementationSlot(proxy, implentation[1]);
    }

    function testUpgradeAndCall(uint256 key, uint256 value, uint96 msgValue) public {
        (address admin,) = _randomSigner();

        vm.prank(admin);
        address proxy = factory.deploy(implentation[0], admin);

        vm.expectEmit(true, true, true, true, address(factory));
        emit Upgraded(proxy, implentation[1]);

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
