// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {LEB128Lib} from "../src/utils/LEB128Lib.sol";

// Helpers
import {LibBit} from "../src/utils/LibBit.sol";
import {FixedPointMathLib} from "../src/utils/FixedPointMathLib.sol";

contract LEB128 {
    function decodeUint(bytes calldata input) external pure returns (uint256, bytes memory) {
        return LEB128Lib.decodeUint(input);
    }

    function decodeInt(bytes calldata input) external pure returns (int256, bytes memory) {
        return LEB128Lib.decodeInt(input);
    }

    function rawDecodeUint(bytes calldata input) external pure returns (uint256, uint256) {
        uint256 ptr;
        assembly {
            ptr := input.offset
        }
        return LEB128Lib.rawDecodeUint(ptr);
    }

    function rawDecodeInt(bytes calldata input) external pure returns (int256, uint256) {
        uint256 ptr;
        assembly {
            ptr := input.offset
        }
        return LEB128Lib.rawDecodeInt(ptr);
    }
}

contract LEB128LibTest is SoladyTest {
    LEB128 public leb128;

    function setUp() public {
        leb128 = new LEB128();
    }

    //function uleb128encodejs(uint256 x) internal returns (bytes memory) {
    //    string[] memory inputs = new string[](3);
    //    inputs[0] = "node";
    //    inputs[1] = "test/utils/uleb128encode.js";
    //    inputs[2] = vm.toString(x);
    //    return vm.ffi(inputs);
    //}

    //function sleb128encodejs(int256 x) internal returns (bytes memory) {
    //    string[] memory inputs = new string[](3);
    //    inputs[0] = "node";
    //    inputs[1] = "test/utils/sleb128encode.js";
    //    inputs[2] = vm.toString(x);
    //    return vm.ffi(inputs);
    //}

    //function test_encodeUint(uint256 x) public {
    //    assertEq(leb128.encode(x), uleb128encodejs(x));
    //}

    //function test_encodeInt(int256 x) public {
    //    assertEq(leb128.encode(x), sleb128encodejs(x));
    //}

    function _encodedUintLength(uint256 x) internal pure returns (uint256) {
        return x == 0 ? 1 : FixedPointMathLib.divUp(LibBit.fls(x) + 1, 7);
    }

    function _encodedIntLength(int256 x) internal pure returns (uint256) {
        uint256 deSigned = x < 0 ? uint256(-(x + 1)) + 1 : uint256(x);
        return x == 0 ? 1 : FixedPointMathLib.divUp(LibBit.fls(deSigned) + 2, 7);
    }

    function testSignedEncode() public {
        assertEq(LEB128Lib.encode(int256(0)), hex"00");
        assertEq(LEB128Lib.encode(int256(1)), hex"01");
        assertEq(LEB128Lib.encode(int256(-1)), hex"7f");
        assertEq(LEB128Lib.encode(int256(69)), hex"c500");
        assertEq(LEB128Lib.encode(int256(-69)), hex"bb7f");
        assertEq(LEB128Lib.encode(int256(420)), hex"a403");
        assertEq(LEB128Lib.encode(int256(-420)), hex"dc7c");
        assertEq(LEB128Lib.encode(int256(1 ether)), hex"808090bbbad6adf00d");
        assertEq(LEB128Lib.encode(int256(-1 ether)), hex"8080f0c4c5a9d28f72");
        assertEq(
            LEB128Lib.encode(int256(type(int256).max - 1)),
            hex"feffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff07"
        );
        assertEq(
            LEB128Lib.encode(int256(type(int256).min + 1)),
            hex"81808080808080808080808080808080808080808080808080808080808080808080808078"
        );
        assertEq(
            LEB128Lib.encode(int256(type(int256).max)),
            hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff07"
        );
        assertEq(
            LEB128Lib.encode(int256(type(int256).min)),
            hex"80808080808080808080808080808080808080808080808080808080808080808080808078"
        );
    }

    function testUnsignedEncode() public {
        assertEq(LEB128Lib.encode(uint256(0)), hex"00");
        assertEq(LEB128Lib.encode(uint256(1)), hex"01");
        assertEq(LEB128Lib.encode(uint256(69)), hex"45");
        assertEq(LEB128Lib.encode(uint256(420)), hex"a403");
        assertEq(LEB128Lib.encode(uint256(666)), hex"9a05");
        assertEq(LEB128Lib.encode(uint256(1 ether)), hex"808090bbbad6adf00d");
        assertEq(
            LEB128Lib.encode(type(uint256).max - 1),
            hex"feffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0f"
        );
        assertEq(
            LEB128Lib.encode(type(uint256).max),
            hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0f"
        );
    }

    function testUnsignedEncodeLength(uint256 x) public {
        vm.assume(x != 0);
        assertEq(LEB128Lib.encode(x).length, _encodedUintLength(x));
    }

    function testSignedEncodeLength(int256 x) public {
        vm.assume(x != 0);
        assertEq(LEB128Lib.encode(x).length, _encodedIntLength(x));
    }

    function testEncodeDecode(uint256 x) public {
        bytes memory uencoded = LEB128Lib.encode(x);
        bytes memory sencoded = LEB128Lib.encode(int256(x));

        {
            (uint256 decoded, bytes memory rem) = leb128.decodeUint(uencoded);
            assertEq(decoded, x);
            assertEq(rem.length, 0);
        }
        {
            (int256 decoded, bytes memory rem) = leb128.decodeInt(sencoded);
            assertEq(decoded, int256(x));
            assertEq(rem.length, 0);
        }
        {
            (uint256 decoded, uint256 size) = LEB128Lib.memDecodeUint(uencoded);
            assertEq(decoded, x);
            assertEq(size, _encodedUintLength(x));
        }
        {
            (int256 decoded, uint256 size) = LEB128Lib.memDecodeInt(sencoded);
            assertEq(decoded, int256(x));
            assertEq(size, _encodedIntLength(int256(x)));
        }
    }

    // Empty input revert for high level decoding methods.
    function testRevertOnEmptyInput() public {
        vm.expectRevert();
        leb128.decodeUint(hex"");

        vm.expectRevert();
        leb128.decodeInt(hex"");

        vm.expectRevert();
        LEB128Lib.memDecodeUint(hex"");

        vm.expectRevert();
        LEB128Lib.memDecodeInt(hex"");
    }

    // Out of bounds revert for high level decoding methods.
    function testRevertOnOutOfBoundsDecoding(uint256 x) public {
        bytes memory uencoded = LEB128Lib.encode(x);
        bytes memory sencoded = LEB128Lib.encode(int256(x));

        uencoded[uencoded.length - 1] ^= 0x80;
        sencoded[sencoded.length - 1] ^= 0x80;

        vm.expectRevert();
        leb128.decodeUint(uencoded);

        vm.expectRevert();
        leb128.decodeInt(sencoded);

        vm.expectRevert();
        LEB128Lib.memDecodeUint(uencoded);

        vm.expectRevert();
        LEB128Lib.memDecodeInt(sencoded);
    }

    // No out of bounds revert for raw decoding methods.
    function testNoRevertOnOutOfBoundsRawDecoding(uint256 x) public view {
        bytes memory uencoded = LEB128Lib.encode(x);
        bytes memory sencoded = LEB128Lib.encode(int256(x));

        uint256 uencodedPtr;
        uint256 sencodedPtr;
        /// @solidity memory-safe-assembly
        assembly {
            uencodedPtr := add(uencoded, 0x20)
            sencodedPtr := add(sencoded, 0x20)
        }

        uencoded[uencoded.length - 1] ^= 0x80;
        sencoded[sencoded.length - 1] ^= 0x80;

        leb128.rawDecodeUint(uencoded);
        leb128.rawDecodeInt(sencoded);
        LEB128Lib.rawMemDecodeUint(uencodedPtr);
        LEB128Lib.rawMemDecodeInt(sencodedPtr);
    }
}
