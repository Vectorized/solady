// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Optimized token callback handler via `fallback()`.
contract Receiver {
    fallback() external payable {
        assembly {
            // Shift right by 224 bits to get the function signature.
            let shiftedSig := shr(224, calldataload(0))

            // `keccak256("onERC721Received(address,address,uint256,bytes)")`.
            if eq(shiftedSig, 0x150b7a02) {
                mstore(0x00, shl(224, shiftedSig))
                return(0x00, 0x20)
            }

            // `keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")`.
            if eq(shiftedSig, 0xf23a6e61) {
                mstore(0x00, shl(224, shiftedSig))
                return(0x00, 0x20)
            }

            // `keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"`.
            if eq(shiftedSig, 0xbc197c81) {
                mstore(0x00, shl(224, shiftedSig))
                return(0x00, 0x20)
            }
        }
    }
}
