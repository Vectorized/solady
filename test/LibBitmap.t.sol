// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {LibBitmap} from "../src/utils/LibBitmap.sol";

contract LibBitmapTest is Test {
    using LibBitmap for LibBitmap.Bitmap;

    error AlreadyClaimed();

    mapping(uint256 => LibBitmap.Bitmap) bitmaps;

    uint256 currentBitmapIndex;

    function setUp() public {
        ++currentBitmapIndex;
    }

    function get(uint256 index) public view returns (bool result) {
        result = bitmaps[currentBitmapIndex].get(index);
    }

    function set(uint256 index) public {
        bitmaps[currentBitmapIndex].set(index);
    }

    function unset(uint256 index) public {
        bitmaps[currentBitmapIndex].unset(index);
    }

    function toggle(uint256 index) public {
        bitmaps[currentBitmapIndex].toggle(index);
    }

    function setTo(uint256 index, bool shouldSet) public {
        bitmaps[currentBitmapIndex].setTo(index, shouldSet);
    }

    function claimWithGetSet(uint256 index) public {
        if (bitmaps[currentBitmapIndex].get(index)) {
            revert AlreadyClaimed();
        }
        bitmaps[currentBitmapIndex].set(index);
    }

    function claimWithToggle(uint256 index) public {
        if (bitmaps[currentBitmapIndex].toggle(index) == false) {
            revert AlreadyClaimed();
        }
    }

    function testBitmapGet() public {
        testBitmapGet(123);
    }

    function testBitmapGet(uint256 index) public {
        assertFalse(get(index));
    }

    function testBitmapSet() public {
        testBitmapSet(123);
    }

    function testBitmapSet(uint256 index) public {
        set(index);
        assertTrue(get(index));
    }

    function testBitmapUnset() public {
        testBitmapSet(123);
    }

    function testBitmapUnset(uint256 index) public {
        set(index);
        assertTrue(get(index));
        unset(index);
        assertFalse(get(index));
    }

    function testBitmapSetTo() public {
        testBitmapSetTo(123, true, 0);
        testBitmapSetTo(123, false, 0);
    }

    function testBitmapSetTo(uint256 index, bool shouldSet, uint256 brutalizer) public {
        bool shouldSetBrutalized;
        assembly {
            shouldSetBrutalized := shl(and(brutalizer, 0xff), shouldSet)
        }
        setTo(index, shouldSetBrutalized);
        assertEq(get(index), shouldSet);
    }

    function testBitmapToggle() public {
        testBitmapToggle(123, true);
        testBitmapToggle(321, false);
    }

    function testBitmapToggle(uint256 index, bool initialValue) public {
        setTo(index, initialValue);
        assertEq(get(index), initialValue);
        toggle(index);
        assertEq(get(index), !initialValue);
    }

    function testBitmapClaimWithGetSet() public {
        uint256 index = 123;
        this.claimWithGetSet(index);
        vm.expectRevert(AlreadyClaimed.selector);
        this.claimWithGetSet(index);
    }

    function testBitmapClaimWithToggle() public {
        uint256 index = 123;
        this.claimWithToggle(index);
        vm.expectRevert(AlreadyClaimed.selector);
        this.claimWithToggle(index);
    }
}
