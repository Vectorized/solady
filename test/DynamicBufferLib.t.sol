// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {DynamicBufferLib} from "../src/utils/DynamicBufferLib.sol";

contract DynamicBufferLibTest is SoladyTest {
    using DynamicBufferLib for DynamicBufferLib.DynamicBuffer;

    function testDynamicBuffer(bytes[] memory inputs, uint256 randomness) public brutalizeMemory {
        _boundInputs(inputs);

        _roundUpFreeMemoryPointer();
        DynamicBufferLib.DynamicBuffer memory buffer;
        unchecked {
            uint256 expectedLength;
            uint256 start;
            if (randomness & 1 == 0) {
                if (inputs.length > 0) {
                    expectedLength = inputs[0].length;
                    buffer.data = inputs[0];
                    start = 1;
                }
            }
            for (uint256 i = start; i < inputs.length; ++i) {
                expectedLength += inputs[i].length;
                // Manually store the randomness in the next free memory word,
                // and then check if append will corrupt it
                // (in the case of insufficient memory allocation).
                uint256 corruptCheck;
                /// @solidity memory-safe-assembly
                assembly {
                    corruptCheck := mload(0x40)
                    mstore(corruptCheck, randomness)
                    mstore(0x40, add(corruptCheck, 0x20))
                }
                buffer.append(inputs[i]);
                assertEq(buffer.data.length, expectedLength);
                _checkMemory(buffer.data);
                bool isCorrupted;
                /// @solidity memory-safe-assembly
                assembly {
                    isCorrupted := iszero(eq(randomness, mload(corruptCheck)))
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
                buffer.append(chunks[i]);
            }
        }
        assertEq(keccak256(buffer.data), joinedHash);
    }

    function testDynamicBufferChaining() public {
        DynamicBufferLib.DynamicBuffer memory bufferA;
        DynamicBufferLib.DynamicBuffer memory bufferB;
        bufferA = bufferB.append("0", "1");
        _checkSamePointers(bufferA, bufferB);
        bufferA = bufferB.append("0", "1", "2");
        _checkSamePointers(bufferA, bufferB);
        bufferA = bufferB.append("0", "1", "2", "3");
        _checkSamePointers(bufferA, bufferB);
        bufferA = bufferB.append("0", "1", "2", "3", "4");
        _checkSamePointers(bufferA, bufferB);
        bufferA = bufferB.append("0", "1", "2", "3", "4", "5");
        _checkSamePointers(bufferA, bufferB);
        bufferA = bufferB.append("0", "1", "2", "3", "4", "5", "6");
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
                    if gt(mload(x), 300) { mstore(x, 300) }
                }
            }
        }
    }
}
