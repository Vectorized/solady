// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/TestPlus.sol";
import {Base64} from "../src/utils/Base64.sol";
import {LibString} from "../src/utils/LibString.sol";

contract Base64Test is TestPlus {
    function testBase64EncodeEmptyString() public {
        _testBase64Encode("", "");
    }

    function testBase64EncodeShortStrings() public {
        _testBase64Encode("M", "TQ==");
        _testBase64Encode("Mi", "TWk=");
        _testBase64Encode("Mil", "TWls");
        _testBase64Encode("Mila", "TWlsYQ==");
        _testBase64Encode("Milad", "TWlsYWQ=");
        _testBase64Encode("Milady", "TWlsYWR5");
    }

    function testBase64EncodeToStringWithDoublePadding() public {
        _testBase64Encode("test", "dGVzdA==");
    }

    function testBase64EncodeToStringWithSinglePadding() public {
        _testBase64Encode("test1", "dGVzdDE=");
    }

    function testBase64EncodeToStringWithNoPadding() public {
        _testBase64Encode("test12", "dGVzdDEy");
    }

    function testBase64EncodeSentence() public {
        _testBase64Encode(
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            "TG9yZW0gaXBzdW0gZG9sb3Igc2l0IGFtZXQsIGNvbnNlY3RldHVyIGFkaXBpc2NpbmcgZWxpdC4="
        );
    }

    function testBase64WordBoundary() public {
        // Base64.encode allocates memory in multiples of 32 bytes.
        // This checks if the amount of memory allocated is enough.
        _testBase64Encode("012345678901234567890", "MDEyMzQ1Njc4OTAxMjM0NTY3ODkw");
        _testBase64Encode("0123456789012345678901", "MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMQ==");
        _testBase64Encode("01234567890123456789012", "MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI=");
        _testBase64Encode("012345678901234567890123", "MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTIz");
        _testBase64Encode("0123456789012345678901234", "MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTIzNA==");
    }

    function _testBase64Encode(string memory input, string memory output) private {
        string memory encoded = Base64.encode(bytes(input));

        assembly {
            let freeMemoryPointer := mload(0x40)
            // This ensures that the memory allocated is 32-byte aligned.
            if and(freeMemoryPointer, 31) {
                revert(0, 0)
            }
            // Write some garbage to the free memory.
            // If the allocated memory is insufficient, this will change the
            // decoded string and cause the subsequent asserts to fail.
            mstore(freeMemoryPointer, keccak256(0x00, 0x60))
        }

        assertEq(keccak256(bytes(encoded)), keccak256(bytes(output)));
    }

    function testBase64EncodeDecode(bytes memory input) public {
        string memory encoded = Base64.encode(input);
        bytes memory decoded = Base64.decode(encoded);

        assertEq(input, decoded);
    }

    function testBase64DecodeShortStringGas() public {
        assertEq(Base64.decode("TWlsYWR5").length, 6);
    }

    function testBase64DecodeSentenceGas() public {
        assertEq(
            Base64.decode("TG9yZW0gaXBzdW0gZG9sb3Igc2l0IGFtZXQsIGNvbnNlY3RldHVyIGFkaXBpc2NpbmcgZWxpdC4=").length,
            56
        );
    }

    function testBase64EncodeDecodeAltModes(bytes memory input, uint256 randomness) public brutalizeMemory {
        for (uint256 i; i < 2; ++i) {
            string memory encoded = Base64.encode(input);

            if (randomness & (1 << 0) != 0) {
                encoded = LibString.replace(encoded, "=", "");
            }
            if (randomness & (1 << 1) != 0) {
                encoded = LibString.replace(encoded, "/", ",");
            }
            if (randomness & (1 << 2) != 0) {
                encoded = LibString.replace(encoded, "/", "_");
            }
            if (randomness & (1 << 3) != 0) {
                encoded = LibString.replace(encoded, "+", "-");
            }

            _roundUpFreeMemoryPointer();
            bytes memory decoded = Base64.decode(encoded);
            _brutalizeFreeMemoryStart();

            assertEq(input, decoded);

            input = abi.encode(encoded);
        }
    }

    function testBase64EncodeFileSafeAndNoPadding(
        bytes memory input,
        bool fileSafe,
        bool noPadding
    ) public {
        string memory expectedEncoded = Base64.encode(input);

        if (fileSafe) {
            expectedEncoded = LibString.replace(expectedEncoded, "+", "-");
            expectedEncoded = LibString.replace(expectedEncoded, "/", "_");
        }
        if (noPadding) {
            expectedEncoded = LibString.replace(expectedEncoded, "=", "");
        }

        assertEq(Base64.encode(input, fileSafe, noPadding), expectedEncoded);
    }

    function testBase64DecodeMemorySafety(bytes memory input) public brutalizeMemory {
        _roundUpFreeMemoryPointer();
        bytes memory decoded = bytes(Base64.decode(string(input)));
        _brutalizeFreeMemoryStart();

        bytes32 hashBefore = keccak256(decoded);

        assembly {
            let freeMemoryPointer := mload(0x40)
            // This ensures that the memory allocated is 32-byte aligned.
            if and(freeMemoryPointer, 31) {
                revert(0, 0)
            }
            // Write some garbage to the free memory.
            // If the allocated memory is insufficient, this will change the
            // decoded string and cause the subsequent asserts to fail.
            mstore(freeMemoryPointer, hashBefore)
        }
        bytes32 hashAfter = keccak256(decoded);
        assertEq(hashBefore, hashAfter);
    }
}
