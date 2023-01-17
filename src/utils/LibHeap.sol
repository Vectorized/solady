// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for managing a minimum heap in storage.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibHeap.sol)
library LibHeap {
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
        (,, popped) = _set(heap, 0, 0, 0);
    }

    /// @dev Pops the minimum value, and pushes the new `value` onto the min-heap.
    /// Reverts if the heap is empty.
    function replace(Heap storage heap, uint256 value) internal returns (uint256 popped) {
        (,, popped) = _set(heap, value, 0, 1);
    }

    /// @dev Pushes the `value` onto the min-heap, and pops the minimum value.
    function pushPop(Heap storage heap, uint256 value) internal returns (uint256 popped) {
        (,, popped) = _set(heap, value, 0, 2);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

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
            for {} 1 {
                mstore(0x00, 0xa6ca772e) // Store the function selector of `HeapIsEmpty()`.
                revert(0x1c, 0x04) // Revert with (offset, size).
            } {
                if eq(mode, 3) {
                    // Enqueue Min.
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
                    if lt(r, value) {
                        success := 1
                        hasPopped := 1
                        popped := r
                        childPos := 1
                        break
                    }
                    break
                }
                if eq(mode, 4) {
                    // Push.
                    // Increment and update the length.
                    pos := n
                    sstore(heap.slot, add(pos, 1))
                    childPos := add(childPos, childPos)
                    break
                }
                if eq(mode, 1) {
                    // Replace.
                    if iszero(n) { continue }
                    popped := sload(sOffset)
                    childPos := 1
                    break
                }
                if iszero(mode) {
                    // Pop.
                    if iszero(n) { continue }
                    // Decrement and update the length.
                    n := sub(n, 1)
                    sstore(heap.slot, n)
                    // Set the `value` to the last item.
                    value := sload(add(sOffset, n))
                    popped := value
                    if n {
                        popped := sload(sOffset)
                        childPos := 1
                    }
                    break
                }
                // Push pop.
                popped := value
                if n {
                    let r := sload(sOffset)
                    if lt(r, value) {
                        popped := r
                        childPos := 1
                    }
                }
                break
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
