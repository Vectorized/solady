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

    function testCdFallback() public {
        uint256[] memory numbers = new uint256[](100);
        for (uint256 i; i < numbers.length; ++i) {
            numbers[i] = i;
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
