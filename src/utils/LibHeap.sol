// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for managing a min or max heap in storage.
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

    /// @dev Returns the root of the heap.
    /// If the heap is a min-heap, the returned value is the minimum.
    /// Otherwise, the heap is a max-heap, and the returned value is the maximum.
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
    function pushMin(Heap storage heap, uint256 value) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let pos := sload(heap.slot)
            sstore(heap.slot, add(pos, 1))
            mstore(0x00, heap.slot)
            let sOffset := keccak256(0x00, 0x20)

            for {} pos {} {
                let parentPos := shr(1, sub(pos, 1))
                let parent := sload(add(sOffset, parentPos))
                if iszero(lt(value, parent)) { break }
                sstore(add(sOffset, pos), parent)
                pos := parentPos
            }
            sstore(add(sOffset, pos), value)
        }
    }

    /// @dev Pops the minimum value from the min-heap.
    /// Reverts if the heap is empty.
    function popMin(Heap storage heap) internal returns (uint256 popped) {
        popped = _setMin(heap, 0, 0);
    }

    /// @dev Pops the minimum value, and pushes the new `value` onto the min-heap.
    /// Reverts if the heap is empty.
    function replaceMin(Heap storage heap, uint256 value) internal returns (uint256 popped) {
        _setMin(heap, value, 1);
    }

    /// @dev Pushes the `value` onto the min-heap, and pops the minimum value.
    function pushPopMin(Heap storage heap, uint256 value) internal returns (uint256 popped) {
        popped = _setMin(heap, value, 2);
    }

    /// @dev Pushes the `value` onto the min-heap, and pops the minimum value
    /// if the length of the heap exceeds `maxLength`.
    ///
    /// Reverts if `maxLength` is zero.
    ///
    /// - If `value` is not greater than the minimum value on the heap and queue is not full:
    ///   (`success` = true, `hasPopped` = false, `popped` = 0)
    /// - If `value` is not greater than the minimum value on the heap and queue is full:
    ///   (`success` = false, `hasPopped` = false, `popped` = 0)
    /// - If `value` is greater than the minimum value on the heap and queue is full:
    ///   (`success` = true, `hasPopped` = true, `popped` = <minimum value>)
    ///
    /// Useful for implementing a bounded priority queue.
    function enqueueMin(Heap storage heap, uint256 value, uint256 maxLength)
        internal
        returns (bool success, bool hasPopped, uint256 popped)
    {}

    /// @dev Pushes the `value` onto the max-heap.
    function pushMax(Heap storage heap, uint256 value) internal {}

    /// @dev Pops the maximum value from the max-heap.
    /// Reverts if the heap is empty.
    function popMax(Heap storage heap) internal returns (uint256 popped) {}

    /// @dev Pops the maximum value, and pushes the new `value` onto the max-heap.
    /// Reverts if the heap is empty.
    function replaceMax(Heap storage heap, uint256 value) internal returns (uint256 popped) {}

    /// @dev Pushes the `value` onto the max-heap, and pops the maximum value.
    function pushPopMax(Heap storage heap, uint256 value) internal returns (uint256 popped) {}

    /// @dev Pushes the `value` onto the max-heap, and pops the maximum value
    /// if the length of the heap exceeds `maxLength`.
    ///
    /// Reverts if `maxLength` is zero.
    ///
    /// - If `value` is not less than the maximum value on the heap and queue is not full:
    ///   (`success` = true, `hasPopped` = false, `popped` = 0)
    /// - If `value` is not less than the maximum value on the heap and queue is full:
    ///   (`success` = false, `hasPopped` = false, `popped` = 0)
    /// - If `value` is less than the maximum value on the heap and queue is full:
    ///   (`success` = true, `hasPopped` = true, `popped` = <maximum value>)
    ///
    /// Useful for implementing a bounded priority queue.
    function enqueueMax(Heap storage heap, uint256 value, uint256 maxLength)
        internal
        returns (bool success, bool hasPopped, uint256 popped)
    {}

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _setMin(Heap storage heap, uint256 value, uint256 mode)
        private
        returns (uint256 popped)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let n := sload(heap.slot)

            mstore(0x00, heap.slot)
            let sOffset := keccak256(0x00, 0x20)

            let needsSift := 0
            switch mode
            case 0 {
                // Pop.
                if iszero(n) {
                    // Revert with `HeapIsEmpty()` if heap is empty.
                    mstore(0x00, 0xa6ca772e)
                    revert(0x1c, 0x04)
                }
                // Decrement and update the length.
                n := sub(n, 1)
                sstore(heap.slot, n)
                // Set the `value` to the last item.
                value := sload(add(sOffset, n))
                popped := value
                if n {
                    popped := sload(sOffset)
                    needsSift := 1
                }
            }
            case 1 {
                // Replace.
                if iszero(n) {
                    // Revert with `HeapIsEmpty()` if heap is empty.
                    mstore(0x00, 0xa6ca772e)
                    revert(0x1c, 0x04)
                }
                popped := sload(sOffset)
                needsSift := 1
            }
            case 2 {
                // Push Pop.
                if n {
                    popped := sload(sOffset)
                    needsSift := 1
                    if lt(value, popped) {
                        popped := value
                        needsSift := 0
                    }
                }
            }

            if needsSift {
                let pos := 0

                for { let childPos := 1 } 1 {} {
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
                    if iszero(lt(childPos, n)) { break }
                }

                for {} pos {} {
                    let parentPos := shr(1, sub(pos, 1))
                    let parent := sload(add(sOffset, parentPos))
                    if iszero(lt(value, parent)) { break }
                    sstore(add(sOffset, pos), parent)
                    pos := parentPos
                }
                sstore(add(sOffset, pos), value)
            }
        }
    }
}
