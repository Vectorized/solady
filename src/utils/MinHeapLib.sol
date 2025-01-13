// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for managing a min-heap in storage or memory.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/MinHeapLib.sol)
library MinHeapLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The heap is empty.
    error HeapIsEmpty();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev A heap in storage.
    struct Heap {
        uint256[] data;
    }

    /// @dev A heap in memory.
    struct MemHeap {
        uint256[] data;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OPERATIONS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Tips:
    // - To use as a max-heap, bitwise negate the input and output values (e.g. `heap.push(~x)`).
    // - To use on tuples, pack the tuple values into a single integer.
    // - To use on signed integers, convert the signed integers into
    //   their ordered unsigned counterparts via `uint256(x) + (1 << 255)`.

    /// @dev Returns the minimum value of the heap.
    /// Reverts if the heap is empty.
    function root(Heap storage heap) internal view returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(sload(heap.slot)) {
                mstore(0x00, 0xa6ca772e) // `HeapIsEmpty()`.
                revert(0x1c, 0x04)
            }
            mstore(0x00, heap.slot)
            result := sload(keccak256(0x00, 0x20))
        }
    }

    /// @dev Returns the minimum value of the heap.
    /// Reverts if the heap is empty.
    function root(MemHeap memory heap) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(heap)
            if iszero(mload(result)) {
                mstore(0x00, 0xa6ca772e) // `HeapIsEmpty()`.
                revert(0x1c, 0x04)
            }
            result := mload(add(0x20, result))
        }
    }

    /// @dev Reserves at least `minimum` slots of memory for the heap.
    /// Helps avoid reallocation if you already know the max size of the heap.
    function reserve(MemHeap memory heap, uint256 minimum) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            let w := not(0x1f)
            let prime := 204053801631428327883786711931463459222251954273621
            let cap := not(mload(add(mload(heap), w)))
            if gt(minimum, mul(iszero(mod(cap, prime)), div(cap, prime))) {
                let data := mload(heap)
                let n := mload(data)
                let newCap := and(add(minimum, 0x1f), w) // Round up to multiple of 32.
                mstore(mload(0x40), not(mul(newCap, prime)))
                let m := add(mload(0x40), 0x20)
                mstore(m, n) // Store the length.
                mstore(0x40, add(add(m, 0x20), shl(5, newCap))) // Allocate `heap.data` memory.
                mstore(heap, m) // Update `heap.data`.
                if n {
                    for { let i := shl(5, n) } 1 {} {
                        mstore(add(m, i), mload(add(data, i)))
                        i := add(i, w)
                        if iszero(i) { break }
                    }
                }
            }
        }
    }

    /// @dev Returns an array of the `k` smallest items in the heap,
    /// sorted in ascending order, without modifying the heap.
    /// If the heap has less than `k` items, all items in the heap will be returned.
    function smallest(Heap storage heap, uint256 k) internal view returns (uint256[] memory a) {
        /// @solidity memory-safe-assembly
        assembly {
            function pIndex(h_, p_) -> _i {
                _i := mload(add(0x20, add(h_, shl(6, p_))))
            }
            function pValue(h_, p_) -> _v {
                _v := mload(add(h_, shl(6, p_)))
            }
            function pSet(h_, p_, i_, v_) {
                mstore(add(h_, shl(6, p_)), v_)
                mstore(add(0x20, add(h_, shl(6, p_))), i_)
            }
            function pSiftdown(h_, p_, i_, v_) {
                for {} 1 {} {
                    let u_ := shr(1, sub(p_, 1))
                    if iszero(mul(p_, lt(v_, pValue(h_, u_)))) { break }
                    pSet(h_, p_, pIndex(h_, u_), pValue(h_, u_))
                    p_ := u_
                }
                pSet(h_, p_, i_, v_)
            }
            function pSiftup(h_, e_, i_, v_) {
                let p_ := 0
                for { let c_ := 1 } lt(c_, e_) { c_ := add(1, shl(1, p_)) } {
                    c_ := add(c_, gt(pValue(h_, c_), pValue(h_, add(c_, lt(add(c_, 1), e_)))))
                    pSet(h_, p_, pIndex(h_, c_), pValue(h_, c_))
                    p_ := c_
                }
                pSiftdown(h_, p_, i_, v_)
            }
            a := mload(0x40)
            mstore(0x00, heap.slot)
            let sOffset := keccak256(0x00, 0x20)
            let o := add(a, 0x20) // Offset into `a`.
            let n := sload(heap.slot) // The number of items in the heap.
            let m := xor(n, mul(xor(n, k), lt(k, n))) // `min(k, n)`.
            let h := add(o, shl(5, m)) // Priority queue.
            pSet(h, 0, 0, sload(sOffset)) // Store the root into the priority queue.
            for { let e := iszero(eq(o, h)) } e {} {
                mstore(o, pValue(h, 0))
                o := add(0x20, o)
                if eq(o, h) { break }
                let childPos := add(shl(1, pIndex(h, 0)), 1)
                if iszero(lt(childPos, n)) {
                    e := sub(e, 1)
                    pSiftup(h, e, pIndex(h, e), pValue(h, e))
                    continue
                }
                pSiftup(h, e, childPos, sload(add(sOffset, childPos)))
                childPos := add(1, childPos)
                if iszero(eq(childPos, n)) {
                    pSiftdown(h, e, childPos, sload(add(sOffset, childPos)))
                    e := add(e, 1)
                }
            }
            mstore(a, shr(5, sub(o, add(a, 0x20)))) // Store the length.
            mstore(0x40, o) // Allocate memory.
        }
    }

    /// @dev Returns an array of the `k` smallest items in the heap,
    /// sorted in ascending order, without modifying the heap.
    /// If the heap has less than `k` items, all items in the heap will be returned.
    function smallest(MemHeap memory heap, uint256 k) internal pure returns (uint256[] memory a) {
        /// @solidity memory-safe-assembly
        assembly {
            function pIndex(h_, p_) -> _i {
                _i := mload(add(0x20, add(h_, shl(6, p_))))
            }
            function pValue(h_, p_) -> _v {
                _v := mload(add(h_, shl(6, p_)))
            }
            function pSet(h_, p_, i_, v_) {
                mstore(add(h_, shl(6, p_)), v_)
                mstore(add(0x20, add(h_, shl(6, p_))), i_)
            }
            function pSiftdown(h_, p_, i_, v_) {
                for {} 1 {} {
                    let u_ := shr(1, sub(p_, 1))
                    if iszero(mul(p_, lt(v_, pValue(h_, u_)))) { break }
                    pSet(h_, p_, pIndex(h_, u_), pValue(h_, u_))
                    p_ := u_
                }
                pSet(h_, p_, i_, v_)
            }
            function pSiftup(h_, e_, i_, v_) {
                let p_ := 0
                for { let c_ := 1 } lt(c_, e_) { c_ := add(1, shl(1, p_)) } {
                    c_ := add(c_, gt(pValue(h_, c_), pValue(h_, add(c_, lt(add(c_, 1), e_)))))
                    pSet(h_, p_, pIndex(h_, c_), pValue(h_, c_))
                    p_ := c_
                }
                pSiftdown(h_, p_, i_, v_)
            }
            a := mload(0x40)
            let sOffset := add(mload(heap), 0x20)
            let o := add(a, 0x20) // Offset into `a`.
            let n := mload(mload(heap)) // The number of items in the heap.
            let m := xor(n, mul(xor(n, k), lt(k, n))) // `min(k, n)`.
            let h := add(o, shl(5, m)) // Priority queue.
            pSet(h, 0, 0, mload(sOffset)) // Store the root into the priority queue.
            for { let e := iszero(eq(o, h)) } e {} {
                mstore(o, pValue(h, 0))
                o := add(0x20, o)
                if eq(o, h) { break }
                let childPos := add(shl(1, pIndex(h, 0)), 1)
                if iszero(lt(childPos, n)) {
                    e := sub(e, 1)
                    pSiftup(h, e, pIndex(h, e), pValue(h, e))
                    continue
                }
                pSiftup(h, e, childPos, mload(add(sOffset, shl(5, childPos))))
                childPos := add(1, childPos)
                if iszero(eq(childPos, n)) {
                    pSiftdown(h, e, childPos, mload(add(sOffset, shl(5, childPos))))
                    e := add(e, 1)
                }
            }
            mstore(a, shr(5, sub(o, add(a, 0x20)))) // Store the length.
            mstore(0x40, o) // Allocate memory.
        }
    }

    /// @dev Returns the number of items in the heap.
    function length(Heap storage heap) internal view returns (uint256) {
        return heap.data.length;
    }

    /// @dev Returns the number of items in the heap.
    function length(MemHeap memory heap) internal pure returns (uint256) {
        return heap.data.length;
    }

    /// @dev Pushes the `value` onto the min-heap.
    function push(Heap storage heap, uint256 value) internal {
        _set(heap, value, 0, 3);
    }

    /// @dev Pushes the `value` onto the min-heap.
    function push(MemHeap memory heap, uint256 value) internal pure {
        _set(heap, value, 0, 3);
    }

    /// @dev Pops the minimum value from the min-heap.
    /// Reverts if the heap is empty.
    function pop(Heap storage heap) internal returns (uint256 popped) {
        (, popped) = _set(heap, 0, 0, 2);
    }

    /// @dev Pops the minimum value from the min-heap.
    /// Reverts if the heap is empty.
    function pop(MemHeap memory heap) internal pure returns (uint256 popped) {
        (, popped) = _set(heap, 0, 0, 2);
    }

    /// @dev Pushes the `value` onto the min-heap, and pops the minimum value.
    function pushPop(Heap storage heap, uint256 value) internal returns (uint256 popped) {
        (, popped) = _set(heap, value, 0, 4);
    }

    /// @dev Pushes the `value` onto the min-heap, and pops the minimum value.
    function pushPop(MemHeap memory heap, uint256 value) internal pure returns (uint256 popped) {
        (, popped) = _set(heap, value, 0, 4);
    }

    /// @dev Pops the minimum value, and pushes the new `value` onto the min-heap.
    /// Reverts if the heap is empty.
    function replace(Heap storage heap, uint256 value) internal returns (uint256 popped) {
        (, popped) = _set(heap, value, 0, 1);
    }

    /// @dev Pops the minimum value, and pushes the new `value` onto the min-heap.
    /// Reverts if the heap is empty.
    function replace(MemHeap memory heap, uint256 value) internal pure returns (uint256 popped) {
        (, popped) = _set(heap, value, 0, 1);
    }

    /// @dev Pushes the `value` onto the min-heap, and pops the minimum value
    /// if the length of the heap exceeds `maxLength`.
    ///
    /// Reverts if `maxLength` is zero.
    ///
    /// - If the queue is not full:
    ///   (`success` = true, `hasPopped` = false, `popped` = 0)
    /// - If the queue is full, and `value` is not greater than the minimum value:
    ///   (`success` = false, `hasPopped` = false, `popped` = 0)
    /// - If the queue is full, and `value` is greater than the minimum value:
    ///   (`success` = true, `hasPopped` = true, `popped` = <minimum value>)
    ///
    /// Useful for implementing a bounded priority queue.
    ///
    /// It is technically possible for the heap size to exceed `maxLength`
    /// if `enqueue` has been previously called with a larger `maxLength`.
    /// In such a case, the heap will be treated exactly as if it is full,
    /// conditionally popping the minimum value if `value` is greater than it.
    ///
    /// Under normal usage, which keeps `maxLength` constant throughout
    /// the lifetime of a heap, this out-of-spec edge case will not be triggered.
    function enqueue(Heap storage heap, uint256 value, uint256 maxLength)
        internal
        returns (bool success, bool hasPopped, uint256 popped)
    {
        (value, popped) = _set(heap, value, maxLength, 0);
        /// @solidity memory-safe-assembly
        assembly {
            hasPopped := eq(3, value)
            success := value
        }
    }

    /// @dev Pushes the `value` onto the min-heap, and pops the minimum value
    /// if the length of the heap exceeds `maxLength`.
    ///
    /// Reverts if `maxLength` is zero.
    ///
    /// - If the queue is not full:
    ///   (`success` = true, `hasPopped` = false, `popped` = 0)
    /// - If the queue is full, and `value` is not greater than the minimum value:
    ///   (`success` = false, `hasPopped` = false, `popped` = 0)
    /// - If the queue is full, and `value` is greater than the minimum value:
    ///   (`success` = true, `hasPopped` = true, `popped` = <minimum value>)
    ///
    /// Useful for implementing a bounded priority queue.
    function enqueue(MemHeap memory heap, uint256 value, uint256 maxLength)
        internal
        pure
        returns (bool success, bool hasPopped, uint256 popped)
    {
        (value, popped) = _set(heap, value, maxLength, 0);
        /// @solidity memory-safe-assembly
        assembly {
            hasPopped := eq(3, value)
            success := value
        }
    }

    /// @dev Increments the free memory pointer by a word and fills the word with 0.
    /// This is if you want to take extra precaution that the memory word slot before
    /// the `data` array in `MemHeap` doesn't contain a non-zero multiple of prime
    /// to masquerade as a prime-checksummed capacity.
    /// If you are not directly assigning some array to `data`,
    /// you don't have to worry about it.
    function bumpFreeMemoryPointer() internal pure {
        uint256 zero;
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, zero)
            mstore(0x40, add(m, 0x20))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Helper function for heap operations.
    /// Designed for code conciseness, bytecode compactness, and decent performance.
    function _set(Heap storage heap, uint256 value, uint256 maxLength, uint256 mode)
        private
        returns (uint256 status, uint256 popped)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let n := sload(heap.slot)
            mstore(0x00, heap.slot)
            let sOffset := keccak256(0x00, 0x20) // Array storage slot offset.
            let pos := 0
            let childPos := not(0)
            // Operations are ordered from most likely usage to least likely usage.
            for {} 1 {
                mstore(0x00, 0xa6ca772e) // `HeapIsEmpty()`.
                revert(0x1c, 0x04)
            } {
                // Mode: `enqueue`.
                if iszero(mode) {
                    if iszero(maxLength) { continue }
                    // If queue is full.
                    if iszero(lt(n, maxLength)) {
                        let r := sload(sOffset)
                        if iszero(lt(r, value)) { break }
                        status := 3
                        childPos := 1
                        popped := r
                        break
                    }
                    status := 1
                    pos := n
                    // Increment and update the length.
                    sstore(heap.slot, add(pos, 1))
                    childPos := sOffset
                    break
                }
                if iszero(gt(mode, 2)) {
                    if iszero(n) { continue }
                    // Mode: `pop`.
                    if eq(mode, 2) {
                        // Decrement and update the length.
                        n := sub(n, 1)
                        sstore(heap.slot, n)
                        // Set the `value` to the last item.
                        value := sload(add(sOffset, n))
                        popped := value
                        if iszero(n) { break }
                    }
                    // Mode: `replace`.
                    popped := sload(sOffset)
                    childPos := 1
                    break
                }
                // Mode: `push`.
                if eq(mode, 3) {
                    // Increment and update the length.
                    pos := n
                    sstore(heap.slot, add(pos, 1))
                    // `sOffset` is used as a value that is `>= n` and `< not(0)`.
                    childPos := sOffset
                    break
                }
                // Mode: `pushPop`.
                popped := value
                if iszero(n) { break }
                let r := sload(sOffset)
                if iszero(lt(r, value)) { break }
                popped := r
                childPos := 1
                break
            }
            // Siftup.
            for {} lt(childPos, n) {} {
                let child := sload(add(sOffset, childPos))
                let rightPos := add(childPos, 1)
                let right := sload(add(sOffset, rightPos))
                if iszero(gt(lt(rightPos, n), lt(child, right))) {
                    right := child
                    rightPos := childPos
                }
                sstore(add(sOffset, pos), right)
                pos := rightPos
                childPos := add(shl(1, pos), 1)
            }
            // Siftdown.
            for {} pos {} {
                let parentPos := shr(1, sub(pos, 1))
                let parent := sload(add(sOffset, parentPos))
                if iszero(lt(value, parent)) { break }
                sstore(add(sOffset, pos), parent)
                pos := parentPos
            }
            // If `childPos` has been changed from `not(0)`.
            if add(childPos, 1) { sstore(add(sOffset, pos), value) }
        }
    }

    /// @dev Helper function for heap operations.
    /// Designed for code conciseness, bytecode compactness, and decent performance.
    function _set(MemHeap memory heap, uint256 value, uint256 maxLength, uint256 mode)
        private
        pure
        returns (uint256 status, uint256 popped)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let data := mload(heap)
            let n := mload(data)
            // Allocation / reallocation.
            for {
                let cap := not(mload(sub(data, 0x20)))
                let prime := 204053801631428327883786711931463459222251954273621
                cap := mul(iszero(mod(cap, prime)), div(cap, prime))
            } iszero(lt(n, cap)) {} {
                let newCap := add(add(cap, cap), shl(5, iszero(cap)))
                if iszero(or(cap, iszero(n))) {
                    for { cap := n } iszero(gt(newCap, n)) {} { newCap := add(newCap, newCap) }
                }
                mstore(mload(0x40), not(mul(newCap, prime))) // Update `heap.capacity`.
                let m := add(mload(0x40), 0x20)
                mstore(m, n) // Store the length.
                mstore(0x40, add(add(m, 0x20), shl(5, newCap))) // Allocate `heap.data` memory.
                if cap {
                    let w := not(0x1f)
                    for { let i := shl(5, cap) } 1 {} {
                        mstore(add(m, i), mload(add(data, i)))
                        i := add(i, w)
                        if iszero(i) { break }
                    }
                }
                mstore(heap, m) // Update `heap.data`.
                data := m
                break
            }
            let sOffset := add(data, 0x20) // Array memory offset.
            let pos := 0
            let childPos := not(0)
            // Operations are ordered from most likely usage to least likely usage.
            for {} 1 {
                mstore(0x00, 0xa6ca772e) // `HeapIsEmpty()`.
                revert(0x1c, 0x04)
            } {
                // Mode: `enqueue`.
                if iszero(mode) {
                    if iszero(maxLength) { continue }
                    // If the queue is full.
                    if iszero(lt(n, maxLength)) {
                        if iszero(lt(mload(sOffset), value)) { break }
                        status := 3
                        childPos := 1
                        popped := mload(sOffset)
                        break
                    }
                    status := 1
                    pos := n
                    // Increment and update the length.
                    mstore(data, add(pos, 1))
                    childPos := 0xff0000000000000000
                    break
                }
                if iszero(gt(mode, 2)) {
                    if iszero(n) { continue }
                    // Mode: `pop`.
                    if eq(mode, 2) {
                        // Decrement and update the length.
                        n := sub(n, 1)
                        mstore(data, n)
                        // Set the `value` to the last item.
                        value := mload(add(sOffset, shl(5, n)))
                        popped := value
                        if iszero(n) { break }
                    }
                    // Mode: `replace`.
                    popped := mload(sOffset)
                    childPos := 1
                    break
                }
                // Mode: `push`.
                if eq(mode, 3) {
                    // Increment and update the length.
                    pos := n
                    mstore(data, add(pos, 1))
                    childPos := 0xff0000000000000000
                    break
                }
                // Mode: `pushPop`.
                if iszero(mul(n, lt(mload(sOffset), value))) {
                    popped := value
                    break
                }
                popped := mload(sOffset)
                childPos := 1
                break
            }
            // Siftup.
            for {} lt(childPos, n) {} {
                let child := mload(add(sOffset, shl(5, childPos)))
                let rightPos := add(childPos, 1)
                let right := mload(add(sOffset, shl(5, rightPos)))
                if iszero(gt(lt(rightPos, n), lt(child, right))) {
                    mstore(add(sOffset, shl(5, pos)), child)
                    pos := childPos
                    childPos := add(shl(1, pos), 1)
                    continue
                }
                mstore(add(sOffset, shl(5, pos)), right)
                pos := rightPos
                childPos := add(shl(1, pos), 1)
            }
            // Siftdown.
            for {} pos {} {
                let parentPos := shr(1, sub(pos, 1))
                let parent := mload(add(sOffset, shl(5, parentPos)))
                if iszero(lt(value, parent)) { break }
                mstore(add(sOffset, shl(5, pos)), parent)
                pos := parentPos
            }
            // If `childPos` has been changed from `not(0)`.
            if iszero(shr(128, childPos)) { mstore(add(sOffset, shl(5, pos)), value) }
        }
    }
}
