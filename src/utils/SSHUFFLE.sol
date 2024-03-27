// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibPRNG} from "./LibPRNG.sol";

/// @notice Fisher–Yates shuffling of a storage-based, lazy-initialised array.
/// @author @divergencearran (github.com/aschlosberg)
/// @custom:source Modified from NextShuffler of github.com/divergencetech/ethier
library SSHUFFLE {
    using LibPRNG for LibPRNG.PRNG;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Bit-width of values; this MUST be the same as the size used as values / size.
    uint256 internal constant BITS = 32;
    uint256 internal constant MAX = 0xffffffff;

    /// @dev Number of bits required to shift a value from one end of a word to the other.
    uint256 internal constant E2E_SHIFT = 224; // 256 - BITS

    /// @dev As it says on the tin.
    uint256 internal constant LEFT_MASK =
        0xffffffff00000000000000000000000000000000000000000000000000000000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev State of a storage-based shuffle. Initialise with `init()`, not directly.
    /// @dev Instead of using a uint32[] storage, we choose a random slot (see `init()`) and use the
    /// next `size/8` words to encode a permutation of [0,size). A value of 0 (default) indicates
    /// an unshuffled index whereas a value of `x+1` indicates that the value `x` has been shuffled
    /// to the index. As a result, `type(uint32).max` can't be supported; see `set()` and `init()`
    /// comments.
    struct State {
        // Order MUST NOT change.
        uint192 array; // Slot of first word.
        uint32 size;
        uint32 shuffled;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OPERATIONS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Initialises the `State`, overwriting _all_ information.
    /// @param $ `State` to initialise.
    /// @param key MUST be distinct between `State` instances, used to derive a storage slot for
    /// lazy-instantiation of an array.
    /// @param size Number of values to shuffle, in [0,`type(uint32).max`); note that the max uint32
    /// value is not allowed.
    function init(State storage $, bytes memory key, uint32 size) internal {
        unchecked {
            uint256 data = uint256(size) << 192 | uint192(bytes24(keccak256(key)));
            assembly ("memory-safe") {
                sstore($.slot, data)
            }
        }
    }

    /// @dev Equivalent to `next($,<uint32>)`, sourcing the `rand` param from the `PRNG`.
    function next(State storage $, LibPRNG.PRNG memory rng) internal returns (uint32 chosen) {
        return next($, uint32(rng.next() % ($.size - $.shuffled)));
    }

    /// @dev Performs the next Fisher–Yates shuffle, returning the chosen value.
    /// @param rand A uniform random number in [0,`$.size-$.shuffled`).
    function next(State storage $, uint32 rand) internal returns (uint32 chosen) {
        unchecked {
            State memory s = $;
            rand += s.shuffled; // guaranteed safe by the requirements on `rand`

            chosen = _get(s.array, rand);
            _set(s.array, rand, _get(s.array, s.shuffled));
            _set(s.array, s.shuffled, chosen);

            ++$.shuffled;

            return chosen;
        }
    }

    /// @dev Getter for array backing `State`.
    /// @return The last value stored at `i` by `set()`. Defaults to `i` if no such call made. This
    /// is guaranteed to match the value returned by the respective call to `next()`.
    function get(State storage $, uint32 i) internal view returns (uint32) {
        return _get($.array, i);
    }

    /// @dev Setter for array backing `State`. Primarily exposed for testing getter–setter loop and
    /// no invariants are guaranteed (i.e. use with caution).
    /// @param val Value in [0,`type(uint32).max`) to store at index `i`; note that the max uint32
    /// value is not allowed.
    function set(State storage $, uint32 i, uint32 val) internal {
        _set($.array, i, val);
    }

    /// @dev Private equivalent of `get($,i)`.
    /// @param arraySlot `$.array`.
    /// @return val See `get()`.
    function _get(uint192 arraySlot, uint32 i) private view returns (uint32 val) {
        unchecked {
            assembly ("memory-safe") {
                let data := sload(add(arraySlot, shr(3, i))) // arraySlot + i/8
                let shift := sub(E2E_SHIFT, shl(5, and(i, 7))) // shl(5, and(i, 7)) === (i % 8)*32

                val := and(MAX, shr(shift, data))
                // forgefmt: disable-next-item
                val := add( // Non-branching equivalent of: `val = val == 0 ? i : val - 1`
                    mul(iszero(val), i),
                    mul(iszero(iszero(val)), sub(val, 1))
                )
            }
        }
    }

    /// @dev Private equivalent of `set($,i,val)`.
    /// @param arraySlot `$.array`.
    /// @param val See `set()` for allowed range.
    function _set(uint192 arraySlot, uint32 i, uint32 val) private {
        unchecked {
            assembly ("memory-safe") {
                // forgefmt: disable-next-item
                val := mul( // Non-branching equivalent of: `val == i ? 0 : val + 1`
                    iszero(eq(val, i)),
                    add(val, 1)
                )

                let shift := shl(5, and(i, 7))
                let clear := not(shr(shift, LEFT_MASK))

                let slot := add(arraySlot, shr(3, i))
                // forgefmt: disable-next-item
                sstore(slot, or(
                    and(sload(slot), clear),
                    shl(sub(E2E_SHIFT, shift), val)
                ))
            }
        }
    }
}
