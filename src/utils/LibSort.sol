// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Optimized sorts and operations for sorted arrays.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Sort.sol)
library LibSort {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      INSERTION SORT                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // - Faster on small arrays (32 or lesser elements).
    // - Faster on almost sorted arrays.
    // - Stable (may matter if you are sorting packed numbers).
    // - Smaller bytecode.
    // - May be suitable for view functions intended for off-chain querying.

    /// @dev Sorts the array in-place with insertion sort.
    function insertionSort(uint256[] memory a) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(a) // Length of `a`.
            mstore(a, 0) // For insertion sort's inner loop to terminate.
            let h := add(a, shl(5, n)) // High slot.
            let w := not(31)

            for { let i := add(a, 0x20) } 1 {} {
                i := add(i, 0x20)
                if gt(i, h) { break }
                let k := mload(i) // Key.
                let j := add(i, w) // The slot before the current slot.
                let v := mload(j) // The value of `j`.
                if iszero(gt(v, k)) { continue }
                for {} 1 {} {
                    mstore(add(j, 0x20), v)
                    j := add(j, w) // `sub(j, 0x20)`.
                    v := mload(j)
                    if iszero(gt(v, k)) { break }
                }
                mstore(add(j, 0x20), k)
            }
            mstore(a, n) // Restore the length of `a`.
        }
    }

    /// @dev Sorts the array in-place with insertion sort.
    function insertionSort(int256[] memory a) internal pure {
        _convertTwosComplement(a);
        insertionSort(_cast(a));
        _convertTwosComplement(a);
    }

    /// @dev Sorts the array in-place with insertion sort.
    function insertionSort(address[] memory a) internal pure {
        insertionSort(_cast(a));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      INTRO-QUICKSORT                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // - Faster on larger arrays (more than 32 elements).
    // - Robust performance.
    // - Larger bytecode.
    // - NOT Stable (may matter if you are sorting packed numbers).

    /// @dev Sorts the array in-place with intro-quicksort.
    function sort(uint256[] memory a) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            let w := not(31)
            let n := mload(a) // Length of `a`.
            mstore(a, 0) // For insertion sort's inner loop to terminate.

            // Let the stack be the start of the free memory.
            let stack := mload(0x40)

            for {} iszero(lt(n, 2)) {} {
                // Push `l` and `h` to the stack.
                // The `shl` by 5 is equivalent to multiplying by `0x20`.
                let l := add(a, 0x20)
                let h := add(a, shl(5, n))

                let j := l
                // forgefmt: disable-next-item
                for {} iszero(or(eq(j, h), gt(mload(j), mload(add(j, 0x20))))) {} {
                    j := add(j, 0x20)
                }
                // If the array is already sorted.
                if eq(j, h) { break }

                j := h
                // forgefmt: disable-next-item
                for {} iszero(or(eq(j, l), gt(mload(j), mload(add(j, w))))) {} {
                    j := add(j, w) // `sub(j, 0x20)`.
                }
                // If the array is reversed sorted.
                if eq(j, l) {
                    for {} 1 {} {
                        let t := mload(l)
                        mstore(l, mload(h))
                        mstore(h, t)
                        h := add(h, w) // `sub(h, 0x20)`.
                        l := add(l, 0x20)
                        if iszero(lt(l, h)) { break }
                    }
                    break
                }

                // Push `l` and `h` onto the stack.
                mstore(stack, l)
                mstore(add(stack, 0x20), h)
                stack := add(stack, 0x40)
                break
            }

            for { let stackBottom := mload(0x40) } iszero(eq(stack, stackBottom)) {} {
                // Pop `l` and `h` from the stack.
                stack := sub(stack, 0x40)
                let l := mload(stack)
                let h := mload(add(stack, 0x20))

                // Do insertion sort if `h - l <= 0x20 * 12`.
                // Threshold is fine-tuned via trial and error.
                if iszero(gt(sub(h, l), 0x180)) {
                    // Hardcode sort the first 2 elements.
                    let i := add(l, 0x20)
                    if iszero(lt(mload(l), mload(i))) {
                        let t := mload(i)
                        mstore(i, mload(l))
                        mstore(l, t)
                    }
                    for {} 1 {} {
                        i := add(i, 0x20)
                        if gt(i, h) { break }
                        let k := mload(i) // Key.
                        let j := add(i, w) // The slot before the current slot.
                        let v := mload(j) // The value of `j`.
                        if iszero(gt(v, k)) { continue }
                        for {} 1 {} {
                            mstore(add(j, 0x20), v)
                            j := add(j, w)
                            v := mload(j)
                            if iszero(gt(v, k)) { break }
                        }
                        mstore(add(j, 0x20), k)
                    }
                    continue
                }
                // Pivot slot is the average of `l` and `h`,
                // rounded down to nearest multiple of 0x20.
                let p := shl(5, shr(6, add(l, h)))
                // Median of 3 with sorting.
                {
                    let e0 := mload(l)
                    let e2 := mload(h)
                    let e1 := mload(p)
                    if iszero(lt(e0, e1)) {
                        let t := e0
                        e0 := e1
                        e1 := t
                    }
                    if iszero(lt(e0, e2)) {
                        let t := e0
                        e0 := e2
                        e2 := t
                    }
                    if iszero(lt(e1, e2)) {
                        let t := e1
                        e1 := e2
                        e2 := t
                    }
                    mstore(p, e1)
                    mstore(h, e2)
                    mstore(l, e0)
                }
                // Hoare's partition.
                {
                    // The value of the pivot slot.
                    let x := mload(p)
                    p := h
                    for { let i := l } 1 {} {
                        for {} 1 {} {
                            i := add(i, 0x20)
                            if iszero(gt(x, mload(i))) { break }
                        }
                        let j := p
                        for {} 1 {} {
                            j := add(j, w)
                            if iszero(lt(x, mload(j))) { break }
                        }
                        p := j
                        if iszero(lt(i, p)) { break }
                        // Swap slots `i` and `p`.
                        let t := mload(i)
                        mstore(i, mload(p))
                        mstore(p, t)
                    }
                }
                // If slice on right of pivot is non-empty, push onto stack.
                {
                    mstore(stack, add(p, 0x20))
                    // Skip `mstore(add(stack, 0x20), h)`, as it is already on the stack.
                    stack := add(stack, shl(6, lt(add(p, 0x20), h)))
                }
                // If slice on left of pivot is non-empty, push onto stack.
                {
                    mstore(stack, l)
                    mstore(add(stack, 0x20), p)
                    stack := add(stack, shl(6, gt(p, l)))
                }
            }
            mstore(a, n) // Restore the length of `a`.
        }
    }

    /// @dev Sorts the array in-place with intro-quicksort.
    function sort(int256[] memory a) internal pure {
        _convertTwosComplement(a);
        sort(_cast(a));
        _convertTwosComplement(a);
    }

    /// @dev Sorts the array in-place with intro-quicksort.
    function sort(address[] memory a) internal pure {
        sort(_cast(a));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  OTHER USEFUL OPERATIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // For performance, the `uniquifySorted` methods will not revert if the
    // array is not sorted -- it will simply remove consecutive duplicate elements.

    /// @dev Removes duplicate elements from a ascendingly sorted memory array.
    function uniquifySorted(uint256[] memory a) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            // If the length of `a` is greater than 1.
            if iszero(lt(mload(a), 2)) {
                let x := add(a, 0x20)
                let y := add(a, 0x40)
                let end := add(a, shl(5, add(mload(a), 1)))
                for {} 1 {} {
                    if iszero(eq(mload(x), mload(y))) {
                        x := add(x, 0x20)
                        mstore(x, mload(y))
                    }
                    y := add(y, 0x20)
                    if eq(y, end) { break }
                }
                mstore(a, shr(5, sub(x, a)))
            }
        }
    }

    /// @dev Removes duplicate elements from a ascendingly sorted memory array.
    function uniquifySorted(int256[] memory a) internal pure {
        uniquifySorted(_cast(a));
    }

    /// @dev Removes duplicate elements from a ascendingly sorted memory array.
    function uniquifySorted(address[] memory a) internal pure {
        uniquifySorted(_cast(a));
    }

    /// @dev Returns whether `a` contains `needle`,
    /// and the index of the nearest element less than or equal to `needle`.
    function searchSorted(uint256[] memory a, uint256 needle)
        internal
        pure
        returns (bool found, uint256 index)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := 0 // Middle slot.
            let l := add(a, 0x20) // Slot of the start of search.
            let h := add(a, shl(5, mload(a))) // Slot of the end of search.
            for {} 1 {} {
                // Average of `l` and `h`, rounded down to the nearest multiple of 0x20.
                m := shl(5, shr(6, add(l, h)))
                found := eq(mload(m), needle)
                if or(gt(l, h), found) { break }
                // Decide whether to search the left or right half.
                if iszero(gt(needle, mload(m))) {
                    h := sub(m, 0x20)
                    continue
                }
                l := add(m, 0x20)
            }
            // `m` will be less than `add(a, 0x20)` in the case of an empty array,
            // or when the value is less than the smallest value in the array.
            let t := iszero(lt(m, add(a, 0x20)))
            index := shr(5, mul(sub(m, add(a, 0x20)), t))
            found := and(found, t)
        }
    }

    /// @dev Reverses the array in-place.
    function reverse(uint256[] memory a) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(lt(mload(a), 2)) {
                let w := not(31)
                let h := add(a, shl(5, mload(a)))
                for { a := add(a, 0x20) } 1 {} {
                    let t := mload(a)
                    mstore(a, mload(h))
                    mstore(h, t)
                    h := add(h, w)
                    a := add(a, 0x20)
                    if iszero(lt(a, h)) { break }
                }
            }
        }
    }

    /// @dev Reverses the array in-place.
    function reverse(int256[] memory a) internal pure {
        reverse(_cast(a));
    }

    /// @dev Reverses the array in-place.
    function reverse(address[] memory a) internal pure {
        reverse(_cast(a));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Reinterpret cast to an uint256 array.
    function _cast(int256[] memory a) private pure returns (uint256[] memory casted) {
        /// @solidity memory-safe-assembly
        assembly {
            casted := a
        }
    }

    /// @dev Reinterpret cast to an uint256 array.
    function _cast(address[] memory a) private pure returns (uint256[] memory casted) {
        /// @solidity memory-safe-assembly
        assembly {
            // As any address written to memory will have the upper 96 bits
            // of the word zeroized (as per Solidity spec), we can directly
            // compare these addresses as if they are whole uint256 words.
            casted := a
        }
    }

    /// @dev Converts an array of signed two-complement integers
    /// to unsigned integers suitable for sorting.
    function _convertTwosComplement(int256[] memory a) private pure {
        /// @solidity memory-safe-assembly
        assembly {
            let w := shl(255, 1)
            for { let end := add(a, shl(5, mload(a))) } iszero(eq(a, end)) {} {
                a := add(a, 0x20)
                mstore(a, add(mload(a), w))
            }
        }
    }
}
