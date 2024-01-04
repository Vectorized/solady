// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {
    MockInitializable,
    MockInitializableRevert,
    MockInitializableDisabled,
    MockInitializableRevert2,
    Initializable
} from "./utils/mocks/MockInitializable.sol";

contract InitializableTest is SoladyTest {
    MockInitializable m1;

    function setUp() public {
        m1 = new MockInitializable();
    }

    function testInit() public {
        testInit(123);
    }

    function testInit(uint256 x) public {
        m1.init(x);
        assertEq(m1.x(), x);
    }

    function testOnlyInitializing() public {
        testInit(123);
        vm.expectRevert(Initializable.NotInitializing.selector);
        m1.onlyDuringInitializing();
    }

    function testInitRevertWithInvalidInitialization(uint256 x) public {
        m1.init(x);
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        m1.init(x);
    }

    function testReinitialize() public {
        m1.init(5);
        assertEq(m1.getVersion(), 1);
        for (uint64 i = 2; i < 258; i++) {
            m1.reinit(i + 5, i);
            assertEq(m1.getVersion(), i);
            assertEq(m1.x(), i + 5);
        }
    }

    function testReinitializeRevertWithInvalidInitialization(uint64 x_, uint64 version) public {
        m1.init(x_);
        m1.reinit(x_, type(uint64).max);

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        m1.reinit(x_, version);
    }

    function testReinitializeRevertWhenContractIsInitializing(uint256 x_, uint64 version) public {
        MockInitializableRevert m2 = new MockInitializableRevert();
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        m2.init1(x_, version);
    }

    function testRevertWhenInitializeIsDisabled(uint256 x_) public {
        MockInitializableDisabled m = new MockInitializableDisabled();
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        m.init(x_);
    }

    function testInitializeIsDisabled() public {
        MockInitializableDisabled m = new MockInitializableDisabled();
        assertEq(m.getVersion(), type(uint64).max);
    }

    function testRevertWhenCalledOnlyInitializingFunctionWithNonInitializer() public {
        MockInitializableRevert2 m = new MockInitializableRevert2();
        vm.expectRevert(Initializable.NotInitializing.selector);
        m.init(5);
    }

    function testInitializeInititalizerTrick(
        bool initializing,
        uint64 initializedVersion,
        uint64 codeSize
    ) public {
        bool isTopLevelCall = !initializing;
        bool initialSetup = initializedVersion == 0 && isTopLevelCall;
        bool construction = initializedVersion == 1 && codeSize == 0;
        bool expected = !initialSetup && !construction;
        bool computed;
        /// @solidity memory-safe-assembly
        assembly {
            let i := or(initializing, shl(1, initializedVersion))
            if i { if iszero(lt(codeSize, eq(shr(1, i), 1))) { computed := 1 } }
        }
        assertEq(computed, expected);
    }

    function testInitializeReinititalizerTrick(
        bool initializing,
        uint64 initializedVersion,
        uint64 version
    ) public {
        bool expected = initializing || initializedVersion >= version;
        bool computed;
        /// @solidity memory-safe-assembly
        assembly {
            let i := or(initializing, shl(1, initializedVersion))
            computed := iszero(lt(and(i, 1), lt(shr(1, i), version)))
        }
        assertEq(computed, expected);
    }
}
