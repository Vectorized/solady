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
    /*                  UINT256 ARRAY OPERATIONS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Low level minimalist uint256 array operations.
    // If you don't need syntax sugar, it's recommended to use these.
    // Some of these functions returns the same array for function chaining.
    // `e.g. `array.set(0, 1).set(1, 2)`.

    /// @dev Returns a uint256 array with `n` elements. The elements are not zeroized.
    function malloc(uint256 n) internal pure returns (uint256[] memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := or(sub(0, shr(32, n)), mload(0x40))
            mstore(result, n)
            mstore(0x40, add(add(result, 0x20), shl(5, n)))
        }
    }

    /// @dev Zeroizes all the elements of `array`.
    function zeroize(uint256[] memory array) internal pure returns (uint256[] memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := array
            codecopy(add(result, 0x20), codesize(), shl(5, mload(result)))
        }
    }

    /// @dev Returns the element at `array[i]`, without bounds checking.
    function get(uint256[] memory array, uint256 i) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(add(add(array, 0x20), shl(5, i)))
        }
    }

    /// @dev Sets `array[i]` to `data`, without bounds checking.
    function set(uint256[] memory array, uint256 i, uint256 data)
        internal
        pure
        returns (uint256[] memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := array
            mstore(add(add(result, 0x20), shl(5, i)), data)
        }
    }

    /// @dev Reduces the size of `array` to `n`.
    /// If `n` is greater than the size of `array`, this will be a no-op.
    function truncate(uint256[] memory array, uint256 n)
        internal
        pure
        returns (uint256[] memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := array
            mstore(mul(lt(n, mload(result)), result), n)
        }
    }

    /// @dev Clears the array and attempts to free the memory if possible.
    function free(uint256[] memory array) internal pure returns (uint256[] memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := array
            let n := mload(result)
            mstore(shl(6, lt(iszero(n), eq(add(shl(5, add(1, n)), result), mload(0x40)))), result)
            mstore(result, 0)
        }
    }

    /// @dev Equivalent to `keccak256(abi.encodePacked(array))`.
    function hash(uint256[] memory array) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := keccak256(add(array, 0x20), shl(5, mload(array)))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  DYNAMIC ARRAY OPERATIONS                  */
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
        result = array;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(mload(result), 0)
        }
    }

    /// @dev Clears the array and attempts to free the memory if possible.
    function free(DynamicArray memory array) internal pure returns (DynamicArray memory result) {
        _deallocate(result);
        result = array;
        /// @solidity memory-safe-assembly
        assembly {
            let arrData := mload(result)
            if iszero(eq(arrData, 0x60)) {
                let prime := 8188386068317523
                let cap := mload(sub(arrData, 0x20))
                // Extract `cap`, initializing it to zero if it is not a multiple of `prime`.
                cap := mul(div(cap, prime), iszero(mod(cap, prime)))
                // If `cap` is non-zero and the memory is contiguous, we can free it.
                if lt(iszero(cap), eq(mload(0x40), add(arrData, add(0x20, cap)))) {
                    mstore(0x40, sub(arrData, 0x20))
                }
                mstore(result, 0x60)
            }
        }
    }

    /// @dev Resizes the array to contain `n` elements. New elements will be zeroized.
    function resize(DynamicArray memory array, uint256 n)
        internal
        pure
        returns (DynamicArray memory result)
    {
        _deallocate(result);
        result = array;
        reserve(result, n);
        /// @solidity memory-safe-assembly
        assembly {
            let arrData := mload(result)
            let arrLen := mload(arrData)
            if iszero(lt(n, arrLen)) {
                codecopy(add(arrData, shl(5, add(1, arrLen))), codesize(), shl(5, sub(n, arrLen)))
            }
            mstore(arrData, n)
        }
    }

    /// @dev Increases the size of `array` to `n`.
    /// If `n` is less than the size of `array`, this will be a no-op.
    /// This method does not zeroize any newly created elements.
    function expand(DynamicArray memory array, uint256 n)
        internal
        pure
        returns (DynamicArray memory result)
    {
        _deallocate(result);
        result = array;
        if (n >= array.data.length) {
            reserve(result, n);
            /// @solidity memory-safe-assembly
            assembly {
                mstore(mload(result), n)
            }
        }
    }

    /// @dev Reduces the size of `array` to `n`.
    /// If `n` is greater than the size of `array`, this will be a no-op.
    function truncate(DynamicArray memory array, uint256 n)
        internal
        pure
        returns (DynamicArray memory result)
    {
        _deallocate(result);
        result = array;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(mul(lt(n, mload(mload(result))), mload(result)), n)
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
            if iszero(lt(minimum, 0xffffffff)) { invalid() } // For extra safety.
            for { let arrData := mload(array) } 1 {} {
                // Some random prime number to multiply `cap`, so that
                // we know that the `cap` is for a dynamic array.
                // Selected to be larger than any memory pointer realistically.
                let prime := 8188386068317523
                // Special case for `arrData` pointing to zero pointer.
                if eq(arrData, 0x60) {
                    let newCap := shl(5, add(1, minimum))
                    let capSlot := mload(0x40)
                    mstore(capSlot, mul(prime, newCap)) // Store the capacity.
                    let newArrData := add(0x20, capSlot)
                    mstore(newArrData, 0) // Store the length.
                    mstore(0x40, add(newArrData, add(0x20, newCap))) // Allocate memory.
                    mstore(array, newArrData)
                    break
                }
                let w := not(0x1f)
                let cap := mload(add(arrData, w)) // `mload(sub(arrData, w))`.
                // Extract `cap`, initializing it to zero if it is not a multiple of `prime`.
                cap := mul(div(cap, prime), iszero(mod(cap, prime)))
                let newCap := shl(5, minimum)
                // If we don't need to grow the memory.
                if iszero(and(gt(minimum, mload(arrData)), gt(newCap, cap))) { break }
                // If the memory is contiguous, we can simply expand it.
                if eq(mload(0x40), add(arrData, add(0x20, cap))) {
                    mstore(add(arrData, w), mul(prime, newCap)) // Store the capacity.
                    mstore(0x40, add(arrData, add(0x20, newCap))) // Expand the memory allocation.
                    break
                }
                let capSlot := mload(0x40)
                let newArrData := add(capSlot, 0x20)
                mstore(0x40, add(newArrData, add(0x20, newCap))) // Reallocate the memory.
                mstore(array, newArrData) // Store the `newArrData`.
                // Copy `arrData` one word at a time, backwards.
                for { let o := add(0x20, shl(5, mload(arrData))) } 1 {} {
                    mstore(add(newArrData, o), mload(add(arrData, o)))
                    o := add(o, w) // `sub(o, 0x20)`.
                    if iszero(o) { break }
                }
                mstore(capSlot, mul(prime, newCap)) // Store the capacity.
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
                    mstore(sub(arrData, 0x20), mul(prime, newCap)) // Store the capacity.
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
                mstore(add(newArrData, w), mul(prime, newCap)) // Store the memory.
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

    /// @dev Removes and returns the last element of `array`.
    /// Returns 0 and does not pop anything if the array is empty.
    function pop(DynamicArray memory array) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let o := mload(array)
            let n := mload(o)
            result := mload(add(o, shl(5, n)))
            mstore(o, sub(n, iszero(iszero(n))))
        }
    }

    /// @dev Removes and returns the last element of `array`.
    /// Returns 0 and does not pop anything if the array is empty.
    function popUint256(DynamicArray memory array) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let o := mload(array)
            let n := mload(o)
            result := mload(add(o, shl(5, n)))
            mstore(o, sub(n, iszero(iszero(n))))
        }
    }

    /// @dev Removes and returns the last element of `array`.
    /// Returns 0 and does not pop anything if the array is empty.
    function popAddress(DynamicArray memory array) internal pure returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            let o := mload(array)
            let n := mload(o)
            result := mload(add(o, shl(5, n)))
            mstore(o, sub(n, iszero(iszero(n))))
        }
    }

    /// @dev Removes and returns the last element of `array`.
    /// Returns 0 and does not pop anything if the array is empty.
    function popBool(DynamicArray memory array) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            let o := mload(array)
            let n := mload(o)
            result := mload(add(o, shl(5, n)))
            mstore(o, sub(n, iszero(iszero(n))))
        }
    }

    /// @dev Removes and returns the last element of `array`.
    /// Returns 0 and does not pop anything if the array is empty.
    function popBytes32(DynamicArray memory array) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let o := mload(array)
            let n := mload(o)
            result := mload(add(o, shl(5, n)))
            mstore(o, sub(n, iszero(iszero(n))))
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
            mstore(add(add(mload(result), 0x20), shl(5, i)), data)
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
            mstore(add(add(mload(result), 0x20), shl(5, i)), shr(96, shl(96, data)))
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
            mstore(add(add(mload(result), 0x20), shl(5, i)), iszero(iszero(data)))
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
            mstore(add(add(mload(result), 0x20), shl(5, i)), data)
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
