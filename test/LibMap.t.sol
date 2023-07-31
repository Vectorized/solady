// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {LibMap} from "../src/utils/LibMap.sol";

contract LibMapTest is SoladyTest {
    using LibMap for *;

    uint8[0xffffffffffffffff] bigUint8ArrayMap;

    LibMap.Uint8Map[2] uint8s;

    LibMap.Uint16Map[2] uint16s;

    LibMap.Uint32Map[2] uint32s;

    LibMap.Uint40Map[2] uint40s;

    LibMap.Uint64Map[2] uint64s;

    LibMap.Uint128Map[2] uint128s;

    mapping(uint256 => LibMap.Uint32Map) uint32Maps;

    mapping(uint256 => mapping(uint256 => uint256)) generalMaps;

    mapping(uint256 => uint256) filled;

    struct _TestTemps {
        uint256 i0;
        uint256 i1;
        uint256 v0;
        uint256 v1;
    }

    function _testTemps() internal returns (_TestTemps memory t) {
        uint256 r = _random();
        t.i0 = (r >> 8) & 31;
        t.i1 = (r >> 16) & 31;
        t.v0 = _random();
        t.v1 = _random();
    }

    function getUint8(uint256 index) public view returns (uint8 result) {
        result = uint8s[0].get(index);
    }

    function setUint8(uint256 index, uint8 value) public {
        uint8s[0].set(index, value);
    }

    function getUint8FromBigArray(uint256 index) public view returns (uint8 result) {
        result = bigUint8ArrayMap[index];
    }

    function setUint8FromBigArray(uint256 index, uint8 value) public {
        bigUint8ArrayMap[index] = value;
    }

    function testMapSetUint8() public {
        this.setUint8(111111, 123);
    }

    function testMapGetUint8() public {
        assertEq(this.getUint8(222222), uint8(0));
    }

    function testMapSetUint8FromBigArray() public {
        this.setUint8FromBigArray(111111, 123);
    }

    function testMapGetFromBigArray() public {
        assertEq(this.getUint8FromBigArray(222222), uint8(0));
    }

    function testUint8MapSetAndGet(uint256) public {
        uint8 u = uint8(_random());
        uint8s[0].set(0, u);
        assertEq(uint8s[0].map[0], u);
        unchecked {
            for (uint256 t; t < 8; ++t) {
                uint256 r = _random();
                uint8 casted;
                /// @solidity memory-safe-assembly
                assembly {
                    casted := r
                }
                uint256 index = _random() % 32;
                uint8s[0].set(index, casted);
                assertEq(uint8s[0].get(index), casted);
            }
        }
    }

    function testUint8MapSetAndGet() public {
        unchecked {
            for (uint256 t; t < 16; ++t) {
                uint256 n = 64;
                uint8 casted;
                uint256 r = _random();
                for (uint256 i; i < n; ++i) {
                    /// @solidity memory-safe-assembly
                    assembly {
                        casted := or(add(mul(n, t), i), r)
                    }
                    uint8s[0].set(i, casted);
                }
                for (uint256 i; i < n; ++i) {
                    /// @solidity memory-safe-assembly
                    assembly {
                        casted := or(add(mul(n, t), i), r)
                    }
                    assertEq(uint8s[0].get(i), casted);
                }
            }
        }
    }

    function testUint8MapSetAndGet2(uint256) public {
        _TestTemps memory t = _testTemps();
        uint8s[0].set(t.i0, uint8(t.v0));
        uint8s[1].set(t.i1, uint8(t.v1));
        assertEq(uint8s[0].get(t.i0), uint8(t.v0));
        assertEq(uint8s[1].get(t.i1), uint8(t.v1));
    }

    function testUint16MapSetAndGet(uint256) public {
        uint16 u = uint16(_random());
        uint16s[0].set(0, u);
        assertEq(uint16s[0].map[0], u);
        unchecked {
            for (uint256 t; t < 8; ++t) {
                uint256 r = _random();
                uint16 casted;
                /// @solidity memory-safe-assembly
                assembly {
                    casted := r
                }
                uint256 index = _random() % 32;
                uint16s[0].set(index, casted);
                assertEq(uint16s[0].get(index), casted);
            }
        }
    }

    function testUint16MapSetAndGet() public {
        unchecked {
            for (uint256 t; t < 16; ++t) {
                uint256 n = 64;
                uint16 casted;
                uint256 r = _random();
                for (uint256 i; i < n; ++i) {
                    /// @solidity memory-safe-assembly
                    assembly {
                        casted := or(add(mul(n, t), i), r)
                    }
                    uint16s[0].set(i, casted);
                }
                for (uint256 i; i < n; ++i) {
                    /// @solidity memory-safe-assembly
                    assembly {
                        casted := or(add(mul(n, t), i), r)
                    }
                    assertEq(uint16s[0].get(i), casted);
                }
            }
        }
    }

    function testUint16MapSetAndGet2(uint256) public {
        _TestTemps memory t = _testTemps();
        uint16s[0].set(t.i0, uint16(t.v0));
        uint16s[1].set(t.i1, uint16(t.v1));
        assertEq(uint16s[0].get(t.i0), uint16(t.v0));
        assertEq(uint16s[1].get(t.i1), uint16(t.v1));
    }

    function testUint32MapSetAndGet(uint256) public {
        uint32 u = uint32(_random());
        uint32s[0].set(0, u);
        assertEq(uint32s[0].map[0], u);
        unchecked {
            for (uint256 t; t < 8; ++t) {
                uint256 r = _random();
                uint32 casted;
                /// @solidity memory-safe-assembly
                assembly {
                    casted := r
                }
                uint256 index = _random() % 32;
                uint32s[0].set(index, casted);
                assertEq(uint32s[0].get(index), casted);
            }
        }
    }

    function testUint32MapSetAndGet() public {
        unchecked {
            for (uint256 t; t < 16; ++t) {
                uint256 n = 64;
                uint32 casted;
                uint256 r = _random();
                for (uint256 i; i < n; ++i) {
                    /// @solidity memory-safe-assembly
                    assembly {
                        casted := or(add(mul(n, t), i), r)
                    }
                    uint32s[0].set(i, casted);
                }
                for (uint256 i; i < n; ++i) {
                    /// @solidity memory-safe-assembly
                    assembly {
                        casted := or(add(mul(n, t), i), r)
                    }
                    assertEq(uint32s[0].get(i), casted);
                }
            }
        }
    }

    function testUint32MapSetAndGet2(uint256) public {
        _TestTemps memory t = _testTemps();
        uint32s[0].set(t.i0, uint32(t.v0));
        uint32s[1].set(t.i1, uint32(t.v1));
        assertEq(uint32s[0].get(t.i0), uint32(t.v0));
        assertEq(uint32s[1].get(t.i1), uint32(t.v1));
    }

    function testUint40MapSetAndGet(uint256) public {
        uint40 u = uint40(_random());
        uint40s[0].set(0, u);
        assertEq(uint40s[0].map[0], u);
        unchecked {
            for (uint256 t; t < 8; ++t) {
                uint256 r = _random();
                uint40 casted;
                /// @solidity memory-safe-assembly
                assembly {
                    casted := r
                }
                uint256 index = _random() % 32;
                uint40s[0].set(index, casted);
                assertEq(uint40s[0].get(index), casted);
            }
        }
    }

    function testUint40MapSetAndGet() public {
        unchecked {
            for (uint256 t; t < 16; ++t) {
                uint256 n = 64;
                uint40 casted;
                uint256 r = _random();
                for (uint256 i; i < n; ++i) {
                    /// @solidity memory-safe-assembly
                    assembly {
                        casted := or(add(mul(n, t), i), r)
                    }
                    uint40s[0].set(i, casted);
                }
                for (uint256 i; i < n; ++i) {
                    /// @solidity memory-safe-assembly
                    assembly {
                        casted := or(add(mul(n, t), i), r)
                    }
                    assertEq(uint40s[0].get(i), casted);
                }
            }
        }
    }

    function testUint40MapSetAndGet2(uint256) public {
        _TestTemps memory t = _testTemps();
        uint40s[0].set(t.i0, uint40(t.v0));
        uint40s[1].set(t.i1, uint40(t.v1));
        assertEq(uint40s[0].get(t.i0), uint40(t.v0));
        assertEq(uint40s[1].get(t.i1), uint40(t.v1));
    }

    function testUint64MapSetAndGet(uint256) public {
        uint64 u = uint64(_random());
        uint64s[0].set(0, u);
        assertEq(uint64s[0].map[0], u);
        unchecked {
            for (uint256 t; t < 8; ++t) {
                uint256 r = _random();
                uint64 casted;
                /// @solidity memory-safe-assembly
                assembly {
                    casted := r
                }
                uint256 index = _random() % 32;
                uint64s[0].set(index, casted);
                assertEq(uint64s[0].get(index), casted);
            }
        }
    }

    function testUint64MapSetAndGet() public {
        unchecked {
            for (uint256 t; t < 16; ++t) {
                uint256 n = 64;
                uint64 casted;
                uint256 r = _random();
                for (uint256 i; i < n; ++i) {
                    /// @solidity memory-safe-assembly
                    assembly {
                        casted := or(add(mul(n, t), i), r)
                    }
                    uint64s[0].set(i, casted);
                }
                for (uint256 i; i < n; ++i) {
                    /// @solidity memory-safe-assembly
                    assembly {
                        casted := or(add(mul(n, t), i), r)
                    }
                    assertEq(uint64s[0].get(i), casted);
                }
            }
        }
    }

    function testUint64MapSetAndGet2(uint256) public {
        _TestTemps memory t = _testTemps();
        uint64s[0].set(t.i0, uint64(t.v0));
        uint64s[1].set(t.i1, uint64(t.v1));
        assertEq(uint64s[0].get(t.i0), uint64(t.v0));
        assertEq(uint64s[1].get(t.i1), uint64(t.v1));
    }

    function testUint128MapSetAndGet(uint256) public {
        uint128 u = uint128(_random());
        uint128s[0].set(0, u);
        assertEq(uint128s[0].map[0], u);
        unchecked {
            for (uint256 t; t < 8; ++t) {
                uint256 r = _random();
                uint128 casted;
                /// @solidity memory-safe-assembly
                assembly {
                    casted := r
                }
                uint256 index = _random() % 32;
                uint128s[0].set(index, casted);
                assertEq(uint128s[0].get(index), casted);
            }
        }
    }

    function testUint128MapSetAndGet() public {
        unchecked {
            for (uint256 t; t < 16; ++t) {
                uint256 n = 64;
                uint128 casted;
                uint256 r = _random();
                for (uint256 i; i < n; ++i) {
                    /// @solidity memory-safe-assembly
                    assembly {
                        casted := or(add(mul(n, t), i), r)
                    }
                    uint128s[0].set(i, casted);
                }
                for (uint256 i; i < n; ++i) {
                    /// @solidity memory-safe-assembly
                    assembly {
                        casted := or(add(mul(n, t), i), r)
                    }
                    assertEq(uint128s[0].get(i), casted);
                }
            }
        }
    }

    function testUint128MapSetAndGet2(uint256) public {
        _TestTemps memory t = _testTemps();
        uint128s[0].set(t.i0, uint128(t.v0));
        uint128s[1].set(t.i1, uint128(t.v1));
        assertEq(uint128s[0].get(t.i0), uint128(t.v0));
        assertEq(uint128s[1].get(t.i1), uint128(t.v1));
    }

    function testUint32Maps(uint256) public {
        unchecked {
            uint256 a0 = _random();
            uint256 a1 = _random() % 2 == 0 ? a0 + _random() % 4 : a0 - _random() % 4;
            uint256 b0 = _random();
            uint256 b1 = _random() % 2 == 0 ? b0 + _random() % 4 : b0 - _random() % 4;
            if (a0 == a1 && b1 == b0) {
                if (_random() % 2 == 0) {
                    if (_random() % 2 == 0) b1++;
                    else a0++;
                } else {
                    if (_random() % 2 == 0) b1--;
                    else a0--;
                }
            }
            uint256 c0 = _random();
            uint256 c1 = _random();
            uint32 c0Casted;
            uint32 c1Casted;
            /// @solidity memory-safe-assembly
            assembly {
                c0Casted := c0
                c1Casted := c1
            }
            assertEq(uint32Maps[a0].get(b0), 0);
            assertEq(uint32Maps[a1].get(b1), 0);
            uint32Maps[a0].set(b0, c0Casted);
            uint32Maps[a1].set(b1, c1Casted);
            assertEq(uint32Maps[a0].get(b0), uint32(c0));
            assertEq(uint32Maps[a1].get(b1), uint32(c1));
        }
    }

    struct _SearchSortedTestVars {
        uint256 o;
        uint256 n;
        uint256 end;
        bool found;
        uint256 index;
        uint256 randomIndex;
        uint256 randomIndexValue;
        uint256[] values;
    }

    function _searchSortedTestVars(mapping(uint256 => uint256) storage map, uint256 bitWidth)
        internal
        returns (_SearchSortedTestVars memory t)
    {
        unchecked {
            t.n = 1 + _random() % 7 + (_random() % 8 == 0 ? _random() % 64 : 0);
            if (_random() % 2 == 0) {
                t.o = type(uint256).max - t.n;
                t.end = t.o + t.n;
                assertEq(t.end, type(uint256).max);
            } else {
                t.o = _random() % 4 + (_random() % 8 == 0 ? type(uint256).max - 256 : 0);
                t.end = t.o + t.n;
            }
            uint256 v = _random() % 4;
            uint256 b = (_random() % 2) * (_random() << 7);
            uint256 valueMask = (1 << bitWidth) - 1;
            for (uint256 i; i != t.n; ++i) {
                map.set(t.o + i, b | v, bitWidth);
                filled.set((b | v) & valueMask, 1, 1);
                v += 1 + _random() % 2;
            }
            t.randomIndex = t.o + _random() % t.n;
            t.randomIndexValue = map.get(t.randomIndex, bitWidth);

            if (t.o > 0) map.set(t.o - 1, _random(), bitWidth);
            if (t.end < type(uint256).max) map.set(t.end, _random(), bitWidth);

            uint256 notFoundValue = _generateNotFoundValue(t.o);

            (t.found, t.index) = map.searchSorted(notFoundValue, t.o, t.end, bitWidth);
            assertFalse(t.found);
            assertEq(t.index, _nearestIndexBefore(map, notFoundValue, t.o, t.n, bitWidth));

            uint256 end = t.o - (t.o > 0 ? _random() % t.o : 0);
            (t.found, t.index) = map.searchSorted(t.randomIndexValue, t.o, end, bitWidth);
            assertFalse(t.found);
            assertEq(t.index, t.o);

            (t.found, t.index) = map.searchSorted(t.randomIndexValue, t.o, t.end, bitWidth);
            assertTrue(t.found);
            assertEq(t.index, t.randomIndex);
        }
    }

    function _generateNotFoundValue(uint256 o) internal returns (uint256 notFoundValue) {
        unchecked {
            uint256 max = 32;
            do {
                notFoundValue = o + _random() % max;
                max += 8;
            } while (filled.get(notFoundValue, 1) == 1);
        }
    }

    function _nearestIndexBefore(
        mapping(uint256 => uint256) storage map,
        uint256 x,
        uint256 o,
        uint256 n,
        uint256 bitWidth
    ) internal view returns (uint256 nearestIndex) {
        unchecked {
            nearestIndex = o;
            uint256 nearestDist = type(uint256).max;
            for (uint256 i; i != n; ++i) {
                uint256 y = map.get(o + i, bitWidth);
                if (y > x) continue;
                uint256 dist = x - y;
                if (dist < nearestDist) {
                    nearestIndex = o + i;
                    nearestDist = dist;
                }
            }
        }
    }

    function testUint8MapSearchSorted(uint256) public {
        unchecked {
            LibMap.Uint8Map storage m = uint8s[0];
            _SearchSortedTestVars memory t = _searchSortedTestVars(m.map, 8);
            assertEq(m.get(t.randomIndex), t.randomIndexValue);
            (bool found, uint256 index) = m.searchSorted(uint8(t.randomIndexValue), t.o, t.end);
            assertTrue(found == t.found && index == t.index);
        }
    }

    function testUint16MapSearchSorted(uint256) public {
        unchecked {
            LibMap.Uint16Map storage m = uint16s[0];
            _SearchSortedTestVars memory t = _searchSortedTestVars(m.map, 16);
            assertEq(m.get(t.randomIndex), t.randomIndexValue);
            (bool found, uint256 index) = m.searchSorted(uint16(t.randomIndexValue), t.o, t.end);
            assertTrue(found == t.found && index == t.index);
        }
    }

    function testUint32MapSearchSorted(uint256) public {
        unchecked {
            LibMap.Uint32Map storage m = uint32s[0];
            _SearchSortedTestVars memory t = _searchSortedTestVars(m.map, 32);
            assertEq(m.get(t.randomIndex), t.randomIndexValue);
            (bool found, uint256 index) = m.searchSorted(uint32(t.randomIndexValue), t.o, t.end);
            assertTrue(found == t.found && index == t.index);
        }
    }

    function testUint40MapSearchSorted(uint256) public {
        unchecked {
            LibMap.Uint40Map storage m = uint40s[0];
            _SearchSortedTestVars memory t = _searchSortedTestVars(m.map, 40);
            assertEq(m.get(t.randomIndex), t.randomIndexValue);
            (bool found, uint256 index) = m.searchSorted(uint40(t.randomIndexValue), t.o, t.end);
            assertTrue(found == t.found && index == t.index);
        }
    }

    function testUint64MapSearchSorted(uint256) public {
        unchecked {
            LibMap.Uint64Map storage m = uint64s[0];
            _SearchSortedTestVars memory t = _searchSortedTestVars(m.map, 64);
            assertEq(m.get(t.randomIndex), t.randomIndexValue);
            (bool found, uint256 index) = m.searchSorted(uint64(t.randomIndexValue), t.o, t.end);
            assertTrue(found == t.found && index == t.index);
        }
    }

    function testUint128MapSearchSorted(uint256) public {
        unchecked {
            LibMap.Uint128Map storage m = uint128s[0];
            _SearchSortedTestVars memory t = _searchSortedTestVars(m.map, 128);
            assertEq(m.get(t.randomIndex), t.randomIndexValue);
            (bool found, uint256 index) = m.searchSorted(uint128(t.randomIndexValue), t.o, t.end);
            assertTrue(found == t.found && index == t.index);
        }
    }

    function testGeneralMapSearchSorted(uint256) public {
        unchecked {
            mapping(uint256 => uint256) storage m = generalMaps[0];
            uint256 bitWidth = _bound(_random(), 8, 256);
            _searchSortedTestVars(m, bitWidth);
        }
    }

    function testGeneralMapFunctionsWithSmallBitWidths(uint256) public {
        unchecked {
            uint256 bitWidth = 1 + _random() % 6;
            uint256 valueMask = (1 << bitWidth) - 1;
            uint256 o = _random() % 64 + (_random() % 8 == 0 ? type(uint256).max - 256 : 0);
            uint256 n = _random() % 9;
            for (uint256 k; k != 2; ++k) {
                for (uint256 i; i != n; ++i) {
                    uint256 j = o + i * 2;
                    generalMaps[k].set(j, _hash(j), bitWidth);
                }
            }
            for (uint256 k; k != 2; ++k) {
                for (uint256 i; i != n; ++i) {
                    uint256 j = o + i * 2 + 1;
                    generalMaps[k].set(j, _hash(j), bitWidth);
                }
            }
            for (uint256 k; k != 2; ++k) {
                for (uint256 i; i != n; ++i) {
                    uint256 j = o + i * 2;
                    assertEq(generalMaps[k].get(j, bitWidth), _hash(j) & valueMask);
                    j = j + 1;
                    assertEq(generalMaps[k].get(j, bitWidth), _hash(j) & valueMask);
                }
            }
        }
    }

    function _hash(uint256 x) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, x)
            result := keccak256(0x00, 0x20)
        }
    }

    function testGeneralMapFunctionsWithZeroBitWidth() public {
        unchecked {
            mapping(uint256 => uint256) storage m = generalMaps[0];
            for (uint256 j; j < 3; ++j) {
                for (uint256 i; i < 3; ++i) {
                    m.set(i, j + 1, 0);
                    assertEq(m.get(i, 0), 0);
                    (bool found, uint256 index) = m.searchSorted(i, j, j + 2, 0);
                    assertFalse(found);
                    assertEq(index, j);
                }
            }
        }
    }

    function testGeneralMapFunctionsGas() public {
        unchecked {
            mapping(uint256 => uint256) storage m = generalMaps[0];
            for (uint256 i; i != 1000; ++i) {
                m.set(i, i + 1, 32);
                assertEq(m.get(i, 32), i + 1);
            }
            for (uint256 j = 1; j < 900; j += 37) {
                (bool found, uint256 index) = m.searchSorted(j, 0, 1000, 32);
                assertTrue(found);
                assertEq(index, j - 1);
            }
        }
    }

    function testFoundStatementDifferential(uint256 t, uint256 needle, uint256 index) public {
        bool a;
        bool b;
        /// @solidity memory-safe-assembly
        assembly {
            a := and(eq(t, needle), iszero(iszero(index)))
            b := iszero(or(xor(t, needle), iszero(index)))
        }
        assertEq(a, b);
    }
}
