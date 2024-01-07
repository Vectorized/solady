// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {ReentrancyGuard} from "../src/utils/ReentrancyGuard.sol";
import {MockReentrancyGuard, ReentrancyAttack} from "./utils/mocks/MockReentrancyGuard.sol";

contract ReentrancyGuardTest is SoladyTest {
    MockReentrancyGuard immutable target = new MockReentrancyGuard();
    ReentrancyAttack immutable reentrancyAttack = new ReentrancyAttack();

    // Before and after each test, the reentrancy guard should be unlocked.
    modifier expectBeforeAfterReentrancyGuardUnlocked() {
        assertEq(target.isReentrancyGuardLocked(), false);
        _;
        assertEq(target.isReentrancyGuardLocked(), false);
    }

    function testRevertGuardLocked() external expectBeforeAfterReentrancyGuardUnlocked {
        // Attempt to call a `nonReentrant` methiod with an unprotected method.
        // Expect a success.
        target.callUnguardedToGuarded();
        assertEq(target.enterTimes(), 1);

        // Attempt to call a `nonReentrant` method within a `nonReentrant` method.
        // Expect a revert with the `Reentrancy` error.
        vm.expectRevert(ReentrancyGuard.Reentrancy.selector);
        target.callGuardedToGuarded();
    }

    function testRevertReadGuardLocked() external expectBeforeAfterReentrancyGuardUnlocked {
        // Attempt to call a `nonReadReentrant` methiod with an unprotected method.
        // Expect a success.
        target.callUnguardedToReadGuarded();
        assertEq(target.enterTimes(), 1);

        // Attempt to call a `nonReadReentrant` method within a `nonReentrant` method.
        // Expect a revert with the `Reentrancy` error.
        vm.expectRevert(ReentrancyGuard.Reentrancy.selector);
        target.callGuardedToReadGuarded();
    }

    function testRevertRemoteCallback() external expectBeforeAfterReentrancyGuardUnlocked {
        // Attempt to reenter a `nonReentrant` method from a remote contract.
        vm.expectRevert(ReentrancyAttack.ReentrancyAttackFailed.selector);
        target.countAndCall(reentrancyAttack);
    }

    function testRecursiveDirectUnguardedCall() external expectBeforeAfterReentrancyGuardUnlocked {
        // Expect to be able to call unguarded methods recursively.
        // Expect a success.
        target.countUnguardedDirectRecursive(10);
        assertEq(target.enterTimes(), 10);
    }

    function testRevertRecursiveDirectGuardedCall()
        external
        expectBeforeAfterReentrancyGuardUnlocked
    {
        // Attempt to reenter a `nonReentrant` method from a direct call.
        // Expect a revert with the `Reentrancy` error.
        vm.expectRevert(ReentrancyGuard.Reentrancy.selector);
        target.countGuardedDirectRecursive(10);
        assertEq(target.enterTimes(), 0);
    }

    function testRecursiveIndirectUnguardedCall()
        external
        expectBeforeAfterReentrancyGuardUnlocked
    {
        // Expect to be able to call unguarded methods recursively.
        // Expect a success.
        target.countUnguardedIndirectRecursive(10);
        assertEq(target.enterTimes(), 10);
    }

    function testRevertRecursiveIndirectGuardedCall()
        external
        expectBeforeAfterReentrancyGuardUnlocked
    {
        // Attempt to reenter a `nonReentrant` method from an indirect call.
        vm.expectRevert(ReentrancyGuard.Reentrancy.selector);
        target.countGuardedIndirectRecursive(10);
        assertEq(target.enterTimes(), 0);
    }
}
