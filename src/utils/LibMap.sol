// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for storage of packed unsigned integers.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibMap.sol)
library LibMap {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev A uint8 map in storage.
    struct Uint8Map {
        mapping(uint256 => uint256) map;
    }

    /// @dev A uint16 map in storage.
    struct Uint16Map {
        mapping(uint256 => uint256) map;
    }

    /// @dev A uint32 map in storage.
    struct Uint32Map {
        mapping(uint256 => uint256) map;
    }

    /// @dev A uint64 map in storage.
    struct Uint64Map {
        mapping(uint256 => uint256) map;
    }

    /// @dev A uint128 map in storage.
    struct Uint128Map {
        mapping(uint256 => uint256) map;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OPERATIONS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the uint8 value of the byte at `index` in `map`.
    function get(Uint8Map storage map, uint256 index) internal view returns (uint8 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, map.slot)
            mstore(0x00, shr(5, index))
            result := byte(xor(31, and(index, 0x1f)), sload(keccak256(0x00, 0x40)))
        }
    }

    /// @dev Updates the uint8 value of the byte at `index` in `map`.
    function set(Uint8Map storage map, uint256 index, uint8 value) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, map.slot)
            mstore(0x00, shr(5, index))
            let s := keccak256(0x00, 0x40) // Storage slot.
            mstore(0x00, sload(s))
            mstore8(xor(31, and(index, 0x1f)), value)
            sstore(s, mload(0x00))
        }
    }

    /// @dev Returns the uint16 value of the byte at `index` in `map`.
    function get(Uint16Map storage map, uint256 index) internal view returns (uint16 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, map.slot)
            mstore(0x00, shr(4, index))
            let m := 0xffff // Value mask.
            result := and(m, shr(shl(4, and(index, 15)), sload(keccak256(0x00, 0x40))))
        }
    }

    /// @dev Updates the uint16 value of the byte at `index` in `map`.
    function set(Uint16Map storage map, uint256 index, uint16 value) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, map.slot)
            mstore(0x00, shr(4, index))
            let s := keccak256(0x00, 0x40) // Storage slot.
            let o := shl(4, and(index, 15)) // Storage slot offset (bits).
            let v := sload(s) // Storage slot value.
            let m := 0xffff // Value mask.
            sstore(s, xor(v, shl(o, and(m, xor(shr(o, v), value)))))
        }
    }

    /// @dev Returns the uint32 value of the byte at `index` in `map`.
    function get(Uint32Map storage map, uint256 index) internal view returns (uint32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, map.slot)
            mstore(0x00, shr(3, index))
            let m := 0xffffffff // Value mask.
            result := and(m, shr(shl(5, and(index, 7)), sload(keccak256(0x00, 0x40))))
        }
    }

    /// @dev Updates the uint32 value of the byte at `index` in `map`.
    function set(Uint32Map storage map, uint256 index, uint32 value) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, map.slot)
            mstore(0x00, shr(3, index))
            let s := keccak256(0x00, 0x40) // Storage slot.
            let o := shl(5, and(index, 7)) // Storage slot offset (bits).
            let v := sload(s) // Storage slot value.
            let m := 0xffffffff // Value mask.
            sstore(s, xor(v, shl(o, and(m, xor(shr(o, v), value)))))
        }
    }

    /// @dev Returns the uint64 value of the byte at `index` in `map`.
    function get(Uint64Map storage map, uint256 index) internal view returns (uint64 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, map.slot)
            mstore(0x00, shr(2, index))
            let m := 0xffffffffffffffff // Value mask.
            result := and(m, shr(shl(6, and(index, 3)), sload(keccak256(0x00, 0x40))))
        }
    }

    /// @dev Updates the uint64 value of the byte at `index` in `map`.
    function set(Uint64Map storage map, uint256 index, uint64 value) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, map.slot)
            mstore(0x00, shr(2, index))
            let s := keccak256(0x00, 0x40) // Storage slot.
            let o := shl(6, and(index, 3)) // Storage slot offset (bits).
            let v := sload(s) // Storage slot value.
            let m := 0xffffffffffffffff // Value mask.
            sstore(s, xor(v, shl(o, and(m, xor(shr(o, v), value)))))
        }
    }

    /// @dev Returns the uint128 value of the byte at `index` in `map`.
    function get(Uint128Map storage map, uint256 index) internal view returns (uint128 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, map.slot)
            mstore(0x00, shr(1, index))
            let m := 0xffffffffffffffffffffffffffffffff // Value mask.
            result := and(m, shr(shl(7, and(index, 1)), sload(keccak256(0x00, 0x40))))
        }
    }

    /// @dev Updates the uint128 value of the byte at `index` in `map`.
    function set(Uint128Map storage map, uint256 index, uint128 value) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, map.slot)
            mstore(0x00, shr(1, index))
            let s := keccak256(0x00, 0x40) // Storage slot.
            let o := shl(7, and(index, 1)) // Storage slot offset (bits).
            let v := sload(s) // Storage slot value.
            let m := 0xffffffffffffffffffffffffffffffff // Value mask.
            sstore(s, xor(v, shl(o, and(m, xor(shr(o, v), value)))))
        }
    }
}
