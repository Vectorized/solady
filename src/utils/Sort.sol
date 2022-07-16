// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Optimized intro sort.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Sort.sol)
library Sort {
    // For efficient rounding down to a multiple of `0x20`.
    uint256 private constant LCG_MASK = 0xffffffffffffffe0;

    // From MINSTD.
    // See: https://en.wikipedia.org/wiki/Lehmer_random_number_generator#Parameters_in_common_use
    uint256 private constant LCG_MULTIPLIER = 48271;

    // For the linear congruential generator.
    uint256 private constant LCG_MODULO = 0x7fffffff;

    // This must be co-prime to `LCG_MODULO`.
    uint256 private constant LCG_SEED = 0xbeef;

    function sort(uint256[] memory a) internal pure {
        // This function could save some gas compared to passing in a calldata
        // array and verifying sortedness. For an array of 100 elements,
        // we are looking at less than 1k gas for each element on average.
        // A calldata address costs `68*20 + 4*12 = 1408` gas.
        // Compared to regular Solidity quick sort, it can save more than 50% gas.
        assembly {
            let n := mload(a) // Length of `a`.
            mstore(a, 0) // For insertion sort's inner loop to terminate.

            // Let the stack be the start of the free memory.
            let stackBottom := mload(0x40)
            let stack := add(stackBottom, 0x40)

            {
                // Push `l` and `h` to the stack.
                // The `shl` by 5 is equivalent to multiplying by `0x20`.
                let l := add(a, 0x20)
                let h := add(a, shl(5, n))
                mstore(stackBottom, l)
                mstore(add(stackBottom, 0x20), h)

                let s := 0 // Number of out of order elements.
                let u := mload(l) // Previous slot value, `u`.
                // prettier-ignore
                for { let j := add(l, 0x20) } iszero(gt(j, h)) { j := add(j, 0x20) } {
                    let v := mload(j) // Current slot value, `v`.
                    s := add(s, gt(u, v)) // Increment `s` by 1 if out of order.
                    u := v // Set previous slot value to current slot value.
                }
                // If the array is sorted, or reverse sorted,
                // subtract `0x40` from `stack` to make it equal to `stackBottom`,
                // which skips the sort.
                // `shl` 6 is equivalent to multiplying by `0x40`.
                stack := sub(stack, shl(6, or(iszero(s), eq(add(s, 1), n))))

                // If 50% or more of the elements are out of order,
                // reverse the array.
                if iszero(lt(shl(1, s), n)) {
                    // prettier-ignore
                    for {} lt(l, h) {} {
                        let t := mload(l)
                        mstore(l, mload(h))
                        mstore(h, t)
                        h := sub(h, 0x20)
                        l := add(l, 0x20)
                    }
                }
            }

            // Linear congruential generator (LCG) for psuedo-random partitioning
            // to prevent idiosyncratic worse case behaviour.
            let lcg := LCG_SEED
            // prettier-ignore
            for {} iszero(eq(stack, stackBottom)) {} {
                // Pop `l` and `h` from the stack.
                stack := sub(stack, 0x40)
                let l := mload(stack)
                let h := mload(add(stack, 0x20))

                switch shr(9, sub(h, l))
                case 0 {
                    // Do insertion sort if `h - l < 0x20 * 16`.
                    // prettier-ignore
                    for { let i := add(l, 0x20) } iszero(gt(i, h)) { i := add(i, 0x20) } {
                        let k := mload(i) // Key.
                        let j := i // The current slot.
                        let b := sub(j, 0x20) // The slot before the current slot.
                        let v := mload(b) // The value of `b`.
                        // prettier-ignore
                        for {} gt(v, k) {} {
                            mstore(j, v)
                            j := b
                            b := sub(b, 0x20)
                            v := mload(b)
                        }
                        mstore(j, k)
                    }
                }
                default {
                    // Psuedo-random partition pivot.
                    lcg := mulmod(lcg, LCG_MULTIPLIER, LCG_MODULO) // Step the LCG.
                    let p := and(sub(h, mod(lcg, sub(h, l))), LCG_MASK) // Pivot slot.
                    let x := mload(p) // The value of the pivot slot.
                    // Swap the values of `p` and `h`.
                    mstore(p, mload(h))
                    mstore(h, x)

                    p := l // Set the pivot slot to the left of the slice.
                    let e := sub(h, 0x20) // End of the partition.

                    // prettier-ignore
                    for { let j := l } iszero(gt(j, e)) { j := add(j, 0x20) } {
                        // Whenever a value less than the pivot value is 
                        // detected, move it to the left of the slice, 
                        // and advance the pivot slot.
                        if iszero(gt(mload(j), x)) {
                            let t := mload(p)
                            mstore(p, mload(j))
                            mstore(j, t)
                            p := add(p, 0x20)
                        }
                    }
                    // Swap back the values of `p` and `h`.
                    {
                        let t := mload(p)
                        mstore(p, x) // Restore the pivot value at the pivot slot.
                        mstore(h, t) // Store whatever was the replaced value at the end.
                    }
                    // If slice on left of pivot is non-empty, push onto stack.
                    {
                        let t := sub(p, 0x20)
                        // We can skip `mstore(stack, l)`.
                        mstore(add(stack, 0x20), t)
                        // `shl` 6 is equivalent to multiplying by `0x40`.
                        stack := add(stack, shl(6, gt(t, l)))
                    }
                    // If slice on right of pivot is non-empty, push onto stack.
                    {
                        let t := add(p, 0x20)
                        mstore(stack, t)
                        mstore(add(stack, 0x20), h)
                        // `shl` 6 is equivalent to multiplying by `0x40`.
                        stack := add(stack, shl(6, lt(t, h)))    
                    }
                }
            }
            mstore(a, n) // Restore the length of `a`.
        }
    }

    function sort(address[] memory a) internal pure {
        // As any address written to memory will have the upper 96 bits of the
        // word zeroized (as per Solidity spec), we can directly compare
        // these addresses as if they are whole uint256 words.
        uint256[] memory aCasted;
        assembly {
            aCasted := a
        }
        sort(aCasted);
    }
}
