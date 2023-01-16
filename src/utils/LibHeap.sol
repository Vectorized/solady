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
    function root(Heap storage heap) internal view returns (uint256 result) {}

    /// @dev Returns the number of items in the heap.
    function length(Heap storage heap) internal view returns (uint256 result) {}

    /// @dev Pushes the value onto the min-heap.
    function pushMin(Heap storage heap, uint256 value) internal {}

    /// @dev Pushes the value onto the min-heap, and pops the minimum value.
    function pushPopMin(Heap storage heap, uint256 value) internal returns (uint256 popped) {}

    /// @dev Pushes the value onto the min-heap, and pops the minimum value
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

    /// @dev Pops the minimum value from the min-heap.
    /// Reverts if the heap is empty.
    function popMin(Heap storage heap) internal returns (uint256 popped) {}

    /// @dev Pops the minimum value, and pushes the new `value` onto the min-heap.
    /// Reverts if the heap is empty.
    function replaceMin(Heap storage heap, uint256 value) internal returns (uint256 popped) {}

    /// @dev Pushes the value onto the max-heap.
    function pushMax(Heap storage heap, uint256 value) internal {}

    /// @dev Pushes the value onto the max-heap, and pops the maximum value.
    function pushPopMax(Heap storage heap, uint256 value) internal returns (uint256 popped) {}

    /// @dev Pushes the value onto the max-heap, and pops the maximum value
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

    /// @dev Pops the maximum value from the max-heap.
    /// Reverts if the heap is empty.
    function popMax(Heap storage heap) internal returns (uint256 popped) {}

    /// @dev Pops the maximum value, and pushes the new `value` onto the max-heap.
    /// Reverts if the heap is empty.
    function replaceMax(Heap storage heap, uint256 value) internal returns (uint256 popped) {}

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // See https://github.com/python/cpython/blob/3.11/Lib/heapq.py

    function _siftupMin(Heap storage heap, uint256 pos) private {}

    function _siftdownMin(Heap storage heap, uint256 startPos, uint256 pos) private {}

    function _siftupMax(Heap storage heap, uint256 pos) private {}

    function _siftdownMax(Heap storage heap, uint256 startPos, uint256 pos) private {}
}
