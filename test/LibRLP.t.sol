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
        assertEq(LibRLP.encode(x), _encode(x));
        _checkMemory();
    }

    function testRLPEncodeBytesDifferential() public {
        bytes memory x;
        testRLPEncodeBytesDifferential(x);
    }

    function testRLPEncodeUintDifferential(uint256 x) public {
        assertEq(LibRLP.encode(x), _encode(x));
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
        _testRLPEncodeUint(type(uint8).max - 0, abi.encodePacked(hex"81", type(uint8).max - 0));
        _testRLPEncodeUint(type(uint8).max - 1, abi.encodePacked(hex"81", type(uint8).max - 1));
        _testRLPEncodeUint(type(uint16).max - 0, abi.encodePacked(hex"82", type(uint16).max - 0));
        _testRLPEncodeUint(type(uint16).max - 1, abi.encodePacked(hex"82", type(uint16).max - 1));
        _testRLPEncodeUint(type(uint24).max - 0, abi.encodePacked(hex"83", type(uint24).max - 0));
        _testRLPEncodeUint(type(uint24).max - 1, abi.encodePacked(hex"83", type(uint24).max - 1));
        _testRLPEncodeUint(type(uint32).max - 0, abi.encodePacked(hex"84", type(uint32).max - 0));
        _testRLPEncodeUint(type(uint32).max - 1, abi.encodePacked(hex"84", type(uint32).max - 1));
        _testRLPEncodeUint(type(uint40).max - 0, abi.encodePacked(hex"85", type(uint40).max - 0));
        _testRLPEncodeUint(type(uint40).max - 1, abi.encodePacked(hex"85", type(uint40).max - 1));
        _testRLPEncodeUint(type(uint48).max - 0, abi.encodePacked(hex"86", type(uint48).max - 0));
        _testRLPEncodeUint(type(uint48).max - 1, abi.encodePacked(hex"86", type(uint48).max - 1));
        _testRLPEncodeUint(type(uint56).max - 0, abi.encodePacked(hex"87", type(uint56).max - 0));
        _testRLPEncodeUint(type(uint56).max - 1, abi.encodePacked(hex"87", type(uint56).max - 1));
        _testRLPEncodeUint(type(uint64).max - 0, abi.encodePacked(hex"88", type(uint64).max - 0));
        _testRLPEncodeUint(type(uint64).max - 1, abi.encodePacked(hex"88", type(uint64).max - 1));
        _testRLPEncodeUint(type(uint72).max - 0, abi.encodePacked(hex"89", type(uint72).max - 0));
        _testRLPEncodeUint(type(uint72).max - 1, abi.encodePacked(hex"89", type(uint72).max - 1));
        _testRLPEncodeUint(type(uint80).max - 0, abi.encodePacked(hex"8a", type(uint80).max - 0));
        _testRLPEncodeUint(type(uint80).max - 1, abi.encodePacked(hex"8a", type(uint80).max - 1));
        _testRLPEncodeUint(type(uint88).max - 0, abi.encodePacked(hex"8b", type(uint88).max - 0));
        _testRLPEncodeUint(type(uint88).max - 1, abi.encodePacked(hex"8b", type(uint88).max - 1));
        _testRLPEncodeUint(type(uint96).max - 0, abi.encodePacked(hex"8c", type(uint96).max - 0));
        _testRLPEncodeUint(type(uint96).max - 1, abi.encodePacked(hex"8c", type(uint96).max - 1));
        _testRLPEncodeUint(type(uint104).max - 0, abi.encodePacked(hex"8d", type(uint104).max - 0));
        _testRLPEncodeUint(type(uint104).max - 1, abi.encodePacked(hex"8d", type(uint104).max - 1));
        _testRLPEncodeUint(type(uint112).max - 0, abi.encodePacked(hex"8e", type(uint112).max - 0));
        _testRLPEncodeUint(type(uint112).max - 1, abi.encodePacked(hex"8e", type(uint112).max - 1));
        _testRLPEncodeUint(type(uint120).max - 0, abi.encodePacked(hex"8f", type(uint120).max - 0));
        _testRLPEncodeUint(type(uint120).max - 1, abi.encodePacked(hex"8f", type(uint120).max - 1));
        _testRLPEncodeUint(type(uint128).max - 0, abi.encodePacked(hex"90", type(uint128).max - 0));
        _testRLPEncodeUint(type(uint128).max - 1, abi.encodePacked(hex"90", type(uint128).max - 1));
        _testRLPEncodeUint(type(uint136).max - 0, abi.encodePacked(hex"91", type(uint136).max - 0));
        _testRLPEncodeUint(type(uint136).max - 1, abi.encodePacked(hex"91", type(uint136).max - 1));
        _testRLPEncodeUint(type(uint144).max - 0, abi.encodePacked(hex"92", type(uint144).max - 0));
        _testRLPEncodeUint(type(uint144).max - 1, abi.encodePacked(hex"92", type(uint144).max - 1));
        _testRLPEncodeUint(type(uint152).max - 0, abi.encodePacked(hex"93", type(uint152).max - 0));
        _testRLPEncodeUint(type(uint152).max - 1, abi.encodePacked(hex"93", type(uint152).max - 1));
        _testRLPEncodeUint(type(uint160).max - 0, abi.encodePacked(hex"94", type(uint160).max - 0));
        _testRLPEncodeUint(type(uint160).max - 1, abi.encodePacked(hex"94", type(uint160).max - 1));
        _testRLPEncodeUint(type(uint168).max - 0, abi.encodePacked(hex"95", type(uint168).max - 0));
        _testRLPEncodeUint(type(uint168).max - 1, abi.encodePacked(hex"95", type(uint168).max - 1));
        _testRLPEncodeUint(type(uint176).max - 0, abi.encodePacked(hex"96", type(uint176).max - 0));
        _testRLPEncodeUint(type(uint176).max - 1, abi.encodePacked(hex"96", type(uint176).max - 1));
        _testRLPEncodeUint(type(uint184).max - 0, abi.encodePacked(hex"97", type(uint184).max - 0));
        _testRLPEncodeUint(type(uint184).max - 1, abi.encodePacked(hex"97", type(uint184).max - 1));
        _testRLPEncodeUint(type(uint192).max - 0, abi.encodePacked(hex"98", type(uint192).max - 0));
        _testRLPEncodeUint(type(uint192).max - 1, abi.encodePacked(hex"98", type(uint192).max - 1));
        _testRLPEncodeUint(type(uint200).max - 0, abi.encodePacked(hex"99", type(uint200).max - 0));
        _testRLPEncodeUint(type(uint200).max - 1, abi.encodePacked(hex"99", type(uint200).max - 1));
        _testRLPEncodeUint(type(uint208).max - 0, abi.encodePacked(hex"9a", type(uint208).max - 0));
        _testRLPEncodeUint(type(uint208).max - 1, abi.encodePacked(hex"9a", type(uint208).max - 1));
        _testRLPEncodeUint(type(uint216).max - 0, abi.encodePacked(hex"9b", type(uint216).max - 0));
        _testRLPEncodeUint(type(uint216).max - 1, abi.encodePacked(hex"9b", type(uint216).max - 1));
        _testRLPEncodeUint(type(uint224).max - 0, abi.encodePacked(hex"9c", type(uint224).max - 0));
        _testRLPEncodeUint(type(uint224).max - 1, abi.encodePacked(hex"9c", type(uint224).max - 1));
        _testRLPEncodeUint(type(uint232).max - 0, abi.encodePacked(hex"9d", type(uint232).max - 0));
        _testRLPEncodeUint(type(uint232).max - 1, abi.encodePacked(hex"9d", type(uint232).max - 1));
        _testRLPEncodeUint(type(uint240).max - 0, abi.encodePacked(hex"9e", type(uint240).max - 0));
        _testRLPEncodeUint(type(uint240).max - 1, abi.encodePacked(hex"9e", type(uint240).max - 1));
        _testRLPEncodeUint(type(uint248).max - 0, abi.encodePacked(hex"9f", type(uint248).max - 0));
        _testRLPEncodeUint(type(uint248).max - 1, abi.encodePacked(hex"9f", type(uint248).max - 1));
        _testRLPEncodeUint(type(uint256).max - 0, abi.encodePacked(hex"a0", type(uint256).max - 0));
        _testRLPEncodeUint(type(uint256).max - 1, abi.encodePacked(hex"a0", type(uint256).max - 1));
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
        assertEq(
            computed,
            hex"f8a58354686585717569636b8562726f776e83666f78856a756d7073846f76657283746865846c617a7983646f67f85280017f81808181a0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff884a61636b64617773856c6f766573826d798085677265617486737068696e78826f668671756172747aa4303132333435363738396162636465666768696a6b6c6d6e6f707172737475767778797a"
        );
    }
}
