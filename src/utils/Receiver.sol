// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Universal transfer callback receiver using fallback returns of selector calldata.
/// @author Solady (https://github.com/Vectorized/solady/blob/main/src/utils/Receiver.sol)
///
/// @dev Note:
/// - Handles all ERC721 and ERC1155 token safety callbacks.
/// - Future-proofed for any selector-based callback check.
/// - Collapses function table gas overhead and code size.
abstract contract Receiver {
    /// @dev Accepts ether (ETH).
    /// Override to reject ETH
    /// or add custom logic.
    receive() external payable virtual {}

    /// @dev Unified fallback function.
    /// Override to reject or specify.
    fallback() external virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Shift and load the calldata `msg.sig`.
            mstore(0x20, shr(224, calldataload(0)))
            return(0x3C, 0x20) // Return `msg.sig`.
        }
    }
}
