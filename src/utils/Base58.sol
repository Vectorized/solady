// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library to encode strings in Base58.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Base58.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Base58.sol)
library Base58 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CUSTOM ERRORS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev An unrecognized character or overflow was encountered during decoding.
    error Base58DecodingError();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    ENCODING / DECODING                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Encodes `data` into a Base58 string.
    function encode(bytes memory data) internal pure returns (string memory result) {
        uint256 l = data.length;
        if (l == uint256(0)) return result;
        /// @solidity memory-safe-assembly
        assembly {
            let b := add(data, 0x20) // Start of `data` bytes.
            let z := 0 // Number of leading zero bytes in `data`.
            // Count leading zero bytes.
            for {} lt(byte(0, mload(add(b, z))), lt(z, l)) {} { z := add(1, z) }

            // Start the output offset by an over-estimate of the length.
            let o := add(add(mload(0x40), 0x21), add(z, div(mul(sub(l, z), 8351), 6115)))
            let e := o

            let limbs := o
            let limbsEnd := limbs
            // Populate the uint248 limbs.
            for {
                let i := mod(l, 31)
                if i {
                    mstore(limbsEnd, shr(shl(3, add(1, sub(31, i))), mload(b)))
                    limbsEnd := add(limbsEnd, 0x20)
                }
            } lt(i, l) { i := add(i, 31) } {
                mstore(limbsEnd, shr(8, mload(add(b, i))))
                limbsEnd := add(limbsEnd, 0x20)
            }
            // Use the extended scratch space for the lookup. We'll restore 0x40 later.
            mstore(0x1f, "123456789ABCDEFGHJKLMNPQRSTUVWXY")
            mstore(0x3f, "Zabcdefghijkmnopqrstuvwxyz")

            let w := not(0) // -1.
            mstore(limbsEnd, w) // Put sentinel after limbs for faster looping.
            for {} 1 {} {
                let i := limbs
                for {} iszero(mload(i)) { i := add(i, 0x20) } {}
                if iszero(not(mload(i))) { break } // Break if all limbs are zero.

                let carry := 0
                for { i := limbs } 1 {} {
                    let acc := add(shl(248, carry), mload(i))
                    mstore(i, div(acc, 58))
                    carry := mod(acc, 58)
                    i := add(i, 0x20)
                    if eq(i, limbsEnd) { break }
                }
                o := add(o, w)
                mstore8(o, mload(carry))
            }
            let j := o
            for { o := sub(o, z) } gt(j, o) {} {
                j := sub(j, 0x20)
                mstore(j, mul(div(w, 0xff), 49)) // '1111...1111' in ASCII.
            }

            let n := sub(e, o) // Compute the final length.
            result := sub(o, 0x20) // Move back one word for the length.
            mstore(result, n) // Store the length.
            mstore(add(add(result, 0x20), n), 0) // Zeroize the slot after the bytes.
            mstore(0x40, add(add(result, 0x40), n)) // Allocate memory.
        }
    }

    /// @dev Encodes the `data` word into a Base58 string.
    function encodeWord(bytes32 data) internal pure returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            let o := add(mload(0x40), 0x4c) // 32 for word, 44 for maximum possible length.
            let e := o

            // Use the extended scratch space for the lookup. We'll restore 0x40 later.
            mstore(0x1f, "123456789ABCDEFGHJKLMNPQRSTUVWXY")
            mstore(0x3f, "Zabcdefghijkmnopqrstuvwxyz")

            let w := not(0) // -1.
            let z := shl(5, iszero(data)) // Number of leading zeroes in `data`.
            if iszero(z) {
                for { let v := data } v { v := div(v, 58) } {
                    o := add(o, w)
                    mstore8(o, mload(mod(v, 58)))
                }
                for {} iszero(byte(z, data)) { z := add(z, 1) } {} // Just loop, `z` is often tiny.
            }
            if z { mstore(sub(o, 0x20), mul(div(w, 0xff), 49)) } // '1111...1111' in ASCII.
            o := sub(o, z)

            let n := sub(e, o) // Compute the final length.
            result := sub(o, 0x20) // Move back one word for the length.
            mstore(result, n) // Store the length.
            mstore(add(add(result, 0x20), n), 0) // Zeroize the slot after the bytes.
            mstore(0x40, add(add(result, 0x40), n)) // Allocate memory.
        }
    }

    /// @dev Decodes `encoded`, a Base58 string, into the original bytes.
    function decode(string memory encoded) internal pure returns (bytes memory result) {
        uint256 n = bytes(encoded).length;
        if (n == uint256(0)) return result;
        /// @solidity memory-safe-assembly
        assembly {
            let s := add(encoded, 0x20)
            let z := 0 // Number of leading '1' in `data`.
            // Count leading '1'.
            for {} and(eq(49, byte(0, mload(add(s, z)))), lt(z, n)) {} { z := add(1, z) }

            // Start the output offset by an over-estimate of the length.
            let o := add(add(mload(0x40), 0x21), add(z, div(mul(sub(n, z), 7323), 10000)))
            let e := o
            let limbs := o
            let limbsEnd := limbs
            let limbMask := shr(8, not(0))
            // Use the extended scratch space for the lookup. We'll restore 0x40 later.
            mstore(0x2a, 0x30313233343536373839)
            mstore(0x20, 0x1718191a1b1c1d1e1f20ffffffffffff2122232425262728292a2bff2c2d2e2f)
            mstore(0x00, 0x000102030405060708ffffffffffffff090a0b0c0d0e0f10ff1112131415ff16)

            for { let j := 0 } 1 {} {
                let c := sub(byte(0, mload(add(s, j))), 49)
                // Check if the input character is valid.
                if iszero(and(shl(c, 1), 0x3fff7ff03ffbeff01ff)) {
                    mstore(0x00, 0xe8fad793) // `Base58DecodingError()`.
                    revert(0x1c, 0x04)
                }
                let carry := byte(0, mload(c))
                for { let i := limbs } iszero(eq(i, limbsEnd)) { i := add(i, 0x20) } {
                    let acc := add(carry, mul(58, mload(i)))
                    mstore(i, and(limbMask, acc))
                    carry := shr(248, acc)
                }
                // Carry will always be < 58.
                if carry {
                    mstore(limbsEnd, carry)
                    limbsEnd := add(limbsEnd, 0x20)
                }
                j := add(j, 1)
                if eq(j, n) { break }
            }
            // Copy and compact the uint248 limbs.
            for { let i := limbs } iszero(eq(i, limbsEnd)) { i := add(i, 0x20) } {
                o := sub(o, 31)
                mstore(sub(o, 1), mload(i))
            }
            // Strip any leading zeros from the limbs.
            for {} lt(byte(0, mload(o)), lt(o, e)) {} { o := add(o, 1) }
            o := sub(o, z) // Move back for the leading zero bytes.
            calldatacopy(o, calldatasize(), z) // Fill the leading zero bytes.

            let l := sub(e, o) // Compute the final length.
            result := sub(o, 0x20) // Move back one word for the length.
            mstore(result, l) // Store the length.
            mstore(add(add(result, 0x20), l), 0) // Zeroize the slot after the bytes.
            mstore(0x40, add(add(result, 0x40), l)) // Allocate memory.
        }
    }

    /// @dev Decodes `encoded`, a Base58 string, into the original word.
    function decodeWord(string memory encoded) internal pure returns (bytes32 result) {
        uint256 n = bytes(encoded).length;
        if (n == uint256(0)) return result;
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            let s := add(encoded, 0x20)
            let t := add(1, div(not(0), 58)) // Overflow threshold for multiplication.
            // Use the extended scratch space for the lookup. We'll restore 0x40 later.
            mstore(0x2a, 0x30313233343536373839)
            mstore(0x20, 0x1718191a1b1c1d1e1f20ffffffffffff2122232425262728292a2bff2c2d2e2f)
            mstore(0x00, 0x000102030405060708ffffffffffffff090a0b0c0d0e0f10ff1112131415ff16)

            for { let j := 0 } 1 {} {
                let c := sub(byte(0, mload(add(s, j))), 49)
                let p := mul(result, 58)
                let acc := add(byte(0, mload(c)), p)
                // Check if the input character is valid.
                if iszero(and(0x3fff7ff03ffbeff01ff, shl(c, lt(lt(acc, p), lt(result, t))))) {
                    mstore(0x00, 0xe8fad793) // `Base58DecodingError()`.
                    revert(0x1c, 0x04)
                }
                result := acc
                j := add(j, 1)
                if eq(j, n) { break }
            }
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }
}
