// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for efficient storage of enumerable sets.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibMap.sol)
library EnumerableSetLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The index cannot be greater than `2 ** 95 - 1`.
    error IndexOverflow();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev A sentinel value to denote the zero value.
    /// No entries can be equal to this value.
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
    ///     let lazyLength := and(0xffffffffffffffff, sload(rootSlot))
    /// ```
    uint256 private constant _ENUMERABLE_ADDRESS_SET_SLOT_SEED = 0x978aab92;

    /// @dev The storage layout is given by:
    /// ```
    ///     mstore(0x04, _ENUMERABLE_BYTES32_SET_SLOT_SEED)
    ///     mstore(0x00, set.slot)
    ///     let rootSlot := keccak256(0x00, 0x24)
    ///     mstore(0x20, rootSlot)
    ///     mstore(0x00, value)
    ///     let positionSlot := keccak256(0x00, 0x40)
    ///     let valueSlot := add(rootSlot, sload(positionSlot))
    ///     let valueInStorage := sload(valueSlot)
    ///     let lazyLength := sload(not(rootSlot))
    /// ```
    uint256 private constant _ENUMERABLE_BYTES32_SET_SLOT_SEED = 0xbd59ad33;

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

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     GETTERS / SETTERS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function length(AddressSet storage set) internal view returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x04, _ENUMERABLE_ADDRESS_SET_SLOT_SEED)
            mstore(0x00, set.slot)
            let rootSlot := keccak256(0x00, 0x24)
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

    function contains(AddressSet storage set, address value) internal view returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            value := shr(96, shl(96, value))
            if eq(value, _ZERO_SENTINEL) { revert(0x00, 0x00) }
            if iszero(value) { value := _ZERO_SENTINEL }
            mstore(0x04, _ENUMERABLE_ADDRESS_SET_SLOT_SEED)
            mstore(0x00, set.slot)
            let rootSlot := keccak256(0x00, 0x24)
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

    function add(AddressSet storage set, address value) internal returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            value := shr(96, shl(96, value))
            if eq(value, _ZERO_SENTINEL) { revert(0x00, 0x00) }
            if iszero(value) { value := _ZERO_SENTINEL }
            mstore(0x04, _ENUMERABLE_ADDRESS_SET_SLOT_SEED)
            mstore(0x00, set.slot)
            let rootSlot := keccak256(0x00, 0x24)
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
                        mstore(0x00, v0)
                        sstore(keccak256(0x00, 0x40), 1)
                        mstore(0x00, v1)
                        sstore(keccak256(0x00, 0x40), 2)
                        mstore(0x00, value)
                        sstore(keccak256(0x00, 0x40), 3)
                        sstore(rootSlot, or(rootPacked, 7))
                        result := 1
                        break
                    }
                    if eq(v2, value) { break }
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

    function remove(AddressSet storage set, address value) internal returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            value := shr(96, shl(96, value))
            if eq(value, _ZERO_SENTINEL) { revert(0x00, 0x00) }
            if iszero(value) { value := _ZERO_SENTINEL }
            mstore(0x04, _ENUMERABLE_ADDRESS_SET_SLOT_SEED)
            mstore(0x00, set.slot)
            let rootSlot := keccak256(0x00, 0x24)
            let rootPacked := sload(rootSlot)
            for { let n := shr(160, shl(160, rootPacked)) } 1 {} {
                if iszero(n) {
                    if iszero(shr(96, rootPacked)) { break }
                    if eq(shr(96, rootPacked), value) {
                        sstore(rootSlot, sload(add(rootSlot, 1)))
                        sstore(add(rootSlot, 1), 0)
                        result := 1
                        break
                    }
                    let v1 := shr(96, sload(add(rootSlot, 1)))
                    if iszero(v1) { break }
                    if eq(v1, value) {
                        sstore(add(rootSlot, 1), 0)
                        result := 1
                        break
                    }
                    break
                }
                mstore(0x20, rootSlot)
                mstore(0x00, value)
                let p := keccak256(0x00, 0x40)
                let position := sload(p)
                if iszero(position) { break }
                let valueIndex := sub(position, 1)
                let lastIndex := sub(shr(1, n), 1)
                if iszero(eq(valueIndex, lastIndex)) {
                    let lastValue := shr(96, sload(add(rootSlot, lastIndex)))
                    sstore(add(rootSlot, valueIndex), shl(96, lastValue))
                    sstore(add(rootSlot, lastIndex), 0)
                    mstore(0x00, lastValue)
                    sstore(keccak256(0x00, 0x40), position)
                }
                sstore(rootSlot, or(shl(96, shr(96, sload(rootSlot))), or(shl(1, lastIndex), 1)))
                sstore(p, 0)
                result := 1 
                break
            }
        }
    }

    function values(AddressSet storage set) internal view returns (address[] memory result) {
        uint256 n = length(set);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x04, _ENUMERABLE_ADDRESS_SET_SLOT_SEED)
            mstore(0x00, set.slot)
            let rootSlot := keccak256(0x00, 0x24)
            result := mload(0x40)
            let o := add(0x20, result)
            for { let i := 0 } iszero(eq(i, n)) { i := add(i, 1) } {
                mstore(add(o, shl(5, i)), shr(96, sload(add(rootSlot, i))))
            }
            mstore(result, n)
            mstore(0x40, add(o, shl(5, n)))
        }
    }

    function at(AddressSet storage set, uint256 i) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            if shr(95, i) {
                mstore(0x00, 0x7decd257) // `IndexOverflow()`.
                revert(0x1c, 0x04)
            }
            mstore(0x04, _ENUMERABLE_ADDRESS_SET_SLOT_SEED)
            mstore(0x00, set.slot)
            result := shr(96, sload(add(keccak256(0x00, 0x24), i)))
        }
    }

}
