// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {IUpgradeableBeacon, MockUpgradeableBeacon} from "./utils/mocks/MockUpgradeableBeacon.sol";
import {MockImplementation} from "./utils/mocks/MockImplementation.sol";
import {LibClone} from "../src/utils/LibClone.sol";

contract UpgradeableBeaconTest is SoladyTest {
    event Upgraded(address indexed implementation);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    address implementation;
    IUpgradeableBeacon beacon;

    function setUp() public {
        implementation = address(new MockImplementation());
        beacon =
            IUpgradeableBeacon(address(new MockUpgradeableBeacon(address(this), implementation)));
    }

    function testInitializeUpgradeableBeacon() public {
        address initialOwner;
        vm.expectRevert(IUpgradeableBeacon.NewOwnerIsZeroAddress.selector);
        new MockUpgradeableBeacon(initialOwner, implementation);

        initialOwner = address(this);
        vm.expectRevert(IUpgradeableBeacon.NewImplementationHasNoCode.selector);
        new MockUpgradeableBeacon(initialOwner, address(0));

        vm.expectEmit(true, true, true, true);
        emit Upgraded(address(implementation));
        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(address(0), initialOwner);
        new MockUpgradeableBeacon(initialOwner, implementation);
    }

    function _testUpgradeableBeaconOnlyOwnerFunctions(address pranker, address newImplementation)
        internal
    {
        vm.startPrank(pranker);
        vm.expectRevert(IUpgradeableBeacon.Unauthorized.selector);
        beacon.transferOwnership(address(123));
        vm.expectRevert(IUpgradeableBeacon.Unauthorized.selector);
        beacon.renounceOwnership();
        vm.expectRevert(IUpgradeableBeacon.Unauthorized.selector);
        beacon.upgradeTo(newImplementation);
        vm.stopPrank();
    }

    function _testUpgradeableBeaconOnlyOwnerFunctions() internal {
        _testUpgradeableBeaconOnlyOwnerFunctions(_randomNonZeroAddress(), implementation);
    }

    function testUpgradeableBeaconOnlyOwnerFunctions() public {
        _testUpgradeableBeaconOnlyOwnerFunctions();
    }

    function testUpgradeableBeacon(uint256) public {
        assertEq(beacon.owner(), address(this));

        address newOwner = _randomNonZeroAddress();

        if (_random() % 32 == 0) {
            _testUpgradeableBeaconOnlyOwnerFunctions();
        }

        if (_random() % 16 == 0) {
            vm.expectRevert(IUpgradeableBeacon.NewOwnerIsZeroAddress.selector);
            beacon.transferOwnership(address(0));
        }

        if (_random() % 16 == 0) {
            vm.expectEmit(true, true, true, true);
            emit OwnershipTransferred(address(this), address(0));
            beacon.renounceOwnership();
            assertEq(beacon.owner(), address(0));
        }

        if (beacon.owner() != address(0) && _random() % 2 == 0) {
            emit OwnershipTransferred(address(this), newOwner);
            beacon.transferOwnership(newOwner);
            assertEq(beacon.owner(), newOwner);

            if (_random() % 2 == 0) {
                _testUpgradeableBeaconOnlyOwnerFunctions(address(this), implementation);
            }

            vm.prank(newOwner);
            emit OwnershipTransferred(newOwner, address(this));
            beacon.transferOwnership(address(this));
            assertEq(beacon.owner(), address(this));
        }

        if (beacon.owner() != address(0) && _random() % 2 == 0) {
            assertEq(beacon.implementation(), implementation);

            address newImplementation;
            if (_random() % 2 == 0) {
                newImplementation = LibClone.clone(implementation);
            }
            if (newImplementation == address(0)) {
                vm.expectRevert(IUpgradeableBeacon.NewImplementationHasNoCode.selector);
                beacon.upgradeTo(newImplementation);
                assertEq(beacon.implementation(), implementation);
            }
            if (newImplementation != address(0)) {
                emit Upgraded(newImplementation);
                beacon.upgradeTo(newImplementation);
                assertEq(beacon.implementation(), newImplementation);
            }
        }
    }

    function testUpgradeableBeaconOnlyFnSelectorNotRecognised() public {
        vm.expectRevert(IUpgradeableBeacon.FnSelectorNotRecognized.selector);
        UpgradeableBeaconTest(address(beacon)).testUpgradeableBeaconOnlyFnSelectorNotRecognised();
    }
}
