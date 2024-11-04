// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// This file is auto-generated.

/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
/*                          STRUCTS                           */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

/// @dev Pointer struct to a `uint256` in transient storage.
struct TUint256 {
    uint256 _spacer;
}

/// @dev Pointer struct to a `int256` in transient storage.
struct TInt256 {
    uint256 _spacer;
}

/// @dev Pointer struct to a `bytes32` in transient storage.
struct TBytes32 {
    uint256 _spacer;
}

/// @dev Pointer struct to a `address` in transient storage.
struct TAddress {
    uint256 _spacer;
}

/// @dev Pointer struct to a `bool` in transient storage.
struct TBool {
    uint256 _spacer;
}

/// @dev Pointer struct to a `bytes` in transient storage.
struct TBytes {
    uint256 _spacer;
}

using LibTransient for TUint256 global;
using LibTransient for TInt256 global;
using LibTransient for TBytes32 global;
using LibTransient for TAddress global;
using LibTransient for TBool global;
using LibTransient for TBytes global;

/// @notice Library for RLP encoding and CREATE address computation.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/g/LibTransient.sol)
/// @author Modified from Transient Goodies by Philogy (https://github.com/Philogy/transient-goodies/blob/main/src/TransientBytesLib.sol)
library LibTransient {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     UINT256 OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns a pointer to a `uint256` in transient storage.
    function tUint256(bytes32 tSlot) internal pure returns (TUint256 storage ptr) {
        /// @solidity memory-safe-assembly
        assembly {
            ptr.slot := tSlot
        }
    }

    /// @dev Returns a pointer to a `uint256` in transient storage.
    function tUint256(uint256 tSlot) internal pure returns (TUint256 storage ptr) {
        /// @solidity memory-safe-assembly
        assembly {
            ptr.slot := tSlot
        }
    }

    /// @dev Returns the value at transient `ptr`.
    function get(TUint256 storage ptr) internal view returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := tload(ptr.slot)
        }
    }

    /// @dev Sets the value at transient `ptr`.
    function set(TUint256 storage ptr, uint256 value) internal {
        /// @solidity memory-safe-assembly
        assembly {
            tstore(ptr.slot, value)
        }
    }

    /// @dev Sets the value at transient `ptr` to zero.
    function clear(TUint256 storage ptr) internal {
        /// @solidity memory-safe-assembly
        assembly {
            tstore(ptr.slot, 0)
        }
    }

    /// @dev Increments the value at transient `ptr` by 1.
    function inc(TUint256 storage ptr) internal returns (uint256 newValue) {
        set(ptr, newValue = get(ptr) + 1);
    }

    /// @dev Increments the value at transient `ptr` by `delta`.
    function inc(TUint256 storage ptr, uint256 delta) internal returns (uint256 newValue) {
        set(ptr, newValue = get(ptr) + delta);
    }

    /// @dev Decrements the value at transient `ptr` by 1.
    function dec(TUint256 storage ptr) internal returns (uint256 newValue) {
        set(ptr, newValue = get(ptr) - 1);
    }

    /// @dev Decrements the value at transient `ptr` by `delta`.
    function dec(TUint256 storage ptr, uint256 delta) internal returns (uint256 newValue) {
        set(ptr, newValue = get(ptr) - delta);
    }

    /// @dev Increments the value at transient `ptr` by `delta`.
    function incSigned(TUint256 storage ptr, int256 delta) internal returns (uint256 newValue) {
        /// @solidity memory-safe-assembly
        assembly {
            let currentValue := tload(ptr.slot)
            newValue := add(currentValue, delta)

            tstore(ptr.slot, newValue)
            if iszero(eq(lt(newValue, currentValue), slt(delta, 0))) {
                mstore(0x00, 0x4e487b71) // `Panic(uint256)`.
                mstore(0x20, 0x11) // Underflow or overflow panic.
                revert(0x1c, 0x24)
            }
        }
    }

    /// @dev Decrements the value at transient `ptr` by `delta`.
    function decSigned(TUint256 storage ptr, int256 delta) internal returns (uint256 newValue) {
        /// @solidity memory-safe-assembly
        assembly {
            let currentValue := tload(ptr.slot)
            newValue := sub(currentValue, delta)
            if iszero(eq(lt(newValue, currentValue), sgt(delta, 0))) {
                mstore(0x00, 0x4e487b71) // `Panic(uint256)`.
                mstore(0x20, 0x11) // Underflow or overflow panic.
                revert(0x1c, 0x24)
            }
            tstore(ptr.slot, newValue)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INT256 OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns a pointer to a `int256` in transient storage.
    function tInt256(bytes32 tSlot) internal pure returns (TInt256 storage ptr) {
        /// @solidity memory-safe-assembly
        assembly {
            ptr.slot := tSlot
        }
    }

    /// @dev Returns a pointer to a `int256` in transient storage.
    function tInt256(uint256 tSlot) internal pure returns (TInt256 storage ptr) {
        /// @solidity memory-safe-assembly
        assembly {
            ptr.slot := tSlot
        }
    }

    /// @dev Returns the value at transient `ptr`.
    function get(TInt256 storage ptr) internal view returns (int256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := tload(ptr.slot)
        }
    }

    /// @dev Sets the value at transient `ptr`.
    function set(TInt256 storage ptr, int256 value) internal {
        /// @solidity memory-safe-assembly
        assembly {
            tstore(ptr.slot, value)
        }
    }

    /// @dev Sets the value at transient `ptr` to zero.
    function clear(TInt256 storage ptr) internal {
        /// @solidity memory-safe-assembly
        assembly {
            tstore(ptr.slot, 0)
        }
    }

    /// @dev Increments the value at transient `ptr` by 1.
    function inc(TInt256 storage ptr) internal returns (int256 newValue) {
        set(ptr, newValue = get(ptr) + 1);
    }

    /// @dev Increments the value at transient `ptr` by `delta`.
    function inc(TInt256 storage ptr, int256 delta) internal returns (int256 newValue) {
        set(ptr, newValue = get(ptr) + delta);
    }

    /// @dev Decrements the value at transient `ptr` by 1.
    function dec(TInt256 storage ptr) internal returns (int256 newValue) {
        set(ptr, newValue = get(ptr) - 1);
    }

    /// @dev Decrements the value at transient `ptr` by `delta`.
    function dec(TInt256 storage ptr, int256 delta) internal returns (int256 newValue) {
        set(ptr, newValue = get(ptr) - delta);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     BYTES32 OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns a pointer to a `bytes32` in transient storage.
    function tBytes32(bytes32 tSlot) internal pure returns (TBytes32 storage ptr) {
        /// @solidity memory-safe-assembly
        assembly {
            ptr.slot := tSlot
        }
    }

    /// @dev Returns a pointer to a `bytes32` in transient storage.
    function tBytes32(uint256 tSlot) internal pure returns (TBytes32 storage ptr) {
        /// @solidity memory-safe-assembly
        assembly {
            ptr.slot := tSlot
        }
    }

    /// @dev Returns the value at transient `ptr`.
    function get(TBytes32 storage ptr) internal view returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := tload(ptr.slot)
        }
    }

    /// @dev Sets the value at transient `ptr`.
    function set(TBytes32 storage ptr, bytes32 value) internal {
        /// @solidity memory-safe-assembly
        assembly {
            tstore(ptr.slot, value)
        }
    }

    /// @dev Sets the value at transient `ptr` to zero.
    function clear(TBytes32 storage ptr) internal {
        /// @solidity memory-safe-assembly
        assembly {
            tstore(ptr.slot, 0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     ADDRESS OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns a pointer to a `address` in transient storage.
    function tAddress(bytes32 tSlot) internal pure returns (TAddress storage ptr) {
        /// @solidity memory-safe-assembly
        assembly {
            ptr.slot := tSlot
        }
    }

    /// @dev Returns a pointer to a `address` in transient storage.
    function tAddress(uint256 tSlot) internal pure returns (TAddress storage ptr) {
        /// @solidity memory-safe-assembly
        assembly {
            ptr.slot := tSlot
        }
    }

    /// @dev Returns the value at transient `ptr`.
    function get(TAddress storage ptr) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := tload(ptr.slot)
        }
    }

    /// @dev Sets the value at transient `ptr`.
    function set(TAddress storage ptr, address value) internal {
        /// @solidity memory-safe-assembly
        assembly {
            tstore(ptr.slot, shr(96, shl(96, value)))
        }
    }

    /// @dev Sets the value at transient `ptr` to zero.
    function clear(TAddress storage ptr) internal {
        /// @solidity memory-safe-assembly
        assembly {
            tstore(ptr.slot, 0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      BOOL OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns a pointer to a `bool` in transient storage.
    function tBool(bytes32 tSlot) internal pure returns (TBool storage ptr) {
        /// @solidity memory-safe-assembly
        assembly {
            ptr.slot := tSlot
        }
    }

    /// @dev Returns a pointer to a `bool` in transient storage.
    function tBool(uint256 tSlot) internal pure returns (TBool storage ptr) {
        /// @solidity memory-safe-assembly
        assembly {
            ptr.slot := tSlot
        }
    }

    /// @dev Returns the value at transient `ptr`.
    function get(TBool storage ptr) internal view returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := tload(ptr.slot)
        }
    }

    /// @dev Sets the value at transient `ptr`.
    function set(TBool storage ptr, bool value) internal {
        /// @solidity memory-safe-assembly
        assembly {
            tstore(ptr.slot, iszero(iszero(value)))
        }
    }

    /// @dev Sets the value at transient `ptr` to zero.
    function clear(TBool storage ptr) internal {
        /// @solidity memory-safe-assembly
        assembly {
            tstore(ptr.slot, 0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      BYTES OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns a pointer to a `bytes` in transient storage.
    function tBytes(bytes32 tSlot) internal pure returns (TBytes storage ptr) {
        /// @solidity memory-safe-assembly
        assembly {
            ptr.slot := tSlot
        }
    }

    /// @dev Returns a pointer to a `bytes` in transient storage.
    function tBytes(uint256 tSlot) internal pure returns (TBytes storage ptr) {
        /// @solidity memory-safe-assembly
        assembly {
            ptr.slot := tSlot
        }
    }

    /// @dev Returns the length of the bytes stored at transient `ptr`.
    function length(TBytes storage ptr) internal view returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := shr(224, tload(ptr.slot))
        }
    }

    /// @dev Returns the bytes stored at transient `ptr`.
    function get(TBytes storage ptr) internal view returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 0x00)
            mstore(add(result, 0x1c), tload(ptr.slot)) // Length and first `0x1c` bytes.
            let n := mload(result)
            let e := add(add(result, 0x20), n)
            if iszero(lt(n, 0x1d)) {
                mstore(0x00, ptr.slot)
                let o := add(result, 0x3c)
                for { let d := sub(keccak256(0x00, 0x20), result) } 1 {} {
                    mstore(o, tload(add(o, d)))
                    o := add(o, 0x20)
                    if iszero(lt(o, e)) { break }
                }
            }
            mstore(e, 0) // Zeroize the slot after the string.
            mstore(0x40, add(0x20, e)) // Allocate memory.
        }
    }

    /// @dev Sets the value at transient `ptr`.
    function set(TBytes storage ptr, bytes memory value) internal {
        /// @solidity memory-safe-assembly
        assembly {
            tstore(ptr.slot, mload(add(value, 0x1c)))
            let n := mload(value)
            if iszero(lt(n, 0x1d)) {
                mstore(0x00, ptr.slot)
                let e := add(add(value, 0x20), mul(n, lt(n, 0x100000000)))
                let o := add(value, 0x3c)
                for { let d := sub(keccak256(0x00, 0x20), value) } 1 {} {
                    tstore(add(o, d), mload(o))
                    o := add(o, 0x20)
                    if iszero(lt(o, e)) { break }
                }
            }
        }
    }

    /// @dev Sets the value at transient `ptr`.
    function setCalldata(TBytes storage ptr, bytes calldata value) internal {
        /// @solidity memory-safe-assembly
        assembly {
            tstore(ptr.slot, calldataload(sub(value.offset, 0x04)))
            if iszero(lt(value.length, 0x1d)) {
                mstore(0x00, ptr.slot)
                let e := add(value.offset, mul(value.length, lt(value.length, 0x100000000)))
                let o := add(value.offset, 0x1c)
                for { let d := add(sub(keccak256(0x00, 0x20), value.offset), 0x20) } 1 {} {
                    tstore(add(o, d), calldataload(o))
                    o := add(o, 0x20)
                    if iszero(lt(o, e)) { break }
                }
            }
        }
    }

    /// @dev Clears the value at transient `ptr`.
    function clear(TBytes storage ptr) internal {
        /// @solidity memory-safe-assembly
        assembly {
            tstore(ptr.slot, 0)
        }
    }
}
