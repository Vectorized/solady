// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for comparing SemVer.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SemVerLib.sol)
library SemVerLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         COMPARISON                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns -1 if `a < b`, 0 if `a == b`, 1 if `a > b`.
    /// For efficiency, this is a forgiving, non-reverting parser:
    /// - Early returns if a strict order can be determined.
    /// - Skips the first byte if it is `v` (case insensitive).
    /// - If a strict order cannot be determined, returns 0.
    function cmp(bytes32 a, bytes32 b) internal pure returns (int256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            function mmp(i_, a_) -> _r, _o {
                for { _o := i_ } iszero(gt(sub(byte(_o, a_), 48), 9)) { _o := add(1, _o) } {
                    _r := add(mul(10, _r), sub(byte(_o, a_), 48))
                }
            }
            function pre(i_, a_) -> hasNonDigit_, _r, _o {
                mstore(0x00, 0)
                for { _o := i_ } 1 { _o := add(1, _o) } {
                    let c_ := byte(_o, a_)
                    if and(1, shr(c_, 0x480000000001)) { break } // '\x00', '.', '+'
                    let digit_ := sub(c_, 48)
                    hasNonDigit_ := or(hasNonDigit_, gt(digit_, 9))
                    _r := add(mul(10, _r), digit_)
                    mstore8(sub(_o, i_), c_)
                }
                mstore(shl(5, hasNonDigit_), _r) // Overwrite if it's numeric.
                _r := mload(0x00)
            }
            let x, i := mmp(or(eq(byte(0, a), 118), eq(byte(0, a), 86)), a) // 'v', 'V'
            let y, j := mmp(or(eq(byte(0, b), 118), eq(byte(0, b), 86)), b) // 'v', 'V'
            result := sub(gt(x, y), lt(x, y))
            for {} lt(result, or(eq(byte(i, a), 46), eq(byte(j, b), 46))) {} {
                x := 0
                y := 0
                if eq(byte(i, a), 46) { x, i := mmp(add(i, 1), a) } // `.`
                if eq(byte(j, b), 46) { y, j := mmp(add(j, 1), b) } // `.`
                result := sub(gt(x, y), lt(x, y))
            }
            if iszero(result) {
                let u := eq(byte(i, a), 45) // `-`
                let v := eq(byte(j, b), 45) // `-`
                result := sub(lt(u, v), gt(u, v))
                for {} lt(result, u) {} {
                    u, x, i := pre(add(i, 1), a)
                    v, y, j := pre(add(j, 1), b)
                    result := sub(gt(u, v), lt(u, v))
                    if result { break }
                    result := sub(gt(x, y), lt(x, y))
                    if result { break }
                    u := eq(byte(i, a), 46) // `.`
                    v := eq(byte(j, b), 46) // `.`
                    result := sub(gt(u, v), lt(u, v))
                }
            }
        }
    }
}
