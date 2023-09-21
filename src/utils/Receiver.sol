// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Optimized token callback handler using a unified fallback function.
/// @author Solady (https://github.com/Vectorized/solady/blob/main/src/utils/Receiver.sol)
///
/// @dev Note:
/// - Handles ERC721 and ERC1155 token callbacks.
/// - Optimizes for gas by using a single fallback function to handle multiple selectors,
///   avoiding the overhead of a selector table.
abstract contract Receiver {
    /// @dev Accepts incoming Ether.
    receive() external payable virtual {}

    /// @dev Fallback function for handling ERC721 and ERC1155 `safeTransferFrom()` callbacks.
    fallback() external virtual {
        /// @solidity memory-safe-assembly
        assembly {
            let s := shr(224, calldataload(0))
            // `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
            if eq(s, 0x150b7a02) {
                mstore(0x20, s)
                return(0x3c, 0x20)
            }
            // `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes))")`.
            if eq(s, 0xf23a6e61) {
                mstore(0x20, s)
                return(0x3c, 0x20)
            }
            // `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes))"`.
            if eq(s, 0xbc197c81) {
                mstore(0x20, s)
                return(0x3c, 0x20)
            }
        }
    }
}
