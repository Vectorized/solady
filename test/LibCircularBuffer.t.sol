// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./utils/SoladyTest.sol";
import {LibCircularBuffer} from "../src/utils/LibCircularBuffer.sol";

contract CircularBufferUser {
    using LibCircularBuffer for LibCircularBuffer.Buffer;

    LibCircularBuffer.Buffer private buffer;

    constructor(uint256 capacity) {
        buffer.initialize(capacity);
    }

    // Expose init to test AlreadyInitialized
    function reinit(uint256 capacity) external {
        buffer.initialize(capacity);
    }

    function pushValue(bytes32 value) public returns (bool) {
        return buffer.push(value);
    }

    function shift() public returns (bytes32) {
        return buffer.shift();
    }

    function pop() public returns (bytes32) {
        return buffer.pop();
    }

    function peekFirst() public view returns (bytes32) {
        return buffer.peekFirst();
    }

    function peekLast() public view returns (bytes32) {
        return buffer.peekLast();
    }

    function getAt(uint256 i) public view returns (bytes32) {
        return buffer.at(i);
    }

    function clear() public {
        buffer.clear();
    }

    function getSize() public view returns (uint256) {
        return buffer.size();
    }

    function getCapacity() public view returns (uint256) {
        return buffer.capacity();
    }

    function isFull() public view returns (bool) {
        return buffer.isFull();
    }

    function pushMany(bytes32[] calldata xs) public returns (uint256) {
        return buffer.pushN(xs);
    }
}

