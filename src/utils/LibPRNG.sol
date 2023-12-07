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
    function gaussianWad(PRNG memory prng) internal pure returns (int256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            function U() -> _r {
                if iszero(mload(0x20)) {
                    _r := keccak256(0x00, 0x20)
                    mstore(0x00, _r)
                    mstore(0x20, 1)
                    _r := shr(129, _r)
                    leave
                }
                mstore(0x20, 0)
                _r := and(0x7fffffffffffffffffffffffffffffff, mload(0x00))
            }
            function T(y_) -> _r {
                for {} 1 {} {
                    let z_ := U()
                    if iszero(lt(z_, y_)) { break }
                    y_ := U()
                    if iszero(lt(y_, z_)) {
                        _r := 1
                        break
                    }
                }
            }
            mstore(0x20, 0)
            mstore(0x00, mload(prng)) // Put state into scratch space.
            for {} 1 {} {
                let n := 0
                for {} 1 { n := add(n, 1) } {
                    let y := U()
                    if iszero(shr(126, y)) { if iszero(T(y)) { break } }
                }
                let k := 0
                let k2 := 0
                for {} iszero(or(gt(k2, n), eq(n, k2))) { k := add(1, k) } {
                    k2 := add(k2, add(add(k, k), 1))
                }
                if iszero(eq(n, k2)) { continue }
                let j := U()
                let h := k
                for {} 1 {} {
                    h := sub(k, 1)
                    if iszero(add(k, 1)) { break }
                    let y := U()
                    if iszero(lt(y, j)) { continue } 
                    if iszero(T(y)) { break } 
                }
                if iszero(slt(h, 0)) { continue }
                n := 0
                for { let y := 0 } 1 {} {
                    let d := keccak256(0x00, 0x20)
                    mstore(0x00, d)
                    if iszero(and(1, shr(127, d))) { break }
                    let z := shr(129, d)
                    y := and(0x7fffffffffffffffffffffffffffffff, d)
                    if iszero(lt(y, j)) { break }
                    if iszero(lt(z, xor(y, mul(iszero(n), xor(j, y))))) { break }
                    y := z
                    n := add(n, 1)
                }
                mstore(0x20, 0)
                if and(n, 1) { continue }
                j := add(div(j, 170141183460469231901), mul(k, 1000000000000000000))
                if iszero(and(1, shr(128, mload(0x00)))) { j := sub(0, j) }
                result := j    
                break
            }
            mstore(prng, mload(0x00)) // Restore state.
        }
    }
}
