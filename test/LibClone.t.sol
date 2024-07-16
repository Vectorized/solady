// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {LibClone} from "../src/utils/LibClone.sol";
import {SafeTransferLib} from "../src/utils/SafeTransferLib.sol";
import {UpgradeableBeaconTestLib} from "./UpgradeableBeacon.t.sol";

contract LibCloneTest is SoladyTest {
    error CustomError(uint256 currentValue);

    uint256 public value;

    mapping(bytes32 => bool) saltIsUsed;

    bytes32 internal constant _ERC1967_IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    bytes32 internal constant _ERC1967_BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    uint256 internal constant _CLONES_ARGS_MAX_LENGTH = 0xffd2;

    uint256 internal constant _ERC1967_ARGS_MAX_LENGTH = 0xffc2;

    function setValue(uint256 value_) public {
        value = value_;
    }

    function revertWithError() public view {
        revert CustomError(value);
    }

    function _shouldBehaveLikeClone(address instance) internal {
        _shouldBehaveLikeClone(instance, _random());
    }

    function _shouldBehaveLikeClone(address instance, uint256 value_) internal {
        assertTrue(instance != address(0));

        uint256 thisValue = this.value();
        if (thisValue == value_) {
            value_ ^= 1;
        }
        LibCloneTest(instance).setValue(value_);
        assertEq(value_, LibCloneTest(instance).value());
        assertEq(thisValue, this.value());
        vm.expectRevert(abi.encodeWithSelector(CustomError.selector, value_));
        LibCloneTest(instance).revertWithError();
    }

    function testDeployERC1967(uint256) public {
        address instance = LibClone.deployERC1967(address(this));
        _shouldBehaveLikeClone(instance);
        _checkArgsOnERC1967(instance, "");
        assertEq(
            vm.load(instance, _ERC1967_IMPLEMENTATION_SLOT),
            bytes32(uint256(uint160(address(this))))
        );
    }

    function testDeployERC1967WithImmutableArgs(uint256) public {
        bytes memory args = _randomBytes();
        if (args.length > _ERC1967_ARGS_MAX_LENGTH) {
            vm.expectRevert(LibClone.DeploymentFailed.selector);
            this.deployERC1967(address(this), args);
            return;
        }
        address instance = LibClone.deployERC1967(address(this), args);
        assertEq(instance.code.length, 61 + args.length);

        _checkArgsOnERC1967(instance, args);
        _shouldBehaveLikeClone(instance);
        assertEq(
            vm.load(instance, _ERC1967_IMPLEMENTATION_SLOT),
            bytes32(uint256(uint160(address(this))))
        );
    }

    function testDeployERC1967I(uint256) public {
        address instance = LibClone.deployERC1967I(address(this));
        _shouldBehaveLikeClone(instance);
        assertEq(
            vm.load(instance, _ERC1967_IMPLEMENTATION_SLOT),
            bytes32(uint256(uint160(address(this))))
        );
    }

    function testDeployERC1967BeaconProxy(uint256) public {
        address beacon = _deployBeacon();
        address instance = LibClone.deployERC1967BeaconProxy(beacon);
        _shouldBehaveLikeClone(instance);
        assertEq(
            vm.load(instance, _ERC1967_BEACON_SLOT), bytes32(uint256(uint160(address(beacon))))
        );
    }

    function testDeployERC1967() public {
        testDeployERC1967(1);
    }

    function testDeployERC1967WithImmutableArgs() public {
        testDeployERC1967WithImmutableArgs(1);
    }

    function testDeployERC1967I() public {
        testDeployERC1967I(1);
    }

    function testDeployERC1967ISpecialPath(address impl, bytes1 data) public {
        address instance = LibClone.deployERC1967I(impl);
        (, bytes memory rd) = instance.call(abi.encodePacked(data));
        assertEq(impl, abi.decode(rd, (address)));
    }

    function testDeployERC1967ISpecialPath() public {
        address instance = LibClone.deployERC1967I(address(this));
        (, bytes memory rd) = instance.call("I");
        assertEq(address(this), abi.decode(rd, (address)));
    }

    function testDeployERC1967CodeHashAndLength(address impl) public {
        assertEq(keccak256(LibClone.deployERC1967(impl).code), LibClone.ERC1967_CODE_HASH);
        assertEq(LibClone.deployERC1967(impl).code.length, 61);
    }

    function testDeployERC1967ICodeHashAndLength(address impl) public {
        assertEq(keccak256(LibClone.deployERC1967I(impl).code), LibClone.ERC1967I_CODE_HASH);
        assertEq(LibClone.deployERC1967I(impl).code.length, 82);
    }

    function testDeployERC1967BeaconProxyCodeHashAndLength(address impl) public {
        assertEq(
            keccak256(LibClone.deployERC1967BeaconProxy(impl).code),
            LibClone.ERC1967_BEACON_PROXY_CODE_HASH
        );
        assertEq(LibClone.deployERC1967BeaconProxy(impl).code.length, 82);
    }

    function testClone(uint256) public {
        _shouldBehaveLikeClone(LibClone.clone(address(this)));
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
        address instance = LibClone.clone(address(this), args);
        _checkArgsOnClone(instance, args);
        _shouldBehaveLikeClone(instance);
    }

    function testCloneDeterministic(uint256, bytes32 salt) public {
        if (saltIsUsed[salt]) {
            vm.expectRevert(LibClone.DeploymentFailed.selector);
            this.cloneDeterministic(address(this), salt);
            return;
        }

        address instance = this.cloneDeterministic(address(this), salt);
        saltIsUsed[salt] = true;

        _shouldBehaveLikeClone(instance);

        address predicted = LibClone.predictDeterministicAddress(address(this), salt, address(this));
        assertEq(instance, predicted);

        if (_random() & 31 == 0) {
            testCloneDeterministic(1, salt);
        }
    }

    function testCloneDeterministicWithImmutableArgs() public {
        _testCloneDeterministicWithImmutableArgs(1, "", bytes32(0));
    }

    function testCloneDeterministicWithImmutableArgs(uint256 value_, bytes32 salt) public {
        _testCloneDeterministicWithImmutableArgs(value_, _randomBytes(), salt);
    }

    function _testCloneDeterministicWithImmutableArgs(
        uint256 value_,
        bytes memory args,
        bytes32 salt
    ) public {
        if (args.length > _CLONES_ARGS_MAX_LENGTH) {
            vm.expectRevert(LibClone.DeploymentFailed.selector);
            this.cloneDeterministic{gas: gasleft() >> 2}(address(this), args, salt);
            return;
        }

        bytes32 saltedSalt = keccak256(abi.encode(args, salt));
        if (saltIsUsed[saltedSalt]) {
            vm.expectRevert(LibClone.DeploymentFailed.selector);
            this.cloneDeterministic{gas: gasleft() >> 2}(address(this), args, salt);
            return;
        }

        address instance = this.cloneDeterministic(address(this), args, salt);
        saltIsUsed[saltedSalt] = true;

        _shouldBehaveLikeClone(instance);
        _checkArgsOnClone(instance, args);

        address predicted =
            LibClone.predictDeterministicAddress(address(this), args, salt, address(this));
        assertEq(instance, predicted);

        if (_random() & 31 == 0) {
            _testCloneDeterministicWithImmutableArgs(value_, args, salt);
        }
    }

    function clone(address implementation, bytes calldata args) external returns (address) {
        return LibClone.clone(_brutalized(implementation), args);
    }

    function cloneDeterministic(address implementation, bytes32 salt) external returns (address) {
        return LibClone.cloneDeterministic(_brutalized(implementation), salt);
    }

    function cloneDeterministic(address implementation, bytes calldata args, bytes32 salt)
        external
        returns (address)
    {
        return LibClone.cloneDeterministic(_brutalized(implementation), args, salt);
    }

    function testCloneDeterministic() public {
        testCloneDeterministic(1, keccak256("b"));
    }

    function testDeployDeterministicERC1967(uint256, bytes32 salt) public {
        if (saltIsUsed[salt]) {
            vm.expectRevert(LibClone.DeploymentFailed.selector);
            this.deployDeterministicERC1967(address(this), salt);
            return;
        }

        address instance = this.deployDeterministicERC1967(address(this), salt);
        _shouldBehaveLikeClone(instance);
        _checkArgsOnERC1967(instance, "");
        saltIsUsed[salt] = true;

        address predicted =
            LibClone.predictDeterministicAddressERC1967(address(this), salt, address(this));
        assertEq(instance, predicted);

        assertEq(
            vm.load(instance, _ERC1967_IMPLEMENTATION_SLOT),
            bytes32(uint256(uint160(address(this))))
        );
        if (_random() & 31 == 0) {
            testDeployDeterministicERC1967(1, salt);
        }
    }

    function testDeployDeterministicERC1967WithImmutableArgs() public {
        _testDeployDeterministicERC1967WithImmutableArgs(1, "", bytes32(0));
    }

    function testDeployDeterministicERC1967WithImmutableArgs(uint256, bytes32 salt) public {
        _testDeployDeterministicERC1967WithImmutableArgs(1, _randomBytes(), salt);
    }

    function _testDeployDeterministicERC1967WithImmutableArgs(
        uint256,
        bytes memory args,
        bytes32 salt
    ) public {
        bytes32 saltedSalt = keccak256(abi.encode(args, salt));
        if (args.length > _ERC1967_ARGS_MAX_LENGTH) {
            vm.expectRevert(LibClone.DeploymentFailed.selector);
            this.deployDeterministicERC1967{gas: gasleft() >> 2}(address(this), args, salt);
            return;
        }
        if (saltIsUsed[saltedSalt]) {
            vm.expectRevert(LibClone.DeploymentFailed.selector);
            this.deployDeterministicERC1967{gas: gasleft() >> 2}(address(this), args, salt);
            return;
        }

        address instance =
            this.deployDeterministicERC1967{gas: gasleft() >> 2}(address(this), args, salt);
        _checkArgsOnERC1967(instance, args);
        _shouldBehaveLikeClone(instance);
        saltIsUsed[saltedSalt] = true;

        address predicted =
            LibClone.predictDeterministicAddressERC1967(address(this), args, salt, address(this));
        assertEq(instance, predicted);

        assertEq(
            vm.load(instance, _ERC1967_IMPLEMENTATION_SLOT),
            bytes32(uint256(uint160(address(this))))
        );

        if (_random() & 31 == 0) {
            _testDeployDeterministicERC1967WithImmutableArgs(1, args, salt);
        }
    }

    function createDeterministicERC1967(address implementation, bytes memory args, bytes32 salt)
        external
        returns (bool, address)
    {
        return LibClone.createDeterministicERC1967(_brutalized(implementation), args, salt);
    }

    function deployERC1967(address implementation, bytes calldata args)
        external
        returns (address)
    {
        return LibClone.deployERC1967(_brutalized(implementation), args);
    }

    function deployDeterministicERC1967(address implementation, bytes32 salt)
        external
        returns (address)
    {
        return LibClone.deployDeterministicERC1967(_brutalized(implementation), salt);
    }

    function deployDeterministicERC1967(address implementation, bytes memory args, bytes32 salt)
        external
        returns (address)
    {
        return LibClone.deployDeterministicERC1967(_brutalized(implementation), args, salt);
    }

    function deployDeterministicERC1967BeaconProxy(address beacon, bytes32 salt)
        external
        returns (address)
    {
        return LibClone.deployDeterministicERC1967BeaconProxy(_brutalized(beacon), salt);
    }

    function testDeployDeterministicERC1967() public {
        testDeployDeterministicERC1967(1, keccak256("b"));
    }

    function testDeployDeterministicERC1967I(uint256, bytes32 salt) public {
        if (saltIsUsed[salt]) {
            vm.expectRevert(LibClone.DeploymentFailed.selector);
            this.deployDeterministicERC1967I(address(this), salt);
            return;
        }

        address instance = this.deployDeterministicERC1967I(address(this), salt);
        saltIsUsed[salt] = true;

        _shouldBehaveLikeClone(instance);

        address predicted =
            LibClone.predictDeterministicAddressERC1967I(address(this), salt, address(this));
        assertEq(instance, predicted);

        assertEq(
            vm.load(instance, _ERC1967_IMPLEMENTATION_SLOT),
            bytes32(uint256(uint160(address(this))))
        );
        if (_random() & 31 == 0) {
            testDeployDeterministicERC1967I(1, salt);
        }
    }

    function deployDeterministicERC1967I(address implementation, bytes32 salt)
        external
        returns (address)
    {
        return LibClone.deployDeterministicERC1967I(_brutalized(implementation), salt);
    }

    function testDeployDeterministicERC1967I() public {
        testDeployDeterministicERC1967I(1, keccak256("b"));
    }

    function testDeployDeterministicERC1967BeaconProxy(uint256, bytes32 salt) public {
        address beacon = _deployBeacon();
        _testDeployDeterministicERC1967BeaconProxy(beacon, salt);
    }

    function _testDeployDeterministicERC1967BeaconProxy(address beacon, bytes32 salt) internal {
        if (saltIsUsed[salt]) {
            vm.expectRevert(LibClone.DeploymentFailed.selector);
            this.deployDeterministicERC1967BeaconProxy(beacon, salt);
            return;
        }

        address instance = this.deployDeterministicERC1967BeaconProxy(beacon, salt);
        saltIsUsed[salt] = true;

        _shouldBehaveLikeClone(instance);

        address predicted = LibClone.predictDeterministicAddressERC1967BeaconProxy(
            address(beacon), salt, address(this)
        );
        assertEq(instance, predicted);

        assertEq(
            vm.load(instance, _ERC1967_BEACON_SLOT), bytes32(uint256(uint160(address(beacon))))
        );
        if (_random() & 31 == 0) {
            _testDeployDeterministicERC1967BeaconProxy(beacon, salt);
        }
    }

    function testCreateDeterministicERC1967(uint256 value_, bytes32 salt) public {
        if (saltIsUsed[salt]) {
            (bool deployed, address instance) =
                LibClone.createDeterministicERC1967(address(this), salt);
            assertEq(deployed, true);
            assertEq(
                instance,
                LibClone.predictDeterministicAddressERC1967(address(this), salt, address(this))
            );
            return;
        }

        (bool deployed_, address instance_) =
            LibClone.createDeterministicERC1967(address(this), salt);
        assertEq(deployed_, false);
        saltIsUsed[salt] = true;

        _shouldBehaveLikeClone(instance_, value_);

        address predicted =
            LibClone.predictDeterministicAddressERC1967(address(this), salt, address(this));
        assertEq(instance_, predicted);

        assertEq(
            vm.load(instance_, _ERC1967_IMPLEMENTATION_SLOT),
            bytes32(uint256(uint160(address(this))))
        );
    }

    function testCreateDeterministicERC1967WithImmutableArgs(uint256 value_, bytes32 salt) public {
        bytes memory args = _randomBytes();
        if (args.length > _ERC1967_ARGS_MAX_LENGTH) {
            vm.expectRevert(LibClone.DeploymentFailed.selector);
            this.createDeterministicERC1967(address(this), args, salt);
            return;
        }
        if (saltIsUsed[salt]) {
            (bool deployed, address instance) =
                LibClone.createDeterministicERC1967(address(this), args, salt);
            assertEq(deployed, true);
            assertEq(
                instance,
                LibClone.predictDeterministicAddressERC1967(
                    address(this), args, salt, address(this)
                )
            );
            return;
        }

        (bool deployed_, address instance_) =
            LibClone.createDeterministicERC1967(address(this), args, salt);
        assertEq(deployed_, false);
        saltIsUsed[salt] = true;

        _shouldBehaveLikeClone(instance_, value_);

        address predicted =
            LibClone.predictDeterministicAddressERC1967(address(this), args, salt, address(this));
        assertEq(instance_, predicted);

        assertEq(
            vm.load(instance_, _ERC1967_IMPLEMENTATION_SLOT),
            bytes32(uint256(uint160(address(this))))
        );
    }

    function testCreateDeterministicERC1967BeaconProxy(uint256 value_, bytes32 salt) public {
        address beacon = _deployBeacon();
        if (saltIsUsed[salt]) {
            (bool deployed, address instance) =
                LibClone.createDeterministicERC1967BeaconProxy(beacon, salt);
            assertEq(deployed, true);
            assertEq(
                instance,
                LibClone.predictDeterministicAddressERC1967BeaconProxy(beacon, salt, address(this))
            );
            return;
        }

        (bool deployed_, address instance_) =
            LibClone.createDeterministicERC1967BeaconProxy(beacon, salt);
        assertEq(deployed_, false);
        saltIsUsed[salt] = true;

        _shouldBehaveLikeClone(instance_, value_);

        address predicted =
            LibClone.predictDeterministicAddressERC1967BeaconProxy(beacon, salt, address(this));
        assertEq(instance_, predicted);

        assertEq(
            vm.load(instance_, _ERC1967_BEACON_SLOT), bytes32(uint256(uint160(address(beacon))))
        );
    }

    function testCreateDeterministicERC1967I(uint256, bytes32 salt) public {
        if (saltIsUsed[salt]) {
            (bool deployed, address instance) =
                LibClone.createDeterministicERC1967I(address(this), salt);
            assertEq(deployed, true);
            assertEq(
                instance,
                LibClone.predictDeterministicAddressERC1967I(address(this), salt, address(this))
            );
            return;
        }

        (bool deployed_, address instance_) =
            LibClone.createDeterministicERC1967I(address(this), salt);
        assertEq(deployed_, false);
        saltIsUsed[salt] = true;

        _shouldBehaveLikeClone(instance_);

        address predicted =
            LibClone.predictDeterministicAddressERC1967I(address(this), salt, address(this));
        assertEq(instance_, predicted);

        assertEq(
            vm.load(instance_, _ERC1967_IMPLEMENTATION_SLOT),
            bytes32(uint256(uint160(address(this))))
        );
        if (_random() & 31 == 0) {
            testCreateDeterministicERC1967I(1, salt);
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
        assertEq(LibClone.deployERC1967BeaconProxy(123, t).balance, 123);
        assertEq(
            LibClone.deployDeterministicERC1967BeaconProxy(123, t, bytes32(gasleft())).balance, 123
        );
    }

    function testInitCode(address implementation, uint256 c) public {
        uint256 m = 1;
        if (c & (m <<= 1) == 0) _testInitCode(implementation);
        if (c & (m <<= 1) == 0) _testInitCodeWithImmutableArgs(implementation);
        if (c & (m <<= 1) == 0) _testInitCode_PUSH0(implementation);
        if (c & (m <<= 1) == 0) _testInitCodeERC1967(implementation);
        if (c & (m <<= 1) == 0) _testInitCodeERC1967WithImmutableArgs(implementation);
        if (c & (m <<= 1) == 0) _testInitCodeERC1967I(implementation);
        if (c & (m <<= 1) == 0) _testInitCodeERC1967BeaconProxy(implementation);
    }

    function _testInitCode(address implementation) internal {
        _brutalizeMemory();
        bytes memory initCode = LibClone.initCode(_brutalized(implementation));
        _checkMemory(initCode);
        _brutalizeMemory();
        bytes32 expected = LibClone.initCodeHash(_brutalized(implementation));
        _checkMemory(initCode);
        assertEq(keccak256(initCode), expected);
    }

    function _testInitCodeWithImmutableArgs(address implementation) internal {
        _brutalizeMemory();
        bytes memory args = _randomBytesForCloneImmutableArgs();
        bytes memory initCode = LibClone.initCode(_brutalized(implementation), args);
        _checkMemory(initCode);
        _brutalizeMemory();
        bytes32 expected = LibClone.initCodeHash(_brutalized(implementation), args);
        _checkMemory(initCode);
        assertEq(keccak256(initCode), expected);
    }

    function _testInitCode_PUSH0(address implementation) internal {
        _brutalizeMemory();
        bytes memory initCode = LibClone.initCode_PUSH0(_brutalized(implementation));
        _checkMemory(initCode);
        _brutalizeMemory();
        bytes32 expected = LibClone.initCodeHash_PUSH0(_brutalized(implementation));
        _checkMemory(initCode);
        assertEq(keccak256(initCode), expected);
    }

    function _testInitCodeERC1967(address implementation) internal {
        _brutalizeMemory();
        bytes memory initCode = LibClone.initCodeERC1967(_brutalized(implementation));
        _checkMemory(initCode);
        _brutalizeMemory();
        bytes32 expected = LibClone.initCodeHashERC1967(_brutalized(implementation));
        _checkMemory(initCode);
        assertEq(keccak256(initCode), expected);
    }

    function _testInitCodeERC1967WithImmutableArgs(address implementation) internal {
        _brutalizeMemory();
        bytes memory args = _randomBytesForERC1967ImmutableArgs();
        bytes memory initCode = LibClone.initCodeERC1967(_brutalized(implementation), args);
        _checkMemory(initCode);
        _brutalizeMemory();
        bytes32 expected = LibClone.initCodeHashERC1967(_brutalized(implementation), args);
        _checkMemory(initCode);
        assertEq(keccak256(initCode), expected);
    }

    function _testInitCodeERC1967I(address implementation) internal {
        _brutalizeMemory();
        bytes memory initCode = LibClone.initCodeERC1967I(_brutalized(implementation));
        _checkMemory(initCode);
        _brutalizeMemory();
        bytes32 expected = LibClone.initCodeHashERC1967I(_brutalized(implementation));
        _checkMemory(initCode);
        assertEq(keccak256(initCode), expected);
    }

    function _testInitCodeERC1967BeaconProxy(address beacon) internal {
        _brutalizeMemory();
        bytes memory initCode = LibClone.initCodeERC1967BeaconProxy(_brutalized(beacon));
        _checkMemory(initCode);
        _brutalizeMemory();
        bytes32 expected = LibClone.initCodeHashERC1967BeaconProxy(_brutalized(beacon));
        _checkMemory(initCode);
        assertEq(keccak256(initCode), expected);
    }

    function testERC1967ConstantBootstrap(address implementation, bytes32 salt) public {
        address bootstrap = LibClone.constantERC1967BootstrapAddress();
        assertEq(LibClone.constantERC1967Bootstrap(), bootstrap);
        if (_random() % 2 == 0) {
            assertEq(LibClone.constantERC1967Bootstrap(), bootstrap);
        }

        address instance;
        if (_random() % 2 == 0) {
            instance = LibClone.predictDeterministicAddressERC1967(bootstrap, salt, address(this));
            assertEq(LibClone.deployDeterministicERC1967(0, bootstrap, salt), instance);
        } else {
            instance = LibClone.predictDeterministicAddressERC1967I(bootstrap, salt, address(this));
            assertEq(LibClone.deployDeterministicERC1967I(0, bootstrap, salt), instance);
        }

        if (_random() % 2 == 0) {
            LibClone.bootstrapERC1967(instance, implementation);
            assertEq(
                vm.load(instance, _ERC1967_IMPLEMENTATION_SLOT),
                bytes32(uint256(uint160(implementation)))
            );
        } else {
            LibClone.bootstrapERC1967(instance, address(this));
            assertEq(
                vm.load(instance, _ERC1967_IMPLEMENTATION_SLOT),
                bytes32(uint256(uint160(address(this))))
            );
            _shouldBehaveLikeClone(instance, 1);
        }
    }

    function _deployBeacon() internal returns (address) {
        if (_random() % 2 == 0) {
            return UpgradeableBeaconTestLib.deployYulBeacon(address(this), address(this));
        }
        return UpgradeableBeaconTestLib.deploySolidityBeacon(address(this), address(this));
    }

    function testERC1967BeaconProxyGasBehavior(uint256 gasBudget, uint256 value_) public {
        address beacon = _deployBeacon();
        address instance = LibClone.deployERC1967BeaconProxy(beacon);
        LibCloneTest(instance).setValue(value_);
        gasBudget = _random() % 2 == 0 ? gasBudget % 3000 : gasBudget % 30000;
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

    function _randomBytes() internal returns (bytes memory result) {
        uint256 r = _random();
        uint256 n = r & 0xffff;
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(0x00, r)
            let t := keccak256(0x00, 0x20)
            if gt(byte(0, r), 16) { n := and(r, 0x7f) }
            codecopy(add(result, 0x20), byte(0, t), codesize())
            codecopy(add(result, n), byte(1, t), codesize())
            mstore(0x40, add(n, add(0x40, result)))
            mstore(result, n)
            if iszero(byte(3, t)) { result := 0x60 }
        }
    }

    function _randomBytesForERC1967ImmutableArgs() internal returns (bytes memory result) {
        return _truncateBytes(_randomBytes(), _ERC1967_ARGS_MAX_LENGTH);
    }

    function _randomBytesForCloneImmutableArgs() internal returns (bytes memory result) {
        return _truncateBytes(_randomBytes(), _CLONES_ARGS_MAX_LENGTH);
    }

    function _truncateBytes(bytes memory b, uint256 n)
        internal
        pure
        returns (bytes memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            if gt(mload(b), n) { mstore(b, n) }
            result := b
        }
    }

    function _checkArgsOnERC1967(address instance, bytes memory args) internal {
        if (_random() & 31 == 0) _brutalizeMemory();
        _misalignFreeMemoryPointer();
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
    }

    function _checkArgsOnClone(address instance, bytes memory args) internal {
        if (_random() & 31 == 0) _brutalizeMemory();
        _misalignFreeMemoryPointer();
        bytes memory retrievedArgs = LibClone.argsOnClone(instance);
        _checkMemory(retrievedArgs);
        assertEq(retrievedArgs, args);
        assertEq(
            instance.code,
            abi.encodePacked(
                hex"363d3d373d3d3d363d73", address(this), hex"5af43d82803e903d91602b57fd5bf3", args
            )
        );
    }
}
