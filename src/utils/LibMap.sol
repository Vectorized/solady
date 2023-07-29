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

    /// @dev A uint40 map in storage. Useful for storing timestamps up to 34841 A.D.
    struct Uint40Map {
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
    /*                     GETTERS / SETTERS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the uint8 value at `index` in `map`.
    function get(Uint8Map storage map, uint256 index) internal view returns (uint8 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, map.slot)
            mstore(0x00, shr(5, index))
            result := byte(and(31, not(index)), sload(keccak256(0x00, 0x40)))
        }
    }

    /// @dev Updates the uint8 value at `index` in `map`.
    function set(Uint8Map storage map, uint256 index, uint8 value) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, map.slot)
            mstore(0x00, shr(5, index))
            let s := keccak256(0x00, 0x40) // Storage slot.
            mstore(0x00, sload(s))
            mstore8(and(31, not(index)), value)
            sstore(s, mload(0x00))
        }
    }

    /// @dev Returns the uint16 value at `index` in `map`.
    function get(Uint16Map storage map, uint256 index) internal view returns (uint16 result) {
        result = uint16(map.map[index >> 4] >> ((index & 15) << 4));
    }

    /// @dev Updates the uint16 value at `index` in `map`.
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

    /// @dev Returns the uint32 value at `index` in `map`.
    function get(Uint32Map storage map, uint256 index) internal view returns (uint32 result) {
        result = uint32(map.map[index >> 3] >> ((index & 7) << 5));
    }

    /// @dev Updates the uint32 value at `index` in `map`.
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

    /// @dev Returns the uint40 value at `index` in `map`.
    function get(Uint40Map storage map, uint256 index) internal view returns (uint40 result) {
        unchecked {
            result = uint40(map.map[index / 6] >> ((index % 6) * 40));
        }
    }

    /// @dev Updates the uint40 value at `index` in `map`.
    function set(Uint40Map storage map, uint256 index, uint40 value) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, map.slot)
            mstore(0x00, div(index, 6))
            let s := keccak256(0x00, 0x40) // Storage slot.
            let o := mul(40, mod(index, 6)) // Storage slot offset (bits).
            let v := sload(s) // Storage slot value.
            let m := 0xffffffffff // Value mask.
            sstore(s, xor(v, shl(o, and(m, xor(shr(o, v), value)))))
        }
    }

    /// @dev Returns the uint64 value at `index` in `map`.
    function get(Uint64Map storage map, uint256 index) internal view returns (uint64 result) {
        result = uint64(map.map[index >> 2] >> ((index & 3) << 6));
    }

    /// @dev Updates the uint64 value at `index` in `map`.
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

    /// @dev Returns the uint128 value at `index` in `map`.
    function get(Uint128Map storage map, uint256 index) internal view returns (uint128 result) {
        result = uint128(map.map[index >> 1] >> ((index & 1) << 7));
    }

    /// @dev Updates the uint128 value at `index` in `map`.
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

    /// @dev Returns the value at `index` in `map`.
    function get(mapping(uint256 => uint256) storage map, uint256 index, uint256 bitWidth)
        internal
        view
        returns (uint256 result)
    {
        unchecked {
            uint256 d = _rawDiv(256, bitWidth); // Bucket size.
            uint256 m = (1 << bitWidth) - 1; // Value mask.
            result = (map[_rawDiv(index, d)] >> (_rawMod(index, d) * bitWidth)) & m;
        }
    }

    /// @dev Updates the value at `index` in `map`.
    function set(
        mapping(uint256 => uint256) storage map,
        uint256 index,
        uint256 value,
        uint256 bitWidth
    ) internal {
        unchecked {
            uint256 d = _rawDiv(256, bitWidth); // Bucket size.
            uint256 m = (1 << bitWidth) - 1; // Value mask.
            uint256 o = _rawMod(index, d) * bitWidth; // Storage slot offset (bits).
            map[_rawDiv(index, d)] ^= (((map[_rawDiv(index, d)] >> o) ^ value) & m) << o;
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       BINARY SEARCH                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // The following functions search in the range of [`start`, `end`)
    // (i.e. `start <= index < end`).
    // The range must be sorted in ascending order.
    // `index` precedence: equal to > nearest before > nearest after.
    // An invalid search range will simply return `(found = false, index = start)`.

    /// @dev Returns whether `map` contains `needle`, and the index of `needle`.
    function searchSorted(Uint8Map storage map, uint8 needle, uint256 start, uint256 end)
        internal
        view
        returns (bool found, uint256 index)
    {
        return searchSorted(map.map, needle, start, end, 8);
    }

    /// @dev Returns whether `map` contains `needle`, and the index of `needle`.
    function searchSorted(Uint16Map storage map, uint16 needle, uint256 start, uint256 end)
        internal
        view
        returns (bool found, uint256 index)
    {
        return searchSorted(map.map, needle, start, end, 16);
    }

    /// @dev Returns whether `map` contains `needle`, and the index of `needle`.
    function searchSorted(Uint32Map storage map, uint32 needle, uint256 start, uint256 end)
        internal
        view
        returns (bool found, uint256 index)
    {
        return searchSorted(map.map, needle, start, end, 32);
    }

    /// @dev Returns whether `map` contains `needle`, and the index of `needle`.
    function searchSorted(Uint40Map storage map, uint40 needle, uint256 start, uint256 end)
        internal
        view
        returns (bool found, uint256 index)
    {
        return searchSorted(map.map, needle, start, end, 40);
    }

    /// @dev Returns whether `map` contains `needle`, and the index of `needle`.
    function searchSorted(Uint64Map storage map, uint64 needle, uint256 start, uint256 end)
        internal
        view
        returns (bool found, uint256 index)
    {
        return searchSorted(map.map, needle, start, end, 64);
    }

    /// @dev Returns whether `map` contains `needle`, and the index of `needle`.
    function searchSorted(Uint128Map storage map, uint128 needle, uint256 start, uint256 end)
        internal
        view
        returns (bool found, uint256 index)
    {
        return searchSorted(map.map, needle, start, end, 128);
    }

    /// @dev Returns whether `map` contains `needle`, and the index of `needle`.
    function searchSorted(
        mapping(uint256 => uint256) storage map,
        uint256 needle,
        uint256 start,
        uint256 end,
        uint256 bitWidth
    ) internal view returns (bool found, uint256 index) {
        unchecked {
            if (start >= end) end = start;
            uint256 t;
            uint256 o = start - 1; // Offset to derive the actual index.
            uint256 l = 1; // Low.
            uint256 d = _rawDiv(256, bitWidth); // Bucket size.
            uint256 m = (1 << bitWidth) - 1; // Value mask.
            uint256 h = end - start; // High.
            while (true) {
                index = (l & h) + ((l ^ h) >> 1);
                if (l > h) break;
                t = (map[_rawDiv(index + o, d)] >> (_rawMod(index + o, d) * bitWidth)) & m;
                if (t == needle) break;
                if (needle <= t) h = index - 1;
                else l = index + 1;
            }
            /// @solidity memory-safe-assembly
            assembly {
                m := or(iszero(index), iszero(bitWidth))
                found := iszero(or(xor(t, needle), m))
                index := add(o, xor(index, mul(xor(index, 1), m)))
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns `x / y`, returning 0 if `y` is zero.
    function _rawDiv(uint256 x, uint256 y) private pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := div(x, y)
        }
    }

    /// @dev Returns `x % y`, returning 0 if `y` is zero.
    function _rawMod(uint256 x, uint256 y) private pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mod(x, y)
        }
    }
}
