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
        assembly {
            mstore(0x00, shr(8, index))
            mstore(0x20, bitmap.slot)
            let storageSlot := keccak256(0x00, 0x40)
            let storageValue := sload(storageSlot)
            let shift := and(index, 0xff)

            // It is better to set `isSet` to either 0 or 1, than zero vs non-zero.
            // Both cost the same amount of gas, but the former allows the returned value
            // to be reused without cleaning the upper bits.
            isSet := and(shr(shift, storageValue), 1)
        }
    }

    function set(Bitmap storage bitmap, uint256 index) internal {
        bitmap.map[index >> 8] |= (1 << (index & 0xff));
    }

    function unset(Bitmap storage bitmap, uint256 index) internal {
        bitmap.map[index >> 8] &= ~(1 << (index & 0xff));
    }

    function toggle(Bitmap storage bitmap, uint256 index) internal returns (bool newIsSet) {
        assembly {
            mstore(0x00, shr(8, index))
            mstore(0x20, bitmap.slot)
            let storageSlot := keccak256(0x00, 0x40)
            let storageValue := sload(storageSlot)
            let shift := and(index, 0xff)
            
            storageValue := xor(storageValue, shl(shift, 1))
            // It makes sense to return the `newIsSet`,
            // as it allow us to skip an additional warm `sload`, 
            // and it costs minimal gas (about 15),
            // which may be optimized away if the returned value is unused.
            newIsSet := and(shr(shift, storageValue), 1)
            sstore(storageSlot, storageValue)
        }
    }

    function setTo(
        Bitmap storage bitmap,
        uint256 index,
        bool shouldSet
    ) internal {
        assembly {
            mstore(0x00, shr(8, index))
            mstore(0x20, bitmap.slot)
            let storageSlot := keccak256(0x00, 0x40)
            let value := sload(storageSlot)
            let shift := and(index, 0xff)

            // Isolate the bit at `shift`.
            // Xor it with `shouldSet`. Results in 1 if both are different, else 0.
            let x := xor(and(shr(shift, value), 1), gt(shouldSet, 0))

            // Shifts the bit back. Then, xor with value.
            // Only the bit at `shift` will be flipped if they differ.
            // Every other bit will stay the same, as they are xor'ed with zeroes.
            // bitmap.map[index >> 8] = xor(value, shl(shift, x))
            sstore(storageSlot, xor(value, shl(shift, x)))
        }
    }
}
