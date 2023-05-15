// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {LibZip} from "../src/utils/LibZip.sol";

contract LibZipTest is SoladyTest {
    bytes32 public numbersHash;
    uint256 public lastCallvalue;

    error NumbersHash(bytes32 h);

    function testCdCompressDecompress(bytes memory data) public brutalizeMemory {
        bytes32 dataHash = keccak256(data);
        bytes memory compressed = LibZip.cdCompress(data);
        bytes32 compressedHash = keccak256(compressed);
        _checkMemory(compressed);
        bytes memory decompressed = LibZip.cdDecompress(compressed);
        _checkMemory(compressed);
        _checkMemory(decompressed);
        assertEq(decompressed, data);
        assertEq(keccak256(data), dataHash);
        assertEq(keccak256(compressed), compressedHash);
    }

    function testCdCompressDecompress(uint256) public brutalizeMemory {
        unchecked {
            uint256 n = _random() % 8 == 0 ? _random() % 2048 : _random() % 256;
            bytes memory data = new bytes(n);
            if (_random() % 2 == 0) {
                /// @solidity memory-safe-assembly
                assembly {
                    for { let i := 0 } lt(i, n) { i := add(i, 0x20) } {
                        mstore(add(add(data, 0x20), i), not(0))
                    }
                }
            }
            if (n != 0) {
                uint256 m = _random() % 8;
                for (uint256 j; j < m; ++j) {
                    data[_random() % n] = bytes1(uint8(_random()));
                }
            }
            bytes memory compressed = LibZip.cdCompress(data);
            bytes memory decompressed = LibZip.cdDecompress(compressed);
            assertEq(decompressed, data);
        }
    }

    function testCdCompress() public {
        bytes memory data =
            hex"ac9650d80000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000022000000000000000000000000000000000000000000000000000000000000002a000000000000000000000000000000000000000000000000000000000000000a40c49ccbe000000000000000000000000000000000000000000000000000000000005b70e00000000000000000000000000000000000000000000000000000dfc79825feb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000645c48a7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000084fc6f7865000000000000000000000000000000000000000000000000000000000005b70e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffff00000000000000000000000000000000ffffffffffffffffffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004449404b7c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001f1cdf1a632eaaab40d1c263edf49faf749010a1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000064df2ab5bb0000000000000000000000007f5c764cbc14f9669b88837ca1490cca17c3160700000000000000000000000000000000000000000000000000000000000000000000000000000000000000001f1cdf1a632eaaab40d1c263edf49faf749010a100000000000000000000000000000000000000000000000000000000";
        bytes memory expected =
            hex"5369af27001e20001e04001e80001d0160001d0220001d02a0001ea40c49ccbe001c05b70e00190dfc79825feb005b645c48a7003a84fc6f7865001c05b70e002f008f000f008f003a4449404b7c002b1f1cdf1a632eaaab40d1c263edf49faf749010a1003a64df2ab5bb000b7f5c764cbc14f9669b88837ca1490cca17c31607002b1f1cdf1a632eaaab40d1c263edf49faf749010a1001b";
        assertEq(LibZip.cdCompress(data), expected);
    }

    function testDecompressWontRevert(bytes memory data) public brutalizeMemory {
        data = LibZip.cdDecompress(data);
        bytes memory compressed = LibZip.cdCompress(data);
        bytes memory decompressed = LibZip.cdDecompress(compressed);
        assertEq(decompressed, data);
    }

    function testCdFallback() public {
        uint256[] memory numbers = new uint256[](100);
        unchecked {
            for (uint256 i; i < numbers.length; ++i) {
                numbers[i] = i % 2 == 0 ? i : ~i;
            }
        }
        assertEq(numbersHash, 0);
        assertEq(lastCallvalue, 0);

        uint256 v = 123 ether;
        vm.deal(address(this), v);

        (bool success, bytes memory result) = payable(this).call{value: v}(
            LibZip.cdCompress(
                abi.encodeWithSignature("storeNumbersHash(uint256[],bool)", numbers, true)
            )
        );

        assertTrue(success);
        bytes32 decodedNumbersHash = abi.decode(result, (bytes32));
        bytes32 expectedNumbersHash = keccak256(abi.encode(numbers));
        assertEq(numbersHash, expectedNumbersHash);
        assertEq(decodedNumbersHash, expectedNumbersHash);
        assertEq(lastCallvalue, v);

        (success, result) = payable(this).call{value: v}(
            LibZip.cdCompress(
                abi.encodeWithSignature("storeNumbersHash(uint256[],bool)", numbers, false)
            )
        );

        assertFalse(success);
        assertEq(abi.encodeWithSelector(NumbersHash.selector, expectedNumbersHash), result);
    }

    function storeNumbersHash(uint256[] calldata numbers, bool success)
        external
        payable
        returns (bytes32 result)
    {
        result = keccak256(abi.encode(numbers));
        numbersHash = result;
        lastCallvalue = msg.value;
        if (!success) {
            revert NumbersHash(keccak256(abi.encode(numbers)));
        }
    }

    receive() external payable {
        LibZip.cdFallback();
    }

    fallback() external payable {
        LibZip.cdFallback();
    }
}
