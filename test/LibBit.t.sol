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

    function testAnd(bool v, bool w, bool x, bool y) public {
        assertEq(LibBit.and(x, y), x && y);
        assertEq(LibBit.and(w, x, y), w && x && y);
        assertEq(LibBit.and(v, w, x, y), v && w && x && y);
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

    function testOr(bool v, bool w, bool x, bool y) public {
        assertEq(LibBit.or(x, y), x || y);
        assertEq(LibBit.or(w, x, y), w || x || y);
        assertEq(LibBit.or(v, w, x, y), v || w || x || y);
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

    function testCountZeroBytesDifferential(uint256 x) public {
        assertEq(LibBit.countZeroBytes(x), _countZeroBytesOriginal(x));
    }

    function testCountZeroBytes() public {
        uint256 x = 0xff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ff;
        x |= uint256(uint160(address(this))) << 16;
        assertEq(LibBit.countZeroBytes(x), 2);
    }

    function _countZeroBytesOriginal(uint256 x) internal pure returns (uint256 c) {
        unchecked {
            for (uint256 i; i < 32; ++i) {
                c += (x & (0xff << (i * 8))) == 0 ? 1 : 0;
            }
            return c;
        }
    }

    function testCountZeroBytesDifferential(bytes32) public {
        testCountZeroBytesDifferential(_randomSmallBytes());
    }

    function testCountZeroBytesDifferential(bytes memory s) public {
        assertEq(LibBit.countZeroBytes(s), _countZeroBytesOriginal(s));
    }

    function testCountZeroBytesCalldataDifferential(bytes32) public {
        this.testCountZeroBytesCalldataDifferential(_randomSmallBytes());
    }

    function testCountZeroBytesCalldataDifferential(bytes calldata s) public {
        assertEq(LibBit.countZeroBytesCalldata(s), _countZeroBytesOriginal(s));
    }

    function _countZeroBytesOriginal(bytes memory s) internal pure returns (uint256 c) {
        unchecked {
            for (uint256 i; i < s.length; ++i) {
                c += uint8(s[i]) == 0 ? 1 : 0;
            }
            return c;
        }
    }

    function _randomSmallBytes() internal returns (bytes memory) {
        uint256 n = _bound(_random(), 0, 100);
        uint256 r = _randomUniform();
        uint256 x = r >> 248;
        bytes memory s = new bytes(n);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, r)
            for { let i := 0 } lt(i, n) { i := add(i, 1) } {
                if and(1, shr(i, r)) { mstore8(add(add(s, 0x20), i), x) }
            }
        }
        return s;
    }

    function testToNibblesGas() public {
        bytes memory s = hex"123456789abcdef123456789abcdef123456789abcdef123456789abcdef";
        bytes memory expected =
            hex"0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f";
        assertEq(LibBit.toNibbles(s), expected);
    }

    function testToNibblesDifferential(uint256 r, bytes memory s) public {
        if (r & 0x01 == 0) {
            _brutalizeMemory();
            _misalignFreeMemoryPointer();
        }
        bytes memory computed = LibBit.toNibbles(s);
        _checkMemory(computed);
        assertEq(computed, _toNibblesOriginal(s));
    }

    // Original code from Optimism (MIT-licensed): https://github.com/ethereum-optimism/optimism/blob/1bfc93f7c1fe1846217795a1f6051e1b0260f597/packages/contracts-bedrock/src/libraries/Bytes.sol#L94
    function _toNibblesOriginal(bytes memory input) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            let bytesLength := mload(input)
            let nibblesLength := shl(0x01, bytesLength)
            mstore(0x40, add(result, and(not(0x1f), add(nibblesLength, 0x3f))))
            mstore(result, nibblesLength)
            let bytesStart := add(input, 0x20)
            let nibblesStart := add(result, 0x20)
            for { let i := 0x00 } lt(i, bytesLength) { i := add(i, 0x01) } {
                let offset := add(nibblesStart, shl(0x01, i))
                let b := byte(0x00, mload(add(bytesStart, i)))
                mstore8(offset, shr(0x04, b))
                mstore8(add(offset, 0x01), and(b, 0x0F))
            }
        }
    }
}
