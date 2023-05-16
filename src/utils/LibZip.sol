// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for compressing and decompressing bytes.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibZip.sol)
/// @author Calldata compression by clabby (https://github.com/clabby/op-kompressor)
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
                let z := 0 // Number of consecutive 0x00.
                let y := 0 // Number of consecutive 0xff.
                let end := add(data, mload(data))
                function rle(v_, o_, d_) -> _o, _d {
                    mstore(o_, 0)
                    mstore8(add(o_, 1), or(sub(d_, 1), and(128, v_)))
                    _o := add(o_, 2)
                }
                for {} iszero(eq(data, end)) {} {
                    data := add(data, 1)
                    let c := byte(31, mload(data))
                    if iszero(c) {
                        if y { o, y := rle(0xff, o, y) }
                        z := add(z, 1)
                        if eq(z, 128) { o, z := rle(0x00, o, 128) }
                        continue
                    }
                    if eq(c, 0xff) {
                        if z { o, z := rle(0x00, o, z) }
                        y := add(y, 1)
                        if eq(y, 32) { o, y := rle(0xff, o, 32) }
                        continue
                    }
                    if y { o, y := rle(0xff, o, y) }
                    if z { o, z := rle(0x00, o, z) }
                    mstore8(o, c)
                    o := add(o, 1)
                }
                if y { o, y := rle(0xff, o, y) }
                if z { o, z := rle(0x00, o, z) }
                // Bitwise negate the first 4 bytes.
                mstore(add(result, 4), xor(0xffffffff, mload(add(result, 4))))
                mstore(result, sub(o, add(result, 0x20))) // Store the length.
                mstore(o, 0) // Zeroize the slot after the string.
                mstore(0x40, and(add(o, 31), not(31))) // Allocate the memory.
            }
        }
    }

    /// @dev Returns the decompressed `data`.
    function cdDecompress(bytes memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            if mload(data) {
                result := mload(0x40)
                let o := add(result, 0x20)
                let s := add(data, 4)
                let v := mload(s)
                mstore(s, xor(0xffffffff, v)) // Bitwise negate the first 4 bytes.
                let end := add(data, mload(data))
                for {} lt(data, end) {} {
                    data := add(data, 1)
                    let c := byte(31, mload(data))
                    if iszero(c) {
                        data := add(data, 1)
                        let d := byte(31, mload(data))
                        // Fill with either 0xff or 0x00.
                        mstore(o, not(0))
                        if iszero(gt(d, 127)) { codecopy(o, codesize(), add(d, 1)) }
                        o := add(o, add(and(d, 127), 1))
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
            if iszero(calldatasize()) { return(calldatasize(), calldatasize()) }
            let o := 0
            let i := 0
            let f := shl(224, 0xffffffff) // For negating the first 4 bytes.
            for {} lt(i, calldatasize()) {} {
                let c := xor(byte(i, f), byte(0, calldataload(i)))
                i := add(i, 1)
                if iszero(c) {
                    let d := xor(byte(i, f), byte(0, calldataload(i)))
                    i := add(i, 1)
                    // Fill with either 0xff or 0x00.
                    mstore(o, not(0))
                    if iszero(gt(d, 127)) { codecopy(o, codesize(), add(d, 1)) }
                    o := add(o, add(and(d, 127), 1))
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
