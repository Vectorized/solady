// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/TestPlus.sol";
import {LibHeap} from "../src/utils/LibHeap.sol";
import {LibSort} from "../src/utils/LibSort.sol";

contract LibHeapTest is TestPlus {
    using LibHeap for LibHeap.Heap;

    LibHeap.Heap heap0;

    LibHeap.Heap heap1;

    function testHeapRoot(uint256 x) public {
        vm.expectRevert(LibHeap.HeapIsEmpty.selector);
        heap0.root();
        heap0.data.push(x);
        assertEq(heap0.length(), 1);
        assertEq(heap0.root(), x);
    }

    function testHeapPushAndPopMin(uint256) public {
        unchecked {
            uint256 n = _random() % 32;
            uint256[] memory a = new uint256[](n);
            for (uint256 i; i < n; ++i) {
                uint256 r = _random();
                a[i] = r;
                heap0.pushMin(r);
            }
            LibSort.sort(a);
            for (uint256 i; i < n; ++i) {
                assertEq(heap0.popMin(), a[i]);
            }
        }
    }

    function _checkMinHeapInvariant(LibHeap.Heap storage heap) private view {
        unchecked {
            uint256 n = heap.data.length;
            for (uint256 i = 1; i < n; ++i) {
                uint256 parentPos = (i - 1) >> 1;
                uint256 item = heap.data[i];
                if (heap.data[parentPos] > item) {
                    revert("Min heap invariant violated.");
                }
            }
        }
    }

    function _checkMinHeapInvariant() private view {
        _checkMinHeapInvariant(heap0);
        _checkMinHeapInvariant(heap1);
    }

    function _checkMaxHeapInvariant(LibHeap.Heap storage heap) private view {
        unchecked {
            uint256 n = heap.data.length;
            for (uint256 i = 1; i < n; ++i) {
                uint256 parentPos = (i - 1) >> 1;
                uint256 item = heap.data[i];
                if (heap.data[parentPos] < item) {
                    revert("Max heap invariant violated.");
                }
            }
        }
    }

    function _checkMaxHeapInvariant() private view {
        _checkMinHeapInvariant(heap0);
        _checkMinHeapInvariant(heap1);
    }
}
