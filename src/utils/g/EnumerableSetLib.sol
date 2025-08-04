// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// This file is auto-generated.

/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
/*                          STRUCTS                           */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

/// @dev An enumerable address set in storage.
struct AddressSet {
    uint256 _spacer;
}

/// @dev An enumerable bytes32 set in storage.
struct Bytes32Set {
    uint256 _spacer;
}

/// @dev An enumerable uint256 set in storage.
struct Uint256Set {
    uint256 _spacer;
}

/// @dev An enumerable int256 set in storage.
struct Int256Set {
    uint256 _spacer;
}

/// @dev An enumerable uint8 set in storage. Useful for enums.
struct Uint8Set {
    uint256 data;
}

using EnumerableSetLib for AddressSet global;
using EnumerableSetLib for Bytes32Set global;
using EnumerableSetLib for Uint256Set global;
using EnumerableSetLib for Int256Set global;
using EnumerableSetLib for Uint8Set global;

/// @notice Library for managing enumerable sets in storage.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/g/EnumerableSetLib.sol)
///
/// @dev Note:
/// In many applications, the number of elements in an enumerable set is small.
/// This enumerable set implementation avoids storing the length and indices
/// for up to 3 elements. Once the length exceeds 3 for the first time, the length
/// and indices will be initialized. The amortized cost of adding elements is O(1).
///
/// The AddressSet implementation packs the length with the 0th entry.
///
/// All enumerable sets except Uint8Set use a pop and swap mechanism to remove elements.
/// This means that the iteration order of elements can change between element removals.
library EnumerableSetLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The index must be less than the length.
    error IndexOutOfBounds();

    /// @dev The value cannot be the zero sentinel.
    error ValueIsZeroSentinel();

    /// @dev Cannot accommodate a new unique value with the capacity.
    error ExceedsCapacity();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The index to represent a value that does not exist.
    uint256 internal constant NOT_FOUND = type(uint256).max;

    /// @dev A sentinel value to denote the zero value in storage.
    /// No elements can be equal to this value.
    /// `uint72(bytes9(keccak256(bytes("_ZERO_SENTINEL"))))`.
    uint256 private constant _ZERO_SENTINEL = 0xfbb67fda52d4bfb8bf;

    /// @dev The storage layout is given by:
    /// ```
    ///     mstore(0x04, _ENUMERABLE_ADDRESS_SET_SLOT_SEED)
    ///     mstore(0x00, set.slot)
    ///     let rootSlot := keccak256(0x00, 0x24)
    ///     mstore(0x20, rootSlot)
    ///     mstore(0x00, shr(96, shl(96, value)))
    ///     let positionSlot := keccak256(0x00, 0x40)
    ///     let valueSlot := add(rootSlot, sload(positionSlot))
    ///     let valueInStorage := shr(96, sload(valueSlot))
    ///     let lazyLength := shr(160, shl(160, sload(rootSlot)))
    /// ```
    uint256 private constant _ENUMERABLE_ADDRESS_SET_SLOT_SEED = 0x978aab92;

    /// @dev The storage layout is given by:
    /// ```
    ///     mstore(0x04, _ENUMERABLE_WORD_SET_SLOT_SEED)
    ///     mstore(0x00, set.slot)
    ///     let rootSlot := keccak256(0x00, 0x24)
    ///     mstore(0x20, rootSlot)
    ///     mstore(0x00, value)
    ///     let positionSlot := keccak256(0x00, 0x40)
    ///     let valueSlot := add(rootSlot, sload(positionSlot))
    ///     let valueInStorage := sload(valueSlot)
    ///     let lazyLength := sload(not(rootSlot))
    /// ```
    uint256 private constant _ENUMERABLE_WORD_SET_SLOT_SEED = 0x18fb5864;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     GETTERS / SETTERS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the number of elements in the set.
    function length(AddressSet storage set) internal view returns (uint256 result) {
        bytes32 rootSlot = _rootSlot(set);
        /// @solidity memory-safe-assembly
        assembly {
            let rootPacked := sload(rootSlot)
            let n := shr(160, shl(160, rootPacked))
            result := shr(1, n)
            for {} iszero(or(iszero(shr(96, rootPacked)), n)) {} {
                result := 1
                if iszero(sload(add(rootSlot, result))) { break }
                result := 2
                if iszero(sload(add(rootSlot, result))) { break }
                result := 3
                break
            }
        }
    }

    /// @dev Returns the number of elements in the set.
    function length(Bytes32Set storage set) internal view returns (uint256 result) {
        bytes32 rootSlot = _rootSlot(set);
        /// @solidity memory-safe-assembly
        assembly {
            let n := sload(not(rootSlot))
            result := shr(1, n)
            for {} iszero(n) {} {
                result := 0
                if iszero(sload(add(rootSlot, result))) { break }
                result := 1
                if iszero(sload(add(rootSlot, result))) { break }
                result := 2
                if iszero(sload(add(rootSlot, result))) { break }
                result := 3
                break
            }
        }
    }

    /// @dev Returns the number of elements in the set.
    function length(Uint256Set storage set) internal view returns (uint256 result) {
        result = length(_toBytes32Set(set));
    }

    /// @dev Returns the number of elements in the set.
    function length(Int256Set storage set) internal view returns (uint256 result) {
        result = length(_toBytes32Set(set));
    }

    /// @dev Returns the number of elements in the set.
    function length(Uint8Set storage set) internal view returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            for { let packed := sload(set.slot) } packed { result := add(1, result) } {
                packed := xor(packed, and(packed, add(1, not(packed))))
            }
        }
    }

    /// @dev Returns whether `value` is in the set.
    function contains(AddressSet storage set, address value) internal view returns (bool result) {
        bytes32 rootSlot = _rootSlot(set);
        /// @solidity memory-safe-assembly
        assembly {
            value := shr(96, shl(96, value))
            if eq(value, _ZERO_SENTINEL) {
                mstore(0x00, 0xf5a267f1) // `ValueIsZeroSentinel()`.
                revert(0x1c, 0x04)
            }
            if iszero(value) { value := _ZERO_SENTINEL }
            let rootPacked := sload(rootSlot)
            for {} 1 {} {
                if iszero(shr(160, shl(160, rootPacked))) {
                    result := 1
                    if eq(shr(96, rootPacked), value) { break }
                    if eq(shr(96, sload(add(rootSlot, 1))), value) { break }
                    if eq(shr(96, sload(add(rootSlot, 2))), value) { break }
                    result := 0
                    break
                }
                mstore(0x20, rootSlot)
                mstore(0x00, value)
                result := iszero(iszero(sload(keccak256(0x00, 0x40))))
                break
            }
        }
    }

    /// @dev Returns whether `value` is in the set.
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool result) {
        bytes32 rootSlot = _rootSlot(set);
        /// @solidity memory-safe-assembly
        assembly {
            if eq(value, _ZERO_SENTINEL) {
                mstore(0x00, 0xf5a267f1) // `ValueIsZeroSentinel()`.
                revert(0x1c, 0x04)
            }
            if iszero(value) { value := _ZERO_SENTINEL }
            for {} 1 {} {
                if iszero(sload(not(rootSlot))) {
                    result := 1
                    if eq(sload(rootSlot), value) { break }
                    if eq(sload(add(rootSlot, 1)), value) { break }
                    if eq(sload(add(rootSlot, 2)), value) { break }
                    result := 0
                    break
                }
                mstore(0x20, rootSlot)
                mstore(0x00, value)
                result := iszero(iszero(sload(keccak256(0x00, 0x40))))
                break
            }
        }
    }

    /// @dev Returns whether `value` is in the set.
    function contains(Uint256Set storage set, uint256 value) internal view returns (bool result) {
        result = contains(_toBytes32Set(set), bytes32(value));
    }

    /// @dev Returns whether `value` is in the set.
    function contains(Int256Set storage set, int256 value) internal view returns (bool result) {
        result = contains(_toBytes32Set(set), bytes32(uint256(value)));
    }

    /// @dev Returns whether `value` is in the set.
    function contains(Uint8Set storage set, uint8 value) internal view returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := and(1, shr(and(0xff, value), sload(set.slot)))
        }
    }

    /// @dev Adds `value` to the set. Returns whether `value` was not in the set.
    function add(AddressSet storage set, address value) internal returns (bool result) {
        bytes32 rootSlot = _rootSlot(set);
        /// @solidity memory-safe-assembly
        assembly {
            value := shr(96, shl(96, value))
            if eq(value, _ZERO_SENTINEL) {
                mstore(0x00, 0xf5a267f1) // `ValueIsZeroSentinel()`.
                revert(0x1c, 0x04)
            }
            if iszero(value) { value := _ZERO_SENTINEL }
            let rootPacked := sload(rootSlot)
            for { let n := shr(160, shl(160, rootPacked)) } 1 {} {
                mstore(0x20, rootSlot)
                if iszero(n) {
                    let v0 := shr(96, rootPacked)
                    if iszero(v0) {
                        sstore(rootSlot, shl(96, value))
                        result := 1
                        break
                    }
                    if eq(v0, value) { break }
                    let v1 := shr(96, sload(add(rootSlot, 1)))
                    if iszero(v1) {
                        sstore(add(rootSlot, 1), shl(96, value))
                        result := 1
                        break
                    }
                    if eq(v1, value) { break }
                    let v2 := shr(96, sload(add(rootSlot, 2)))
                    if iszero(v2) {
                        sstore(add(rootSlot, 2), shl(96, value))
                        result := 1
                        break
                    }
                    if eq(v2, value) { break }
                    mstore(0x00, v0)
                    sstore(keccak256(0x00, 0x40), 1)
                    mstore(0x00, v1)
                    sstore(keccak256(0x00, 0x40), 2)
                    mstore(0x00, v2)
                    sstore(keccak256(0x00, 0x40), 3)
                    rootPacked := or(rootPacked, 7)
                    n := 7
                }
                mstore(0x00, value)
                let p := keccak256(0x00, 0x40)
                if iszero(sload(p)) {
                    n := shr(1, n)
                    result := 1
                    sstore(p, add(1, n))
                    if iszero(n) {
                        sstore(rootSlot, or(3, shl(96, value)))
                        break
                    }
                    sstore(add(rootSlot, n), shl(96, value))
                    sstore(rootSlot, add(2, rootPacked))
                    break
                }
                break
            }
        }
    }

    /// @dev Adds `value` to the set. Returns whether `value` was not in the set.
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool result) {
        bytes32 rootSlot = _rootSlot(set);
        /// @solidity memory-safe-assembly
        assembly {
            if eq(value, _ZERO_SENTINEL) {
                mstore(0x00, 0xf5a267f1) // `ValueIsZeroSentinel()`.
                revert(0x1c, 0x04)
            }
            if iszero(value) { value := _ZERO_SENTINEL }
            for { let n := sload(not(rootSlot)) } 1 {} {
                mstore(0x20, rootSlot)
                if iszero(n) {
                    let v0 := sload(rootSlot)
                    if iszero(v0) {
                        sstore(rootSlot, value)
                        result := 1
                        break
                    }
                    if eq(v0, value) { break }
                    let v1 := sload(add(rootSlot, 1))
                    if iszero(v1) {
                        sstore(add(rootSlot, 1), value)
                        result := 1
                        break
                    }
                    if eq(v1, value) { break }
                    let v2 := sload(add(rootSlot, 2))
                    if iszero(v2) {
                        sstore(add(rootSlot, 2), value)
                        result := 1
                        break
                    }
                    if eq(v2, value) { break }
                    mstore(0x00, v0)
                    sstore(keccak256(0x00, 0x40), 1)
                    mstore(0x00, v1)
                    sstore(keccak256(0x00, 0x40), 2)
                    mstore(0x00, v2)
                    sstore(keccak256(0x00, 0x40), 3)
                    n := 7
                }
                mstore(0x00, value)
                let p := keccak256(0x00, 0x40)
                if iszero(sload(p)) {
                    n := shr(1, n)
                    sstore(add(rootSlot, n), value)
                    sstore(p, add(1, n))
                    sstore(not(rootSlot), or(1, shl(1, add(1, n))))
                    result := 1
                    break
                }
                break
            }
        }
    }

    /// @dev Adds `value` to the set. Returns whether `value` was not in the set.
    function add(Uint256Set storage set, uint256 value) internal returns (bool result) {
        result = add(_toBytes32Set(set), bytes32(value));
    }

    /// @dev Adds `value` to the set. Returns whether `value` was not in the set.
    function add(Int256Set storage set, int256 value) internal returns (bool result) {
        result = add(_toBytes32Set(set), bytes32(uint256(value)));
    }

    /// @dev Adds `value` to the set. Returns whether `value` was not in the set.
    function add(Uint8Set storage set, uint8 value) internal returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(set.slot)
            let mask := shl(and(0xff, value), 1)
            sstore(set.slot, or(result, mask))
            result := iszero(and(result, mask))
        }
    }

    /// @dev Adds `value` to the set. Returns whether `value` was not in the set.
    /// Reverts if the set grows bigger than the custom on-the-fly capacity `cap`.
    function add(AddressSet storage set, address value, uint256 cap)
        internal
        returns (bool result)
    {
        if (result = add(set, value)) if (length(set) > cap) revert ExceedsCapacity();
    }

    /// @dev Adds `value` to the set. Returns whether `value` was not in the set.
    /// Reverts if the set grows bigger than the custom on-the-fly capacity `cap`.
    function add(Bytes32Set storage set, bytes32 value, uint256 cap)
        internal
        returns (bool result)
    {
        if (result = add(set, value)) if (length(set) > cap) revert ExceedsCapacity();
    }

    /// @dev Adds `value` to the set. Returns whether `value` was not in the set.
    /// Reverts if the set grows bigger than the custom on-the-fly capacity `cap`.
    function add(Uint256Set storage set, uint256 value, uint256 cap)
        internal
        returns (bool result)
    {
        if (result = add(set, value)) if (length(set) > cap) revert ExceedsCapacity();
    }

    /// @dev Adds `value` to the set. Returns whether `value` was not in the set.
    /// Reverts if the set grows bigger than the custom on-the-fly capacity `cap`.
    function add(Int256Set storage set, int256 value, uint256 cap) internal returns (bool result) {
        if (result = add(set, value)) if (length(set) > cap) revert ExceedsCapacity();
    }

    /// @dev Adds `value` to the set. Returns whether `value` was not in the set.
    /// Reverts if the set grows bigger than the custom on-the-fly capacity `cap`.
    function add(Uint8Set storage set, uint8 value, uint256 cap) internal returns (bool result) {
        if (result = add(set, value)) if (length(set) > cap) revert ExceedsCapacity();
    }

    /// @dev Removes `value` from the set. Returns whether `value` was in the set.
    function remove(AddressSet storage set, address value) internal returns (bool result) {
        bytes32 rootSlot = _rootSlot(set);
        /// @solidity memory-safe-assembly
        assembly {
            value := shr(96, shl(96, value))
            if eq(value, _ZERO_SENTINEL) {
                mstore(0x00, 0xf5a267f1) // `ValueIsZeroSentinel()`.
                revert(0x1c, 0x04)
            }
            if iszero(value) { value := _ZERO_SENTINEL }
            let rootPacked := sload(rootSlot)
            for { let n := shr(160, shl(160, rootPacked)) } 1 {} {
                if iszero(n) {
                    result := 1
                    if eq(shr(96, rootPacked), value) {
                        sstore(rootSlot, sload(add(rootSlot, 1)))
                        sstore(add(rootSlot, 1), sload(add(rootSlot, 2)))
                        sstore(add(rootSlot, 2), 0)
                        break
                    }
                    if eq(shr(96, sload(add(rootSlot, 1))), value) {
                        sstore(add(rootSlot, 1), sload(add(rootSlot, 2)))
                        sstore(add(rootSlot, 2), 0)
                        break
                    }
                    if eq(shr(96, sload(add(rootSlot, 2))), value) {
                        sstore(add(rootSlot, 2), 0)
                        break
                    }
                    result := 0
                    break
                }
                mstore(0x20, rootSlot)
                mstore(0x00, value)
                let p := keccak256(0x00, 0x40)
                let position := sload(p)
                if iszero(position) { break }
                n := sub(shr(1, n), 1)
                if iszero(eq(sub(position, 1), n)) {
                    let lastValue := shr(96, sload(add(rootSlot, n)))
                    sstore(add(rootSlot, sub(position, 1)), shl(96, lastValue))
                    mstore(0x00, lastValue)
                    sstore(keccak256(0x00, 0x40), position)
                }
                sstore(rootSlot, or(shl(96, shr(96, sload(rootSlot))), or(shl(1, n), 1)))
                sstore(p, 0)
                result := 1
                break
            }
        }
    }

    /// @dev Removes `value` from the set. Returns whether `value` was in the set.
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool result) {
        bytes32 rootSlot = _rootSlot(set);
        /// @solidity memory-safe-assembly
        assembly {
            if eq(value, _ZERO_SENTINEL) {
                mstore(0x00, 0xf5a267f1) // `ValueIsZeroSentinel()`.
                revert(0x1c, 0x04)
            }
            if iszero(value) { value := _ZERO_SENTINEL }
            for { let n := sload(not(rootSlot)) } 1 {} {
                if iszero(n) {
                    result := 1
                    if eq(sload(rootSlot), value) {
                        sstore(rootSlot, sload(add(rootSlot, 1)))
                        sstore(add(rootSlot, 1), sload(add(rootSlot, 2)))
                        sstore(add(rootSlot, 2), 0)
                        break
                    }
                    if eq(sload(add(rootSlot, 1)), value) {
                        sstore(add(rootSlot, 1), sload(add(rootSlot, 2)))
                        sstore(add(rootSlot, 2), 0)
                        break
                    }
                    if eq(sload(add(rootSlot, 2)), value) {
                        sstore(add(rootSlot, 2), 0)
                        break
                    }
                    result := 0
                    break
                }
                mstore(0x20, rootSlot)
                mstore(0x00, value)
                let p := keccak256(0x00, 0x40)
                let position := sload(p)
                if iszero(position) { break }
                n := sub(shr(1, n), 1)
                if iszero(eq(sub(position, 1), n)) {
                    let lastValue := sload(add(rootSlot, n))
                    sstore(add(rootSlot, sub(position, 1)), lastValue)
                    mstore(0x00, lastValue)
                    sstore(keccak256(0x00, 0x40), position)
                }
                sstore(not(rootSlot), or(shl(1, n), 1))
                sstore(p, 0)
                result := 1
                break
            }
        }
    }

    /// @dev Removes `value` from the set. Returns whether `value` was in the set.
    function remove(Uint256Set storage set, uint256 value) internal returns (bool result) {
        result = remove(_toBytes32Set(set), bytes32(value));
    }

    /// @dev Removes `value` from the set. Returns whether `value` was in the set.
    function remove(Int256Set storage set, int256 value) internal returns (bool result) {
        result = remove(_toBytes32Set(set), bytes32(uint256(value)));
    }

    /// @dev Removes `value` from the set. Returns whether `value` was in the set.
    function remove(Uint8Set storage set, uint8 value) internal returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(set.slot)
            let mask := shl(and(0xff, value), 1)
            sstore(set.slot, and(result, not(mask)))
            result := iszero(iszero(and(result, mask)))
        }
    }

    /// @dev Shorthand for `isAdd ? set.add(value, cap) : set.remove(value)`.
    function update(AddressSet storage set, address value, bool isAdd, uint256 cap)
        internal
        returns (bool)
    {
        return isAdd ? add(set, value, cap) : remove(set, value);
    }

    /// @dev Shorthand for `isAdd ? set.add(value, cap) : set.remove(value)`.
    function update(Bytes32Set storage set, bytes32 value, bool isAdd, uint256 cap)
        internal
        returns (bool)
    {
        return isAdd ? add(set, value, cap) : remove(set, value);
    }

    /// @dev Shorthand for `isAdd ? set.add(value, cap) : set.remove(value)`.
    function update(Uint256Set storage set, uint256 value, bool isAdd, uint256 cap)
        internal
        returns (bool)
    {
        return isAdd ? add(set, value, cap) : remove(set, value);
    }

    /// @dev Shorthand for `isAdd ? set.add(value, cap) : set.remove(value)`.
    function update(Int256Set storage set, int256 value, bool isAdd, uint256 cap)
        internal
        returns (bool)
    {
        return isAdd ? add(set, value, cap) : remove(set, value);
    }

    /// @dev Shorthand for `isAdd ? set.add(value, cap) : set.remove(value)`.
    function update(Uint8Set storage set, uint8 value, bool isAdd, uint256 cap)
        internal
        returns (bool)
    {
        return isAdd ? add(set, value, cap) : remove(set, value);
    }

    /// @dev Returns all of the values in the set.
    /// Note: This can consume more gas than the block gas limit for large sets.
    function values(AddressSet storage set) internal view returns (address[] memory result) {
        bytes32 rootSlot = _rootSlot(set);
        /// @solidity memory-safe-assembly
        assembly {
            let zs := _ZERO_SENTINEL
            let rootPacked := sload(rootSlot)
            let n := shr(160, shl(160, rootPacked))
            result := mload(0x40)
            let o := add(0x20, result)
            let v := shr(96, rootPacked)
            mstore(o, mul(v, iszero(eq(v, zs))))
            for {} 1 {} {
                if iszero(n) {
                    if v {
                        n := 1
                        v := shr(96, sload(add(rootSlot, n)))
                        if v {
                            n := 2
                            mstore(add(o, 0x20), mul(v, iszero(eq(v, zs))))
                            v := shr(96, sload(add(rootSlot, n)))
                            if v {
                                n := 3
                                mstore(add(o, 0x40), mul(v, iszero(eq(v, zs))))
                            }
                        }
                    }
                    break
                }
                n := shr(1, n)
                for { let i := 1 } lt(i, n) { i := add(i, 1) } {
                    v := shr(96, sload(add(rootSlot, i)))
                    mstore(add(o, shl(5, i)), mul(v, iszero(eq(v, zs))))
                }
                break
            }
            mstore(result, n)
            mstore(0x40, add(o, shl(5, n)))
        }
    }

    /// @dev Returns all of the values in the set.
    /// Note: This can consume more gas than the block gas limit for large sets.
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory result) {
        bytes32 rootSlot = _rootSlot(set);
        /// @solidity memory-safe-assembly
        assembly {
            let zs := _ZERO_SENTINEL
            let n := sload(not(rootSlot))
            result := mload(0x40)
            let o := add(0x20, result)
            for {} 1 {} {
                if iszero(n) {
                    let v := sload(rootSlot)
                    if v {
                        n := 1
                        mstore(o, mul(v, iszero(eq(v, zs))))
                        v := sload(add(rootSlot, n))
                        if v {
                            n := 2
                            mstore(add(o, 0x20), mul(v, iszero(eq(v, zs))))
                            v := sload(add(rootSlot, n))
                            if v {
                                n := 3
                                mstore(add(o, 0x40), mul(v, iszero(eq(v, zs))))
                            }
                        }
                    }
                    break
                }
                n := shr(1, n)
                for { let i := 0 } lt(i, n) { i := add(i, 1) } {
                    let v := sload(add(rootSlot, i))
                    mstore(add(o, shl(5, i)), mul(v, iszero(eq(v, zs))))
                }
                break
            }
            mstore(result, n)
            mstore(0x40, add(o, shl(5, n)))
        }
    }

    /// @dev Returns all of the values in the set.
    /// Note: This can consume more gas than the block gas limit for large sets.
    function values(Uint256Set storage set) internal view returns (uint256[] memory result) {
        result = _toUints(values(_toBytes32Set(set)));
    }

    /// @dev Returns all of the values in the set.
    /// Note: This can consume more gas than the block gas limit for large sets.
    function values(Int256Set storage set) internal view returns (int256[] memory result) {
        result = _toInts(values(_toBytes32Set(set)));
    }

    /// @dev Returns all of the values in the set.
    function values(Uint8Set storage set) internal view returns (uint8[] memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            let ptr := add(result, 0x20)
            let o := 0
            for { let packed := sload(set.slot) } packed {} {
                if iszero(and(packed, 0xffff)) {
                    o := add(o, 16)
                    packed := shr(16, packed)
                    continue
                }
                mstore(ptr, o)
                ptr := add(ptr, shl(5, and(packed, 1)))
                o := add(o, 1)
                packed := shr(1, packed)
            }
            mstore(result, shr(5, sub(ptr, add(result, 0x20))))
            mstore(0x40, ptr)
        }
    }

    /// @dev Returns the element at index `i` in the set. Reverts if `i` is out-of-bounds.
    function at(AddressSet storage set, uint256 i) internal view returns (address result) {
        bytes32 rootSlot = _rootSlot(set);
        /// @solidity memory-safe-assembly
        assembly {
            result := shr(96, sload(add(rootSlot, i)))
            result := mul(result, iszero(eq(result, _ZERO_SENTINEL)))
        }
        if (i >= length(set)) revert IndexOutOfBounds();
    }

    /// @dev Returns the element at index `i` in the set. Reverts if `i` is out-of-bounds.
    function at(Bytes32Set storage set, uint256 i) internal view returns (bytes32 result) {
        result = _rootSlot(set);
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(add(result, i))
            result := mul(result, iszero(eq(result, _ZERO_SENTINEL)))
        }
        if (i >= length(set)) revert IndexOutOfBounds();
    }

    /// @dev Returns the element at index `i` in the set. Reverts if `i` is out-of-bounds.
    function at(Uint256Set storage set, uint256 i) internal view returns (uint256 result) {
        result = uint256(at(_toBytes32Set(set), i));
    }

    /// @dev Returns the element at index `i` in the set. Reverts if `i` is out-of-bounds.
    function at(Int256Set storage set, uint256 i) internal view returns (int256 result) {
        result = int256(uint256(at(_toBytes32Set(set), i)));
    }

    /// @dev Returns the element at index `i` in the set. Reverts if `i` is out-of-bounds.
    function at(Uint8Set storage set, uint256 i) internal view returns (uint8 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let packed := sload(set.slot)
            for {} 1 {
                mstore(0x00, 0x4e23d035) // `IndexOutOfBounds()`.
                revert(0x1c, 0x04)
            } {
                if iszero(lt(i, 256)) { continue }
                for { let j := 0 } iszero(eq(i, j)) {} {
                    packed := xor(packed, and(packed, add(1, not(packed))))
                    j := add(j, 1)
                }
                if iszero(packed) { continue }
                break
            }
            // Find first set subroutine, optimized for smaller bytecode size.
            let x := and(packed, add(1, not(packed)))
            let r := shl(7, iszero(iszero(shr(128, x))))
            r := or(r, shl(6, iszero(iszero(shr(64, shr(r, x))))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            // For the lower 5 bits of the result, use a De Bruijn lookup.
            // forgefmt: disable-next-item
            result := or(r, byte(and(div(0xd76453e0, shr(r, x)), 0x1f),
                0x001f0d1e100c1d070f090b19131c1706010e11080a1a141802121b1503160405))
        }
    }

    /// @dev Returns the index of `value`. Returns `NOT_FOUND` if the value does not exist.
    function indexOf(AddressSet storage set, address value)
        internal
        view
        returns (uint256 result)
    {
        result = NOT_FOUND;
        if (uint160(value) == _ZERO_SENTINEL) return result;
        bytes32 rootSlot = _rootSlot(set);
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(value) { value := _ZERO_SENTINEL }
            result := not(0)
            let rootPacked := sload(rootSlot)
            for {} 1 {} {
                if iszero(shr(160, shl(160, rootPacked))) {
                    if eq(shr(96, rootPacked), value) {
                        result := 0
                        break
                    }
                    if eq(shr(96, sload(add(rootSlot, 1))), value) {
                        result := 1
                        break
                    }
                    if eq(shr(96, sload(add(rootSlot, 2))), value) {
                        result := 2
                        break
                    }
                    break
                }
                mstore(0x20, rootSlot)
                mstore(0x00, value)
                result := sub(sload(keccak256(0x00, 0x40)), 1)
                break
            }
        }
    }

    /// @dev Returns the index of `value`. Returns `NOT_FOUND` if the value does not exist.
    function indexOf(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (uint256 result)
    {
        result = NOT_FOUND;
        if (uint256(value) == _ZERO_SENTINEL) return result;
        bytes32 rootSlot = _rootSlot(set);
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(value) { value := _ZERO_SENTINEL }
            for {} 1 {} {
                if iszero(sload(not(rootSlot))) {
                    if eq(sload(rootSlot), value) {
                        result := 0
                        break
                    }
                    if eq(sload(add(rootSlot, 1)), value) {
                        result := 1
                        break
                    }
                    if eq(sload(add(rootSlot, 2)), value) {
                        result := 2
                        break
                    }
                    break
                }
                mstore(0x20, rootSlot)
                mstore(0x00, value)
                result := sub(sload(keccak256(0x00, 0x40)), 1)
                break
            }
        }
    }

    /// @dev Returns the index of `value`. Returns `NOT_FOUND` if the value does not exist.
    function indexOf(Uint256Set storage set, uint256 i) internal view returns (uint256 result) {
        result = indexOf(_toBytes32Set(set), bytes32(i));
    }

    /// @dev Returns the index of `value`. Returns `NOT_FOUND` if the value does not exist.
    function indexOf(Int256Set storage set, int256 i) internal view returns (uint256 result) {
        result = indexOf(_toBytes32Set(set), bytes32(uint256(i)));
    }

    /// @dev Returns the index of `value`. Returns `NOT_FOUND` if the value does not exist.
    function indexOf(Uint8Set storage set, uint8 value) internal view returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := not(0)
            let packed := sload(set.slot)
            let m := shl(and(0xff, value), 1)
            if and(packed, m) {
                result := 0
                for { let p := and(packed, sub(m, 1)) } p {} {
                    p := xor(p, and(p, add(1, not(p))))
                    result := add(result, 1)
                }
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the root slot.
    function _rootSlot(AddressSet storage s) private pure returns (bytes32 r) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x04, _ENUMERABLE_ADDRESS_SET_SLOT_SEED)
            mstore(0x00, s.slot)
            r := keccak256(0x00, 0x24)
        }
    }

    /// @dev Returns the root slot.
    function _rootSlot(Bytes32Set storage s) private pure returns (bytes32 r) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x04, _ENUMERABLE_WORD_SET_SLOT_SEED)
            mstore(0x00, s.slot)
            r := keccak256(0x00, 0x24)
        }
    }

    /// @dev Casts to a Bytes32Set.
    function _toBytes32Set(Uint256Set storage s) private pure returns (Bytes32Set storage c) {
        /// @solidity memory-safe-assembly
        assembly {
            c.slot := s.slot
        }
    }

    /// @dev Casts to a Bytes32Set.
    function _toBytes32Set(Int256Set storage s) private pure returns (Bytes32Set storage c) {
        /// @solidity memory-safe-assembly
        assembly {
            c.slot := s.slot
        }
    }

    /// @dev Casts to a uint256 array.
    function _toUints(bytes32[] memory a) private pure returns (uint256[] memory c) {
        /// @solidity memory-safe-assembly
        assembly {
            c := a
        }
    }

    /// @dev Casts to a int256 array.
    function _toInts(bytes32[] memory a) private pure returns (int256[] memory c) {
        /// @solidity memory-safe-assembly
        assembly {
            c := a
        }
    }
}
