// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for compressing and decompressing bytes.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibZip.sol)
/// @author Calldata compression by clabby (https://github.com/clabby/op-kompressor)
/// @author FastLZ by ariya (https://github.com/ariya/FastLZ)
library LibZip {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     FAST LZ OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the compressed `data`.
    function flzCompress(bytes memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            function ms8(d_, v_) -> _r {
                mstore8(d_, v_)
                _r := add(d_, 1)
            }
            function u24(p_) -> _r {
                let w := mload(p_)
                _r := or(shl(16, byte(2, w)), or(shl(8, byte(1, w)), byte(0, w)))
            }
            function cmp(p_, q_, r_) -> _r {
                _r := p_
                for { let t := 0 } and(lt(q_, r_), iszero(t)) {} {
                    t := byte(0, xor(mload(p_), mload(q_)))
                    p_ := add(p_, 1)
                    q_ := add(q_, 1)
                }
                _r := sub(p_, _r)
            }
            function literals(runs_, src_, dest_) -> _r {
                for { _r := dest_ } iszero(lt(runs_, 0x20)) { runs_ := sub(runs_, 0x20) } {
                    mstore(ms8(_r, 31), mload(src_))
                    _r := add(_r, 0x21)
                    src_ := add(src_, 0x20)
                }
                if iszero(runs_) { leave }
                mstore(ms8(_r, sub(runs_, 1)), mload(src_))
                _r := add(1, add(_r, runs_))
            }
            function match(l_, d_, o_) -> _r {
                for { d_ := sub(d_, 1) } iszero(lt(l_, 263)) { l_ := sub(l_, 262) } {
                    o_ := ms8(ms8(ms8(o_, add(224, shr(8, d_))), 253), and(0xff, d_))
                }
                if iszero(lt(l_, 7)) {
                    _r := ms8(ms8(ms8(o_, add(224, shr(8, d_))), sub(l_, 7)), and(0xff, d_))
                    leave
                }
                _r := ms8(ms8(o_, add(shl(5, l_), shr(8, d_))), and(0xff, d_))
            }
            function setHash(i_, v_) {
                let p := add(mload(0x40), shl(2, i_))
                mstore(p, xor(mload(p), shl(224, xor(shr(224, mload(p)), v_))))
            }
            function hash(v_) -> _r {
                _r := and(shr(19, mul(2654435769, v_)), 0x1fff)
            }
            codecopy(mload(0x40), codesize(), 0x8000) // Zeroize the hashmap.
            let ip := add(data, 0x20)
            let op := add(mload(0x40), 0x8000)
            let a := ip
            let ipStart := add(data, 0x20)
            let ipLimit := sub(add(ipStart, mload(data)), 13)
            for { ip := add(2, ip) } lt(ip, ipLimit) {} {
                let r := 0
                let d := 0
                for {} 1 {} {
                    let s := u24(ip)
                    let h := hash(s)
                    r := add(ipStart, shr(224, mload(add(mload(0x40), shl(2, h)))))
                    setHash(h, sub(ip, ipStart))
                    d := sub(ip, r)
                    if iszero(lt(ip, ipLimit)) { break }
                    ip := add(ip, 1)
                    if iszero(gt(d, 0x1fff)) { if eq(s, u24(r)) { break } }
                }
                if iszero(lt(ip, ipLimit)) { break }
                ip := sub(ip, 1)
                if gt(ip, a) { op := literals(sub(ip, a), a, op) }
                let l := cmp(add(r, 3), add(ip, 3), add(ipLimit, 9))
                op := match(l, d, op)
                ip := add(ip, l)
                setHash(hash(u24(ip)), sub(ip, ipStart))
                ip := add(ip, 1)
                setHash(hash(u24(ip)), sub(ip, ipStart))
                ip := add(ip, 1)
                a := ip
            }
            op := literals(sub(add(ipStart, mload(data)), a), a, op)
            result := mload(0x40)
            let t := add(mload(0x40), 0x8000)
            let n := sub(op, t)
            mstore(result, n) // Store the length.
            // Copy the result to compact the memory, overwriting the hashmap.
            let o := add(result, 0x20)
            for { let i := 0 } lt(i, n) { i := add(i, 0x20) } {
                mstore(add(o, i), mload(add(t, i)))
            }
            mstore(add(o, n), 0) // Zeroize the slot after the string.
            mstore(0x40, add(add(o, n), 0x20)) // Allocate the memory.
        }
    }

    /// @dev Returns the decompressed `data`.
    function flzDecompress(bytes memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            function append(output_, dest_, ofs_, len_) {
                let r := add(output_, sub(dest_, add(ofs_, 0x20)))
                let o := add(output_, dest_)
                for { let j := 0 } iszero(eq(j, len_)) { j := add(j, 1) } {
                    mstore8(add(o, j), mload(add(r, j)))
                }
            }
            let dest := 0
            let end := add(add(data, 0x20), mload(data))
            result := mload(0x40)
            let output := add(result, 0x20)
            for { data := add(data, 0x20) } lt(data, end) {} {
                let srcWord := mload(data)
                let srcValue := byte(0, srcWord)
                let t := shr(5, srcValue)
                if iszero(t) {
                    data := add(data, 1)
                    mstore(add(output, dest), mload(data))
                    data := add(data, add(1, srcValue))
                    dest := add(dest, add(1, srcValue))
                    continue
                }
                if iszero(lt(t, 7)) {
                    let ofs := add(shl(8, and(31, srcValue)), byte(2, srcWord))
                    let len := add(9, byte(1, srcWord))
                    data := add(data, 3)
                    append(output, dest, ofs, len)
                    dest := add(dest, len)
                    continue
                }
                let ofs := add(shl(8, and(31, srcValue)), byte(1, srcWord))
                let len := add(2, t)
                data := add(data, 2)
                append(output, dest, ofs, len)
                dest := add(dest, len)
            }
            mstore(result, dest) // Store the length.
            let o := add(add(result, 0x20), dest)
            mstore(o, 0) // Zeroize the slot after the string.
            mstore(0x40, add(o, 0x20)) // Allocate the memory.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    CALLDATA OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the compressed `data`.
    function cdCompress(bytes memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            function rle(v_, o_, d_) -> _o, _d {
                mstore(o_, 0)
                mstore8(add(o_, 1), or(sub(d_, 1), and(0x80, v_)))
                _o := add(o_, 2)
            }
            if mload(data) {
                result := mload(0x40)
                let o := add(result, 0x20)
                let z := 0 // Number of consecutive 0x00.
                let y := 0 // Number of consecutive 0xff.
                for { let end := add(data, mload(data)) } iszero(eq(data, end)) {} {
                    data := add(data, 1)
                    let c := byte(31, mload(data))
                    if iszero(c) {
                        if y { o, y := rle(0xff, o, y) }
                        z := add(z, 1)
                        if eq(z, 0x80) { o, z := rle(0x00, o, 0x80) }
                        continue
                    }
                    if eq(c, 0xff) {
                        if z { o, z := rle(0x00, o, z) }
                        y := add(y, 1)
                        if eq(y, 0x20) { o, y := rle(0xff, o, 0x20) }
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
                mstore(0x40, add(o, 0x20)) // Allocate the memory.
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
                for { let end := add(data, mload(data)) } lt(data, end) {} {
                    data := add(data, 1)
                    let c := byte(31, mload(data))
                    if iszero(c) {
                        data := add(data, 1)
                        let d := byte(31, mload(data))
                        // Fill with either 0xff or 0x00.
                        mstore(o, not(0))
                        if iszero(gt(d, 0x7f)) { codecopy(o, codesize(), add(d, 1)) }
                        o := add(o, add(and(d, 0x7f), 1))
                        continue
                    }
                    mstore8(o, c)
                    o := add(o, 1)
                }
                mstore(result, sub(o, add(result, 0x20))) // Store the length.
                mstore(o, 0) // Zeroize the slot after the string.
                mstore(0x40, add(o, 0x20)) // Allocate the memory.
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
            let f := shl(224, 0xffffffff) // For negating the first 4 bytes.
            for { let i := 0 } lt(i, calldatasize()) {} {
                let c := xor(byte(i, f), byte(0, calldataload(i)))
                i := add(i, 1)
                if iszero(c) {
                    let d := xor(byte(i, f), byte(0, calldataload(i)))
                    i := add(i, 1)
                    // Fill with either 0xff or 0x00.
                    mstore(o, not(0))
                    if iszero(gt(d, 0x7f)) { codecopy(o, codesize(), add(d, 1)) }
                    o := add(o, add(and(d, 0x7f), 1))
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
