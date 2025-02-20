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

    function testCmp() public {
        assertEq(LibBytes.cmp("", ""), 0);
        assertEq(LibBytes.cmp("abc", "abc"), 0);
        assertEq(LibBytes.cmp("abcd", "abc"), 1);
        assertEq(LibBytes.cmp("abb", "abc"), -1);
        assertEq(
            LibBytes.cmp(
                "0123456789012345678901234567890123456789abb",
                "0123456789012345678901234567890123456789abc"
            ),
            -1
        );
    }

    function testCmpDifferential(bytes memory a, bytes memory b) public {
        if (_randomChance(32)) {
            _misalignFreeMemoryPointer();
            _brutalizeMemory();
        }
        if (_randomChance(256)) {
            a = b;
        }
        if (_randomChance(16)) {
            a = abi.encodePacked(a, b);
        }
        if (_randomChance(16)) {
            b = abi.encodePacked(b, a);
        }
        bytes32 aHash = keccak256(a);
        bytes32 bHash = keccak256(b);
        if (_randomChance(8)) {
            a = _brutalizeRightPadding(a);
        }
        if (_randomChance(8)) {
            b = _brutalizeRightPadding(b);
        }
        int256 computed = LibBytes.cmp(a, b);
        int256 expected = cmpOriginal(a, b);
        assertEq(computed, expected);
        assertEq(keccak256(a), aHash);
        assertEq(keccak256(b), bHash);
    }

    struct SampleDynamicStruct {
        address user;
        uint256 nonce;
        bytes data;
    }

    function testDynamicStructInCalldata() public {
        SampleDynamicStruct memory u;
        u.user = address(1);
        u.nonce = 123;
        u.data = "hehe";
        bytes memory encoded = abi.encode(u);
        this._testDynamicStructInCalldata(encoded, 0x00, u.user, u.nonce, keccak256(u.data));
    }

    function testDynamicStructInCalldata(bytes32) public {
        SampleDynamicStruct memory u;
        u.user = _randomHashedAddress();
        u.nonce = _randomUniform();
        u.data = _truncateBytes(_randomBytes(), 100);
        bytes memory encoded;
        encoded = abi.encode(u);
        this._testDynamicStructInCalldata(encoded, 0x00, u.user, u.nonce, keccak256(u.data));
        encoded = abi.encode(uint256(1), u);
        this._testDynamicStructInCalldata(encoded, 0x20, u.user, u.nonce, keccak256(u.data));
        encoded = abi.encode(uint256(1), uint256(2), u);
        if (_randomChance(32)) encoded = abi.encodePacked(encoded, _randomBytes());
        this._testDynamicStructInCalldata(encoded, 0x40, u.user, u.nonce, keccak256(u.data));
    }

    function _testDynamicStructInCalldata(
        bytes calldata encoded,
        uint256 offset,
        address expectedUser,
        uint256 expectedNonce,
        bytes32 expectedDataHash
    ) public {
        bytes calldata p = LibBytes.dynamicStructInCalldata(encoded, offset);
        assertEq(uint256(LibBytes.loadCalldata(p, 0x00)), uint160(expectedUser));
        assertEq(uint256(LibBytes.loadCalldata(p, 0x20)), expectedNonce);
        assertEq(keccak256(LibBytes.bytesInCalldata(p, 0x40)), expectedDataHash);
    }

    function testBytesInCalldata() public {
        bytes memory encoded = abi.encode("hello");
        this._testBytesInCalldata(encoded, 0x00, keccak256("hello"));
    }

    function testBytesInCalldata(bytes32) public {
        bytes memory u = _truncateBytes(_randomBytes(), 100);
        bytes memory encoded;
        encoded = abi.encode(u);
        this._testBytesInCalldata(encoded, 0x00, keccak256(u));
        encoded = abi.encode(uint256(1), u);
        this._testBytesInCalldata(encoded, 0x20, keccak256(u));
        if (_randomChance(16)) {
            encoded = abi.encode(uint256(1), uint256(2), u);
            if (_randomChance(32)) encoded = abi.encodePacked(encoded, _randomBytes());
            this._testBytesInCalldata(encoded, 0x40, keccak256(u));
        }
    }

    function _testBytesInCalldata(bytes calldata encoded, uint256 offset, bytes32 expectedHash)
        public
    {
        assertEq(keccak256(LibBytes.bytesInCalldata(encoded, offset)), expectedHash);
    }

    function _brutalizeRightPadding(bytes memory s) internal returns (bytes memory result) {
        uint256 n = s.length;
        result = abi.encodePacked(s, _randomUniform(), _randomUniform());
        /// @solidity memory-safe-assembly
        assembly {
            mstore(result, n)
        }
    }

    function cmpOriginal(bytes memory a, bytes memory b) internal pure returns (int256) {
        uint256 minLen = a.length < b.length ? a.length : b.length;
        for (uint256 i; i < minLen; ++i) {
            uint8 x = uint8(a[i]);
            uint8 y = uint8(b[i]);
            if (x < y) return -1;
            if (x > y) return 1;
        }
        if (a.length < b.length) return -1;
        if (a.length > b.length) return 1;
        return 0;
    }
}
