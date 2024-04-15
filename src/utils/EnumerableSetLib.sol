// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for managing enumerable sets in storage.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibMap.sol)
///
/// @dev Note:
/// In many applications, the number of elements in an enumerable set is small.
/// This enumerable set implementation avoids storing the length and indices
/// for up to 3 elements. Once the length exceeds 3 for the first time, the length
/// and indices will be initialized. The amortized cost of adding elements is O(1).
///
/// The AddressSet implementation packs the length with the 0th entry.
library EnumerableSetLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The index must be less than the length.
    error IndexOutOfBounds();

    /// @dev The value cannot be the zero sentinel.
    error ValueIsZeroSentinel();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

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
                    sstore(add(rootSlot, n), shl(96, value))
                    sstore(p, add(1, n))
                    sstore(rootSlot, add(2, rootPacked))
                    result := 1
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
                    sstore(add(rootSlot, n), 0)
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
                    sstore(add(rootSlot, n), 0)
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

    /// @dev Returns the element at index `i` in the set.
    function at(AddressSet storage set, uint256 i) internal view returns (address result) {
        bytes32 rootSlot = _rootSlot(set);
        /// @solidity memory-safe-assembly
        assembly {
            result := shr(96, sload(add(rootSlot, i)))
            result := mul(result, iszero(eq(result, _ZERO_SENTINEL)))
        }
        if (i >= length(set)) revert IndexOutOfBounds();
    }

    /// @dev Returns the element at index `i` in the set.
    function at(Bytes32Set storage set, uint256 i) internal view returns (bytes32 result) {
        result = _rootSlot(set);
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(add(result, i))
            result := mul(result, iszero(eq(result, _ZERO_SENTINEL)))
        }
        if (i >= length(set)) revert IndexOutOfBounds();
    }

    /// @dev Returns the element at index `i` in the set.
    function at(Uint256Set storage set, uint256 i) internal view returns (uint256 result) {
        result = uint256(at(_toBytes32Set(set), i));
    }

    /// @dev Returns the element at index `i` in the set.
    function at(Int256Set storage set, uint256 i) internal view returns (int256 result) {
        result = int256(uint256(at(_toBytes32Set(set), i)));
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
