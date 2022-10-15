// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for dynamic buffers
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/DynamicBuffer.sol)
/// @author Modified from cozyco (https://github.com/samkingco/cozyco/blob/main/contracts/utils/DynamicBuffer.sol)
library DynamicBufferLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Type to represent a dynamic buffer in memory.
    /// You can directly assign to `data`, and the `append` function will
    /// take care of the memory allocation.
    struct DynamicBuffer {
        bytes data;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OPERATIONS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Appends `data` to `buffer`.
    function append(DynamicBuffer memory buffer, bytes memory data) internal pure {
        assembly {
            if mload(data) {
                let bufferData := mload(buffer)
                let bufferDataLength := mload(bufferData)
                let newBufferDataLength := add(mload(data), bufferDataLength)
                // Some random prime number to multiply `capacity`, so that
                // we know that the `capacity` is for a dynamic buffer.
                // Selected to be larger than any memory pointer realistically.
                let prime := 1621250193422201
                let capacity := mload(sub(bufferData, 0x20))

                // Extract `capacity`, and set it to 0
                // if it is not a multiple of `prime`.
                capacity := mul(div(capacity, prime), iszero(mod(capacity, prime)))

                // Reallocate if the `newBufferDataLength` exceeds `capacity`.
                if gt(newBufferDataLength, capacity) {
                    // Approximately double the memory with a heuristic,
                    // ensuring more than enough space for the combined data,
                    // rounding up to the next multiple of 32.
                    capacity := and(add(capacity, add(or(capacity, newBufferDataLength), 32)), not(31))
                    // Store the `capacity` multiplied by `prime` in the slot before the `length`,
                    mstore(mload(0x40), mul(prime, capacity))
                    // Set the `newBufferData` to point to the slot after capacity.
                    let newBufferData := add(mload(0x40), 0x20)
                    // Allocate the memory for the `newBufferData`.
                    mstore(0x40, add(newBufferData, add(0x20, capacity)))
                    // Store the `newBufferData`.
                    mstore(buffer, newBufferData)
                    // Copy `bufferData` one word at a time, backwards.
                    // prettier-ignore
                    for { let o := and(add(bufferDataLength, 32), not(31)) } 1 {} {
                        mstore(add(newBufferData, o), mload(add(bufferData, o)))
                        o := sub(o, 0x20)
                        // prettier-ignore
                        if iszero(o) { break }
                    }
                    // Assign `newBufferData` to `bufferData`.
                    bufferData := newBufferData
                }
                // Initalize `output` to the next empty position in `bufferData`.
                let output := add(bufferData, bufferDataLength)
                // Copy `data` one word at a time, backwards.
                // prettier-ignore
                for { let o := and(add(mload(data), 32), not(31)) } 1 {} {
                    mstore(add(output, o), mload(add(data, o)))
                    o := sub(o, 0x20)
                    // prettier-ignore
                    if iszero(o) { break }
                }
                // Zeroize the slot after the buffer.
                mstore(add(add(bufferData, 0x20), newBufferDataLength), 0)
                // Store the `newBufferDataLength`.
                mstore(bufferData, newBufferDataLength)
            }
        }
    }
}
