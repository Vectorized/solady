// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for RLP encoding and CREATE address computation.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibRLP.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibRLP.sol)
library LibRLP {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev A pointer to a RLP item list.
    struct List {
        // Do NOT modify the `_data` directly.
        uint256 _data;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                 CREATE ADDRESS PREDICTION                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the address where a contract will be stored if deployed via
    /// `deployer` with `nonce` using the `CREATE` opcode.
    /// For the specification of the Recursive Length Prefix (RLP)
    /// encoding scheme, please refer to p. 19 of the Ethereum Yellow Paper
    /// (https://ethereum.github.io/yellowpaper/paper.pdf)
    /// and the Ethereum Wiki (https://eth.wiki/fundamentals/rlp).
    ///
    /// Based on the EIP-161 (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-161.md)
    /// specification, all contract accounts on the Ethereum mainnet are initiated with
    /// `nonce = 1`. Thus, the first contract address created by another contract
    /// is calculated with a non-zero nonce.
    ///
    /// The theoretical allowed limit, based on EIP-2681
    /// (https://eips.ethereum.org/EIPS/eip-2681), for an account nonce is 2**64-2.
    ///
    /// Caution! This function will NOT check that the nonce is within the theoretical range.
    /// This is for performance, as exceeding the range is extremely impractical.
    /// It is the user's responsibility to ensure that the nonce is valid
    /// (e.g. no dirty bits after packing / unpacking).
    ///
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function computeAddress(address deployer, uint256 nonce)
        internal
        pure
        returns (address deployed)
    {
        /// @solidity memory-safe-assembly
        assembly {
            for {} 1 {} {
                // The integer zero is treated as an empty byte string,
                // and as a result it only has a length prefix, 0x80,
                // computed via `0x80 + 0`.

                // A one-byte integer in the [0x00, 0x7f] range uses its
                // own value as a length prefix,
                // there is no additional `0x80 + length` prefix that precedes it.
                if iszero(gt(nonce, 0x7f)) {
                    mstore(0x00, deployer)
                    // Using `mstore8` instead of `or` naturally cleans
                    // any dirty upper bits of `deployer`.
                    mstore8(0x0b, 0x94)
                    mstore8(0x0a, 0xd6)
                    // `shl` 7 is equivalent to multiplying by 0x80.
                    mstore8(0x20, or(shl(7, iszero(nonce)), nonce))
                    deployed := keccak256(0x0a, 0x17)
                    break
                }
                let i := 8
                // Just use a loop to generalize all the way with minimal bytecode size.
                for {} shr(i, nonce) { i := add(i, 8) } {}
                // `shr` 3 is equivalent to dividing by 8.
                i := shr(3, i)
                // Store in descending slot sequence to overlap the values correctly.
                mstore(i, nonce)
                mstore(0x00, shl(8, deployer))
                mstore8(0x1f, add(0x80, i))
                mstore8(0x0a, 0x94)
                mstore8(0x09, add(0xd6, i))
                deployed := keccak256(0x09, add(0x17, i))
                break
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  RLP ENCODING OPERATIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Appends `x` to `l`.
    function p(List memory l, uint256 x) internal pure returns (List memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(result, shl(48, x))
            let v := or(shr(mload(l), result), mload(l))
            let tail := shr(40, v)
            mstore(l, xor(shl(40, xor(tail, result)), v)) // Update the tail.
            mstore(tail, or(mload(tail), result)) // Make the previous tail point to `m`.
            if shr(208, x) {
                let m := mload(0x40)
                mstore(m, x)
                mstore(0x40, add(m, 0x20))
                mstore(result, shl(40, or(1, shl(8, m))))
            }
            result := l
        }
    }

    /// @dev Appends `x` to `l`.
    function p(List memory l, bytes memory x) internal pure returns (List memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(result, shl(40, or(2, shl(8, x))))
            let v := or(shr(mload(l), result), mload(l))
            let tail := shr(40, v)
            mstore(l, xor(shl(40, xor(tail, result)), v)) // Update the tail.
            mstore(tail, or(mload(tail), result)) // Make the previous tail point to `m`.
            result := l
        }
    }

    /// @dev Appends `x` to `l`.
    function p(List memory l, List memory x) internal pure returns (List memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(result, shl(40, or(3, shl(8, x))))
            let v := or(shr(mload(l), result), mload(l))
            let tail := shr(40, v)
            mstore(l, xor(shl(40, xor(tail, result)), v)) // Update the tail.
            mstore(tail, or(mload(tail), result)) // Make the previous tail point to `m`.
            result := l
        }
    }

    /// @dev Returns the RLP encoding of `l`.
    function encode(List memory l) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            function encodeUint(x_, o_) -> _o {
                _o := add(o_, 1)
                if iszero(gt(x_, 0x7f)) {
                    mstore8(o_, or(x_, shl(7, iszero(x_)))) // Copy `x_`.
                    leave
                }
                let r_ := shl(7, lt(0xffffffffffffffffffffffffffffffff, x_))
                r_ := or(r_, shl(6, lt(0xffffffffffffffff, shr(r_, x_))))
                r_ := or(r_, shl(5, lt(0xffffffff, shr(r_, x_))))
                r_ := or(r_, shl(4, lt(0xffff, shr(r_, x_))))
                r_ := or(shr(3, r_), lt(0xff, shr(r_, x_)))
                mstore8(o_, add(r_, 0x81)) // Store the prefix.
                mstore(_o, shl(shl(3, xor(31, r_)), x_)) // Copy `x_`.
                _o := add(add(1, r_), _o)
            }
            function encodeBytes(x_, o_, c_) -> _o {
                _o := add(o_, 1)
                let f_ := mload(add(0x20, x_))
                let n_ := mload(x_)
                if iszero(gt(n_, 55)) {
                    if iszero(and(eq(1, n_), lt(byte(0, f_), 0x80))) {
                        mstore8(o_, add(n_, c_)) // Store the prefix.
                        mstore(add(0x21, o_), mload(add(0x40, x_)))
                        mstore(_o, f_)
                        _o := add(n_, _o)
                        leave
                    }
                    mstore(o_, f_) // Copy `x_`.
                    leave
                }
                returndatacopy(returndatasize(), returndatasize(), shr(32, n_))
                let r_ := add(1, add(lt(0xff, n_), add(lt(0xffff, n_), lt(0xffffff, n_))))
                mstore(o_, shl(248, add(r_, add(c_, 55)))) // Store the prefix.
                // Copy `x`.
                let i_ := add(r_, _o)
                _o := add(i_, n_)
                for { let d_ := sub(add(0x20, x_), i_) } 1 {} {
                    mstore(i_, mload(add(d_, i_)))
                    i_ := add(i_, 0x20)
                    if iszero(lt(i_, _o)) { break }
                }
                mstore(o_, or(mload(o_), shl(sub(248, shl(3, r_)), n_))) // Store the prefix.
            }
            function encodeList(l_, o_) -> _o {
                if iszero(mload(l_)) {
                    mstore8(o_, 0xc0)
                    _o := add(o_, 1)
                    leave
                }
                let j_ := add(o_, 0x20)
                for { let h_ := l_ } 1 {} {
                    h_ := and(mload(h_), 0xffffffffff)
                    if iszero(h_) { break }
                    let t_ := byte(26, mload(h_))
                    if iszero(gt(t_, 1)) {
                        if iszero(t_) {
                            j_ := encodeUint(shr(48, mload(h_)), j_)
                            continue
                        }
                        j_ := encodeUint(mload(shr(48, mload(h_))), j_)
                        continue
                    }
                    if eq(t_, 2) {
                        j_ := encodeBytes(shr(48, mload(h_)), j_, 0x80)
                        continue
                    }
                    j_ := encodeList(shr(48, mload(h_)), j_)
                }
                mstore(o_, sub(j_, add(o_, 0x20)))
                _o := encodeBytes(o_, o_, 0xc0)
            }
            result := mload(0x40)
            let begin := add(result, 0x20)
            let end := encodeList(l, begin)
            mstore(result, sub(end, begin))
            mstore(end, 0)
            mstore(0x40, add(end, 0x20))
        }
    }

    /// @dev Returns the RLP encoding of `x`.
    function encode(uint256 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            for {} 1 {} {
                result := mload(0x40)
                if iszero(gt(x, 0x7f)) {
                    mstore(result, 1) // Store the length of `result`.
                    mstore(add(result, 0x20), shl(248, or(shl(7, iszero(x)), x))) // Copy `x`.
                    mstore(0x40, add(result, 0x40)) // Allocate memory for `result`.
                    break
                }
                let r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
                r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
                r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
                r := or(r, shl(4, lt(0xffff, shr(r, x))))
                r := add(1, or(shr(3, r), lt(0xff, shr(r, x))))
                mstore(add(result, 0x40), 0) // Zeroize the slot after `result`.
                mstore(add(r, add(result, 1)), x) // Copy `x`.
                mstore(add(result, 1), add(r, 0x80)) // Store the prefix.
                mstore(result, add(1, r)) // Store the length of `result`.
                mstore(0x40, add(result, 0x60)) // Allocate memory for `result`.
                break
            }
        }
    }

    /// @dev Returns the RLP encoding of `x`.
    function encode(bytes memory x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := x
            for {} iszero(and(eq(1, mload(x)), lt(byte(0, mload(add(x, 0x20))), 0x80))) {} {
                result := mload(0x40)
                let n := mload(x)
                if iszero(gt(n, 55)) {
                    mstore(0x40, add(result, 0x60))
                    mstore(add(0x41, result), mload(add(0x40, x)))
                    mstore(add(0x21, result), mload(add(0x20, x)))
                    mstore(add(1, result), add(n, 0x80)) // Store the prefix.
                    mstore(result, add(1, n)) // Store the length of `result`.
                    mstore(add(add(result, 0x21), n), 0) // Zeroize the slot after `result`.
                    break
                }
                returndatacopy(returndatasize(), returndatasize(), shr(32, n))
                let r := add(1, add(lt(0xff, n), add(lt(0xffff, n), lt(0xffffff, n))))
                // Copy `x`.
                let i := add(r, add(0x21, result))
                let end := add(i, n)
                for { let d := sub(add(0x20, x), i) } 1 {} {
                    mstore(i, mload(add(d, i)))
                    i := add(i, 0x20)
                    if iszero(lt(i, end)) { break }
                }
                mstore(add(r, add(1, result)), n) // Store the prefix.
                mstore(add(1, result), add(r, 0xb7)) // Store the prefix.
                mstore(result, add(r, add(1, n))) // Store the length of `result`.
                mstore(end, 0) // Zeroize the slot after `result`.
                mstore(0x40, add(end, 0x20)) // Allocate memory.
                break
            }
        }
    }
}
