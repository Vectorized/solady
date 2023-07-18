// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import "./utils/mocks/MockOwnable.sol";

contract OwnableTest is SoladyTest {
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    event OwnershipHandoverRequested(address indexed pendingOwner);

    event OwnershipHandoverCanceled(address indexed pendingOwner);

    MockOwnable mockOwnable;

    function setUp() public {
        mockOwnable = new MockOwnable();
    }

    function testBytecodeSize() public {
        MockOwnableBytecodeSizer mock = new MockOwnableBytecodeSizer();
        assertTrue(address(mock).code.length > 0);
        assertEq(mock.owner(), address(this));
    }

    function testInitializeOwnerDirect() public {
        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(address(0), address(1));
        mockOwnable.initializeOwnerDirect(address(1));
    }

    function testSetOwnerDirect(address newOwner) public {
        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(address(this), newOwner);
        mockOwnable.setOwnerDirect(newOwner);
        assertEq(mockOwnable.owner(), newOwner);
    }

    function testSetOwnerDirect() public {
        testSetOwnerDirect(address(1));
    }

    function testRenounceOwnership() public {
        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(address(this), address(0));
        mockOwnable.renounceOwnership();
        assertEq(mockOwnable.owner(), address(0));
    }

    function testTransferOwnership(
        address newOwner,
        bool setNewOwnerToZeroAddress,
        bool callerIsOwner
    ) public {
        assertEq(mockOwnable.owner(), address(this));

        vm.assume(newOwner != address(this));

        if (newOwner == address(0) || setNewOwnerToZeroAddress) {
            newOwner = address(0);
            vm.expectRevert(Ownable.NewOwnerIsZeroAddress.selector);
        } else if (callerIsOwner) {
            vm.expectEmit(true, true, true, true);
            emit OwnershipTransferred(address(this), newOwner);
        } else {
            vm.prank(newOwner);
            vm.expectRevert(Ownable.Unauthorized.selector);
        }

        mockOwnable.transferOwnership(newOwner);

        if (newOwner != address(0) && callerIsOwner) {
            assertEq(mockOwnable.owner(), newOwner);
        }
    }

    function testTransferOwnership() public {
        testTransferOwnership(address(1), false, true);
    }

    function testOnlyOwnerModifier(address nonOwner, bool callerIsOwner) public {
        vm.assume(nonOwner != address(this));

        if (!callerIsOwner) {
            vm.prank(nonOwner);
            vm.expectRevert(Ownable.Unauthorized.selector);
        }
        mockOwnable.updateFlagWithOnlyOwner();
    }

    function testHandoverOwnership(address pendingOwner) public {
        vm.prank(pendingOwner);
        vm.expectEmit(true, true, true, true);
        emit OwnershipHandoverRequested(pendingOwner);
        mockOwnable.requestOwnershipHandover();
        assertTrue(mockOwnable.ownershipHandoverExpiresAt(pendingOwner) > block.timestamp);

        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(address(this), pendingOwner);

        mockOwnable.completeOwnershipHandover(pendingOwner);

        assertEq(mockOwnable.owner(), pendingOwner);
    }

    function testHandoverOwnership() public {
        testHandoverOwnership(address(1));
    }

    function testHandoverOwnershipRevertsIfCompleteIsNotOwner() public {
        address pendingOwner = address(1);
        vm.prank(pendingOwner);
        mockOwnable.requestOwnershipHandover();

        vm.prank(pendingOwner);
        vm.expectRevert(Ownable.Unauthorized.selector);
        mockOwnable.completeOwnershipHandover(pendingOwner);
    }

    function testHandoverOwnershipWithCancellation() public {
        address pendingOwner = address(1);

        vm.prank(pendingOwner);
        vm.expectEmit(true, true, true, true);
        emit OwnershipHandoverRequested(pendingOwner);
        mockOwnable.requestOwnershipHandover();
        assertTrue(mockOwnable.ownershipHandoverExpiresAt(pendingOwner) > block.timestamp);

        vm.expectEmit(true, true, true, true);
        emit OwnershipHandoverCanceled(pendingOwner);
        vm.prank(pendingOwner);
        mockOwnable.cancelOwnershipHandover();
        assertEq(mockOwnable.ownershipHandoverExpiresAt(pendingOwner), 0);
        vm.expectRevert(Ownable.NoHandoverRequest.selector);

        mockOwnable.completeOwnershipHandover(pendingOwner);
    }

    function testHandoverOwnershipBeforeExpiration() public {
        address pendingOwner = address(1);
        vm.prank(pendingOwner);
        mockOwnable.requestOwnershipHandover();

        vm.warp(block.timestamp + mockOwnable.ownershipHandoverValidFor());

        mockOwnable.completeOwnershipHandover(pendingOwner);
    }

    function testHandoverOwnershipAfterExpiration() public {
        address pendingOwner = address(1);
        vm.prank(pendingOwner);
        mockOwnable.requestOwnershipHandover();

        vm.warp(block.timestamp + mockOwnable.ownershipHandoverValidFor() + 1);

        vm.expectRevert(Ownable.NoHandoverRequest.selector);

        mockOwnable.completeOwnershipHandover(pendingOwner);
    }

    function testOwnershipHandoverValidForDefaultValue() public {
        assertEq(mockOwnable.ownershipHandoverValidFor(), 48 * 3600);
    }
}
