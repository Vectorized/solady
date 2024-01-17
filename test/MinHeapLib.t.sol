// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {MinHeapLib} from "../src/utils/MinHeapLib.sol";
import {LibSort} from "../src/utils/LibSort.sol";

contract MinHeapLibTest is SoladyTest {
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
            uint256[] memory a = new uint256[](n + 1);
            for (uint256 i; i < n; ++i) {
                uint256 r = _random();
                heap0.push(r);
                heap1.push(r);
                a[i + 1] = r;
            }
            n = _random() % 8;
            for (uint256 i; i < n; ++i) {
                uint256 r = _random();
                a[0] = r;
                LibSort.insertionSort(a);
                uint256 popped0 = heap0.pushPop(r);
                heap1.push(r);
                uint256 popped1 = heap1.pop();
                assertEq(popped0, popped1);
            }
            LibSort.insertionSort(a);
            n = heap0.length();
            for (uint256 i; i < n; ++i) {
                assertEq(heap0.pop(), a[i + 1]);
            }
        }
    }

    function testHeapReplace(uint256) public {
        unchecked {
            uint256 n = _random() % 8 + 1;
            uint256[] memory a = new uint256[](n);
            for (uint256 i; i < n; ++i) {
                uint256 r = _random();
                heap0.push(r);
                heap1.push(r);
                a[i] = r;
            }
            n = _random() % 8;
            for (uint256 i; i < n; ++i) {
                uint256 r = _random();
                LibSort.insertionSort(a);
                a[0] = r;
                uint256 popped0 = heap0.replace(r);
                uint256 popped1 = heap1.pop();
                heap1.push(r);
                assertEq(popped0, popped1);
            }
            LibSort.insertionSort(a);
            n = heap0.length();
            for (uint256 i; i < n; ++i) {
                assertEq(heap0.pop(), a[i]);
            }
        }
    }

    function testHeapSmallest(uint256) public brutalizeMemory {
        unchecked {
            uint256 n = _random() & 15 == 0 ? _random() % 256 : _random() % 32;
            for (uint256 i; i < n; ++i) {
                heap0.push(_random());
            }
            if (_random() & 7 == 0) {
                n = _random() % 32;
                for (uint256 i; i < n; ++i) {
                    heap0.pushPop(_random());
                    if (_random() & 1 == 0) {
                        heap0.push(_random());
                        if (_random() & 1 == 0) heap0.pop();
                    }
                    if (_random() & 1 == 0) if (heap0.length() != 0) heap0.replace(_random());
                }
            }
            uint256 k = _random() & 15 == 0 ? _random() % 256 : _random() % 32;
            k = _random() & 31 == 0 ? 1 << 255 : k;
            if (_random() & 7 == 0) _brutalizeMemory();
            uint256[] memory computed = heap0.smallest(k);
            _checkMemory();
            if (_random() & 7 == 0) _brutalizeMemory();
            assertEq(computed, _smallest(heap0.data, k));
        }
    }

    function testHeapSmallestGas() public {
        unchecked {
            for (uint256 i; i < 2048; ++i) {
                heap0.push(_random());
            }
            uint256 gasBefore = gasleft();
            heap0.smallest(512);
            uint256 gasUsed = gasBefore - gasleft();
            emit LogUint("gasUsed", gasUsed);
        }
    }

    function _smallest(uint256[] memory a, uint256 n)
        internal
        view
        returns (uint256[] memory result)
    {
        result = _copy(a);
        LibSort.insertionSort(result);
        uint256 k = _min(n, result.length);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(result, k)
        }
    }

    function _copy(uint256[] memory a) private view returns (uint256[] memory b) {
        /// @solidity memory-safe-assembly
        assembly {
            b := mload(0x40)
            let n := add(shl(5, mload(a)), 0x20)
            pop(staticcall(gas(), 4, a, n, b, n))
            mstore(0x40, add(b, n))
        }
    }

    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function testHeapPSiftTrick(uint256 c, uint256 h, uint256 e) public {
        assertEq(_heapPSiftTrick(c, h, e), _heapPSiftTrickOriginal(c, h, e));
    }

    function _heapPSiftTrick(uint256 c, uint256 h, uint256 e)
        internal
        pure
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            function pValue(h_, p_) -> _v {
                mstore(0x00, h_)
                mstore(0x20, p_)
                _v := keccak256(0x00, 0x40)
            }
            if lt(c, e) {
                c := add(c, gt(pValue(h, c), pValue(h, add(c, lt(add(c, 1), e)))))
                result := c
            }
        }
    }

    function _heapPSiftTrickOriginal(uint256 childPos, uint256 sOffset, uint256 n)
        internal
        pure
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            function pValue(h_, p_) -> _v {
                mstore(0x00, h_)
                mstore(0x20, p_)
                _v := keccak256(0x00, 0x40)
            }
            if lt(childPos, n) {
                let child := pValue(sOffset, childPos)
                let rightPos := add(childPos, 1)
                let right := pValue(sOffset, rightPos)
                if or(iszero(lt(rightPos, n)), lt(child, right)) {
                    right := child
                    rightPos := childPos
                }
                result := rightPos
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

    function testHeapEnqueue2(uint256) public {
        unchecked {
            uint256 maxLength = _random() & 31 == 0 ? 1 << 255 : _random() % 32 + 1;
            uint256 m = _random() % 32 + 1;
            for (uint256 i; i < m; ++i) {
                uint256 r = _random();
                heap0.enqueue(r, maxLength);
                heap1.push(r);
                if (heap1.length() > maxLength) heap1.pop();
            }
            uint256 k = _random() % m;
            k = _random() & 31 == 0 ? 1 << 255 : k;
            assertEq(heap0.smallest(k), heap1.smallest(k));
        }
    }

    function testHeapEnqueueGas() public {
        unchecked {
            for (uint256 t = 8; t < 16; ++t) {
                uint256 maxLength = t;
                for (uint256 i; i < 16; ++i) {
                    heap0.enqueue(i, maxLength);
                }
                for (uint256 i; i < 16; ++i) {
                    heap0.enqueue(_random() % 16, maxLength);
                }
            }
            while (heap0.length() != 0) heap0.pop();
        }
    }
}
