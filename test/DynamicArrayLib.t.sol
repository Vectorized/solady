// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {DynamicArrayLib} from "../src/utils/DynamicArrayLib.sol";

contract DynamicArrayLibTest is SoladyTest {
    using DynamicArrayLib for DynamicArrayLib.DynamicArray;
    using DynamicArrayLib for uint256[];

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
            DynamicArrayLib.DynamicArray memory slice = a.slice(start, end);
            _checkMemory(slice.data);
            assertEq(slice.data, _sliceOriginal(data, start, end));
        }
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
