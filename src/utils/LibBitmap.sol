// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./LibBit.sol";

/// @notice Efficient bitmap library for mapping integers to single bit booleans.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibBitmap.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibBitmap.sol)
/// @author Modified from Solidity-Bits (https://github.com/estarriolvetch/solidity-bits/blob/main/contracts/BitMaps.sol)
library LibBitmap {
    uint256 private constant MASK_FULL = type(uint256).max;

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

    /// @dev Consecutively sets `amount` of bits starting from the bit at `startIndex`.
    function setBatch(
        Bitmap storage bitmap,
        uint256 startIndex,
        uint256 amount
    ) internal {
        uint256 bucket = startIndex >> 8;

        uint256 bucketStartIndex = (startIndex & 0xff);

        unchecked {
            if (bucketStartIndex + amount <= 256) {
                bitmap.map[bucket] |= (MASK_FULL >> (256 - amount)) << bucketStartIndex;
            } else {
                bitmap.map[bucket] |= MASK_FULL << bucketStartIndex;
                amount -= (256 - bucketStartIndex);
                bucket++;

                while (amount > 256) {
                    bitmap.map[bucket] = MASK_FULL;
                    amount -= 256;
                    bucket++;
                }

                bitmap.map[bucket] |= MASK_FULL >> (256 - amount);
            }
        }
    }

    /// @dev Consecutively unsets `amount` of bits starting from the bit at `startIndex`.
    function unsetBatch(
        Bitmap storage bitmap,
        uint256 startIndex,
        uint256 amount
    ) internal {
        uint256 bucket = startIndex >> 8;

        uint256 bucketStartIndex = (startIndex & 0xff);

        unchecked {
            if (bucketStartIndex + amount <= 256) {
                bitmap.map[bucket] &= ~((MASK_FULL >> (256 - amount)) << bucketStartIndex);
            } else {
                bitmap.map[bucket] &= ~(MASK_FULL << bucketStartIndex);
                amount -= (256 - bucketStartIndex);
                bucket++;

                while (amount > 256) {
                    bitmap.map[bucket] = 0;
                    amount -= 256;
                    bucket++;
                }

                bitmap.map[bucket] &= ~(MASK_FULL >> (256 - amount));
            }
        }
    }

    /// @dev Returns number of set bits within a range.
    function popCount(
        Bitmap storage bitmap,
        uint256 startIndex,
        uint256 amount
    ) internal view returns (uint256 count) {
        uint256 bucket = startIndex >> 8;

        uint256 bucketStartIndex = (startIndex & 0xff);

        unchecked {
            if (bucketStartIndex + amount <= 256) {
                count += LibBit.popCount((bitmap.map[bucket] >> bucketStartIndex) << (256 - amount));
            } else {
                count += LibBit.popCount(bitmap.map[bucket] >> bucketStartIndex);
                amount -= (256 - bucketStartIndex);
                bucket++;

                while (amount > 256) {
                    count += LibBit.popCount(bitmap.map[bucket]);
                    amount -= 256;
                    bucket++;
                }
                count += LibBit.popCount(bitmap.map[bucket] << (256 - amount));
            }
        }
    }

    /// @dev Find the closest index of the set bit before `index`.
    function scanForward(Bitmap storage bitmap, uint256 index) internal view returns (uint256 setBitIndex) {
        uint256 bucket = index >> 8;

        // index within the bucket
        uint256 bucketIndex = (index & 0xff);

        // load a bitboard from the bitmap.
        uint256 bb = bitmap.map[bucket];

        // offset the bitboard to scan from `bucketIndex`.
        uint256 offset = (0xff ^ bucketIndex);
        bb = bb << offset;

        if (bb > 0) {
            unchecked {
                setBitIndex = (bucket << 8) | (LibBit.fls(bb) - offset);
            }
        } else {
            while (true) {
                require(bucket > 0, "BitMaps: The set bit before the index doesn't exist.");
                unchecked {
                    bucket--;
                }
                // No offset. Always scan from the least significiant bit now.
                bb = bitmap.map[bucket];

                if (bb > 0) {
                    unchecked {
                        setBitIndex = (bucket << 8) | LibBit.fls(bb);
                        break;
                    }
                }
            }
        }
    }
}
