// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// This file is auto-generated.

/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
/*                          STRUCTS                           */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

/// @dev A pseudorandom number state in memory.
struct PRNG {
    uint256 state;
}

/// @dev A lazy Fisher-Yates shuffler for a range `[0..n)` in storage.
struct LazyShuffler {
    // Bits Layout:
    // - [0..31]    `numShuffled`
    // - [32..223]  `permutationSlot`
    // - [224..255] `length`
    uint256 _state;
}

using LibPRNG for PRNG global;
using LibPRNG for LazyShuffler global;

/// @notice Library for generating pseudorandom numbers.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/g/LibPRNG.sol)
/// @author LazyShuffler based on NextShuffler by aschlosberg (divergencearran)
/// (https://github.com/divergencetech/ethier/blob/main/contracts/random/NextShuffler.sol)
library LibPRNG {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The initial length must be greater than zero and less than `2**32 - 1`.
    error InvalidInitialLazyShufflerLength();

    /// @dev The new length must not be less than the current length.
    error InvalidNewLazyShufflerLength();

    /// @dev The lazy shuffler has not been initialized.
    error LazyShufflerNotInitialized();

    /// @dev Cannot double initialize the lazy shuffler.
    error LazyShufflerAlreadyInitialized();

    /// @dev The lazy shuffle has finished.
    error LazyShuffleFinished();

    /// @dev The queried index is out of bounds.
    error LazyShufflerGetOutOfBounds();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The scalar of ETH and most ERC20s.
    uint256 internal constant WAD = 1e18;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OPERATIONS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Seeds the `prng` with `state`.
    function seed(PRNG memory prng, uint256 state) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(prng, state)
        }
    }

    /// @dev Returns the next pseudorandom uint256.
    /// All bits of the returned uint256 pass the NIST Statistical Test Suite.
    function next(PRNG memory prng) internal pure returns (uint256 result) {
        // We simply use `keccak256` for a great balance between
        // runtime gas costs, bytecode size, and statistical properties.
        //
        // A high-quality LCG with a 32-byte state
        // is only about 30% more gas efficient during runtime,
        // but requires a 32-byte multiplier, which can cause bytecode bloat
        // when this function is inlined.
        //
        // Using this method is about 2x more efficient than
        // `nextRandomness = uint256(keccak256(abi.encode(randomness)))`.
        /// @solidity memory-safe-assembly
        assembly {
            result := keccak256(prng, 0x20)
            mstore(prng, result)
        }
    }

    /// @dev Returns a pseudorandom uint256, uniformly distributed
    /// between 0 (inclusive) and `upper` (exclusive).
    /// If your modulus is big, this method is recommended
    /// for uniform sampling to avoid modulo bias.
    /// For uniform sampling across all uint256 values,
    /// or for small enough moduli such that the bias is negligible,
    /// use {next} instead.
    function uniform(PRNG memory prng, uint256 upper) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            for {} 1 {} {
                result := keccak256(prng, 0x20)
                mstore(prng, result)
                if iszero(lt(result, mod(sub(0, upper), upper))) { break }
            }
            result := mod(result, upper)
        }
    }

    /// @dev Returns a sample from the standard normal distribution denominated in `WAD`.
    function standardNormalWad(PRNG memory prng) internal pure returns (int256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Technically, this is the Irwin-Hall distribution with 20 samples.
            // The chance of drawing a sample outside 10 σ from the standard normal distribution
            // is ≈ 0.000000000000000000000015, which is insignificant for most practical purposes.
            // Passes the Kolmogorov-Smirnov test for 200k samples. Uses about 322 gas.
            result := keccak256(prng, 0x20)
            mstore(prng, result)
            let n := 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff43 // Prime.
            let a := 0x100000000000000000000000000000051 // Prime and a primitive root of `n`.
            let m := 0x1fffffffffffffff1fffffffffffffff1fffffffffffffff1fffffffffffffff
            let s := 0x1000000000000000100000000000000010000000000000001
            let r1 := mulmod(result, a, n)
            let r2 := mulmod(r1, a, n)
            let r3 := mulmod(r2, a, n)
            // forgefmt: disable-next-item
            result := sub(sar(96, mul(26614938895861601847173011183,
                add(add(shr(192, mul(s, add(and(m, result), and(m, r1)))),
                shr(192, mul(s, add(and(m, r2), and(m, r3))))),
                shr(192, mul(s, and(m, mulmod(r3, a, n))))))), 7745966692414833770)
        }
    }

    /// @dev Returns a sample from the unit exponential distribution denominated in `WAD`.
    function exponentialWad(PRNG memory prng) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Passes the Kolmogorov-Smirnov test for 200k samples.
            // Gas usage varies, starting from about 172+ gas.
            let r := keccak256(prng, 0x20)
            mstore(prng, r)
            let p := shl(129, r)
            let w := shl(1, r)
            if iszero(gt(w, p)) {
                let n := 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff43 // Prime.
                let a := 0x100000000000000000000000000000051 // Prime and a primitive root of `n`.
                for {} 1 {} {
                    r := mulmod(r, a, n)
                    if iszero(lt(shl(129, r), w)) {
                        r := mulmod(r, a, n)
                        result := add(1000000000000000000, result)
                        w := shl(1, r)
                        p := shl(129, r)
                        if iszero(lt(w, p)) { break }
                        continue
                    }
                    w := shl(1, r)
                    if iszero(lt(w, shl(129, r))) { break }
                }
            }
            result := add(div(p, shl(129, 170141183460469231732)), result)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*             MEMORY ARRAY SHUFFLING OPERATIONS              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Shuffles the array in-place with Fisher-Yates shuffle.
    function shuffle(PRNG memory prng, uint256[] memory a) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(a)
            let w := not(0)
            let mask := shr(128, w)
            if n {
                for { a := add(a, 0x20) } 1 {} {
                    // We can just directly use `keccak256`, cuz
                    // the other approaches don't save much.
                    let r := keccak256(prng, 0x20)
                    mstore(prng, r)

                    // Note that there will be a very tiny modulo bias
                    // if the length of the array is not a power of 2.
                    // For all practical purposes, it is negligible
                    // and will not be a fairness or security concern.
                    {
                        let j := add(a, shl(5, mod(shr(128, r), n)))
                        n := add(n, w) // `sub(n, 1)`.
                        if iszero(n) { break }

                        let i := add(a, shl(5, n))
                        let t := mload(i)
                        mstore(i, mload(j))
                        mstore(j, t)
                    }

                    {
                        let j := add(a, shl(5, mod(and(r, mask), n)))
                        n := add(n, w) // `sub(n, 1)`.
                        if iszero(n) { break }

                        let i := add(a, shl(5, n))
                        let t := mload(i)
                        mstore(i, mload(j))
                        mstore(j, t)
                    }
                }
            }
        }
    }

    /// @dev Shuffles the array in-place with Fisher-Yates shuffle.
    function shuffle(PRNG memory prng, int256[] memory a) internal pure {
        shuffle(prng, _toUints(a));
    }

    /// @dev Shuffles the array in-place with Fisher-Yates shuffle.
    function shuffle(PRNG memory prng, address[] memory a) internal pure {
        shuffle(prng, _toUints(a));
    }

    /// @dev Partially shuffles the array in-place with Fisher-Yates shuffle.
    /// The first `k` elements will be uniformly sampled without replacement.
    function shuffle(PRNG memory prng, uint256[] memory a, uint256 k) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(a)
            k := xor(k, mul(xor(k, n), lt(n, k))) // `min(n, k)`.
            if k {
                let mask := shr(128, not(0))
                let b := 0
                for { a := add(a, 0x20) } 1 {} {
                    // We can just directly use `keccak256`, cuz
                    // the other approaches don't save much.
                    let r := keccak256(prng, 0x20)
                    mstore(prng, r)

                    // Note that there will be a very tiny modulo bias
                    // if the length of the array is not a power of 2.
                    // For all practical purposes, it is negligible
                    // and will not be a fairness or security concern.
                    {
                        let j := add(a, shl(5, add(b, mod(shr(128, r), sub(n, b)))))
                        let i := add(a, shl(5, b))
                        let t := mload(i)
                        mstore(i, mload(j))
                        mstore(j, t)
                        b := add(b, 1)
                        if eq(b, k) { break }
                    }

                    {
                        let j := add(a, shl(5, add(b, mod(and(r, mask), sub(n, b)))))
                        let i := add(a, shl(5, b))
                        let t := mload(i)
                        mstore(i, mload(j))
                        mstore(j, t)
                        b := add(b, 1)
                        if eq(b, k) { break }
                    }
                }
            }
        }
    }

    /// @dev Partially shuffles the array in-place with Fisher-Yates shuffle.
    /// The first `k` elements will be uniformly sampled without replacement.
    function shuffle(PRNG memory prng, int256[] memory a, uint256 k) internal pure {
        shuffle(prng, _toUints(a), k);
    }

    /// @dev Partially shuffles the array in-place with Fisher-Yates shuffle.
    /// The first `k` elements will be uniformly sampled without replacement.
    function shuffle(PRNG memory prng, address[] memory a, uint256 k) internal pure {
        shuffle(prng, _toUints(a), k);
    }

    /// @dev Shuffles the bytes in-place with Fisher-Yates shuffle.
    function shuffle(PRNG memory prng, bytes memory a) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(a)
            let w := not(0)
            let mask := shr(128, w)
            if n {
                let b := add(a, 0x01)
                for { a := add(a, 0x20) } 1 {} {
                    // We can just directly use `keccak256`, cuz
                    // the other approaches don't save much.
                    let r := keccak256(prng, 0x20)
                    mstore(prng, r)

                    // Note that there will be a very tiny modulo bias
                    // if the length of the array is not a power of 2.
                    // For all practical purposes, it is negligible
                    // and will not be a fairness or security concern.
                    {
                        let o := mod(shr(128, r), n)
                        n := add(n, w) // `sub(n, 1)`.
                        if iszero(n) { break }

                        let t := mload(add(b, n))
                        mstore8(add(a, n), mload(add(b, o)))
                        mstore8(add(a, o), t)
                    }

                    {
                        let o := mod(and(r, mask), n)
                        n := add(n, w) // `sub(n, 1)`.
                        if iszero(n) { break }

                        let t := mload(add(b, n))
                        mstore8(add(a, n), mload(add(b, o)))
                        mstore8(add(a, o), t)
                    }
                }
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*       STORAGE-BASED RANGE LAZY SHUFFLING OPERATIONS        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Initializes the state for lazy-shuffling the range `[0..n)`.
    /// Reverts if `n == 0 || n >= 2**32 - 1`.
    /// Reverts if `$` has already been initialized.
    /// If you need to reduce the length after initialization, just use a fresh new `$`.
    function initialize(LazyShuffler storage $, uint256 n) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(lt(sub(n, 1), 0xfffffffe)) {
                mstore(0x00, 0x83b53941) // `InvalidInitialLazyShufflerLength()`.
                revert(0x1c, 0x04)
            }
            if sload($.slot) {
                mstore(0x00, 0x0c9f11f2) // `LazyShufflerAlreadyInitialized()`.
                revert(0x1c, 0x04)
            }
            mstore(0x00, $.slot)
            sstore($.slot, or(shl(224, n), shl(32, shr(64, keccak256(0x00, 0x20)))))
        }
    }

    /// @dev Increases the length of `$`.
    /// Reverts if `$` has not been initialized.
    function grow(LazyShuffler storage $, uint256 n) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let state := sload($.slot) // The packed value at `$`.
            // If the new length is smaller than the old length, revert.
            if lt(n, shr(224, state)) {
                mstore(0x00, 0xbed37c6e) // `InvalidNewLazyShufflerLength()`.
                revert(0x1c, 0x04)
            }
            if iszero(state) {
                mstore(0x00, 0x1ead2566) // `LazyShufflerNotInitialized()`.
                revert(0x1c, 0x04)
            }
            sstore($.slot, or(shl(224, n), shr(32, shl(32, state))))
        }
    }

    /// @dev Restarts the shuffler by setting `numShuffled` to zero,
    /// such that all elements can be drawn again.
    /// Restarting does NOT clear the internal permutation, nor changes the length.
    /// Even with the same sequence of randomness, reshuffling can yield different results.
    function restart(LazyShuffler storage $) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let state := sload($.slot)
            if iszero(state) {
                mstore(0x00, 0x1ead2566) // `LazyShufflerNotInitialized()`.
                revert(0x1c, 0x04)
            }
            sstore($.slot, shl(32, shr(32, state)))
        }
    }

    /// @dev Returns the number of elements that have been shuffled.
    function numShuffled(LazyShuffler storage $) internal view returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := and(0xffffffff, sload($.slot))
        }
    }

    /// @dev Returns the length of `$`.
    /// Returns zero if `$` is not initialized, else a non-zero value less than `2**32 - 1`.
    function length(LazyShuffler storage $) internal view returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := shr(224, sload($.slot))
        }
    }

    /// @dev Returns if `$` has been initialized.
    function initialized(LazyShuffler storage $) internal view returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := iszero(iszero(sload($.slot)))
        }
    }

    /// @dev Returns if there are any more elements left to shuffle.
    /// Reverts if `$` is not initialized.
    function finished(LazyShuffler storage $) internal view returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            let state := sload($.slot) // The packed value at `$`.
            if iszero(state) {
                mstore(0x00, 0x1ead2566) // `LazyShufflerNotInitialized()`.
                revert(0x1c, 0x04)
            }
            result := eq(shr(224, state), and(0xffffffff, state))
        }
    }

    /// @dev Returns the current value stored at `index`, accounting for all historical shuffling.
    /// Reverts if `index` is greater than or equal to the `length` of `$`.
    function get(LazyShuffler storage $, uint256 index) internal view returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let state := sload($.slot) // The packed value at `$`.
            let n := shr(224, state) // Length of `$`.
            if iszero(lt(index, n)) {
                mstore(0x00, 0x61367cc4) // `LazyShufflerGetOutOfBounds()`.
                revert(0x1c, 0x04)
            }
            let u32 := gt(n, 0xfffe)
            let s := add(shr(sub(4, u32), index), shr(64, shl(32, state))) // Bucket slot.
            let o := shl(add(4, u32), and(index, shr(u32, 15))) // Bucket slot offset (bits).
            let m := sub(shl(shl(u32, 16), 1), 1) // Value mask.
            result := and(m, shr(o, sload(s)))
            result := xor(index, mul(xor(index, sub(result, 1)), iszero(iszero(result))))
        }
    }

    /// @dev Does a single Fisher-Yates shuffle step, increments the `numShuffled` in `$`,
    /// and returns the next value in the shuffled range.
    /// `randomness` can be taken from a good-enough source, or a higher quality source like VRF.
    /// Reverts if there are no more values to shuffle, which includes the case if `$` is not initialized.
    function next(LazyShuffler storage $, uint256 randomness) internal returns (uint256 chosen) {
        /// @solidity memory-safe-assembly
        assembly {
            function _get(u32_, state_, i_) -> _value {
                let s_ := add(shr(sub(4, u32_), i_), shr(64, shl(32, state_))) // Bucket slot.
                let o_ := shl(add(4, u32_), and(i_, shr(u32_, 15))) // Bucket slot offset (bits).
                let m_ := sub(shl(shl(u32_, 16), 1), 1) // Value mask.
                _value := and(m_, shr(o_, sload(s_)))
                _value := xor(i_, mul(xor(i_, sub(_value, 1)), iszero(iszero(_value))))
            }
            function _set(u32_, state_, i_, value_) {
                let s_ := add(shr(sub(4, u32_), i_), shr(64, shl(32, state_))) // Bucket slot.
                let o_ := shl(add(4, u32_), and(i_, shr(u32_, 15))) // Bucket slot offset (bits).
                let m_ := sub(shl(shl(u32_, 16), 1), 1) // Value mask.
                let v_ := sload(s_) // Bucket slot value.
                value_ := mul(iszero(eq(i_, value_)), add(value_, 1))
                sstore(s_, xor(v_, shl(o_, and(m_, xor(shr(o_, v_), value_)))))
            }
            let state := sload($.slot) // The packed value at `$`.
            let shuffled := and(0xffffffff, state) // Number of elements shuffled.
            let n := shr(224, state) // Length of `$`.
            let remainder := sub(n, shuffled) // Number of elements left to shuffle.
            if iszero(remainder) {
                mstore(0x00, 0x51065f79) // `LazyShuffleFinished()`.
                revert(0x1c, 0x04)
            }
            mstore(0x00, randomness) // (Re)hash the randomness so that we don't
            mstore(0x20, shuffled) // need to expect guarantees on its distribution.
            let index := add(mod(keccak256(0x00, 0x40), remainder), shuffled)
            chosen := _get(gt(n, 0xfffe), state, index)
            _set(gt(n, 0xfffe), state, index, _get(gt(n, 0xfffe), state, shuffled))
            _set(gt(n, 0xfffe), state, shuffled, chosen)
            sstore($.slot, add(1, state)) // Increment the `numShuffled` by 1, and store it.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Reinterpret cast to an uint256 array.
    function _toUints(int256[] memory a) private pure returns (uint256[] memory casted) {
        /// @solidity memory-safe-assembly
        assembly {
            casted := a
        }
    }

    /// @dev Reinterpret cast to an uint256 array.
    function _toUints(address[] memory a) private pure returns (uint256[] memory casted) {
        /// @solidity memory-safe-assembly
        assembly {
            // As any address written to memory will have the upper 96 bits
            // of the word zeroized (as per Solidity spec), we can directly
            // compare these addresses as if they are whole uint256 words.
            casted := a
        }
    }
}
