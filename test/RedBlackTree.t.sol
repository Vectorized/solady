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

    function testRedBlackTreePerformance() public {
        unchecked {
            LibPRNG.PRNG memory prng = LibPRNG.PRNG(123);
            uint256 n = 128;
            uint256[] memory a = new uint256[](n);
            uint256 m = (1 << 161) - 1;
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

    function testRedBlackTreeInsertAndRemove(uint256) public {
        unchecked {
            for (uint256 t; t < 2; ++t) {
                _testRedBlackTreeInsertAndRemove();
            }
        }
    }

    function _testRedBlackTreeInsertAndRemove() internal {
        uint256 n = _random() % 16;
        uint256[] memory a = new uint256[](n);

        unchecked {
            for (uint256 i; i != n; ++i) {
                uint256 r = _bound(_random(), 1, type(uint256).max);
                a[i] = r;
                if (tree.find(r).isEmpty()) {
                    tree.insert(r);
                }

                if (_random() % 2 == 0) {
                    uint256 c0 = a[_random() % (i + 1)];
                    bytes32 p0 = tree.find(c0);
                    assertEq(p0.value(), c0);
                    if (!p0.isEmpty()) {
                        p0.remove();
                        assertTrue(tree.find(c0).isEmpty());
                        assertFalse(tree.exists(c0));
                        if (_random() % 2 == 0) {
                            uint256 c1 = a[_random() % (i + 1)];
                            bytes32 p1 = tree.find(c1);
                            if (!p1.isEmpty()) {
                                assertEq(p1.value(), c1);
                                p1.remove();
                                tree.insert(c1);
                            }
                        }
                        tree.insert(c0);
                        assertFalse(tree.find(c0).isEmpty());
                        assertTrue(tree.exists(c0));
                    }
                }
            }
        }

        LibSort.sort(a);
        LibSort.uniquifySorted(a);

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
            uint256 i = a.length;
            bytes32 ptr = tree.last();
            while (!ptr.isEmpty()) {
                assertEq(a[--i], ptr.value());
                ptr = ptr.prev();
            }
            assertEq(ptr.prev().value(), 0);
        }

        assertEq(tree.size(), a.length);

        LibPRNG.PRNG memory prng = LibPRNG.PRNG(_random());
        prng.shuffle(a);

        unchecked {
            for (uint256 i; i != a.length; ++i) {
                tree.remove(a[i]);
            }
        }
        assertEq(tree.size(), 0);

        unchecked {
            for (uint256 i; i != a.length; ++i) {
                assertTrue(tree.find(a[i]).isEmpty());
            }
            assertTrue(tree.first().isEmpty());
            assertEq(tree.first().value(), 0);
            assertTrue(tree.last().isEmpty());
            assertEq(tree.last().value(), 0);
        }
    }
}
