// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {LibBytemap} from "../src/utils/LibBytemap.sol";

contract LibBytemapTest is Test {
    using LibBytemap for LibBytemap.Bytemap;

    LibBytemap.Bytemap bytemap;

    uint8[0xffffffffffffffff] bigArrayBytemap;

    function get(uint256 index) public view returns (uint8 result) {
        result = bytemap.get(index);
    }

    function set(uint256 index, uint8 value) public {
        bytemap.set(index, value);
    }

    function getBigArray(uint256 index) public view returns (uint8 result) {
        result = bigArrayBytemap[index];
    }

    function setBigArray(uint256 index, uint8 value) public {
        bigArrayBytemap[index] = value;
    }

    function testBytemapSetAndGet(
        uint256 index,
        uint8 value,
        uint256 brutalizer
    ) public {
        assembly {
            value := or(shl(8, brutalizer), value)
        }

        set(index, value);
        uint8 result = get(index);

        assertEq(result, value);

        bool resultEqualValue;
        assembly {
            resultEqualValue := eq(result, and(value, 0xff))
        }
        assertTrue(resultEqualValue);
    }

    function testBytemapSet() public {
        this.set(111111, 123);
    }

    function testBytemapGet() public {
        assertEq(this.get(222222), uint8(0));
    }

    function testBytemapSetBigArray() public {
        this.setBigArray(111111, 123);
    }

    function testBytemapGetBigArray() public {
        assertEq(this.getBigArray(222222), uint8(0));
    }
}
