// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import "./utils/mocks/MockPausable.sol";

contract PausableTest is SoladyTest {
    // errors
    error EnforcedPause();
    error ExpectedPause();

    // events
    event Paused(address account);
    event Unpaused(address account);

    MockPausable mockPausable;

    function setUp() public {
        mockPausable = new MockPausable();
    }

    function testBytecodeSize() public {
        PausableMockBytecodeSizer mock = new PausableMockBytecodeSizer();
        assertTrue(address(mock).code.length > 0);
        assertEq(mockPausable.paused(), false);
    }

    function testCanPerformNonPaused() public {
        mockPausable.normalProcess();
        assertEq(mockPausable.count(), 1, "count should be 1");
    }

    function testNotPerformIfPaused() public {
        mockPausable.pause();
        vm.expectRevert(EnforcedPause.selector);
        mockPausable.normalProcess();
    }

    function testPauseUnpause() public {
        mockPausable.pause();
        vm.expectRevert(EnforcedPause.selector);
        mockPausable.normalProcess();

        mockPausable.unpause();
        mockPausable.normalProcess();
        assertEq(mockPausable.count(), 1, "count should be 1");

        mockPausable.pause();
        vm.expectRevert(EnforcedPause.selector);
        mockPausable.normalProcess();

        mockPausable.unpause();
        mockPausable.normalProcess();
        assertEq(mockPausable.count(), 2, "count should be 2");
    }

    function testCantRunIfNonPause() public {
        vm.expectRevert(ExpectedPause.selector);
        mockPausable.drasticMeasure();
    }

    function testCantPauseIfPaused() public {
        mockPausable.pause();
        vm.expectRevert(EnforcedPause.selector);
        mockPausable.pause();
    }

    function testCantUnpausedIfUnpaused() public {
        /// @dev by default contract starts unpaused
        vm.expectRevert(ExpectedPause.selector);
        mockPausable.unpause();
    }

    function testEvents(address pauser, address unpauser) public {
        vm.assume(pauser != address(0));
        vm.assume(unpauser != address(0));

        vm.startPrank(pauser);

        vm.expectEmit(true, true, true, true);
        emit Paused(pauser);
        mockPausable.pause();

        vm.stopPrank();
        vm.startPrank(unpauser);

        vm.expectEmit(true, true, true, true);
        emit Unpaused(unpauser);
        mockPausable.unpause();
    }
}