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
}
