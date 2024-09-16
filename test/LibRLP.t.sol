// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {LibRLP} from "../src/utils/LibRLP.sol";
import {FixedPointMathLib} from "../src/utils/FixedPointMathLib.sol";

contract LibRLPTest is SoladyTest {
    using LibRLP for LibRLP.List;

    function testComputeAddressDifferential(address deployer, uint256 nonce) public {
        address computed = LibRLP.computeAddress(_brutalized(deployer), nonce);
        assertEq(computed, computeAddressOriginal(deployer, nonce));
        assertEq(computed, computeAddressWithRLPList(deployer, nonce));
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

    function computeAddressWithRLPList(address deployer, uint256 nonce)
        internal
        pure
        returns (address)
    {
        return address(uint160(uint256(keccak256(LibRLP.p(deployer).p(nonce).encode()))));
    }

    function computeAddressOriginal(address deployer, uint256 nonce)
        internal
        pure
        returns (address)
    {
        return address(uint160(uint256(keccak256(_computeAddressOriginal(deployer, nonce)))));
    }

    function _computeAddressOriginal(address deployer, uint256 nonce)
        internal
        pure
        returns (bytes memory)
    {
        // Although the theoretical allowed limit, based on EIP-2681,
        // for an account nonce is 2**64-2: https://eips.ethereum.org/EIPS/eip-2681,
        // we just test all the way to 2**256-1 to ensure that the computeAddress function does not revert
        // for whatever nonce we provide.

        if (nonce == 0x00) {
            return abi.encodePacked(uint8(0xd6), uint8(0x94), deployer, uint8(0x80));
        }
        if (nonce <= 0x7f) {
            return abi.encodePacked(uint8(0xd6), uint8(0x94), deployer, uint8(nonce));
        }
        bytes memory ep = _ep(nonce);
        uint256 n = ep.length;
        return abi.encodePacked(uint8(0xd6 + n), uint8(0x94), deployer, uint8(0x80 + n), ep);
    }

    function _ep(uint256 x) internal pure returns (bytes memory) {
        if (x <= type(uint8).max) return abi.encodePacked(uint8(x));
        if (x <= type(uint16).max) return abi.encodePacked(uint16(x));
        if (x <= type(uint24).max) return abi.encodePacked(uint24(x));
        if (x <= type(uint32).max) return abi.encodePacked(uint32(x));
        if (x <= type(uint40).max) return abi.encodePacked(uint40(x));
        if (x <= type(uint48).max) return abi.encodePacked(uint48(x));
        if (x <= type(uint56).max) return abi.encodePacked(uint56(x));
        if (x <= type(uint64).max) return abi.encodePacked(uint64(x));
        if (x <= type(uint72).max) return abi.encodePacked(uint72(x));
        if (x <= type(uint80).max) return abi.encodePacked(uint80(x));
        if (x <= type(uint88).max) return abi.encodePacked(uint88(x));
        if (x <= type(uint96).max) return abi.encodePacked(uint96(x));
        if (x <= type(uint104).max) return abi.encodePacked(uint104(x));
        if (x <= type(uint112).max) return abi.encodePacked(uint112(x));
        if (x <= type(uint120).max) return abi.encodePacked(uint120(x));
        if (x <= type(uint128).max) return abi.encodePacked(uint128(x));
        if (x <= type(uint136).max) return abi.encodePacked(uint136(x));
        if (x <= type(uint144).max) return abi.encodePacked(uint144(x));
        if (x <= type(uint152).max) return abi.encodePacked(uint152(x));
        if (x <= type(uint160).max) return abi.encodePacked(uint160(x));
        if (x <= type(uint168).max) return abi.encodePacked(uint168(x));
        if (x <= type(uint176).max) return abi.encodePacked(uint176(x));
        if (x <= type(uint184).max) return abi.encodePacked(uint184(x));
        if (x <= type(uint192).max) return abi.encodePacked(uint192(x));
        if (x <= type(uint200).max) return abi.encodePacked(uint200(x));
        if (x <= type(uint208).max) return abi.encodePacked(uint208(x));
        if (x <= type(uint216).max) return abi.encodePacked(uint216(x));
        if (x <= type(uint224).max) return abi.encodePacked(uint224(x));
        if (x <= type(uint232).max) return abi.encodePacked(uint232(x));
        if (x <= type(uint240).max) return abi.encodePacked(uint240(x));
        if (x <= type(uint248).max) return abi.encodePacked(uint248(x));
        return abi.encodePacked(uint256(x));
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
                _checkMemory(l);
                assertEq(_getUint256(l, i), y);
            }
            for (uint256 i; i != 32; ++i) {
                uint256 y = x ^ i;
                assertEq(_getUint256(l, i), y);
            }
        }
    }

    function testRLPMemory(bytes32) public returns (LibRLP.List memory l) {
        while (true) {
            uint256 r = _random();
            if (r & 0x0003 == 0) {
                _maybeBzztMemory();
                l.p(_randomBytes());
                _checkMemory(l);
            }
            if (r & 0x0030 == 0) {
                if (_random() & 1 == 0) {
                    l.p(_randomNonZeroAddress());
                } else {
                    l.p(_random());
                }
                _checkMemory(l);
                _maybeBzztMemory();
            }
            if (r & 0x0100 == 0) {
                l.p(_testRLPP(0));
                _checkMemory(l);
            }
            if (r & 0x1000 == 0) break;
        }
        _checkMemory(l.encode());
    }

    function _testRLPP(uint256 depth) internal returns (LibRLP.List memory l) {
        if (depth <= 2) {
            while (true) {
                uint256 r = _random();
                if (r & 0x0007 == 0) {
                    _maybeBzztMemory();
                    l.p(_randomBytes());
                    _checkMemory(l);
                }
                if (r & 0x0030 == 0) {
                    if (_random() & 1 == 0) {
                        l.p(_randomNonZeroAddress());
                    } else {
                        l.p(_random());
                    }
                    _checkMemory(l);
                    _maybeBzztMemory();
                }
                if (r & 0x0300 == 0) {
                    _maybeBzztMemory();
                    unchecked {
                        l.p(_testRLPP(depth + 1));
                    }
                    _checkMemory(l);
                }
                if (r & 0x1000 == 0) break;
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

    function testRLPEncodeBytes2() public {
        assertEq(LibRLP.encode(""), hex"80");
        for (uint256 i = 0; i < 128; ++i) {
            assertEq(
                LibRLP.encode(bytes(abi.encodePacked(uint8(i)))), bytes(abi.encodePacked(uint8(i)))
            );
        }
        for (uint256 i = 128; i < 256; ++i) {
            assertEq(
                LibRLP.encode(bytes(abi.encodePacked(uint8(i)))),
                bytes(abi.encodePacked(bytes1(0x81), uint8(i)))
            );
        }
    }

    function testRLPEncodeAddressViaList(address a0, address a1) public {
        _maybeBzztMemory();
        bytes memory computed = LibRLP.p(_brutalized(a0)).p(_brutalized(a1)).encode();
        _checkMemory(computed);
        _maybeBzztMemory();
        bytes memory expected = LibRLP.p(abi.encodePacked(a0)).p(abi.encodePacked(a1)).encode();
        assertEq(computed, expected);
    }

    function testRLPEncodeListDifferential(bytes memory x0, uint256 x1) public {
        _maybeBzztMemory();
        LibRLP.List memory list = LibRLP.p(x0).p(x1).p(x1).p(x0);
        _checkMemory(list);
        _maybeBzztMemory();
        bytes memory computed = LibRLP.encode(list);
        _checkAndMaybeBzztMemory(computed);
        bytes memory x0Encoded = LibRLP.encode(x0);
        _checkAndMaybeBzztMemory(x0Encoded);
        bytes memory x1Encoded = LibRLP.encode(x1);
        _checkAndMaybeBzztMemory(x1Encoded);
        bytes memory combined = abi.encodePacked(x0Encoded, x1Encoded, x1Encoded, x0Encoded);
        assertEq(computed, _encodeSimple(combined, 0xc0));
        _checkAndMaybeBzztMemory(computed);
        assertEq(computed, LibRLP.encode(list));
    }

    function testRLPEncodeBytesDifferential(bytes32) public {
        bytes memory x = _randomBytesZeroRightPadded();
        _maybeBzztMemory();
        bytes memory computed = LibRLP.encode(x);
        _checkAndMaybeBzztMemory(computed);
        bytes memory computed2 = _encode(x);
        _checkAndMaybeBzztMemory(computed2);
        assertEq(computed, computed2);
        assertEq(computed, _encodeSimple(x));
    }

    function testRLPEncodeUintDifferential(uint256 x) public {
        _maybeBzztMemory();
        bytes memory computed = LibRLP.encode(x);
        _checkAndMaybeBzztMemory(computed);
        bytes memory computed2 = _encode(x);
        _checkAndMaybeBzztMemory(computed2);
        assertEq(computed, computed2);
        assertEq(computed, _encodeSimple(x));
    }

    function testRLPEncodeAddressDifferential(address x) public {
        _maybeBzztMemory();
        bytes memory computed = LibRLP.encode(_brutalized(x));
        _checkAndMaybeBzztMemory(computed);
        bytes memory computed2 = _encode(x);
        _checkAndMaybeBzztMemory(computed2);
        assertEq(computed, computed2);
        assertEq(computed, _encodeSimple(x));
    }

    function testRLPEncodeBool(bool x) public {
        _maybeBzztMemory();
        bytes memory computed = LibRLP.encode(_brutalized(x));
        _checkMemory(computed);
        bytes memory expected = bytes(x ? hex"01" : hex"80");
        assertEq(computed, expected);
        uint256 y = x ? 1 : 0;
        assertEq(LibRLP.p(y).p(y ^ 1).p(y).encode(), LibRLP.p(x).p(!x).p(x).encode());
    }

    function _maybeBzztMemory() internal {
        uint256 r = _random();
        if (r & 0x000f == uint256(0)) _misalignFreeMemoryPointer();
        if (r & 0x0ff0 == uint256(0)) _brutalizeMemory();
        if (r & 0xf000 == uint256(0)) _misalignFreeMemoryPointer();
    }

    function _bzztMemory() internal view {
        _misalignFreeMemoryPointer();
        _brutalizeMemory();
    }

    function _checkAndMaybeBzztMemory(bytes memory x) internal {
        _checkMemory(x);
        _maybeBzztMemory();
    }

    function _encode(uint256 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            function encodeUint(x_, o_) -> _o {
                _o := add(o_, 1)
                if iszero(gt(x_, 0x7f)) {
                    mstore8(o_, or(shl(7, iszero(x_)), x_)) // Copy `x_`.
                    leave
                }
                let r_ := shl(7, lt(0xffffffffffffffffffffffffffffffff, x_))
                r_ := or(r_, shl(6, lt(0xffffffffffffffff, shr(r_, x_))))
                r_ := or(r_, shl(5, lt(0xffffffff, shr(r_, x_))))
                r_ := or(r_, shl(4, lt(0xffff, shr(r_, x_))))
                r_ := or(shr(3, r_), lt(0xff, shr(r_, x_)))
                mstore8(o_, add(r_, 0x81)) // Store the prefix.
                mstore(0x00, x_)
                mstore(_o, mload(xor(31, r_))) // Copy `x_`.
                _o := add(add(1, r_), _o)
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
                let n_ := mload(x_)
                if iszero(gt(n_, 55)) {
                    let f_ := mload(add(0x20, x_))
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
                returndatacopy(returndatasize(), returndatasize(), shr(32, n_))
                let r_ := add(1, add(lt(0xff, n_), add(lt(0xffff, n_), lt(0xffffff, n_))))
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
            }
            result := mload(0x40)
            let o := encodeBytes(x, add(result, 0x20), 0x80)
            mstore(result, sub(o, add(result, 0x20)))
            mstore(o, 0)
            mstore(0x40, add(o, 0x20))
        }
    }

    function _encode(address x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            function encodeAddress(x_, o_) -> _o {
                _o := add(o_, 0x15)
                mstore(o_, shl(88, x_))
                mstore8(o_, 0x94)
            }
            result := mload(0x40)
            let o := encodeAddress(x, add(result, 0x20))
            mstore(result, sub(o, add(result, 0x20)))
            mstore(o, 0)
            mstore(0x40, add(o, 0x20))
        }
    }

    function _encodeSimple(uint256 x) internal pure returns (bytes memory) {
        if (x == 0) return hex"80";
        if (x < 0x80) return abi.encodePacked(uint8(x));
        bytes memory ep = _ep(x);
        return abi.encodePacked(uint8(0x80 + ep.length), ep);
    }

    function _encodeSimple(address x) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(0x94), x);
    }

    function _encodeSimple(bytes memory x, uint256 c) internal pure returns (bytes memory) {
        uint256 n = x.length;
        if (n == 0) return hex"80";
        if (n == 1 && uint8(bytes1(x[0])) < 0x80) return x;
        if (n < 56) return abi.encodePacked(uint8(n + c), x);
        bytes memory ep = _ep(n);
        return abi.encodePacked(uint8(c + 55 + ep.length), ep, x);
    }

    function _encodeSimple(bytes memory x) internal pure returns (bytes memory) {
        return _encodeSimple(x, 0x80);
    }

    function testRLPEncodeUint(uint256 x) public {
        _maybeBzztMemory();
        if (x == 0) {
            _testRLPEncodeUint(x, hex"80");
            return;
        }
        if (x < 0x80) {
            _testRLPEncodeUint(x, abi.encodePacked(uint8(x)));
            return;
        }
        bytes memory ep = _ep(x);
        uint256 n = ep.length;
        _testRLPEncodeUint(x, abi.encodePacked(uint8(0x80 + n), _ep(x)));
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
        unchecked {
            uint256 x = type(uint256).max;
            while (x != 0) {
                testRLPEncodeUint(x);
                testRLPEncodeUint(x - 1);
                x >>= 8;
            }
        }
    }

    function _testRLPEncodeUint(uint256 x, bytes memory expected) internal {
        bytes memory computed = LibRLP.encode(x);
        _checkMemory(computed);
        assertEq(computed, expected);
    }

    function testRLPEncodeList() public {
        LibRLP.List memory l;
        _bzztMemory();
        assertEq(LibRLP.encode(l), hex"c0");
        l.p(LibRLP.p());
        _checkMemory(l);
        l.p(LibRLP.p(LibRLP.p()));
        _checkMemory(l);
        l.p(LibRLP.p(LibRLP.p()).p(LibRLP.p(LibRLP.p())));
        _checkMemory(l);
        _bzztMemory();
        bytes memory computed = LibRLP.encode(l);
        _checkMemory(computed);
        assertEq(computed, hex"c7c0c1c0c3c0c1c0");
        _bzztMemory();
        bytes memory computed2 = LibRLP.encode(l);
        assertEq(computed, computed2);
        _checkMemory(computed);
        _checkMemory(computed2);
    }

    function testRLPEncodeList2() public {
        LibRLP.List memory l;
        _checkMemory(l);
        _bzztMemory();
        l.p("The").p("quick").p("brown").p("fox");
        l.p("jumps").p("over").p("the").p("lazy").p("dog");
        _checkMemory(l);
        {
            LibRLP.List memory lSub;
            lSub.p(0).p(1).p(0x7f).p(0x80).p(0x81);
            lSub.p(2 ** 256 - 1);
            _checkMemory(lSub);
            lSub.p("Jackdaws").p("loves").p("my").p("");
            lSub.p("great").p("sphinx").p("of").p("quartz");
            _checkMemory(lSub);
            l.p(lSub);
            _checkMemory(l);
        }
        _bzztMemory();
        l.p("0123456789abcdefghijklmnopqrstuvwxyz");
        _checkMemory(l);
        _bzztMemory();
        bytes memory computed = LibRLP.encode(l);
        _checkMemory(computed);
        bytes memory expected =
            hex"f8a58354686585717569636b8562726f776e83666f78856a756d7073846f76657283746865846c617a7983646f67f85280017f81808181a0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff884a61636b64617773856c6f766573826d798085677265617486737068696e78826f668671756172747aa4303132333435363738396162636465666768696a6b6c6d6e6f707172737475767778797a";
        assertEq(computed, expected);
        _bzztMemory();
        bytes memory computed2 = LibRLP.encode(l);
        assertEq(computed, computed2);
        _checkMemory(computed);
        _checkMemory(computed2);
    }

    function testSmallLog256Equivalence(uint256 n) public {
        n = _bound(n, 0, 0xffffffff);
        assertEq(_smallLog256(n), FixedPointMathLib.log256(n));
        assertEq(_smallLog256(n), _smallLog256Simple(n));
        n = _random() & 0xffffffff;
        assertEq(_smallLog256(n), _smallLog256Simple(n));
    }

    function _smallLog256(uint256 n) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := add(lt(0xff, n), add(lt(0xffff, n), lt(0xffffff, n)))
        }
    }

    function _smallLog256Simple(uint256 n) internal pure returns (uint256 result) {
        if (n <= 0x000000ff) return 0;
        if (n <= 0x0000ffff) return 1;
        if (n <= 0x00ffffff) return 2;
        if (n <= 0xffffffff) return 3;
        revert();
    }

    function _checkMemory(LibRLP.List memory l) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let v := mload(l)
            if gt(shr(40, v), m) { invalid() }
            for { let head := and(v, 0xffffffffff) } head {} {
                if gt(head, m) { invalid() }
                head := and(mload(head), 0xffffffffff)
            }
        }
        _checkMemory();
    }
}
