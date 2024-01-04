// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {MockInitializable, Initializable} from "./utils/mocks/MockInitializable.sol";

contract InitializableTest is SoladyTest {
    event Initialized(uint64 version);

    MockInitializable m;

    function setUp() public {
        MockInitializable.Args memory a;
        m = new MockInitializable(a);
    }

    function _args() internal returns (MockInitializable.Args memory a) {
        a.x = _random();
        a.version = uint64(_bound(_random(), 1, type(uint64).max));
        a.checkOnlyDuringInitializing = _random() & 1 == 0;
        a.recurse = _random() & 1 == 0;
    }

    function _expectEmitInitialized(uint64 version) internal {
        vm.expectEmit(true, true, true, true);
        emit Initialized(version);
    }

    function testInitialize() public {
        MockInitializable.Args memory a;
        a.x = 123;
        m.initialize(a);
        assertEq(m.x(), a.x);
        _checkVersion(1);
    }

    function _checkVersion(uint64 version) internal {
        assertEq(m.version(), version);
        assertFalse(m.isInitializing());
    }

    function testInitializeReinititalize(uint256) public {
        MockInitializable.Args memory a = _args();

        if (a.recurse) {
            vm.expectRevert(Initializable.InvalidInitialization.selector);
            if (_random() & 1 == 0) {
                m.initialize(a);
            } else {
                m.reinitialize(a);
            }
            return;
        }

        if (_random() & 1 == 0) {
            _expectEmitInitialized(1);
            m.initialize(a);
            a.version = 1;
        } else {
            _expectEmitInitialized(a.version);
            m.reinitialize(a);
        }
        assertEq(m.x(), a.x);
        _checkVersion(a.version);

        if (_random() & 1 == 0) {
            vm.expectRevert(Initializable.InvalidInitialization.selector);
            m.initialize(a);
        }
        if (_random() & 1 == 0) {
            vm.expectRevert(Initializable.InvalidInitialization.selector);
            m.reinitialize(a);
        }
        if (_random() & 1 == 0) {
            a.version = m.version();
            uint64 newVersion = uint64(_random());
            if (newVersion > a.version) {
                a.version = newVersion;
                m.reinitialize(a);
                _checkVersion(a.version);
            }
        }
    }

    function testOnlyInitializing() public {
        vm.expectRevert(Initializable.NotInitializing.selector);
        m.onlyDuringInitializing();
    }

    function testDisableInitializers() public {
        _expectEmitInitialized(type(uint64).max);
        m.disableInitializers();
        _checkVersion(type(uint64).max);
        m.disableInitializers();
        _checkVersion(type(uint64).max);

        MockInitializable.Args memory a;
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        m.initialize(a);
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        m.reinitialize(a);
    }

    function testInitializableConstructor() public {
        MockInitializable.Args memory a;
        a.initializeMulti = true;
        m = new MockInitializable(a);
        _checkVersion(1);

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        m.initialize(a);
        a.version = 2;
        m.reinitialize(a);
        _checkVersion(2);

        a.disableInitializers = true;
        _expectEmitInitialized(type(uint64).max);
        m = new MockInitializable(a);
        _checkVersion(type(uint64).max);
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        m.initialize(a);
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        m.reinitialize(a);
    }

    function testInitializeInititalizerTrick(
        bool initializing,
        uint64 initializedVersion,
        uint16 codeSize
    ) public {
        bool isTopLevelCall = !initializing;
        bool initialSetup = initializedVersion == 0 && isTopLevelCall;
        bool construction = initializedVersion == 1 && codeSize == 0;
        bool expected = !initialSetup && !construction;
        bool computed;
        uint256 i;
        /// @solidity memory-safe-assembly
        assembly {
            i := or(initializing, shl(1, initializedVersion))
            if i { if iszero(lt(codeSize, eq(shr(1, i), 1))) { computed := 1 } }
        }
        assertEq(computed, expected);
    }

    function testInitializeReinititalizerTrick(
        bool initializing,
        uint64 initializedVersion,
        uint64 version
    ) public {
        bool expected = initializing == true || initializedVersion >= version;
        bool computed;
        /// @solidity memory-safe-assembly
        assembly {
            let i := or(initializing, shl(1, initializedVersion))
            computed := iszero(lt(and(i, 1), lt(shr(1, i), version)))
        }
        assertEq(computed, expected);
    }
}
