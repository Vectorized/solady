// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./../../utils/SoladyTest.sol";

import "./../../../src/utils/ext/zksync/ERC1967Factory.sol";

contract SampleImplementation {
    uint256 public x;

    bytes public constant NAME = "Implementation";

    event Foo();

    error Hehe();

    function foo() public {
        emit Foo();
    }

    function setX(uint256 newX) public {
        x = newX;
    }

    function hehe() public pure {
        revert Hehe();
    }

    function version() public pure virtual returns (uint256) {
        return 1;
    }
}

contract SampleImplementation2 is SampleImplementation {
    function version() public pure virtual override returns (uint256) {
        return 2;
    }
}

contract ERC1967FactoryTest is SoladyTest {
    ERC1967Factory public factory;
    address public implementation;
    address public implementation2;

    function setUp() public {
        factory = new ERC1967Factory();
        implementation = address(new SampleImplementation());
        implementation2 = address(new SampleImplementation2());
    }

    function testDeployDeterministicAndUpgrade() public {
        bytes32 salt = 0x0000000000000000000000000000000000000000ff112233445566778899aabb;
        address predicted = factory.predictDeterministicAddress(factory.proxyHash(), salt);
        assertEq(factory.implementationOf(predicted), address(0));
        address instance = factory.deployProxyDeterministic(implementation, address(this), salt);
        assertEq(factory.implementationOf(predicted), implementation);
        assertEq(predicted, instance);
        SampleImplementation(instance).setX(123);
        assertEq(SampleImplementation(instance).x(), 123);
        assertEq(SampleImplementation(instance).version(), 1);
        assertGt(instance.code.length, 0);

        factory.upgradeAndCall(
            instance, implementation2, abi.encodeWithSignature("setX(uint256)", uint256(456))
        );
        assertEq(SampleImplementation(instance).x(), 456);
        assertEq(SampleImplementation(instance).version(), 2);

        _checkBehavesLikeProxy(instance);
    }

    function testDeployBeaconProxyDeterministicAndUpgrade() public {
        bytes32 salt = 0x0000000000000000000000000000000000000000ff112233445566778899aabb;
        address predicted = factory.predictDeterministicAddress(factory.beaconHash(), salt);
        assertEq(factory.implementationOf(predicted), address(0));
        address beacon = factory.deployBeaconDeterministic(implementation, address(this), salt);
        assertEq(UpgradeableBeacon(beacon).implementation(), implementation);
        assertEq(factory.implementationOf(predicted), implementation);
        assertEq(predicted, beacon);

        predicted = factory.predictDeterministicAddress(factory.beaconProxyHash(), salt);
        address beaconProxy = factory.deployBeaconProxyDeterministic(beacon, salt);
        assertEq(predicted, beaconProxy);
        assertEq(factory.implementationOf(beaconProxy), implementation);

        SampleImplementation(beaconProxy).setX(123);
        assertEq(SampleImplementation(beaconProxy).x(), 123);
        assertEq(SampleImplementation(beaconProxy).version(), 1);

        factory.upgrade(beacon, implementation2);
        assertEq(SampleImplementation(beaconProxy).version(), 2);

        _checkBehavesLikeProxy(beaconProxy);
    }

    function _checkBehavesLikeProxy(address instance) internal {
        assertTrue(instance != address(0));
        uint256 x = _random();
        SampleImplementation(instance).setX(x);
        assertEq(x, SampleImplementation(instance).x());
        vm.expectRevert(SampleImplementation.Hehe.selector);
        SampleImplementation(instance).hehe();
    }
}
