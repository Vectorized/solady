// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {DynamicArrayLib} from "src/utils/DynamicArrayLib.sol";

contract BugBountyTest is Test {
    using DynamicArrayLib for uint256[];

    function test_slice_zero_state_pointer() public {
        uint256[] memory arr = new uint256[](1);
        arr[0] = 123;
        
        // Corrupt the scratch space to simulate prior operations (e.g. hashing)
        assembly {
            mstore(0x00, 100) // fake length
            mstore(0x20, 999) // fake data
        }

        // Call slice with start == end, which skips allocation and returns a 0-pointer
        uint256[] memory emptySlice = arr.slice(1, 1);

        // emptySlice now points to 0x00. Its length reads from 0x00, which we set to 100!
        assertEq(emptySlice.length, 100, "Slice returned a 0-pointer reading from scratch space!");
        assertEq(emptySlice[0], 999, "Slice elements read from scratch space!");
    }
}
