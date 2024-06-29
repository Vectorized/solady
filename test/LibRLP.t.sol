// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {LibRLP} from "../src/utils/LibRLP.sol";

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
                let data := shr(40, mload(head))
                result := shr(8, data)
                if eq(1, and(data, 0xff)) { result := mload(result) }
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

    function testRLPEncodeUint256() public {
        // forgefmt: disable-next-item
        {
            _testRLPEncodeUint256(0x1, hex"01");
            _testRLPEncodeUint256(0x2, hex"02");
            _testRLPEncodeUint256(0x7e, hex"7e");
            _testRLPEncodeUint256(0x7f, hex"7f");
            _testRLPEncodeUint256(0x80, hex"8180");
            _testRLPEncodeUint256(0x81, hex"8181");
            _testRLPEncodeUint256(0x82, hex"8182");
            _testRLPEncodeUint256(0xfe, hex"81fe");
            _testRLPEncodeUint256(0xff, hex"81ff");
            _testRLPEncodeUint256(0xfffe, hex"82fffe");
            _testRLPEncodeUint256(0xffff, hex"82ffff");
            _testRLPEncodeUint256(0xfffffe, hex"83fffffe");
            _testRLPEncodeUint256(0xffffff, hex"83ffffff");
            _testRLPEncodeUint256(0xfffffffe, hex"84fffffffe");
            _testRLPEncodeUint256(0xffffffff, hex"84ffffffff");
            _testRLPEncodeUint256(0xfffffffffe, hex"85fffffffffe");
            _testRLPEncodeUint256(0xffffffffff, hex"85ffffffffff");
            _testRLPEncodeUint256(0xfffffffffffe, hex"86fffffffffffe");
            _testRLPEncodeUint256(0xffffffffffff, hex"86ffffffffffff");
            _testRLPEncodeUint256(0xfffffffffffffe, hex"87fffffffffffffe");
            _testRLPEncodeUint256(0xffffffffffffff, hex"87ffffffffffffff");
            _testRLPEncodeUint256(0xfffffffffffffffe, hex"88fffffffffffffffe");
            _testRLPEncodeUint256(0xffffffffffffffff, hex"88ffffffffffffffff");
            _testRLPEncodeUint256(0xfffffffffffffffffe, hex"89fffffffffffffffffe");
            _testRLPEncodeUint256(0xffffffffffffffffff, hex"89ffffffffffffffffff");
            _testRLPEncodeUint256(0xfffffffffffffffffffe, hex"8afffffffffffffffffffe");
            _testRLPEncodeUint256(0xffffffffffffffffffff, hex"8affffffffffffffffffff");
            _testRLPEncodeUint256(0xfffffffffffffffffffffe, hex"8bfffffffffffffffffffffe");
            _testRLPEncodeUint256(0xffffffffffffffffffffff, hex"8bffffffffffffffffffffff");
            _testRLPEncodeUint256(0xfffffffffffffffffffffffe, hex"8cfffffffffffffffffffffffe");
            _testRLPEncodeUint256(0xffffffffffffffffffffffff, hex"8cffffffffffffffffffffffff");
            _testRLPEncodeUint256(0xfffffffffffffffffffffffffe, hex"8dfffffffffffffffffffffffffe");
            _testRLPEncodeUint256(0xffffffffffffffffffffffffff, hex"8dffffffffffffffffffffffffff");
            _testRLPEncodeUint256(0xfffffffffffffffffffffffffffe, hex"8efffffffffffffffffffffffffffe");
            _testRLPEncodeUint256(0xffffffffffffffffffffffffffff, hex"8effffffffffffffffffffffffffff");
            _testRLPEncodeUint256(0xfffffffffffffffffffffffffffffe, hex"8ffffffffffffffffffffffffffffffe");
            _testRLPEncodeUint256(0xffffffffffffffffffffffffffffff, hex"8fffffffffffffffffffffffffffffff");
            _testRLPEncodeUint256(0xfffffffffffffffffffffffffffffffe, hex"90fffffffffffffffffffffffffffffffe");
            _testRLPEncodeUint256(0xffffffffffffffffffffffffffffffff, hex"90ffffffffffffffffffffffffffffffff");
            _testRLPEncodeUint256(0xfffffffffffffffffffffffffffffffffe, hex"91fffffffffffffffffffffffffffffffffe");
            _testRLPEncodeUint256(0xffffffffffffffffffffffffffffffffff, hex"91ffffffffffffffffffffffffffffffffff");
            _testRLPEncodeUint256(0xfffffffffffffffffffffffffffffffffffe, hex"92fffffffffffffffffffffffffffffffffffe");
            _testRLPEncodeUint256(0xffffffffffffffffffffffffffffffffffff, hex"92ffffffffffffffffffffffffffffffffffff");
            _testRLPEncodeUint256(0xfffffffffffffffffffffffffffffffffffffe, hex"93fffffffffffffffffffffffffffffffffffffe");
            _testRLPEncodeUint256(0xffffffffffffffffffffffffffffffffffffff, hex"93ffffffffffffffffffffffffffffffffffffff");
            _testRLPEncodeUint256(0xfffffffffffffffffffffffffffffffffffffffffe, hex"95fffffffffffffffffffffffffffffffffffffffffe");
            _testRLPEncodeUint256(0xffffffffffffffffffffffffffffffffffffffffff, hex"95ffffffffffffffffffffffffffffffffffffffffff");
            _testRLPEncodeUint256(0xfffffffffffffffffffffffffffffffffffffffffffe, hex"96fffffffffffffffffffffffffffffffffffffffffffe");
            _testRLPEncodeUint256(0xffffffffffffffffffffffffffffffffffffffffffff, hex"96ffffffffffffffffffffffffffffffffffffffffffff");
            _testRLPEncodeUint256(0xfffffffffffffffffffffffffffffffffffffffffffffe, hex"97fffffffffffffffffffffffffffffffffffffffffffffe");
            _testRLPEncodeUint256(0xffffffffffffffffffffffffffffffffffffffffffffff, hex"97ffffffffffffffffffffffffffffffffffffffffffffff");
            _testRLPEncodeUint256(0xfffffffffffffffffffffffffffffffffffffffffffffffe, hex"98fffffffffffffffffffffffffffffffffffffffffffffffe");
            _testRLPEncodeUint256(0xffffffffffffffffffffffffffffffffffffffffffffffff, hex"98ffffffffffffffffffffffffffffffffffffffffffffffff");
            _testRLPEncodeUint256(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe, hex"a0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe");
            _testRLPEncodeUint256(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, hex"a0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
        }
    }

    function _testRLPEncodeUint256(uint256 x, bytes memory expected) internal {
        assertEq(LibRLP.encode(x), expected);
        _checkMemory();
    }
}
