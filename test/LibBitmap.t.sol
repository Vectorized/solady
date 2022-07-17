// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {MockLibBitmap} from "./utils/mocks/MockLibBitmap.sol";

contract LibBitmapTest is Test {
    MockLibBitmap mockLibBitmap;

    function setUp() public {
        mockLibBitmap = new MockLibBitmap();
    }

    function testBitmapGet() public {
        testBitmapGet(123);
    }

    function testBitmapGet(uint256 index) public {
        assertFalse(mockLibBitmap.get(index));
    }

    function testBitmapSet() public {
        testBitmapSet(123);
    }

    function testBitmapSet(uint256 index) public {
        mockLibBitmap.set(index);
        assertTrue(mockLibBitmap.get(index));
    }

    function testBitmapUnset() public {
        testBitmapSet(123);
    }

    function testBitmapUnset(uint256 index) public {
        mockLibBitmap.set(index);
        assertTrue(mockLibBitmap.get(index));
        mockLibBitmap.unset(index);
        assertFalse(mockLibBitmap.get(index));
    }

    function testBitmapSetTo() public {
        testBitmapSetTo(123, true);
        testBitmapSetTo(123, false);
    }

    function testBitmapSetTo(uint256 index, bool shouldSet) public {
        mockLibBitmap.setTo(index, shouldSet);
        assertEq(mockLibBitmap.get(index), shouldSet);
    }

    function testBitmapToggle() public {
        testBitmapToggle(123, true);
        testBitmapToggle(321, false);
    }

    function testBitmapToggle(uint256 index, bool initialValue) public {
        mockLibBitmap.setTo(index, initialValue);
        assertEq(mockLibBitmap.get(index), initialValue);
        mockLibBitmap.toggle(index);
        assertEq(mockLibBitmap.get(index), !initialValue);
    }
}
