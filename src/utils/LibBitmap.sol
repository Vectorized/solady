// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Efficient bitmap library for mapping integers to single bit booleans.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibBitmap.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibBitmap.sol)
library LibBitmap {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev A bitmap in storage.
    struct Bitmap {
        mapping(uint256 => uint256) map;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OPERATIONS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the boolean value of the bit at `index` in `bitmap`.
    function get(Bitmap storage bitmap, uint256 index) internal view returns (bool isSet) {
        // It is better to set `isSet` to either 0 or 1, than zero vs non-zero.
        // Both cost the same amount of gas, but the former allows the returned value
        // to be reused without cleaning the upper bits.
        uint256 b = (bitmap.map[index >> 8] >> (index & 0xff)) & 1;
        assembly {
            isSet := b
        }
    }

    /// @dev Updates the bit at `index` in `bitmap` to true.
    function set(Bitmap storage bitmap, uint256 index) internal {
        bitmap.map[index >> 8] |= (1 << (index & 0xff));
    }

    /// @dev Updates the bit at `index` in `bitmap` to false.
    function unset(Bitmap storage bitmap, uint256 index) internal {
        bitmap.map[index >> 8] &= ~(1 << (index & 0xff));
    }

    /// @dev Flips the bit at `index` in `bitmap`.
    /// Returns the boolean result of the flipped bit.
    function toggle(Bitmap storage bitmap, uint256 index) internal returns (bool newIsSet) {
        assembly {
            mstore(0x00, shr(8, index))
            mstore(0x20, bitmap.slot)
            let storageSlot := keccak256(0x00, 0x40)
            let shift := and(index, 0xff)
            let storageValue := sload(storageSlot)

            let mask := shl(shift, 1)
            storageValue := xor(storageValue, mask)
            // It makes sense to return the `newIsSet`,
            // as it allow us to skip an additional warm `sload`,
            // and it costs minimal gas (about 15),
            // which may be optimized away if the returned value is unused.
            newIsSet := iszero(iszero(and(storageValue, mask)))
            sstore(storageSlot, storageValue)
        }
    }

    /// @dev Updates the bit at `index` in `bitmap` to `shouldSet`.
    function setTo(
        Bitmap storage bitmap,
        uint256 index,
        bool shouldSet
    ) internal {
        assembly {
            mstore(0x20, bitmap.slot)
            mstore(0x00, shr(8, index))
            let storageSlot := keccak256(0x00, 0x40)
            let storageValue := sload(storageSlot)
            let shift := and(index, 0xff)

            sstore(
                storageSlot,
                // Unsets the bit at `shift` via `and`, then sets its new value via `or`.
                or(and(storageValue, not(shl(shift, 1))), shl(shift, iszero(iszero(shouldSet))))
            )
        }
    }
}
