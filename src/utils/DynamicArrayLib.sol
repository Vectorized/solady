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
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The constant returned when the element is not found in the array.
    uint256 internal constant NOT_FOUND = type(uint256).max;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  UINT256 ARRAY OPERATIONS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Low level minimalist uint256 array operations.
    // If you don't need syntax sugar, it's recommended to use these.
    // Some of these functions return the same array for function chaining.
    // e.g. `array.set(0, 1).set(1, 2)`.

    /// @dev Returns a uint256 array with `n` elements. The elements are not zeroized.
    function malloc(uint256 n) internal pure returns (uint256[] memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := or(sub(0, shr(32, n)), mload(0x40))
            mstore(result, n)
            mstore(0x40, add(add(result, 0x20), shl(5, n)))
        }
    }

    /// @dev Zeroizes all the elements of `a`.
    function zeroize(uint256[] memory a) internal pure returns (uint256[] memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := a
            calldatacopy(add(result, 0x20), calldatasize(), shl(5, mload(result)))
        }
    }

    /// @dev Returns the element at `a[i]`, without bounds checking.
    function get(uint256[] memory a, uint256 i) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(add(add(a, 0x20), shl(5, i)))
        }
    }

    /// @dev Returns the element at `a[i]`, without bounds checking.
    function getUint256(uint256[] memory a, uint256 i) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(add(add(a, 0x20), shl(5, i)))
        }
    }

    /// @dev Returns the element at `a[i]`, without bounds checking.
    function getAddress(uint256[] memory a, uint256 i) internal pure returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(add(add(a, 0x20), shl(5, i)))
        }
    }

    /// @dev Returns the element at `a[i]`, without bounds checking.
    function getBool(uint256[] memory a, uint256 i) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(add(add(a, 0x20), shl(5, i)))
        }
    }

    /// @dev Returns the element at `a[i]`, without bounds checking.
    function getBytes32(uint256[] memory a, uint256 i) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(add(add(a, 0x20), shl(5, i)))
        }
    }

    /// @dev Sets `a.data[i]` to `data`, without bounds checking.
    function set(uint256[] memory a, uint256 i, uint256 data)
        internal
        pure
        returns (uint256[] memory result)
    {
        result = a;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(add(add(result, 0x20), shl(5, i)), data)
        }
    }

    /// @dev Sets `a.data[i]` to `data`, without bounds checking.
    function set(uint256[] memory a, uint256 i, address data)
        internal
        pure
        returns (uint256[] memory result)
    {
        result = a;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(add(add(result, 0x20), shl(5, i)), shr(96, shl(96, data)))
        }
    }

    /// @dev Sets `a.data[i]` to `data`, without bounds checking.
    function set(uint256[] memory a, uint256 i, bool data)
        internal
        pure
        returns (uint256[] memory result)
    {
        result = a;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(add(add(result, 0x20), shl(5, i)), iszero(iszero(data)))
        }
    }

    /// @dev Sets `a.data[i]` to `data`, without bounds checking.
    function set(uint256[] memory a, uint256 i, bytes32 data)
        internal
        pure
        returns (uint256[] memory result)
    {
        result = a;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(add(add(result, 0x20), shl(5, i)), data)
        }
    }

    /// @dev Casts `a` to `address[]`.
    function asAddressArray(uint256[] memory a) internal pure returns (address[] memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := a
        }
    }

    /// @dev Casts `a` to `bool[]`.
    function asBoolArray(uint256[] memory a) internal pure returns (bool[] memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := a
        }
    }

    /// @dev Casts `a` to `bytes32[]`.
    function asBytes32Array(uint256[] memory a) internal pure returns (bytes32[] memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := a
        }
    }

    /// @dev Casts `a` to `uint256[]`.
    function toUint256Array(address[] memory a) internal pure returns (uint256[] memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := a
        }
    }

    /// @dev Casts `a` to `uint256[]`.
    function toUint256Array(bool[] memory a) internal pure returns (uint256[] memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := a
        }
    }

    /// @dev Casts `a` to `uint256[]`.
    function toUint256Array(bytes32[] memory a) internal pure returns (uint256[] memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := a
        }
    }

    /// @dev Reduces the size of `a` to `n`.
    /// If `n` is greater than the size of `a`, this will be a no-op.
    function truncate(uint256[] memory a, uint256 n)
        internal
        pure
        returns (uint256[] memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := a
            mstore(mul(lt(n, mload(result)), result), n)
        }
    }

    /// @dev Clears the array and attempts to free the memory if possible.
    function free(uint256[] memory a) internal pure returns (uint256[] memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := a
            let n := mload(result)
            mstore(shl(6, lt(iszero(n), eq(add(shl(5, add(1, n)), result), mload(0x40)))), result)
            mstore(result, 0)
        }
    }

    /// @dev Equivalent to `keccak256(abi.encodePacked(a))`.
    function hash(uint256[] memory a) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := keccak256(add(a, 0x20), shl(5, mload(a)))
        }
    }

    /// @dev Returns a copy of `a` sliced from `start` to `end` (exclusive).
    function slice(uint256[] memory a, uint256 start, uint256 end)
        internal
        pure
        returns (uint256[] memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let arrayLen := mload(a)
            if iszero(gt(arrayLen, end)) { end := arrayLen }
            if iszero(gt(arrayLen, start)) { start := arrayLen }
            if lt(start, end) {
                result := mload(0x40)
                let resultLen := sub(end, start)
                mstore(result, resultLen)
                a := add(a, shl(5, start))
                // Copy the `a` one word at a time, backwards.
                let o := shl(5, resultLen)
                mstore(0x40, add(add(result, o), 0x20)) // Allocate memory.
                for {} 1 {} {
                    mstore(add(result, o), mload(add(a, o)))
                    o := sub(o, 0x20)
                    if iszero(o) { break }
                }
            }
        }
    }

    /// @dev Returns a copy of `a` sliced from `start` to the end of the array.
    function slice(uint256[] memory a, uint256 start)
        internal
        pure
        returns (uint256[] memory result)
    {
        result = slice(a, start, type(uint256).max);
    }

    /// @dev Returns a copy of the array.
    function copy(uint256[] memory a) internal pure returns (uint256[] memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            let end := add(add(result, 0x20), shl(5, mload(a)))
            let o := result
            for { let d := sub(a, result) } 1 {} {
                mstore(o, mload(add(o, d)))
                o := add(0x20, o)
                if eq(o, end) { break }
            }
            mstore(0x40, o)
        }
    }

    /// @dev Returns if `needle` is in `a`.
    function contains(uint256[] memory a, uint256 needle) internal pure returns (bool) {
        return ~indexOf(a, needle, 0) != 0;
    }

    /// @dev Returns the first index of `needle`, scanning forward from `from`.
    /// If `needle` is not in `a`, returns `NOT_FOUND`.
    function indexOf(uint256[] memory a, uint256 needle, uint256 from)
        internal
        pure
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := not(0)
            if lt(from, mload(a)) {
                let o := add(a, shl(5, from))
                let end := add(shl(5, add(1, mload(a))), a)
                let c := mload(end) // Cache the word after the array.
                for { mstore(end, needle) } 1 {} {
                    o := add(o, 0x20)
                    if eq(mload(o), needle) { break }
                }
                mstore(end, c) // Restore the word after the array.
                if iszero(eq(o, end)) { result := shr(5, sub(o, add(0x20, a))) }
            }
        }
    }

    /// @dev Returns the first index of `needle`.
    /// If `needle` is not in `a`, returns `NOT_FOUND`.
    function indexOf(uint256[] memory a, uint256 needle) internal pure returns (uint256 result) {
        result = indexOf(a, needle, 0);
    }

    /// @dev Returns the last index of `needle`, scanning backwards from `from`.
    /// If `needle` is not in `a`, returns `NOT_FOUND`.
    function lastIndexOf(uint256[] memory a, uint256 needle, uint256 from)
        internal
        pure
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := not(0)
            let n := mload(a)
            if n {
                if iszero(lt(from, n)) { from := sub(n, 1) }
                let o := add(shl(5, add(2, from)), a)
                for { mstore(a, needle) } 1 {} {
                    o := sub(o, 0x20)
                    if eq(mload(o), needle) { break }
                }
                mstore(a, n) // Restore the length.
                if iszero(eq(o, a)) { result := shr(5, sub(o, add(0x20, a))) }
            }
        }
    }

    /// @dev Returns the first index of `needle`.
    /// If `needle` is not in `a`, returns `NOT_FOUND`.
    function lastIndexOf(uint256[] memory a, uint256 needle)
        internal
        pure
        returns (uint256 result)
    {
        result = lastIndexOf(a, needle, NOT_FOUND);
    }

    /// @dev Directly returns `a` without copying.
    function directReturn(uint256[] memory a) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            let retStart := sub(a, 0x20)
            mstore(retStart, 0x20)
            return(retStart, add(0x40, shl(5, mload(a))))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  DYNAMIC ARRAY OPERATIONS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Some of these functions return the same array for function chaining.
    // e.g. `a.p("1").p("2")`.

    /// @dev Shorthand for `a.data.length`.
    function length(DynamicArray memory a) internal pure returns (uint256) {
        return a.data.length;
    }

    /// @dev Wraps `a` in a dynamic array struct.
    function wrap(uint256[] memory a) internal pure returns (DynamicArray memory result) {
        result.data = a;
    }

    /// @dev Wraps `a` in a dynamic array struct.
    function wrap(address[] memory a) internal pure returns (DynamicArray memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(result, a)
        }
    }

    /// @dev Wraps `a` in a dynamic array struct.
    function wrap(bool[] memory a) internal pure returns (DynamicArray memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(result, a)
        }
    }

    /// @dev Wraps `a` in a dynamic array struct.
    function wrap(bytes32[] memory a) internal pure returns (DynamicArray memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(result, a)
        }
    }

    /// @dev Clears the array without deallocating the memory.
    function clear(DynamicArray memory a) internal pure returns (DynamicArray memory result) {
        _deallocate(result);
        result = a;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(mload(result), 0)
        }
    }

    /// @dev Clears the array and attempts to free the memory if possible.
    function free(DynamicArray memory a) internal pure returns (DynamicArray memory result) {
        _deallocate(result);
        result = a;
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
    function resize(DynamicArray memory a, uint256 n)
        internal
        pure
        returns (DynamicArray memory result)
    {
        _deallocate(result);
        result = a;
        reserve(result, n);
        /// @solidity memory-safe-assembly
        assembly {
            let arrData := mload(result)
            let arrLen := mload(arrData)
            if iszero(lt(n, arrLen)) {
                calldatacopy(
                    add(arrData, shl(5, add(1, arrLen))), calldatasize(), shl(5, sub(n, arrLen))
                )
            }
            mstore(arrData, n)
        }
    }

    /// @dev Increases the size of `a` to `n`.
    /// If `n` is less than the size of `a`, this will be a no-op.
    /// This method does not zeroize any newly created elements.
    function expand(DynamicArray memory a, uint256 n)
        internal
        pure
        returns (DynamicArray memory result)
    {
        _deallocate(result);
        result = a;
        if (n >= a.data.length) {
            reserve(result, n);
            /// @solidity memory-safe-assembly
            assembly {
                mstore(mload(result), n)
            }
        }
    }

    /// @dev Reduces the size of `a` to `n`.
    /// If `n` is greater than the size of `a`, this will be a no-op.
    function truncate(DynamicArray memory a, uint256 n)
        internal
        pure
        returns (DynamicArray memory result)
    {
        _deallocate(result);
        result = a;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(mul(lt(n, mload(mload(result))), mload(result)), n)
        }
    }

    /// @dev Reserves at least `minimum` amount of contiguous memory.
    function reserve(DynamicArray memory a, uint256 minimum)
        internal
        pure
        returns (DynamicArray memory result)
    {
        _deallocate(result);
        result = a;
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(lt(minimum, 0xffffffff)) { invalid() } // For extra safety.
            for { let arrData := mload(a) } 1 {} {
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
                    mstore(a, newArrData)
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
                mstore(a, newArrData) // Store the `newArrData`.
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

    /// @dev Appends `data` to `a`.
    function p(DynamicArray memory a, uint256 data)
        internal
        pure
        returns (DynamicArray memory result)
    {
        _deallocate(result);
        result = a;
        /// @solidity memory-safe-assembly
        assembly {
            let arrData := mload(a)
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
                if iszero(or(xor(mload(0x40), add(arrData, add(0x20, cap))), iszero(cap))) {
                    mstore(sub(arrData, 0x20), mul(prime, newCap)) // Store the capacity.
                    mstore(0x40, add(arrData, add(0x20, newCap))) // Expand the memory allocation.
                    break
                }
                // Set the `newArrData` to point to the word after `cap`.
                let newArrData := add(mload(0x40), 0x20)
                mstore(0x40, add(newArrData, add(0x20, newCap))) // Reallocate the memory.
                mstore(a, newArrData) // Store the `newArrData`.
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

    /// @dev Appends `data` to `a`.
    function p(DynamicArray memory a, address data)
        internal
        pure
        returns (DynamicArray memory result)
    {
        _deallocate(result);
        result = p(a, uint256(uint160(data)));
    }

    /// @dev Appends `data` to `a`.
    function p(DynamicArray memory a, bool data)
        internal
        pure
        returns (DynamicArray memory result)
    {
        _deallocate(result);
        result = p(a, _toUint(data));
    }

    /// @dev Appends `data` to `a`.
    function p(DynamicArray memory a, bytes32 data)
        internal
        pure
        returns (DynamicArray memory result)
    {
        _deallocate(result);
        result = p(a, uint256(data));
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

    /// @dev Removes and returns the last element of `a`.
    /// Returns 0 and does not pop anything if the array is empty.
    function pop(DynamicArray memory a) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let o := mload(a)
            let n := mload(o)
            result := mload(add(o, shl(5, n)))
            mstore(o, sub(n, iszero(iszero(n))))
        }
    }

    /// @dev Removes and returns the last element of `a`.
    /// Returns 0 and does not pop anything if the array is empty.
    function popUint256(DynamicArray memory a) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let o := mload(a)
            let n := mload(o)
            result := mload(add(o, shl(5, n)))
            mstore(o, sub(n, iszero(iszero(n))))
        }
    }

    /// @dev Removes and returns the last element of `a`.
    /// Returns 0 and does not pop anything if the array is empty.
    function popAddress(DynamicArray memory a) internal pure returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            let o := mload(a)
            let n := mload(o)
            result := mload(add(o, shl(5, n)))
            mstore(o, sub(n, iszero(iszero(n))))
        }
    }

    /// @dev Removes and returns the last element of `a`.
    /// Returns 0 and does not pop anything if the array is empty.
    function popBool(DynamicArray memory a) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            let o := mload(a)
            let n := mload(o)
            result := mload(add(o, shl(5, n)))
            mstore(o, sub(n, iszero(iszero(n))))
        }
    }

    /// @dev Removes and returns the last element of `a`.
    /// Returns 0 and does not pop anything if the array is empty.
    function popBytes32(DynamicArray memory a) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let o := mload(a)
            let n := mload(o)
            result := mload(add(o, shl(5, n)))
            mstore(o, sub(n, iszero(iszero(n))))
        }
    }

    /// @dev Returns the element at `a.data[i]`, without bounds checking.
    function get(DynamicArray memory a, uint256 i) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(add(add(mload(a), 0x20), shl(5, i)))
        }
    }

    /// @dev Returns the element at `a.data[i]`, without bounds checking.
    function getUint256(DynamicArray memory a, uint256 i) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(add(add(mload(a), 0x20), shl(5, i)))
        }
    }

    /// @dev Returns the element at `a.data[i]`, without bounds checking.
    function getAddress(DynamicArray memory a, uint256 i) internal pure returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(add(add(mload(a), 0x20), shl(5, i)))
        }
    }

    /// @dev Returns the element at `a.data[i]`, without bounds checking.
    function getBool(DynamicArray memory a, uint256 i) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(add(add(mload(a), 0x20), shl(5, i)))
        }
    }

    /// @dev Returns the element at `a.data[i]`, without bounds checking.
    function getBytes32(DynamicArray memory a, uint256 i) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(add(add(mload(a), 0x20), shl(5, i)))
        }
    }

    /// @dev Sets `a.data[i]` to `data`, without bounds checking.
    function set(DynamicArray memory a, uint256 i, uint256 data)
        internal
        pure
        returns (DynamicArray memory result)
    {
        _deallocate(result);
        result = a;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(add(add(mload(result), 0x20), shl(5, i)), data)
        }
    }

    /// @dev Sets `a.data[i]` to `data`, without bounds checking.
    function set(DynamicArray memory a, uint256 i, address data)
        internal
        pure
        returns (DynamicArray memory result)
    {
        _deallocate(result);
        result = a;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(add(add(mload(result), 0x20), shl(5, i)), shr(96, shl(96, data)))
        }
    }

    /// @dev Sets `a.data[i]` to `data`, without bounds checking.
    function set(DynamicArray memory a, uint256 i, bool data)
        internal
        pure
        returns (DynamicArray memory result)
    {
        _deallocate(result);
        result = a;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(add(add(mload(result), 0x20), shl(5, i)), iszero(iszero(data)))
        }
    }

    /// @dev Sets `a.data[i]` to `data`, without bounds checking.
    function set(DynamicArray memory a, uint256 i, bytes32 data)
        internal
        pure
        returns (DynamicArray memory result)
    {
        _deallocate(result);
        result = a;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(add(add(mload(result), 0x20), shl(5, i)), data)
        }
    }

    /// @dev Returns the underlying array as a `uint256[]`.
    function asUint256Array(DynamicArray memory a)
        internal
        pure
        returns (uint256[] memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(a)
        }
    }

    /// @dev Returns the underlying array as a `address[]`.
    function asAddressArray(DynamicArray memory a)
        internal
        pure
        returns (address[] memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(a)
        }
    }

    /// @dev Returns the underlying array as a `bool[]`.
    function asBoolArray(DynamicArray memory a) internal pure returns (bool[] memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(a)
        }
    }

    /// @dev Returns the underlying array as a `bytes32[]`.
    function asBytes32Array(DynamicArray memory a)
        internal
        pure
        returns (bytes32[] memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(a)
        }
    }

    /// @dev Returns a copy of `a` sliced from `start` to `end` (exclusive).
    function slice(DynamicArray memory a, uint256 start, uint256 end)
        internal
        pure
        returns (DynamicArray memory result)
    {
        result.data = slice(a.data, start, end);
    }

    /// @dev Returns a copy of `a` sliced from `start` to the end of the array.
    function slice(DynamicArray memory a, uint256 start)
        internal
        pure
        returns (DynamicArray memory result)
    {
        result.data = slice(a.data, start, type(uint256).max);
    }

    /// @dev Returns a copy of `a`.
    function copy(DynamicArray memory a) internal pure returns (DynamicArray memory result) {
        result.data = copy(a.data);
    }

    /// @dev Returns if `needle` is in `a`.
    function contains(DynamicArray memory a, uint256 needle) internal pure returns (bool) {
        return ~indexOf(a.data, needle, 0) != 0;
    }

    /// @dev Returns if `needle` is in `a`.
    function contains(DynamicArray memory a, address needle) internal pure returns (bool) {
        return ~indexOf(a.data, uint160(needle), 0) != 0;
    }

    /// @dev Returns if `needle` is in `a`.
    function contains(DynamicArray memory a, bytes32 needle) internal pure returns (bool) {
        return ~indexOf(a.data, uint256(needle), 0) != 0;
    }

    /// @dev Returns the first index of `needle`, scanning forward from `from`.
    /// If `needle` is not in `a`, returns `NOT_FOUND`.
    function indexOf(DynamicArray memory a, uint256 needle, uint256 from)
        internal
        pure
        returns (uint256)
    {
        return indexOf(a.data, needle, from);
    }

    /// @dev Returns the first index of `needle`, scanning forward from `from`.
    /// If `needle` is not in `a`, returns `NOT_FOUND`.
    function indexOf(DynamicArray memory a, address needle, uint256 from)
        internal
        pure
        returns (uint256)
    {
        return indexOf(a.data, uint160(needle), from);
    }

    /// @dev Returns the first index of `needle`, scanning forward from `from`.
    /// If `needle` is not in `a`, returns `NOT_FOUND`.
    function indexOf(DynamicArray memory a, bytes32 needle, uint256 from)
        internal
        pure
        returns (uint256)
    {
        return indexOf(a.data, uint256(needle), from);
    }

    /// @dev Returns the first index of `needle`.
    /// If `needle` is not in `a`, returns `NOT_FOUND`.
    function indexOf(DynamicArray memory a, uint256 needle) internal pure returns (uint256) {
        return indexOf(a.data, needle, 0);
    }

    /// @dev Returns the first index of `needle`.
    /// If `needle` is not in `a`, returns `NOT_FOUND`.
    function indexOf(DynamicArray memory a, address needle) internal pure returns (uint256) {
        return indexOf(a.data, uint160(needle), 0);
    }

    /// @dev Returns the first index of `needle`.
    /// If `needle` is not in `a`, returns `NOT_FOUND`.
    function indexOf(DynamicArray memory a, bytes32 needle) internal pure returns (uint256) {
        return indexOf(a.data, uint256(needle), 0);
    }

    /// @dev Returns the last index of `needle`, scanning backwards from `from`.
    /// If `needle` is not in `a`, returns `NOT_FOUND`.
    function lastIndexOf(DynamicArray memory a, uint256 needle, uint256 from)
        internal
        pure
        returns (uint256)
    {
        return lastIndexOf(a.data, needle, from);
    }

    /// @dev Returns the last index of `needle`, scanning backwards from `from`.
    /// If `needle` is not in `a`, returns `NOT_FOUND`.
    function lastIndexOf(DynamicArray memory a, address needle, uint256 from)
        internal
        pure
        returns (uint256)
    {
        return lastIndexOf(a.data, uint160(needle), from);
    }

    /// @dev Returns the last index of `needle`, scanning backwards from `from`.
    /// If `needle` is not in `a`, returns `NOT_FOUND`.
    function lastIndexOf(DynamicArray memory a, bytes32 needle, uint256 from)
        internal
        pure
        returns (uint256)
    {
        return lastIndexOf(a.data, uint256(needle), from);
    }

    /// @dev Returns the last index of `needle`.
    /// If `needle` is not in `a`, returns `NOT_FOUND`.
    function lastIndexOf(DynamicArray memory a, uint256 needle) internal pure returns (uint256) {
        return lastIndexOf(a.data, needle, NOT_FOUND);
    }

    /// @dev Returns the last index of `needle`.
    /// If `needle` is not in `a`, returns `NOT_FOUND`.
    function lastIndexOf(DynamicArray memory a, address needle) internal pure returns (uint256) {
        return lastIndexOf(a.data, uint160(needle), NOT_FOUND);
    }

    /// @dev Returns the last index of `needle`.
    /// If `needle` is not in `a`, returns `NOT_FOUND`.
    function lastIndexOf(DynamicArray memory a, bytes32 needle) internal pure returns (uint256) {
        return lastIndexOf(a.data, uint256(needle), NOT_FOUND);
    }

    /// @dev Equivalent to `keccak256(abi.encodePacked(a.data))`.
    function hash(DynamicArray memory a) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := keccak256(add(mload(a), 0x20), shl(5, mload(mload(a))))
        }
    }

    /// @dev Directly returns `a` without copying.
    function directReturn(DynamicArray memory a) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            let arrData := mload(a)
            let retStart := sub(arrData, 0x20)
            mstore(retStart, 0x20)
            return(retStart, add(0x40, shl(5, mload(arrData))))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Helper for deallocating an automatically allocated array pointer.
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
