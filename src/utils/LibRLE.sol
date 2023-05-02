// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for the Run-length encoding.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibString.sol)
library LibRLE {
    /// @dev Returns encoded into RLE of the given bytes
    /// See: https://en.wikipedia.org/wiki/Run-length_encoding
    function encode(bytes memory str) internal pure returns (bytes memory r) {
        /// @solidity memory-safe-assembly
        assembly {
            if mload(str) {
                let strEnd := add(str, add(0x20, mload(str)))
                let count := 1 // counting for the char
                r := mload(0x40) // free-memory pointer
                let p := add(r, 0x20)

                let prevChar := byte(0, mload(add(str, 0x20)))

                for { let i := add(str, 0x20) } 1 {} {
                    i := add(i, 1)

                    let currChar := byte(0, mload(i))

                    if and(eq(prevChar, currChar), lt(count, 255)) {
                        count := add(count, 1)
                        continue
                    }

                    mstore8(p, count)
                    mstore8(add(p, 1), prevChar)

                    p := add(p, 2)

                    if iszero(lt(i, strEnd)) {
                        mstore8(sub(p, 2), sub(count, sub(i, strEnd)))
                        break
                    }

                    count := 1
                    prevChar := currChar
                }
                // store length of the `r`
                mstore(r, sub(sub(p, 0x20), r))
                // updates free memory pointer
                mstore(0x40, shl(5, shr(5, add(p, 31))))
            }
        }
    }

    /// @dev Returns decoded bytes encoded using {encode}.
    /// Note: If `str` is not output of {encode}, the output behavious is undenfined.
    function decode(bytes memory str) internal pure returns (bytes memory r) {
        /// @solidity memory-safe-assembly
        assembly {
            if mload(str) {
                let strEnd := add(str, add(0x20, mload(str)))

                r := mload(0x40)

                let p := add(r, 0x20)

                for { let i := add(str, 0x20) } 1 {} {
                    let n := byte(0, mload(i))
                    let char := byte(1, mload(i))

                    for { let j } 1 {} {
                        mstore8(p, char)
                        p := add(p, 1)
                        j := add(j, 1)
                        if eq(n, j) { break }
                    }

                    i := add(i, 2)

                    if iszero(lt(i, strEnd)) { break }
                }
                // store length of the `r`
                mstore(r, sub(sub(p, 0x20), r))
                // updates free memory pointer
                mstore(0x40, shl(5, shr(5, add(p, 31))))
            }
        }
    }
}
