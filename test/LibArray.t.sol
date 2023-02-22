// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/TestPlus.sol";
import {LibArray} from "../src/utils/LibArray.sol";

contract LibArrayTest is TestPlus {
    function testUnsignedSum() public {
        assertEq(LibArray.unsignedSum(_generateArray()), 169);
    }

    function testUnsignedMax() public {
        assertEq(LibArray.unsignedMax(_generateArray()), 140);
    }

    function testUnsignedMin() public {
        assertEq(LibArray.unsignedMin(_generateArray()), 0);
    }

    function testUnsignedMax(uint256[] memory arr) public {
        assertEq(LibArray.unsignedMax(arr), _bruteForceMax(arr));
    }

    function testUnsignedMin(uint256[] memory arr) public {
        assertEq(LibArray.unsignedMin(arr), _bruteForceMin(arr));
    }

    function _generateArray() internal returns (uint256[] memory) {
        uint256[] memory sampleArray = new uint256[](7);
        sampleArray[0] = 1;
        sampleArray[1] = 10;
        sampleArray[2] = 140;
        sampleArray[3] = 11;
        sampleArray[4] = 5;
        sampleArray[5] = 0;
        sampleArray[6] = 2;
        sampleArray[6] = 2;

        return sampleArray;
    }

    function _bruteForceMax(uint256[] memory arr) internal returns (uint256 max) {
        // default is 0
        if (arr.length == 0) {
            return 0;
        }

        for (uint256 i = 0; i < arr.length; ++i) {
            max = arr[i] > max ? arr[i] : max;
        }
    }

    function _bruteForceMin(uint256[] memory arr) internal returns (uint256 min) {
        // default is 0
        if (arr.length == 0) {
            return 0;
        }

        min = type(uint256).max;
        for (uint256 i = 0; i < arr.length; ++i) {
            min = arr[i] < min ? arr[i] : min;
        }
    }
}
