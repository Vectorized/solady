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
        this.testInitialize(123);
    }

    function testInitialize(uint256) public {
        MockInitializable.Args memory a = _args();
        if (a.recurse) {
            vm.expectRevert(Initializable.InvalidInitialization.selector);
            m.reinitialize(a);
            return;
        }
        _expectEmitInitialized(1);
        m.initialize(a);
        assertEq(m.x(), a.x);
        assertEq(m.version(), 1);

        a.version = 1;
        _testInitializeReinitialize(a);
    }

    function testReinitialize(uint256) public {
        MockInitializable.Args memory a = _args();
        if (a.recurse) {
            vm.expectRevert(Initializable.InvalidInitialization.selector);
            m.reinitialize(a);
            return;
        }
        _expectEmitInitialized(a.version);
        m.reinitialize(a);
        assertEq(m.x(), a.x);
        assertEq(m.version(), a.version);

        _testInitializeReinitialize(a);
    }

    function _testInitializeReinitialize(MockInitializable.Args memory a) internal {
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
                assertEq(m.version(), a.version);
            }
        }
    }

    function testOnlyInitializing() public {
        testInitialize(123);
        vm.expectRevert(Initializable.NotInitializing.selector);
        m.onlyDuringInitializing();
    }

    function testDisableInitializers() public {
        _expectEmitInitialized(type(uint64).max);
        m.disableInitializers();
        assertEq(m.version(), type(uint64).max);
        m.disableInitializers();
        assertEq(m.version(), type(uint64).max);

        MockInitializable.Args memory a;
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        m.initialize(a);
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        m.reinitialize(a);
    }

    function testInitializeMultiInConstructor() public {
        MockInitializable.Args memory a;
        a.initializeMulti = true;
        m = new MockInitializable(a);
        assertEq(m.version(), 1);

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        m.initialize(a);
        a.version = 2;
        m.reinitialize(a);

        a.disableInitializers = true;
        _expectEmitInitialized(type(uint64).max);
        m = new MockInitializable(a);
        assertEq(m.version(), type(uint64).max);
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
