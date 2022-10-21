// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for generating psuedorandom numbers.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibPRNG.sol)
library LibPRNG {
    /// @dev Returns the next psuedorandom state.
    /// The input `state` can be any uint256 number, including 0.
    /// All bits of the returned state pass the NIST Statistical Test Suite.
    function next(uint256 state) internal pure returns (uint256 randomness) {
        // We simply use `keccak256` for a great balance between
        // runtime gas costs, bytecode size, and statistical properties.
        //
        // A high-quality LCG with a 32-byte state
        // is only about 30% more gas efficient during runtime,
        // but requires a 32-byte multiplier, which can cause bytecode bloat
        // when this function is inlined.
        //
        // Using this method is about 2x more efficient than
        // `uint256(keccak256(abi.encode(state)))`.
        assembly {
            mstore(0x00, state)
            randomness := keccak256(0x00, 0x20)
        }
    }
}
