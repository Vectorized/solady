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

    function testReverseBits() public {
        uint256 x = 0xf2e857a5b8e3fec9f9c60ae71ba63813c96741bc837169cf0f29f113ede5956f;
        uint256 r = 0xf6a9a7b7c88f94f0f3968ec13d82e693c81c65d8e750639f937fc71da5ea174f;
        assertEq(LibBit.reverseBits(x), r);
        unchecked {
            for (uint256 i; i < 256; ++i) {
                assertEq(LibBit.reverseBits(1 << i), (1 << 255) >> i);
            }
        }
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

    function testReverseBytes() public {
        uint256 x = 0x112233445566778899aa112233445566778899aa112233445566778899aa1122;
        uint256 r = 0x2211aa998877665544332211aa998877665544332211aa998877665544332211;
        assertEq(LibBit.reverseBytes(x), r);
        unchecked {
            for (uint256 i; i < 256; i += 8) {
                assertEq(LibBit.reverseBytes(0xff << i), (0xff << 248) >> i);
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

    function testCommonNibblePrefix() public {
        assertEq(LibBit.commonNibblePrefix(0x1, 0x2), 0);
        assertEq(LibBit.commonNibblePrefix(0x1234abc, 0x1234bbb), 0x1234000);
        assertEq(LibBit.commonNibblePrefix(0x1234abc, 0x1234abc), 0x1234abc);
    }

    function testCommonNibblePrefixDifferential(uint256 x, uint256 y) public {
        assertEq(LibBit.commonNibblePrefix(x, y), _commonNibblePrefixOriginal(x, y));
    }

    function _commonNibblePrefixOriginal(uint256 x, uint256 y) internal pure returns (uint256 z) {
        uint256 m = 0xf000000000000000000000000000000000000000000000000000000000000000;
        while (m != 0) {
            if ((x & m) == (y & m)) z |= x & m;
            else break;
            m >>= 4;
        }
    }

    function testCommonBytePrefix() public {
        assertEq(LibBit.commonBytePrefix(0xaabbcc, 0xaabbcc), 0xaabbcc);
        assertEq(LibBit.commonBytePrefix(0xaabbcc, 0xaabbc0), 0xaabb00);
        assertEq(LibBit.commonBytePrefix(0xaabbcc, 0xaab0c0), 0xaa0000);
        assertEq(LibBit.commonBytePrefix(0xaabbcc, 0xa0b0c0), 0x000000);
    }

    function testCommonBytePrefixDifferential(uint256 x, uint256 y) public {
        assertEq(LibBit.commonBytePrefix(x, y), _commonBytePrefixOriginal(x, y));
    }

    function _commonBytePrefixOriginal(uint256 x, uint256 y) internal pure returns (uint256 z) {
        uint256 m = 0xff00000000000000000000000000000000000000000000000000000000000000;
        while (m != 0) {
            if ((x & m) == (y & m)) z |= x & m;
            else break;
            m >>= 8;
        }
    }

    function testCommonBitPrefixDifferential(uint256 x, uint256 y) public {
        assertEq(LibBit.commonBitPrefix(x, y), _commonBitPrefixOriginal(x, y));
    }

    function _commonBitPrefixOriginal(uint256 x, uint256 y) internal pure returns (uint256 z) {
        uint256 m = 0x8000000000000000000000000000000000000000000000000000000000000000;
        while (m != 0) {
            if ((x & m) == (y & m)) z |= x & m;
            else break;
            m >>= 1;
        }
    }
}
