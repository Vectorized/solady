// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {LibBit} from "../src/utils/LibBit.sol";

contract LibBitTest is SoladyTest {
    function testFLS() public {
        assertEq(LibBit.fls(0xff << 3), 10);
        for (uint256 i = 1; i < 255; i++) {
            assertEq(LibBit.fls((1 << i) - 1), i - 1);
            assertEq(LibBit.fls((1 << i)), i);
            assertEq(LibBit.fls((1 << i) + 1), i);
        }
        assertEq(LibBit.fls(0), 256);
    }

    function testCLZ() public {
        for (uint256 i = 1; i < 255; i++) {
            assertEq(LibBit.clz((1 << i) - 1), 255 - (i - 1));
            assertEq(LibBit.clz((1 << i)), 255 - i);
            assertEq(LibBit.clz((1 << i) + 1), 255 - i);
        }
        assertEq(LibBit.clz(0), 256);
    }

    function testFFS() public {
        assertEq(LibBit.ffs(0xff << 3), 3);
        uint256 brutalizer = uint256(keccak256(abi.encode(address(this), block.timestamp)));
        for (uint256 i = 0; i < 256; i++) {
            assertEq(LibBit.ffs(1 << i), i);
            assertEq(LibBit.ffs(type(uint256).max << i), i);
            assertEq(LibBit.ffs((brutalizer | 1) << i), i);
        }
        assertEq(LibBit.ffs(0), 256);
    }

    function testPopCount(uint256 x) public {
        uint256 c;
        unchecked {
            for (uint256 t = x; t != 0; c++) {
                t &= t - 1;
            }
        }
        assertEq(LibBit.popCount(x), c);
    }

    function testPopCount() public {
        unchecked {
            for (uint256 i = 1; i < 256; ++i) {
                assertEq(LibBit.popCount((1 << i) | 1), 2);
            }
        }
    }

    function testIsPo2(uint8 a, uint8 b) public {
        unchecked {
            uint256 x = (1 << uint256(a)) | (1 << uint256(b));
            if (a == b) {
                assertTrue(LibBit.isPo2(x));
            } else {
                assertFalse(LibBit.isPo2(x));
            }
        }
    }

    function testIsPo2(uint256 x) public {
        uint256 c;
        unchecked {
            for (uint256 t = x; t != 0; c++) {
                t &= t - 1;
            }
        }
        assertEq(LibBit.isPo2(x), c == 1);
    }

    function testIsPo2() public {
        assertFalse(LibBit.isPo2(0));
        assertFalse(LibBit.isPo2(type(uint256).max));
        unchecked {
            for (uint256 i; i < 256; ++i) {
                uint256 x = 1 << i;
                assertTrue(LibBit.isPo2(x));
                assertFalse(LibBit.isPo2(~x));
            }
        }
    }

    function testAnd(bool x, bool y) public {
        assertEq(LibBit.and(x, y), x && y);
        assertEq(LibBit.rawAnd(x, y), LibBit.and(x, y));
    }

    function testAnd() public {
        unchecked {
            for (uint256 t; t != 100; ++t) {
                uint256 i = _random();
                uint256 j = _random();
                uint256 k = _random();
                bool a = i < j;
                bool b = j < k;
                assertEq(LibBit.and(a, b), i < j && j < k);
            }
        }
    }

    function testOr(bool x, bool y) public {
        assertEq(LibBit.or(x, y), x || y);
        assertEq(LibBit.rawOr(x, y), LibBit.or(x, y));
    }

    function testOr() public {
        unchecked {
            for (uint256 t; t != 100; ++t) {
                uint256 i = _random();
                uint256 j = _random();
                uint256 k = _random();
                bool a = i < j;
                bool b = j < k;
                assertEq(LibBit.or(a, b), i < j || j < k);
            }
        }
    }

    function testAutoClean(uint256 x, uint256 y) public {
        bool xCasted;
        bool yCasted;
        /// @solidity memory-safe-assembly
        assembly {
            xCasted := x
            yCasted := y
        }
        bool result = LibBit.and(true, LibBit.or(xCasted, yCasted));
        assertEq(result, xCasted || yCasted);
    }

    function testReturnsBool() public {
        bool result;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x40b98a2f)
            mstore(0x20, 123)
            pop(staticcall(gas(), address(), 0x1c, 0x24, 0x00, 0x20))
            result := eq(mload(0x00), 1)
        }
        assertTrue(result);
    }

    function returnsBool(uint256 i) public pure returns (bool b) {
        /// @solidity memory-safe-assembly
        assembly {
            b := i
        }
    }

    function testPassInBool() public {
        bool result;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x59a3028a)
            mstore(0x20, 1)
            pop(staticcall(gas(), address(), 0x1c, 0x24, 0x00, 0x20))
            result := eq(mload(0x00), 1)
        }
        assertTrue(result);
    }

    function acceptsBool(bool) public pure returns (bool) {
        return true;
    }

    function testBoolToUint(bool b) public {
        uint256 z;
        /// @solidity memory-safe-assembly
        assembly {
            z := b
        }
        assertEq(LibBit.toUint(b), z);
        assertEq(LibBit.rawToUint(b), z);
    }

    function testReverseBitsDifferential(uint256 x) public {
        assertEq(LibBit.reverseBits(x), _reverseBitsOriginal(x));
    }

    function _reverseBitsOriginal(uint256 x) internal pure returns (uint256 r) {
        unchecked {
            for (uint256 i; i != 256; ++i) {
                r = (r << 1) | ((x >> i) & 1);
            }
        }
    }

    function testReverseBytesDifferential(uint256 x) public {
        assertEq(LibBit.reverseBytes(x), _reverseBytesOriginal(x));
    }

    function _reverseBytesOriginal(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            for { let i := 0 } lt(i, 32) { i := add(i, 1) } { mstore8(i, byte(sub(31, i), x)) }
            r := mload(0x00)
        }
    }
}
