// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {LibBit} from "../src/utils/LibBit.sol";

contract LibBitTest is Test {
    function testFuzzFLS() public {
        for (uint256 i = 1; i < 255; i++) {
            assertEq(LibBit.fls((1 << i) - 1), i - 1);
            assertEq(LibBit.fls((1 << i)), i);
            assertEq(LibBit.fls((1 << i) + 1), i);
        }
        assertEq(LibBit.fls(0), 256);
    }

    function testFLS() public {
        assertEq(LibBit.fls(0xff << 3), 10);
    }

    function testFuzzCLZ() public {
        for (uint256 i = 1; i < 255; i++) {
            assertEq(LibBit.clz((1 << i) - 1), 255 - (i - 1));
            assertEq(LibBit.clz((1 << i)), 255 - i);
            assertEq(LibBit.clz((1 << i) + 1), 255 - i);
        }
        assertEq(LibBit.clz(0), 256);
    }

    function testFuzzFFS() public {
        uint256 brutalizer = uint256(keccak256(abi.encode(address(this), block.timestamp)));
        for (uint256 i = 0; i < 256; i++) {
            assertEq(LibBit.ffs(1 << i), i);
            assertEq(LibBit.ffs(type(uint256).max << i), i);
            assertEq(LibBit.ffs((brutalizer | 1) << i), i);
        }
        assertEq(LibBit.ffs(0), 256);
    }

    function testFFS() public {
        assertEq(LibBit.ffs(0xff << 3), 3);
    }

    function testFuzzPopCount(uint256 x) public {
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

    function testFuzzIsPo2(uint8 a, uint8 b) public {
        unchecked {
            uint256 x = (1 << uint256(a)) | (1 << uint256(b));
            if (a == b) {
                assertTrue(LibBit.isPo2(x));
            } else {
                assertFalse(LibBit.isPo2(x));
            }
        }
    }

    function testFuzzIsPo2(uint256 x) public {
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
}
