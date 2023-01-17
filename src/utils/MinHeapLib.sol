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
    // - To use as a max-map, negate the values.
    // - If use on tuples, pack the tuple values into a single integer.
    // - To use on signed integers, convert the signed integers into
    //   their ordered unsigned counterparts via `uint256(x) + (1 << 255)`.

    /// @dev Returns the minimum value of the heap.
    /// Reverts if the heap is empty.
    function root(Heap storage heap) internal view returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(sload(heap.slot)) {
                mstore(0x00, 0xa6ca772e) // Store the function selector of `HeapIsEmpty()`.
                revert(0x1c, 0x04) // Revert with (offset, size).
            }
            mstore(0x00, heap.slot)
            result := sload(keccak256(0x00, 0x20))
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
