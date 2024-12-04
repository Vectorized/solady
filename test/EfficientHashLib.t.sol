// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {EfficientHashLib} from "../src/utils/EfficientHashLib.sol";
import {LibString} from "../src/utils/LibString.sol";

contract EfficientHashLibTest is SoladyTest {
    using EfficientHashLib for bytes32[];

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
        assertEq(EfficientHashLib.hash(a[0], a[1]), _hash(encoded, 2));
        assertEq(EfficientHashLib.hash(a[0], a[1], a[2]), _hash(encoded, 3));
        assertEq(EfficientHashLib.hash(a[0], a[1], a[2], a[3]), _hash(encoded, 4));
        assertEq(EfficientHashLib.hash(a[0], a[1], a[2], a[3], a[4]), _hash(encoded, 5));
        assertEq(EfficientHashLib.hash(a[0], a[1], a[2], a[3], a[4], a[5]), _hash(encoded, 6));
        assertEq(EfficientHashLib.hash(a[0], a[1], a[2], a[3], a[4], a[5], a[6]), _hash(encoded, 7));
        assertEq(
            EfficientHashLib.hash(a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7]), _hash(encoded, 8)
        );
        _checkMemory();
        EfficientHashLib.free(a);
        _checkMemory();
        a = EfficientHashLib.malloc(1);
        assertEq(t, "01234567890123456789012345678901");
        EfficientHashLib.free(a);
        _checkMemory();
        assertEq(t, "01234567890123456789012345678901");
    }

    function testEfficientHashUints() public {
        uint256[] memory a = new uint256[](10);
        for (uint256 i; i < 10; ++i) {
            a[i] = i << 128;
        }
        bytes memory encoded = abi.encodePacked(a);
        assertEq(EfficientHashLib.hash(a[0]), _hash(encoded, 1));
        assertEq(EfficientHashLib.hash(a[0], a[1]), _hash(encoded, 2));
        assertEq(EfficientHashLib.hash(a[0], a[1], a[2]), _hash(encoded, 3));
        assertEq(EfficientHashLib.hash(a[0], a[1], a[2], a[3]), _hash(encoded, 4));
        assertEq(EfficientHashLib.hash(a[0], a[1], a[2], a[3], a[4]), _hash(encoded, 5));
        assertEq(EfficientHashLib.hash(a[0], a[1], a[2], a[3], a[4], a[5]), _hash(encoded, 6));
        assertEq(EfficientHashLib.hash(a[0], a[1], a[2], a[3], a[4], a[5], a[6]), _hash(encoded, 7));
        assertEq(
            EfficientHashLib.hash(a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7]), _hash(encoded, 8)
        );
    }

    function testEfficientHashSet() public {
        assertEq(
            EfficientHashLib.malloc(3).set(0, 1).set(1, 2).set(2, 3).hash(),
            keccak256(abi.encode(uint256(1), uint256(2), uint256(3)))
        );
        assertEq(
            EfficientHashLib.malloc(2).set(0, 1).set(1, 2).hash(),
            keccak256(abi.encode(uint256(1), uint256(2)))
        );
        assertEq(EfficientHashLib.malloc(1).set(0, 1).hash(), keccak256(abi.encode(uint256(1))));
        assertEq(EfficientHashLib.malloc(0).hash(), keccak256(""));
        assertEq(EfficientHashLib.malloc(0).hash(), keccak256(""));
        bytes32[] memory empty;
        assertEq(EfficientHashLib.hash(empty), keccak256(""));
    }

    function _hash(bytes memory encoded, uint256 n) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := keccak256(add(encoded, 0x20), shl(5, n))
        }
    }

    function testEfficientHashFree() public {
        uint256 mBefore = _fmp();
        bytes32[] memory buffer;
        EfficientHashLib.free(buffer);
        assertEq(mBefore, _fmp());
    }

    function testEfficientHashFree(uint8 n, bool b, uint8 t) public {
        if (b) EfficientHashLib.malloc(t | 1);
        uint256 mBefore = _fmp();
        bytes32[] memory buffer = EfficientHashLib.malloc(n | 1);
        assertGt(_fmp(), mBefore);
        EfficientHashLib.free(buffer);
        assertEq(mBefore, _fmp());
    }

    function _fmp() internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
        }
    }

    function testEfficientHashBytesSlice(bytes32, bytes calldata b) public {
        unchecked {
            uint256 n = b.length + 100;
            uint256 start = _bound(_random(), 0, n);
            uint256 end = _bound(_random(), 0, n);
            bytes memory bMem = b;
            if (b.length == 0 && _randomChance(2)) {
                /// @solidity memory-safe-assembly
                assembly {
                    bMem := 0x60
                }
            }
            bytes32 h;

            h = EfficientHashLib.hashCalldata(b);
            assertEq(h, keccak256(bMem));
            assertEq(EfficientHashLib.hash(bMem), h);

            h = EfficientHashLib.hashCalldata(b, start);
            assertEq(h, keccak256(bytes(LibString.slice(string(bMem), start))));
            assertEq(EfficientHashLib.hash(bMem, start), h);

            h = EfficientHashLib.hashCalldata(b, start, end);
            assertEq(h, keccak256(bytes(LibString.slice(string(bMem), start, end))));
            assertEq(EfficientHashLib.hash(bMem, start, end), h);

            _checkMemory();
        }
    }

    function testEfficientHashBytesSlice() public {
        this.testEfficientHashBytesSlice(bytes32(0), "0123456789");
    }

    function testEfficientHashEq(bytes32 a, uint256 n) public {
        bytes memory b = abi.encode(a);
        bytes memory s = abi.encode(a);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(s, mod(n, 0x20))
        }
        assertTrue(EfficientHashLib.eq(a, b));
        assertTrue(EfficientHashLib.eq(b, a));
        assertFalse(EfficientHashLib.eq(a, s));
        assertFalse(EfficientHashLib.eq(s, a));
    }

    function testEfficientHashEq() public {
        bytes32 a = 0x123456789a123456789a123456789a123456789a123456789a123456789a1234;
        bytes memory b = hex"123456789a123456789a123456789a123456789a123456789a123456789a1234";
        assertTrue(EfficientHashLib.eq(a, b));
        // The following costs approximately 90 more gas:
        // `assertTrue(a == abi.decode(b, (bytes32)))`;
    }

    function testSha2(bytes32 b) public {
        assertEq(sha256(abi.encode(b)), EfficientHashLib.sha2(b));
    }

    function testSha2(bytes calldata b) public {
        assertEq(sha256(b), EfficientHashLib.sha2(b));
        assertEq(sha256(b), EfficientHashLib.sha2Calldata(b));
    }

    function testSha2BytesSlice(bytes32, bytes calldata b) public {
        unchecked {
            uint256 n = b.length + 100;
            uint256 start = _bound(_random(), 0, n);
            uint256 end = _bound(_random(), 0, n);
            bytes memory bMem = b;
            if (b.length == 0 && _randomChance(2)) {
                /// @solidity memory-safe-assembly
                assembly {
                    bMem := 0x60
                }
            }
            bytes32 h;

            h = EfficientHashLib.sha2Calldata(b);
            assertEq(h, sha256(bMem));
            assertEq(EfficientHashLib.sha2(bMem), h);

            h = EfficientHashLib.sha2Calldata(b, start);
            assertEq(h, sha256(bytes(LibString.slice(string(bMem), start))));
            assertEq(EfficientHashLib.sha2(bMem, start), h);

            h = EfficientHashLib.sha2Calldata(b, start, end);
            assertEq(h, sha256(bytes(LibString.slice(string(bMem), start, end))));
            assertEq(EfficientHashLib.sha2(bMem, start, end), h);

            _checkMemory();
        }
    }

    function testEfficientHashMaxStack(uint256 x) public {
        unchecked {
            bytes32 computed = EfficientHashLib.hash(x, x, x, x, x, x, x, x, x, x, x, x, x, x);
            bytes32[] memory a = EfficientHashLib.malloc(14);
            for (uint256 i; i != 14; ++i) {
                EfficientHashLib.set(a, i, x);
            }
            assertEq(computed, EfficientHashLib.hash(a));
        }
    }

    function testEfficientHashMaxStack() public {
        bytes32 computed = EfficientHashLib.hash(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14);
        bytes32[] memory a = EfficientHashLib.malloc(14);
        for (uint256 i; i != 14; ++i) {
            EfficientHashLib.set(a, i, i + 1);
        }
        assertEq(computed, EfficientHashLib.hash(a));
    }
}
