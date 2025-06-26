// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library to encode strings in Base58.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Base58.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Base58.sol)
library Base58 {
    /// @dev Encodes `data` into a base58 string.
    function encode(bytes memory data) internal pure returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            let l := mload(data) // `data.length`.
            let b := add(data, 0x20) // Start of `data` bytes.
            let z := 0 // Number of leading zero bytes in `data`.
            for {} lt(byte(0, mload(add(b, z))), lt(z, l)) {} { z := add(1, z) }

            // Start the output offset by an over-estimate of the length.
            let o := add(add(mload(0x40), 0x21), add(z, div(mul(sub(l, z), 8351), 6115)))
            let e := o

            let limbs := o
            let limbsEnd := limbs

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

            // Use the scratch space for the lookup. We'll restore 0x40 later.
            mstore(0x1f, "123456789ABCDEFGHJKLMNPQRSTUVWXY")
            mstore(0x3f, "Zabcdefghijkmnopqrstuvwxyz")

            if iszero(eq(limbs, limbsEnd)) {
                for {} 1 {} {
                    let anyNonZero := 0
                    for { let i := limbs } 1 {} {
                        if mload(i) {
                            anyNonZero := 1
                            break
                        }
                        i := add(i, 0x20)
                        if eq(i, limbsEnd) { break }
                    }
                    if iszero(anyNonZero) { break }

                    let carry := 0
                    for { let i := limbs } 1 {} {
                        let acc := add(shl(248, carry), mload(i))
                        mstore(i, div(acc, 58))
                        carry := mod(acc, 58)
                        i := add(i, 0x20)
                        if eq(i, limbsEnd) { break }
                    }
                    o := sub(o, 1)
                    mstore8(o, mload(carry))
                }
                for { let i := 0 } iszero(eq(i, z)) { i := add(i, 1) } {
                    o := sub(o, 1)
                    mstore8(o, 49) // '1' in ASCII.
                }
            }
            let n := sub(e, o) // Compute the final length.
            result := sub(o, 0x20) // Move back one word for the length.
            mstore(result, n) // Store the length.
            mstore(add(add(result, 0x20), n), 0) // Zeroize the slot after the bytes.
            mstore(0x40, add(add(result, 0x40), n)) // Allocate memory.
        }
    }
}
