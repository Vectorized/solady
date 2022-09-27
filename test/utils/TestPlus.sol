// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";

contract TestPlus is Test {
    modifier brutalizeMemory() {
        /// @solidity memory-safe-assembly
        assembly {
            let offset := mload(0x40) // Start the offset at the free memory pointer.
            calldatacopy(offset, 0, calldatasize())

            // Fill the 64 bytes of scratch space with garbage.
            mstore(0x00, xor(gas(), calldatasize()))
            mstore(0x20, xor(caller(), keccak256(offset, calldatasize())))
            mstore(0x00, keccak256(0x00, 0x40))
            mstore(0x20, keccak256(0x00, 0x40))

            let size := 0x40 // Start with 2 slots.
            mstore(offset, mload(0x00))
            mstore(add(offset, 0x20), mload(0x20))

            // prettier-ignore
            for { let i := add(11, and(mload(0x00), 1)) } 1 {} {
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

                i := sub(i, 1)
                // prettier-ignore
                if iszero(i) { break }
            }
        }

        _;
    }

    function _roundUpFreeMemoryPointer() internal pure {
        assembly {
            mstore(0x40, and(add(mload(0x40), 31), not(31)))
        }
    }

    function _brutalizeFreeMemoryStart() internal pure {
        bool failed;
        assembly {
            let freeMemoryPointer := mload(0x40)
            // This ensures that the memory allocated is 32-byte aligned.
            if and(freeMemoryPointer, 31) {
                failed := 1
            }
            // Write some garbage to the free memory.
            // If the allocated memory is insufficient, this will change the
            // decoded string and cause the subsequent asserts to fail.
            mstore(freeMemoryPointer, keccak256(0x00, 0x60))
        }
        if (failed) revert("Free memory pointer `0x40` is not 32-byte word aligned!");
    }
}
