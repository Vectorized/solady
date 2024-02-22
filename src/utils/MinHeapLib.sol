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
        uint256 capacity;
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
            if iszero(mload(mload(heap))) {
                mstore(0x00, 0xa6ca772e) // `HeapIsEmpty()`.
                revert(0x1c, 0x04)
            }
            result := mload(add(0x20, mload(heap)))
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
        _set(heap, value, 0, 4);
    }

    /// @dev Pushes the `value` onto the min-heap.
    function push(MemHeap memory heap, uint256 value) internal pure {
        _set(heap, value, 0, 4);
    }

    /// @dev Pops the minimum value from the min-heap.
    /// Reverts if the heap is empty.
    function pop(Heap storage heap) internal returns (uint256 popped) {
        (,, popped) = _set(heap, 0, 0, 3);
    }

    /// @dev Pops the minimum value from the min-heap.
    /// Reverts if the heap is empty.
    function pop(MemHeap memory heap) internal pure returns (uint256 popped) {
        (,, popped) = _set(heap, 0, 0, 3);
    }

    /// @dev Pushes the `value` onto the min-heap, and pops the minimum value.
    function pushPop(Heap storage heap, uint256 value) internal returns (uint256 popped) {
        (,, popped) = _set(heap, value, 0, 2);
    }

    /// @dev Pushes the `value` onto the min-heap, and pops the minimum value.
    function pushPop(MemHeap memory heap, uint256 value) internal pure returns (uint256 popped) {
        (,, popped) = _set(heap, value, 0, 2);
    }

    /// @dev Pops the minimum value, and pushes the new `value` onto the min-heap.
    /// Reverts if the heap is empty.
    function replace(Heap storage heap, uint256 value) internal returns (uint256 popped) {
        (,, popped) = _set(heap, value, 0, 1);
    }

    /// @dev Pops the minimum value, and pushes the new `value` onto the min-heap.
    /// Reverts if the heap is empty.
    function replace(MemHeap memory heap, uint256 value) internal pure returns (uint256 popped) {
        (,, popped) = _set(heap, value, 0, 1);
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
    function enqueue(Heap storage heap, uint256 value, uint256 maxLength)
        internal
        returns (bool success, bool hasPopped, uint256 popped)
    {
        (success, hasPopped, popped) = _set(heap, value, maxLength, 0);
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
        (success, hasPopped, popped) = _set(heap, value, maxLength, 0);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Helper function for heap operations.
    /// Designed for code conciseness, bytecode compactness, and decent performance.
    function _set(Heap storage heap, uint256 value, uint256 maxLength, uint256 mode)
        private
        returns (bool success, bool hasPopped, uint256 popped)
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
                    // If queue is not full.
                    if iszero(eq(n, maxLength)) {
                        success := 1
                        pos := n
                        // Increment and update the length.
                        sstore(heap.slot, add(pos, 1))
                        childPos := add(childPos, childPos)
                        break
                    }
                    let r := sload(sOffset)
                    if iszero(lt(r, value)) { break }
                    success := 1
                    hasPopped := 1
                    childPos := 1
                    popped := r
                    break
                }
                // Mode: `replace`.
                if eq(mode, 1) {
                    if iszero(n) { continue }
                    popped := sload(sOffset)
                    childPos := 1
                    break
                }
                // Mode: `pushPop`.
                if eq(mode, 2) {
                    popped := value
                    if iszero(n) { break }
                    let r := sload(sOffset)
                    if iszero(lt(r, value)) { break }
                    popped := r
                    childPos := 1
                    break
                }
                // Mode: `pop`.
                if eq(mode, 3) {
                    if iszero(n) { continue }
                    // Decrement and update the length.
                    n := sub(n, 1)
                    sstore(heap.slot, n)
                    // Set the `value` to the last item.
                    value := sload(add(sOffset, n))
                    popped := value
                    if iszero(n) { break }
                    popped := sload(sOffset)
                    childPos := 1
                    break
                }
                // Mode: `push`.
                // Increment and update the length.
                pos := n
                sstore(heap.slot, add(pos, 1))
                childPos := add(childPos, childPos)
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
        returns (bool success, bool hasPopped, uint256 popped)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(mload(heap))
            // Allocation / re-allocation logic.
            for {} iszero(lt(n, mload(add(heap, 0x20)))) {} {
                let oldData := mload(heap) // The old `heap.data`.
                let cap := mload(add(heap, 0x20))
                let fresh := iszero(cap)
                let newCap := or(shl(5, fresh), mul(shl(1, cap), iszero(fresh)))
                let m := mload(0x40) // Grab the free memory pointer.
                mstore(heap, m) // Update `heap.data`.
                mstore(m, n) // Store the length.
                mstore(add(heap, 0x20), newCap) // Update `heap.capacity`.
                mstore(0x40, add(add(m, 0x20), shl(5, newCap))) // Allocate `heap.data` memory.
                codecopy(add(m, 0x20), codesize(), shl(5, newCap)) // Zeroize the `heap.data` memory.
                if iszero(fresh) {
                    for { let i := shl(5, cap) } 1 {} {
                        mstore(add(m, i), mload(add(oldData, i)))
                        i := sub(i, 0x20)
                        if iszero(i) { break }
                    }
                }
                break
            }
            let sOffset := add(mload(heap), 0x20) // Array storage slot offset.
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
                    // If queue is not full.
                    if iszero(eq(n, maxLength)) {
                        success := 1
                        pos := n
                        // Increment and update the length.
                        mstore(mload(heap), add(pos, 1))
                        childPos := add(childPos, childPos)
                        break
                    }
                    let r := mload(sOffset)
                    if iszero(lt(r, value)) { break }
                    success := 1
                    hasPopped := 1
                    childPos := 1
                    popped := r
                    break
                }
                // Mode: `replace`.
                if eq(mode, 1) {
                    if iszero(n) { continue }
                    popped := mload(sOffset)
                    childPos := 1
                    break
                }
                // Mode: `pushPop`.
                if eq(mode, 2) {
                    popped := value
                    if iszero(n) { break }
                    let r := mload(sOffset)
                    if iszero(lt(r, value)) { break }
                    popped := r
                    childPos := 1
                    break
                }
                // Mode: `pop`.
                if eq(mode, 3) {
                    if iszero(n) { continue }
                    // Decrement and update the length.
                    n := sub(n, 1)
                    mstore(mload(heap), n)
                    // Set the `value` to the last item.
                    value := mload(add(sOffset, shl(5, n)))
                    popped := value
                    if iszero(n) { break }
                    popped := mload(sOffset)
                    childPos := 1
                    break
                }
                // Mode: `push`.
                // Increment and update the length.
                pos := n
                mstore(mload(heap), add(pos, 1))
                childPos := add(childPos, childPos)
                break
            }
            // Siftup.
            for {} lt(childPos, n) {} {
                let child := mload(add(sOffset, shl(5, childPos)))
                let rightPos := add(childPos, 1)
                let right := mload(add(sOffset, shl(5, rightPos)))
                if iszero(gt(lt(rightPos, n), lt(child, right))) {
                    right := child
                    rightPos := childPos
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
            if add(childPos, 1) { mstore(add(sOffset, shl(5, pos)), value) }
        }
    }
}
