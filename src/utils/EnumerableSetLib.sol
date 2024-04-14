// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for efficient storage of enumerable sets.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibMap.sol)
library EnumerableSetLib {
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
    ///     let length := and(0xffffffffffffffff, sload(rootSlot))
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
    ///     let length := sload(not(rootSlot))
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
            result := and(0xffffffffffffffff, rootPacked)
            for {} iszero(result) {} {
                if iszero(shr(96, rootPacked)) {
                    result := 0
                    break
                }
                if iszero(sload(add(rootSlot, 1))) {
                    result := 1
                    break
                }
                if iszero(sload(add(rootSlot, 2))) {
                    result := 2
                    break
                }
                result := 3 
                break
            }
        }
    }

    function contains(AddressSet storage set, address value) internal view returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            value := shr(96, shl(96, value))
            if iszero(value) { value := _ZERO_SENTINEL }
            mstore(0x04, _ENUMERABLE_ADDRESS_SET_SLOT_SEED)
            mstore(0x00, set.slot)
            let rootSlot := keccak256(0x00, 0x24)
            let rootPacked := sload(rootSlot)
            for {} 1 {} {
                if iszero(and(0xffffffffffffffff, rootPacked)) {
                    if eq(shr(96, rootPacked), value) {
                        result := 1
                        break
                    }
                    if eq(shr(96, sload(add(rootSlot, 1))), value) {
                        result := 1
                        break
                    }
                    if eq(shr(96, sload(add(rootSlot, 2))), value) {
                        result := 1
                        break
                    }
                    break
                }
                mstore(0x20, rootSlot)
                mstore(0x00, shl(96, value))
                // Whether the position is non-zero.
                result := iszero(iszero(sload(keccak256(0x00, 0x40))))
                break
            }
        }
    }

}
