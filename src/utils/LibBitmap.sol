// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Efficient bitmap library for mapping integers to single bit booleans.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibBitmap.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibBitmap.sol)
library LibBitmap {
    struct Bitmap {
        mapping(uint256 => uint256) map;
    }

    function get(Bitmap storage bitmap, uint256 index) internal view returns (bool isSet) {
        uint256 value = bitmap.map[index >> 8] & (1 << (index & 0xff));

        assembly {
            isSet := value // Assign `isSet` to whether the value is non zero.
        }
    }

    function set(Bitmap storage bitmap, uint256 index) internal {
        bitmap.map[index >> 8] |= (1 << (index & 0xff));
    }

    function unset(Bitmap storage bitmap, uint256 index) internal {
        bitmap.map[index >> 8] &= ~(1 << (index & 0xff));
    }

    function toggle(Bitmap storage bitmap, uint256 index) internal {
        bitmap.map[index >> 8] ^= (1 << (index & 0xff));
    }

    function setTo(
        Bitmap storage bitmap,
        uint256 index,
        bool shouldSet
    ) internal {
        assembly {
            // get the storage pointer for bitmap.map[index >> 8]
            // storage pointer == keccak256(index >> 8 . bitmap.slot)
            mstore(0x00, shr(8, index))
            mstore(0x20, bitmap.slot)
            let storagePointer := keccak256(0x00, 0x40)

            // value = bitmap.map[index >> 8]
            let value := sload(storagePointer)

            // The following sets the bit at `shift` without branching.
            let shift := and(index, 0xff)

            // Isolate the bit at `shift`.
            // Xor it with `shouldSet`. Results in 1 if both are different, else 0.
            let x := xor(and(shr(shift, value), 1), shouldSet)

            // Shifts the bit back. Then, xor with value.
            // Only the bit at `shift` will be flipped if they differ.
            // Every other bit will stay the same, as they are xor'ed with zeroes.
            // bitmap.map[index >> 8] = xor(value, shl(shift, x))
            sstore(storagePointer, xor(value, shl(shift, x)))
        }
    }
}
