// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {LibClone} from "../src/utils/LibClone.sol";
import {LibString} from "../src/utils/LibString.sol";
import {SafeTransferLib} from "../src/utils/SafeTransferLib.sol";
import {UpgradeableBeaconTestLib} from "./UpgradeableBeacon.t.sol";

contract LibCloneTest is SoladyTest {
    error CustomError(uint256 currentValue);

    uint256 public value;

    bytes32 internal constant _ERC1967_IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    bytes32 internal constant _ERC1967_BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    uint256 internal constant _CLONES_ARGS_MAX_LENGTH = 0xffd2;

    uint256 internal constant _ERC1967_ARGS_MAX_LENGTH = 0xffc2;

    uint256 internal constant _ERC1967I_ARGS_MAX_LENGTH = 0xffad;

    uint256 internal constant _ERC1967_BEACON_PROXY_ARGS_MAX_LENGTH = 0xffad;

    uint256 internal constant _ERC1967I_BEACON_PROXY_ARGS_MAX_LENGTH = 0xffa8;

    address internal _deployedBeacon;

    function setValue(uint256 value_) public {
        value = value_;
    }

    function revertWithError() public view {
        revert CustomError(value);
    }

    function _checkBehavesLikeProxy(address instance) internal {
        assertTrue(instance != address(0));

        uint256 v = _random();
        uint256 thisValue = this.value();
        if (thisValue == v) {
            v ^= 1;
        }
        LibCloneTest(instance).setValue(v);
        assertEq(v, LibCloneTest(instance).value());
        assertEq(thisValue, this.value());
        vm.expectRevert(abi.encodeWithSelector(CustomError.selector, v));
        LibCloneTest(instance).revertWithError();
    }

    function testDeployERC1967(bytes32) public {
        address instance = LibClone.deployERC1967(address(this));
        _checkBehavesLikeProxy(instance);
        _checkArgsOnERC1967(instance, "");
        _checkERC1967ImplementationSlot(instance);
        assertEq(keccak256(instance.code), LibClone.ERC1967_CODE_HASH);
        assertEq(instance.code.length, 61);
    }

    function testDeployERC1967WithImmutableArgs(bytes32) public {
        bytes memory args = _randomBytes();
        if (args.length > _ERC1967_ARGS_MAX_LENGTH) {
            vm.expectRevert();
            this.deployERC1967(address(this), args);
            return;
        }
        address instance = this.deployERC1967(address(this), args);
        _checkArgsOnERC1967(instance, args);
        _checkBehavesLikeProxy(instance);
        _checkERC1967ImplementationSlot(instance);
    }

    function testDeployERC1967I(bytes32) public {
        address instance = this.deployERC1967I(address(this));
        _checkBehavesLikeProxy(instance);
        _checkERC1967ImplementationSlot(instance);
        _checkERC1967ISpecialPath(instance, address(this));
        assertEq(keccak256(instance.code), LibClone.ERC1967I_CODE_HASH);
        assertEq(instance.code.length, 82);
    }

    function testDeployERC1967IWithImmutableArgs(bytes32) public {
        bytes memory args = _randomBytes();
        if (args.length > _ERC1967I_ARGS_MAX_LENGTH) {
            vm.expectRevert();
            this.deployERC1967I(address(this), args);
            return;
        }
        address instance = this.deployERC1967I(address(this), args);
        _checkArgsOnERC1967I(instance, args);
        _checkBehavesLikeProxy(instance);
        _checkERC1967ImplementationSlot(instance);
        _checkERC1967ISpecialPath(instance, address(this));
    }

    function testDeployERC1967BeaconProxy(bytes32) public {
        address beacon = _beacon();
        address instance = this.deployERC1967BeaconProxy(beacon);
        _checkBehavesLikeProxy(instance);
        _checkERC1967BeaconSlot(instance, beacon);
        assertEq(keccak256(instance.code), LibClone.ERC1967_BEACON_PROXY_CODE_HASH);
        assertEq(instance.code.length, 82);
    }

    function testDeployERC1967IBeaconProxy(bytes32) public {
        address beacon = _beacon();
        address instance = this.deployERC1967IBeaconProxy(beacon);
        _checkBehavesLikeProxy(instance);
        _checkERC1967BeaconSlot(instance, beacon);
        _checkERC1967ISpecialPath(instance, address(this));
        assertEq(keccak256(instance.code), LibClone.ERC1967I_BEACON_PROXY_CODE_HASH);
        assertEq(instance.code.length, 87);
    }

    function testDeployERC1967() public {
        testDeployERC1967(bytes32(0));
    }

    function testDeployERC1967WithImmutableArgs() public {
        testDeployERC1967WithImmutableArgs(bytes32(0));
    }

    function testDeployERC1967IWithImmutableArgs() public {
        testDeployERC1967IWithImmutableArgs(bytes32(0));
    }

    function testDeployERC1967I() public {
        testDeployERC1967I(bytes32(0));
    }

    function testDeployERC1967IBeaconProxy() public {
        testDeployERC1967IBeaconProxy(bytes32(0));
    }

    function testDeployERC1967BeaconProxyWithImmutableArgs(address beacon, bytes32 salt) public {
        bytes memory args = _randomBytes();
        if (args.length > _ERC1967_BEACON_PROXY_ARGS_MAX_LENGTH) {
            if (_randomChance(2)) {
                vm.expectRevert();
                this.deployERC1967BeaconProxy(beacon, args);
                return;
            }
            if (_randomChance(2)) {
                vm.expectRevert();
                this.deployDeterministicERC1967BeaconProxy(beacon, args, salt);
                return;
            }
            vm.expectRevert();
            this.createDeterministicERC1967BeaconProxy(beacon, args, salt);
            return;
        }
        address instance = LibClone.deployERC1967BeaconProxy(beacon);
        bytes memory expected = abi.encodePacked(instance.code, args);
        if (_randomChance(2)) {
            instance = this.deployERC1967BeaconProxy(beacon, args);
            assertEq(instance.code, expected);
        }
        if (_randomChance(2)) {
            instance = this.deployDeterministicERC1967BeaconProxy(beacon, args, salt);
            assertEq(instance.code, expected);
            if (_randomChance(2)) {
                vm.expectRevert();
                this.deployDeterministicERC1967BeaconProxy(beacon, args, salt);
                return;
            }
        }
        if (_randomChance(2)) {
            instance = this.createDeterministicERC1967BeaconProxy(beacon, args, salt);
            assertEq(instance.code, expected);
            _checkArgsOnERC1967BeaconProxy(instance, args);
        }
    }

    function testDeployERC1967IBeaconProxyWithImmutableArgs(address beacon, bytes32 salt) public {
        bytes memory args = _randomBytes();
        if (args.length > _ERC1967I_BEACON_PROXY_ARGS_MAX_LENGTH) {
            if (_randomChance(2)) {
                vm.expectRevert();
                this.deployERC1967IBeaconProxy(beacon, args);
                return;
            }
            if (_randomChance(2)) {
                vm.expectRevert();
                this.deployDeterministicERC1967IBeaconProxy(beacon, args, salt);
                return;
            }
            vm.expectRevert();
            this.createDeterministicERC1967IBeaconProxy(beacon, args, salt);
            return;
        }
        address instance = LibClone.deployERC1967IBeaconProxy(beacon);
        bytes memory expected = abi.encodePacked(instance.code, args);
        if (_randomChance(2)) {
            instance = this.deployERC1967IBeaconProxy(beacon, args);
            assertEq(instance.code, expected);
        }
        if (_randomChance(2)) {
            instance = this.deployDeterministicERC1967IBeaconProxy(beacon, args, salt);
            assertEq(instance.code, expected);
            if (_randomChance(2)) {
                vm.expectRevert();
                this.deployDeterministicERC1967IBeaconProxy(beacon, args, salt);
                return;
            }
        }
        if (_randomChance(2)) {
            instance = this.createDeterministicERC1967IBeaconProxy(beacon, args, salt);
            assertEq(instance.code, expected);
            _checkArgsOnERC1967IBeaconProxy(instance, args);
        }
    }

    function testDeployERC1967BeaconProxyWithImmutableArgs() public {
        address beacon = _beacon();
        bytes memory args = "123456789";
        address instance = LibClone.deployERC1967BeaconProxy(beacon, args);
        _checkBehavesLikeProxy(instance);
        _checkArgsOnERC1967BeaconProxy(instance, args);
    }

    function testDeployERC1967IBeaconProxyWithImmutableArgs() public {
        address beacon = _beacon();
        bytes memory args = "123456789";
        address instance = LibClone.deployERC1967IBeaconProxy(beacon, args);
        _checkBehavesLikeProxy(instance);
        _checkERC1967ISpecialPath(instance, address(this));
        _checkArgsOnERC1967IBeaconProxy(instance, args);
    }

    function testImplemenationOf(address implementation) public {
        _maybeBrutalizeMemory();
        bytes memory args = _truncateBytes(_randomBytes(), _ERC1967I_BEACON_PROXY_ARGS_MAX_LENGTH);
        address instance;
        if (_randomChance(8)) {
            _maybeBrutalizeMemory();
            instance = LibClone.clone(implementation);
            assertEq(LibClone.implementationOf(instance), implementation);
        }
        if (_randomChance(8)) {
            _maybeBrutalizeMemory();
            instance = LibClone.clone(implementation, args);
            assertEq(LibClone.implementationOf(instance), implementation);
        }
        if (_randomChance(8)) {
            _maybeBrutalizeMemory();
            instance = LibClone.deployERC1967I(implementation);
            assertEq(LibClone.implementationOf(instance), implementation);
        }
        if (_randomChance(8)) {
            _maybeBrutalizeMemory();
            instance = LibClone.deployERC1967I(implementation, args);
            assertEq(LibClone.implementationOf(instance), implementation);
        }
        if (_randomChance(8)) {
            _maybeBrutalizeMemory();
            instance = LibClone.deployERC1967IBeaconProxy(_beacon());
            assertEq(LibClone.implementationOf(instance), address(this));
        }
        if (_randomChance(8)) {
            _maybeBrutalizeMemory();
            instance = LibClone.deployERC1967IBeaconProxy(_beacon(), args);
            assertEq(LibClone.implementationOf(instance), address(this));
        }
        if (_randomChance(8)) {
            _maybeBrutalizeMemory();
            assertEq(LibClone.implementationOf(address(this)), address(0));
            assertEq(LibClone.implementationOf(implementation), address(0));
        }
        _checkMemory();
    }

    function testImplemenationOfGas() public {
        address implementation = address(123);
        bytes memory args = "1234564789";
        address instance;

        instance = LibClone.clone(implementation);
        assertEq(LibClone.implementationOf(instance), implementation);

        instance = LibClone.clone(implementation, args);
        assertEq(LibClone.implementationOf(instance), implementation);

        instance = LibClone.deployERC1967I(implementation);
        assertEq(LibClone.implementationOf(instance), implementation);

        instance = LibClone.deployERC1967I(implementation, args);
        assertEq(LibClone.implementationOf(instance), implementation);

        instance = LibClone.deployERC1967IBeaconProxy(_beacon());
        assertEq(LibClone.implementationOf(instance), address(this));

        instance = LibClone.deployERC1967IBeaconProxy(_beacon(), args);
        assertEq(LibClone.implementationOf(instance), address(this));

        assertEq(LibClone.implementationOf(address(this)), address(0));
        assertEq(LibClone.implementationOf(implementation), address(0));
    }

    function testClone(uint256) public {
        _checkBehavesLikeProxy(this.clone(address(this)));
    }

    function testClone() public {
        testClone(1);
    }

    function testCloneWithImmutableArgs() public {
        testCloneWithImmutableArgs(1);
    }

    function testCloneWithImmutableArgs(uint256) public {
        bytes memory args = _randomBytes();
        if (args.length > _CLONES_ARGS_MAX_LENGTH) {
            vm.expectRevert(LibClone.DeploymentFailed.selector);
            this.clone(address(this), args);
            return;
        }
        address instance = this.clone(address(this), args);
        _checkArgsOnClone(instance, args);
        _checkBehavesLikeProxy(instance);
    }

    function testSlicingRevertsOnZeroCodeAddress(address instance) public {
        while (instance.code.length != 0) instance = _randomNonZeroAddress();
        if (_randomChance(4)) {
            _maybeBrutalizeMemory();
            if (_randomChance(4)) {
                vm.expectRevert();
                _mustCompute(LibClone.argsOnClone(instance));
                return;
            }
            if (_randomChance(4)) {
                vm.expectRevert();
                _mustCompute(LibClone.argsOnClone(instance, _random()));
                return;
            }
            if (_randomChance(4)) {
                vm.expectRevert();
                _mustCompute(LibClone.argsOnClone(instance, _random(), _random()));
                return;
            }
            instance = LibClone.clone(address(this), "");
            assertEq(LibClone.argsOnClone(instance), "");
            assertEq(LibClone.argsOnClone(instance, _random()), "");
            assertEq(LibClone.argsOnClone(instance, _random(), _random()), "");
            return;
        }
        if (_randomChance(4)) {
            _maybeBrutalizeMemory();
            if (_randomChance(4)) {
                vm.expectRevert();
                _mustCompute(LibClone.argsOnERC1967(instance));
                return;
            }
            if (_randomChance(4)) {
                vm.expectRevert();
                _mustCompute(LibClone.argsOnERC1967(instance, _random()));
                return;
            }
            if (_randomChance(4)) {
                vm.expectRevert();
                _mustCompute(LibClone.argsOnERC1967(instance, _random(), _random()));
                return;
            }
            instance = LibClone.deployERC1967(address(this), "");
            assertEq(LibClone.argsOnERC1967(instance), "");
            assertEq(LibClone.argsOnERC1967(instance, _random()), "");
            assertEq(LibClone.argsOnERC1967(instance, _random(), _random()), "");
            return;
        }
        if (_randomChance(4)) {
            _maybeBrutalizeMemory();
            if (_randomChance(4)) {
                vm.expectRevert();
                _mustCompute(LibClone.argsOnERC1967I(instance));
                return;
            }
            if (_randomChance(4)) {
                vm.expectRevert();
                _mustCompute(LibClone.argsOnERC1967I(instance, _random()));
                return;
            }
            if (_randomChance(4)) {
                vm.expectRevert();
                _mustCompute(LibClone.argsOnERC1967I(instance, _random(), _random()));
                return;
            }
            instance = LibClone.deployERC1967I(address(this), "");
            assertEq(LibClone.argsOnERC1967I(instance), "");
            assertEq(LibClone.argsOnERC1967I(instance, _random()), "");
            assertEq(LibClone.argsOnERC1967I(instance, _random(), _random()), "");
            return;
        }
        if (_randomChance(4)) {
            _maybeBrutalizeMemory();
            if (_randomChance(4)) {
                vm.expectRevert();
                _mustCompute(LibClone.argsOnERC1967BeaconProxy(instance));
                return;
            }
            if (_randomChance(4)) {
                vm.expectRevert();
                _mustCompute(LibClone.argsOnERC1967BeaconProxy(instance, _random()));
                return;
            }
            if (_randomChance(4)) {
                vm.expectRevert();
                _mustCompute(LibClone.argsOnERC1967BeaconProxy(instance, _random(), _random()));
                return;
            }
            instance = LibClone.deployERC1967BeaconProxy(address(this), "");
            assertEq(LibClone.argsOnERC1967BeaconProxy(instance), "");
            assertEq(LibClone.argsOnERC1967BeaconProxy(instance, _random()), "");
            assertEq(LibClone.argsOnERC1967BeaconProxy(instance, _random(), _random()), "");
            return;
        }
        if (_randomChance(4)) {
            _maybeBrutalizeMemory();
            if (_randomChance(4)) {
                vm.expectRevert();
                _mustCompute(LibClone.argsOnERC1967IBeaconProxy(instance));
                return;
            }
            if (_randomChance(4)) {
                vm.expectRevert();
                _mustCompute(LibClone.argsOnERC1967IBeaconProxy(instance, _random()));
                return;
            }
            if (_randomChance(4)) {
                vm.expectRevert();
                _mustCompute(LibClone.argsOnERC1967IBeaconProxy(instance, _random(), _random()));
                return;
            }
            instance = LibClone.deployERC1967IBeaconProxy(address(this), "");
            assertEq(LibClone.argsOnERC1967IBeaconProxy(instance), "");
            assertEq(LibClone.argsOnERC1967IBeaconProxy(instance, _random()), "");
            assertEq(LibClone.argsOnERC1967IBeaconProxy(instance, _random(), _random()), "");
            return;
        }
    }

    function _mustCompute(bytes memory s) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if eq(keccak256(s, 0x80), 123) { sstore(keccak256(0x00, 0x21), 1) }
        }
    }

    function testCloneWithImmutableArgsSlicing() public {
        bytes memory args = "1234567890123456789012345678901234567890123456789012345678901234";
        address instance = LibClone.clone(address(this), args);
        assertEq(LibClone.argsOnClone(instance), args);
        assertEq(LibClone.argsOnClone(instance, 32), "34567890123456789012345678901234");
        assertEq(LibClone.argsOnClone(instance, 0, 64), args);
        assertEq(LibClone.argsOnClone(instance, 0, 65), args);
        assertEq(LibClone.argsOnClone(instance, 0, 32), "12345678901234567890123456789012");
        assertEq(LibClone.argsOnClone(instance, 1, 32), "2345678901234567890123456789012");
    }

    function testCloneDeterministic(bytes32 salt) public {
        address instance = this.cloneDeterministic(address(this), salt);
        _checkBehavesLikeProxy(instance);
        if (_randomChance(32)) {
            vm.expectRevert(LibClone.DeploymentFailed.selector);
            this.testCloneDeterministic(salt);
        }
    }

    function testCreateDeterministicCloneWithImmutableArgs(bytes32 salt) public {
        bytes memory args = _randomBytes();
        if (args.length > _CLONES_ARGS_MAX_LENGTH) {
            vm.expectRevert();
            this.createDeterministicClone(address(this), args, salt);
            return;
        }
        address instance = this.createDeterministicClone(address(this), args, salt);
        _checkArgsOnClone(instance, args);
        _checkBehavesLikeProxy(instance);
        if (_randomChance(32)) {
            this.createDeterministicClone(address(this), args, salt);
        }
    }

    function testCloneDeterministicWithImmutableArgs() public {
        testCloneDeterministicWithImmutableArgs(bytes32(0));
    }

    function testCloneDeterministicWithImmutableArgs(bytes32 salt) public {
        bytes memory args = _randomBytes();
        if (args.length > _CLONES_ARGS_MAX_LENGTH) {
            vm.expectRevert(LibClone.DeploymentFailed.selector);
            this.cloneDeterministic(address(this), args, salt);
            return;
        }
        address instance = this.cloneDeterministic(address(this), args, salt);
        _checkBehavesLikeProxy(instance);
        _checkArgsOnClone(instance, args);
        if (_randomChance(32)) {
            vm.expectRevert(LibClone.DeploymentFailed.selector);
            this.cloneDeterministic(address(this), args, salt);
        }
    }

    function testCloneDeterministic() public {
        testCloneDeterministic(keccak256("b"));
    }

    function testDeployDeterministicERC1967(bytes32 salt) public {
        address instance = this.deployDeterministicERC1967(address(this), salt);
        _checkBehavesLikeProxy(instance);
        _checkArgsOnERC1967(instance, "");
        _checkERC1967ImplementationSlot(instance);
        if (_randomChance(32)) {
            vm.expectRevert(LibClone.DeploymentFailed.selector);
            this.testDeployDeterministicERC1967(salt);
        }
    }

    function testDeployDeterministicERC1967WithImmutableArgs() public {
        testDeployDeterministicERC1967WithImmutableArgs(bytes32(0));
    }

    function testDeployDeterministicERC1967WithImmutableArgs(bytes32 salt) public {
        bytes memory args = _randomBytes();
        if (args.length > _ERC1967_ARGS_MAX_LENGTH) {
            vm.expectRevert();
            this.deployDeterministicERC1967(address(this), args, salt);
            return;
        }
        address instance = this.deployDeterministicERC1967(address(this), args, salt);
        _checkArgsOnERC1967(instance, args);
        _checkBehavesLikeProxy(instance);
        _checkERC1967ImplementationSlot(instance);
        if (_randomChance(32)) {
            vm.expectRevert(LibClone.DeploymentFailed.selector);
            this.deployDeterministicERC1967(address(this), args, salt);
        }
    }

    function testDeployDeterministicERC1967() public {
        testDeployDeterministicERC1967(bytes32(0));
    }

    function testDeployDeterministicERC1967I() public {
        testDeployDeterministicERC1967I(bytes32(0));
    }

    function testDeployDeterministicERC1967I(bytes32 salt) public {
        address instance = this.deployDeterministicERC1967I(address(this), salt);
        _checkBehavesLikeProxy(instance);
        _checkERC1967ImplementationSlot(instance);
        if (_randomChance(32)) {
            vm.expectRevert(LibClone.DeploymentFailed.selector);
            this.testDeployDeterministicERC1967I(salt);
        }
    }

    function testDeployDeterministicERC1967IWithImmutableArgs() public {
        testDeployDeterministicERC1967I(bytes32(0));
    }

    function testDeployDeterministicERC1967IWithImmutableArgs(bytes32 salt) public {
        bytes memory args = _randomBytes();
        if (args.length > _ERC1967I_ARGS_MAX_LENGTH) {
            vm.expectRevert();
            this.deployDeterministicERC1967I(address(this), args, salt);
            return;
        }
        address instance = this.deployDeterministicERC1967I(address(this), args, salt);
        _checkArgsOnERC1967I(instance, args);
        _checkBehavesLikeProxy(instance);
        _checkERC1967ImplementationSlot(instance);
        if (_randomChance(32)) {
            vm.expectRevert(LibClone.DeploymentFailed.selector);
            this.deployDeterministicERC1967I(address(this), args, salt);
        }
    }

    function testDeployDeterministicERC1967BeaconProxy(bytes32 salt) public {
        address instance = this.deployDeterministicERC1967BeaconProxy(_beacon(), salt);
        _checkBehavesLikeProxy(instance);
        _checkERC1967BeaconSlot(instance, _beacon());
        if (_randomChance(32)) {
            vm.expectRevert(LibClone.DeploymentFailed.selector);
            this.testDeployDeterministicERC1967BeaconProxy(salt);
        }
    }

    function testDeployDeterministicERC1967IBeaconProxy(bytes32 salt) public {
        address instance = this.deployDeterministicERC1967IBeaconProxy(_beacon(), salt);
        _checkBehavesLikeProxy(instance);
        _checkERC1967BeaconSlot(instance, _beacon());
        _checkERC1967ISpecialPath(instance, address(this));
        if (_randomChance(32)) {
            vm.expectRevert(LibClone.DeploymentFailed.selector);
            this.testDeployDeterministicERC1967IBeaconProxy(salt);
        }
    }

    function testDeployDeterministicERC1967BeaconProxyWithImmutableArgs(bytes32 salt) public {
        bytes memory args = _randomBytes();
        if (args.length > _ERC1967_BEACON_PROXY_ARGS_MAX_LENGTH) {
            vm.expectRevert();
            this.deployDeterministicERC1967BeaconProxy(address(this), args, salt);
            return;
        }
        address instance = this.deployDeterministicERC1967BeaconProxy(_beacon(), args, salt);
        _checkBehavesLikeProxy(instance);
        _checkERC1967BeaconSlot(instance, _beacon());
        _checkArgsOnERC1967BeaconProxy(instance, args);
        if (_randomChance(32)) {
            vm.expectRevert(LibClone.DeploymentFailed.selector);
            this.deployDeterministicERC1967BeaconProxy(_beacon(), args, salt);
        }
    }

    function testDeployDeterministicERC1967IBeaconProxyWithImmutableArgs(bytes32 salt) public {
        bytes memory args = _randomBytes();
        if (args.length > _ERC1967I_BEACON_PROXY_ARGS_MAX_LENGTH) {
            vm.expectRevert();
            this.deployDeterministicERC1967IBeaconProxy(address(this), args, salt);
            return;
        }
        address instance = this.deployDeterministicERC1967IBeaconProxy(_beacon(), args, salt);
        _checkBehavesLikeProxy(instance);
        _checkArgsOnERC1967IBeaconProxy(instance, args);
        _checkERC1967BeaconSlot(instance, _beacon());
        _checkERC1967ISpecialPath(instance, address(this));
        if (_randomChance(32)) {
            vm.expectRevert(LibClone.DeploymentFailed.selector);
            this.deployDeterministicERC1967IBeaconProxy(_beacon(), args, salt);
        }
    }

    function testCreateDeterministicERC1967(bytes32 salt) public {
        address instance = this.createDeterministicERC1967(address(this), salt);
        _checkBehavesLikeProxy(instance);
        _checkERC1967ImplementationSlot(instance);
        if (_randomChance(32)) {
            this.testCreateDeterministicERC1967(salt);
        }
    }

    function testCreateDeterministicERC1967WithImmutableArgs(bytes32 salt) public {
        bytes memory args = _randomBytes();
        if (args.length > _ERC1967_ARGS_MAX_LENGTH) {
            vm.expectRevert();
            this.createDeterministicERC1967(address(this), args, salt);
            return;
        }
        address instance = this.createDeterministicERC1967(address(this), args, salt);
        _checkBehavesLikeProxy(instance);
        _checkERC1967ImplementationSlot(instance);
        _checkArgsOnERC1967(instance, args);
        if (_randomChance(32)) {
            this.createDeterministicERC1967(address(this), args, salt);
        }
    }

    function testCreateDeterministicERC1967I(bytes32 salt) public {
        address instance = this.createDeterministicERC1967I(address(this), salt);
        _checkBehavesLikeProxy(instance);
        _checkERC1967ImplementationSlot(instance);
        if (_randomChance(32)) {
            this.testCreateDeterministicERC1967I(salt);
        }
    }

    function testCreateDeterministicERC1967IWithImmutableArgs(bytes32 salt) public {
        bytes memory args = _randomBytes();
        if (args.length > _ERC1967I_ARGS_MAX_LENGTH) {
            vm.expectRevert();
            this.createDeterministicERC1967I(address(this), args, salt);
            return;
        }
        address instance = this.createDeterministicERC1967I(address(this), args, salt);
        _checkBehavesLikeProxy(instance);
        _checkArgsOnERC1967I(instance, args);
        _checkERC1967ImplementationSlot(instance);
        if (_randomChance(32)) {
            this.createDeterministicERC1967I(address(this), args, salt);
        }
    }

    function testCreateDeterministicERC1967BeaconProxy(bytes32 salt) public {
        address instance = this.createDeterministicERC1967BeaconProxy(_beacon(), salt);
        _checkBehavesLikeProxy(instance);
        _checkERC1967BeaconSlot(instance, _beacon());
        if (_randomChance(32)) {
            this.testCreateDeterministicERC1967BeaconProxy(salt);
        }
    }

    function testCreateDeterministicERC1967IBeaconProxy(bytes32 salt) public {
        address instance = this.createDeterministicERC1967IBeaconProxy(_beacon(), salt);
        _checkBehavesLikeProxy(instance);
        _checkERC1967BeaconSlot(instance, _beacon());
        if (_randomChance(32)) {
            this.testCreateDeterministicERC1967IBeaconProxy(salt);
        }
    }

    function testCreateDeterministicERC1967BeaconProxyWithImmutableArgs(bytes32 salt) public {
        bytes memory args = _randomBytes();
        if (args.length > _ERC1967_BEACON_PROXY_ARGS_MAX_LENGTH) {
            vm.expectRevert();
            this.createDeterministicERC1967BeaconProxy(address(this), args, salt);
            return;
        }

        address instance = this.createDeterministicERC1967BeaconProxy(_beacon(), args, salt);
        _checkBehavesLikeProxy(instance);
        _checkERC1967BeaconSlot(instance, _beacon());
        if (_randomChance(32)) {
            this.createDeterministicERC1967BeaconProxy(_beacon(), args, salt);
        }
    }

    function testCreateDeterministicERC1967IBeaconProxyWithImmutableArgs(bytes32 salt) public {
        bytes memory args = _randomBytes();
        if (args.length > _ERC1967I_BEACON_PROXY_ARGS_MAX_LENGTH) {
            vm.expectRevert();
            this.createDeterministicERC1967IBeaconProxy(address(this), args, salt);
            return;
        }

        address instance = this.createDeterministicERC1967IBeaconProxy(_beacon(), args, salt);
        _checkBehavesLikeProxy(instance);
        _checkERC1967BeaconSlot(instance, _beacon());
        _checkERC1967ISpecialPath(instance, address(this));
        if (_randomChance(32)) {
            this.createDeterministicERC1967IBeaconProxy(_beacon(), args, salt);
        }
    }

    function testStartsWith(uint256) public {
        uint256 noise = _random() >> 160;
        this.checkStartsWith(bytes32(noise), address(0));

        address by = _randomNonZeroAddress();
        this.checkStartsWith(bytes32((uint256(uint160(by)) << 96) | noise), by);

        address notBy;
        while (by == notBy) notBy = _randomNonZeroAddress();
        vm.expectRevert(LibClone.SaltDoesNotStartWith.selector);
        this.checkStartsWith(bytes32((uint256(uint160(by)) << 96) | noise), notBy);
    }

    function checkStartsWith(bytes32 salt, address by) public pure {
        LibClone.checkStartsWith(salt, _brutalized(by));
    }

    function testInitialDeposit() public {
        vm.deal(address(this), 1 ether);
        address t = address(this);
        assertEq(LibClone.clone(123, t).balance, 123);
        assertEq(LibClone.cloneDeterministic(123, t, bytes32(gasleft())).balance, 123);
        assertEq(LibClone.clone(123, t, "").balance, 123);
        assertEq(LibClone.cloneDeterministic(123, t, "", bytes32(gasleft())).balance, 123);
        assertEq(LibClone.deployERC1967(123, t).balance, 123);
        assertEq(LibClone.deployDeterministicERC1967(123, t, bytes32(gasleft())).balance, 123);
        assertEq(LibClone.deployERC1967I(123, t).balance, 123);
        assertEq(LibClone.deployDeterministicERC1967I(123, t, bytes32(gasleft())).balance, 123);
        assertEq(LibClone.deployERC1967I(123, t, "").balance, 123);
        assertEq(LibClone.deployDeterministicERC1967I(123, t, "", bytes32(gasleft())).balance, 123);
        assertEq(LibClone.deployERC1967BeaconProxy(123, t).balance, 123);
        assertEq(
            LibClone.deployDeterministicERC1967BeaconProxy(123, t, bytes32(gasleft())).balance, 123
        );
        assertEq(LibClone.deployERC1967IBeaconProxy(123, t, "").balance, 123);
        assertEq(
            LibClone.deployDeterministicERC1967IBeaconProxy(123, t, "", bytes32(gasleft())).balance,
            123
        );
    }

    function testInitCode(address implementation) public {
        if (_randomChance(4)) _testInitCode(implementation);
        if (_randomChance(4)) _testInitCodeWithImmutableArgs(implementation);
        if (_randomChance(4)) _testInitCode_PUSH0(implementation);
        if (_randomChance(4)) _testInitCodeERC1967(implementation);
        if (_randomChance(4)) _testInitCodeERC1967WithImmutableArgs(implementation);
        if (_randomChance(4)) _testInitCodeERC1967I(implementation);
        if (_randomChance(4)) _testInitCodeERC1967IWithImmutableArgs(implementation);
        if (_randomChance(4)) _testInitCodeERC1967BeaconProxy(implementation);
        if (_randomChance(4)) _testInitCodeERC1967BeaconProxyWithImmutableArgs(implementation);
        if (_randomChance(4)) _testInitCodeERC1967IBeaconProxy(implementation);
        if (_randomChance(4)) _testInitCodeERC1967IBeaconProxyWithImmutableArgs(implementation);
    }

    function _testInitCode(address implementation) internal {
        _misalignFreeMemoryPointer();
        _maybeBrutalizeMemory();
        bytes memory initCode = LibClone.initCode(_brutalized(implementation));
        _checkMemory(initCode);
        _maybeBrutalizeMemory();
        bytes32 expected = LibClone.initCodeHash(_brutalized(implementation));
        _checkMemory(initCode);
        assertEq(keccak256(initCode), expected);
    }

    function _testInitCodeWithImmutableArgs(address implementation) internal {
        _maybeBrutalizeMemory();
        bytes memory args = _randomBytesForCloneImmutableArgs();
        bytes memory initCode = LibClone.initCode(_brutalized(implementation), args);
        _checkMemory(initCode);
        _maybeBrutalizeMemory();
        bytes32 expected = LibClone.initCodeHash(_brutalized(implementation), args);
        _checkMemory(initCode);
        assertEq(keccak256(initCode), expected);
        if (_randomChance(32)) {
            assertEq(initCode, _initCodeOfClonesWithImmutableArgs(implementation, args));
        }
    }

    function _testInitCode_PUSH0(address implementation) internal {
        _maybeBrutalizeMemory();
        bytes memory initCode = LibClone.initCode_PUSH0(_brutalized(implementation));
        _checkMemory(initCode);
        _maybeBrutalizeMemory();
        bytes32 expected = LibClone.initCodeHash_PUSH0(_brutalized(implementation));
        _checkMemory(initCode);
        assertEq(keccak256(initCode), expected);
    }

    function _testInitCodeERC1967(address implementation) internal {
        _maybeBrutalizeMemory();
        bytes memory initCode = LibClone.initCodeERC1967(_brutalized(implementation));
        _checkMemory(initCode);
        _maybeBrutalizeMemory();
        bytes32 expected = LibClone.initCodeHashERC1967(_brutalized(implementation));
        _checkMemory(initCode);
        assertEq(keccak256(initCode), expected);
    }

    function _testInitCodeERC1967WithImmutableArgs(address implementation) internal {
        _maybeBrutalizeMemory();
        bytes memory args = _randomBytesForERC1967ImmutableArgs();
        bytes memory initCode = LibClone.initCodeERC1967(_brutalized(implementation), args);
        _checkMemory(initCode);
        _maybeBrutalizeMemory();
        bytes32 expected = LibClone.initCodeHashERC1967(_brutalized(implementation), args);
        _checkMemory(initCode);
        assertEq(keccak256(initCode), expected);
        if (_randomChance(32)) {
            assertEq(initCode, _initCodeOfERC1967WithImmutableArgs(implementation, args));
        }
    }

    function _testInitCodeERC1967I(address implementation) internal {
        _maybeBrutalizeMemory();
        bytes memory initCode = LibClone.initCodeERC1967I(_brutalized(implementation));
        _checkMemory(initCode);
        _maybeBrutalizeMemory();
        bytes32 expected = LibClone.initCodeHashERC1967I(_brutalized(implementation));
        _checkMemory(initCode);
        assertEq(keccak256(initCode), expected);
    }

    function _testInitCodeERC1967IWithImmutableArgs(address implementation) internal {
        _maybeBrutalizeMemory();
        bytes memory args = _randomBytesForERC1967IImmutableArgs();
        bytes memory initCode = LibClone.initCodeERC1967I(_brutalized(implementation), args);
        _checkMemory(initCode);
        _maybeBrutalizeMemory();
        bytes32 expected = LibClone.initCodeHashERC1967I(_brutalized(implementation), args);
        _checkMemory(initCode);
        assertEq(keccak256(initCode), expected);
        if (_randomChance(32)) {
            assertEq(initCode, _initCodeOfERC1967IWithImmutableArgs(implementation, args));
        }
    }

    function _testInitCodeERC1967BeaconProxy(address beacon) internal {
        _maybeBrutalizeMemory();
        bytes memory initCode = LibClone.initCodeERC1967BeaconProxy(_brutalized(beacon));
        _checkMemory(initCode);
        _maybeBrutalizeMemory();
        bytes32 expected = LibClone.initCodeHashERC1967BeaconProxy(_brutalized(beacon));
        _checkMemory(initCode);
        assertEq(keccak256(initCode), expected);
    }

    function _testInitCodeERC1967BeaconProxyWithImmutableArgs(address beacon) internal {
        _maybeBrutalizeMemory();
        bytes memory args = _randomBytesForERC1967BeconProxyImmutableArgs();
        bytes memory initCode = LibClone.initCodeERC1967BeaconProxy(_brutalized(beacon), args);
        _checkMemory(initCode);
        _maybeBrutalizeMemory();
        bytes32 expected = LibClone.initCodeHashERC1967BeaconProxy(_brutalized(beacon), args);
        _checkMemory(initCode);
        assertEq(keccak256(initCode), expected);
        if (_randomChance(32)) {
            assertEq(initCode, _initCodeOfERC1967BeaconProxyWithImmutableArgs(beacon, args));
        }
    }

    function _testInitCodeERC1967IBeaconProxy(address beacon) internal {
        _maybeBrutalizeMemory();
        bytes memory initCode = LibClone.initCodeERC1967IBeaconProxy(_brutalized(beacon));
        _checkMemory(initCode);
        _maybeBrutalizeMemory();
        bytes32 expected = LibClone.initCodeHashERC1967IBeaconProxy(_brutalized(beacon));
        _checkMemory(initCode);
        assertEq(keccak256(initCode), expected);
    }

    function _testInitCodeERC1967IBeaconProxyWithImmutableArgs(address beacon) internal {
        _maybeBrutalizeMemory();
        bytes memory args = _randomBytesForERC1967IBeconProxyImmutableArgs();
        bytes memory initCode = LibClone.initCodeERC1967IBeaconProxy(_brutalized(beacon), args);
        _checkMemory(initCode);
        _maybeBrutalizeMemory();
        bytes32 expected = LibClone.initCodeHashERC1967IBeaconProxy(_brutalized(beacon), args);
        _checkMemory(initCode);
        assertEq(keccak256(initCode), expected);
        if (_randomChance(32)) {
            assertEq(initCode, _initCodeOfERC1967IBeaconProxyWithImmutableArgs(beacon, args));
        }
    }

    function _initCodeOfClonesWithImmutableArgs(address implementation, bytes memory args)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            hex"61",
            uint16(args.length + 0x2d),
            hex"3d81600a3d39f3363d3d373d3d3d363d73",
            implementation,
            hex"5af43d82803e903d91602b57fd5bf3",
            args
        );
    }

    function _initCodeOfERC1967WithImmutableArgs(address implementation, bytes memory args)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            hex"61",
            uint16(args.length + 0x3d),
            hex"3d8160233d3973",
            implementation,
            hex"60095155f3363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f3",
            args
        );
    }

    function _initCodeOfERC1967IWithImmutableArgs(address implementation, bytes memory args)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            hex"61",
            uint16(args.length + 0x52),
            hex"3d8160233d3973",
            implementation,
            hex"600f5155f3365814604357363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af43d6000803e603e573d6000fd5b3d6000f35b6020600f3d393d51543d52593df3",
            args
        );
    }

    function _initCodeOfERC1967BeaconProxyWithImmutableArgs(address beacon, bytes memory args)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            hex"61",
            uint16(args.length + 0x52),
            hex"3d8160233d3973",
            beacon,
            hex"60195155f3363d3d373d3d363d602036600436635c60da1b60e01b36527fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50545afa5036515af43d6000803e604d573d6000fd5b3d6000f3",
            args
        );
    }

    function _initCodeOfERC1967IBeaconProxy(address beacon) internal pure returns (bytes memory) {
        return abi.encodePacked(
            hex"60573d8160233d3973",
            beacon,
            hex"60195155f3363d3d373d3d363d602036600436635c60da1b60e01b36527fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50545afa361460525736515af43d600060013e6052573d6001fd5b3d6001f3"
        );
    }

    function _initCodeOfERC1967IBeaconProxyWithImmutableArgs(address beacon, bytes memory args)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            hex"61",
            uint16(args.length + 0x57),
            hex"3d8160233d3973",
            beacon,
            hex"60195155f3363d3d373d3d363d602036600436635c60da1b60e01b36527fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50545afa361460525736515af43d600060013e6052573d6001fd5b3d6001f3",
            args
        );
    }

    function testERC1967BootstrapInitCode(address authorizedUpgrader) public {
        bytes memory c = LibClone.initCodeERC1967Bootstrap(authorizedUpgrader);
        bytes memory expected = abi.encodePacked(
            hex"606880600a3d393df3fe3373",
            authorizedUpgrader,
            hex"0338573d3560601c7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc55601436116049575b005b363d3d373d3d6014360360143d3560601c5af46047573d6000383e3d38fd"
        );
        assertEq(c, expected);
    }

    function testERC1967BootstrapGuard(address implementation, bytes32 salt) public {
        address authorizedUpgrader = _randomNonZeroAddress();
        address bootstrap = LibClone.erc1967Bootstrap(authorizedUpgrader);
        address instance = this.deployDeterministicERC1967I(bootstrap, salt);
        assertEq(LibClone.implementationOf(instance), bootstrap);
        bytes memory bootstrapCode = address(bootstrap).code;
        assertEq(uint8(bootstrapCode[bootstrapCode.length - 1]), uint8(0xfd));
        if (_randomChance(2)) {
            vm.prank(authorizedUpgrader);
            LibClone.bootstrapERC1967(instance, implementation);
            assertEq(LibClone.implementationOf(instance), implementation);
        } else {
            vm.expectRevert();
            LibClone.bootstrapERC1967(instance, implementation);
        }
    }

    function testERC1967Bootstrap(address implementation, bytes32 salt) public {
        address bootstrap = LibClone.predictDeterministicAddressERC1967Bootstrap();
        assertEq(LibClone.erc1967Bootstrap(), bootstrap);
        if (_randomChance(2)) {
            assertEq(LibClone.erc1967Bootstrap(), bootstrap);
        }

        address instance;
        if (_randomChance(2)) {
            instance = LibClone.predictDeterministicAddressERC1967(bootstrap, salt, address(this));
            assertEq(this.deployDeterministicERC1967(bootstrap, salt), instance);
        } else {
            instance = LibClone.predictDeterministicAddressERC1967I(bootstrap, salt, address(this));
            assertEq(this.deployDeterministicERC1967I(bootstrap, salt), instance);
        }

        if (_randomChance(2)) {
            LibClone.bootstrapERC1967(instance, implementation);
            assertEq(
                vm.load(instance, _ERC1967_IMPLEMENTATION_SLOT),
                bytes32(uint256(uint160(implementation)))
            );
        } else if (_randomChance(2)) {
            LibClone.bootstrapERC1967(instance, address(this));
            assertEq(
                vm.load(instance, _ERC1967_IMPLEMENTATION_SLOT),
                bytes32(uint256(uint160(address(this))))
            );
            _checkBehavesLikeProxy(instance);
        } else if (_randomChance(2)) {
            uint256 x = _random();
            this.bootstrapERC1967AndCall(
                instance, address(this), abi.encodeWithSignature("setValue(uint256)", x)
            );
            assertEq(LibCloneTest(instance).value(), x);
            assertEq(
                vm.load(instance, _ERC1967_IMPLEMENTATION_SLOT),
                bytes32(uint256(uint160(address(this))))
            );
            _checkBehavesLikeProxy(instance);
        } else {
            vm.expectRevert(abi.encodeWithSelector(CustomError.selector, uint256(0)));
            this.bootstrapERC1967AndCall(
                instance, address(this), abi.encodeWithSignature("revertWithError()")
            );
            assertEq(
                vm.load(instance, _ERC1967_IMPLEMENTATION_SLOT),
                bytes32(uint256(uint160(bootstrap)))
            );
        }
    }

    function bootstrapERC1967AndCall(address instance, address implementation, bytes memory data)
        public
    {
        LibClone.bootstrapERC1967AndCall(instance, implementation, data);
    }

    function _beacon() internal returns (address result) {
        if (_deployedBeacon != address(0)) return _deployedBeacon;
        if (_randomChance(2)) {
            result = UpgradeableBeaconTestLib.deployYulBeacon(address(this), address(this));
        } else {
            result = UpgradeableBeaconTestLib.deploySolidityBeacon(address(this), address(this));
        }
        _deployedBeacon = result;
    }

    function testERC1967BeaconProxyGasBehavior(uint256 gasBudget, uint256 value_) public {
        address instance = this.deployERC1967BeaconProxy(_beacon());
        LibCloneTest(instance).setValue(value_);
        gasBudget = _randomChance(2) ? gasBudget % 3000 : gasBudget % 30000;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, value_)
            let hash := keccak256(0x00, 0x40)
            mstore(0x20, hash)
            mstore(0x00, 0x3fa4f245) // `value()`.
            switch staticcall(gasBudget, instance, 0x1c, 0x04, 0x20, 0x20)
            case 0 { if iszero(eq(mload(0x20), hash)) { invalid() } }
            default { if iszero(eq(mload(0x20), value_)) { invalid() } }

            mstore(0x20, hash)
            mstore(0x00, 0x57eca1a5) // `revertWithError()`.
            switch staticcall(gasBudget, instance, 0x1c, 0x04, 0x20, 0x20)
            case 0 {
                if iszero(or(iszero(returndatasize()), eq(returndatasize(), 0x24))) { invalid() }
            }
            default { invalid() }
        }
    }

    function testERC1967IBeaconProxyGasBehavior(uint256 gasBudget, uint256 value_) public {
        address instance = this.deployERC1967IBeaconProxy(_beacon());
        LibCloneTest(instance).setValue(value_);
        gasBudget = _randomChance(2) ? gasBudget % 3000 : gasBudget % 30000;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, value_)
            let hash := keccak256(0x00, 0x40)
            mstore(0x20, hash)
            mstore(0x00, 0x3fa4f245) // `value()`.
            switch staticcall(gasBudget, instance, 0x1c, 0x04, 0x20, 0x20)
            case 0 { if iszero(eq(mload(0x20), hash)) { invalid() } }
            default { if iszero(eq(mload(0x20), value_)) { invalid() } }

            mstore(0x20, hash)
            mstore(0x00, 0x57eca1a5) // `revertWithError()`.
            switch staticcall(gasBudget, instance, 0x1c, 0x04, 0x20, 0x20)
            case 0 {
                if iszero(or(iszero(returndatasize()), eq(returndatasize(), 0x24))) { invalid() }
            }
            default { invalid() }
        }
    }

    function _randomBytesForERC1967BeconProxyImmutableArgs()
        internal
        returns (bytes memory result)
    {
        return _truncateBytes(_randomBytes(), _ERC1967_BEACON_PROXY_ARGS_MAX_LENGTH);
    }

    function _randomBytesForERC1967IBeconProxyImmutableArgs()
        internal
        returns (bytes memory result)
    {
        return _truncateBytes(_randomBytes(), _ERC1967I_BEACON_PROXY_ARGS_MAX_LENGTH);
    }

    function _randomBytesForERC1967ImmutableArgs() internal returns (bytes memory result) {
        return _truncateBytes(_randomBytes(), _ERC1967_ARGS_MAX_LENGTH);
    }

    function _randomBytesForERC1967IImmutableArgs() internal returns (bytes memory result) {
        return _truncateBytes(_randomBytes(), _ERC1967I_ARGS_MAX_LENGTH);
    }

    function _randomBytesForCloneImmutableArgs() internal returns (bytes memory result) {
        return _truncateBytes(_randomBytes(), _CLONES_ARGS_MAX_LENGTH);
    }

    function _checkArgsOnERC1967BeaconProxy(address instance, bytes memory args) internal {
        _maybeBrutalizeMemory();
        bytes memory retrievedArgs = LibClone.argsOnERC1967BeaconProxy(instance);
        _checkMemory(retrievedArgs);
        assertEq(retrievedArgs, args);
        (uint256 start, uint256 end) = _randomStartAndEnd(args);
        _maybeBrutalizeMemory();
        retrievedArgs = LibClone.argsOnERC1967BeaconProxy(instance, start, end);
        _checkMemory(retrievedArgs);
        assertEq(retrievedArgs, bytes(LibString.slice(string(args), start, end)));
        retrievedArgs = LibClone.argsOnERC1967BeaconProxy(instance, start);
        _maybeBrutalizeMemory();
        _checkMemory(retrievedArgs);
        assertEq(retrievedArgs, bytes(LibString.slice(string(args), start)));
    }

    function _checkArgsOnERC1967IBeaconProxy(address instance, bytes memory args) internal {
        _maybeBrutalizeMemory();
        bytes memory retrievedArgs = LibClone.argsOnERC1967IBeaconProxy(instance);
        _checkMemory(retrievedArgs);
        assertEq(retrievedArgs, args);
        (uint256 start, uint256 end) = _randomStartAndEnd(args);
        _maybeBrutalizeMemory();
        retrievedArgs = LibClone.argsOnERC1967IBeaconProxy(instance, start, end);
        _checkMemory(retrievedArgs);
        assertEq(retrievedArgs, bytes(LibString.slice(string(args), start, end)));
        retrievedArgs = LibClone.argsOnERC1967IBeaconProxy(instance, start);
        _maybeBrutalizeMemory();
        _checkMemory(retrievedArgs);
        assertEq(retrievedArgs, bytes(LibString.slice(string(args), start)));
    }

    function _checkArgsOnERC1967(address instance, bytes memory args) internal {
        _maybeBrutalizeMemory();
        bytes memory retrievedArgs = LibClone.argsOnERC1967(instance);
        _checkMemory(retrievedArgs);
        assertEq(retrievedArgs, args);
        assertEq(
            instance.code,
            abi.encodePacked(
                hex"363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f3",
                args
            )
        );
        (uint256 start, uint256 end) = _randomStartAndEnd(args);
        _maybeBrutalizeMemory();
        retrievedArgs = LibClone.argsOnERC1967(instance, start, end);
        _checkMemory(retrievedArgs);
        assertEq(retrievedArgs, bytes(LibString.slice(string(args), start, end)));
        retrievedArgs = LibClone.argsOnERC1967(instance, start);
        _maybeBrutalizeMemory();
        _checkMemory(retrievedArgs);
        assertEq(retrievedArgs, bytes(LibString.slice(string(args), start)));
    }

    function _checkArgsOnERC1967I(address instance, bytes memory args) internal {
        _maybeBrutalizeMemory();
        bytes memory retrievedArgs = LibClone.argsOnERC1967I(instance);
        _checkMemory(retrievedArgs);
        assertEq(retrievedArgs, args);
        assertEq(
            instance.code,
            abi.encodePacked(
                hex"365814604357363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af43d6000803e603e573d6000fd5b3d6000f35b6020600f3d393d51543d52593df3",
                args
            )
        );
        (uint256 start, uint256 end) = _randomStartAndEnd(args);
        _maybeBrutalizeMemory();
        retrievedArgs = LibClone.argsOnERC1967I(instance, start, end);
        _checkMemory(retrievedArgs);
        assertEq(retrievedArgs, bytes(LibString.slice(string(args), start, end)));
        retrievedArgs = LibClone.argsOnERC1967I(instance, start);
        _maybeBrutalizeMemory();
        _checkMemory(retrievedArgs);
        assertEq(retrievedArgs, bytes(LibString.slice(string(args), start)));
    }

    function _checkArgsOnClone(address instance, bytes memory args) internal {
        _maybeBrutalizeMemory();
        bytes memory retrievedArgs = LibClone.argsOnClone(instance);
        _checkMemory(retrievedArgs);
        assertEq(retrievedArgs, args);
        assertEq(
            instance.code,
            abi.encodePacked(
                hex"363d3d373d3d3d363d73", address(this), hex"5af43d82803e903d91602b57fd5bf3", args
            )
        );
        (uint256 start, uint256 end) = _randomStartAndEnd(args);
        retrievedArgs = LibClone.argsOnClone(instance, start, end);
        _maybeBrutalizeMemory();
        _checkMemory(retrievedArgs);
        assertEq(retrievedArgs, bytes(LibString.slice(string(args), start, end)));
        retrievedArgs = LibClone.argsOnClone(instance, start);
        _maybeBrutalizeMemory();
        _checkMemory(retrievedArgs);
        assertEq(retrievedArgs, bytes(LibString.slice(string(args), start)));
    }

    function _randomStartAndEnd(bytes memory args) internal returns (uint256 start, uint256 end) {
        unchecked {
            if (_randomChance(2)) {
                uint256 n = args.length + 2;
                start = _bound(_random(), 0, n);
                end = _bound(_random(), 0, n);
            } else {
                start = _random();
                end = _random();
            }
        }
    }

    function _checkERC1967ImplementationSlot(address instance) internal {
        _checkERC1967ImplementationSlot(instance, address(this));
    }

    function _checkERC1967ImplementationSlot(address instance, address expected) internal {
        assertEq(
            vm.load(instance, _ERC1967_IMPLEMENTATION_SLOT), bytes32(uint256(uint160(expected)))
        );
    }

    function _checkERC1967BeaconSlot(address instance, address expected) internal {
        assertEq(vm.load(instance, _ERC1967_BEACON_SLOT), bytes32(uint256(uint160(expected))));
    }

    function _checkERC1967ISpecialPath(address instance, address expected) internal {
        (, bytes memory returnData) = instance.call("c");
        assertEq(abi.decode(returnData, (address)), expected);
    }

    function clone(address implementation)
        external
        maybeBrutalizeMemory
        returns (address instance)
    {
        instance = LibClone.clone(_brutalized(implementation));
    }

    function clone(address implementation, bytes memory args)
        external
        maybeBrutalizeMemory
        returns (address instance)
    {
        instance = LibClone.clone(_brutalized(implementation), args);
    }

    function cloneDeterministic(address implementation, bytes32 salt)
        external
        maybeBrutalizeMemory
        returns (address instance)
    {
        instance = LibClone.cloneDeterministic(_brutalized(implementation), salt);
        address predicted =
            LibClone.predictDeterministicAddress(implementation, salt, address(this));
        assertEq(instance, predicted);
    }

    function cloneDeterministic(address implementation, bytes memory args, bytes32 salt)
        external
        maybeBrutalizeMemory
        returns (address instance)
    {
        instance = LibClone.cloneDeterministic(_brutalized(implementation), args, salt);
        address predicted =
            LibClone.predictDeterministicAddress(implementation, args, salt, address(this));
        assertEq(instance, predicted);
    }

    function createDeterministicClone(address implementation, bytes memory args, bytes32 salt)
        external
        maybeBrutalizeMemory
        returns (address instance)
    {
        address predicted =
            LibClone.predictDeterministicAddress(implementation, args, salt, address(this));
        bool alreadyDeployed = predicted.code.length != 0;
        bool deployed;
        (deployed, instance) =
            LibClone.createDeterministicClone(_brutalized(implementation), args, salt);
        assertEq(alreadyDeployed, deployed);
        assertEq(instance, predicted);
    }

    function createDeterministicERC1967(address implementation, bytes32 salt)
        external
        maybeBrutalizeMemory
        returns (address instance)
    {
        address predicted =
            LibClone.predictDeterministicAddressERC1967(implementation, salt, address(this));
        bool alreadyDeployed = predicted.code.length != 0;
        bool deployed;
        (deployed, instance) =
            LibClone.createDeterministicERC1967(_brutalized(implementation), salt);
        assertEq(alreadyDeployed, deployed);
        assertEq(instance, predicted);
    }

    function createDeterministicERC1967(address implementation, bytes memory args, bytes32 salt)
        external
        maybeBrutalizeMemory
        returns (address instance)
    {
        address predicted =
            LibClone.predictDeterministicAddressERC1967(implementation, args, salt, address(this));
        bool alreadyDeployed = predicted.code.length != 0;
        bool deployed;
        (deployed, instance) =
            LibClone.createDeterministicERC1967(_brutalized(implementation), args, salt);
        assertEq(alreadyDeployed, deployed);
        assertEq(instance, predicted);
    }

    function createDeterministicERC1967I(address implementation, bytes32 salt)
        external
        maybeBrutalizeMemory
        returns (address instance)
    {
        address predicted =
            LibClone.predictDeterministicAddressERC1967I(implementation, salt, address(this));
        bool alreadyDeployed = predicted.code.length != 0;
        bool deployed;
        (deployed, instance) =
            LibClone.createDeterministicERC1967I(_brutalized(implementation), salt);
        assertEq(alreadyDeployed, deployed);
        assertEq(instance, predicted);
    }

    function createDeterministicERC1967I(address implementation, bytes memory args, bytes32 salt)
        external
        maybeBrutalizeMemory
        returns (address instance)
    {
        address predicted =
            LibClone.predictDeterministicAddressERC1967I(implementation, args, salt, address(this));
        bool alreadyDeployed = predicted.code.length != 0;
        bool deployed;
        (deployed, instance) =
            LibClone.createDeterministicERC1967I(_brutalized(implementation), args, salt);
        assertEq(alreadyDeployed, deployed);
        assertEq(instance, predicted);
    }

    function deployERC1967(address implementation, bytes calldata args)
        external
        maybeBrutalizeMemory
        returns (address instance)
    {
        instance = LibClone.deployERC1967(_brutalized(implementation), args);
    }

    function deployDeterministicERC1967(address implementation, bytes32 salt)
        external
        maybeBrutalizeMemory
        returns (address instance)
    {
        instance = LibClone.deployDeterministicERC1967(_brutalized(implementation), salt);
        address predicted =
            LibClone.predictDeterministicAddressERC1967(implementation, salt, address(this));
        assertEq(instance, predicted);
    }

    function deployERC1967I(address implementation)
        external
        maybeBrutalizeMemory
        returns (address instance)
    {
        instance = LibClone.deployERC1967I(_brutalized(implementation));
    }

    function deployERC1967I(address implementation, bytes memory args)
        external
        maybeBrutalizeMemory
        returns (address instance)
    {
        instance = LibClone.deployERC1967I(_brutalized(implementation), args);
    }

    function deployDeterministicERC1967I(address implementation, bytes32 salt)
        external
        maybeBrutalizeMemory
        returns (address instance)
    {
        instance = LibClone.deployDeterministicERC1967I(_brutalized(implementation), salt);
        address predicted =
            LibClone.predictDeterministicAddressERC1967I(implementation, salt, address(this));
        assertEq(instance, predicted);
    }

    function deployDeterministicERC1967I(address implementation, bytes memory args, bytes32 salt)
        external
        maybeBrutalizeMemory
        returns (address instance)
    {
        instance = LibClone.deployDeterministicERC1967I(_brutalized(implementation), args, salt);
        address predicted =
            LibClone.predictDeterministicAddressERC1967I(implementation, args, salt, address(this));
        assertEq(instance, predicted);
    }

    function deployDeterministicERC1967(address implementation, bytes memory args, bytes32 salt)
        external
        maybeBrutalizeMemory
        returns (address instance)
    {
        instance = LibClone.deployDeterministicERC1967(_brutalized(implementation), args, salt);
        address predicted =
            LibClone.predictDeterministicAddressERC1967(implementation, args, salt, address(this));
        assertEq(instance, predicted);
    }

    function deployERC1967BeaconProxy(address beacon)
        external
        maybeBrutalizeMemory
        returns (address instance)
    {
        instance = LibClone.deployERC1967BeaconProxy(_brutalized(beacon));
    }

    function deployERC1967IBeaconProxy(address beacon)
        external
        maybeBrutalizeMemory
        returns (address instance)
    {
        instance = LibClone.deployERC1967IBeaconProxy(_brutalized(beacon));
    }

    function deployDeterministicERC1967BeaconProxy(address beacon, bytes32 salt)
        external
        maybeBrutalizeMemory
        returns (address instance)
    {
        instance = LibClone.deployDeterministicERC1967BeaconProxy(_brutalized(beacon), salt);
        address predicted =
            LibClone.predictDeterministicAddressERC1967BeaconProxy(beacon, salt, address(this));
        assertEq(instance, predicted);
    }

    function deployDeterministicERC1967IBeaconProxy(address beacon, bytes32 salt)
        external
        maybeBrutalizeMemory
        returns (address instance)
    {
        instance = LibClone.deployDeterministicERC1967IBeaconProxy(_brutalized(beacon), salt);
        address predicted =
            LibClone.predictDeterministicAddressERC1967IBeaconProxy(beacon, salt, address(this));
        assertEq(instance, predicted);
    }

    function deployDeterministicERC1967IBeaconProxy(address beacon, bytes memory args, bytes32 salt)
        external
        maybeBrutalizeMemory
        returns (address instance)
    {
        instance = LibClone.deployDeterministicERC1967IBeaconProxy(_brutalized(beacon), args, salt);
        address predicted = LibClone.predictDeterministicAddressERC1967IBeaconProxy(
            beacon, args, salt, address(this)
        );
        assertEq(instance, predicted);
    }

    function createDeterministicERC1967BeaconProxy(address beacon, bytes32 salt)
        external
        maybeBrutalizeMemory
        returns (address instance)
    {
        address predicted =
            LibClone.predictDeterministicAddressERC1967BeaconProxy(beacon, salt, address(this));
        bool alreadyDeployed = predicted.code.length != 0;
        bool deployed;
        (deployed, instance) =
            LibClone.createDeterministicERC1967BeaconProxy(_brutalized(beacon), salt);
        assertEq(deployed, alreadyDeployed);
        assertEq(instance, predicted);
    }

    function createDeterministicERC1967IBeaconProxy(address beacon, bytes32 salt)
        external
        maybeBrutalizeMemory
        returns (address instance)
    {
        address predicted =
            LibClone.predictDeterministicAddressERC1967IBeaconProxy(beacon, salt, address(this));
        bool alreadyDeployed = predicted.code.length != 0;
        bool deployed;
        (deployed, instance) =
            LibClone.createDeterministicERC1967IBeaconProxy(_brutalized(beacon), salt);
        assertEq(deployed, alreadyDeployed);
        assertEq(instance, predicted);
    }

    function deployERC1967BeaconProxy(address beacon, bytes memory args)
        external
        maybeBrutalizeMemory
        returns (address instance)
    {
        instance = LibClone.deployERC1967BeaconProxy(_brutalized(beacon), args);
    }

    function deployERC1967IBeaconProxy(address beacon, bytes memory args)
        external
        maybeBrutalizeMemory
        returns (address instance)
    {
        instance = LibClone.deployERC1967IBeaconProxy(_brutalized(beacon), args);
    }

    function deployDeterministicERC1967BeaconProxy(address beacon, bytes memory args, bytes32 salt)
        external
        maybeBrutalizeMemory
        returns (address instance)
    {
        instance = LibClone.deployDeterministicERC1967BeaconProxy(_brutalized(beacon), args, salt);
        address predicted = LibClone.predictDeterministicAddressERC1967BeaconProxy(
            beacon, args, salt, address(this)
        );
        assertEq(instance, predicted);
    }

    function createDeterministicERC1967BeaconProxy(address beacon, bytes memory args, bytes32 salt)
        external
        maybeBrutalizeMemory
        returns (address instance)
    {
        address predicted = LibClone.predictDeterministicAddressERC1967BeaconProxy(
            beacon, args, salt, address(this)
        );
        bool alreadyDeployed = predicted.code.length != 0;
        bool deployed;
        (deployed, instance) =
            LibClone.createDeterministicERC1967BeaconProxy(_brutalized(beacon), args, salt);
        assertEq(deployed, alreadyDeployed);
        assertEq(instance, predicted);
    }

    function createDeterministicERC1967IBeaconProxy(address beacon, bytes memory args, bytes32 salt)
        external
        maybeBrutalizeMemory
        returns (address instance)
    {
        address predicted = LibClone.predictDeterministicAddressERC1967IBeaconProxy(
            beacon, args, salt, address(this)
        );
        bool alreadyDeployed = predicted.code.length != 0;
        bool deployed;
        (deployed, instance) =
            LibClone.createDeterministicERC1967IBeaconProxy(_brutalized(beacon), args, salt);
        assertEq(deployed, alreadyDeployed);
        assertEq(instance, predicted);
    }

    modifier maybeBrutalizeMemory() {
        _maybeBrutalizeMemory();
        _;
        _checkMemory();
    }

    function _maybeBrutalizeMemory() internal {
        if (_randomChance(2)) _misalignFreeMemoryPointer();
        if (_randomChance(16)) _brutalizeMemory();
    }
}
