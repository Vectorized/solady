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
            do {} while ((i <<= 1) < minimum);
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
        }
        result = buffer;
    }

    /// @dev Appends `data` to `buffer`.
    /// Returns the same buffer, so that it can be used for function chaining.
    function p(DynamicBuffer memory buffer, bytes memory data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = buffer;
        if (data.length == 0) return result;
        /// @solidity memory-safe-assembly
        assembly {
            let w := not(0x1f)
            let bufData := mload(buffer)
            let bufDataLen := mload(bufData)
            let newBufDataLen := add(mload(data), bufDataLen)
            // Some random prime number to multiply `cap`, so that
            // we know that the `cap` is for a dynamic buffer.
            // Selected to be larger than any memory pointer realistically.
            let prime := 1621250193422201
            let cap := mload(add(bufData, w)) // `mload(sub(bufData, 0x20))`.
            // Extract `cap`, initializing it to zero if it is not a multiple of `prime`.
            cap := mul(div(cap, prime), iszero(mod(cap, prime)))

            // Expand / Reallocate memory if required.
            // Note that we need to allocate an extra word for the length, and
            // and another extra word as a safety word (giving a total of 0x40 bytes).
            // Without the safety word, the backwards copying can cause a buffer overflow.
            for {} iszero(lt(newBufDataLen, cap)) {} {
                // Approximately more than double the capacity to ensure more than enough space.
                let newCap := and(add(cap, add(or(cap, newBufDataLen), 0x20)), w)
                // If the memory is contiguous, we can simply expand it.
                if iszero(or(xor(mload(0x40), add(bufData, add(0x40, cap))), eq(bufData, 0x60))) {
                    mstore(0x40, add(bufData, add(0x40, newCap)))
                    // Store the `cap * prime` in the word before the `length`.
                    mstore(add(bufData, w), mul(prime, newCap))
                    break
                }
                // Set the `newBufferData` to point to the word after `cap`.
                let newBufferData := add(mload(0x40), 0x20)
                // Reallocate the memory.
                mstore(0x40, add(newBufferData, add(0x40, newCap)))
                // Store the `newBufferData`.
                mstore(buffer, newBufferData)
                // Copy `bufData` one word at a time, backwards.
                for { let o := and(add(bufDataLen, 0x20), w) } 1 {} {
                    mstore(add(newBufferData, o), mload(add(bufData, o)))
                    o := add(o, w) // `sub(o, 0x20)`.
                    if iszero(o) { break }
                }
                // Store the `cap * prime` in the word before the `length`.
                mstore(add(newBufferData, w), mul(prime, newCap))
                // Assign `newBufferData` to `bufData`.
                bufData := newBufferData
                break
            }
            // If it's a reserve operation, set the variables to skip the appending.
            if iszero(data) {
                mstore(data, 0)
                newBufDataLen := bufDataLen
            }
            // Copy `data` one word at a time, backwards.
            for { let o := and(add(mload(data), 0x20), w) } 1 {} {
                mstore(add(add(bufData, bufDataLen), o), mload(add(data, o)))
                o := add(o, w) // `sub(o, 0x20)`.
                if iszero(o) { break }
            }
            // Zeroize the word after the buffer.
            mstore(add(add(bufData, 0x20), newBufDataLen), 0)
            // Store the `newBufDataLen`.
            mstore(bufData, newBufDataLen)
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
