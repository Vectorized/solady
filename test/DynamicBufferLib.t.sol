// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/TestPlus.sol";
import {DynamicBufferLib} from "../src/utils/DynamicBufferLib.sol";

contract DynamicBufferLibTest is TestPlus {
    using DynamicBufferLib for DynamicBufferLib.DynamicBuffer;

    function testDynamicBuffer(bytes[] memory inputs, uint256 randomness) public brutalizeMemory {
        _boundInputs(inputs);

        bytes memory expectedResult;
        unchecked {
            for (uint256 i; i < inputs.length; ++i) {
                expectedResult = bytes.concat(expectedResult, inputs[i]);
            }
        }
        _roundUpFreeMemoryPointer();

        DynamicBufferLib.DynamicBuffer memory dynamicBuffer;
        unchecked {
            if (randomness % 2 == 0) {
                if (inputs.length > 0) {
                    dynamicBuffer.data = inputs[0];
                    for (uint256 i = 1; i < inputs.length; ++i) {
                        dynamicBuffer.append(inputs[i]);
                        _brutalizeFreeMemoryStart();
                        _checkBytesIsZeroRightPadded(dynamicBuffer.data);
                    }
                }
            } else {
                for (uint256 i; i < inputs.length; ++i) {
                    dynamicBuffer.append(inputs[i]);
                    _brutalizeFreeMemoryStart();
                    _checkBytesIsZeroRightPadded(dynamicBuffer.data);
                }
            }
        }
        assertEq(keccak256(dynamicBuffer.data), keccak256(expectedResult));
    }

    function testJoinWithConcat() public pure {
        bytes memory expectedResult;
        bytes[] memory chunks = _getChunks();
        unchecked {
            for (uint256 i; i < chunks.length; ++i) {
                expectedResult = bytes.concat(expectedResult, chunks[i]);
            }
        }
    }

    function testJoinWithDynamicBuffer() public pure {
        DynamicBufferLib.DynamicBuffer memory dynamicBuffer;
        bytes[] memory chunks = _getChunks();
        unchecked {
            for (uint256 i; i < chunks.length; ++i) {
                dynamicBuffer.append(chunks[i]);
            }
        }
    }

    function _getChunks() internal pure returns (bytes[] memory chunks) {
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
    }

    function _checkBytesIsZeroRightPadded(bytes memory s) internal pure {
        bool failed;
        assembly {
            let lastAlignedWord := mload(add(add(s, 0x20), and(mload(s), not(31))))
            let remainder := and(mload(s), 31)
            if remainder {
                if shl(mul(8, remainder), lastAlignedWord) {
                    failed := 1
                }
            }
        }
        if (failed) revert("Bytes is not zero right padded!");
    }

    function _boundInputs(bytes[] memory inputs) internal pure {
        // Limit the total number of inputs.
        assembly {
            if gt(mload(inputs), 16) {
                mstore(inputs, 16)
            }
        }
        unchecked {
            // Limit the lengths of the inputs.
            for (uint256 i; i < inputs.length; ++i) {
                bytes memory x = inputs[i];
                assembly {
                    if gt(mload(x), 256) {
                        mstore(x, 256)
                    }
                }
            }
        }
    }
}
