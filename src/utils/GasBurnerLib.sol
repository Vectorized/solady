// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for burning gas without reverting.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/GasBurnerLib.sol)
library GasBurnerLib {
    /// @dev Burns about `x` amount of gas.
    /// Intended for Contract Secured Revenue (CSR).
    /// For best results, pass in a admin-controlled dynamic value instead of a hardcoded one.
    /// This is so that you can adjust your contract as needed depending on market conditions,
    /// and to give your users a leeway just in case.
    function burn(uint256 x) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, or(1, x))
            let n := mul(gt(x, 120), div(x, 88))
            // We use keccak256 instead of blake2f precompile for better widespread compatibility.
            for { let i := 0 } iszero(eq(i, n)) { i := add(i, 1) } {
                mstore(0x00, keccak256(0x10, 0x10)) // Yes.
            }
            if iszero(mload(0x00)) { invalid() }
        }
    }
}
