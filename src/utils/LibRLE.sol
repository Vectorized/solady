// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for the Run-length encoding.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibRLE.sol)
library LibRLE {
    /// @dev Encodes `data` using run-length encoding.
    /// See: https://en.wikipedia.org/wiki/Run-length_encoding
    function encode(bytes memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            if mload(data) {
                let dataEnd := add(data, add(0x20, mload(data)))
                let count := 1 // counting for the char
                result := mload(0x40) // free-memory pointer
                let p := add(result, 0x20)

                let prevChar := byte(0, mload(add(data, 0x20)))

                for { let i := add(data, 0x20) } 1 {} {
                    i := add(i, 1)

                    let currChar := byte(0, mload(i))

                    if and(eq(prevChar, currChar), lt(count, 255)) {
                        count := add(count, 1)
                        continue
                    }

                    mstore8(p, count)
                    mstore8(add(p, 1), prevChar)

                    p := add(p, 2)

                    if iszero(lt(i, dataEnd)) {
                        mstore8(sub(p, 2), sub(count, sub(i, dataEnd)))
                        break
                    }

                    count := 1
                    prevChar := currChar
                }
                // store length of the `result`
                mstore(result, sub(sub(p, 0x20), result))
                // updates free memory pointer
                mstore(0x40, shl(5, shr(5, add(p, 31))))
            }
        }
    }

    /// @dev Decodes RLE encoded `data`.
    /// Note: For performance reasons,
    /// this function will NOT revert on invalid `data` inputs.
    /// Outputs for invalid inputs will simply be undefined behaviour.
    /// It is the user's responsibility to ensure that the `data`
    /// is a valid RLE encoded string.
    function decode(bytes memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            if mload(data) {
                let dataEnd := add(data, add(0x20, mload(data)))

                result := mload(0x40)

                let p := add(result, 0x20)

                for { let i := add(data, 0x20) } 1 {} {
                    let n := byte(0, mload(i))
                    let char := byte(1, mload(i))

                    for { let j } 1 {} {
                        mstore8(p, char)
                        p := add(p, 1)
                        j := add(j, 1)
                        if eq(n, j) { break }
                    }

                    i := add(i, 2)

                    if iszero(lt(i, dataEnd)) { break }
                }
                // store length of the `result`
                mstore(result, sub(sub(p, 0x20), result))
                // updates free memory pointer
                mstore(0x40, shl(5, shr(5, add(p, 31))))
            }
        }
    }
}
