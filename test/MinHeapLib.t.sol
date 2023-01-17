// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/TestPlus.sol";
import {MinHeapLib} from "../src/utils/MinHeapLib.sol";
import {LibSort} from "../src/utils/LibSort.sol";

contract MinHeapLibTest is TestPlus {
    using MinHeapLib for MinHeapLib.Heap;

    MinHeapLib.Heap heap0;

    MinHeapLib.Heap heap1;

    function testHeapRoot(uint256 x) public {
        vm.expectRevert(MinHeapLib.HeapIsEmpty.selector);
        heap0.root();
        heap0.data.push(x);
        assertEq(heap0.length(), 1);
        assertEq(heap0.root(), x);
    }

    function testHeapPushAndPop(uint256) public {
        unchecked {
            uint256 n = _random() % 8;
            uint256[] memory a = new uint256[](n);

            for (uint256 i; i < n; ++i) {
                uint256 r = _random();
                a[i] = r;
                heap0.push(r);
            }
            LibSort.insertionSort(a);
            for (uint256 i; i < n; ++i) {
                assertEq(heap0.pop(), a[i]);
            }
            assertEq(heap0.length(), 0);
        }
    }

    function testHeapPushPop(uint256) public {
        unchecked {
            uint256 n = _random() % 8;
            for (uint256 i; i < n; ++i) {
                uint256 r = _random();
                heap0.push(r);
                heap1.push(r);
            }
            n = _random() % 8;
            for (uint256 i; i < n; ++i) {
                uint256 r = _random();
                uint256 popped0 = heap0.pushPop(r);
                heap1.push(r);
                uint256 popped1 = heap1.pop();
                assertEq(popped0, popped1);
            }
        }
    }

    function testHeapReplace(uint256) public {
        unchecked {
            uint256 n = _random() % 8 + 1;
            for (uint256 i; i < n; ++i) {
                uint256 r = _random();
                heap0.push(r);
                heap1.push(r);
            }
            n = _random() % 8;
            for (uint256 i; i < n; ++i) {
                uint256 r = _random();
                uint256 popped0 = heap0.replace(r);
                uint256 popped1 = heap1.pop();
                heap1.push(r);
                assertEq(popped0, popped1);
            }
        }
    }

    function testHeapEnqueue(uint256) public {
        unchecked {
            uint256 maxLength = _random() % 8 + 1;
            uint256 m = _random() % 32 + maxLength;
            uint256[] memory a = new uint256[](m);
            uint256[] memory rejected = new uint256[](m);
            uint256 numRejected;
            for (uint256 i; i < m; ++i) {
                uint256 r = _random();
                (bool success, bool hasPopped, uint256 popped) = heap0.enqueue(r, maxLength);
                if (hasPopped) {
                    assertEq(heap0.length(), maxLength);
                    assertEq(success, true);
                    rejected[numRejected++] = popped;
                }
                if (!success) {
                    assertEq(heap0.length(), maxLength);
                    rejected[numRejected++] = r;
                }
                a[i] = r;
            }
            LibSort.insertionSort(a);
            /// @solidity memory-safe-assembly
            assembly {
                mstore(rejected, numRejected)
            }
            LibSort.insertionSort(rejected);
            for (uint256 i; i < maxLength; ++i) {
                assertEq(a[m - maxLength + i], heap0.pop());
            }
            assertEq(numRejected + maxLength, m);
            for (uint256 i; i < numRejected; ++i) {
                assertEq(a[i], rejected[i]);
            }
        }
    }

    function testHeapEnqueueGas(uint256) public {
        unchecked {
            for (uint256 i; i < 16; ++i) {
                this.enqueue(i, 8);
            }
            for (uint256 i; i < 16; ++i) {
                this.enqueue(_random() % 16, 8);
            }
        }
    }

    function enqueue(uint256 value, uint256 maxLength) public {
        heap0.enqueue(value, maxLength);
    }
}
