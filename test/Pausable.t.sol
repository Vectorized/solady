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
    /*
    function testSetOwnerDirect() public {
        testSetOwnerDirect(address(1));
    }

    function testRenounceOwnership() public {
        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(address(this), address(0));
        mockPausable.renounceOwnership();
        assertEq(mockPausable.owner(), address(0));
    }

    function testTransferOwnership(
        address newOwner,
        bool setNewOwnerToZeroAddress,
        bool callerIsOwner
    ) public {
        assertEq(mockPausable.owner(), address(this));

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

        mockPausable.transferOwnership(newOwner);

        if (newOwner != address(0) && callerIsOwner) {
            assertEq(mockPausable.owner(), newOwner);
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
        mockPausable.updateFlagWithOnlyOwner();
    }

    function testHandoverOwnership(address pendingOwner) public {
        vm.prank(pendingOwner);
        vm.expectEmit(true, true, true, true);
        emit OwnershipHandoverRequested(pendingOwner);
        mockPausable.requestOwnershipHandover();
        assertTrue(mockPausable.ownershipHandoverExpiresAt(pendingOwner) > block.timestamp);

        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(address(this), pendingOwner);

        mockPausable.completeOwnershipHandover(pendingOwner);

        assertEq(mockPausable.owner(), pendingOwner);
    }

    function testHandoverOwnership() public {
        testHandoverOwnership(address(1));
    }

    function testHandoverOwnershipRevertsIfCompleteIsNotOwner() public {
        address pendingOwner = address(1);
        vm.prank(pendingOwner);
        mockPausable.requestOwnershipHandover();

        vm.prank(pendingOwner);
        vm.expectRevert(Ownable.Unauthorized.selector);
        mockPausable.completeOwnershipHandover(pendingOwner);
    }

    function testHandoverOwnershipWithCancellation() public {
        address pendingOwner = address(1);

        vm.prank(pendingOwner);
        vm.expectEmit(true, true, true, true);
        emit OwnershipHandoverRequested(pendingOwner);
        mockPausable.requestOwnershipHandover();
        assertTrue(mockPausable.ownershipHandoverExpiresAt(pendingOwner) > block.timestamp);

        vm.expectEmit(true, true, true, true);
        emit OwnershipHandoverCanceled(pendingOwner);
        vm.prank(pendingOwner);
        mockPausable.cancelOwnershipHandover();
        assertEq(mockPausable.ownershipHandoverExpiresAt(pendingOwner), 0);
        vm.expectRevert(Ownable.NoHandoverRequest.selector);

        mockPausable.completeOwnershipHandover(pendingOwner);
    }

    function testHandoverOwnershipBeforeExpiration() public {
        address pendingOwner = address(1);
        vm.prank(pendingOwner);
        mockPausable.requestOwnershipHandover();

        vm.warp(block.timestamp + mockPausable.ownershipHandoverValidFor());

        mockPausable.completeOwnershipHandover(pendingOwner);
    }

    function testHandoverOwnershipAfterExpiration() public {
        address pendingOwner = address(1);
        vm.prank(pendingOwner);
        mockPausable.requestOwnershipHandover();

        vm.warp(block.timestamp + mockPausable.ownershipHandoverValidFor() + 1);

        vm.expectRevert(Ownable.NoHandoverRequest.selector);

        mockPausable.completeOwnershipHandover(pendingOwner);
    }

    function testOwnershipHandoverValidForDefaultValue() public {
        assertEq(mockPausable.ownershipHandoverValidFor(), 48 * 3600);
    }

    */
}

/*
const { expectEvent } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

const { expectRevertCustomError } = require('../helpers/customError');

const PausableMock = artifacts.require('PausableMock');

contract('Pausable', function (accounts) {
  const [pauser] = accounts;

  beforeEach(async function () {
    this.pausable = await PausableMock.new();
  });

  context('when unpaused', function () {

    

    context('when paused', function () {
      beforeEach(async function () {
        this.receipt = await this.pausable.pause({ from: pauser });
      });

      it('emits a Paused event', function () {
        expectEvent(this.receipt, 'Paused', { account: pauser });
      });

      it('cannot perform normal process in pause', async function () {
        await expectRevertCustomError(this.pausable.normalProcess(), 'EnforcedPause', []);
      });

      it('can take a drastic measure in a pause', async function () {
        await this.pausable.drasticMeasure();
        expect(await this.pausable.drasticMeasureTaken()).to.equal(true);
      });

      it('reverts when re-pausing', async function () {
        await expectRevertCustomError(this.pausable.pause(), 'EnforcedPause', []);
      });

      describe('unpausing', function () {
        it('is unpausable by the pauser', async function () {
          await this.pausable.unpause();
          expect(await this.pausable.paused()).to.equal(false);
        });

        context('when unpaused', function () {
          beforeEach(async function () {
            this.receipt = await this.pausable.unpause({ from: pauser });
          });

          it('emits an Unpaused event', function () {
            expectEvent(this.receipt, 'Unpaused', { account: pauser });
          });

          it('should resume allowing normal process', async function () {
            expect(await this.pausable.count()).to.be.bignumber.equal('0');
            await this.pausable.normalProcess();
            expect(await this.pausable.count()).to.be.bignumber.equal('1');
          });

          it('should prevent drastic measure', async function () {
            await expectRevertCustomError(this.pausable.drasticMeasure(), 'ExpectedPause', []);
          });

          it('reverts when re-unpausing', async function () {
            await expectRevertCustomError(this.pausable.unpause(), 'ExpectedPause', []);
          });
        });
      });
    });
  });
});
*/
