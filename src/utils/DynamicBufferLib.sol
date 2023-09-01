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
    /// You can directly assign to `data`, and the `p` function will
    /// take care of the memory allocation.
    struct DynamicBuffer {
        bytes data;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OPERATIONS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Reserves at least `minimum` amount of contiguous memory.
    function reserve(DynamicBuffer memory buffer, uint256 minimum)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = buffer;
        uint256 n = buffer.data.length;
        if (minimum > n) {
            uint256 i = 0x40;
            do {
                i = i << 1;
            } while (i < minimum);
            bytes memory data;
            /// @solidity memory-safe-assembly
            assembly {
                data := 0x00
                mstore(data, sub(i, n))
            }
            result = p(result, data);
        }
    }

    /// @dev Clears the buffer without deallocating the memory.
    function clear(DynamicBuffer memory buffer)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(mload(buffer), 0)
            result := buffer
        }
    }

    /// @dev Appends `data` to `buffer`.
    /// Returns the same buffer, so that it can be used for function chaining.
    function p(DynamicBuffer memory buffer, bytes memory data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        /// @solidity memory-safe-assembly
        assembly {
            result := buffer
            if mload(data) {
                let w := not(0x1f)
                let bufferData := mload(buffer)
                let bufferDataLength := mload(bufferData)
                let newBufferDataLength := add(mload(data), bufferDataLength)
                // Some random prime number to multiply `capacity`, so that
                // we know that the `capacity` is for a dynamic buffer.
                // Selected to be larger than any memory pointer realistically.
                let prime := 1621250193422201
                let capacity := mload(add(bufferData, w)) // `mload(sub(bufferData, 0x20))`.

                // Extract `capacity`, initializing it to zero if it is not a multiple of `prime`.
                capacity := mul(div(capacity, prime), iszero(mod(capacity, prime)))

                // Expand / Reallocate memory if required.
                // Note that we need to allocate an extra word for the length, and
                // and another extra word as a safety word (giving a total of 0x40 bytes).
                // Without the safety word, the backwards copying can cause a buffer overflow.
                for {} iszero(lt(newBufferDataLength, capacity)) {} {
                    // Set `newCapacity` to `(2 * capacity + 0x20) / 0x20 * 0x20`,
                    // ensuring more than enough space.
                    let newCapacity :=
                        and(add(capacity, add(or(capacity, newBufferDataLength), 0x20)), w)

                    // If the memory is discontiguous, we have to reallocate.
                    if iszero(eq(mload(0x40), add(bufferData, add(0x40, capacity)))) {
                        // Set the `newBufferData` to point to the word after capacity.
                        let newBufferData := add(mload(0x40), 0x20)
                        // Reallocate the memory.
                        mstore(0x40, add(newBufferData, add(0x40, newCapacity)))
                        // Store the `newBufferData`.
                        mstore(buffer, newBufferData)
                        // Copy `bufferData` one word at a time, backwards.
                        for { let o := and(add(bufferDataLength, 0x20), w) } 1 {} {
                            mstore(add(newBufferData, o), mload(add(bufferData, o)))
                            o := add(o, w) // `sub(o, 0x20)`.
                            if iszero(o) { break }
                        }
                        // Store the `capacity * prime` in the word before the `length`.
                        mstore(add(newBufferData, w), mul(prime, newCapacity))
                        // Assign `newBufferData` to `bufferData`.
                        bufferData := newBufferData
                        break
                    }
                    // Otherwise, we can expand the memory.
                    mstore(0x40, add(bufferData, add(0x40, newCapacity)))
                    // Store the `capacity * prime` in the word before the `length`.
                    mstore(add(bufferData, w), mul(prime, newCapacity))
                    break
                }
                if iszero(gt(data, 0x60)) {
                    mstore(data, 0)
                    newBufferDataLength := bufferDataLength
                }
                // Initialize `output` to the next empty position in `bufferData`.
                let output := add(bufferData, bufferDataLength)
                // Copy `data` one word at a time, backwards.
                for { let o := and(add(mload(data), 0x20), w) } 1 {} {
                    mstore(add(output, o), mload(add(data, o)))
                    o := add(o, w) // `sub(o, 0x20)`.
                    if iszero(o) { break }
                }
                // Zeroize the word after the buffer.
                mstore(add(add(bufferData, 0x20), newBufferDataLength), 0)
                // Store the `newBufferDataLength`.
                mstore(bufferData, newBufferDataLength)
            }
        }
    }

    /// @dev Appends `data0`, `data1` to `buffer`.
    /// Returns the same buffer, so that it can be used for function chaining.
    function p(DynamicBuffer memory buffer, bytes memory data0, bytes memory data1)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(p(buffer, data0), data1);
    }

    /// @dev Appends `data0` .. `data2` to `buffer`.
    /// Returns the same buffer, so that it can be used for function chaining.
    function p(
        DynamicBuffer memory buffer,
        bytes memory data0,
        bytes memory data1,
        bytes memory data2
    ) internal pure returns (DynamicBuffer memory result) {
        _deallocate(result);
        result = p(p(p(buffer, data0), data1), data2);
    }

    /// @dev Appends `data0` .. `data3` to `buffer`.
    /// Returns the same buffer, so that it can be used for function chaining.
    function p(
        DynamicBuffer memory buffer,
        bytes memory data0,
        bytes memory data1,
        bytes memory data2,
        bytes memory data3
    ) internal pure returns (DynamicBuffer memory result) {
        _deallocate(result);
        result = p(p(p(p(buffer, data0), data1), data2), data3);
    }

    /// @dev Appends `data0` .. `data4` to `buffer`.
    /// Returns the same buffer, so that it can be used for function chaining.
    function p(
        DynamicBuffer memory buffer,
        bytes memory data0,
        bytes memory data1,
        bytes memory data2,
        bytes memory data3,
        bytes memory data4
    ) internal pure returns (DynamicBuffer memory result) {
        _deallocate(result);
        result = p(p(p(p(p(buffer, data0), data1), data2), data3), data4);
    }

    /// @dev Appends `data0` .. `data5` to `buffer`.
    /// Returns the same buffer, so that it can be used for function chaining.
    function p(
        DynamicBuffer memory buffer,
        bytes memory data0,
        bytes memory data1,
        bytes memory data2,
        bytes memory data3,
        bytes memory data4,
        bytes memory data5
    ) internal pure returns (DynamicBuffer memory result) {
        _deallocate(result);
        result = p(p(p(p(p(p(buffer, data0), data1), data2), data3), data4), data5);
    }

    /// @dev Appends `data0` .. `data6` to `buffer`.
    /// Returns the same buffer, so that it can be used for function chaining.
    function p(
        DynamicBuffer memory buffer,
        bytes memory data0,
        bytes memory data1,
        bytes memory data2,
        bytes memory data3,
        bytes memory data4,
        bytes memory data5,
        bytes memory data6
    ) internal pure returns (DynamicBuffer memory result) {
        _deallocate(result);
        result = p(p(p(p(p(p(p(buffer, data0), data1), data2), data3), data4), data5), data6);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Helper for deallocating a automatically allocated `buffer` pointer.
    function _deallocate(DynamicBuffer memory result) private pure {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x40, result) // Deallocate, as we have already allocated.
        }
    }
}
