// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {DynamicArrayLib} from "../src/utils/DynamicArrayLib.sol";

contract DynamicArrayLibTest is SoladyTest {
    using DynamicArrayLib for *;

    function testDynamicArrayPushAndPop() public {
        uint256 n = 100;
        DynamicArrayLib.DynamicArray memory a;
        unchecked {
            for (uint256 i; i != n; ++i) {
                a.p(i);
            }
            for (uint256 i; i != n; ++i) {
                assertEq(a.get(i), i);
            }
            for (uint256 i; i != n; ++i) {
                assertEq(a.length(), 100 - i);
                assertEq(a.pop(), 99 - i);
            }
        }
    }

    function testDynamicArrayPushAfterReserve() public {
        uint256 n = 100;
        DynamicArrayLib.DynamicArray memory a;
        a.reserve(n);
        unchecked {
            for (uint256 i; i != n; ++i) {
                a.p(i);
            }
            for (uint256 i; i != n; ++i) {
                assertEq(a.get(i), i);
            }
        }
    }

    function testDynamicArrayWrap() public {
        {
            address[] memory a = new address[](2);
            a[1] = address(1);
            assertEq(DynamicArrayLib.wrap(a).get(0), 0);
            assertEq(DynamicArrayLib.wrap(a).get(1), 1);
        }
        {
            bytes32[] memory a = new bytes32[](2);
            a[1] = bytes32(uint256(1));
            assertEq(DynamicArrayLib.wrap(a).get(0), 0);
            assertEq(DynamicArrayLib.wrap(a).get(1), 1);
        }
        {
            bool[] memory a = new bool[](2);
            a[1] = true;
            assertEq(DynamicArrayLib.wrap(a).get(0), 0);
            assertEq(DynamicArrayLib.wrap(a).get(1), 1);
        }
    }

    function testDynamicArrayResize(uint256[] memory data, uint256 n) public {
        DynamicArrayLib.DynamicArray memory a;
        a.data = data;
        n = _bound(_random(), 0, 0xff);
        a.resize(n);
        assertEq(a.data.length, n);
        _checkMemory(a.data);
        unchecked {
            for (uint256 i; i != n; ++i) {
                if (i < data.length) {
                    assertEq(a.get(i), data[i]);
                } else {
                    assertEq(a.get(i), 0);
                }
            }
        }
        uint256 lengthBefore = n;
        n = _bound(_random(), 0, 0xff);
        a.resize(n);
        assertEq(a.data.length, n);
        _checkMemory(a.data);
        unchecked {
            for (uint256 i; i != n; ++i) {
                if (i < lengthBefore && i < data.length) {
                    assertEq(a.get(i), data[i]);
                } else {
                    assertEq(a.get(i), 0);
                }
            }
        }
    }

    function testDynamicArrayExpandAndTruncate(bytes32) public {
        uint256 n = _bound(_random(), 0, 0xff);
        DynamicArrayLib.DynamicArray memory a;
        uint256 lengthBefore = a.expand(n).length();
        assertEq(lengthBefore, n);
        _checkMemory(a.data);
        n = _bound(_random(), 0, 0xff);
        a.expand(n);
        if (n > lengthBefore) {
            assertEq(a.length(), n);
        } else {
            assertEq(a.length(), lengthBefore);
        }
        bool hasValues;
        if (_randomChance(32)) {
            hasValues = true;
            unchecked {
                for (uint256 i; i != a.length(); ++i) {
                    a.set(i, i);
                }
            }
        }
        lengthBefore = a.length();
        n = _bound(_random(), 0, 0xff);
        a.truncate(n);
        if (n < lengthBefore) {
            assertEq(a.length(), n);
        } else {
            assertEq(a.length(), lengthBefore);
        }
        _checkMemory(a.data);
        if (hasValues) {
            unchecked {
                for (uint256 i; i != a.length(); ++i) {
                    assertEq(a.get(i), i);
                }
            }
        }
    }

    function testDynamicArrayPushPop(uint256 n, uint256 r) public {
        n = _bound(n, 0, 50);
        if (_randomChance(2)) _misalignFreeMemoryPointer();
        if (_randomChance(8)) _brutalizeMemory();

        DynamicArrayLib.DynamicArray memory a;
        assertEq(a.data.length, 0);

        unchecked {
            if (_randomChance(16)) a.free();
            if (_randomChance(16)) assertEq(a.pop(), 0);
            if (_randomChance(16)) a.reserve(_bound(_random(), 0, 50));
            if (_randomChance(2)) _checkMemory(a.data);

            for (uint256 i; i != n; ++i) {
                a.p(i ^ r);
                assertEq(a.length(), i + 1);
                _checkMemory(a.data);

                if (_randomChance(8)) {
                    a.reserve(_bound(_random(), 0, 50));
                    _checkMemory(a.data);
                    assertEq(a.length(), i + 1);
                }
                if (_randomChance(16)) {
                    assertEq(keccak256(abi.encodePacked(a.data)), a.hash());
                }
                if (_randomChance(16)) {
                    for (uint256 j; j != i; ++j) {
                        assertEq(a.get(j), j ^ r);
                    }
                }
            }
            for (uint256 i; i != n; ++i) {
                assertEq(a.get(i), i ^ r);
            }

            assertEq(keccak256(abi.encodePacked(a.data)), a.hash());

            if (_randomChance(16)) {
                assertEq(a.free().length(), 0);
                if (_randomChance(16)) a.reserve(_bound(_random(), 0, 50));
                if (_randomChance(2)) _checkMemory(a.data);
                for (uint256 i; i != n; ++i) {
                    a.p(i ^ r);
                    _checkMemory(a.data);
                }
                for (uint256 i; i != n; ++i) {
                    assertEq(a.get(i), i ^ r);
                }
            }

            if (_randomChance(2)) {
                a.clear();
                assertEq(a.length(), 0);
            } else {
                if (_randomChance(2)) {
                    uint256 newLength = _bound(_random(), 0, 50);
                    a.resize(newLength);
                    assertEq(a.length(), newLength);
                    _checkMemory(a.data);
                    for (uint256 i; i != newLength; ++i) {
                        if (i < n) {
                            assertEq(a.get(i), i ^ r);
                        } else {
                            assertEq(a.getBytes32(i), bytes32(0));
                        }
                    }
                } else {
                    for (uint256 i; i != n; ++i) {
                        assertEq(a.pop(), (n - 1 - i) ^ r);
                    }
                    assertEq(a.pop(), 0);
                }
            }
        }
    }

    function testDynamicArraySlice() public {
        DynamicArrayLib.DynamicArray memory a = DynamicArrayLib.p("a").p("b").p("c");
        assertEq(a.slice(0, 3).hash(), DynamicArrayLib.p("a").p("b").p("c").hash());
        assertEq(a.slice(1, 3).hash(), DynamicArrayLib.p("b").p("c").hash());
        assertEq(a.slice(2, 3).hash(), DynamicArrayLib.p("c").hash());
        assertEq(a.slice(3, 3).hash(), DynamicArrayLib.p().hash());
        assertEq(a.slice(0, 2).hash(), DynamicArrayLib.p("a").p("b").hash());
        assertEq(a.slice(0, 1).hash(), DynamicArrayLib.p("a").hash());
        assertEq(a.slice(0, 0).hash(), DynamicArrayLib.p().hash());
        assertEq(a.slice(1, 2).hash(), DynamicArrayLib.p("b").hash());
        assertEq(a.slice(1, 1).hash(), DynamicArrayLib.p().hash());
    }

    function testDynamicArraySlice(uint256[] memory data, uint256 start, uint256 end) public {
        DynamicArrayLib.DynamicArray memory a;
        a.data = data;
        unchecked {
            start = _bound(start, 0, a.data.length + 2);
            end = _bound(end, 0, a.data.length + 2);
            DynamicArrayLib.DynamicArray memory slice;
            if (_randomChance(2) && end > a.data.length) {
                slice = a.slice(start);
            } else {
                slice = a.slice(start, end);
            }
            _checkMemory(slice.data);
            assertEq(slice.data, _sliceOriginal(data, start, end));
        }
    }

    function testDynamicArrayCopy(uint256[] memory data) public {
        DynamicArrayLib.DynamicArray memory a;
        a.data = data;
        DynamicArrayLib.DynamicArray memory b = a.copy();
        assertEq(a.data, b.data);
        a.p(1);
        assertNotEq(a.data, b.data);
        b.p(1);
        assertEq(a.data, b.data);
    }

    function testUint256Contains() public {
        uint256 n = 50;
        uint256[] memory a;
        assertEq(DynamicArrayLib.contains(a, 0), false);
        assertEq(DynamicArrayLib.contains(a, 1), false);
        assertEq(DynamicArrayLib.contains(a, 2), false);
        a = new uint256[](0);
        assertEq(DynamicArrayLib.contains(a, 0), false);
        assertEq(DynamicArrayLib.contains(a, 1), false);
        assertEq(DynamicArrayLib.contains(a, 2), false);
        a = new uint256[](1);
        assertEq(DynamicArrayLib.contains(a, 0), true);
        assertEq(DynamicArrayLib.contains(a, 1), false);
        assertEq(DynamicArrayLib.contains(a, 2), false);
        a = DynamicArrayLib.malloc(n);
        unchecked {
            for (uint256 i; i != n; ++i) {
                a.set(i, i);
            }
        }
        assertEq(DynamicArrayLib.contains(a, 0), true);
        assertEq(DynamicArrayLib.contains(a, 1), true);
        assertEq(DynamicArrayLib.contains(a, 10), true);
        assertEq(DynamicArrayLib.contains(a, 31), true);
        assertEq(DynamicArrayLib.contains(a, 32), true);
        assertEq(DynamicArrayLib.contains(a, 49), true);
        assertEq(DynamicArrayLib.contains(a, 50), false);
        assertEq(DynamicArrayLib.contains(a, 100), false);
    }

    function testUint256ArrayIndexOf() public {
        uint256 n = 50;
        uint256[] memory a;
        assertEq(DynamicArrayLib.indexOf(a, 0), DynamicArrayLib.NOT_FOUND);
        assertEq(DynamicArrayLib.indexOf(a, 1), DynamicArrayLib.NOT_FOUND);
        assertEq(DynamicArrayLib.indexOf(a, 2), DynamicArrayLib.NOT_FOUND);
        a = new uint256[](0);
        assertEq(DynamicArrayLib.indexOf(a, 0), DynamicArrayLib.NOT_FOUND);
        assertEq(DynamicArrayLib.indexOf(a, 1), DynamicArrayLib.NOT_FOUND);
        assertEq(DynamicArrayLib.indexOf(a, 2), DynamicArrayLib.NOT_FOUND);
        a = new uint256[](1);
        assertEq(DynamicArrayLib.indexOf(a, 0), 0);
        assertEq(DynamicArrayLib.indexOf(a, 1), DynamicArrayLib.NOT_FOUND);
        assertEq(DynamicArrayLib.indexOf(a, 2), DynamicArrayLib.NOT_FOUND);
        a = DynamicArrayLib.malloc(n);
        unchecked {
            for (uint256 i; i != n; ++i) {
                a.set(i, i);
            }
        }
        assertEq(DynamicArrayLib.indexOf(a, 0), 0);
        assertEq(DynamicArrayLib.indexOf(a, 1), 1);
        assertEq(DynamicArrayLib.indexOf(a, 10), 10);
        assertEq(DynamicArrayLib.indexOf(a, 31), 31);
        assertEq(DynamicArrayLib.indexOf(a, 32), 32);
        assertEq(DynamicArrayLib.indexOf(a, 49), 49);
        assertEq(DynamicArrayLib.indexOf(a, 50), DynamicArrayLib.NOT_FOUND);
        assertEq(DynamicArrayLib.indexOf(a, 100), DynamicArrayLib.NOT_FOUND);
    }

    function testUint256ArrayIndexOfDifferential(
        uint256[] memory array,
        uint256 needle,
        uint256 from
    ) public {
        if (_randomChance(2)) _misalignFreeMemoryPointer();
        if (_randomChance(8)) _brutalizeMemory();
        from = _bound(from, 0, array.length + 10);
        uint256 computed = DynamicArrayLib.indexOf(array, needle, from);
        assertEq(computed, _indexOfOriginal(array, needle, from));
        if (_randomChance(16)) {
            computed = DynamicArrayLib.indexOf(array, needle);
            assertEq(computed, _indexOfOriginal(array, needle));
            computed = DynamicArrayLib.indexOf(DynamicArrayLib.DynamicArray(array), needle);
            assertEq(computed, _indexOfOriginal(array, needle));
        }
    }

    function _indexOfOriginal(uint256[] memory array, uint256 needle)
        internal
        pure
        returns (uint256)
    {
        return _indexOfOriginal(array, needle, 0);
    }

    function _indexOfOriginal(uint256[] memory array, uint256 needle, uint256 from)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 n = array.length;
            for (uint256 i = from; i < n; ++i) {
                if (array[i] == needle) return i;
            }
        }
        return type(uint256).max;
    }

    function testUint256ArrayLastIndexOf() public {
        uint256 n = 50;
        uint256[] memory a;
        assertEq(DynamicArrayLib.lastIndexOf(a, 0), DynamicArrayLib.NOT_FOUND);
        assertEq(DynamicArrayLib.lastIndexOf(a, 1), DynamicArrayLib.NOT_FOUND);
        assertEq(DynamicArrayLib.lastIndexOf(a, 2), DynamicArrayLib.NOT_FOUND);
        a = new uint256[](0);
        assertEq(DynamicArrayLib.lastIndexOf(a, 0), DynamicArrayLib.NOT_FOUND);
        assertEq(DynamicArrayLib.lastIndexOf(a, 1), DynamicArrayLib.NOT_FOUND);
        assertEq(DynamicArrayLib.lastIndexOf(a, 2), DynamicArrayLib.NOT_FOUND);
        a = new uint256[](1);
        assertEq(DynamicArrayLib.lastIndexOf(a, 0), 0);
        assertEq(DynamicArrayLib.lastIndexOf(a, 1), DynamicArrayLib.NOT_FOUND);
        assertEq(DynamicArrayLib.lastIndexOf(a, 2), DynamicArrayLib.NOT_FOUND);
        a = DynamicArrayLib.malloc(n);
        unchecked {
            for (uint256 i; i != n; ++i) {
                a.set(i, i);
            }
        }
        assertEq(DynamicArrayLib.lastIndexOf(a, 0), 0);
        assertEq(DynamicArrayLib.lastIndexOf(a, 1), 1);
        assertEq(DynamicArrayLib.lastIndexOf(a, 10), 10);
        assertEq(DynamicArrayLib.lastIndexOf(a, 31), 31);
        assertEq(DynamicArrayLib.lastIndexOf(a, 32), 32);
        assertEq(DynamicArrayLib.lastIndexOf(a, 49), 49);
        assertEq(DynamicArrayLib.lastIndexOf(a, 50), DynamicArrayLib.NOT_FOUND);
        assertEq(DynamicArrayLib.lastIndexOf(a, 100), DynamicArrayLib.NOT_FOUND);

        // edge case
        assertEq(DynamicArrayLib.lastIndexOf(a, 0, 0), 0);
        assertEq(DynamicArrayLib.lastIndexOf(a, 1, 1), 1);
        assertEq(DynamicArrayLib.lastIndexOf(a, 10, 10), 10);
        assertEq(DynamicArrayLib.lastIndexOf(a, 31, 31), 31);
        assertEq(DynamicArrayLib.lastIndexOf(a, 32, 32), 32);
        assertEq(DynamicArrayLib.lastIndexOf(a, 49, 49), 49);
        assertEq(DynamicArrayLib.lastIndexOf(a, 50, 50), DynamicArrayLib.NOT_FOUND);
        assertEq(DynamicArrayLib.lastIndexOf(a, 100, 100), DynamicArrayLib.NOT_FOUND);
    }

    function testUint256ArrayLastIndexOfDifferential(
        uint256[] memory array,
        uint256 needle,
        uint256 from
    ) public {
        if (_randomChance(2)) _misalignFreeMemoryPointer();
        if (_randomChance(8)) _brutalizeMemory();
        from = _bound(from, 0, array.length + 10);
        uint256 computed = DynamicArrayLib.lastIndexOf(array, needle, from);
        assertEq(computed, _lastIndexOfOriginal(array, needle, from));
        if (_randomChance(16)) {
            computed = DynamicArrayLib.lastIndexOf(array, needle);
            assertEq(computed, _lastIndexOfOriginal(array, needle));
            computed = DynamicArrayLib.lastIndexOf(DynamicArrayLib.DynamicArray(array), needle);
            assertEq(computed, _lastIndexOfOriginal(array, needle));
        }
    }

    function _lastIndexOfOriginal(uint256[] memory array, uint256 needle)
        internal
        pure
        returns (uint256)
    {
        return _lastIndexOfOriginal(array, needle, type(uint256).max);
    }

    function _lastIndexOfOriginal(uint256[] memory array, uint256 needle, uint256 from)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 n = array.length;
            if (n > 0) {
                if (from >= n) from = (n - 1);
                for (uint256 i = (from + 1); i != 0;) {
                    --i;
                    if (array[i] == needle) return i;
                }
            }
        }
        return type(uint256).max;
    }

    function testUint256ArrayPopulate() public {
        unchecked {
            uint256 n = 100;
            uint256[] memory a = DynamicArrayLib.malloc(n);
            for (uint256 i; i != n; ++i) {
                a.set(i, i);
            }
            uint256 sum;
            for (uint256 i; i != n; ++i) {
                sum += a.get(i);
            }
            assertEq(sum, 4950);
        }
    }

    function testUint256ArrayPopulateOriginal() public {
        unchecked {
            uint256 n = 100;
            uint256[] memory a = new uint256[](n);
            for (uint256 i; i != n; ++i) {
                a[i] = i;
            }
            uint256 sum;
            for (uint256 i; i != n; ++i) {
                sum += a[i];
            }
            assertEq(sum, 4950);
        }
    }

    function testUint256ArrayOperations(uint256 n, uint256 r) public {
        unchecked {
            n = _bound(n, 0, 50);
            uint256[] memory a = DynamicArrayLib.malloc(n);
            assertEq(a.length, n);
            _checkMemory(a);
            for (uint256 i; i != n; ++i) {
                a.set(i, i ^ r);
            }
            for (uint256 i; i != n; ++i) {
                assertEq(a.get(i), i ^ r);
            }
            if (_randomChance(32)) {
                DynamicArrayLib.DynamicArray memory b;
                for (uint256 i; i != n; ++i) {
                    b.p(i ^ r);
                }
                assertEq(b.hash(), a.hash());
                if (_randomChance(2)) {
                    assertEq(b.resize(0).resize(n).hash(), a.zeroize().hash());
                }
            }
            if (n > 5 && _randomChance(8)) {
                a.set(0, 1).set(1, 2);
                assertEq(a.get(0), 1);
                assertEq(a.get(1), 2);
            }
            uint256 lengthBefore = n;
            n = _bound(_random(), 0, 50);
            if (n < lengthBefore) {
                assertEq(a.truncate(n).length, n);
            } else {
                assertEq(a.truncate(n).length, lengthBefore);
            }
            if (_randomChance(2)) {
                assertEq(a.free().length, 0);
                _checkMemory(a);
            }
        }
    }

    function testUint256ArrayMisc() public {
        uint256[] memory a = DynamicArrayLib.malloc(1);
        assertEq(a.set(0, address(3)).get(0), 3);
        assertEq(a.set(0, bytes32(uint256(9))).get(0), 9);
        assertEq(a.set(0, bytes32(uint256(9))).getUint256(0), 9);
        assertEq(a.set(0, bytes32(uint256(9))).getAddress(0), address(9));
        assertEq(a.set(0, bytes32(uint256(9))).getBool(0), true);
        assertEq(a.set(0, true).get(0), 1);
    }

    function testDynamicArraySetAndGet(bytes32, uint256 i, uint256 n) public {
        DynamicArrayLib.DynamicArray memory a;
        n = _bound(n, 1, 5);
        a.resize(n);
        {
            i = _bound(i, 0, n - 1);
            address data = _randomHashedAddress();
            assertEq(a.set(i, data).getAddress(i), data);
        }
        {
            i = _bound(i, 0, n - 1);
            bool data = _randomChance(2);
            assertEq(a.set(i, data).getBool(i), data);
        }
        {
            i = _bound(i, 0, n - 1);
            bytes32 data = bytes32(_random());
            assertEq(a.set(i, data).getBytes32(i), data);
        }
        {
            i = _bound(i, 0, n - 1);
            uint256 data = _random();
            assertEq(a.set(i, data).get(i), data);
        }
    }

    function testDynamicArrayFree(uint256 n) public {
        DynamicArrayLib.DynamicArray memory a;
        uint256 m = _freeMemoryPointer();
        n = _bound(n, 0, 50);
        if (_randomChance(16)) a.reserve(n);
        a.free();
        assertEq(m, _freeMemoryPointer());
    }

    function testUint256ArrayDirectReturn(uint256 seed) public {
        unchecked {
            uint256[] memory a = this.uint256ArrayDirectReturn(seed);
            assertEq(a[0], seed + 0);
            assertEq(a[1], seed + 1);
            assertEq(a[2], seed + 2);
            assertEq(a.length, 3);
            _checkMemory(a);
        }
    }

    function uint256ArrayDirectReturn(uint256 seed) external pure returns (uint256[] memory) {
        unchecked {
            uint256[] memory result = DynamicArrayLib.malloc(3);
            result.set(0, seed + 0);
            result.set(1, seed + 1);
            result.set(2, seed + 2);
            DynamicArrayLib.directReturn(result);
        }
    }

    function testDynamicArrayDirectReturn(uint256 seed) public {
        unchecked {
            uint256[] memory a = this.dynamicArrayDirectReturn(seed);
            assertEq(a[0], seed + 0);
            assertEq(a[1], seed + 1);
            assertEq(a[2], seed + 2);
            assertEq(a.length, 3);
            _checkMemory(a);
        }
    }

    function dynamicArrayDirectReturn(uint256 seed) external pure returns (uint256[] memory) {
        unchecked {
            DynamicArrayLib.p(seed + 0).p(seed + 1).p(seed + 2).directReturn();
        }
    }

    function _sliceOriginal(uint256[] memory a, uint256 start, uint256 end)
        internal
        pure
        returns (uint256[] memory result)
    {
        if (start > a.length) start = a.length;
        if (end > a.length) end = a.length;
        unchecked {
            if (start < end) {
                uint256 n = end - start;
                result = new uint256[](n);
                for (uint256 i; i != n; ++i) {
                    result[i] = a[start + i];
                }
            }
        }
    }
}
