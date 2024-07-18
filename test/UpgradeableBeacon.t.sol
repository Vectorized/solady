// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {UpgradeableBeacon} from "../src/utils/UpgradeableBeacon.sol";
import {MockImplementation} from "./utils/mocks/MockImplementation.sol";
import {LibClone} from "../src/utils/LibClone.sol";

library UpgradeableBeaconTestLib {
    function deploySolidityBeacon(address initialOwner, address initialImplementation)
        internal
        returns (address)
    {
        return address(new UpgradeableBeacon(initialOwner, initialImplementation));
    }

    function deployYulBeacon(address initialOwner, address initialImplementation)
        internal
        returns (address)
    {
        bytes memory creationCode =
            hex"60406101c73d393d5160205180821760a01c3d3d3e803b1560875781684343a0dc92ed22dbfc558068911c5a209f08d5ec5e557fbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b3d38a23d7f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e03d38a3610132806100953d393df35b636d3e283b3d526004601cfdfe3d3560e01c635c60da1b14610120573d3560e01c80638da5cb5b1461010e5780633659cfe61460021b8163f2fde38b1460011b179063715018a6141780153d3d3e684343a0dc92ed22dbfc805490813303610101573d9260068116610089575b508290557f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e03d38a3005b925060048035938460a01c60243610173d3d3e146100ba5782156100ad573861005f565b637448fbae3d526004601cfd5b82803b156100f4578068911c5a209f08d5ec5e557fbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b3d38a2005b636d3e283b3d526004601cfd5b6382b429003d526004601cfd5b684343a0dc92ed22dbfc543d5260203df35b68911c5a209f08d5ec5e543d5260203df3";
        bytes memory initcode =
            abi.encodePacked(creationCode, abi.encode(initialOwner, initialImplementation));
        address result;
        /// @solidity memory-safe-assembly
        assembly {
            result := create(0, add(0x20, initcode), mload(initcode))
        }
        return result;
    }
}

contract UpgradeableBeaconTest is SoladyTest {
    event Upgraded(address indexed implementation);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    address implementation;
    UpgradeableBeacon beacon;

    bytes32 internal constant _ERC1967_BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    function setUp() public {
        implementation = address(new MockImplementation());
    }

    function _deploySolidityBeacon(address initialOwner, address initialImplementation) internal {
        beacon = UpgradeableBeacon(
            UpgradeableBeaconTestLib.deploySolidityBeacon(initialOwner, initialImplementation)
        );
    }

    function _deploySolidityBeacon() internal {
        _deploySolidityBeacon(address(this), implementation);
    }

    function _deployYulBeacon(address initialOwner, address initialImplementation) internal {
        beacon = UpgradeableBeacon(
            UpgradeableBeaconTestLib.deployYulBeacon(initialOwner, initialImplementation)
        );
    }

    function _deployYulBeacon() internal {
        _deployYulBeacon(address(this), implementation);
    }

    function _deployBeacon() internal {
        if (_randomChance(2)) {
            _deployYulBeacon();
        } else {
            _deploySolidityBeacon();
        }
    }

    function testInitializeUpgradeableSolidityBeacon() public {
        address initialOwner = address(this);
        vm.expectRevert(UpgradeableBeacon.NewImplementationHasNoCode.selector);
        _deploySolidityBeacon(initialOwner, address(0));

        vm.expectEmit(true, true, true, true);
        emit Upgraded(address(implementation));
        emit OwnershipTransferred(address(0), initialOwner);
        _deploySolidityBeacon(initialOwner, implementation);
    }

    function testInitializeUpgradeableYulBeacon() public {
        address initialOwner;
        vm.expectRevert(UpgradeableBeacon.NewOwnerIsZeroAddress.selector);
        _deployYulBeacon(initialOwner, implementation);

        initialOwner = address(this);
        vm.expectRevert(UpgradeableBeacon.NewImplementationHasNoCode.selector);
        _deployYulBeacon(initialOwner, address(0));

        vm.expectEmit(true, true, true, true);
        emit Upgraded(address(implementation));
        emit OwnershipTransferred(address(0), initialOwner);
        _deployYulBeacon(initialOwner, implementation);
    }

    function _testUpgradeableBeaconOnlyOwnerFunctions(address pranker, address newImplementation)
        internal
    {
        vm.startPrank(pranker);
        vm.expectRevert(UpgradeableBeacon.Unauthorized.selector);
        beacon.transferOwnership(address(123));
        vm.expectRevert(UpgradeableBeacon.Unauthorized.selector);
        beacon.renounceOwnership();
        vm.expectRevert(UpgradeableBeacon.Unauthorized.selector);
        beacon.upgradeTo(newImplementation);
        vm.stopPrank();
    }

    function _testUpgradeableBeaconOnlyOwnerFunctions() internal {
        _testUpgradeableBeaconOnlyOwnerFunctions(_randomNonZeroAddress(), implementation);
    }

    function testUpgradeableSolidityBeaconOnlyOwnerFunctions() public {
        _deploySolidityBeacon();
        _testUpgradeableBeaconOnlyOwnerFunctions();
    }

    function testUpgradeableYulBeaconOnlyOwnerFunctions() public {
        _deployYulBeacon();
        _testUpgradeableBeaconOnlyOwnerFunctions();
    }

    function testUpgradeableBeacon(uint256) public {
        _deployBeacon();
        assertEq(beacon.owner(), address(this));

        address newOwner = _randomNonZeroAddress();

        if (_randomChance(32)) {
            _testUpgradeableBeaconOnlyOwnerFunctions();
        }

        if (_randomChance(16)) {
            vm.expectRevert(UpgradeableBeacon.NewOwnerIsZeroAddress.selector);
            beacon.transferOwnership(address(0));
        }

        if (_randomChance(16)) {
            vm.expectEmit(true, true, true, true);
            emit OwnershipTransferred(address(this), address(0));
            beacon.renounceOwnership();
            assertEq(beacon.owner(), address(0));
        }

        if (beacon.owner() != address(0) && _randomChance(2)) {
            emit OwnershipTransferred(address(this), newOwner);
            beacon.transferOwnership(newOwner);
            assertEq(beacon.owner(), newOwner);

            if (_randomChance(2)) {
                _testUpgradeableBeaconOnlyOwnerFunctions(address(this), implementation);
            }

            vm.prank(newOwner);
            emit OwnershipTransferred(newOwner, address(this));
            beacon.transferOwnership(address(this));
            assertEq(beacon.owner(), address(this));
        }

        if (beacon.owner() != address(0) && _randomChance(2)) {
            assertEq(beacon.implementation(), implementation);

            address newImplementation;
            if (_randomChance(2)) {
                newImplementation = LibClone.clone(implementation);
            }
            if (newImplementation == address(0)) {
                vm.expectRevert(UpgradeableBeacon.NewImplementationHasNoCode.selector);
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

    function testUpgradeableYulBeaconOnlyFnSelectorNotRecognised() public {
        _deployYulBeacon();
        vm.expectRevert();
        UpgradeableBeaconTest(address(beacon)).testUpgradeableYulBeaconOnlyFnSelectorNotRecognised();
    }

    function testUpgradeableSolidityBeaconOnlyFnSelectorNotRecognised() public {
        _deploySolidityBeacon();
        vm.expectRevert();
        UpgradeableBeaconTest(address(beacon)).testUpgradeableYulBeaconOnlyFnSelectorNotRecognised();
    }
}
