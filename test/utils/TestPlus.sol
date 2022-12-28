// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";

contract TestPlus is Test {
    modifier brutalizeMemory() {
        /// @solidity memory-safe-assembly
        assembly {
            let offset := mload(0x40) // Start the offset at the free memory pointer.
            calldatacopy(offset, 0, calldatasize())

            // Fill the 64 bytes of scratch space with garbage.
            mstore(0x00, xor(gas(), calldatasize()))
            mstore(0x20, xor(caller(), keccak256(offset, calldatasize())))
            mstore(0x00, keccak256(0x00, 0x40))
            mstore(0x20, keccak256(0x00, 0x40))

            let size := 0x40 // Start with 2 slots.
            mstore(offset, mload(0x00))
            mstore(add(offset, 0x20), mload(0x20))

            for { let i := add(11, and(mload(0x00), 1)) } 1 {} {
                let nextOffset := add(offset, size)
                // Duplicate the data.
                pop(
                    staticcall(
                        gas(), // Pass along all the gas in the call.
                        0x04, // Call the identity precompile address.
                        offset, // Offset is the bytes' pointer.
                        size, // We want to pass the length of the bytes.
                        nextOffset, // Store the return value at the next offset.
                        size // Since the precompile just returns its input, we reuse size.
                    )
                )
                // Duplicate the data again.
                returndatacopy(add(nextOffset, size), 0, size)
                offset := nextOffset
                size := mul(2, size)

                i := sub(i, 1)
                if iszero(i) { break }
            }
        }

        _;
    }

    function _random() internal view returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, calldataload(0x00))
            mstore(0x20, xor(calldataload(0x20), gas()))
            r := keccak256(0x00, 0x40)
            for {} 1 {} {
                if iszero(byte(0, r)) {
                    r := and(r, 3)
                    break
                }
                if iszero(gt(byte(0, r), 16)) {
                    r := sub(shl(shl(3, and(byte(1, r), 31)), 1), and(r, 3))
                    break
                }
                mstore(0x00, r)
                r := keccak256(0x00, 0x20)
                break
            }
        }
    }

    function _roundUpFreeMemoryPointer() internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x40, and(add(mload(0x40), 31), not(31)))
        }
    }

    function _checkMemory() internal pure {
        bool zeroSlotIsNotZero;
        bool freeMemoryPointerOverflowed;
        /// @solidity memory-safe-assembly
        assembly {
            // Technically, it can support up to 2**64 - 1, but we test at a lower,
            // but reasonable limit for safety.
            if gt(mload(0x40), 0xffffffff) { freeMemoryPointerOverflowed := 1 }
            zeroSlotIsNotZero := mload(0x60)
        }
        if (freeMemoryPointerOverflowed) revert("Free memory pointer overflowed!");
        if (zeroSlotIsNotZero) revert("Zero slot is not zero!");
    }

    function _checkMemory(bytes memory s) internal pure {
        bool notZeroRightPadded;
        bool fmpNotWordAligned;
        bool insufficientMalloc;
        /// @solidity memory-safe-assembly
        assembly {
            let length := mload(s)
            let lastWord := mload(add(add(s, 0x20), and(length, not(31))))
            let remainder := and(length, 31)
            if remainder { if shl(mul(8, remainder), lastWord) { notZeroRightPadded := 1 } }
            // Check if the free memory pointer is a multiple of 32.
            if and(mload(0x40), 31) { fmpNotWordAligned := 1 }
            // Write some garbage to the free memory.
            mstore(mload(0x40), keccak256(0x00, 0x60))
            // Check if the memory allocated is sufficient.
            if length { if gt(add(add(s, 0x20), length), mload(0x40)) { insufficientMalloc := 1 } }
        }
        if (notZeroRightPadded) revert("Not zero right padded!");
        if (fmpNotWordAligned) revert("Free memory pointer `0x40` not 32-byte word aligned!");
        if (insufficientMalloc) revert("Insufficient memory allocation!");
        _checkMemory();
    }

    function _checkMemory(string memory s) internal pure {
        _checkMemory(bytes(s));
    }

    /// @dev Adapted from:
    /// https://github.com/foundry-rs/forge-std/blob/ff4bf7db008d096ea5a657f2c20516182252a3ed/src/StdUtils.sol#L10
    /// Differentially fuzzed tested against the original implementation.
    function _bound(uint256 x, uint256 min, uint256 max)
        internal
        pure
        virtual
        returns (uint256 result)
    {
        require(min <= max, "_bound(uint256,uint256,uint256): Max is less than min.");

        /// @solidity memory-safe-assembly
        assembly {
            for {} 1 {} {
                // If `x` is between `min` and `max`, return `x` directly.
                // This is to ensure that dictionary values
                // do not get shifted if the min is nonzero.
                // More info: https://github.com/foundry-rs/forge-std/issues/188
                if iszero(or(lt(x, min), gt(x, max))) {
                    result := x
                    break
                }

                let size := add(sub(max, min), 1)
                if and(iszero(gt(x, 3)), gt(size, x)) {
                    result := add(min, x)
                    break
                }

                let w := not(0)
                if and(iszero(lt(x, sub(0, 4))), gt(size, sub(w, x))) {
                    result := sub(max, sub(w, x))
                    break
                }

                // Otherwise, wrap x into the range [min, max],
                // i.e. the range is inclusive.
                if iszero(lt(x, max)) {
                    let d := sub(x, max)
                    let r := mod(d, size)
                    if iszero(r) {
                        result := max
                        break
                    }
                    result := add(add(min, r), w)
                    break
                }
                let d := sub(min, x)
                let r := mod(d, size)
                if iszero(r) {
                    result := min
                    break
                }
                result := add(sub(max, r), 1)
                break
            }
        }
    }
}
