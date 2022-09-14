// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {Base64} from "../src/utils/Base64.sol";

contract Base64Test is Test {
    function testBase64EncodeEmptyString() public {
        _testBase64("", "");
    }

    function testBase64EncodeShortStrings() public {
        _testBase64("M", "TQ==");
        _testBase64("Mi", "TWk=");
        _testBase64("Mil", "TWls");
        _testBase64("Mila", "TWlsYQ==");
        _testBase64("Milad", "TWlsYWQ=");
        _testBase64("Milady", "TWlsYWR5");
    }

    function testBase64EncodeToStringWithDoublePadding() public {
        _testBase64("test", "dGVzdA==");
    }

    function testBase64EncodeToStringWithSinglePadding() public {
        _testBase64("test1", "dGVzdDE=");
    }

    function testBase64EncodeToStringWithNoPadding() public {
        _testBase64("test12", "dGVzdDEy");
    }

    function testBase64EncodeSentence() public {
        _testBase64(
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            "TG9yZW0gaXBzdW0gZG9sb3Igc2l0IGFtZXQsIGNvbnNlY3RldHVyIGFkaXBpc2NpbmcgZWxpdC4="
        );
    }

    function testBase64WordBoundary() public {
        // Base64.encode allocates memory in multiples of 32 bytes.
        // This checks if the amount of memory allocated is enough.
        _testBase64("012345678901234567890", "MDEyMzQ1Njc4OTAxMjM0NTY3ODkw");
        _testBase64("0123456789012345678901", "MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMQ==");
        _testBase64("01234567890123456789012", "MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI=");
        _testBase64("012345678901234567890123", "MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTIz");
        _testBase64("0123456789012345678901234", "MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTIzNA==");
    }

    function _testBase64(string memory input, string memory output) private {
        string memory encoded = Base64.encode(bytes(input));
        bool freeMemoryPointerIs32ByteAligned;
        assembly {
            let freeMemoryPointer := mload(0x40)
            // This ensures that the memory allocated is 32-byte aligned.
            freeMemoryPointerIs32ByteAligned := iszero(and(freeMemoryPointer, 31))
            // Write a non Base64 character to the free memory pointer.
            // If the allocated memory is insufficient, this will change the
            // encoded string and cause the subsequent asserts to fail.
            mstore(freeMemoryPointer, "#")
        }
        assertTrue(freeMemoryPointerIs32ByteAligned);
        assertEq(keccak256(bytes(encoded)), keccak256(bytes(output)));
    }

    function testBase64EncodeDecode(bytes memory input) public {
        string memory encoded = Base64.encode(input);
        bytes memory decoded = Base64.decode(encoded);
        assertEq(input, decoded);
    }

    function testBase64DecodeShortString() public {
        // Mainly for testing gas.
        assertEq(Base64.decode("TWlsYWR5").length, 6);
    }

    function testBase64DecodeSentence() public {
        // Mainly for testing gas.
        assertEq(
            Base64.decode("TG9yZW0gaXBzdW0gZG9sb3Igc2l0IGFtZXQsIGNvbnNlY3RldHVyIGFkaXBpc2NpbmcgZWxpdC4=").length,
            56
        );
    }

    function testBase64EncodeDecodeNoPadding(bytes memory input) public {
        string memory encoded = Base64.encode(input);
        assembly {
            let lastBytes := mload(add(encoded, mload(encoded)))
            mstore(
                encoded,
                sub(mload(encoded), add(eq(and(lastBytes, 0xFF), 0x3d), eq(and(lastBytes, 0xFFFF), 0x3d3d)))
            )
        }
        bytes memory decoded = Base64.decode(encoded);
        assertEq(input, decoded);
    }
}
