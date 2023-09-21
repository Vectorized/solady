// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Optimized token callback handler via `fallback()`.
contract Receiver {
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
                mstore(0x00, shl(224, s))
                return(0x00, 0x20)
            }
            // `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes))"`.
            if eq(s, 0xbc197c81) {
                mstore(0x00, shl(224, s))
                return(0x00, 0x20)
            }
        }
    }
}
