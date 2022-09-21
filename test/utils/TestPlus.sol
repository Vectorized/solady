// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";

contract TestPlus is Test {
    modifier brutalizeMemory(bytes memory brutalizeWith) {
        /// @solidity memory-safe-assembly
        assembly {
            // Fill the 64 bytes of scratch space with the data.
            pop(
                staticcall(
                    gas(), // Pass along all the gas in the call.
                    0x04, // Call the identity precompile address.
                    brutalizeWith, // Offset is the bytes' pointer.
                    64, // Copy enough to only fill the scratch space.
                    0, // Store the return value in the scratch space.
                    64 // Scratch space is only 64 bytes in size, we don't want to write further.
                )
            )

            let size := add(mload(brutalizeWith), 32) // Add 32 to include the 32 byte length slot.

            // Fill the free memory pointer's destination with the data.
            pop(
                staticcall(
                    gas(), // Pass along all the gas in the call.
                    0x04, // Call the identity precompile address.
                    brutalizeWith, // Offset is the bytes' pointer.
                    size, // We want to pass the length of the bytes.
                    mload(0x40), // Store the return value at the free memory pointer.
                    size // Since the precompile just returns its input, we reuse size.
                )
            )
        }

        _;
    }

    modifier brutalizeMemoryWithSeed(uint256 seed) {
        /// @solidity memory-safe-assembly
        assembly {
            // Fill the 64 bytes of scratch space with garbage.
            mstore(0x00, gas())
            mstore(0x20, xor(caller(), seed))
            mstore(0x00, keccak256(0x00, 0x40))
            mstore(0x20, keccak256(0x00, 0x40))

            let offset := mload(0x40) // Start the offset at the free memory pointer.
            let size := 0x40 // Start with 2 slots.
            mstore(offset, mload(0x00))
            mstore(add(offset, 0x20), mload(0x20))

            for {
                let i := 0
            } lt(i, 10) {
                i := add(i, 1)
            } {
                let nextOffset := add(offset, size)
                // Duplicate the data.
                pop(
                    staticcall(
                        gas(), // Pass along all the gas in the call.
                        0x04, // Call the identity precompile address.
                        offset, // Offset is the bytes' pointer.
                        size, // We want to pass the length of the bytes.
                        nextOffset, // Store the return value at the next offset.
                        size // Since the precompile just returns its input, we reuse size.
                    )
                )
                // Duplicate the data again.
                returndatacopy(add(nextOffset, size), 0, size)
                offset := nextOffset
                size := mul(2, size)
            }
        }

        _;
    }
}
