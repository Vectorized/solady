// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {EfficientHashLib} from "../src/utils/EfficientHashLib.sol";

contract EfficientHashLibTest is SoladyTest {
    function testEfficientHash() public {
        testEfficientHash(0);
    }

    function testEfficientHash(uint256 x) public {
        string memory t = "01234567890123456789012345678901";
        _checkMemory();
        bytes32[] memory a = EfficientHashLib.malloc(10);
        _checkMemory();
        unchecked {
            for (uint256 i; i < 10; ++i) {
                EfficientHashLib.set(a, i, bytes32(x ^ (i << 128)));
            }
        }
        bytes memory encoded = abi.encodePacked(a);
        assertEq(EfficientHashLib.hash(a[0]), _hash(encoded, 1));
        assertEq(EfficientHashLib.hash(a, 1), _hash(encoded, 1));
        assertEq(EfficientHashLib.hash(a[0], a[1]), _hash(encoded, 2));
        assertEq(EfficientHashLib.hash(a[0], a[1], a[2]), _hash(encoded, 3));
        assertEq(EfficientHashLib.hash(a[0], a[1], a[2], a[3]), _hash(encoded, 4));
        assertEq(EfficientHashLib.hash(a[0], a[1], a[2], a[3], a[4]), _hash(encoded, 5));
        assertEq(EfficientHashLib.hash(a[0], a[1], a[2], a[3], a[4], a[5]), _hash(encoded, 6));
        assertEq(EfficientHashLib.hash(a[0], a[1], a[2], a[3], a[4], a[5], a[6]), _hash(encoded, 7));
        assertEq(
            EfficientHashLib.hash(a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7]), _hash(encoded, 8)
        );
        assertEq(EfficientHashLib.hash(a, 8), _hash(encoded, 8));
        _checkMemory();
        EfficientHashLib.free(a);
        _checkMemory();
        a = EfficientHashLib.malloc(1);
        assertEq(t, "01234567890123456789012345678901");
        EfficientHashLib.free(a);
        _checkMemory();
        assertEq(t, "01234567890123456789012345678901");
    }

    function _hash(bytes memory encoded, uint256 n) internal pure returns (bytes32 result) {
        assembly {
            result := keccak256(add(encoded, 0x20), shl(5, n))
        }
    }
}
