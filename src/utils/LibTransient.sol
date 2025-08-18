// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for transient storage operations.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibTransient.sol)
/// @author Modified from Transient Goodies by Philogy (https://github.com/Philogy/transient-goodies/blob/main/src/TransientBytesLib.sol)
///
/// @dev Note: The functions postfixed with `Compat` will only use transient storage on L1.
/// L2s are super cheap anyway.
/// For best safety, always clear the storage after use.
library LibTransient {
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

    /// @dev Pointer struct to a stack pointer generator in transient storage.
    /// This stack does not directly take in values. Instead, it generates pointers
    /// that can be casted to any of the other transient storage pointer struct.
    struct TStack {
        uint256 _spacer;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The transient stack is empty.
    error StackIsEmpty();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The storage slot seed for converting a transient slot to a storage slot.
    /// `bytes4(keccak256("_LIB_TRANSIENT_COMPAT_SLOT_SEED"))`.
    uint256 private constant _LIB_TRANSIENT_COMPAT_SLOT_SEED = 0x5a0b45f2;

    /// @dev Multiplier to stack base slot, so that in the case where two stacks
    /// share consecutive base slots, their pointers will likely not overlap. A prime.
    uint256 private constant _STACK_BASE_SALT = 0x9e076501211e1371b;

    /// @dev The canonical address of the transient registry.
    /// See: https://gist.github.com/Vectorized/4ab665d7a234ef5aaaff2e5091ec261f
    address internal constant REGISTRY = 0x000000000000297f64C7F8d9595e43257908F170;

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

    /// @dev Returns the value at transient `ptr`.
    function getCompat(TUint256 storage ptr) internal view returns (uint256 result) {
        result = block.chainid == 1 ? get(ptr) : _compat(ptr)._spacer;
    }

    /// @dev Sets the value at transient `ptr`.
    function set(TUint256 storage ptr, uint256 value) internal {
        /// @solidity memory-safe-assembly
        assembly {
            tstore(ptr.slot, value)
        }
    }

    /// @dev Sets the value at transient `ptr`.
    function setCompat(TUint256 storage ptr, uint256 value) internal {
        if (block.chainid == 1) return set(ptr, value);
        _compat(ptr)._spacer = value;
    }

    /// @dev Clears the value at transient `ptr`.
    function clear(TUint256 storage ptr) internal {
        /// @solidity memory-safe-assembly
        assembly {
            tstore(ptr.slot, 0)
        }
    }

    /// @dev Clears the value at transient `ptr`.
    function clearCompat(TUint256 storage ptr) internal {
        if (block.chainid == 1) return clear(ptr);
        _compat(ptr)._spacer = 0;
    }

    /// @dev Increments the value at transient `ptr` by 1.
    function inc(TUint256 storage ptr) internal returns (uint256 newValue) {
        set(ptr, newValue = get(ptr) + 1);
    }

    /// @dev Increments the value at transient `ptr` by 1.
    function incCompat(TUint256 storage ptr) internal returns (uint256 newValue) {
        setCompat(ptr, newValue = getCompat(ptr) + 1);
    }

    /// @dev Increments the value at transient `ptr` by `delta`.
    function inc(TUint256 storage ptr, uint256 delta) internal returns (uint256 newValue) {
        set(ptr, newValue = get(ptr) + delta);
    }

    /// @dev Increments the value at transient `ptr` by `delta`.
    function incCompat(TUint256 storage ptr, uint256 delta) internal returns (uint256 newValue) {
        setCompat(ptr, newValue = getCompat(ptr) + delta);
    }

    /// @dev Decrements the value at transient `ptr` by 1.
    function dec(TUint256 storage ptr) internal returns (uint256 newValue) {
        set(ptr, newValue = get(ptr) - 1);
    }

    /// @dev Decrements the value at transient `ptr` by `delta`.
    function decCompat(TUint256 storage ptr) internal returns (uint256 newValue) {
        setCompat(ptr, newValue = getCompat(ptr) - 1);
    }

    /// @dev Decrements the value at transient `ptr` by `delta`.
    function dec(TUint256 storage ptr, uint256 delta) internal returns (uint256 newValue) {
        set(ptr, newValue = get(ptr) - delta);
    }

    /// @dev Decrements the value at transient `ptr` by `delta`.
    function decCompat(TUint256 storage ptr, uint256 delta) internal returns (uint256 newValue) {
        setCompat(ptr, newValue = getCompat(ptr) - delta);
    }

    /// @dev Increments the value at transient `ptr` by `delta`.
    function incSigned(TUint256 storage ptr, int256 delta) internal returns (uint256 newValue) {
        /// @solidity memory-safe-assembly
        assembly {
            let currentValue := tload(ptr.slot)
            newValue := add(currentValue, delta)
            if iszero(eq(lt(newValue, currentValue), slt(delta, 0))) {
                mstore(0x00, 0x4e487b71) // `Panic(uint256)`.
                mstore(0x20, 0x11) // Underflow or overflow panic.
                revert(0x1c, 0x24)
            }
            tstore(ptr.slot, newValue)
        }
    }

    /// @dev Increments the value at transient `ptr` by `delta`.
    function incSignedCompat(TUint256 storage ptr, int256 delta)
        internal
        returns (uint256 newValue)
    {
        if (block.chainid == 1) return incSigned(ptr, delta);
        ptr = _compat(ptr);
        /// @solidity memory-safe-assembly
        assembly {
            let currentValue := sload(ptr.slot)
            newValue := add(currentValue, delta)
            if iszero(eq(lt(newValue, currentValue), slt(delta, 0))) {
                mstore(0x00, 0x4e487b71) // `Panic(uint256)`.
                mstore(0x20, 0x11) // Underflow or overflow panic.
                revert(0x1c, 0x24)
            }
            sstore(ptr.slot, newValue)
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

    /// @dev Decrements the value at transient `ptr` by `delta`.
    function decSignedCompat(TUint256 storage ptr, int256 delta)
        internal
        returns (uint256 newValue)
    {
        if (block.chainid == 1) return decSigned(ptr, delta);
        ptr = _compat(ptr);
        /// @solidity memory-safe-assembly
        assembly {
            let currentValue := sload(ptr.slot)
            newValue := sub(currentValue, delta)
            if iszero(eq(lt(newValue, currentValue), sgt(delta, 0))) {
                mstore(0x00, 0x4e487b71) // `Panic(uint256)`.
                mstore(0x20, 0x11) // Underflow or overflow panic.
                revert(0x1c, 0x24)
            }
            sstore(ptr.slot, newValue)
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

    /// @dev Returns the value at transient `ptr`.
    function getCompat(TInt256 storage ptr) internal view returns (int256 result) {
        result = block.chainid == 1 ? get(ptr) : int256(_compat(ptr)._spacer);
    }

    /// @dev Sets the value at transient `ptr`.
    function set(TInt256 storage ptr, int256 value) internal {
        /// @solidity memory-safe-assembly
        assembly {
            tstore(ptr.slot, value)
        }
    }

    /// @dev Sets the value at transient `ptr`.
    function setCompat(TInt256 storage ptr, int256 value) internal {
        if (block.chainid == 1) return set(ptr, value);
        _compat(ptr)._spacer = uint256(value);
    }

    /// @dev Clears the value at transient `ptr`.
    function clear(TInt256 storage ptr) internal {
        /// @solidity memory-safe-assembly
        assembly {
            tstore(ptr.slot, 0)
        }
    }

    /// @dev Clears the value at transient `ptr`.
    function clearCompat(TInt256 storage ptr) internal {
        if (block.chainid == 1) return clear(ptr);
        _compat(ptr)._spacer = 0;
    }

    /// @dev Increments the value at transient `ptr` by 1.
    function inc(TInt256 storage ptr) internal returns (int256 newValue) {
        set(ptr, newValue = get(ptr) + 1);
    }

    /// @dev Increments the value at transient `ptr` by 1.
    function incCompat(TInt256 storage ptr) internal returns (int256 newValue) {
        setCompat(ptr, newValue = getCompat(ptr) + 1);
    }

    /// @dev Increments the value at transient `ptr` by `delta`.
    function inc(TInt256 storage ptr, int256 delta) internal returns (int256 newValue) {
        set(ptr, newValue = get(ptr) + delta);
    }

    /// @dev Increments the value at transient `ptr` by `delta`.
    function incCompat(TInt256 storage ptr, int256 delta) internal returns (int256 newValue) {
        setCompat(ptr, newValue = getCompat(ptr) + delta);
    }

    /// @dev Decrements the value at transient `ptr` by 1.
    function dec(TInt256 storage ptr) internal returns (int256 newValue) {
        set(ptr, newValue = get(ptr) - 1);
    }

    /// @dev Decrements the value at transient `ptr` by 1.
    function decCompat(TInt256 storage ptr) internal returns (int256 newValue) {
        setCompat(ptr, newValue = getCompat(ptr) - 1);
    }

    /// @dev Decrements the value at transient `ptr` by `delta`.
    function dec(TInt256 storage ptr, int256 delta) internal returns (int256 newValue) {
        set(ptr, newValue = get(ptr) - delta);
    }

    /// @dev Decrements the value at transient `ptr` by `delta`.
    function decCompat(TInt256 storage ptr, int256 delta) internal returns (int256 newValue) {
        setCompat(ptr, newValue = getCompat(ptr) - delta);
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

    /// @dev Returns the value at transient `ptr`.
    function getCompat(TBytes32 storage ptr) internal view returns (bytes32 result) {
        result = block.chainid == 1 ? get(ptr) : bytes32(_compat(ptr)._spacer);
    }

    /// @dev Sets the value at transient `ptr`.
    function set(TBytes32 storage ptr, bytes32 value) internal {
        /// @solidity memory-safe-assembly
        assembly {
            tstore(ptr.slot, value)
        }
    }

    /// @dev Sets the value at transient `ptr`.
    function setCompat(TBytes32 storage ptr, bytes32 value) internal {
        if (block.chainid == 1) return set(ptr, value);
        _compat(ptr)._spacer = uint256(value);
    }

    /// @dev Clears the value at transient `ptr`.
    function clear(TBytes32 storage ptr) internal {
        /// @solidity memory-safe-assembly
        assembly {
            tstore(ptr.slot, 0)
        }
    }

    /// @dev Clears the value at transient `ptr`.
    function clearCompat(TBytes32 storage ptr) internal {
        if (block.chainid == 1) return clear(ptr);
        _compat(ptr)._spacer = 0;
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

    /// @dev Returns the value at transient `ptr`.
    function getCompat(TAddress storage ptr) internal view returns (address result) {
        result = block.chainid == 1 ? get(ptr) : address(uint160(_compat(ptr)._spacer));
    }

    /// @dev Sets the value at transient `ptr`.
    function set(TAddress storage ptr, address value) internal {
        /// @solidity memory-safe-assembly
        assembly {
            tstore(ptr.slot, shr(96, shl(96, value)))
        }
    }

    /// @dev Sets the value at transient `ptr`.
    function setCompat(TAddress storage ptr, address value) internal {
        if (block.chainid == 1) return set(ptr, value);
        _compat(ptr)._spacer = uint160(value);
    }

    /// @dev Clears the value at transient `ptr`.
    function clear(TAddress storage ptr) internal {
        /// @solidity memory-safe-assembly
        assembly {
            tstore(ptr.slot, 0)
        }
    }

    /// @dev Clears the value at transient `ptr`.
    function clearCompat(TAddress storage ptr) internal {
        if (block.chainid == 1) return clear(ptr);
        _compat(ptr)._spacer = 0;
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

    /// @dev Returns the value at transient `ptr`.
    function getCompat(TBool storage ptr) internal view returns (bool result) {
        result = block.chainid == 1 ? get(ptr) : _compat(ptr)._spacer != 0;
    }

    /// @dev Sets the value at transient `ptr`.
    function set(TBool storage ptr, bool value) internal {
        /// @solidity memory-safe-assembly
        assembly {
            tstore(ptr.slot, iszero(iszero(value)))
        }
    }

    /// @dev Sets the value at transient `ptr`.
    function setCompat(TBool storage ptr, bool value) internal {
        if (block.chainid == 1) return set(ptr, value);
        ptr = _compat(ptr);
        /// @solidity memory-safe-assembly
        assembly {
            sstore(ptr.slot, iszero(iszero(value)))
        }
    }

    /// @dev Clears the value at transient `ptr`.
    function clear(TBool storage ptr) internal {
        /// @solidity memory-safe-assembly
        assembly {
            tstore(ptr.slot, 0)
        }
    }

    /// @dev Clears the value at transient `ptr`.
    function clearCompat(TBool storage ptr) internal {
        if (block.chainid == 1) return clear(ptr);
        _compat(ptr)._spacer = 0;
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

    /// @dev Returns the length of the bytes stored at transient `ptr`.
    function lengthCompat(TBytes storage ptr) internal view returns (uint256 result) {
        if (block.chainid == 1) return length(ptr);
        ptr = _compat(ptr);
        /// @solidity memory-safe-assembly
        assembly {
            result := shr(224, sload(ptr.slot))
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
                let d := sub(keccak256(0x00, 0x20), result)
                for { let o := add(result, 0x3c) } 1 {} {
                    mstore(o, tload(add(o, d)))
                    o := add(o, 0x20)
                    if iszero(lt(o, e)) { break }
                }
            }
            mstore(e, 0) // Zeroize the slot after the string.
            mstore(0x40, add(0x20, e)) // Allocate memory.
        }
    }

    /// @dev Returns the bytes stored at transient `ptr`.
    function getCompat(TBytes storage ptr) internal view returns (bytes memory result) {
        if (block.chainid == 1) return get(ptr);
        ptr = _compat(ptr);
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 0x00)
            mstore(add(result, 0x1c), sload(ptr.slot)) // Length and first `0x1c` bytes.
            let n := mload(result)
            let e := add(add(result, 0x20), n)
            if iszero(lt(n, 0x1d)) {
                mstore(0x00, ptr.slot)
                let d := sub(keccak256(0x00, 0x20), result)
                for { let o := add(result, 0x3c) } 1 {} {
                    mstore(o, sload(add(o, d)))
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
            if iszero(lt(mload(value), 0x1d)) {
                mstore(0x00, ptr.slot)
                let e := add(add(value, 0x20), mload(value))
                let d := sub(keccak256(0x00, or(0x20, sub(0, shr(32, mload(value))))), value)
                for { let o := add(value, 0x3c) } 1 {} {
                    tstore(add(o, d), mload(o))
                    o := add(o, 0x20)
                    if iszero(lt(o, e)) { break }
                }
            }
        }
    }

    /// @dev Sets the value at transient `ptr`.
    function setCompat(TBytes storage ptr, bytes memory value) internal {
        if (block.chainid == 1) return set(ptr, value);
        ptr = _compat(ptr);
        /// @solidity memory-safe-assembly
        assembly {
            sstore(ptr.slot, mload(add(value, 0x1c)))
            if iszero(lt(mload(value), 0x1d)) {
                mstore(0x00, ptr.slot)
                let e := add(add(value, 0x20), mload(value))
                let d := sub(keccak256(0x00, or(0x20, sub(0, shr(32, mload(value))))), value)
                for { let o := add(value, 0x3c) } 1 {} {
                    sstore(add(o, d), mload(o))
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
            tstore(ptr.slot, or(shl(224, value.length), shr(32, calldataload(value.offset))))
            if iszero(lt(value.length, 0x1d)) {
                mstore(0x00, ptr.slot)
                let e := add(value.offset, value.length)
                // forgefmt: disable-next-item
                let d := add(sub(keccak256(0x00, or(0x20, sub(0, shr(32, value.length)))),
                    value.offset), 0x20)
                for { let o := add(value.offset, 0x1c) } 1 {} {
                    tstore(add(o, d), calldataload(o))
                    o := add(o, 0x20)
                    if iszero(lt(o, e)) { break }
                }
            }
        }
    }

    /// @dev Sets the value at transient `ptr`.
    function setCalldataCompat(TBytes storage ptr, bytes calldata value) internal {
        if (block.chainid == 1) return setCalldata(ptr, value);
        ptr = _compat(ptr);
        /// @solidity memory-safe-assembly
        assembly {
            sstore(ptr.slot, or(shl(224, value.length), shr(32, calldataload(value.offset))))
            if iszero(lt(value.length, 0x1d)) {
                mstore(0x00, ptr.slot)
                let e := add(value.offset, value.length)
                // forgefmt: disable-next-item
                let d := add(sub(keccak256(0x00, or(0x20, sub(0, shr(32, value.length)))),
                    value.offset), 0x20)
                for { let o := add(value.offset, 0x1c) } 1 {} {
                    sstore(add(o, d), calldataload(o))
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

    /// @dev Clears the value at transient `ptr`.
    function clearCompat(TBytes storage ptr) internal {
        if (block.chainid == 1) return clear(ptr);
        _compat(ptr)._spacer = 0;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      STACK OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns a pointer to a stack in transient storage.
    function tStack(bytes32 tSlot) internal pure returns (TStack storage ptr) {
        /// @solidity memory-safe-assembly
        assembly {
            ptr.slot := tSlot
        }
    }

    /// @dev Returns a pointer to a stack in transient storage.
    function tStack(uint256 tSlot) internal pure returns (TStack storage ptr) {
        /// @solidity memory-safe-assembly
        assembly {
            ptr.slot := tSlot
        }
    }

    /// @dev Returns the number of elements in the stack.
    function length(TStack storage ptr) internal view returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := shr(160, shl(128, tload(ptr.slot))) // Removes the base offset and stride.
        }
    }

    /// @dev Clears the stack at `ptr`.
    /// Note: Future usage of the stack will point to a fresh transient storage region.
    function clear(TStack storage ptr) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Clears the length and increments the base pointer by `1 << 128`.
            tstore(ptr.slot, shl(128, add(1, shr(128, tload(ptr.slot)))))
        }
    }

    /// @dev Increments the stack length by 1, and returns a pointer to the top element.
    /// We don't want to call this `push` as it does not take in an element value.
    /// Note: The value pointed to might not be cleared from previous usage.
    function place(TStack storage ptr) internal returns (bytes32 topPtr) {
        /// @solidity memory-safe-assembly
        assembly {
            topPtr := add(0x100000000, tload(ptr.slot)) // Increments by a stride.
            tstore(ptr.slot, topPtr)
            topPtr := add(mul(_STACK_BASE_SALT, ptr.slot), topPtr)
        }
    }

    /// @dev Returns a pointer to the top element. Returns the zero pointer if the stack is empty.
    /// This method can help avoid an additional `TLOAD`, but you MUST check if the
    /// returned pointer is zero. And if it is, please DO NOT read / write to it.
    function peek(TStack storage ptr) internal view returns (bytes32 topPtr) {
        /// @solidity memory-safe-assembly
        assembly {
            let t := tload(ptr.slot)
            topPtr := mul(iszero(iszero(shl(128, t))), add(mul(_STACK_BASE_SALT, ptr.slot), t))
        }
    }

    /// @dev Returns a pointer to the top element. Reverts if the stack is empty.
    function top(TStack storage ptr) internal view returns (bytes32 topPtr) {
        /// @solidity memory-safe-assembly
        assembly {
            topPtr := tload(ptr.slot)
            if iszero(topPtr) {
                mstore(0x00, 0xbb704e21) // `StackIsEmpty()`.
                revert(0x1c, 0x04)
            }
            topPtr := add(mul(_STACK_BASE_SALT, ptr.slot), topPtr)
        }
    }

    /// @dev Decrements the stack length by 1, returns a pointer to the top element
    /// before the popping. Reverts if the stack is empty.
    /// Note: Popping from the stack does NOT auto-clear the top value.
    function pop(TStack storage ptr) internal returns (bytes32 lastTopPtr) {
        /// @solidity memory-safe-assembly
        assembly {
            lastTopPtr := tload(ptr.slot)
            if iszero(lastTopPtr) {
                mstore(0x00, 0xbb704e21) // `StackIsEmpty()`.
                revert(0x1c, 0x04)
            }
            tstore(ptr.slot, sub(lastTopPtr, 0x100000000)) // Decrements by a stride.
            lastTopPtr := add(mul(_STACK_BASE_SALT, ptr.slot), lastTopPtr)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               TRANSIENT REGISTRY OPERATIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sets the value for the key.
    /// If the key does not exist, its admin will be set to the caller.
    /// If the key already exist, its value will be overwritten,
    /// and the caller must be the current admin for the key.
    /// Reverts with empty data if the registry has not been deployed.
    function registrySet(bytes32 key, bytes memory value) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, 0xaac438c0) // `set(bytes32,bytes)`.
            mstore(add(m, 0x20), key)
            mstore(add(m, 0x40), 0x40)
            let n := mload(value)
            mstore(add(m, 0x60), n)
            for { let i := 0 } lt(i, n) { i := add(i, 0x20) } {
                mstore(add(add(m, 0x80), i), mload(add(add(value, 0x20), i)))
            }
            if iszero(
                mul(
                    returndatasize(),
                    call(gas(), REGISTRY, 0, add(m, 0x1c), add(n, 0x64), 0x00, 0x20)
                )
            ) { revert(0x00, returndatasize()) }
        }
    }

    /// @dev Returns the value for the key.
    /// Reverts if the key does not exist.
    /// Reverts with empty data if the registry has not been deployed.
    function registryGet(bytes32 key) internal view returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(0x00, 0x8eaa6ac0) // `get(bytes32)`.
            mstore(0x20, key)
            if iszero(mul(returndatasize(), staticcall(gas(), REGISTRY, 0x1c, 0x24, 0x00, 0x20))) {
                revert(0x00, returndatasize())
            }
            // We can safely assume that the bytes will be containing the 0x20 offset.
            returndatacopy(result, 0x20, sub(returndatasize(), 0x20))
            mstore(0x40, add(result, returndatasize())) // Allocate memory.
        }
    }

    /// @dev Clears the admin and the value for the key.
    /// The caller must be the current admin of the key.
    /// Reverts with empty data if the registry has not been deployed.
    function registryClear(bytes32 key) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x97040a45) // `clear(bytes32)`.
            mstore(0x20, key)
            if iszero(mul(returndatasize(), call(gas(), REGISTRY, 0, 0x1c, 0x24, 0x00, 0x20))) {
                revert(0x00, returndatasize())
            }
        }
    }

    /// @dev Returns the admin of the key.
    /// Returns `address(0)` if the key does not exist.
    /// Reverts with empty data if the registry has not been deployed.
    function registryAdminOf(bytes32 key) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0xc5344411) // `adminOf(bytes32)`.
            mstore(0x20, key)
            if iszero(mul(returndatasize(), staticcall(gas(), REGISTRY, 0x1c, 0x24, 0x00, 0x20))) {
                revert(0x00, returndatasize())
            }
            result := mload(0x00)
        }
    }

    /// @dev Changes the admin of the key.
    /// The caller must be the current admin of the key.
    /// The new admin must not be `address(0)`.
    /// Reverts with empty data if the registry has not been deployed.
    function registryChangeAdmin(bytes32 key, address newAdmin) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x00, 0x053b1ca3) // `changeAdmin(bytes32,address)`.
            mstore(0x20, key)
            mstore(0x40, shr(96, shl(96, newAdmin)))
            if iszero(mul(returndatasize(), call(gas(), REGISTRY, 0, 0x1c, 0x44, 0x00, 0x20))) {
                revert(0x00, returndatasize())
            }
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns a regular storage pointer used for compatibility.
    function _compat(TUint256 storage ptr) private pure returns (TUint256 storage c) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x04, _LIB_TRANSIENT_COMPAT_SLOT_SEED)
            mstore(0x00, ptr.slot)
            c.slot := keccak256(0x00, 0x24)
        }
    }

    /// @dev Returns a regular storage pointer used for compatibility.
    function _compat(TInt256 storage ptr) private pure returns (TInt256 storage c) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x04, _LIB_TRANSIENT_COMPAT_SLOT_SEED)
            mstore(0x00, ptr.slot)
            c.slot := keccak256(0x00, 0x24)
        }
    }

    /// @dev Returns a regular storage pointer used for compatibility.
    function _compat(TBytes32 storage ptr) private pure returns (TBytes32 storage c) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x04, _LIB_TRANSIENT_COMPAT_SLOT_SEED)
            mstore(0x00, ptr.slot)
            c.slot := keccak256(0x00, 0x24)
        }
    }

    /// @dev Returns a regular storage pointer used for compatibility.
    function _compat(TAddress storage ptr) private pure returns (TAddress storage c) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x04, _LIB_TRANSIENT_COMPAT_SLOT_SEED)
            mstore(0x00, ptr.slot)
            c.slot := keccak256(0x00, 0x24)
        }
    }

    /// @dev Returns a regular storage pointer used for compatibility.
    function _compat(TBool storage ptr) private pure returns (TBool storage c) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x04, _LIB_TRANSIENT_COMPAT_SLOT_SEED)
            mstore(0x00, ptr.slot)
            c.slot := keccak256(0x00, 0x24)
        }
    }

    /// @dev Returns a regular storage pointer used for compatibility.
    function _compat(TBytes storage ptr) private pure returns (TBytes storage c) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x04, _LIB_TRANSIENT_COMPAT_SLOT_SEED)
            mstore(0x00, ptr.slot)
            c.slot := keccak256(0x00, 0x24)
        }
    }
}
