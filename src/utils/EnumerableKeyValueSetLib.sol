// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EnumerableSetLib} from "./EnumerableSetLib.sol";

library EnumerableKeyValueSetLib {
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

    /// @dev An enumerable KeyValue (address to uint96) set in storage.
    struct KeyValueSet {
        uint256 _spacer;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     GETTERS / SETTERS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Gets the address key from the keyValuePair. It extracts the first 160 bits.
    /// @dev The first 160 (20 bytes) are for the address key, the last 96 bits (12 bytes) are for the value.
    function getAddressKey(bytes32 keyValuePair) internal pure returns (address key) {
        /// @solidity memory-safe-assembly
        assembly {
            key := shr(96, keyValuePair)
        }
    }

    /// @notice Gets the value from the keyValuePair. It extracts the last 96 bits.
    /// @dev The first 160 (20 bytes) are for the address key, the last 96 bits (12 bytes) are for the value.
    function getValue(bytes32 keyValuePair) internal pure returns (uint256 value) {
        /// @solidity memory-safe-assembly
        assembly {
            value := shr(160, shl(160, keyValuePair))
        }
    }

    function joinKeyValue(address key, uint96 value) internal pure returns (bytes32 keyValuePair) {
        /// @solidity memory-safe-assembly
        assembly {
            keyValuePair := or(shl(96, key), shr(160, shl(160, value)))
        }
    }

    /// @dev Returns the number of elements in the set.
    function length(KeyValueSet storage set) internal view returns (uint256) {
        return EnumerableSetLib.length(_toBytes32Set(set));
    }

    /// @dev Returns whether address `key` is in the set.
    function contains(KeyValueSet storage set, address key) internal view returns (bool result) {
        bytes32 rootSlot = _rootSlot(set);
        /// @solidity memory-safe-assembly
        assembly {
            key := shr(96, shl(96, key))
            if eq(key, _ZERO_SENTINEL) {
                mstore(0x00, 0xf5a267f1) // `ValueIsZeroSentinel()`.
                revert(0x1c, 0x04)
            }
            if iszero(key) { key := _ZERO_SENTINEL }
            for {} 1 {} {
                if iszero(sload(not(rootSlot))) {
                    result := 1
                    /// @dev We only check if the first 20 bytes are equal to the key. (left-padded address)
                    if eq(shr(96, sload(rootSlot)), key) { break }
                    if eq(shr(96, sload(add(rootSlot, 1))), key) { break }
                    if eq(shr(96, sload(add(rootSlot, 2))), key) { break }
                    result := 0
                    break
                }
                mstore(0x20, rootSlot)
                mstore(0x00, key)
                result := iszero(iszero(sload(keccak256(0x00, 0x40))))
                break
            }
        }
    }

    /// @dev Adds `keyValuePair` to the set. Returns whether address `key` was not in the set.
    /// @dev The first 160 (20 bytes) are for the address key, the last 96 bits (12 bytes) are for the value.
    function add(KeyValueSet storage set, bytes32 keyValuePair) internal returns (bool result) {
        bytes32 rootSlot = _rootSlot(set);
        /// @solidity memory-safe-assembly
        assembly {
            let key := shr(96, keyValuePair)
            if eq(key, _ZERO_SENTINEL) {
                mstore(0x00, 0xf5a267f1) // `ValueIsZeroSentinel()`.
                revert(0x1c, 0x04)
            }
            if iszero(key) {
                key := _ZERO_SENTINEL
                keyValuePair := or(shl(96, key), keyValuePair)
            }
            for { let n := sload(not(rootSlot)) } 1 {} {
                mstore(0x20, rootSlot)
                if iszero(n) {
                    let v0 := shr(96, sload(rootSlot))
                    if iszero(v0) {
                        sstore(rootSlot, keyValuePair)
                        result := 1
                        break
                    }
                    if eq(v0, key) { break }
                    let v1 := shr(96, sload(add(rootSlot, 1)))
                    if iszero(v1) {
                        sstore(add(rootSlot, 1), keyValuePair)
                        result := 1
                        break
                    }
                    if eq(v1, key) { break }
                    let v2 := shr(96, sload(add(rootSlot, 2)))
                    if iszero(v2) {
                        sstore(add(rootSlot, 2), keyValuePair)
                        result := 1
                        break
                    }
                    if eq(v2, key) { break }
                    mstore(0x00, v0)
                    sstore(keccak256(0x00, 0x40), 1)
                    mstore(0x00, v1)
                    sstore(keccak256(0x00, 0x40), 2)
                    mstore(0x00, v2)
                    sstore(keccak256(0x00, 0x40), 3)
                    n := 7
                }
                mstore(0x00, key)
                let p := keccak256(0x00, 0x40)
                if iszero(sload(p)) {
                    n := shr(1, n)
                    sstore(add(rootSlot, n), keyValuePair)
                    sstore(p, add(1, n))
                    sstore(not(rootSlot), or(1, shl(1, add(1, n))))
                    result := 1
                    break
                }
                break
            }
        }
    }

    /// @dev Removes `keyValuePair` from the set if the `key` is present. Returns whether address `key` was in the set.
    function remove(KeyValueSet storage set, address key) internal returns (bool result) {
        bytes32 rootSlot = _rootSlot(set);
        /// @solidity memory-safe-assembly
        assembly {
            key := shr(96, shl(96, key))
            if eq(key, _ZERO_SENTINEL) {
                mstore(0x00, 0xf5a267f1) // `ValueIsZeroSentinel()`.
                revert(0x1c, 0x04)
            }
            if iszero(key) { key := _ZERO_SENTINEL }
            for { let n := sload(not(rootSlot)) } 1 {} {
                if iszero(n) {
                    result := 1
                    if eq(shr(96, sload(rootSlot)), key) {
                        sstore(rootSlot, sload(add(rootSlot, 1)))
                        sstore(add(rootSlot, 1), sload(add(rootSlot, 2)))
                        sstore(add(rootSlot, 2), 0)
                        break
                    }
                    if eq(shr(96, sload(add(rootSlot, 1))), key) {
                        sstore(add(rootSlot, 1), sload(add(rootSlot, 2)))
                        sstore(add(rootSlot, 2), 0)
                        break
                    }
                    if eq(shr(96, sload(add(rootSlot, 2))), key) {
                        sstore(add(rootSlot, 2), 0)
                        break
                    }
                    result := 0
                    break
                }
                mstore(0x20, rootSlot)
                mstore(0x00, key)
                let p := keccak256(0x00, 0x40)
                let position := sload(p)
                if iszero(position) { break }
                n := sub(shr(1, n), 1)
                if iszero(eq(sub(position, 1), n)) {
                    let lastValue := sload(add(rootSlot, n))
                    sstore(add(rootSlot, sub(position, 1)), lastValue)
                    sstore(add(rootSlot, n), 0)
                    mstore(0x00, shr(96, lastValue))
                    sstore(keccak256(0x00, 0x40), position)
                }
                sstore(not(rootSlot), or(shl(1, n), 1))
                sstore(p, 0)
                result := 1
                break
            }
        }
    }

    /// @dev Returns all of the values in the set.
    /// Note: This can consume more gas than the block gas limit for large sets.
    function values(KeyValueSet storage set) internal view returns (bytes32[] memory result) {
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
                        mstore(o, or(mul(v, iszero(eq(shr(96, v), zs))), shr(160, shl(160, v))))
                        v := sload(add(rootSlot, n))
                        if v {
                            n := 2
                            mstore(
                                add(o, 0x20),
                                or(mul(v, iszero(eq(shr(96, v), zs))), shr(160, shl(160, v)))
                            )
                            v := sload(add(rootSlot, n))
                            if v {
                                n := 3
                                mstore(
                                    add(o, 0x40),
                                    or(mul(v, iszero(eq(shr(96, v), zs))), shr(160, shl(160, v)))
                                )
                            }
                        }
                    }
                    break
                }
                n := shr(1, n)
                for { let i := 0 } lt(i, n) { i := add(i, 1) } {
                    let v := sload(add(rootSlot, i))
                    mstore(
                        add(o, shl(5, i)),
                        or(mul(v, iszero(eq(shr(96, v), zs))), shr(160, shl(160, v)))
                    )
                }
                break
            }
            mstore(result, n)
            mstore(0x40, add(o, shl(5, n)))
        }
    }

    /// @dev Returns the element at index `i` in the set.
    function at(KeyValueSet storage set, uint256 i) internal view returns (bytes32 result) {
        result = _rootSlot(set);
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(add(result, i))
            result :=
                or(mul(result, iszero(eq(shr(96, result), _ZERO_SENTINEL))), shr(160, shl(160, result)))
        }
        if (i >= length(set)) revert IndexOutOfBounds();
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Casts to a Bytes32Set.
    function _toBytes32Set(KeyValueSet storage s)
        private
        pure
        returns (EnumerableSetLib.Bytes32Set storage c)
    {
        /// @solidity memory-safe-assembly
        assembly {
            c.slot := s.slot
        }
    }

    /// @dev Returns the root slot.
    function _rootSlot(KeyValueSet storage s) private pure returns (bytes32 r) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x04, _ENUMERABLE_WORD_SET_SLOT_SEED)
            mstore(0x00, s.slot)
            r := keccak256(0x00, 0x24)
        }
    }
}
