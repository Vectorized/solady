// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {LibSort} from "../src/utils/LibSort.sol";
import {LibPRNG} from "../src/utils/LibPRNG.sol";
import {RedBlackTreeLib} from "../src/utils/RedBlackTreeLib.sol";

contract RedBlackTreeLibTest is SoladyTest {
    using RedBlackTreeLib for *;
    using LibPRNG for *;

    RedBlackTreeLib.Tree tree;
    RedBlackTreeLib.Tree tree2;

    function testRedBlackTreeInsertBenchStep() public {
        unchecked {
            LibPRNG.PRNG memory prng = LibPRNG.PRNG(123);
            uint256 n = 128;
            uint256 m = (1 << 160) - 1;
            for (uint256 i; i != n; ++i) {
                uint256 r = 1 | (prng.next() & m);
                tree.insert(r);
            }
            _testIterateTree();
        }
    }

    function testRedBlackTreeInsertBenchUint160() public {
        unchecked {
            LibPRNG.PRNG memory prng = LibPRNG.PRNG(123);
            uint256 n = 128;
            uint256[] memory a = _makeArray(n);
            uint256 m = (1 << 160) - 1;
            for (uint256 i; i != n; ++i) {
                uint256 r = 1 | (prng.next() & m);
                a[i] = r;
                tree.insert(r);
            }
        }
    }

    function testRedBlackTreeBenchUint160() public {
        unchecked {
            LibPRNG.PRNG memory prng = LibPRNG.PRNG(123);
            uint256 n = 128;
            uint256[] memory a = _makeArray(n);
            uint256 m = (1 << 160) - 1;
            for (uint256 i; i != n; ++i) {
                uint256 r = 1 | (prng.next() & m);
                a[i] = r;
                tree.insert(r);
            }
            prng.shuffle(a);
            for (uint256 i; i != n; ++i) {
                tree.remove(a[i]);
            }
            assertEq(tree.size(), 0);
        }
    }

    function testRedBlackTreeInsertBenchUint256() public {
        unchecked {
            LibPRNG.PRNG memory prng = LibPRNG.PRNG(123);
            uint256 n = 128;
            uint256[] memory a = _makeArray(n);
            for (uint256 i; i != n; ++i) {
                uint256 r = 1 | prng.next();
                a[i] = r;
                tree.insert(r);
            }
        }
    }

    function testRedBlackTreeBenchUint256() public {
        unchecked {
            LibPRNG.PRNG memory prng = LibPRNG.PRNG(123);
            uint256 n = 128;
            uint256[] memory a = _makeArray(n);
            for (uint256 i; i != n; ++i) {
                uint256 r = 1 | prng.next();
                a[i] = r;
                tree.insert(r);
            }
            prng.shuffle(a);
            for (uint256 i; i != n; ++i) {
                tree.remove(a[i]);
            }
            assertEq(tree.size(), 0);
        }
    }

    function testRedBlackTreeInsertAndRemove(uint256) public {
        unchecked {
            for (uint256 t; t < 2; ++t) {
                _testRedBlackTreeInsertAndRemove();
            }
        }
    }

    function _testRemoveAndInsertBack(uint256[] memory a, uint256 n, uint256 t) internal {
        unchecked {
            uint256 choice = a[_random() % n];
            bytes32 ptr = tree.find(choice);
            bool exists = !ptr.isEmpty();
            if (exists) {
                assertEq(ptr.value(), choice);
                _brutalizeScratchSpace();
                ptr.remove();
                if (_random() % 4 == 0) {
                    _brutalizeScratchSpace();
                    tree.tryRemove(choice);
                }
                assertTrue(tree.find(choice).isEmpty());
                assertFalse(tree.exists(choice));
            }
            if (t != 0) {
                _testRemoveAndInsertBack(a, n, t - 1);
            }
            if (exists) {
                _brutalizeScratchSpace();
                tree.insert(choice);
                if (_random() % 4 == 0) {
                    _brutalizeScratchSpace();
                    tree.tryInsert(choice);
                }
                assertFalse(tree.find(choice).isEmpty());
                assertTrue(tree.exists(choice));
            }
        }
    }

    function _testIterateTree() internal {
        bytes32 ptr = tree.first();
        uint256 prevValue;
        while (!ptr.isEmpty()) {
            uint256 v = ptr.value();
            assertTrue(prevValue < v);
            prevValue = v;
            ptr = ptr.next();
        }
        assertEq(ptr.next().value(), 0);

        ptr = tree.last();
        prevValue = 0;
        while (!ptr.isEmpty()) {
            uint256 v = ptr.value();
            assertTrue(prevValue == 0 || prevValue > v);
            prevValue = v;
            ptr = ptr.prev();
        }
        assertEq(ptr.prev().value(), 0);
    }

    function _testRedBlackTreeInsertAndRemove() internal {
        uint256 n = _random() % (_random() % 128 == 0 ? 32 : 8);
        uint256[] memory a = _fillTree(n);

        LibSort.sort(a);
        LibSort.uniquifySorted(a);
        assertEq(a.length, n);
        assertEq(tree.size(), n);

        assertEq(tree2.size(), 0);

        unchecked {
            uint256 i;
            bytes32 ptr = tree.first();
            while (!ptr.isEmpty()) {
                assertEq(a[i++], ptr.value());
                ptr = ptr.next();
            }
            assertEq(ptr.next().value(), 0);
        }

        unchecked {
            uint256 i = n;
            bytes32 ptr = tree.last();
            while (!ptr.isEmpty()) {
                assertEq(a[--i], ptr.value());
                ptr = ptr.prev();
            }
            assertEq(ptr.prev().value(), 0);
        }

        _testIterateTree();

        LibPRNG.PRNG memory prng = LibPRNG.PRNG(_random());
        prng.shuffle(a);

        unchecked {
            uint256 m = n < 8 ? 4 : n;
            for (uint256 i; i != n; ++i) {
                _brutalizeScratchSpace();
                tree.remove(a[i]);
                assertEq(tree.size(), n - i - 1);
                if (_random() % m == 0) {
                    _testIterateTree();
                }
            }
        }
        assertEq(tree.size(), 0);

        unchecked {
            if (_random() % 2 == 0) {
                for (uint256 i; i != n; ++i) {
                    assertTrue(tree.find(a[i]).isEmpty());
                }
            }
            assertTrue(tree.first().isEmpty());
            assertEq(tree.first().value(), 0);
            assertTrue(tree.last().isEmpty());
            assertEq(tree.last().value(), 0);
        }

        assertEq(tree2.size(), 0);
    }

    function testRedBlackTreeInsertAndRemove2(uint256) public {
        unchecked {
            uint256 n = _random() % 2 == 0 ? 16 : 32;
            uint256[] memory candidates = _makeArray(n);
            for (uint256 i; i != n; ++i) {
                candidates[i] = _bound(_random(), 1, type(uint256).max);
            }
            uint256[] memory records = _makeArray(0);
            uint256 mode = 0;
            for (uint256 t = _random() % 32 + 1; t != 0; --t) {
                uint256 r = candidates[_random() % n];
                bytes32 ptr = tree.find(r);
                if (mode == 0) {
                    if (ptr.isEmpty()) {
                        _brutalizeScratchSpace();
                        tree.insert(r);
                        _addToArray(records, r);
                    }
                } else {
                    if (!ptr.isEmpty()) {
                        _brutalizeScratchSpace();
                        tree.remove(r);
                        _removeFromArray(records, r);
                    }
                }
                if (_random() % 3 == 0) mode = _random() % 2;
            }
            LibSort.sort(records);
            assertEq(tree.size(), records.length);

            assertEq(tree2.size(), 0);

            {
                uint256 i = 0;
                bytes32 ptr = tree.first();
                while (!ptr.isEmpty()) {
                    assertEq(records[i++], ptr.value());
                    ptr = ptr.next();
                }
                assertEq(ptr.next().value(), 0);
            }
        }
    }

    function _makeArray(uint256 size, uint256 maxCap)
        internal
        pure
        returns (uint256[] memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, size)
            mstore(0x40, add(result, shl(5, add(maxCap, 1))))
        }
    }

    function _makeArray(uint256 size) internal pure returns (uint256[] memory result) {
        require(size <= 512, "Size too big.");
        result = _makeArray(size, 512);
    }

    function _addToArray(uint256[] memory a, uint256 x) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            let exists := 0
            let n := mload(a)
            for { let i := 0 } lt(i, n) { i := add(i, 1) } {
                let o := add(add(a, 0x20), shl(5, i))
                if eq(mload(o), x) {
                    exists := 1
                    break
                }
            }
            if iszero(exists) {
                n := add(n, 1)
                mstore(add(a, shl(5, n)), x)
                mstore(a, n)
            }
        }
    }

    function _removeFromArray(uint256[] memory a, uint256 x) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(a)
            for { let i := 0 } lt(i, n) { i := add(i, 1) } {
                let o := add(add(a, 0x20), shl(5, i))
                if eq(mload(o), x) {
                    mstore(o, mload(add(a, shl(5, n))))
                    mstore(a, sub(n, 1))
                    break
                }
            }
        }
    }

    function testRedBlackTreeInsertAndRemove3() public {
        unchecked {
            uint256 m = type(uint256).max;
            for (uint256 i; i < 256; ++i) {
                _brutalizeScratchSpace();
                tree.insert(m - i);
                assertEq(tree.size(), i + 1);
            }
            for (uint256 i; i < 256; ++i) {
                tree2.insert(i + 1);
                assertEq(tree2.size(), i + 1);
            }
            for (uint256 i; i < 256; ++i) {
                assertTrue(tree.exists(m - i));
                assertFalse(tree.exists(i + 1));
                assertTrue(tree2.exists(i + 1));
                assertFalse(tree2.exists(m - i));
            }
            bytes32[] memory ptrs = new bytes32[](256);
            for (uint256 i; i < 256; ++i) {
                bytes32 ptr = tree.find(m - i);
                _brutalizeScratchSpace();
                ptr.remove();
                assertTrue(ptr.value() != m - i);
                ptrs[i] = ptr;
                assertEq(tree.size(), 256 - (i + 1));
            }
            for (uint256 i; i < 256; ++i) {
                assertEq(ptrs[i].value(), 0);
                vm.expectRevert(RedBlackTreeLib.PointerOutOfBounds.selector);
                _brutalizeScratchSpace();
                ptrs[i].remove();
            }
            for (uint256 i; i < 256; ++i) {
                _brutalizeScratchSpace();
                tree2.remove(i + 1);
                assertEq(tree2.size(), 256 - (i + 1));
            }
        }
    }

    function testRedBlackTreeInsertOneGas() public {
        unchecked {
            for (uint256 i; i != 1; ++i) {
                tree.insert(i + 1);
            }
        }
    }

    function testRedBlackTreeInsertTwoGas() public {
        unchecked {
            for (uint256 i; i != 2; ++i) {
                tree.insert(i + 1);
            }
        }
    }

    function testRedBlackTreeInsertThreeGas() public {
        unchecked {
            for (uint256 i; i != 3; ++i) {
                tree.insert(i + 1);
            }
        }
    }

    function testRedBlackTreeInsertTenGas() public {
        unchecked {
            for (uint256 i; i != 10; ++i) {
                tree.insert(i + 1);
            }
        }
    }

    function testRedBlackTreeValues() public {
        testRedBlackTreeValues(3);
    }

    function testRedBlackTreeValues(uint256 n) public {
        unchecked {
            n = n & 7;
            while (true) {
                uint256[] memory values = new uint256[](n);
                for (uint256 i; i != n; ++i) {
                    values[i] = 1 | _random();
                    _brutalizeScratchSpace();
                    tree.tryInsert(values[i]);
                }
                LibSort.sort(values);
                LibSort.uniquifySorted(values);
                uint256[] memory retrieved = tree.values();
                _checkMemory();
                assertEq(retrieved, values);
                n = values.length;
                if (_random() & 1 == 0) {
                    LibPRNG.PRNG memory prng = LibPRNG.PRNG(_random());
                    prng.shuffle(values);
                    for (uint256 i; i != n; ++i) {
                        _brutalizeScratchSpace();
                        tree.tryRemove(values[i]);
                    }
                    assertEq(tree.values(), new uint256[](0));
                    if (_random() & 1 == 0) {
                        n += _random() & 15;
                        continue;
                    }
                }
                break;
            }
        }
    }

    function testRedBlackTreeRejectsEmptyValue() public {
        vm.expectRevert(RedBlackTreeLib.ValueIsEmpty.selector);
        tree.insert(0);
        vm.expectRevert(RedBlackTreeLib.ValueIsEmpty.selector);
        tree.remove(0);
        vm.expectRevert(RedBlackTreeLib.ValueIsEmpty.selector);
        tree.find(0);
    }

    function testRedBlackTreeRemoveViaPointer() public {
        tree.insert(1);
        tree.insert(2);

        bytes32 ptr = tree.find(1);
        ptr.remove();
        ptr.remove();

        vm.expectRevert(RedBlackTreeLib.PointerOutOfBounds.selector);
        ptr.remove();

        ptr = bytes32(0);
        vm.expectRevert(RedBlackTreeLib.ValueDoesNotExist.selector);
        ptr.remove();
    }

    function testRedBlackTreeTryInsertAndRemove() public {
        tree.tryInsert(1);
        tree.tryInsert(2);
        assertEq(tree.size(), 2);
        tree.tryInsert(1);
        assertEq(tree.size(), 2);
        tree.tryRemove(2);
        assertEq(tree.size(), 1);
        tree.tryRemove(2);
        assertEq(tree.size(), 1);
    }

    function testRedBlackTreeTreeFullReverts() public {
        tree.insert(1);
        bytes32 ptr = tree.find(1);
        /// @solidity memory-safe-assembly
        assembly {
            ptr := shl(32, shr(32, ptr))
            sstore(ptr, or(sload(ptr), sub(shl(31, 1), 1)))
        }
        vm.expectRevert(RedBlackTreeLib.TreeIsFull.selector);
        tree.insert(2);
        assertEq(tree.size(), 2 ** 31 - 1);
    }

    function testRedBlackTreePointers() public {
        assertTrue(tree.find(1).isEmpty());
        assertTrue(tree.find(2).isEmpty());

        tree.insert(1);
        tree.insert(2);

        assertFalse(tree.find(1).isEmpty());
        assertFalse(tree.find(2).isEmpty());

        assertTrue(tree.find(1).prev().isEmpty());
        assertFalse(tree.find(1).next().isEmpty());

        assertFalse(tree.find(2).prev().isEmpty());
        assertTrue(tree.find(2).next().isEmpty());

        assertEq(tree.find(1).next(), tree.find(2));
        assertEq(tree.find(1), tree.find(2).prev());

        assertTrue(tree.find(1).prev().isEmpty());
        assertTrue(tree.find(1).prev().prev().isEmpty());
        assertTrue(tree.find(1).prev().next().isEmpty());

        assertTrue(tree.find(2).next().isEmpty());
        assertTrue(tree.find(2).next().next().isEmpty());
        assertTrue(tree.find(2).next().prev().isEmpty());

        assertEq(tree.first(), tree.find(1));
        assertEq(tree.last(), tree.find(2));

        assertTrue(tree.find(3).isEmpty());
    }

    function testRedBlackTreeNearest(uint256) public {
        assertEq(tree.nearest(1), bytes32(0));
        uint256[] memory a = _fillTree(_random() % 8);
        uint256 x = _bound(_random(), 1, type(uint256).max);
        (uint256 nearestIndex, bool found) = _nearestIndex(a, x);
        if (found) {
            assertEq(tree.nearest(x).value(), a[nearestIndex]);
        } else {
            assertEq(tree.nearest(x), bytes32(0));
        }
    }

    function _nearestIndex(uint256[] memory a, uint256 x)
        internal
        pure
        returns (uint256 nearestIndex, bool found)
    {
        unchecked {
            uint256 nearestValue = type(uint256).max;
            uint256 nearestDist = type(uint256).max;
            uint256 n = a.length;
            for (uint256 i; i != n; ++i) {
                uint256 y = a[i];
                uint256 dist = x < y ? y - x : x - y;
                if (dist < nearestDist || (dist == nearestDist && y < nearestValue)) {
                    nearestIndex = i;
                    nearestValue = y;
                    nearestDist = dist;
                    found = true;
                }
            }
        }
    }

    function testRedBlackTreeNearestBefore(uint256) public {
        assertEq(tree.nearestBefore(1), bytes32(0));
        uint256[] memory a = _fillTree(_random() % 8);
        uint256 x = _bound(_random(), 1, type(uint256).max);
        (uint256 nearestIndexBefore, bool found) = _nearestIndexBefore(a, x);
        if (found) {
            assertEq(tree.nearestBefore(x).value(), a[nearestIndexBefore]);
        } else {
            assertEq(tree.nearestBefore(x), bytes32(0));
        }
    }

    function _nearestIndexBefore(uint256[] memory a, uint256 x)
        internal
        pure
        returns (uint256 nearestIndex, bool found)
    {
        unchecked {
            uint256 nearestDist = type(uint256).max;
            uint256 n = a.length;
            for (uint256 i; i != n; ++i) {
                uint256 y = a[i];
                if (y > x) continue;
                uint256 dist = x - y;
                if (dist < nearestDist) {
                    nearestIndex = i;
                    nearestDist = dist;
                    found = true;
                }
            }
        }
    }

    function testRedBlackTreeNearestAfter(uint256) public {
        assertEq(tree.nearestAfter(1), bytes32(0));
        uint256[] memory a = _fillTree(_random() % 8);
        uint256 x = _bound(_random(), 1, type(uint256).max);
        (uint256 nearestIndexAfter, bool found) = _nearestIndexAfter(a, x);
        if (found) {
            assertEq(tree.nearestAfter(x).value(), a[nearestIndexAfter]);
        } else {
            assertEq(tree.nearestAfter(x), bytes32(0));
        }
    }

    function _nearestIndexAfter(uint256[] memory a, uint256 x)
        internal
        pure
        returns (uint256 nearestIndex, bool found)
    {
        unchecked {
            uint256 nearestDist = type(uint256).max;
            uint256 n = a.length;
            for (uint256 i; i != n; ++i) {
                uint256 y = a[i];
                if (y < x) continue;
                uint256 dist = y - x;
                if (dist < nearestDist) {
                    nearestIndex = i;
                    nearestDist = dist;
                    found = true;
                }
            }
        }
    }

    function _fillTree(uint256 n) internal returns (uint256[] memory a) {
        a = _makeArray(n);
        unchecked {
            for (uint256 i; i != n;) {
                uint256 r = _bound(_random(), 1, type(uint256).max);
                if (tree.find(r).isEmpty()) {
                    a[i++] = r;
                    _brutalizeScratchSpace();
                    tree.insert(r);
                }
                if (_random() % 4 == 0) {
                    _testRemoveAndInsertBack(a, i, (3 + i >> 2));
                }
            }
        }
    }
}
