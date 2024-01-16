// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for managing a min-heap in storage.
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

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OPERATIONS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Tips:
    // - To use as a max-heap, bitwise negate the values (e.g. `heap.push(~x)`).
    // - If use on tuples, pack the tuple values into a single integer.
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

    /// @dev Returns an array of the `k` smallest items in the heap, without modifying the heap.
    /// If the heap has less than `k` items, returns all items in the heap.
    function smallest(Heap storage heap, uint256 k) internal view returns (uint256[] memory a) {
        /// @solidity memory-safe-assembly
        assembly {
            let n := sload(heap.slot) // The number of items in the heap.
            if iszero(or(iszero(k), iszero(n))) {
                a := mload(0x40)
                mstore(0x00, heap.slot)
                let sOffset := keccak256(0x00, 0x20)
                let j := 0 // Number of items found.
                let p := add(add(a, 0x60), shl(5, k)) // Priority queue.
                let q := 0x40 // Priority queue length in bytes.
                codecopy(sub(p, q), codesize(), 0x80) // Zeroize the start of the priority queue.
                mstore(p, sload(sOffset)) // Store the root into the priority queue.
                for {} q {} {
                    j := add(1, j)
                    mstore(add(a, shl(5, j)), mload(p))
                    if eq(j, k) { break }
                    let childPos := add(shl(1, mload(add(0x20, p))), 1)
                    if iszero(lt(childPos, n)) {
                        p := add(0x40, p)
                        q := sub(q, 0x40)
                        continue
                    }
                    let v := sload(add(sOffset, childPos))
                    let i := add(p, 0x40)
                    for { mstore(add(p, q), not(0)) } lt(mload(i), v) { i := add(i, 0x40) } {
                        mstore(sub(i, 0x20), mload(add(0x20, i)))
                        mstore(sub(i, 0x40), mload(i))
                    }
                    mstore(sub(i, 0x20), childPos)
                    mstore(sub(i, 0x40), v)
                    childPos := add(1, childPos)
                    if iszero(lt(childPos, n)) { continue }
                    v := sload(add(sOffset, childPos))
                    for { i := add(p, sub(q, 0x40)) } gt(mload(i), v) { i := sub(i, 0x40) } {
                        mstore(add(0x60, i), mload(add(0x20, i)))
                        mstore(add(0x40, i), mload(i))
                    }
                    mstore(add(0x60, i), childPos)
                    mstore(add(0x40, i), v)
                    q := add(q, 0x40)
                }
                mstore(a, j) // Store the length.
                mstore(0x40, add(a, shl(5, add(1, j)))) // Allocate memory.
            }
        }
    }

    /// @dev Returns the number of items in the heap.
    function length(Heap storage heap) internal view returns (uint256) {
        return heap.data.length;
    }

    /// @dev Pushes the `value` onto the min-heap.
    function push(Heap storage heap, uint256 value) internal {
        _set(heap, value, 0, 4);
    }

    /// @dev Pops the minimum value from the min-heap.
    /// Reverts if the heap is empty.
    function pop(Heap storage heap) internal returns (uint256 popped) {
        (,, popped) = _set(heap, 0, 0, 3);
    }

    /// @dev Pushes the `value` onto the min-heap, and pops the minimum value.
    function pushPop(Heap storage heap, uint256 value) internal returns (uint256 popped) {
        (,, popped) = _set(heap, value, 0, 2);
    }

    /// @dev Pops the minimum value, and pushes the new `value` onto the min-heap.
    /// Reverts if the heap is empty.
    function replace(Heap storage heap, uint256 value) internal returns (uint256 popped) {
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
            // Compute the array storage slot offset.
            mstore(0x00, heap.slot)
            let sOffset := keccak256(0x00, 0x20)

            let pos := 0
            let childPos := not(0)
            // Operations are ordered from most likely usage to least likely usage.
            for {} 1 {
                mstore(0x00, 0xa6ca772e) // Store the function selector of `HeapIsEmpty()`.
                revert(0x1c, 0x04) // Revert with (offset, size).
            } {
                // `enqueue`.
                if iszero(mode) {
                    if iszero(maxLength) { continue }
                    if iszero(eq(n, maxLength)) {
                        // If queue is not full.
                        success := 1
                        // Increment and update the length.
                        pos := n
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
                // `replace`.
                if eq(mode, 1) {
                    if iszero(n) { continue }
                    popped := sload(sOffset)
                    childPos := 1
                    break
                }
                // `pushPop`.
                if eq(mode, 2) {
                    popped := value
                    if iszero(n) { break }
                    let r := sload(sOffset)
                    if iszero(lt(r, value)) { break }
                    popped := r
                    childPos := 1
                    break
                }
                // `pop`.
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
                // `push`.
                {
                    // Increment and update the length.
                    pos := n
                    sstore(heap.slot, add(pos, 1))
                    childPos := add(childPos, childPos)
                    break
                }
            }

            for {} lt(childPos, n) {} {
                let child := sload(add(sOffset, childPos))
                let rightPos := add(childPos, 1)
                let right := sload(add(sOffset, rightPos))
                if iszero(and(lt(rightPos, n), iszero(lt(child, right)))) {
                    right := child
                    rightPos := childPos
                }
                sstore(add(sOffset, pos), right)
                pos := rightPos
                childPos := add(shl(1, pos), 1)
            }

            for {} pos {} {
                let parentPos := shr(1, sub(pos, 1))
                let parent := sload(add(sOffset, parentPos))
                if iszero(lt(value, parent)) { break }
                sstore(add(sOffset, pos), parent)
                pos := parentPos
            }

            // If `childPos` is not `not(0)`.
            if add(childPos, 1) { sstore(add(sOffset, pos), value) }
        }
    }
}
