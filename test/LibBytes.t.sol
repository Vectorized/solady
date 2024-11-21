// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {LibBytes} from "../src/utils/LibBytes.sol";

contract LibBytesTest is SoladyTest {
    function testLoad(bytes memory a) public {
        if (a.length < 32) a = abi.encodePacked(a, new bytes(32));
        uint256 o = _bound(_random(), 0, a.length - 32);
        bytes memory expected = LibBytes.slice(a, o, o + 32);
        assertEq(abi.encode(LibBytes.load(a, o)), expected);
        this._testLoadCalldata(a);
    }

    function _testLoadCalldata(bytes calldata a) public {
        uint256 o = _bound(_random(), 0, a.length - 32);
        bytes memory expected = LibBytes.slice(a, o, o + 32);
        assertEq(abi.encode(LibBytes.loadCalldata(a, o)), expected);
    }

    function testTruncate(bytes memory a, uint256 n) public {
        bytes memory sliced = LibBytes.slice(a, 0, n);
        bytes memory truncated = LibBytes.truncate(a, n);
        assertEq(truncated, sliced);
        assertEq(a, sliced);
    }

    function testTruncatedCalldata(bytes calldata a, uint256 n) public {
        bytes memory sliced = LibBytes.slice(a, 0, n);
        bytes memory truncated = LibBytes.truncatedCalldata(a, n);
        assertEq(truncated, sliced);
    }
}
