// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Optimized intro sort.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Sort.sol)
library Sort {
    function sort(uint256[] memory a) internal pure {
        assembly {
            let n := mload(a) // Length of `a`.
            mstore(a, 0) // For insertion sort's inner loop to terminate.

            // Let the stack be the start of the free memory.
            let stack := mload(0x40)

            // prettier-ignore
            for {} iszero(lt(n, 2)) {} {
                // Push `l` and `h` to the stack.
                // The `shl` by 5 is equivalent to multiplying by `0x20`.
                let l := add(a, 0x20)
                let h := add(a, shl(5, n))
                
                let j := l
                // prettier-ignore
                for {} iszero(or(eq(j, h), gt(mload(j), mload(add(j, 0x20))))) {} {
                    j := add(j, 0x20)
                }
                // If the array is already sorted.
                // prettier-ignore
                if eq(j, h) { break }

                j := h
                // prettier-ignore
                for {} iszero(or(eq(j, l), gt(mload(j), mload(sub(j, 0x20))))) {} {
                    j := sub(j, 0x20)
                }
                // If the array is reversed sorted.
                if eq(j, l) { 
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
                mstore(add(stack, 0x20), h)
                stack := add(stack, 0x40)
                break
            }

            // prettier-ignore
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
                    // prettier-ignore
                    for {} 1 {} {
                        i := add(i, 0x20)
                        // prettier-ignore
                        if gt(i, h) { break }
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
                    // prettier-ignore
                    for { let i := l } 1 {} {
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
