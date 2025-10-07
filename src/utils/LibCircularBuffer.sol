// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Gas-lean circular buffer of 32-byte words in storage.
/// @dev Meta layout in one word: [ cap:64 | size:64 | head:128 ].
///      Capacity must be a power of two; writes overwrite oldest when full.
library LibCircularBuffer {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    struct Buffer {
        uint256 _meta; // [ cap:64 | size:64 | head:128 ]
        bytes32[] _data; // slot stores length; elements at keccak256(slot) + i
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error AlreadyInitialized(); // 0x0dc149f0
    error Empty(); // 0x3db2a12a
    error NotInitialized(); // 0x87138d5c
    error NotPowerOfTwo(); // 0x24e8e742
    error OutOfBounds(); // 0xb4120f14

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        INITIALIZER                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Initialize with a fixed capacity (must be power of two).
    function initialize(Buffer storage b, uint256 cap) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := sload(b.slot)
            // already initialized?
            if gt(shr(192, m), 0) {
                mstore(0x00, 0x0dc149f0) // AlreadyInitialized()
                revert(0x1c, 0x04)
            }
            // cap != 0 && (cap & (cap-1)) == 0
            if or(iszero(cap), and(cap, sub(cap, 1))) {
                mstore(0x00, 0x24e8e742) // NotPowerOfTwo()
                revert(0x1c, 0x04)
            }
            // set backing array length and meta (head=0,size=0)
            sstore(add(b.slot, 1), cap)
            sstore(b.slot, shl(192, cap))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     GETTERS                                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Capacity (reverts if not initialized).
    function capacity(Buffer storage b) internal view returns (uint256 cap) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := sload(b.slot)
            cap := shr(192, m)
            if iszero(cap) {
                mstore(0x00, 0x87138d5c) // NotInitialized()
                revert(0x1c, 0x04)
            }
        }
    }

    /// @notice Current number of elements (reverts if not initialized).
    function size(Buffer storage b) internal view returns (uint256 n) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := sload(b.slot)
            let cap := shr(192, m)
            if iszero(cap) {
                mstore(0x00, 0x87138d5c) // NotInitialized()
                revert(0x1c, 0x04)
            }
            n := and(shr(128, m), 0xFFFFFFFFFFFFFFFF)
        }
    }

    /// @notice True if buffer is full (reverts if not initialized).
    function isFull(Buffer storage b) internal view returns (bool full) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := sload(b.slot)
            let cap := shr(192, m)
            if iszero(cap) {
                mstore(0x00, 0x87138d5c) // NotInitialized()
                revert(0x1c, 0x04)
            }
            full := eq(and(shr(128, m), 0xFFFFFFFFFFFFFFFF), cap)
        }
    }

    /// @notice Read by logical index from oldest (0) to newest (size-1).
    function at(Buffer storage b, uint256 i) internal view returns (bytes32 out) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := sload(b.slot)
            let cap := shr(192, m)
            if iszero(cap) {
                mstore(0x00, 0x87138d5c) // NotInitialized()
                revert(0x1c, 0x04)
            }

            let n := and(shr(128, m), 0xFFFFFFFFFFFFFFFF)
            // if (i >= n) revert OutOfBounds()
            if iszero(lt(i, n)) {
                mstore(0x00, 0xb4120f14) // OutOfBounds()
                revert(0x1c, 0x04)
            }

            let head := and(m, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            let idx := and(add(sub(head, n), i), sub(cap, 1))

            mstore(0x00, add(b.slot, 1))
            let base := keccak256(0x00, 0x20)
            out := sload(add(base, idx))
        }
    }

    /// @notice Peek newest (without removing).
    function peekLast(Buffer storage b) internal view returns (bytes32 out) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := sload(b.slot)
            let cap := shr(192, m)
            if iszero(cap) {
                mstore(0x00, 0x87138d5c) // NotInitialized()
                revert(0x1c, 0x04)
            }
            let n := and(shr(128, m), 0xFFFFFFFFFFFFFFFF)
            if iszero(n) {
                mstore(0x00, 0x3db2a12a) // Empty()
                revert(0x1c, 0x04)
            }
            let head := and(m, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            let idx := and(sub(head, 1), sub(cap, 1))

            mstore(0x00, add(b.slot, 1))
            let base := keccak256(0x00, 0x20)
            out := sload(add(base, idx))
        }
    }

    /// @notice Peek oldest (without removing).
    function peekFirst(Buffer storage b) internal view returns (bytes32 out) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := sload(b.slot)
            let cap := shr(192, m)
            if iszero(cap) {
                mstore(0x00, 0x87138d5c) // NotInitialized()
                revert(0x1c, 0x04)
            }
            let n := and(shr(128, m), 0xFFFFFFFFFFFFFFFF)
            if iszero(n) {
                mstore(0x00, 0x3db2a12a) // Empty()
                revert(0x1c, 0x04)
            }
            let head := and(m, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            let idx := and(sub(head, n), sub(cap, 1))

            mstore(0x00, add(b.slot, 1))
            let base := keccak256(0x00, 0x20)
            out := sload(add(base, idx))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     CIRCULAR BUFFER OPERATIONS             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Append a batch of items. Returns the number of overwritten items (0 if none).
    function pushN(Buffer storage b, bytes32[] calldata xs)
        internal
        returns (uint256 overwritten)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := sload(b.slot)
            let cap := shr(192, m)
            if iszero(cap) {
                mstore(0x00, 0x87138d5c) // NotInitialized()
                revert(0x1c, 0x04)
            }

            let len := xs.length
            // if len == 0 just skip (return overwritten = 0)
            if len {
                let head := and(m, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                let n := and(shr(128, m), 0xFFFFFFFFFFFFFFFF)
                mstore(0x00, add(b.slot, 1))
                let base := keccak256(0x00, 0x20)
                let mask := sub(cap, 1)
                let off := xs.offset

                // sstore(base + ((head + i) & mask), xs[i])
                for { let i := 0 } lt(i, len) { i := add(i, 1) } {
                    let word := calldataload(add(off, shl(5, i)))
                    sstore(add(base, and(add(head, i), mask)), word)
                }

                head := add(head, len)
                let sum := add(n, len)
                switch gt(sum, cap)
                case 0 { n := sum }
                default {
                    n := cap
                    overwritten := sub(sum, cap)
                }

                // Mask head to 128 bits before packing.
                head := and(head, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                sstore(b.slot, or(or(shl(192, cap), shl(128, n)), head))
            }
        }
    }

    /// @notice Append one item, overwriting the oldest if full.
    /// @return overwritten True if an old item was overwritten.
    function push(Buffer storage b, bytes32 val) internal returns (bool overwritten) {
        uint256 ow;
        /// @solidity memory-safe-assembly
        assembly {
            let m := sload(b.slot)
            let cap := shr(192, m)
            if iszero(cap) {
                mstore(0x00, 0x87138d5c) // NotInitialized()
                revert(0x1c, 0x04)
            }

            let head := and(m, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            let n := and(shr(128, m), 0xFFFFFFFFFFFFFFFF)

            // idx = head & (cap - 1)
            let idx := and(head, sub(cap, 1))

            // base = keccak256(slotOfData)
            mstore(0x00, add(b.slot, 1))
            let base := keccak256(0x00, 0x20)

            sstore(add(base, idx), val)

            head := add(head, 1)

            switch lt(n, cap)
            case 1 { n := add(n, 1) }
            // ow defaults to 0
            default { ow := 1 }

            // Mask head to 128 bits before packing.
            head := and(head, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            // write meta: (cap<<192) | (n<<128) | head
            sstore(b.slot, or(or(shl(192, cap), shl(128, n)), head))
        }
        overwritten = (ow != 0);
    }

    /// @notice Pop the most recently pushed item (LIFO).
    function pop(Buffer storage b) internal returns (bytes32 out) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := sload(b.slot)
            let cap := shr(192, m)
            if iszero(cap) {
                mstore(0x00, 0x87138d5c) // NotInitialized()
                revert(0x1c, 0x04)
            }

            let n := and(shr(128, m), 0xFFFFFFFFFFFFFFFF)
            if iszero(n) {
                mstore(0x00, 0x3db2a12a) // Empty()
                revert(0x1c, 0x04)
            }

            let head := and(m, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            head := sub(head, 1)
            let idx := and(head, sub(cap, 1))

            mstore(0x00, add(b.slot, 1))
            let base := keccak256(0x00, 0x20)

            out := sload(add(base, idx))

            n := sub(n, 1)
            // Mask head to 128 bits before packing.
            head := and(head, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            sstore(b.slot, or(or(shl(192, cap), shl(128, n)), head))
        }
    }

    /// @notice Remove and return the oldest item (FIFO).
    function shift(Buffer storage b) internal returns (bytes32 out) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := sload(b.slot)
            let cap := shr(192, m)
            if iszero(cap) {
                mstore(0x00, 0x87138d5c) // NotInitialized()
                revert(0x1c, 0x04)
            }

            let n := and(shr(128, m), 0xFFFFFFFFFFFFFFFF)
            if iszero(n) {
                mstore(0x00, 0x3db2a12a) // Empty()
                revert(0x1c, 0x04)
            }

            let head := and(m, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            let idx := and(sub(head, n), sub(cap, 1))

            mstore(0x00, add(b.slot, 1))
            let base := keccak256(0x00, 0x20)

            out := sload(add(base, idx))

            n := sub(n, 1)
            // Mask head to 128 bits before packing (head unchanged, but consistent).
            head := and(head, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            sstore(b.slot, or(or(shl(192, cap), shl(128, n)), head))
        }
    }

    /// @notice Clear contents; capacity unchanged (head=0,size=0). Data not zeroed.
    function clear(Buffer storage b) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := sload(b.slot)
            let cap := shr(192, m)
            if iszero(cap) {
                mstore(0x00, 0x87138d5c) // NotInitialized()
                revert(0x1c, 0x04)
            }
            // keep cap, zero head/size
            sstore(b.slot, shl(192, cap))
        }
    }
}
