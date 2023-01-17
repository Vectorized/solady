// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/TestPlus.sol";
import {LibMap} from "../src/utils/LibMap.sol";

contract LibMapTest is TestPlus {
    using LibMap for *;

    uint8[0xffffffffffffffff] bigUint8ArrayMap;

    LibMap.Uint8Map uint8s;

    LibMap.Uint16Map uint16s;

    LibMap.Uint32Map uint32s;

    LibMap.Uint64Map uint64s;

    LibMap.Uint128Map uint128s;

    function getUint8(uint256 index) public view returns (uint8 result) {
        result = uint8s.get(index);
    }

    function setUint8(uint256 index, uint8 value) public {
        uint8s.set(index, value);
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
        uint8s.set(0, u);
        assertEq(uint8s.map[0], u);
        unchecked {
            for (uint256 t; t < 8; ++t) {
                uint256 r = _random();
                uint8 casted;
                /// @solidity memory-safe-assembly
                assembly {
                    casted := r
                }
                uint256 index = _random() % 32;
                uint8s.set(index, casted);
                assertEq(uint8s.get(index), casted);
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
                    uint8s.set(i, casted);
                }
                for (uint256 i; i < n; ++i) {
                    /// @solidity memory-safe-assembly
                    assembly {
                        casted := or(add(mul(n, t), i), r)
                    }
                    assertEq(uint8s.get(i), casted);
                }
            }
        }
    }

    function testUint16MapSetAndGet(uint256) public {
        uint16 u = uint16(_random());
        uint16s.set(0, u);
        assertEq(uint16s.map[0], u);
        unchecked {
            for (uint256 t; t < 8; ++t) {
                uint256 r = _random();
                uint16 casted;
                /// @solidity memory-safe-assembly
                assembly {
                    casted := r
                }
                uint256 index = _random() % 32;
                uint16s.set(index, casted);
                assertEq(uint16s.get(index), casted);
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
                    uint16s.set(i, casted);
                }
                for (uint256 i; i < n; ++i) {
                    /// @solidity memory-safe-assembly
                    assembly {
                        casted := or(add(mul(n, t), i), r)
                    }
                    assertEq(uint16s.get(i), casted);
                }
            }
        }
    }

    function testUint32MapSetAndGet(uint256) public {
        uint32 u = uint32(_random());
        uint32s.set(0, u);
        assertEq(uint32s.map[0], u);
        unchecked {
            for (uint256 t; t < 8; ++t) {
                uint256 r = _random();
                uint32 casted;
                /// @solidity memory-safe-assembly
                assembly {
                    casted := r
                }
                uint256 index = _random() % 32;
                uint32s.set(index, casted);
                assertEq(uint32s.get(index), casted);
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
                    uint32s.set(i, casted);
                }
                for (uint256 i; i < n; ++i) {
                    /// @solidity memory-safe-assembly
                    assembly {
                        casted := or(add(mul(n, t), i), r)
                    }
                    assertEq(uint32s.get(i), casted);
                }
            }
        }
    }

    function testUint64MapSetAndGet(uint256) public {
        uint64 u = uint64(_random());
        uint64s.set(0, u);
        assertEq(uint64s.map[0], u);
        unchecked {
            for (uint256 t; t < 8; ++t) {
                uint256 r = _random();
                uint64 casted;
                /// @solidity memory-safe-assembly
                assembly {
                    casted := r
                }
                uint256 index = _random() % 32;
                uint64s.set(index, casted);
                assertEq(uint64s.get(index), casted);
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
                    uint64s.set(i, casted);
                }
                for (uint256 i; i < n; ++i) {
                    /// @solidity memory-safe-assembly
                    assembly {
                        casted := or(add(mul(n, t), i), r)
                    }
                    assertEq(uint64s.get(i), casted);
                }
            }
        }
    }

    function testUint128MapSetAndGet(uint256) public {
        uint128 u = uint128(_random());
        uint128s.set(0, u);
        assertEq(uint128s.map[0], u);
        unchecked {
            for (uint256 t; t < 8; ++t) {
                uint256 r = _random();
                uint128 casted;
                /// @solidity memory-safe-assembly
                assembly {
                    casted := r
                }
                uint256 index = _random() % 32;
                uint128s.set(index, casted);
                assertEq(uint128s.get(index), casted);
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
                    uint128s.set(i, casted);
                }
                for (uint256 i; i < n; ++i) {
                    /// @solidity memory-safe-assembly
                    assembly {
                        casted := or(add(mul(n, t), i), r)
                    }
                    assertEq(uint128s.get(i), casted);
                }
            }
        }
    }
}
