// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./LibBit.sol";

/// @notice Efficient bitmap library for mapping integers to single bit booleans.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibBitmap.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibBitmap.sol)
/// @author Modified from Solidity-Bits (https://github.com/estarriolvetch/solidity-bits/blob/main/contracts/BitMaps.sol)
library LibBitmap {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The constant returned when a bitmap scan does not find a result.
    uint256 internal constant NOT_FOUND = type(uint256).max;

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

    /// @dev Consecutively sets `amount` of bits starting from the bit at `start`.
    function setBatch(
        Bitmap storage bitmap,
        uint256 start,
        uint256 amount
    ) internal {
        assembly {
            let shift := and(start, 0xff)
            mstore(0x20, bitmap.slot)
            mstore(0x00, shr(8, start))
            let storageSlot := keccak256(0x00, 0x40)
            if iszero(lt(add(shift, amount), 257)) {
                sstore(storageSlot, or(sload(storageSlot), shl(shift, not(0))))
                amount := sub(add(amount, shift), 256)
                let bucket := add(shr(8, start), 1)
                // prettier-ignore
                for {} iszero(lt(amount, 257)) {} {
                    mstore(0x00, bucket)
                    sstore(keccak256(0x00, 0x40), not(0))
                    amount := sub(amount, 256)
                    bucket := add(bucket, 1)
                }
                mstore(0x00, bucket)
                storageSlot := keccak256(0x00, 0x40)
                shift := 0
            }
            sstore(storageSlot, or(sload(storageSlot), shl(shift, shr(sub(256, amount), not(0)))))
        }
    }

    /// @dev Consecutively unsets `amount` of bits starting from the bit at `start`.
    function unsetBatch(
        Bitmap storage bitmap,
        uint256 start,
        uint256 amount
    ) internal {
        assembly {
            let shift := and(start, 0xff)
            mstore(0x20, bitmap.slot)
            mstore(0x00, shr(8, start))
            let storageSlot := keccak256(0x00, 0x40)
            if iszero(lt(add(shift, amount), 257)) {
                sstore(storageSlot, and(sload(storageSlot), not(shl(shift, not(0)))))
                amount := sub(add(amount, shift), 256)
                let bucket := add(shr(8, start), 1)
                // prettier-ignore
                for {} iszero(lt(amount, 257)) {} {
                    mstore(0x00, bucket)
                    sstore(keccak256(0x00, 0x40), 0)
                    amount := sub(amount, 256)
                    bucket := add(bucket, 1)
                }
                mstore(0x00, bucket)
                storageSlot := keccak256(0x00, 0x40)
                shift := 0
            }
            sstore(storageSlot, and(sload(storageSlot), not(shl(shift, shr(sub(256, amount), not(0))))))
        }
    }
    
    /// @dev Returns number of set bits within a range.
    function popCount(
        Bitmap storage bitmap,
        uint256 start,
        uint256 amount
    ) internal view returns (uint256 count) {
        unchecked {
            uint256 bucket = start >> 8;
            uint256 shift = start & 0xff;
            if (!(amount + shift < 257)) {
                count = LibBit.popCount(bitmap.map[bucket] >> shift);
                amount = amount + shift - 256;
                ++bucket;
                while (!(amount < 257)) {
                    count += LibBit.popCount(bitmap.map[bucket]);
                    amount -= 256;
                    ++bucket;
                }
                shift = 0;
            }
            count += LibBit.popCount((bitmap.map[bucket] >> shift) << (256 - amount));
        }
    }

    /// @dev Returns the index of the most significant set bit smaller than `before`.
    /// If no set bit is found, returns `NOT_FOUND`.
    function findLastSet(Bitmap storage bitmap, uint256 before) internal view returns (uint256 setBitIndex) {
        uint256 bucket = before >> 8;
        uint256 bb;
        assembly {
            setBitIndex := not(0)
            mstore(0x20, bitmap.slot)
            mstore(0x00, bucket)
            let offset := xor(0xff, and(0xff, before))
            bb := shr(offset, shl(offset, sload(keccak256(0x00, 0x40))))
            if iszero(bb) {
                // prettier-ignore
                for {} bucket {} {
                    bucket := sub(bucket, 1)
                    mstore(0x00, bucket)
                    bb := sload(keccak256(0x00, 0x40))
                    // prettier-ignore
                    if bb { break }
                }
            }
        }
        if (bb != 0) {
            setBitIndex = (bucket << 8) | LibBit.fls(bb);
            assembly {
                setBitIndex := or(setBitIndex, mul(not(0), gt(setBitIndex, before)))
            }
        }
    }
}
