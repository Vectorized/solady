// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract Brutalizer {
    /// @dev Fills the memory with junk, for more robust testing of inline assembly
    /// which reads/write to the memory.
    function _brutalizeMemory() internal view {
        // To prevent a solidity 0.8.13 bug.
        // See: https://blog.soliditylang.org/2022/06/15/inline-assembly-memory-side-effects-bug
        // Basically, we need to access a solidity variable from the assembly to
        // tell the compiler that this assembly block is not in isolation.
        uint256 zero;
        /// @solidity memory-safe-assembly
        assembly {
            let offset := mload(0x40) // Start the offset at the free memory pointer.
            calldatacopy(offset, zero, calldatasize())

            // Fill the 64 bytes of scratch space with garbage.
            mstore(zero, add(caller(), gas()))
            mstore(0x20, keccak256(offset, calldatasize()))
            mstore(zero, keccak256(zero, 0x40))

            let r0 := mload(zero)
            let r1 := mload(0x20)

            let cSize := add(codesize(), iszero(codesize()))
            if iszero(lt(cSize, 32)) { cSize := sub(cSize, and(mload(0x02), 0x1f)) }
            let start := mod(mload(0x10), cSize)
            let size := mul(sub(cSize, start), gt(cSize, start))
            let times := div(0x7ffff, cSize)
            if iszero(lt(times, 128)) { times := 128 }

            // Occasionally offset the offset by a pseudorandom large amount.
            // Can't be too large, or we will easily get out-of-gas errors.
            offset := add(offset, mul(iszero(and(r1, 0xf)), and(r0, 0xfffff)))

            // Fill the free memory with garbage.
            // prettier-ignore
            for { let w := not(0) } 1 {} {
                mstore(offset, r0)
                mstore(add(offset, 0x20), r1)
                offset := add(offset, 0x40)
                // We use codecopy instead of the identity precompile
                // to avoid polluting the `forge test -vvvv` output with tons of junk.
                codecopy(offset, start, size)
                codecopy(add(offset, size), 0, start)
                offset := add(offset, cSize)
                times := add(times, w) // `sub(times, 1)`.
                if iszero(times) { break }
            }
        }
    }

    /// @dev Fills the scratch space with junk, for more robust testing of inline assembly
    /// which reads/write to the memory.
    function _brutalizeScratchSpace() internal view {
        // To prevent a solidity 0.8.13 bug.
        // See: https://blog.soliditylang.org/2022/06/15/inline-assembly-memory-side-effects-bug
        // Basically, we need to access a solidity variable from the assembly to
        // tell the compiler that this assembly block is not in isolation.
        uint256 zero;
        /// @solidity memory-safe-assembly
        assembly {
            let offset := mload(0x40) // Start the offset at the free memory pointer.
            calldatacopy(offset, zero, calldatasize())

            // Fill the 64 bytes of scratch space with garbage.
            mstore(zero, add(caller(), gas()))
            mstore(0x20, keccak256(offset, calldatasize()))
            mstore(zero, keccak256(zero, 0x40))
        }
    }

    /// @dev Fills the lower memory with junk, for more robust testing of inline assembly
    /// which reads/write to the memory.
    /// For efficiency, this only fills a small portion of the free memory.
    function _brutalizeLowerMemory() internal view {
        // To prevent a solidity 0.8.13 bug.
        // See: https://blog.soliditylang.org/2022/06/15/inline-assembly-memory-side-effects-bug
        // Basically, we need to access a solidity variable from the assembly to
        // tell the compiler that this assembly block is not in isolation.
        uint256 zero;
        /// @solidity memory-safe-assembly
        assembly {
            let offset := mload(0x40) // Start the offset at the free memory pointer.
            calldatacopy(offset, zero, calldatasize())

            // Fill the 64 bytes of scratch space with garbage.
            mstore(zero, add(caller(), gas()))
            mstore(0x20, keccak256(offset, calldatasize()))
            mstore(zero, keccak256(zero, 0x40))

            for { let r := keccak256(0x10, 0x20) } 1 {} {
                if iszero(and(7, r)) {
                    let x := keccak256(zero, 0x40)
                    mstore(offset, x)
                    mstore(add(0x20, offset), x)
                    mstore(add(0x40, offset), x)
                    mstore(add(0x60, offset), x)
                    mstore(add(0x80, offset), x)
                    mstore(add(0xa0, offset), x)
                    mstore(add(0xc0, offset), x)
                    mstore(add(0xe0, offset), x)
                    mstore(add(0x100, offset), x)
                    mstore(add(0x120, offset), x)
                    mstore(add(0x140, offset), x)
                    mstore(add(0x160, offset), x)
                    mstore(add(0x180, offset), x)
                    mstore(add(0x1a0, offset), x)
                    mstore(add(0x1c0, offset), x)
                    mstore(add(0x1e0, offset), x)
                    mstore(add(0x200, offset), x)
                    mstore(add(0x220, offset), x)
                    mstore(add(0x240, offset), x)
                    mstore(add(0x260, offset), x)
                    break
                }
                codecopy(offset, byte(0, r), codesize())
                break
            }
        }
    }

    /// @dev Fills the memory with junk, for more robust testing of inline assembly
    /// which reads/write to the memory.
    modifier brutalizeMemory() {
        _brutalizeMemory();
        _;
        _checkMemory();
    }

    /// @dev Fills the scratch space with junk, for more robust testing of inline assembly
    /// which reads/write to the memory.
    modifier brutalizeScratchSpace() {
        _brutalizeScratchSpace();
        _;
        _checkMemory();
    }

    /// @dev Fills the lower memory with junk, for more robust testing of inline assembly
    /// which reads/write to the memory.
    modifier brutalizeLowerMemory() {
        _brutalizeLowerMemory();
        _;
        _checkMemory();
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalized(address value) internal pure returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, xor(add(shl(32, value), calldataload(0x00)), mload(0x10)))
            mstore(0x20, calldataload(0x04))
            mstore(0x10, keccak256(0x00, 0x60))
            result := or(shl(160, mload(0x10)), value)
        }
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalized(uint96 value) internal pure returns (uint96 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, xor(add(shl(32, value), calldataload(0x00)), mload(0x10)))
            mstore(0x20, calldataload(0x04))
            mstore(0x10, keccak256(0x00, 0x60))
            result := or(shl(96, mload(0x10)), value)
        }
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalized(bool value) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, xor(add(shl(32, value), calldataload(0x00)), mload(0x10)))
            mstore(0x20, calldataload(0x04))
            mstore(0x10, keccak256(0x00, 0x60))
            result := mul(iszero(iszero(value)), mload(0x10))
        }
    }

    /// @dev Misaligns the free memory pointer.
    /// The free memory pointer has a 1/32 chance to be aligned.
    function _misalignFreeMemoryPointer() internal pure {
        uint256 twoWords = 0x40;
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(twoWords)
            m := add(m, mul(and(keccak256(0x00, twoWords), 0x1f), iszero(and(m, 0x1f))))
            mstore(twoWords, m)
        }
    }

    /// @dev Check if the free memory pointer and the zero slot are not contaminated.
    /// Useful for cases where these slots are used for temporary storage.
    function _checkMemory() internal pure {
        bool zeroSlotIsNotZero;
        bool freeMemoryPointerOverflowed;
        /// @solidity memory-safe-assembly
        assembly {
            // Write ones to the free memory, to make subsequent checks fail if
            // insufficient memory is allocated.
            mstore(mload(0x40), not(0))
            // Test at a lower, but reasonable limit for more safety room.
            if gt(mload(0x40), 0xffffffff) { freeMemoryPointerOverflowed := 1 }
            // Check the value of the zero slot.
            zeroSlotIsNotZero := mload(0x60)
        }
        if (freeMemoryPointerOverflowed) revert("`0x40` overflowed!");
        if (zeroSlotIsNotZero) revert("`0x60` is not zero!");
    }

    /// @dev Check if `s`:
    /// - Has sufficient memory allocated.
    /// - Is zero right padded (cuz some frontends like Etherscan has issues
    ///   with decoding non-zero-right-padded strings).
    function _checkMemory(bytes memory s) internal pure {
        bool notZeroRightPadded;
        bool insufficientMalloc;
        /// @solidity memory-safe-assembly
        assembly {
            // Write ones to the free memory, to make subsequent checks fail if
            // insufficient memory is allocated.
            mstore(mload(0x40), not(0))
            let length := mload(s)
            let lastWord := mload(add(add(s, 0x20), and(length, not(0x1f))))
            let remainder := and(length, 0x1f)
            if remainder { if shl(mul(8, remainder), lastWord) { notZeroRightPadded := 1 } }
            // Check if the memory allocated is sufficient.
            if length { if gt(add(add(s, 0x20), length), mload(0x40)) { insufficientMalloc := 1 } }
        }
        if (notZeroRightPadded) revert("Not zero right padded!");
        if (insufficientMalloc) revert("Insufficient memory allocation!");
        _checkMemory();
    }

    /// @dev For checking the memory allocation for string `s`.
    function _checkMemory(string memory s) internal pure {
        _checkMemory(bytes(s));
    }
}
