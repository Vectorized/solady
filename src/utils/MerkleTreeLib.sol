// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Gas optimized verification of proof of inclusion for a leaf in a Merkle tree.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/MerkleTreeLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/merkle-tree/blob/master/src/core.ts)
/// @author Modified from Murky (https://github.com/dmfxyz/murky)
library MerkleTreeLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev A complete Merkle tree in memory.
    /// To make it a full Merkle tree, use `build(pad(leafs))`.
    struct MerkleTree {
        bytes32[] nodes;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev At least 1 leaf is required to build the tree.
    error MerkleTreeLeafsEmpty();

    /// @dev Attempt to access a node with an out-of-bounds index.
    /// Check if the tree has been built and has sufficient leafs and nodes.
    error MerkleTreeOutOfBoundsAccess();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   MERKLE TREE OPERATIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Builds the tree.
    /// If the tree has been already built, overwrites the existing tree.
    function build(MerkleTree memory t, bytes32[] memory leafs) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            let l := mload(leafs)
            if iszero(l) {
                mstore(0x00, 0x089aff6e) // `MerkleTreeLeafsEmpty()`.
                revert(0x1c, 0x04)
            }
            let n := sub(add(l, l), 1)
            let m := mload(0x40) // `nodes`.
            mstore(t, m) // Set `t.nodes`.
            mstore(m, n) // Store the length of the `nodes.length`.
            m := add(m, 0x20)
            let f := add(m, shl(5, n))
            mstore(0x40, f) // Allocate memory.
            let e := add(0x20, shl(5, l))
            for { let i := 0x20 } 1 {} {
                mstore(sub(f, i), mload(add(leafs, i)))
                i := add(i, 0x20)
                if eq(i, e) { break }
            }
            if iszero(lt(l, 2)) {
                for { let i := shl(5, sub(l, 2)) } 1 {} {
                    let left := mload(add(m, add(add(i, i), 0x20)))
                    let right := mload(add(m, add(add(i, i), 0x40)))
                    let c := shl(5, lt(left, right))
                    mstore(c, right)
                    mstore(xor(c, 0x20), left)
                    mstore(add(m, i), keccak256(0x00, 0x40))
                    if iszero(i) { break }
                    i := sub(i, 0x20)
                }
            }
        }
    }

    /// @dev Returns the root.
    function root(MerkleTree memory t) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(add(0x20, mload(t)))
            if iszero(mload(mload(t))) {
                mstore(0x00, 0x7a856a38) // `MerkleTreeOutOfBoundsAccess()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Returns the number of leafs.
    function numLeafs(MerkleTree memory t) internal pure returns (uint256) {
        unchecked {
            return t.nodes.length - (t.nodes.length >> 1);
        }
    }

    /// @dev Returns the number of internal nodes.
    function numInternalNodes(MerkleTree memory t) internal pure returns (uint256) {
        return t.nodes.length >> 1;
    }

    /// @dev Returns the leaf at `leafIndex`.
    function leaf(MerkleTree memory t, uint256 leafIndex) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(mload(t))
            if iszero(lt(leafIndex, sub(n, shr(1, n)))) {
                mstore(0x00, 0x7a856a38) // `MerkleTreeOutOfBoundsAccess()`.
                revert(0x1c, 0x04)
            }
            result := mload(add(mload(t), shl(5, sub(n, leafIndex))))
        }
    }

    /// @dev Returns the proof for the leaf at `leafIndex`.
    function leafProof(MerkleTree memory t, uint256 leafIndex)
        internal
        pure
        returns (bytes32[] memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            let n := mload(mload(t))
            if iszero(lt(leafIndex, sub(n, shr(1, n)))) {
                mstore(0x00, 0x7a856a38) // `MerkleTreeOutOfBoundsAccess()`.
                revert(0x1c, 0x04)
            }
            let o := add(result, 0x20)
            for { let i := sub(n, add(1, leafIndex)) } i { i := shr(1, sub(i, 1)) } {
                mstore(o, mload(add(mload(t), shl(5, add(i, shl(1, and(1, i)))))))
                o := add(o, 0x20)
            }
            mstore(0x40, o) // Allocate memory.
            mstore(result, shr(5, sub(o, add(result, 0x20)))) // Store length.
        }
    }

    /// @dev Returns the proof for the node at `nodeIndex`.
    /// This function can be used to prove the existence of internal nodes.
    function nodeProof(MerkleTree memory t, uint256 nodeIndex)
        internal
        pure
        returns (bytes32[] memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            if iszero(lt(nodeIndex, mload(mload(t)))) {
                mstore(0x00, 0x7a856a38) // `MerkleTreeOutOfBoundsAccess()`.
                revert(0x1c, 0x04)
            }
            let o := add(result, 0x20)
            for { let i := nodeIndex } i { i := shr(1, sub(i, 1)) } {
                mstore(o, mload(add(mload(t), shl(5, add(i, shl(1, and(1, i)))))))
                o := add(o, 0x20)
            }
            mstore(0x40, o) // Allocate memory.
            mstore(result, shr(5, sub(o, add(result, 0x20)))) // Store length.
        }
    }

    /// @dev Returns a copy of leafs, with the length padded to a power of 2.
    function pad(bytes32[] memory leafs, bytes32 defaultFill)
        internal
        pure
        returns (bytes32[] memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            let l := mload(leafs)
            if iszero(l) {
                mstore(0x00, 0x089aff6e) // `MerkleTreeLeafsEmpty()`.
                revert(0x1c, 0x04)
            }
            let p := 1 // Padded length.
            for {} lt(p, l) {} { p := add(p, p) }
            mstore(result, p) // Store length.
            mstore(0x40, add(result, add(0x20, shl(5, p)))) // Allocate memory.
            let d := sub(result, leafs)
            let copyEnd := add(add(leafs, 0x20), shl(5, l))
            let end := add(add(leafs, 0x20), shl(5, p))
            mstore(0x00, defaultFill)
            for { let i := add(leafs, 0x20) } 1 {} {
                mstore(add(i, d), mload(mul(i, lt(i, copyEnd))))
                i := add(i, 0x20)
                if eq(i, end) { break }
            }
        }
    }
}
