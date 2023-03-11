// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/TestPlus.sol";
import {LibSort} from "../src/utils/LibSort.sol";
import {LibPRNG} from "../src/utils/LibPRNG.sol";
import {RedBlackTreeLib} from "../src/utils/RedBlackTreeLib.sol";

import {LibString} from "../src/utils/LibString.sol";

contract RedBlackTreeLibTest is TestPlus {
    using RedBlackTreeLib for *;
    using LibPRNG for *;

    RedBlackTreeLib.Tree tree;

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

    function _testRandomlyAndInsert(uint256[] memory a, uint256 n, uint256 t) internal {
        unchecked {
            uint256 choice = a[_random() % n];
            bytes32 ptr = tree.find(choice);
            bool exists = !ptr.isEmpty();
            if (exists) {
                assertEq(ptr.value(), choice);
                ptr.remove();
                assertTrue(tree.find(choice).isEmpty());
                assertFalse(tree.exists(choice));
            }
            if (t != 0) {
                _testRandomlyAndInsert(a, n, t - 1);
            }
            if (exists) {
                tree.insert(choice);
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
        uint256[] memory a = _makeArray(n);

        unchecked {
            for (uint256 i; i != n;) {
                uint256 r = _bound(_random(), 1, type(uint256).max);

                if (tree.find(r).isEmpty()) {
                    a[i++] = r;
                    tree.insert(r);
                }
                if (_random() % 4 == 0) {
                    _testRandomlyAndInsert(a, i, (3 + i >> 2));
                }
            }
        }

        LibSort.sort(a);
        LibSort.uniquifySorted(a);
        assertEq(a.length, n);
        assertEq(tree.size(), n);

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
    }

    function testRedBlackTreeInsertAndRemove2(uint256) public {
        unchecked {
            uint256[] memory candidates = _makeArray(32);
            for (uint256 i; i != candidates.length; ++i) {
                candidates[i] = _bound(_random(), 1, type(uint256).max);
            }
            uint256[] memory records = _makeArray(0);
            for (uint256 t; t != 8; ++t) {
                uint256 r = candidates[_random() % candidates.length];
                bytes32 ptr = tree.find(r);
                if (_random() % 2 == 0) {
                    if (ptr.isEmpty()) {
                        tree.insert(r);
                        _addToArray(records, r);
                    }
                } else {
                    if (!ptr.isEmpty()) {
                        tree.remove(r);
                        _removeFromArray(records, r);
                    }
                }
            }
            LibSort.sort(records);
            assertEq(tree.size(), records.length);

            {
                uint256 i;
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
        uint256 n = _bound(_random(), 1, 8);
        uint256[] memory a = _makeArray(n);
        unchecked {
            for (uint256 i; i != n;) {
                uint256 r = _bound(_random(), 1, type(uint256).max);

                if (tree.find(r).isEmpty()) {
                    a[i++] = r;
                    tree.insert(r);
                }
            }
        }
        uint256 x = _bound(_random(), 1, type(uint256).max);
        uint256 nearestIndex = _nearestIndex(a, x);
        assertEq(tree.nearest(x).value(), a[nearestIndex]);
    }

    function _nearestIndex(uint256[] memory a, uint256 x) internal pure returns (uint256) {
        unchecked {
            uint256 nearestIndex;
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
                }
            }
            return nearestIndex;
        }
    }
}
