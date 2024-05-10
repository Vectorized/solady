// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {DynamicBufferLib} from "../src/utils/DynamicBufferLib.sol";

contract DynamicBufferLibTest is SoladyTest {
    using DynamicBufferLib for DynamicBufferLib.DynamicBuffer;

    function testDynamicBufferPushSingles(uint256 x) public {
        {
            DynamicBufferLib.DynamicBuffer memory buffer;
            assertEq(buffer.data.length, 0x00);
            buffer.pUint256(x);
            assertEq(buffer.data, abi.encodePacked(uint256(x)));
        }

        {
            DynamicBufferLib.DynamicBuffer memory buffer;
            assertEq(buffer.data.length, 0x00);
            buffer.pUint8(uint8(x));
            assertEq(buffer.data, abi.encodePacked(uint8(x)));
        }

        {
            DynamicBufferLib.DynamicBuffer memory buffer;
            assertEq(buffer.data.length, 0x00);
            buffer.pBytes32(bytes32(x));
            assertEq(buffer.data, abi.encodePacked(bytes32(x)));
        }

        {
            DynamicBufferLib.DynamicBuffer memory buffer;
            assertEq(buffer.data.length, 0x00);
            buffer.pBytes1(bytes1(bytes32(x)));
            assertEq(buffer.data, abi.encodePacked(bytes1(bytes32(x))));
        }

        {
            DynamicBufferLib.DynamicBuffer memory buffer;
            assertEq(buffer.data.length, 0x00);
            buffer.pBool(x % 2 == 0);
            assertEq(buffer.data, abi.encodePacked(bool(x % 2 == 0)));
        }

        {
            DynamicBufferLib.DynamicBuffer memory buffer;
            assertEq(buffer.data.length, 0x00);
            buffer.pAddress(address(uint160(x)));
            assertEq(buffer.data, abi.encodePacked(address(uint160(x))));
        }
    }

    function testDynamicBufferPushSinglesReinterpretCast() public {
        uint256 n = 32;
        DynamicBufferLib.DynamicBuffer memory buffer;
        uint256[] memory expected = new uint256[](n);
        unchecked {
            for (uint256 i; i != n; ++i) {
                uint256 v = (i << 128) | 1;
                buffer.pUint256(v);
                expected[i] = v;
            }
        }
        uint256[] memory computed;
        /// @solidity memory-safe-assembly
        assembly {
            computed := mload(buffer)
            let nBytes := mload(computed)
            mstore(computed, shr(5, nBytes))
        }
        assertEq(computed, expected);
    }

    function testClear(uint256) public {
        DynamicBufferLib.DynamicBuffer memory buffer;
        bytes memory b0 = _generateRandomBytes(128, _random());
        bytes memory b1 = _generateRandomBytes(256, _random());
        bytes memory emptyBytes;
        assertEq(buffer.data.length, 0);
        assertEq(emptyBytes.length, 0);
        if (_random() & 1 == 0) buffer.clear();
        assertEq(buffer.data.length, 0);
        assertEq(emptyBytes.length, 0);
        buffer.clear().p(b0);
        assertEq(buffer.data, b0);
        assertEq(emptyBytes.length, 0);
        uint256 n0 = _bound(_random(), 0, 1024);
        uint256 n1 = _bound(_random(), 0, 4096);
        buffer.reserve(n0).p(b1).clear().reserve(n1);
        assertEq(buffer.data.length, 0);
        assertEq(emptyBytes.length, 0);
        buffer.p(b1);
        assertEq(buffer.data, b1);
        assertEq(emptyBytes.length, 0);
        buffer.p(b0);
        assertEq(buffer.data, abi.encodePacked(b1, b0));
        assertEq(emptyBytes.length, 0);
        buffer.clear();
    }

    function testDynamicBufferReserveFromEmpty() public {
        uint256 m = _freeMemoryPointer();
        DynamicBufferLib.DynamicBuffer memory buffer;
        assertEq(_freeMemoryPointer(), m + 0x20);
        buffer.reserve(0x200);
        assertTrue(_freeMemoryPointer() > m + 0x20);
        assertTrue(_freeMemoryPointer() < 0xffff);
        m = _freeMemoryPointer();
        buffer.reserve(0x200);
        assertEq(_freeMemoryPointer(), m);
        buffer.reserve(0x200);
        assertEq(_freeMemoryPointer(), m);
    }

    function testDynamicBufferReserveFromEmpty2() public {
        DynamicBufferLib.DynamicBuffer memory buffer;
        _incrementFreeMemoryPointer();
        buffer.reserve(0x200);
        uint256 m = _freeMemoryPointer();
        buffer.reserve(0x200);
        assertEq(_freeMemoryPointer(), m);
        buffer.reserve(0x200);
        assertEq(_freeMemoryPointer(), m);
    }

    function testDynamicBufferReserveFromEmpty3(bytes calldata b, uint256 t) public {
        DynamicBufferLib.DynamicBuffer memory buffer;
        if (t & 1 == 0) _incrementFreeMemoryPointer();
        if (t & 2 == 0) buffer.p(_generateRandomBytes((t >> 32) & 0xff, 1));
        if (t & 4 == 0) buffer.p(b);
        assertTrue(_freeMemoryPointer() < 0xffffff);
        uint256 r = t >> 240;
        buffer.reserve(r);
        assertTrue(_freeMemoryPointer() < 0xffffff);
        uint256 m = _freeMemoryPointer();
        buffer.reserve(r);
        assertEq(_freeMemoryPointer(), m);
        buffer.reserve(r);
        assertEq(_freeMemoryPointer(), m);
    }

    function _incrementFreeMemoryPointer() internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x40, add(mload(0x40), 0x20))
        }
    }

    function _freeMemoryPointer() internal pure returns (uint256 m) {
        /// @solidity memory-safe-assembly
        assembly {
            m := mload(0x40)
        }
    }

    function _bufferLocation(DynamicBufferLib.DynamicBuffer memory buffer)
        internal
        pure
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(buffer)
        }
    }

    function testDynamicBuffer(uint256) public brutalizeMemory {
        unchecked {
            if (_random() & 7 == 0) _misalignFreeMemoryPointer();
            DynamicBufferLib.DynamicBuffer memory bufferA;
            DynamicBufferLib.DynamicBuffer memory bufferB;
            uint256 z = _bound(_random(), 32, 4096);
            if (_random() & 7 == 0) bufferA.reserve(_random() % z);
            if (_random() & 7 == 0) bufferB.reserve(_random() % z);
            uint256 r = _random() % 3;
            uint256 o = _bound(_random(), 0, 32);
            uint256 n = _bound(_random(), 5, _random() & 7 == 0 ? 64 : 8);
            z = z + z;

            if (r == 0) {
                for (uint256 i; i != n; ++i) {
                    if (_random() & 7 == 0) bufferA.reserve(_random() % z);
                    bufferA.p(_generateRandomBytes(i + o, i + z));
                }
                for (uint256 i; i != n; ++i) {
                    if (_random() & 7 == 0) bufferB.reserve(_random() % z);
                    bufferB.p(_generateRandomBytes(i + o, i + z));
                }
            } else if (r == 1) {
                for (uint256 i; i != n; ++i) {
                    if (_random() & 7 == 0) bufferB.reserve(_random() % z);
                    bufferB.p(_generateRandomBytes(i + o, i + z));
                }
                for (uint256 i; i != n; ++i) {
                    if (_random() & 7 == 0) bufferA.reserve(_random() % z);
                    bufferA.p(_generateRandomBytes(i + o, i + z));
                }
            } else {
                uint256 mode;
                for (uint256 i; i != n; ++i) {
                    if (_random() & 7 == 0) mode ^= 1;
                    if (mode == 0) {
                        if (_random() & 7 == 0) bufferA.reserve(_random() % z);
                        bufferA.p(_generateRandomBytes(i + o, i + z));
                        if (_random() & 7 == 0) bufferB.reserve(_random() % z);
                        bufferB.p(_generateRandomBytes(i + o, i + z));
                    } else {
                        if (_random() & 7 == 0) bufferB.reserve(_random() % z);
                        bufferB.p(_generateRandomBytes(i + o, i + z));
                        if (_random() & 7 == 0) bufferA.reserve(_random() % z);
                        bufferA.p(_generateRandomBytes(i + o, i + z));
                    }
                }
            }

            bytes memory expected;
            for (uint256 i; i != n; ++i) {
                expected = bytes.concat(expected, _generateRandomBytes(i + o, i + z));
            }
            assertEq(bufferA.data, expected);
            assertEq(bufferB.data, expected);
        }
    }

    function _generateRandomBytes(uint256 n, uint256 seed)
        internal
        pure
        returns (bytes memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            if n {
                result := mload(0x40)
                mstore(result, n)
                mstore(0x00, seed)
                for { let i := 0 } lt(i, n) { i := add(i, 0x20) } {
                    mstore(0x20, i)
                    mstore(add(add(result, 0x20), i), keccak256(0x00, 0x40))
                }
                mstore(0x40, add(add(result, 0x20), n))
            }
        }
    }

    function testDynamicBuffer(bytes[] memory inputs, uint256 t) public brutalizeMemory {
        _boundInputs(inputs);

        uint256 sharedLocation;
        if ((t >> 128) & 1 == 0) {
            bytes memory first = _generateRandomBytes((t & 0xff | 1), t);
            bytes memory expectedResult = first;
            for (uint256 i; i < inputs.length; ++i) {
                expectedResult = bytes.concat(expectedResult, inputs[i]);
            }
            DynamicBufferLib.DynamicBuffer memory buffer;
            buffer.p(first);
            uint256 location = _bufferLocation(buffer);
            for (uint256 i; i < inputs.length; ++i) {
                buffer.p(inputs[i]);
                assertEq(_bufferLocation(buffer), location);
                _checkMemory(buffer.data);
            }
            assertEq(buffer.data, expectedResult);
            sharedLocation = _bufferLocation(buffer);
        }

        if ((t >> 129) & 1 == 0) {
            if ((t >> 16) & 7 == 0) _misalignFreeMemoryPointer();
            DynamicBufferLib.DynamicBuffer memory buffer;
            if ((t >> 160) & 3 == 0) _incrementFreeMemoryPointer();
            if ((t >> 130) & 1 == 0 && sharedLocation != 0) {
                /// @solidity memory-safe-assembly
                assembly {
                    mstore(buffer, sharedLocation)
                }
                buffer.clear();
            }
            if ((t >> 162) & 3 == 0) _incrementFreeMemoryPointer();
            if ((t >> 32) & 3 == 0) {
                buffer.reserve((t >> 128) % 1024);
            }

            unchecked {
                uint256 expectedLength;
                uint256 start;
                if (t & 1 == 0) {
                    if (inputs.length > 0) {
                        expectedLength = inputs[0].length;
                        buffer.data = inputs[0];
                        start = 1;
                    }
                }
                for (uint256 i = start; i < inputs.length; ++i) {
                    expectedLength += inputs[i].length;
                    // Manually store the t in the next free memory word,
                    // and then check if p will corrupt it
                    // (in the case of insufficient memory allocation).
                    uint256 corruptCheckSlot;
                    /// @solidity memory-safe-assembly
                    assembly {
                        corruptCheckSlot := mload(0x40)
                        mstore(corruptCheckSlot, t)
                        mstore(0x40, add(corruptCheckSlot, 0x20))
                    }
                    buffer.p(inputs[i]);
                    if ((t >> 48) & 7 == 0 && expectedLength != 0) {
                        buffer.reserve((t >> 160) % (expectedLength * 2));
                    }
                    assertEq(buffer.data.length, expectedLength);
                    _checkMemory(buffer.data);
                    bool isCorrupted;
                    /// @solidity memory-safe-assembly
                    assembly {
                        isCorrupted := iszero(eq(t, mload(corruptCheckSlot)))
                    }
                    assertFalse(isCorrupted);
                }
            }

            bytes memory expectedResult;
            unchecked {
                for (uint256 i; i < inputs.length; ++i) {
                    expectedResult = bytes.concat(expectedResult, inputs[i]);
                }
            }

            assertEq(keccak256(buffer.data), keccak256(expectedResult));
        }
    }

    function testJoinWithConcat() public {
        bytes memory expectedResult;
        (bytes[] memory chunks, bytes32 joinedHash) = _getChunks();
        unchecked {
            for (uint256 i; i < chunks.length; ++i) {
                expectedResult = bytes.concat(expectedResult, chunks[i]);
            }
        }
        assertEq(keccak256(expectedResult), joinedHash);
    }

    function testJoinWithDynamicBuffer() public {
        DynamicBufferLib.DynamicBuffer memory buffer;
        (bytes[] memory chunks, bytes32 joinedHash) = _getChunks();
        unchecked {
            for (uint256 i; i < chunks.length; ++i) {
                buffer.p(chunks[i]);
            }
        }
        assertEq(keccak256(buffer.data), joinedHash);
    }

    function testDynamicBufferChaining() public {
        DynamicBufferLib.DynamicBuffer memory bufferA;
        DynamicBufferLib.DynamicBuffer memory bufferB;
        bufferA = bufferB.p("0", "1");
        _checkSamePointers(bufferA, bufferB);
        bufferA = bufferB.p("0", "1", "2");
        _checkSamePointers(bufferA, bufferB);
        bufferA = bufferB.p("0", "1", "2", "3");
        _checkSamePointers(bufferA, bufferB);
        bufferA = bufferB.p("0", "1", "2", "3", "4");
        _checkSamePointers(bufferA, bufferB);
        bufferA = bufferB.p("0", "1", "2", "3", "4", "5");
        _checkSamePointers(bufferA, bufferB);
        bufferA = bufferB.p("0", "1", "2", "3", "4", "5", "6");
        _checkSamePointers(bufferA, bufferB);
        assertEq(bufferA.data, "010120123012340123450123456");
        assertEq(bufferB.data, "010120123012340123450123456");
    }

    function _checkSamePointers(
        DynamicBufferLib.DynamicBuffer memory a,
        DynamicBufferLib.DynamicBuffer memory b
    ) internal {
        bool isSamePointer;
        assembly {
            isSamePointer := eq(a, b)
        }
        assertTrue(isSamePointer);
    }

    function _getChunks() internal pure returns (bytes[] memory chunks, bytes32 joinedHash) {
        chunks = new bytes[](20);
        chunks[0] = bytes(
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
        );
        chunks[1] = bytes("Vitae suscipit tellus mauris a diam maecenas sed enim ut.");
        chunks[2] = bytes("Nisl nisi scelerisque eu ultrices vitae auctor eu augue.");
        chunks[3] = bytes("Et pharetra pharetra massa massa ultricies mi quis.");
        chunks[4] = bytes("Ullamcorper malesuada proin libero nunc.");
        chunks[5] = bytes("Tempus imperdiet nulla malesuada pellentesque.");
        chunks[6] = bytes("Nunc congue nisi vitae suscipit tellus mauris.");
        chunks[7] = bytes("Eu augue ut lectus arcu.");
        chunks[8] = bytes("Natoque penatibus et magnis dis parturient montes nascetur.");
        chunks[9] = bytes("Convallis posuere morbi leo urna.");

        chunks[15] = bytes("Hehe");

        joinedHash = 0x166b0e99fea53034ed188896344996efc141b922127f90922905e478cb26b312;
    }

    function _boundInputs(bytes[] memory inputs) internal pure {
        // Limit the total number of inputs.
        /// @solidity memory-safe-assembly
        assembly {
            if gt(mload(inputs), 16) { mstore(inputs, 16) }
        }
        unchecked {
            // Limit the lengths of the inputs.
            for (uint256 i; i < inputs.length; ++i) {
                bytes memory x = inputs[i];
                /// @solidity memory-safe-assembly
                assembly {
                    if gt(mload(x), 128) { mstore(x, 128) }
                }
            }
        }
    }
}
