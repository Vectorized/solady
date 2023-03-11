// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/TestPlus.sol";
import {LibSort} from "../src/utils/LibSort.sol";
import {LibPRNG} from "../src/utils/LibPRNG.sol";
import {RedBlackTreeLib} from "../src/utils/RedBlackTreeLib.sol";

contract RedBlackTreeLibTest is TestPlus {
    using RedBlackTreeLib for *;
    using LibPRNG for *;

    RedBlackTreeLib.Tree tree;

    function testRedBlackTreeInsertBenchUint160() public {
        unchecked {
            LibPRNG.PRNG memory prng = LibPRNG.PRNG(123);
            uint256 n = 128;
            uint256[] memory a = new uint256[](n);
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
            uint256[] memory a = new uint256[](n);
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
            uint256[] memory a = new uint256[](n);
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
            uint256[] memory a = new uint256[](n);
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
        uint256 n = _random() % (_random() % 32 == 0 ? 32 : 8);
        uint256[] memory a = new uint256[](n);

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
}
