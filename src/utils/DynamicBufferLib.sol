// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for buffers with automatic capacity resizing.
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
                let w := not(31)
                let bufferData := mload(buffer)
                let bufferDataLength := mload(bufferData)
                let newBufferDataLength := add(mload(data), bufferDataLength)
                // Some random prime number to multiply `capacity`, so that
                // we know that the `capacity` is for a dynamic buffer.
                // Selected to be larger than any memory pointer realistically.
                let prime := 1621250193422201
                let capacity := mload(add(bufferData, w))

                // Extract `capacity`, and set it to 0, if it is not a multiple of `prime`.
                capacity := mul(div(capacity, prime), iszero(mod(capacity, prime)))

                // Expand / Reallocate memory if required.
                // Note that we need to allocate an exta word for the length, and
                // and another extra word as a safety word (giving a total of 0x40 bytes).
                // Without the safety word, the data at the next free memory word can be overwritten,
                // because the backwards copying can exceed the buffer space used for storage.
                // prettier-ignore
                for {} iszero(lt(newBufferDataLength, capacity)) {} {
                    // Approximately double the memory with a heuristic,
                    // ensuring more than enough space for the combined data,
                    // rounding up to the next multiple of 32.
                    let newCapacity := and(add(capacity, add(or(capacity, newBufferDataLength), 32)), w)

                    // If next word after current buffer is not eligible for use.
                    if iszero(eq(mload(0x40), add(bufferData, add(0x40, capacity)))) {
                        // Set the `newBufferData` to point to the word after capacity.
                        let newBufferData := add(mload(0x40), 0x20)
                        // Reallocate the memory.
                        mstore(0x40, add(newBufferData, add(0x40, newCapacity)))
                        // Store the `newBufferData`.
                        mstore(buffer, newBufferData)
                        // Copy `bufferData` one word at a time, backwards.
                        // prettier-ignore
                        for { let o := and(add(bufferDataLength, 32), w) } 1 {} {
                            mstore(add(newBufferData, o), mload(add(bufferData, o)))
                            o := add(o, w) // `sub(o, 0x20)`.
                            // prettier-ignore
                            if iszero(o) { break }
                        }
                        // Store the `capacity` multiplied by `prime` in the word before the `length`.
                        mstore(add(newBufferData, w), mul(prime, newCapacity))
                        // Assign `newBufferData` to `bufferData`.
                        bufferData := newBufferData
                        break
                    }
                    // Expand the memory.
                    mstore(0x40, add(bufferData, add(0x40, newCapacity)))
                    // Store the `capacity` multiplied by `prime` in the word before the `length`.
                    mstore(add(bufferData, w), mul(prime, newCapacity))
                    break
                }
                // Initalize `output` to the next empty position in `bufferData`.
                let output := add(bufferData, bufferDataLength)
                // Copy `data` one word at a time, backwards.
                // prettier-ignore
                for { let o := and(add(mload(data), 32), w) } 1 {} {
                    mstore(add(output, o), mload(add(data, o)))
                    o := add(o, w)  // `sub(o, 0x20)`.
                    // prettier-ignore
                    if iszero(o) { break }
                }
                // Zeroize the word after the buffer.
                mstore(add(add(bufferData, 0x20), newBufferDataLength), 0)
                // Store the `newBufferDataLength`.
                mstore(bufferData, newBufferDataLength)
            }
        }
    }
}