contract LibCircularBufferTest is SoladyTest {
    CircularBufferUser buf4; // cap = 4

    function setUp() public {
        buf4 = new CircularBufferUser(4);
    }

    /* ─────────────────────────── init  ────────────────────────── */

    function testInitRejectsNonPowerOfTwo() public {
        vm.expectRevert(LibCircularBuffer.NotPowerOfTwo.selector);
        new CircularBufferUser(3);
    }

    function testAlreadyInitialized() public {
        vm.expectRevert(LibCircularBuffer.AlreadyInitialized.selector);
        buf4.reinit(4);
    }

    function testCapacityAndSizeStart() public {
        assertEq(buf4.getCapacity(), 4);
        assertEq(buf4.getSize(), 0);
        assertFalse(buf4.isFull());
    }

    /* ─────────────────────────── shift / pop / peek ───────────────────────── */

    function testShift_FIFO() public {
        _pushSeq(buf4, 10, 4); // 10,11,12,13
        assertEq(uint256(buf4.shift()), 10);
        assertEq(buf4.getSize(), 3);
        assertEq(uint256(buf4.shift()), 11);
        assertEq(buf4.getSize(), 2);
        // remaining: 12,13
        assertEq(uint256(buf4.peekFirst()), 12);
        assertEq(uint256(buf4.peekLast()), 13);
    }

    function testPop_LIFO() public {
        _pushSeq(buf4, 100, 3); // 100,101,102
        assertEq(uint256(buf4.pop()), 102);
        assertEq(buf4.getSize(), 2);
        assertEq(uint256(buf4.pop()), 101);
        assertEq(buf4.getSize(), 1);
        assertEq(uint256(buf4.peekFirst()), 100);
        assertEq(uint256(buf4.peekLast()), 100);
    }

    /* ──────────────────────────── at / bounds ─────────────────────────────── */

    function testAt_OutOfBounds() public {
        _pushSeq(buf4, 1, 2); // size=2
        vm.expectRevert(LibCircularBuffer.OutOfBounds.selector);
        buf4.getAt(2); // equal to size -> OOB
    }

    function testPeekOnEmptyReverts() public {
        vm.expectRevert(LibCircularBuffer.Empty.selector);
        buf4.peekFirst();
        vm.expectRevert(LibCircularBuffer.Empty.selector);
        buf4.peekLast();
        vm.expectRevert(LibCircularBuffer.Empty.selector);
        buf4.pop();
        vm.expectRevert(LibCircularBuffer.Empty.selector);
        buf4.shift();
    }

    /* ────────────────────────── push / overwrite ──────────────────────────── */

    function testPushFillAndOverwrite() public {
        _pushSeq(buf4, 1, 4); // push 1,2,3,4
        assertEq(buf4.getSize(), 4);
        assertTrue(buf4.isFull());

        bool overwritten = buf4.pushValue(bytes32(uint256(5)));
        assertTrue(overwritten, "fifth push should overwrite");
        assertEq(buf4.getSize(), 4);

        // Now logical order should be 2,3,4,5
        assertEq(uint256(buf4.peekFirst()), 2);
        assertEq(uint256(buf4.peekLast()), 5);
        assertEq(uint256(buf4.getAt(0)), 2);
        assertEq(uint256(buf4.getAt(1)), 3);
        assertEq(uint256(buf4.getAt(2)), 4);
        assertEq(uint256(buf4.getAt(3)), 5);
    }

    function testPushN_NoOverwrite() public {
        // cap=4, push 3 items → no overwrite, size=3
        bytes32[] memory xs = new bytes32[](3);
        xs[0] = bytes32(uint256(11));
        xs[1] = bytes32(uint256(12));
        xs[2] = bytes32(uint256(13));

        uint256 ow = buf4.pushMany(xs);
        assertEq(ow, 0);
        assertEq(buf4.getSize(), 3);
        assertEq(uint256(buf4.getAt(0)), 11);
        assertEq(uint256(buf4.getAt(1)), 12);
        assertEq(uint256(buf4.getAt(2)), 13);
        assertEq(uint256(buf4.peekFirst()), 11);
        assertEq(uint256(buf4.peekLast()), 13);
    }

    function testPushN_WithOverwrite() public {
        // Fill to 4: 1,2,3,4
        for (uint256 i = 1; i <= 4; ++i) {
            buf4.pushValue(bytes32(i));
        }
        // Push 3: 5,6,7 → overwrites=3, ring holds 4 newest: 4,5,6,7
        bytes32[] memory xs = new bytes32[](3);
        xs[0] = bytes32(uint256(5));
        xs[1] = bytes32(uint256(6));
        xs[2] = bytes32(uint256(7));

        uint256 ow = buf4.pushMany(xs);
        assertEq(ow, 3);
        assertEq(buf4.getSize(), 4);
        assertEq(uint256(buf4.getAt(0)), 4);
        assertEq(uint256(buf4.getAt(1)), 5);
        assertEq(uint256(buf4.getAt(2)), 6);
        assertEq(uint256(buf4.getAt(3)), 7);
        assertEq(uint256(buf4.peekFirst()), 4);
        assertEq(uint256(buf4.peekLast()), 7);
    }

    function testPushN_LargeBatchMultipleWraps() public {
        // cap=4, push 10 → size stays 4, overwritten=6, last 4 kept
        bytes32[] memory xs = new bytes32[](10);
        for (uint256 i = 0; i < xs.length; ++i) {
            xs[i] = bytes32(uint256(100 + i));
        }
        uint256 ow = buf4.pushMany(xs);
        assertEq(ow, 6);
        assertEq(buf4.getSize(), 4);
        // Expect 106..109
        for (uint256 i = 0; i < 4; ++i) {
            assertEq(uint256(buf4.getAt(i)), 106 + i);
        }
        assertEq(uint256(buf4.peekFirst()), 106);
        assertEq(uint256(buf4.peekLast()), 109);
    }

    function testPushN_ZeroLength_NoOp() public {
        // size stays the same; overwritten=0
        buf4.pushValue(bytes32(uint256(1)));
        uint256 before = buf4.getSize();

        bytes32[] memory xs = new bytes32[](0);
        uint256 ow = buf4.pushMany(xs);

        assertEq(ow, 0);
        assertEq(buf4.getSize(), before);
        assertEq(uint256(buf4.peekLast()), 1);
    }

    function testPushN_InterleaveWithShift_PreservesOrder() public {
        // Start with 2 items
        buf4.pushValue(bytes32(uint256(1)));
        buf4.pushValue(bytes32(uint256(2)));
        assertEq(buf4.getSize(), 2);

        // Batch push 3 more → now size=4, overwritten=1 (since cap=4, sum=5)
        bytes32[] memory xs = new bytes32[](3);
        xs[0] = bytes32(uint256(3));
        xs[1] = bytes32(uint256(4));
        xs[2] = bytes32(uint256(5));
        uint256 ow = buf4.pushMany(xs);
        assertEq(ow, 1);
        assertEq(buf4.getSize(), 4);

        // Logical order now: 2,3,4,5
        assertEq(uint256(buf4.getAt(0)), 2);
        assertEq(uint256(buf4.getAt(1)), 3);
        assertEq(uint256(buf4.getAt(2)), 4);
        assertEq(uint256(buf4.getAt(3)), 5);

        // Shift twice (FIFO): should get 2 then 3
        assertEq(uint256(buf4.shift()), 2);
        assertEq(uint256(buf4.shift()), 3);
        assertEq(buf4.getSize(), 2);

        // PushN 2 more: 6,7 → ring now holds last 4: 4,5,6,7
        bytes32[] memory ys = new bytes32[](2);
        ys[0] = bytes32(uint256(6));
        ys[1] = bytes32(uint256(7));
        ow = buf4.pushMany(ys);

        assertEq(ow, 0); // size went 2 -> 4 (no overwrite)
        assertEq(buf4.getSize(), 4);
        assertEq(uint256(buf4.getAt(0)), 4);
        assertEq(uint256(buf4.getAt(1)), 5);
        assertEq(uint256(buf4.getAt(2)), 6);
        assertEq(uint256(buf4.getAt(3)), 7);
    }

    /* ───────────────────────────── clear ──────────────────────────────────── */

    function testClearKeepsCapacity() public {
        _pushSeq(buf4, 7, 4);
        assertEq(buf4.getSize(), 4);
        buf4.clear();
        assertEq(buf4.getSize(), 0);
        assertEq(buf4.getCapacity(), 4); // cap preserved
        // push works after clear
        buf4.pushValue(bytes32(uint256(99)));
        assertEq(buf4.getSize(), 1);
        assertEq(uint256(buf4.peekFirst()), 99);
    }

    /* ─────────────────────────── edge cases ───────────────────────────────── */

    function testCapacityOne() public {
        CircularBufferUser b1 = new CircularBufferUser(1);
        assertEq(b1.getCapacity(), 1);
        assertEq(b1.getSize(), 0);

        bool ow;
        ow = b1.pushValue(bytes32(uint256(42)));
        assertFalse(ow);
        assertEq(b1.getSize(), 1);
        assertEq(uint256(b1.getAt(0)), 42);

        ow = b1.pushValue(bytes32(uint256(99)));
        assertTrue(ow); // overwrite
        assertEq(b1.getSize(), 1);
        assertEq(uint256(b1.getAt(0)), 99);

        assertEq(uint256(b1.shift()), 99);
        assertEq(b1.getSize(), 0);
    }

    /* ───────────────────────────── fuzzing ────────────────────────────────── */

    // Fuzz small sequences (<= cap) so no overwrite; FIFO should match input.
    function testFuzz_PushThenShift_NoOverwrite(uint8 a, uint8 b, uint8 c) public {
        // cap 4 means up to 4 items fits without overwrite.
        uint256[3] memory xs = [uint256(a), uint256(b), uint256(c)];
        // reset fresh buffer
        CircularBufferUser B = new CircularBufferUser(4);

        for (uint256 i = 0; i < xs.length; ++i) {
            B.pushValue(bytes32(xs[i]));
        }
        assertEq(B.getSize(), xs.length);

        for (uint256 i = 0; i < xs.length; ++i) {
            assertEq(uint256(B.getAt(i)), xs[i]);
        }
        for (uint256 i = 0; i < xs.length; ++i) {
            assertEq(uint256(B.shift()), xs[i]);
        }
        assertEq(B.getSize(), 0);
    }

    /* ─────────────────────────── helpers ──────────────────────────────────── */

    function _pushSeq(CircularBufferUser b, uint256 start, uint256 count) internal {
        for (uint256 i = 0; i < count; ++i) {
            b.pushValue(bytes32(start + i));
        }
    }
}
