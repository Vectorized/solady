// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev Closely packs `items`, similar to `abi.encodePacked`. Any item larger than `chunkSize`
/// bytes will be truncated.
function pack(uint256[] memory items, uint256 chunkSize) pure returns (bytes memory newList) {
    uint256 shift;
    unchecked {
        shift = 256 - (chunkSize << 3);
    }

    /// @solidity memory-safe-assembly
    assembly {
        // Start `newList` at the free memory pointer
        newList := mload(0x40)

        let newPtr := add(newList, 0x20)
        let arrPtr := add(items, 0x20)
        let arrMemEnd := add(arrPtr, shl(5, mload(items)))

        // prettier-ignore
        for {} lt(arrPtr, arrMemEnd) { arrPtr := add(arrPtr, 0x20) } {
            // Load 32 byte chunk from `items`, left shifting by N bits so that items get
            // packed together
            let x := shl(shift, mload(arrPtr))

            // Copy to `newList`
            mstore(newPtr, x)
            newPtr := add(newPtr, chunkSize)
        }

        // Set `newList` length
        mstore(newList, sub(sub(newPtr, newList), 0x20))
        // Update free memory pointer
        mstore(0x40, newPtr)
    }
}

/// @notice Library for handling packed arrays.
/// @dev `chunkSize` must be <= 32 bytes and should not change for the lifetime of a packed
/// array.
library LibPackedArray {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Attempted to index into the array beyond its length
    error IndexOutOfBounds();

    /// @dev No matching item found within the array
    error ItemNotFound();

    /// @dev Unable to remove item because it is not present in the array
    error RemovalFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OPERATIONS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Pushes `item` onto `oldList`, a packed array where each element spans `chunkSize`
    /// bytes.
    function push(bytes memory oldList, uint256 item, uint256 chunkSize)
        internal
        view
        returns (bytes memory newList)
    {
        unchecked {
            item <<= 256 - (chunkSize << 3);
        }

        /// @solidity memory-safe-assembly
        assembly {
            // Start `newList` at the free memory pointer.
            newList := mload(0x40)

            let newPtr := add(newList, 0x20)
            let length := mload(oldList)

            // Use identity precompile to copy `oldList` memory to `newList`.
            if iszero(staticcall(gas(), 0x04, add(oldList, 0x20), length, newPtr, length)) {
                revert(0, 0)
            }

            // Write new `item` at the end.
            newPtr := add(newPtr, length)
            mstore(newPtr, item)

            // Set `newList` length.
            mstore(newList, add(length, chunkSize))
            // Update free memory pointer.
            mstore(0x40, add(newPtr, chunkSize))
        }
    }

    /// @dev Pushes all `items` onto `oldList`, a packed array where each element spans `chunkSize`
    /// bytes.
    function push(bytes memory oldList, uint256[] memory items, uint256 chunkSize)
        internal
        view
        returns (bytes memory newList)
    {
        uint256 shift;
        unchecked {
            shift = 256 - (chunkSize << 3);
        }

        /// @solidity memory-safe-assembly
        assembly {
            // Start `newList` at the free memory pointer.
            newList := mload(0x40)

            let newPtr := add(newList, 0x20)
            let length := mload(oldList)

            // Use identity precompile to copy `oldList` memory to `newList`.
            if iszero(staticcall(gas(), 0x04, add(oldList, 0x20), length, newPtr, length)) {
                revert(0, 0)
            }

            // Write new `items` at the end.
            newPtr := add(newPtr, length)
            let arrPtr := add(items, 0x20)
            let arrMemEnd := add(arrPtr, shl(5, mload(items)))

            for {} lt(arrPtr, arrMemEnd) { arrPtr := add(arrPtr, 0x20) } {
                // Load 32 byte chunk from `items`, left shifting by N bits so that items get
                // packed together.
                let x := shl(shift, mload(arrPtr))

                // Copy to `newList`.
                mstore(newPtr, x)
                newPtr := add(newPtr, chunkSize)
            }

            // Set `newList` length.
            mstore(newList, sub(sub(newPtr, newList), 0x20))
            // Update free memory pointer.
            mstore(0x40, newPtr)
        }
    }

    /// @dev Gets `list[index]`, where `list` is a packed array with elements spanning `chunkSize`
    /// bytes.
    function at(bytes memory list, uint256 index, uint256 chunkSize)
        internal
        pure
        returns (uint256 result)
    {
        uint256 shift;
        unchecked {
            shift = 256 - (chunkSize << 3);
        }

        /// @solidity memory-safe-assembly
        assembly {
            let start := mul(index, chunkSize)

            {
                let length := mload(list)
                if iszero(lt(start, length)) {
                    // Store the function selector of `IndexOutOfBounds()`.
                    mstore(0x00, 0x4e23d035)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
            }

            let ptr := add(add(list, 0x20), start)
            // Load 32 bytes from `list`. Since chunks may overlap, `shr` to isolate the desired
            // one.
            result := shr(shift, mload(ptr))
        }
    }

    /// @dev Removes all occurrences of `item` from `oldList`, a packed array where each element
    /// spans `chunkSize` bytes.
    function filter(bytes memory oldList, uint256 item, uint256 chunkSize)
        internal
        pure
        returns (bytes memory newList)
    {
        uint256 mask = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        unchecked {
            uint256 shift = 256 - (chunkSize << 3);
            mask <<= shift;
            item <<= shift;
        }

        /// @solidity memory-safe-assembly
        assembly {
            // Start `newList` at the free memory pointer.
            newList := mload(0x40)

            let newPtr := add(newList, 0x20)
            let oldPtr := add(oldList, 0x20)
            let oldMemEnd := add(oldPtr, mload(oldList))

            for {} lt(oldPtr, oldMemEnd) { oldPtr := add(oldPtr, chunkSize) } {
                // Load 32 byte chunk from `oldList`, masking out the last N bits since items are
                // packed together.
                let x := and(mload(oldPtr), mask)
                // Skip it if it matches the `item` being deleted.
                if eq(x, item) { continue }

                // Copy to `newList`
                mstore(newPtr, x)
                newPtr := add(newPtr, chunkSize)
            }

            // Set `newList` length
            mstore(newList, sub(sub(newPtr, newList), 0x20))
            // Update free memory pointer
            mstore(0x40, newPtr)
        }
    }

    /// @dev Returns the first element of `list` where `(element & mask) == item`, if such exists,
    /// otherwise reverts. Each element of `list` must span `chunkSize` bytes.
    function find(bytes memory list, uint256 item, uint256 mask, uint256 chunkSize)
        internal
        pure
        returns (uint256 result)
    {
        uint256 shift;
        unchecked {
            shift = 256 - (chunkSize << 3);
        }

        /// @solidity memory-safe-assembly
        assembly {
            let ptr := add(list, 0x20)
            let memEnd := add(ptr, mload(list))

            for {} lt(ptr, memEnd) { ptr := add(ptr, chunkSize) } {
                // Load 32 bytes from `list`. Since chunks may overlap, `shr` to isolate the
                // current one.
                result := shr(shift, mload(ptr))
                // If masked `result` matches `item`, we're done.
                if eq(and(result, mask), item) {
                    // Reuse `ptr` as a flag to indicate that `item` was found.
                    ptr := 0
                    break
                }
            }

            if ptr {
                // Store the function selector of `ItemNotFound()`.
                mstore(0x00, 0xd3ed043d)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Checks whether `item` is present in `list`, a packed array where each element spans
    /// `chunkSize` bytes.
    function includes(bytes memory list, uint256 item, uint256 chunkSize)
        internal
        pure
        returns (bool result)
    {
        uint256 shift;
        unchecked {
            shift = 256 - (chunkSize << 3);
        }

        /// @solidity memory-safe-assembly
        assembly {
            let ptr := add(list, 0x20)
            let memEnd := add(ptr, mload(list))

            for {} lt(ptr, memEnd) { ptr := add(ptr, chunkSize) } {
                // Load 32 bytes from `list`. Since chunks may overlap, `shr` to isolate the
                // current one.
                let x := shr(shift, mload(ptr))
                // If it matches `item`, return true.
                if eq(x, item) {
                    result := 1
                    break
                }
            }
        }
    }

    /// @dev Removes all occurrences of `item` from `oldList`, a packed array where each element
    /// spans `chunkSize` bytes. Reverts if nothing was removed.
    function remove(bytes memory oldList, uint256 item, uint256 chunkSize)
        internal
        pure
        returns (bytes memory newList)
    {
        newList = filter(oldList, item, chunkSize);
        if (newList.length == oldList.length) revert RemovalFailed();
    }

    /// @dev Unpacks `list` into a standard Solidity memory array. Each element of `list` must span
    /// `chunkSize` bytes.
    function unpack(bytes memory list, uint256 chunkSize)
        internal
        pure
        returns (uint256[] memory items)
    {
        uint256 shift;
        unchecked {
            shift = 256 - (chunkSize << 3);
        }

        /// @solidity memory-safe-assembly
        assembly {
            // Start `items` at the free memory pointer.
            items := mload(0x40)

            let arrPtr := add(items, 0x20)
            let oldPtr := add(list, 0x20)
            let oldMemEnd := add(oldPtr, mload(list))

            for {} lt(oldPtr, oldMemEnd) { oldPtr := add(oldPtr, chunkSize) } {
                // Load 32 bytes from `list`. Since chunks may overlap, `shr` to isolate the
                // current one.
                let x := shr(shift, mload(oldPtr))

                // Copy to `items`.
                mstore(arrPtr, x)
                arrPtr := add(arrPtr, 0x20)
            }

            // Set `items` length.
            mstore(items, shr(5, sub(sub(arrPtr, items), 0x20)))
            // Update free memory pointer.
            mstore(0x40, arrPtr)
        }
    }
}
