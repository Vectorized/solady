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
    address implentation0;
    address implentation1;

    struct _TestTemps {
        uint256 key;
        uint256 value;
        uint256 msgValue;
        bytes32 salt;
        address predictedProxy;
        address proxy;
    }

    function _testTemps() internal returns (_TestTemps memory t) {
        t.key = _random();
        t.value = _random();
        t.msgValue = _bound(_random(), 0, uint256(type(uint96).max));
        t.salt = bytes32(_random() & uint256(type(uint96).max));
    }

    function setUp() public {
        factory = new ERC1967Factory();
        implentation0 = address(new MockImplementation());
        implentation1 = address(new MockImplementation());
    }

    function testDeploy() public {
        (address admin,) = _randomSigner();

        vm.prank(admin);
        address proxy = factory.deploy(implentation0, admin);

        assertEq(factory.adminOf(proxy), admin);
        assertTrue(proxy != address(0));
        assertTrue(proxy.code.length > 0);
        _checkImplementationSlot(proxy, implentation0);
    }

    function testDeployAndCall(uint256) public {
        (address admin,) = _randomSigner();
        _TestTemps memory t = _testTemps();

        bytes memory data = abi.encodeWithSignature("setValue(uint256,uint256)", t.key, t.value);
        vm.deal(admin, type(uint128).max);
        vm.prank(admin);
        address proxy = factory.deployAndCall{value: t.msgValue}(implentation0, admin, data);

        assertEq(factory.adminOf(proxy), admin);
        assertTrue(proxy != address(0));
        assertTrue(proxy.code.length > 0);
        _checkImplementationSlot(proxy, implentation0);
        assertEq(MockImplementation(proxy).getValue(t.key), t.value);
        assertEq(proxy.balance, t.msgValue);
    }

    function testDeployDeterministicAndCall(uint256) public {
        (address admin,) = _randomSigner();
        _TestTemps memory t = _testTemps();

        t.predictedProxy = factory.predictDeterministicAddress(t.salt);
        bytes memory data = abi.encodeWithSignature("setValue(uint256,uint256)", t.key, t.value);
        vm.deal(admin, type(uint128).max);
        vm.prank(admin);
        if (_random() % 8 == 0) {
            t.salt = keccak256(abi.encode(_random()));
            vm.expectRevert(ERC1967Factory.SaltDoesNotStartWithCaller.selector);
            t.proxy = factory.deployDeterministicAndCall{value: t.msgValue}(
                implentation0, admin, t.salt, data
            );
            return;
        } else {
            vm.expectEmit(true, true, true, true);
            emit Deployed(t.predictedProxy, implentation0, admin);
            t.proxy = factory.deployDeterministicAndCall{value: t.msgValue}(
                implentation0, admin, t.salt, data
            );
            assertEq(t.proxy, t.predictedProxy);
        }

        assertEq(factory.adminOf(t.proxy), admin);
        assertTrue(t.proxy != address(0));
        assertTrue(t.proxy.code.length > 0);
        _checkImplementationSlot(t.proxy, implentation0);
        assertEq(MockImplementation(t.proxy).getValue(t.key), t.value);
        assertEq(t.proxy.balance, t.msgValue);
    }

    function testDeployAndCallWithRevert() public {
        (address admin,) = _randomSigner();

        bytes memory data = abi.encodeWithSignature("fails()");
        vm.expectRevert(MockImplementation.Fail.selector);
        factory.deployAndCall(implentation0, admin, data);
    }

    function testProxySucceeds() public {
        (address admin,) = _randomSigner();
        uint256 a = 1;

        MockImplementation proxy = MockImplementation(factory.deploy(implentation0, admin));

        assertEq(proxy.succeeds(a), a);
    }

    function testProxyFails() public {
        (address admin,) = _randomSigner();

        address proxy = factory.deploy(implentation0, admin);

        vm.expectRevert(MockImplementation.Fail.selector);
        MockImplementation(proxy).fails();
    }

    function testChangeAdmin() public {
        (address admin,) = _randomSigner();
        (address newAdmin,) = _randomSigner();

        vm.prank(admin);
        address proxy = factory.deploy(implentation0, admin);

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
        address proxy = factory.deploy(implentation0, admin);

        vm.expectRevert();

        vm.prank(sussyAccount);
        factory.changeAdmin(proxy, sussyAccount);
    }

    function testUpgrade() public {
        (address admin,) = _randomSigner();

        vm.prank(admin);
        address proxy = factory.deploy(implentation0, admin);

        vm.expectEmit(true, true, true, true, address(factory));
        emit Upgraded(proxy, implentation1);

        vm.prank(admin);
        factory.upgrade(proxy, implentation1);

        _checkImplementationSlot(proxy, implentation1);
    }

    function testUpgradeAndCall(uint256) public {
        (address admin,) = _randomSigner();
        _TestTemps memory t = _testTemps();

        vm.prank(admin);
        address proxy = factory.deploy(implentation0, admin);

        vm.expectEmit(true, true, true, true, address(factory));
        emit Upgraded(proxy, implentation1);

        vm.prank(admin);
        vm.deal(admin, type(uint128).max);
        bytes memory data = abi.encodeWithSignature("setValue(uint256,uint256)", t.key, t.value);
        factory.upgradeAndCall{value: t.msgValue}(proxy, implentation1, data);

        _checkImplementationSlot(proxy, implentation1);
        assertEq(MockImplementation(proxy).getValue(t.key), t.value);
        assertEq(proxy.balance, t.msgValue);
    }

    function testUpgradeAndCallWithRevert() public {
        (address admin,) = _randomSigner();

        vm.prank(admin);
        address proxy = factory.deploy(implentation0, admin);

        vm.prank(admin);
        vm.expectRevert(MockImplementation.Fail.selector);
        factory.upgradeAndCall(proxy, implentation1, abi.encodeWithSignature("fails()"));
    }

    function testUpgradeUnauthorized() public {
        (address admin,) = _randomSigner();
        (address sussyAccount,) = _randomSigner();
        vm.assume(admin != sussyAccount);

        vm.prank(admin);
        address proxy = factory.deploy(implentation0, admin);

        vm.expectRevert();

        vm.prank(sussyAccount);
        factory.upgrade(proxy, implentation1);
    }

    function _checkImplementationSlot(address proxy, address implementation) internal {
        bytes32 slot = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
        assertEq(vm.load(proxy, slot), bytes32(uint256(uint160(implementation))));
    }
}
