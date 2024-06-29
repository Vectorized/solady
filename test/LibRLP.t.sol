// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {LibRLP} from "../src/utils/LibRLP.sol";
import {FixedPointMathLib} from "../src/utils/FixedPointMathLib.sol";

contract LibRLPTest is SoladyTest {
    using LibRLP for LibRLP.List;

    function testComputeAddressDifferential(address deployer, uint256 nonce) public {
        assertEq(LibRLP.computeAddress(deployer, nonce), computeAddressOriginal(deployer, nonce));
    }

    function testComputeAddressForSmallNonces() public {
        address deployer = address(1);
        assertTrue(LibRLP.computeAddress(deployer, 1) != address(0));
        assertTrue(LibRLP.computeAddress(deployer, 0x7f) != address(0));
        assertTrue(LibRLP.computeAddress(deployer, 0xff) != address(0));
    }

    function testComputeAddressOriginalForSmallNonces() public {
        address deployer = address(1);
        assertTrue(computeAddressOriginal(deployer, 1) != address(0));
        assertTrue(computeAddressOriginal(deployer, 0x7f) != address(0));
        assertTrue(computeAddressOriginal(deployer, 0xff) != address(0));
    }

    function testComputeAddressForLargeNonces() public {
        address deployer = address(1);
        assertTrue(LibRLP.computeAddress(deployer, 0xffffffff) != address(0));
        assertTrue(LibRLP.computeAddress(deployer, 0xffffffffffffff) != address(0));
        assertTrue(LibRLP.computeAddress(deployer, 0xffffffffffffffff) != address(0));
    }

    function testComputeAddressOriginalForLargeNonces() public {
        address deployer = address(1);
        assertTrue(computeAddressOriginal(deployer, 0xffffffff) != address(0));
        assertTrue(computeAddressOriginal(deployer, 0xffffffffffffff) != address(0));
        assertTrue(computeAddressOriginal(deployer, 0xffffffffffffffff) != address(0));
    }

    function computeAddressOriginal(address deployer, uint256 nonce)
        internal
        pure
        returns (address)
    {
        // Although the theoretical allowed limit, based on EIP-2681,
        // for an account nonce is 2**64-2: https://eips.ethereum.org/EIPS/eip-2681,
        // we just test all the way to 2**256-1 to ensure that the computeAddress function does not revert
        // for whatever nonce we provide.

        // forgefmt: disable-next-item
        {
            if (nonce == 0x00) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployer, bytes1(0x80))))));
            if (nonce <= 0x7f) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployer, uint8(nonce))))));
            if (nonce <= type(uint8).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd7), bytes1(0x94), deployer, bytes1(0x81), uint8(nonce))))));
            if (nonce <= type(uint16).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd8), bytes1(0x94), deployer, bytes1(0x82), uint16(nonce))))));
            if (nonce <= type(uint24).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd9), bytes1(0x94), deployer, bytes1(0x83), uint24(nonce))))));
            if (nonce <= type(uint32).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xda), bytes1(0x94), deployer, bytes1(0x84), uint32(nonce))))));
            if (nonce <= type(uint40).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xdb), bytes1(0x94), deployer, bytes1(0x85), uint40(nonce))))));
            if (nonce <= type(uint48).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xdc), bytes1(0x94), deployer, bytes1(0x86), uint48(nonce))))));
            if (nonce <= type(uint56).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xdd), bytes1(0x94), deployer, bytes1(0x87), uint56(nonce))))));
            if (nonce <= type(uint64).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xde), bytes1(0x94), deployer, bytes1(0x88), uint64(nonce))))));
            if (nonce <= type(uint72).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xdf), bytes1(0x94), deployer, bytes1(0x89), uint72(nonce))))));
            if (nonce <= type(uint80).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xe0), bytes1(0x94), deployer, bytes1(0x8a), uint80(nonce))))));
            if (nonce <= type(uint88).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xe1), bytes1(0x94), deployer, bytes1(0x8b), uint88(nonce))))));
            if (nonce <= type(uint96).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xe2), bytes1(0x94), deployer, bytes1(0x8c), uint96(nonce))))));
            if (nonce <= type(uint104).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xe3), bytes1(0x94), deployer, bytes1(0x8d), uint104(nonce))))));
            if (nonce <= type(uint112).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xe4), bytes1(0x94), deployer, bytes1(0x8e), uint112(nonce))))));
            if (nonce <= type(uint120).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xe5), bytes1(0x94), deployer, bytes1(0x8f), uint120(nonce))))));
            if (nonce <= type(uint128).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xe6), bytes1(0x94), deployer, bytes1(0x90), uint128(nonce))))));
            if (nonce <= type(uint136).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xe7), bytes1(0x94), deployer, bytes1(0x91), uint136(nonce))))));
            if (nonce <= type(uint144).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xe8), bytes1(0x94), deployer, bytes1(0x92), uint144(nonce))))));
            if (nonce <= type(uint152).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xe9), bytes1(0x94), deployer, bytes1(0x93), uint152(nonce))))));
            if (nonce <= type(uint160).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xea), bytes1(0x94), deployer, bytes1(0x94), uint160(nonce))))));
            if (nonce <= type(uint168).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xeb), bytes1(0x94), deployer, bytes1(0x95), uint168(nonce))))));
            if (nonce <= type(uint176).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xec), bytes1(0x94), deployer, bytes1(0x96), uint176(nonce))))));
            if (nonce <= type(uint184).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xed), bytes1(0x94), deployer, bytes1(0x97), uint184(nonce))))));
            if (nonce <= type(uint192).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xee), bytes1(0x94), deployer, bytes1(0x98), uint192(nonce))))));
            if (nonce <= type(uint200).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xef), bytes1(0x94), deployer, bytes1(0x99), uint200(nonce))))));
            if (nonce <= type(uint208).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xf0), bytes1(0x94), deployer, bytes1(0x9a), uint208(nonce))))));
            if (nonce <= type(uint216).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xf1), bytes1(0x94), deployer, bytes1(0x9b), uint216(nonce))))));
            if (nonce <= type(uint224).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xf2), bytes1(0x94), deployer, bytes1(0x9c), uint224(nonce))))));
            if (nonce <= type(uint232).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xf3), bytes1(0x94), deployer, bytes1(0x9d), uint232(nonce))))));
            if (nonce <= type(uint240).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xf4), bytes1(0x94), deployer, bytes1(0x9e), uint240(nonce))))));
            if (nonce <= type(uint248).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xf5), bytes1(0x94), deployer, bytes1(0x9f), uint248(nonce))))));
            if (nonce <= type(uint256).max) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xf6), bytes1(0x94), deployer, bytes1(0xa0), uint256(nonce))))));
        }
        revert();
    }

    function testRLPPUint256() public {
        _testRLPPUint256(0);
        _testRLPPUint256(1);
        _testRLPPUint256(1 << 255);
    }

    function _testRLPPUint256(uint256 x) internal {
        LibRLP.List memory l;
        unchecked {
            for (uint256 i; i != 32; ++i) {
                uint256 y = x ^ i;
                l.p(y);
                _checkMemory();
                assertEq(_getUint256(l, i), y);
            }
            for (uint256 i; i != 32; ++i) {
                uint256 y = x ^ i;
                assertEq(_getUint256(l, i), y);
            }
        }
    }

    function _getUint256(LibRLP.List memory l, uint256 i) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0)
            let head := and(mload(l), 0xffffffffff)
            if head {
                for { let j := 0 } iszero(eq(j, i)) { j := add(j, 1) } {
                    head := and(mload(head), 0xffffffffff)
                }
                result := shr(48, mload(head))
                if eq(1, byte(26, mload(head))) { result := mload(result) }
            }
        }
    }

    function testRLPEncodeBytes() public {
        bytes memory s;
        assertEq(LibRLP.encode(""), hex"80");
        s = "dog";
        assertEq(LibRLP.encode(s), abi.encodePacked(hex"83", s));
        assertEq(LibRLP.encode(hex"00"), hex"00");
        assertEq(LibRLP.encode(hex"0f"), hex"0f");
        assertEq(LibRLP.encode(hex"0400"), hex"820400");
        s = "Lorem ipsum dolor sit amet, consectetur adipisicing eli";
        assertEq(LibRLP.encode(s), abi.encodePacked(hex"b7", s));
        s = "Lorem ipsum dolor sit amet, consectetur adipisicing elit";
        assertEq(LibRLP.encode(s), abi.encodePacked(hex"b838", s));
        s = new bytes(0x100);
        assertEq(LibRLP.encode(s), abi.encodePacked(hex"b90100", s));
        s = new bytes(0xfffe);
        assertEq(LibRLP.encode(s), abi.encodePacked(hex"b9fffe", s));
    }

    function testRLPEncodeBytesDifferential(bytes memory x) public {
        bytes memory computed = LibRLP.encode(x);
        _checkMemory();
        assertEq(computed, _encode(x));
        assertEq(computed, _encodeSimple(x));
        _checkMemory();
    }

    function testRLPEncodeBytesDifferential() public {
        bytes memory x;
        testRLPEncodeBytesDifferential(x);
    }

    function testRLPEncodeUintDifferential(uint256 x) public {
        bytes memory computed = LibRLP.encode(x);
        _checkMemory();
        assertEq(computed, _encode(x));
        assertEq(computed, _encodeSimple(x));
        _checkMemory();
    }

    function _encode(uint256 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            function encodeUint(x_, o_) -> _o {
                _o := add(o_, 1)
                if iszero(gt(x_, 0x7f)) {
                    mstore8(o_, or(x_, shl(7, iszero(x_)))) // Copy `x_`.
                    leave
                }
                let r_ := shl(7, lt(0xffffffffffffffffffffffffffffffff, x_))
                r_ := or(r_, shl(6, lt(0xffffffffffffffff, shr(r_, x_))))
                r_ := or(r_, shl(5, lt(0xffffffff, shr(r_, x_))))
                r_ := or(r_, shl(4, lt(0xffff, shr(r_, x_))))
                r_ := add(1, or(shr(3, r_), lt(0xff, shr(r_, x_))))
                mstore8(o_, add(r_, 0x80)) // Store the prefix.
                mstore(_o, shl(shl(3, sub(32, r_)), x_)) // Copy `x_`.
                _o := add(r_, _o)
            }
            result := mload(0x40)
            let o := encodeUint(x, add(result, 0x20))
            mstore(result, sub(o, add(result, 0x20)))
            mstore(o, 0)
            mstore(0x40, add(o, 0x20))
        }
    }

    function _encode(bytes memory x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            function encodeBytes(x_, o_, c_) -> _o {
                _o := add(o_, 1)
                let f_ := mload(add(0x20, x_))
                let n_ := mload(x_)
                if iszero(gt(n_, 55)) {
                    if iszero(and(eq(1, n_), lt(byte(0, f_), 0x80))) {
                        mstore8(o_, add(n_, c_)) // Store the prefix.
                        mstore(add(0x21, o_), mload(add(0x40, x_)))
                        mstore(_o, f_)
                        _o := add(n_, _o)
                        leave
                    }
                    mstore(o_, f_) // Copy `x_`.
                    leave
                }
                if iszero(gt(n_, 0xffffffffffffffff)) {
                    let r_ := shl(5, lt(0xffffffff, n_))
                    r_ := or(r_, shl(4, lt(0xffff, shr(r_, n_))))
                    r_ := add(1, or(shr(3, r_), lt(0xff, shr(r_, n_))))
                    mstore(o_, shl(248, add(r_, add(c_, 55)))) // Store the prefix.
                    // Copy `x`.
                    let i_ := add(r_, _o)
                    _o := add(i_, n_)
                    for { let d_ := sub(add(0x20, x_), i_) } 1 {} {
                        mstore(i_, mload(add(d_, i_)))
                        i_ := add(i_, 0x20)
                        if iszero(lt(i_, _o)) { break }
                    }
                    mstore(o_, or(mload(o_), shl(sub(248, shl(3, r_)), n_))) // Store the prefix.
                    leave
                }
                mstore(0x00, 0x25755edb) // `BytesStringTooBig()`.
                revert(0x1c, 0x04)
            }
            result := mload(0x40)
            let o := encodeBytes(x, add(result, 0x20), 0x80)
            mstore(result, sub(o, add(result, 0x20)))
            mstore(o, 0)
            mstore(0x40, add(o, 0x20))
        }
    }

    function _encodeSimple(uint256 x) internal pure returns (bytes memory) {
        if (x == 0) return hex"80";
        if (x < 0x80) return abi.encodePacked(uint8(x));
        if (x <= type(uint8).max) return abi.encodePacked(bytes1(0x81), uint8(x));
        if (x <= type(uint16).max) return abi.encodePacked(bytes1(0x82), uint16(x));
        if (x <= type(uint24).max) return abi.encodePacked(bytes1(0x83), uint24(x));
        if (x <= type(uint32).max) return abi.encodePacked(bytes1(0x84), uint32(x));
        if (x <= type(uint40).max) return abi.encodePacked(bytes1(0x85), uint40(x));
        if (x <= type(uint48).max) return abi.encodePacked(bytes1(0x86), uint48(x));
        if (x <= type(uint56).max) return abi.encodePacked(bytes1(0x87), uint56(x));
        if (x <= type(uint64).max) return abi.encodePacked(bytes1(0x88), uint64(x));
        if (x <= type(uint72).max) return abi.encodePacked(bytes1(0x89), uint72(x));
        if (x <= type(uint80).max) return abi.encodePacked(bytes1(0x8a), uint80(x));
        if (x <= type(uint88).max) return abi.encodePacked(bytes1(0x8b), uint88(x));
        if (x <= type(uint96).max) return abi.encodePacked(bytes1(0x8c), uint96(x));
        if (x <= type(uint104).max) return abi.encodePacked(bytes1(0x8d), uint104(x));
        if (x <= type(uint112).max) return abi.encodePacked(bytes1(0x8e), uint112(x));
        if (x <= type(uint120).max) return abi.encodePacked(bytes1(0x8f), uint120(x));
        if (x <= type(uint128).max) return abi.encodePacked(bytes1(0x90), uint128(x));
        if (x <= type(uint136).max) return abi.encodePacked(bytes1(0x91), uint136(x));
        if (x <= type(uint144).max) return abi.encodePacked(bytes1(0x92), uint144(x));
        if (x <= type(uint152).max) return abi.encodePacked(bytes1(0x93), uint152(x));
        if (x <= type(uint160).max) return abi.encodePacked(bytes1(0x94), uint160(x));
        if (x <= type(uint168).max) return abi.encodePacked(bytes1(0x95), uint168(x));
        if (x <= type(uint176).max) return abi.encodePacked(bytes1(0x96), uint176(x));
        if (x <= type(uint184).max) return abi.encodePacked(bytes1(0x97), uint184(x));
        if (x <= type(uint192).max) return abi.encodePacked(bytes1(0x98), uint192(x));
        if (x <= type(uint200).max) return abi.encodePacked(bytes1(0x99), uint200(x));
        if (x <= type(uint208).max) return abi.encodePacked(bytes1(0x9a), uint208(x));
        if (x <= type(uint216).max) return abi.encodePacked(bytes1(0x9b), uint216(x));
        if (x <= type(uint224).max) return abi.encodePacked(bytes1(0x9c), uint224(x));
        if (x <= type(uint232).max) return abi.encodePacked(bytes1(0x9d), uint232(x));
        if (x <= type(uint240).max) return abi.encodePacked(bytes1(0x9e), uint240(x));
        if (x <= type(uint248).max) return abi.encodePacked(bytes1(0x9f), uint248(x));
        return abi.encodePacked(bytes1(0xa0), uint256(x));
    }

    function _encodeSimple(bytes memory x) internal pure returns (bytes memory) {
        uint256 n = x.length;
        if (n == 0) return hex"80";
        if (n == 1 && uint8(bytes1(x[0])) < 0x80) return x;
        if (n < 56) return abi.encodePacked(uint8(n + 0x80), x);
        if (n <= type(uint8).max) return abi.encodePacked(bytes1(0xb8), uint8(n), x);
        if (n <= type(uint16).max) return abi.encodePacked(bytes1(0xb9), uint16(n), x);
        if (n <= type(uint24).max) return abi.encodePacked(bytes1(0xba), uint24(n), x);
        if (n <= type(uint32).max) return abi.encodePacked(bytes1(0xbb), uint32(n), x);
        if (n <= type(uint40).max) return abi.encodePacked(bytes1(0xbc), uint40(n), x);
        if (n <= type(uint48).max) return abi.encodePacked(bytes1(0xbd), uint48(n), x);
        if (n <= type(uint56).max) return abi.encodePacked(bytes1(0xbe), uint56(n), x);
        if (n <= type(uint64).max) return abi.encodePacked(bytes1(0xbf), uint64(n), x);
        if (n <= type(uint72).max) return abi.encodePacked(bytes1(0xc0), uint72(n), x);
        if (n <= type(uint80).max) return abi.encodePacked(bytes1(0xc1), uint80(n), x);
        if (n <= type(uint88).max) return abi.encodePacked(bytes1(0xc2), uint88(n), x);
        if (n <= type(uint96).max) return abi.encodePacked(bytes1(0xc3), uint96(n), x);
        if (n <= type(uint104).max) return abi.encodePacked(bytes1(0xc4), uint104(n), x);
        if (n <= type(uint112).max) return abi.encodePacked(bytes1(0xc5), uint112(n), x);
        if (n <= type(uint120).max) return abi.encodePacked(bytes1(0xc6), uint120(n), x);
        if (n <= type(uint128).max) return abi.encodePacked(bytes1(0xc7), uint128(n), x);
        if (n <= type(uint136).max) return abi.encodePacked(bytes1(0xc8), uint136(n), x);
        if (n <= type(uint144).max) return abi.encodePacked(bytes1(0xc9), uint144(n), x);
        if (n <= type(uint152).max) return abi.encodePacked(bytes1(0xca), uint152(n), x);
        if (n <= type(uint160).max) return abi.encodePacked(bytes1(0xcb), uint160(n), x);
        if (n <= type(uint168).max) return abi.encodePacked(bytes1(0xcc), uint168(n), x);
        if (n <= type(uint176).max) return abi.encodePacked(bytes1(0xcd), uint176(n), x);
        if (n <= type(uint184).max) return abi.encodePacked(bytes1(0xce), uint184(n), x);
        if (n <= type(uint192).max) return abi.encodePacked(bytes1(0xcf), uint192(n), x);
        if (n <= type(uint200).max) return abi.encodePacked(bytes1(0xd0), uint200(n), x);
        if (n <= type(uint208).max) return abi.encodePacked(bytes1(0xd1), uint208(n), x);
        if (n <= type(uint216).max) return abi.encodePacked(bytes1(0xd2), uint216(n), x);
        if (n <= type(uint224).max) return abi.encodePacked(bytes1(0xd3), uint224(n), x);
        if (n <= type(uint232).max) return abi.encodePacked(bytes1(0xd4), uint232(n), x);
        if (n <= type(uint240).max) return abi.encodePacked(bytes1(0xd5), uint240(n), x);
        if (n <= type(uint248).max) return abi.encodePacked(bytes1(0xd6), uint248(n), x);
        return abi.encodePacked(bytes1(0xd7), uint256(n), x);
    }

    function testRLPEncodeUint() public {
        _testRLPEncodeUint(0, hex"80");
        _testRLPEncodeUint(0x1, hex"01");
        _testRLPEncodeUint(0x2, hex"02");
        _testRLPEncodeUint(0x7e, hex"7e");
        _testRLPEncodeUint(0x7f, hex"7f");
        _testRLPEncodeUint(0x80, hex"8180");
        _testRLPEncodeUint(0x81, hex"8181");
        _testRLPEncodeUint(0x82, hex"8182");
        _testRLPEncodeUint(0xfe, hex"81fe");
        _testRLPEncodeUint(0xff, hex"81ff");
        uint256 f = type(uint256).max;
        uint256 e = f - 1;
        _testRLPEncodeUint(uint8(f), abi.encodePacked(hex"81", uint8(f)));
        _testRLPEncodeUint(uint8(e), abi.encodePacked(hex"81", uint8(e)));
        _testRLPEncodeUint(uint16(f), abi.encodePacked(hex"82", uint16(f)));
        _testRLPEncodeUint(uint16(e), abi.encodePacked(hex"82", uint16(e)));
        _testRLPEncodeUint(uint24(f), abi.encodePacked(hex"83", uint24(f)));
        _testRLPEncodeUint(uint24(e), abi.encodePacked(hex"83", uint24(e)));
        _testRLPEncodeUint(uint32(f), abi.encodePacked(hex"84", uint32(f)));
        _testRLPEncodeUint(uint32(e), abi.encodePacked(hex"84", uint32(e)));
        _testRLPEncodeUint(uint40(f), abi.encodePacked(hex"85", uint40(f)));
        _testRLPEncodeUint(uint40(e), abi.encodePacked(hex"85", uint40(e)));
        _testRLPEncodeUint(uint48(f), abi.encodePacked(hex"86", uint48(f)));
        _testRLPEncodeUint(uint48(e), abi.encodePacked(hex"86", uint48(e)));
        _testRLPEncodeUint(uint56(f), abi.encodePacked(hex"87", uint56(f)));
        _testRLPEncodeUint(uint56(e), abi.encodePacked(hex"87", uint56(e)));
        _testRLPEncodeUint(uint64(f), abi.encodePacked(hex"88", uint64(f)));
        _testRLPEncodeUint(uint64(e), abi.encodePacked(hex"88", uint64(e)));
        _testRLPEncodeUint(uint72(f), abi.encodePacked(hex"89", uint72(f)));
        _testRLPEncodeUint(uint72(e), abi.encodePacked(hex"89", uint72(e)));
        _testRLPEncodeUint(uint80(f), abi.encodePacked(hex"8a", uint80(f)));
        _testRLPEncodeUint(uint80(e), abi.encodePacked(hex"8a", uint80(e)));
        _testRLPEncodeUint(uint88(f), abi.encodePacked(hex"8b", uint88(f)));
        _testRLPEncodeUint(uint88(e), abi.encodePacked(hex"8b", uint88(e)));
        _testRLPEncodeUint(uint96(f), abi.encodePacked(hex"8c", uint96(f)));
        _testRLPEncodeUint(uint96(e), abi.encodePacked(hex"8c", uint96(e)));
        _testRLPEncodeUint(uint104(f), abi.encodePacked(hex"8d", uint104(f)));
        _testRLPEncodeUint(uint104(e), abi.encodePacked(hex"8d", uint104(e)));
        _testRLPEncodeUint(uint112(f), abi.encodePacked(hex"8e", uint112(f)));
        _testRLPEncodeUint(uint112(e), abi.encodePacked(hex"8e", uint112(e)));
        _testRLPEncodeUint(uint120(f), abi.encodePacked(hex"8f", uint120(f)));
        _testRLPEncodeUint(uint120(e), abi.encodePacked(hex"8f", uint120(e)));
        _testRLPEncodeUint(uint128(f), abi.encodePacked(hex"90", uint128(f)));
        _testRLPEncodeUint(uint128(e), abi.encodePacked(hex"90", uint128(e)));
        _testRLPEncodeUint(uint136(f), abi.encodePacked(hex"91", uint136(f)));
        _testRLPEncodeUint(uint136(e), abi.encodePacked(hex"91", uint136(e)));
        _testRLPEncodeUint(uint144(f), abi.encodePacked(hex"92", uint144(f)));
        _testRLPEncodeUint(uint144(e), abi.encodePacked(hex"92", uint144(e)));
        _testRLPEncodeUint(uint152(f), abi.encodePacked(hex"93", uint152(f)));
        _testRLPEncodeUint(uint152(e), abi.encodePacked(hex"93", uint152(e)));
        _testRLPEncodeUint(uint160(f), abi.encodePacked(hex"94", uint160(f)));
        _testRLPEncodeUint(uint160(e), abi.encodePacked(hex"94", uint160(e)));
        _testRLPEncodeUint(uint168(f), abi.encodePacked(hex"95", uint168(f)));
        _testRLPEncodeUint(uint168(e), abi.encodePacked(hex"95", uint168(e)));
        _testRLPEncodeUint(uint176(f), abi.encodePacked(hex"96", uint176(f)));
        _testRLPEncodeUint(uint176(e), abi.encodePacked(hex"96", uint176(e)));
        _testRLPEncodeUint(uint184(f), abi.encodePacked(hex"97", uint184(f)));
        _testRLPEncodeUint(uint184(e), abi.encodePacked(hex"97", uint184(e)));
        _testRLPEncodeUint(uint192(f), abi.encodePacked(hex"98", uint192(f)));
        _testRLPEncodeUint(uint192(e), abi.encodePacked(hex"98", uint192(e)));
        _testRLPEncodeUint(uint200(f), abi.encodePacked(hex"99", uint200(f)));
        _testRLPEncodeUint(uint200(e), abi.encodePacked(hex"99", uint200(e)));
        _testRLPEncodeUint(uint208(f), abi.encodePacked(hex"9a", uint208(f)));
        _testRLPEncodeUint(uint208(e), abi.encodePacked(hex"9a", uint208(e)));
        _testRLPEncodeUint(uint216(f), abi.encodePacked(hex"9b", uint216(f)));
        _testRLPEncodeUint(uint216(e), abi.encodePacked(hex"9b", uint216(e)));
        _testRLPEncodeUint(uint224(f), abi.encodePacked(hex"9c", uint224(f)));
        _testRLPEncodeUint(uint224(e), abi.encodePacked(hex"9c", uint224(e)));
        _testRLPEncodeUint(uint232(f), abi.encodePacked(hex"9d", uint232(f)));
        _testRLPEncodeUint(uint232(e), abi.encodePacked(hex"9d", uint232(e)));
        _testRLPEncodeUint(uint240(f), abi.encodePacked(hex"9e", uint240(f)));
        _testRLPEncodeUint(uint240(e), abi.encodePacked(hex"9e", uint240(e)));
        _testRLPEncodeUint(uint248(f), abi.encodePacked(hex"9f", uint248(f)));
        _testRLPEncodeUint(uint248(e), abi.encodePacked(hex"9f", uint248(e)));
        _testRLPEncodeUint(uint256(f), abi.encodePacked(hex"a0", uint256(f)));
        _testRLPEncodeUint(uint256(e), abi.encodePacked(hex"a0", uint256(e)));
    }

    function _testRLPEncodeUint(uint256 x, bytes memory expected) internal {
        assertEq(LibRLP.encode(x), expected);
        _checkMemory();
    }

    function testRLPEncodeList() public {
        LibRLP.List memory l;
        assertEq(LibRLP.encode(l), hex"c0");
        {
            LibRLP.List memory t0;
            l.p(t0);
        }
        {
            LibRLP.List memory t1a;
            LibRLP.List memory t1b;
            t1a.p(t1b);
            l.p(t1a);
        }
        {
            LibRLP.List memory t2a;
            LibRLP.List memory t2b;
            LibRLP.List memory t2c;
            t2a.p(t2c);
            t2a.p(t2b);
            t2b.p(t2c);
            l.p(t2a);
        }
        _checkMemory();
        bytes memory computed = LibRLP.encode(l);
        _checkMemory();
        assertEq(computed, hex"c7c0c1c0c3c0c1c0");
    }

    function testRLPEncodeList2() public {
        LibRLP.List memory l;
        l.p("The").p("quick").p("brown").p("fox");
        l.p("jumps").p("over").p("the").p("lazy").p("dog");
        {
            LibRLP.List memory lSub;
            lSub.p(0).p(1).p(0x7f).p(0x80).p(0x81);
            lSub.p(2 ** 256 - 1);
            lSub.p("Jackdaws").p("loves").p("my").p("");
            lSub.p("great").p("sphinx").p("of").p("quartz");
            l.p(lSub);
        }
        l.p("0123456789abcdefghijklmnopqrstuvwxyz");
        _checkMemory();
        bytes memory computed = LibRLP.encode(l);
        _checkMemory();
        bytes memory expected =
            hex"f8a58354686585717569636b8562726f776e83666f78856a756d7073846f76657283746865846c617a7983646f67f85280017f81808181a0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff884a61636b64617773856c6f766573826d798085677265617486737068696e78826f668671756172747aa4303132333435363738396162636465666768696a6b6c6d6e6f707172737475767778797a";
        assertEq(computed, expected);
    }
}
