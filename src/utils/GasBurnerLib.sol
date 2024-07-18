// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for burning gas without reverting.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/GasBurnerLib.sol)
///
/// @dev Intended for Contract Secured Revenue (CSR).
///
/// Recommendation: for the amount of gas to burn,
/// pass in an admin-controlled dynamic value instead of a hardcoded one.
/// This is so that you can adjust your contract as needed depending on market conditions,
/// and to give you and your users a leeway in case the L2 chain change the rules.
library GasBurnerLib {
    /// @dev Burns approximately `x` amount of gas.
    function burnPure(uint256 x) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x10, or(1, x))
            let n := mul(gt(x, 120), div(x, 91))
            // We use keccak256 instead of blake2f precompile for better widespread compatibility.
            for { let i := 0 } iszero(eq(i, n)) { i := add(i, 1) } {
                mstore(0x10, keccak256(0x10, 0x10)) // Yes.
            }
            if iszero(mload(0x10)) { invalid() }
        }
    }

    /// @dev Burns approximately `x` amount of gas.
    function burnView(uint256 x) internal view {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mul(gt(x, 3500), div(x, 3200))
            let m := mload(0x40)
            mstore(0x00, xor(address(), xor(origin(), timestamp())))
            mstore(0x00, keccak256(0x00, 0x20))
            mstore(0x20, 27) // `v`.
            mstore(0x40, 45) // `r`.
            mstore(0x60, 10) // `s`.
            for { let i := 0 } iszero(eq(i, n)) { i := add(i, 1) } {
                pop(staticcall(gas(), 1, 0x00, 0x81, 0x00, 0x20))
            }
            if iszero(mload(0x10)) { invalid() }
            mstore(0x60, 0) // Restore the zero slot.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Burns approximately `x` amount of gas.
    function burn(uint256 x) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let n := mul(gt(x, 18000), div(x, 17700))
            mstore(m, xor(address(), xor(origin(), timestamp())))
            codecopy(add(m, 0x20), and(keccak256(m, 0x20), 0xff), 2080)
            for { let i := 0 } 1 { i := add(i, 1) } {
                let h := keccak256(m, 0x21)
                mstore(m, h)
                codecopy(add(m, and(h, 0x7ff)), and(0xff, h), 0xff)
                mstore(add(m, 2048), not(h))
                if eq(i, n) {
                    n := shr(3, mod(x, 17700))
                    n := mul(gt(n, 0x30), sub(n, 0x30))
                    mstore(add(m, n), h)
                    log0(m, add(n, 0x20))
                    break
                }
                log0(m, 2080)
            }
        }
    }
}
