// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Optimized sorts and operations for sorted arrays.
/// @author Solady (https://github.com/Vectorized/solady/blob/main/src/utils/LibSort.sol)
library LibSort {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      INSERTION SORT                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // - Faster on small arrays (32 or lesser elements).
    // - Faster on almost sorted arrays.
    // - Smaller bytecode (about 300 bytes smaller than sort, which uses intro-quicksort).
    // - May be suitable for view functions intended for off-chain querying.

    /// @dev Sorts the array in-place with insertion sort.
    function insertionSort(uint256[] memory a) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(a) // Length of `a`.
            mstore(a, 0) // For insertion sort's inner loop to terminate.
            let h := add(a, shl(5, n)) // High slot.
            let w := not(0x1f)
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
        _flipSign(a);
        insertionSort(_toUints(a));
        _flipSign(a);
    }

    /// @dev Sorts the array in-place with insertion sort.
    function insertionSort(address[] memory a) internal pure {
        insertionSort(_toUints(a));
    }

    /// @dev Sorts the array in-place with insertion sort.
    function insertionSort(bytes32[] memory a) internal pure {
        insertionSort(_toUints(a));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      INTRO-QUICKSORT                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // - Faster on larger arrays (more than 32 elements).
    // - Robust performance.
    // - Larger bytecode.

    /// @dev Sorts the array in-place with intro-quicksort.
    function sort(uint256[] memory a) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            function swap(a_, b_) -> _a, _b {
                _b := a_
                _a := b_
            }
            function mswap(i_, j_) {
                let t_ := mload(i_)
                mstore(i_, mload(j_))
                mstore(j_, t_)
            }
            function sortInner(w_, l_, h_) {
                // Do insertion sort if `h_ - l_ <= 0x20 * 12`.
                // Threshold is fine-tuned via trial and error.
                if iszero(gt(sub(h_, l_), 0x180)) {
                    // Hardcode sort the first 2 elements.
                    let i_ := add(l_, 0x20)
                    if iszero(lt(mload(l_), mload(i_))) { mswap(i_, l_) }
                    for {} 1 {} {
                        i_ := add(i_, 0x20)
                        if gt(i_, h_) { break }
                        let k_ := mload(i_) // Key.
                        let j_ := add(i_, w_) // The slot before the current slot.
                        let v_ := mload(j_) // The value of `j_`.
                        if iszero(gt(v_, k_)) { continue }
                        for {} 1 {} {
                            mstore(add(j_, 0x20), v_)
                            j_ := add(j_, w_)
                            v_ := mload(j_)
                            if iszero(gt(v_, k_)) { break }
                        }
                        mstore(add(j_, 0x20), k_)
                    }
                    leave
                }
                // Pivot slot is the average of `l_` and `h_`.
                let p_ := add(shl(5, shr(6, add(l_, h_))), and(31, l_))
                // Median of 3 with sorting.
                {
                    let e0_ := mload(l_)
                    let e1_ := mload(p_)
                    if iszero(lt(e0_, e1_)) { e0_, e1_ := swap(e0_, e1_) }
                    let e2_ := mload(h_)
                    if iszero(lt(e1_, e2_)) {
                        e1_, e2_ := swap(e1_, e2_)
                        if iszero(lt(e0_, e1_)) { e0_, e1_ := swap(e0_, e1_) }
                    }
                    mstore(h_, e2_)
                    mstore(p_, e1_)
                    mstore(l_, e0_)
                }
                // Hoare's partition.
                {
                    // The value of the pivot slot.
                    let x_ := mload(p_)
                    p_ := h_
                    for { let i_ := l_ } 1 {} {
                        for {} 1 {} {
                            i_ := add(0x20, i_)
                            if iszero(gt(x_, mload(i_))) { break }
                        }
                        let j_ := p_
                        for {} 1 {} {
                            j_ := add(w_, j_)
                            if iszero(lt(x_, mload(j_))) { break }
                        }
                        p_ := j_
                        if iszero(lt(i_, p_)) { break }
                        mswap(i_, p_)
                    }
                }
                if iszero(eq(add(p_, 0x20), h_)) { sortInner(w_, add(p_, 0x20), h_) }
                if iszero(eq(p_, l_)) { sortInner(w_, l_, p_) }
            }

            for { let n := mload(a) } iszero(lt(n, 2)) {} {
                let w := not(0x1f) // `-0x20`.
                let l := add(a, 0x20) // Low slot.
                let h := add(a, shl(5, n)) // High slot.
                let j := h
                // While `mload(j - 0x20) <= mload(j): j -= 0x20`.
                for {} iszero(gt(mload(add(w, j)), mload(j))) {} { j := add(w, j) }
                // If the array is already sorted, break.
                if iszero(gt(j, l)) { break }
                // While `mload(j - 0x20) >= mload(j): j -= 0x20`.
                for { j := h } iszero(lt(mload(add(w, j)), mload(j))) {} { j := add(w, j) }
                // If the array is reversed sorted.
                if iszero(gt(j, l)) {
                    for {} 1 {} {
                        let t := mload(l)
                        mstore(l, mload(h))
                        mstore(h, t)
                        h := add(w, h)
                        l := add(l, 0x20)
                        if iszero(lt(l, h)) { break }
                    }
                    break
                }
                mstore(a, 0) // For insertion sort's inner loop to terminate.
                sortInner(w, l, h)
                mstore(a, n) // Restore the length of `a`.
                break
            }
        }
    }

    /// @dev Sorts the array in-place with intro-quicksort.
    function sort(int256[] memory a) internal pure {
        _flipSign(a);
        sort(_toUints(a));
        _flipSign(a);
    }

    /// @dev Sorts the array in-place with intro-quicksort.
    function sort(address[] memory a) internal pure {
        sort(_toUints(a));
    }

    /// @dev Sorts the array in-place with intro-quicksort.
    function sort(bytes32[] memory a) internal pure {
        sort(_toUints(a));
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
        uniquifySorted(_toUints(a));
    }

    /// @dev Removes duplicate elements from a ascendingly sorted memory array.
    function uniquifySorted(address[] memory a) internal pure {
        uniquifySorted(_toUints(a));
    }

    /// @dev Removes duplicate elements from a ascendingly sorted memory array.
    function uniquifySorted(bytes32[] memory a) internal pure {
        uniquifySorted(_toUints(a));
    }

    /// @dev Returns whether `a` contains `needle`, and the index of `needle`.
    /// `index` precedence: equal to > nearest before > nearest after.
    function searchSorted(uint256[] memory a, uint256 needle)
        internal
        pure
        returns (bool found, uint256 index)
    {
        (found, index) = _searchSorted(a, needle, 0);
    }

    /// @dev Returns whether `a` contains `needle`, and the index of `needle`.
    /// `index` precedence: equal to > nearest before > nearest after.
    function searchSorted(int256[] memory a, int256 needle)
        internal
        pure
        returns (bool found, uint256 index)
    {
        (found, index) = _searchSorted(_toUints(a), uint256(needle), 1 << 255);
    }

    /// @dev Returns whether `a` contains `needle`, and the index of `needle`.
    /// `index` precedence: equal to > nearest before > nearest after.
    function searchSorted(address[] memory a, address needle)
        internal
        pure
        returns (bool found, uint256 index)
    {
        (found, index) = _searchSorted(_toUints(a), uint160(needle), 0);
    }

    /// @dev Returns whether `a` contains `needle`, and the index of `needle`.
    /// `index` precedence: equal to > nearest before > nearest after.
    function searchSorted(bytes32[] memory a, bytes32 needle)
        internal
        pure
        returns (bool found, uint256 index)
    {
        (found, index) = _searchSorted(_toUints(a), uint256(needle), 0);
    }

    /// @dev Returns whether `a` contains `needle`.
    function inSorted(uint256[] memory a, uint256 needle) internal pure returns (bool found) {
        (found,) = searchSorted(a, needle);
    }

    /// @dev Returns whether `a` contains `needle`.
    function inSorted(int256[] memory a, int256 needle) internal pure returns (bool found) {
        (found,) = searchSorted(a, needle);
    }

    /// @dev Returns whether `a` contains `needle`.
    function inSorted(address[] memory a, address needle) internal pure returns (bool found) {
        (found,) = searchSorted(a, needle);
    }

    /// @dev Returns whether `a` contains `needle`.
    function inSorted(bytes32[] memory a, bytes32 needle) internal pure returns (bool found) {
        (found,) = searchSorted(a, needle);
    }

    /// @dev Reverses the array in-place.
    function reverse(uint256[] memory a) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(lt(mload(a), 2)) {
                let s := 0x20
                let w := not(0x1f)
                let h := add(a, shl(5, mload(a)))
                for { a := add(a, s) } 1 {} {
                    let t := mload(a)
                    mstore(a, mload(h))
                    mstore(h, t)
                    h := add(h, w)
                    a := add(a, s)
                    if iszero(lt(a, h)) { break }
                }
            }
        }
    }

    /// @dev Reverses the array in-place.
    function reverse(int256[] memory a) internal pure {
        reverse(_toUints(a));
    }

    /// @dev Reverses the array in-place.
    function reverse(address[] memory a) internal pure {
        reverse(_toUints(a));
    }

    /// @dev Reverses the array in-place.
    function reverse(bytes32[] memory a) internal pure {
        reverse(_toUints(a));
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

    /// @dev Returns a copy of the array.
    function copy(int256[] memory a) internal pure returns (int256[] memory result) {
        result = _toInts(copy(_toUints(a)));
    }

    /// @dev Returns a copy of the array.
    function copy(address[] memory a) internal pure returns (address[] memory result) {
        result = _toAddresses(copy(_toUints(a)));
    }

    /// @dev Returns a copy of the array.
    function copy(bytes32[] memory a) internal pure returns (bytes32[] memory result) {
        result = _toBytes32s(copy(_toUints(a)));
    }

    /// @dev Returns whether the array is sorted in ascending order.
    function isSorted(uint256[] memory a) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            if iszero(lt(mload(a), 2)) {
                let end := add(a, shl(5, mload(a)))
                for { a := add(a, 0x20) } 1 {} {
                    let p := mload(a)
                    a := add(a, 0x20)
                    result := iszero(gt(p, mload(a)))
                    if iszero(mul(result, xor(a, end))) { break }
                }
            }
        }
    }

    /// @dev Returns whether the array is sorted in ascending order.
    function isSorted(int256[] memory a) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            if iszero(lt(mload(a), 2)) {
                let end := add(a, shl(5, mload(a)))
                for { a := add(a, 0x20) } 1 {} {
                    let p := mload(a)
                    a := add(a, 0x20)
                    result := iszero(sgt(p, mload(a)))
                    if iszero(mul(result, xor(a, end))) { break }
                }
            }
        }
    }

    /// @dev Returns whether the array is sorted in ascending order.
    function isSorted(address[] memory a) internal pure returns (bool result) {
        result = isSorted(_toUints(a));
    }

    /// @dev Returns whether the array is sorted in ascending order.
    function isSorted(bytes32[] memory a) internal pure returns (bool result) {
        result = isSorted(_toUints(a));
    }

    /// @dev Returns whether the array is strictly ascending (sorted and uniquified).
    function isSortedAndUniquified(uint256[] memory a) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            if iszero(lt(mload(a), 2)) {
                let end := add(a, shl(5, mload(a)))
                for { a := add(a, 0x20) } 1 {} {
                    let p := mload(a)
                    a := add(a, 0x20)
                    result := lt(p, mload(a))
                    if iszero(mul(result, xor(a, end))) { break }
                }
            }
        }
    }

    /// @dev Returns whether the array is strictly ascending (sorted and uniquified).
    function isSortedAndUniquified(int256[] memory a) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            if iszero(lt(mload(a), 2)) {
                let end := add(a, shl(5, mload(a)))
                for { a := add(a, 0x20) } 1 {} {
                    let p := mload(a)
                    a := add(a, 0x20)
                    result := slt(p, mload(a))
                    if iszero(mul(result, xor(a, end))) { break }
                }
            }
        }
    }

    /// @dev Returns whether the array is strictly ascending (sorted and uniquified).
    function isSortedAndUniquified(address[] memory a) internal pure returns (bool result) {
        result = isSortedAndUniquified(_toUints(a));
    }

    /// @dev Returns whether the array is strictly ascending (sorted and uniquified).
    function isSortedAndUniquified(bytes32[] memory a) internal pure returns (bool result) {
        result = isSortedAndUniquified(_toUints(a));
    }

    /// @dev Returns the sorted set difference of `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function difference(uint256[] memory a, uint256[] memory b)
        internal
        pure
        returns (uint256[] memory c)
    {
        c = _difference(a, b, 0);
    }

    /// @dev Returns the sorted set difference between `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function difference(int256[] memory a, int256[] memory b)
        internal
        pure
        returns (int256[] memory c)
    {
        c = _toInts(_difference(_toUints(a), _toUints(b), 1 << 255));
    }

    /// @dev Returns the sorted set difference between `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function difference(address[] memory a, address[] memory b)
        internal
        pure
        returns (address[] memory c)
    {
        c = _toAddresses(_difference(_toUints(a), _toUints(b), 0));
    }

    /// @dev Returns the sorted set difference between `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function difference(bytes32[] memory a, bytes32[] memory b)
        internal
        pure
        returns (bytes32[] memory c)
    {
        c = _toBytes32s(_difference(_toUints(a), _toUints(b), 0));
    }

    /// @dev Returns the sorted set intersection between `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function intersection(uint256[] memory a, uint256[] memory b)
        internal
        pure
        returns (uint256[] memory c)
    {
        c = _intersection(a, b, 0);
    }

    /// @dev Returns the sorted set intersection between `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function intersection(int256[] memory a, int256[] memory b)
        internal
        pure
        returns (int256[] memory c)
    {
        c = _toInts(_intersection(_toUints(a), _toUints(b), 1 << 255));
    }

    /// @dev Returns the sorted set intersection between `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function intersection(address[] memory a, address[] memory b)
        internal
        pure
        returns (address[] memory c)
    {
        c = _toAddresses(_intersection(_toUints(a), _toUints(b), 0));
    }

    /// @dev Returns the sorted set intersection between `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function intersection(bytes32[] memory a, bytes32[] memory b)
        internal
        pure
        returns (bytes32[] memory c)
    {
        c = _toBytes32s(_intersection(_toUints(a), _toUints(b), 0));
    }

    /// @dev Returns the sorted set union of `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function union(uint256[] memory a, uint256[] memory b)
        internal
        pure
        returns (uint256[] memory c)
    {
        c = _union(a, b, 0);
    }

    /// @dev Returns the sorted set union of `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function union(int256[] memory a, int256[] memory b)
        internal
        pure
        returns (int256[] memory c)
    {
        c = _toInts(_union(_toUints(a), _toUints(b), 1 << 255));
    }

    /// @dev Returns the sorted set union between `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function union(address[] memory a, address[] memory b)
        internal
        pure
        returns (address[] memory c)
    {
        c = _toAddresses(_union(_toUints(a), _toUints(b), 0));
    }

    /// @dev Returns the sorted set union between `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function union(bytes32[] memory a, bytes32[] memory b)
        internal
        pure
        returns (bytes32[] memory c)
    {
        c = _toBytes32s(_union(_toUints(a), _toUints(b), 0));
    }

    /// @dev Cleans the upper 96 bits of the addresses.
    /// In case `a` is produced via assembly and might have dirty upper bits.
    function clean(address[] memory a) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            let addressMask := shr(96, not(0))
            for { let end := add(a, shl(5, mload(a))) } iszero(eq(a, end)) {} {
                a := add(a, 0x20)
                mstore(a, and(mload(a), addressMask))
            }
        }
    }

    /// @dev Sorts and uniquifies `keys`. Updates `values` with the grouped sums by key.
    function groupSum(uint256[] memory keys, uint256[] memory values) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            function mswap(i_, j_) {
                let t_ := mload(i_)
                mstore(i_, mload(j_))
                mstore(j_, t_)
            }
            function sortInner(l_, h_, d_) {
                let p_ := mload(l_)
                let j_ := l_
                for { let i_ := add(l_, 0x20) } 1 {} {
                    if lt(mload(i_), p_) {
                        j_ := add(j_, 0x20)
                        mswap(i_, j_)
                        mswap(add(i_, d_), add(j_, d_))
                    }
                    i_ := add(0x20, i_)
                    if iszero(lt(i_, h_)) { break }
                }
                mswap(l_, j_)
                mswap(add(l_, d_), add(j_, d_))
                if iszero(gt(add(0x40, l_), j_)) { sortInner(l_, j_, d_) }
                if iszero(gt(add(0x60, j_), h_)) { sortInner(add(j_, 0x20), h_, d_) }
            }
            let n := mload(values)
            if iszero(eq(mload(keys), n)) {
                mstore(0x00, 0x4e487b71)
                mstore(0x20, 0x32) // Array out of bounds panic if the arrays lengths differ.
                revert(0x1c, 0x24)
            }
            if iszero(lt(n, 2)) {
                let d := sub(values, keys)
                let x := add(keys, 0x20)
                let end := add(x, shl(5, n))
                sortInner(x, end, d)
                let s := mload(add(x, d))
                for { let y := add(keys, 0x40) } 1 {} {
                    if iszero(eq(mload(x), mload(y))) {
                        mstore(add(x, d), s) // Write sum.
                        s := 0
                        x := add(x, 0x20)
                        mstore(x, mload(y))
                    }
                    s := add(s, mload(add(y, d)))
                    if lt(s, mload(add(y, d))) {
                        mstore(0x00, 0x4e487b71)
                        mstore(0x20, 0x11) // Overflow panic if the addition overflows.
                        revert(0x1c, 0x24)
                    }
                    y := add(y, 0x20)
                    if eq(y, end) { break }
                }
                mstore(add(x, d), s) // Write sum.
                mstore(keys, shr(5, sub(x, keys))) // Truncate.
                mstore(values, mload(keys)) // Truncate.
            }
        }
    }

    /// @dev Sorts and uniquifies `keys`. Updates `values` with the grouped sums by key.
    function groupSum(address[] memory keys, uint256[] memory values) internal pure {
        groupSum(_toUints(keys), values);
    }

    /// @dev Sorts and uniquifies `keys`. Updates `values` with the grouped sums by key.
    function groupSum(bytes32[] memory keys, uint256[] memory values) internal pure {
        groupSum(_toUints(keys), values);
    }

    /// @dev Sorts and uniquifies `keys`. Updates `values` with the grouped sums by key.
    function groupSum(int256[] memory keys, uint256[] memory values) internal pure {
        groupSum(_toUints(keys), values);
    }

    /// @dev Returns if `a` has any duplicate. Does NOT mutate `a`. `O(n)`.
    function hasDuplicate(uint256[] memory a) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            function p(i_, x_) -> _y {
                _y := or(shr(i_, x_), x_)
            }
            let n := mload(a)
            if iszero(lt(n, 2)) {
                let m := mload(0x40) // Use free memory temporarily for hashmap.
                let w := not(0x1f) // `-0x20`.
                let c := and(w, p(16, p(8, p(4, p(2, p(1, mul(0x30, n)))))))
                calldatacopy(m, calldatasize(), add(0x20, c)) // Zeroize hashmap.
                for { let i := add(a, shl(5, n)) } 1 {} {
                    // See LibPRNG for explanation of this formula.
                    let r := mulmod(mload(i), 0x100000000000000000000000000000051, not(0xbc))
                    // Linear probing.
                    for {} 1 { r := add(0x20, r) } {
                        let o := add(m, and(r, c)) // Non-zero pointer into hashmap.
                        if iszero(mload(o)) {
                            mstore(o, i) // Store non-zero pointer into hashmap.
                            break
                        }
                        if eq(mload(mload(o)), mload(i)) {
                            result := 1
                            i := a // To break the outer loop.
                            break
                        }
                    }
                    i := add(i, w) // Iterate `a` backwards.
                    if iszero(lt(a, i)) { break }
                }
                if shr(31, n) { invalid() } // Just in case.
            }
        }
    }

    /// @dev Returns if `a` has any duplicate. Does NOT mutate `a`. `O(n)`.
    function hasDuplicate(address[] memory a) internal pure returns (bool) {
        return hasDuplicate(_toUints(a));
    }

    /// @dev Returns if `a` has any duplicate. Does NOT mutate `a`. `O(n)`.
    function hasDuplicate(bytes32[] memory a) internal pure returns (bool) {
        return hasDuplicate(_toUints(a));
    }

    /// @dev Returns if `a` has any duplicate. Does NOT mutate `a`. `O(n)`.
    function hasDuplicate(int256[] memory a) internal pure returns (bool) {
        return hasDuplicate(_toUints(a));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Reinterpret cast to an uint256 array.
    function _toUints(int256[] memory a) private pure returns (uint256[] memory casted) {
        /// @solidity memory-safe-assembly
        assembly {
            casted := a
        }
    }

    /// @dev Reinterpret cast to an uint256 array.
    function _toUints(address[] memory a) private pure returns (uint256[] memory casted) {
        /// @solidity memory-safe-assembly
        assembly {
            // As any address written to memory will have the upper 96 bits
            // of the word zeroized (as per Solidity spec), we can directly
            // compare these addresses as if they are whole uint256 words.
            casted := a
        }
    }

    /// @dev Reinterpret cast to an uint256 array.
    function _toUints(bytes32[] memory a) private pure returns (uint256[] memory casted) {
        /// @solidity memory-safe-assembly
        assembly {
            casted := a
        }
    }

    /// @dev Reinterpret cast to an int array.
    function _toInts(uint256[] memory a) private pure returns (int256[] memory casted) {
        /// @solidity memory-safe-assembly
        assembly {
            casted := a
        }
    }

    /// @dev Reinterpret cast to an address array.
    function _toAddresses(uint256[] memory a) private pure returns (address[] memory casted) {
        /// @solidity memory-safe-assembly
        assembly {
            casted := a
        }
    }

    /// @dev Reinterpret cast to an bytes32 array.
    function _toBytes32s(uint256[] memory a) private pure returns (bytes32[] memory casted) {
        /// @solidity memory-safe-assembly
        assembly {
            casted := a
        }
    }

    /// @dev Converts an array of signed integers to unsigned
    /// integers suitable for sorting or vice versa.
    function _flipSign(int256[] memory a) private pure {
        /// @solidity memory-safe-assembly
        assembly {
            let q := shl(255, 1)
            for { let i := add(a, shl(5, mload(a))) } iszero(eq(a, i)) {} {
                mstore(i, add(mload(i), q))
                i := sub(i, 0x20)
            }
        }
    }

    /// @dev Returns whether `a` contains `needle`, and the index of `needle`.
    /// `index` precedence: equal to > nearest before > nearest after.
    function _searchSorted(uint256[] memory a, uint256 needle, uint256 signed)
        private
        pure
        returns (bool found, uint256 index)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let w := not(0)
            let l := 1
            let h := mload(a)
            let t := 0
            for { needle := add(signed, needle) } 1 {} {
                index := shr(1, add(l, h))
                t := add(signed, mload(add(a, shl(5, index))))
                if or(gt(l, h), eq(t, needle)) { break }
                // Decide whether to search the left or right half.
                if iszero(gt(needle, t)) {
                    h := add(index, w)
                    continue
                }
                l := add(index, 1)
            }
            // `index` will be zero in the case of an empty array,
            // or when the value is less than the smallest value in the array.
            found := eq(t, needle)
            t := iszero(iszero(index))
            index := mul(add(index, w), t)
            found := and(found, t)
        }
    }

    /// @dev Returns the sorted set difference of `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function _difference(uint256[] memory a, uint256[] memory b, uint256 signed)
        private
        pure
        returns (uint256[] memory c)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let s := 0x20
            let aEnd := add(a, shl(5, mload(a)))
            let bEnd := add(b, shl(5, mload(b)))
            c := mload(0x40) // Set `c` to the free memory pointer.
            a := add(a, s)
            b := add(b, s)
            let k := c
            for {} iszero(or(gt(a, aEnd), gt(b, bEnd))) {} {
                let u := mload(a)
                let v := mload(b)
                if iszero(xor(u, v)) {
                    a := add(a, s)
                    b := add(b, s)
                    continue
                }
                if iszero(lt(add(u, signed), add(v, signed))) {
                    b := add(b, s)
                    continue
                }
                k := add(k, s)
                mstore(k, u)
                a := add(a, s)
            }
            for {} iszero(gt(a, aEnd)) {} {
                k := add(k, s)
                mstore(k, mload(a))
                a := add(a, s)
            }
            mstore(c, shr(5, sub(k, c))) // Store the length of `c`.
            mstore(0x40, add(k, s)) // Allocate the memory for `c`.
        }
    }

    /// @dev Returns the sorted set intersection between `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function _intersection(uint256[] memory a, uint256[] memory b, uint256 signed)
        private
        pure
        returns (uint256[] memory c)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let s := 0x20
            let aEnd := add(a, shl(5, mload(a)))
            let bEnd := add(b, shl(5, mload(b)))
            c := mload(0x40) // Set `c` to the free memory pointer.
            a := add(a, s)
            b := add(b, s)
            let k := c
            for {} iszero(or(gt(a, aEnd), gt(b, bEnd))) {} {
                let u := mload(a)
                let v := mload(b)
                if iszero(xor(u, v)) {
                    k := add(k, s)
                    mstore(k, u)
                    a := add(a, s)
                    b := add(b, s)
                    continue
                }
                if iszero(lt(add(u, signed), add(v, signed))) {
                    b := add(b, s)
                    continue
                }
                a := add(a, s)
            }
            mstore(c, shr(5, sub(k, c))) // Store the length of `c`.
            mstore(0x40, add(k, s)) // Allocate the memory for `c`.
        }
    }

    /// @dev Returns the sorted set union of `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function _union(uint256[] memory a, uint256[] memory b, uint256 signed)
        private
        pure
        returns (uint256[] memory c)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let s := 0x20
            let aEnd := add(a, shl(5, mload(a)))
            let bEnd := add(b, shl(5, mload(b)))
            c := mload(0x40) // Set `c` to the free memory pointer.
            a := add(a, s)
            b := add(b, s)
            let k := c
            for {} iszero(or(gt(a, aEnd), gt(b, bEnd))) {} {
                let u := mload(a)
                let v := mload(b)
                if iszero(xor(u, v)) {
                    k := add(k, s)
                    mstore(k, u)
                    a := add(a, s)
                    b := add(b, s)
                    continue
                }
                if iszero(lt(add(u, signed), add(v, signed))) {
                    k := add(k, s)
                    mstore(k, v)
                    b := add(b, s)
                    continue
                }
                k := add(k, s)
                mstore(k, u)
                a := add(a, s)
            }
            for {} iszero(gt(a, aEnd)) {} {
                k := add(k, s)
                mstore(k, mload(a))
                a := add(a, s)
            }
            for {} iszero(gt(b, bEnd)) {} {
                k := add(k, s)
                mstore(k, mload(b))
                b := add(b, s)
            }
            mstore(c, shr(5, sub(k, c))) // Store the length of `c`.
            mstore(0x40, add(k, s)) // Allocate the memory for `c`.
        }
    }
}
