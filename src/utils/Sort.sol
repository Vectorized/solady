// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Optimized intro sort.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Sort.sol)
library Sort {
    // For efficient rounding down to a multiple of `0x20`.
    uint256 private constant _LCG_MASK = 0xffffffffffffffe0;

    // From MINSTD.
    // See: https://en.wikipedia.org/wiki/Lehmer_random_number_generator#Parameters_in_common_use
    uint256 private constant _LCG_MULTIPLIER = 48271;

    // For the linear congruential generator.
    uint256 private constant _LCG_MODULO = 0x7fffffff;

    // Any integer from `[1 .. _LCG_MODULO - 1]` will do, since `_LCG_MODULO` is prime.
    uint256 private constant _LCG_SEED = 0xbeef;

    function sort(uint256[] memory a) internal pure {
        assembly {
            let n := mload(a) // Length of `a`.
            mstore(a, 0) // For insertion sort's inner loop to terminate.

            // Let the stack be the start of the free memory.
            let stack := mload(0x40)
            let stackBottom := stack

            for {

            } iszero(lt(n, 2)) {

            } {
                // Push `l` and `h` to the stack.
                // The `shl` by 5 is equivalent to multiplying by `0x20`.
                let l := add(a, 0x20)
                let h := add(l, shl(5, n))

                let u := mload(l) // Previous slot value, `u`.
                let j := add(l, 0x20)
                let s := 0 // Number of out of order elements.

                // prettier-ignore
                for {} 1 {} {
                    let v := mload(j) // Current slot value, `v`.
                    s := add(s, gt(u, v)) // Increment `s` by 1 if out of order.
                    u := v // Set previous slot value to current slot value.
                    j := add(j, 0x20)
                    // prettier-ignore
                    if iszero(lt(j, h)) { break }
                }

                // If the array is already sorted.
                // prettier-ignore
                if iszero(s) { break }

                // If the array is reversed sorted.
                if eq(add(s, 1), n) {
                    h := sub(h, 0x20)
                    // prettier-ignore
                    for {} 1 {} {
                        let t := mload(l)
                        mstore(l, mload(h))
                        mstore(h, t)
                        h := sub(h, 0x20)
                        l := add(l, 0x20)
                        // prettier-ignore
                        if iszero(lt(l, h)) { break }
                    }
                    break
                }

                // Push `l` and `h` onto the stack.
                mstore(stack, l)
                mstore(add(stack, 0x20), sub(h, 0x20))
                stack := add(stack, 0x40)
                break
            }

            // Linear congruential generator (LCG) for psuedo-random partitioning
            // to prevent idiosyncratic worse case behaviour.
            let lcg := _LCG_SEED
            // prettier-ignore
            for {} iszero(eq(stack, stackBottom)) {} {
                // Pop `l` and `h` from the stack.
                stack := sub(stack, 0x40)
                let l := mload(stack)
                let h := mload(add(stack, 0x20))

                // Do insertion sort if `h - l <= 0x20 * 12`.
                // Threshold is fine-tuned via trial and error.
                if iszero(gt(sub(h, l), 0x180)) {
                    // Hardcode sort the first 2 elements.
                    let t := mload(add(l, 0x20))
                    if iszero(lt(mload(l), t)) {
                        mstore(add(l, 0x20), mload(l))
                        mstore(l, t)
                    }
                    // prettier-ignore
                    for { let i := add(l, 0x40) } iszero(gt(i, h)) { i := add(i, 0x20) } {
                        let k := mload(i) // Key.
                        let j := sub(i, 0x20) // The slot before the current slot.
                        let v := mload(j) // The value of `j`.
                        // prettier-ignore
                        if iszero(gt(v, k)) { continue }
                        // prettier-ignore
                        for {} 1 {} {
                            mstore(add(j, 0x20), v)
                            j := sub(j, 0x20)
                            v := mload(j)
                            // prettier-ignore
                            if iszero(gt(v, k)) { break }
                        }
                        mstore(add(j, 0x20), k)
                    }
                    continue
                }

                // Psuedo-random partition pivot.
                lcg := mulmod(lcg, _LCG_MULTIPLIER, _LCG_MODULO) // Step the LCG.
                let p := and(sub(h, mod(lcg, sub(h, l))), _LCG_MASK) // Pivot slot.
                let x := mload(p) // The value of the pivot slot.
                // Swap slots `l` and `p`.
                {
                    mstore(p, mload(l))
                    mstore(l, x)
                }
                // Hoare's partition.
                {
                    p := add(h, 0x20)
                    // prettier-ignore
                    for { let i := sub(l, 0x20) } 1 {} {
                        // prettier-ignore
                        for {} 1 {} { 
                            i := add(i, 0x20)
                            // prettier-ignore
                            if iszero(gt(x, mload(i))) { break }
                        }
                        let j := p
                        // prettier-ignore
                        for {} 1 {} { 
                            j := sub(j, 0x20)
                            // prettier-ignore
                            if iszero(lt(x, mload(j))) { break }
                        }
                        p := j
                        // prettier-ignore
                        if iszero(lt(i, p)) { break }
                        // Swap slots `i` and `p`.
                        let t := mload(i)
                        mstore(i, mload(p))
                        mstore(p, t)
                    }
                }
                // If slice on left of pivot is non-empty, push onto stack.
                {
                    // We can skip `mstore(stack, l)`.
                    mstore(add(stack, 0x20), p)
                    stack := add(stack, mul(0x40, gt(p, l)))
                }
                // If slice on right of pivot is non-empty, push onto stack.
                {
                    mstore(stack, add(p, 0x20))
                    mstore(add(stack, 0x20), h)
                    stack := add(stack, mul(0x40, lt(add(p, 0x20), h)))
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
