// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for generating pseudorandom numbers.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibPRNG.sol)
library LibPRNG {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev A pseudorandom number state in memory.
    struct PRNG {
        uint256 state;
    }

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
    /// or for small enough moduli such that the bias is neligible,
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
            let n := 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff43 // Prime.
            let a := 0x100000000000000000000000000000051 // Prime and a primitive root of `n`.
            let m := 0x7fffffffffffffffffffffffffffffff
            let r := keccak256(prng, 0x20)
            mstore(prng, r)
            let p := and(m, r)
            let w := and(m, shr(127, r))
            if iszero(gt(w, p)) {
                // Passes the Kolmogorov-Smirnov test for 200k samples.
                // Gas usage varies, starting from about 199+ gas.
                for {} 1 {} {
                    r := mulmod(r, a, n)
                    let v := and(m, r)
                    if iszero(lt(v, w)) {
                        r := mulmod(r, a, n)
                        result := add(result, 1000000000000000000)
                        w := and(m, shr(127, r))
                        p := and(m, r)
                        if iszero(lt(w, p)) { break }
                        continue
                    }
                    w := and(m, shr(127, r))
                    if iszero(lt(w, v)) { break }
                }
            }
            result := add(result, div(p, 170141183460469231732))
        }
    }
}
