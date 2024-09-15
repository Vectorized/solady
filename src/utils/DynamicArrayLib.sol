// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for memory arrays with automatic capacity resizing.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/DynamicArrayLib.sol)
library DynamicArrayLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Type to represent a dynamic array in memory.
    /// You can directly assign to `data`, and the `p` function will
    /// take care of the memory allocation.
    struct DynamicArray {
        uint256[] data;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OPERATIONS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Some of these functions returns the same array for function chaining.
    // `e.g. `array.p("1").p("2")`.

    /// @dev Shorthand for `array.data.length`.
    function length(DynamicArray memory array) internal pure returns (uint256) {
        return array.data.length;
    }

    /// @dev Clears the array without deallocating the memory.
    function clear(DynamicArray memory array) internal pure returns (DynamicArray memory result) {
        _deallocate(result);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(mload(array), 0)
        }
        result = array;
    }

    /// @dev Clears the array and attempts to free the memory if possible.
    function free(DynamicArray memory array) internal pure returns (DynamicArray memory result) {
        _deallocate(result);
        /// @solidity memory-safe-assembly
        assembly {
            let arrData := mload(array)
            let prime := 8188386068317523
            let cap := mload(sub(arrData, 0x20))
            // Extract `cap`, initializing it to zero if it is not a multiple of `prime`.
            cap := mul(div(cap, prime), iszero(mod(cap, prime)))
            // If the memory is contiguous, we can free it.
            if iszero(or(xor(mload(0x40), add(arrData, add(0x20, cap))), eq(arrData, 0x60))) {
                mstore(0x40, sub(arrData, 0x20))
            }
            mstore(array, 0x60)
        }
        result = array;
    }

    /// @dev Resizes the array to contain `n` elements. New elements will be zeroized.
    function resize(DynamicArray memory array, uint256 n)
        internal
        pure
        returns (DynamicArray memory result)
    {
        _deallocate(result);
        result = reserve(array, n);
        /// @solidity memory-safe-assembly
        assembly {
            let arrData := mload(result)
            let arrLen := mload(arrData)
            if gt(n, arrLen) {
                let o := add(add(0x20, arrData), shl(5, arrLen))
                codecopy(o, codesize(), shl(5, sub(n, arrLen)))
            }
            mstore(arrData, n)
        }
    }

    /// @dev Reserves at least `minimum` amount of contiguous memory.
    function reserve(DynamicArray memory array, uint256 minimum)
        internal
        pure
        returns (DynamicArray memory result)
    {
        _deallocate(result);
        result = array;
        /// @solidity memory-safe-assembly
        assembly {
            for { let arrData := mload(array) } gt(minimum, mload(arrData)) {} {
                let w := not(0x1f)
                // Some random prime number to multiply `cap`, so that
                // we know that the `cap` is for a dynamic array.
                // Selected to be larger than any memory pointer realistically.
                let prime := 8188386068317523
                let cap := mload(add(arrData, w)) // `mload(sub(arrData, w))`.
                // Extract `cap`, initializing it to zero if it is not a multiple of `prime`.
                cap := mul(div(cap, prime), iszero(mod(cap, prime)))
                let newCap := shl(5, minimum)
                // If we don't need to grow the memory.
                if iszero(gt(newCap, cap)) { break }
                // If the memory is contiguous, we can simply expand it.
                if iszero(or(xor(mload(0x40), add(arrData, add(0x20, cap))), eq(arrData, 0x60))) {
                    // Store `cap * prime` in the word before the length.
                    mstore(add(arrData, w), mul(prime, newCap))
                    mstore(0x40, add(arrData, add(0x20, newCap))) // Expand the memory allocation.
                    break
                }
                // Set the `newArrData` to point to the word after `cap`.
                let newArrData := add(mload(0x40), 0x20)
                mstore(0x40, add(newArrData, add(0x20, newCap))) // Reallocate the memory.
                mstore(array, newArrData) // Store the `newArrData`.
                // Copy `arrData` one word at a time, backwards.
                for { let o := add(0x20, shl(5, mload(arrData))) } 1 {} {
                    mstore(add(newArrData, o), mload(add(arrData, o)))
                    o := add(o, w) // `sub(o, 0x20)`.
                    if iszero(o) { break }
                }
                // Store `cap * prime` in the word before the length.
                mstore(add(newArrData, w), mul(prime, newCap))
                mstore(newArrData, mload(arrData)) // Store the length.
                break
            }
        }
    }

    /// @dev Appends `data` to `array`.
    function p(DynamicArray memory array, uint256 data)
        internal
        pure
        returns (DynamicArray memory result)
    {
        _deallocate(result);
        result = array;
        /// @solidity memory-safe-assembly
        assembly {
            let arrData := mload(array)
            let newArrLen := add(mload(arrData), 1)
            let newArrBytesLen := shl(5, newArrLen)
            // Some random prime number to multiply `cap`, so that
            // we know that the `cap` is for a dynamic array.
            // Selected to be larger than any memory pointer realistically.
            let prime := 8188386068317523
            let cap := mload(sub(arrData, 0x20))
            // Extract `cap`, initializing it to zero if it is not a multiple of `prime`.
            cap := mul(div(cap, prime), iszero(mod(cap, prime)))

            // Expand / Reallocate memory if required.
            // Note that we need to allocate an extra word for the length.
            for {} iszero(lt(newArrBytesLen, cap)) {} {
                // Approximately more than double the capacity to ensure more than enough space.
                let newCap := add(cap, or(cap, newArrBytesLen))
                // If the memory is contiguous, we can simply expand it.
                if iszero(or(xor(mload(0x40), add(arrData, add(0x20, cap))), eq(arrData, 0x60))) {
                    // Store `cap * prime` in the word before the length.
                    mstore(sub(arrData, 0x20), mul(prime, newCap))
                    mstore(0x40, add(arrData, add(0x20, newCap))) // Expand the memory allocation.
                    break
                }
                // Set the `newArrData` to point to the word after `cap`.
                let newArrData := add(mload(0x40), 0x20)
                mstore(0x40, add(newArrData, add(0x20, newCap))) // Reallocate the memory.
                mstore(array, newArrData) // Store the `newArrData`.
                let w := not(0x1f)
                // Copy `arrData` one word at a time, backwards.
                for { let o := newArrBytesLen } 1 {} {
                    mstore(add(newArrData, o), mload(add(arrData, o)))
                    o := add(o, w) // `sub(o, 0x20)`.
                    if iszero(o) { break }
                }
                // Store `cap * prime` in the word before the length.
                mstore(add(newArrData, w), mul(prime, newCap))
                arrData := newArrData // Assign `newArrData` to `arrData`.
                break
            }
            mstore(add(arrData, newArrBytesLen), data) // Append `data`.
            mstore(arrData, newArrLen) // Store the length.
        }
    }

    /// @dev Appends `data` to `array`.
    function p(DynamicArray memory array, address data)
        internal
        pure
        returns (DynamicArray memory result)
    {
        _deallocate(result);
        result = p(array, uint256(uint160(data)));
    }

    /// @dev Appends `data` to `array`.
    function p(DynamicArray memory array, bool data)
        internal
        pure
        returns (DynamicArray memory result)
    {
        _deallocate(result);
        result = p(array, _toUint(data));
    }

    /// @dev Appends `data` to `array`.
    function p(DynamicArray memory array, bytes32 data)
        internal
        pure
        returns (DynamicArray memory result)
    {
        _deallocate(result);
        result = p(array, uint256(data));
    }

    /// @dev Shorthand for returning an empty array.
    function p() internal pure returns (DynamicArray memory result) {}

    /// @dev Shorthand for `p(p(), data)`.
    function p(uint256 data) internal pure returns (DynamicArray memory result) {
        p(result, uint256(data));
    }

    /// @dev Shorthand for `p(p(), data)`.
    function p(address data) internal pure returns (DynamicArray memory result) {
        p(result, uint256(uint160(data)));
    }

    /// @dev Shorthand for `p(p(), data)`.
    function p(bool data) internal pure returns (DynamicArray memory result) {
        p(result, _toUint(data));
    }

    /// @dev Shorthand for `p(p(), data)`.
    function p(bytes32 data) internal pure returns (DynamicArray memory result) {
        p(result, uint256(data));
    }

    /// @dev Remove last element of `array.data`, without bounds checking.
    function pop(DynamicArray memory array) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let o := mload(array)
            result := mload(add(o, shl(5, mload(o))))
            // update the array.length
            mstore(o, sub(mload(o), 1))
        }
    }

    /// @dev Remove last element of `array.data`, without bounds checking.
    function popUint256(DynamicArray memory array) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let o := mload(array)
            result := mload(add(o, shl(5, mload(o))))
            // update the array.length
            mstore(o, sub(mload(o), 1))
        }
    }

    /// @dev Remove last element of `array.data`, without bounds checking.
    function popAddress(DynamicArray memory array) internal pure returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            let o := mload(array)
            result := mload(add(o, shl(5, mload(o))))
            // update the array.length
            mstore(o, sub(mload(o), 1))
        }
    }

    /// @dev Remove last element of `array.data`, without bounds checking.
    function popBool(DynamicArray memory array) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            let o := mload(array)
            result := mload(add(o, shl(5, mload(o))))
            // update the array.length
            mstore(o, sub(mload(o), 1))
        }
    }

    /// @dev Remove last element of `array.data`, without bounds checking.
    function popBytes32(DynamicArray memory array) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let o := mload(array)
            result := mload(add(o, shl(5, mload(o))))
            // update the array.length
            mstore(o, sub(mload(o), 1))
        }
    }

    /// @dev Returns the element at `array.data[i]`, without bounds checking.
    function get(DynamicArray memory array, uint256 i) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(add(add(mload(array), 0x20), shl(5, i)))
        }
    }

    /// @dev Returns the element at `array.data[i]`, without bounds checking.
    function getUint256(DynamicArray memory array, uint256 i)
        internal
        pure
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(add(add(mload(array), 0x20), shl(5, i)))
        }
    }

    /// @dev Returns the element at `array.data[i]`, without bounds checking.
    function getAddress(DynamicArray memory array, uint256 i)
        internal
        pure
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(add(add(mload(array), 0x20), shl(5, i)))
        }
    }

    /// @dev Returns the element at `array.data[i]`, without bounds checking.
    function getBool(DynamicArray memory array, uint256 i) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(add(add(mload(array), 0x20), shl(5, i)))
        }
    }

    /// @dev Returns the element at `array.data[i]`, without bounds checking.
    function getBytes32(DynamicArray memory array, uint256 i)
        internal
        pure
        returns (bytes32 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(add(add(mload(array), 0x20), shl(5, i)))
        }
    }

    /// @dev Sets `array.data[i]` to `data`, without bounds checking.
    function set(DynamicArray memory array, uint256 i, uint256 data)
        internal
        pure
        returns (DynamicArray memory result)
    {
        _deallocate(result);
        result = array;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(add(add(mload(array), 0x20), shl(5, i)), data)
        }
    }

    /// @dev Sets `array.data[i]` to `data`, without bounds checking.
    function set(DynamicArray memory array, uint256 i, address data)
        internal
        pure
        returns (DynamicArray memory result)
    {
        _deallocate(result);
        result = array;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(add(add(mload(array), 0x20), shl(5, i)), shr(96, shl(96, data)))
        }
    }

    /// @dev Sets `array.data[i]` to `data`, without bounds checking.
    function set(DynamicArray memory array, uint256 i, bool data)
        internal
        pure
        returns (DynamicArray memory result)
    {
        _deallocate(result);
        result = array;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(add(add(mload(array), 0x20), shl(5, i)), iszero(iszero(data)))
        }
    }

    /// @dev Sets `array.data[i]` to `data`, without bounds checking.
    function set(DynamicArray memory array, uint256 i, bytes32 data)
        internal
        pure
        returns (DynamicArray memory result)
    {
        _deallocate(result);
        result = array;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(add(add(mload(array), 0x20), shl(5, i)), data)
        }
    }

    /// @dev Returns the underlying array as a `uint256[]`.
    function asUint256Array(DynamicArray memory array)
        internal
        pure
        returns (uint256[] memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(array)
        }
    }

    /// @dev Returns the underlying array as a `address[]`.
    function asAddressArray(DynamicArray memory array)
        internal
        pure
        returns (address[] memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(array)
        }
    }

    /// @dev Returns the underlying array as a `bool[]`.
    function asBoolArray(DynamicArray memory array) internal pure returns (bool[] memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(array)
        }
    }

    /// @dev Returns the underlying array as a `bytes32[]`.
    function asBytes32Array(DynamicArray memory array)
        internal
        pure
        returns (bytes32[] memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(array)
        }
    }

    /// @dev Returns a copy of `array` sliced from `start` to `end` (exclusive).
    function slice(DynamicArray memory array, uint256 start, uint256 end)
        internal
        pure
        returns (DynamicArray memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let arrData := mload(array)
            let arrDataLen := mload(arrData)
            if iszero(gt(arrDataLen, end)) { end := arrDataLen }
            if iszero(gt(arrDataLen, start)) { start := arrDataLen }
            if lt(start, end) {
                let resultData := mload(0x40)
                let resultDataLen := sub(end, start)
                mstore(resultData, resultDataLen)
                arrData := add(arrData, shl(5, start))
                let w := not(0x1f)
                // Copy the `arrData` one word at a time, backwards.
                let o := add(shl(5, resultDataLen), 0x20)
                mstore(0x40, add(resultData, o)) // Allocate memory.
                for {} 1 {} {
                    mstore(add(resultData, o), mload(add(arrData, o)))
                    o := add(o, w) // `sub(o, 0x20)`.
                    if iszero(o) { break }
                }
                mstore(result, resultData)
            }
        }
    }

    /// @dev Returns a copy of `array` sliced from `start` to the end of the array.
    function slice(DynamicArray memory array, uint256 start)
        internal
        pure
        returns (DynamicArray memory result)
    {
        _deallocate(result);
        result = slice(array, start, type(uint256).max);
    }

    /// @dev Equivalent to `keccak256(abi.encodePacked(array.data))`.
    function hash(DynamicArray memory array) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := keccak256(add(mload(array), 0x20), shl(5, mload(mload(array))))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Helper for deallocating a automatically allocated array pointer.
    function _deallocate(DynamicArray memory result) private pure {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x40, result) // Deallocate, as we have already allocated.
        }
    }

    /// @dev Casts the bool into a uint256.
    function _toUint(bool b) private pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := iszero(iszero(b))
        }
    }
}
