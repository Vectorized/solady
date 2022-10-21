// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for generating psuedorandom numbers.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibPRNG.sol)
library LibPRNG {
    /// @dev Returns the next psuedorandom state.
    function next(uint256 state) internal pure returns (uint256 randomness) {
        // We simply use `keccak256` for the best balance between
        // runtime gas costs, bytecode size, and statistical guarantees.
        //
        // A high-quality LCG with a 32-byte state
        // is only about 30% more gas efficient during runtime,
        // but requires a 32-byte multiplier, which can cause bytecode bloat
        // when this function is inlined.
        //
        // If you are curious, you can try the following for yourself:
        // ```
        // let a := 0xd6aad120322a96acae4ccfaf5fcd4bbfda3f2f3001db6837c0981639faa68d8d
        // state := add(mul(state, a), 83)
        // randomness := xor(state, shr(128, state))
        // ``
        //
        // Using this method is about 2x more efficient than
        // `uint256(keccak256(abi.encode(state)))`.
        assembly {
            mstore(0x00, state)
            randomness := keccak256(0x00, 0x20)
        }
    }
}
