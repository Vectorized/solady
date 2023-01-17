// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/TestPlus.sol";
import {LibHeap} from "../src/utils/LibHeap.sol";
import {LibSort} from "../src/utils/LibSort.sol";
import {LibString} from "../src/utils/LibString.sol";

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

    function testHeapPushAndPop(uint256) public {
        unchecked {
            uint256 n = _random() % 32;
            uint256[] memory a = new uint256[](n);

            for (uint256 i; i < n; ++i) {
                uint256 r = _random();
                a[i] = r;
                heap0.push(r);
            }
            LibSort.sort(a);
            for (uint256 i; i < n; ++i) {
                assertEq(heap0.pop(), a[i]);
            }
            assertEq(heap0.length(), 0);
        }
    }

    function testHeapPushPop(uint256) public {
        unchecked {
            uint256 n = _random() % 32;
            for (uint256 i; i < n; ++i) {
                uint256 r = _random();
                heap0.push(r);
                heap1.push(r);
            }
            n = _random() % 32;
            for (uint256 i; i < 2; ++i) {
                uint256 r = _random();
                uint256 popped0 = heap0.pushPop(r);
                heap1.push(r);
                uint256 popped1 = heap1.pop();
                assertEq(popped0, popped1);
            }
        }
    }
}
