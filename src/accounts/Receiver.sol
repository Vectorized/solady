// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Receiver mixin for ETH and safe-transferred ERC721 and ERC1155 tokens.
/// @author Solady (https://github.com/Vectorized/solady/blob/main/src/accounts/Receiver.sol)
///
/// @dev Note:
/// - Handles all ERC721 and ERC1155 token safety callbacks.
/// - Collapses function table gas overhead and code size.
/// - Utilizes fallback so unknown calldata will pass on.
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
            // Shift to the calldata `msg.sig`.
            // Compare with token magic values.
            let s := shr(224, calldataload(0))
            // `onERC721Received`.
            if eq(s, 0x150b7a02) {
                mstore(0x20, s) // Load into memory slot.
                return(0x3c, 0x20) // Return `msg.sig`.
            }
            // `onERC1155Received`.
            if eq(s, 0xf23a6e61) {
                mstore(0x20, s) // Load into memory slot.
                return(0x3c, 0x20) // Return `msg.sig`.
            }
            // `onERC1155BatchReceived`.
            if eq(s, 0xbc197c81) {
                mstore(0x20, s) // Load into memory slot.
                return(0x3c, 0x20) // Return `msg.sig`.
            }
        }
    }
}
