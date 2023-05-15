// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for compressing and decompressing bytes.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibZip.sol)
/// @author Calldata compression by clabby
/// (https://github.com/clabby/op-kompressor)
library LibZip {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    CALLDATA OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the compressed `data`.
    function cdCompress(bytes memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            if mload(data) {
                result := mload(0x40)
                let o := add(result, 0x20)
                let z := 0 // Number of consecutive zeros.
                let end := add(data, mload(data))
                for {} iszero(eq(data, end)) {} {
                    data := add(data, 1)
                    let c := and(0xff, mload(data))
                    // If the byte is zero, run length encode.
                    if iszero(c) {
                        if eq(z, 0xff) {
                            mstore(o, shl(240, 0xff))
                            o := add(o, 2)
                            z := 0
                            continue
                        }
                        z := add(z, 1)
                        continue
                    }
                    if z {
                        mstore(o, shl(240, sub(z, 1)))
                        o := add(o, 2)
                    }
                    mstore8(o, c)
                    o := add(o, 1)
                    z := 0
                }
                if z {
                    mstore(o, shl(240, sub(z, 1)))
                    o := add(o, 2)
                }
                // Bitwise negate the first 4 bytes.
                let s := add(result, 4)
                mstore(s, xor(0xffffffff, mload(s)))
                mstore(result, sub(o, add(result, 0x20))) // Store the length.
                mstore(o, 0) // Zeroize the slot after the string.
                mstore(0x40, and(add(o, 31), not(31))) // Allocate the memory.
            }
        }
    }

    /// @dev Returns the uncompressed `data`.
    function cdDecompress(bytes memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            if mload(data) {
                result := mload(0x40)
                let o := add(result, 0x20)
                let s := add(data, 4)
                let v := mload(s)
                // Bitwise negate the first 4 bytes.
                mstore(s, xor(0xffffffff, v))
                let end := add(data, mload(data))
                for {} iszero(eq(data, end)) {} {
                    data := add(data, 1)
                    let c := and(0xff, mload(data))
                    if iszero(c) {
                        data := add(data, 1)
                        let z := add(and(0xff, mload(data)), 1)
                        codecopy(o, codesize(), z) // Fill with zeros.
                        o := add(o, z)
                        continue
                    }
                    mstore8(o, c)
                    o := add(o, 1)
                }
                mstore(result, sub(o, add(result, 0x20))) // Store the length.
                mstore(o, 0) // Zeroize the slot after the string.
                mstore(0x40, and(add(o, 31), not(31))) // Allocate the memory.
                mstore(s, v) // Restore the first 4 bytes.
            }
        }
    }

    /// @dev To be called in the `receive` and `fallback` functions.
    /// ```
    ///     receive() external payable { LibZip.cdFallback(); }
    ///     fallback() external payable { LibZip.cdFallback(); }
    /// ```
    /// For efficiency, this function will directly return the results, terminating the context.
    /// If called internally, it must be called at the end of the function.
    function cdFallback() internal {
        /// @solidity memory-safe-assembly
        assembly {
            let o := 0
            let i := 0
            let f := shl(224, 0xffffffff)
            for {} lt(i, calldatasize()) {} {
                let c := xor(byte(i, f), byte(0, calldataload(i)))
                i := add(i, 1)
                if iszero(c) {
                    let z := add(xor(byte(i, f), byte(0, calldataload(i))), 1)
                    i := add(i, 1)
                    codecopy(o, codesize(), z) // Fill with zeros.
                    o := add(o, z)
                    continue
                }
                mstore8(o, c)
                o := add(o, 1)
            }
            if iszero(delegatecall(gas(), address(), 0x00, o, 0x00, 0x00)) {
                returndatacopy(0x00, 0x00, returndatasize())
                revert(0x00, returndatasize())
            }
            returndatacopy(0x00, 0x00, returndatasize())
            return(0x00, returndatasize())
        }
    }
}
