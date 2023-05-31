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
    }

    function testOr(bool x, bool y) public {
        assertEq(LibBit.or(x, y), x || y);
    }

    function testBoolToUint(bool b) public {
        uint256 z;
        /// @solidity memory-safe-assembly
        assembly {
            z := b
        }
        assertEq(LibBit.toUint(b), z);
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
