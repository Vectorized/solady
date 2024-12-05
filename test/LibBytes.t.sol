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

    function testSliceCalldata(bytes calldata a, uint256 start, uint256 end) public {
        bytes memory aCopy = a;
        assertEq(LibBytes.sliceCalldata(a, start, end), LibBytes.slice(aCopy, start, end));
        assertEq(LibBytes.sliceCalldata(a, start), LibBytes.slice(aCopy, start));
    }

    function testSliceCalldata() public {
        bytes memory data = hex"12f712c77281c66267d947165237893ba5eca3e5481727fe76d4511ce1b564f5";
        this.testSliceCalldata(data, 1, 11);
    }

    function testEmptyCalldata() public {
        assertEq(LibBytes.emptyCalldata(), "");
    }

    function testDirectReturn() public {
        uint256 seed = 123;
        bytes[] memory expected = _generateBytesArray(seed);
        bytes[] memory computed = this.generateBytesArray(seed, false);
        unchecked {
            for (uint256 i; i != expected.length; ++i) {
                _checkMemory(computed[i]);
                assertEq(computed[i], expected[i]);
            }
            assertEq(computed.length, expected.length);
        }
    }

    function testDirectReturn(uint256 seed) public {
        bytes[] memory expected = _generateBytesArray(seed);
        (bool success, bytes memory encoded) = address(this).call(
            abi.encodeWithSignature("generateBytesArray(uint256,bool)", seed, true)
        );
        assertTrue(success);
        bytes[] memory computed;
        /// @solidity memory-safe-assembly
        assembly {
            let o := add(encoded, 0x20)
            computed := add(o, mload(o))
            for { let i := 0 } lt(i, mload(computed)) { i := add(i, 1) } {
                let c := add(add(0x20, computed), shl(5, i))
                mstore(c, add(add(0x20, computed), mload(c)))
            }
        }
        unchecked {
            for (uint256 i; i != expected.length; ++i) {
                _checkMemory(computed[i]);
                assertEq(computed[i], expected[i]);
            }
            assertEq(computed.length, expected.length);
        }
        if (seed & 0xf == 0) {
            assertEq(abi.encode(expected), abi.encode(this.generateBytesArray(seed, true)));
        }
    }

    function generateBytesArray(uint256 seed, bool brutalized)
        public
        view
        returns (bytes[] memory)
    {
        if (brutalized) {
            _misalignFreeMemoryPointer();
            _brutalizeMemory();
        }
        LibBytes.directReturn(_generateBytesArray(seed));
    }

    function _generateBytesArray(uint256 seed) internal pure returns (bytes[] memory a) {
        bytes memory before = "hehe";
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, seed)
            mstore(0x20, 0)
            function _next() -> _r {
                _r := keccak256(0x00, 0x40)
                mstore(0x20, _r)
            }
            function _nextBytes() -> _b {
                _b := mload(0x40)
                let n_ := and(_next(), 0x7f)
                mstore(_b, n_)
                for { let i_ := 0 } lt(i_, n_) { i_ := add(i_, 0x20) } {
                    mstore(add(add(_b, 0x20), i_), _next())
                }
                if and(1, _next()) {
                    mstore(0x40, add(n_, add(_b, 0x20)))
                    leave
                }
                mstore(add(n_, add(_b, 0x20)), 0)
                mstore(0x40, add(n_, add(_b, 0x40)))
            }
            let n := and(_next(), 7)
            a := mload(0x40)
            mstore(a, n)
            mstore(0x40, add(add(a, 0x20), shl(5, n)))
            for { let i := 0 } lt(i, n) { i := add(1, i) } {
                if iszero(and(7, _next())) {
                    mstore(add(add(a, 0x20), shl(5, i)), before)
                    continue
                }
                mstore(add(add(a, 0x20), shl(5, i)), _nextBytes())
            }
        }
    }
}
