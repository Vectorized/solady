// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for generating Merkle trees.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/MerkleTreeLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/merkle-tree/blob/master/src/core.ts)
/// @dev Note:
/// - Leaves are NOT auto hashed. Note that some libraries hash the leaves by default.
///   We leave it up to you to decide if this is needed.
///   If your leaves are 64 bytes long, do hash them first for safety.
///   See: https://www.rareskills.io/post/merkle-tree-second-preimage-attack
/// - Leaves are NOT auto globally sorted. Note that some libraries sort the leaves by default.
/// - The pair hash is pair-sorted-keccak256, which works out-of-the-box with `MerkleProofLib`.
/// - This library is NOT equivalent to OpenZeppelin or Murky.
///   Equivalence is NOT required if you are just using this for pure Solidity testing.
///   May be relevant for differential testing between Solidity vs external libraries.
library MerkleTreeLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev At least 1 leaf is required to build the tree.
    error MerkleTreeLeavesEmpty();

    /// @dev Attempt to access a node with an out-of-bounds index.
    /// Check if the tree has been built and has sufficient leaves and nodes.
    error MerkleTreeOutOfBoundsAccess();

    /// @dev Leaf indices for multi proof must be strictly ascending and not empty.
    error MerkleTreeInvalidLeafIndices();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   MERKLE TREE OPERATIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Builds and return a complete Merkle tree.
    /// To make it a full Merkle tree, use `build(pad(leaves))`.
    function build(bytes32[] memory leaves) internal pure returns (bytes32[] memory tree) {
        /// @solidity memory-safe-assembly
        assembly {
            tree := mload(0x40) // `nodes`.
            let l := mload(leaves)
            if iszero(l) {
                mstore(0x00, 0xe7171dc4) // `MerkleTreeLeavesEmpty()`.
                revert(0x1c, 0x04)
            }
            let n := sub(add(l, l), 1)
            mstore(tree, n) // `.length`.
            let nodes := add(tree, 0x20)
            let f := add(nodes, shl(5, n))
            mstore(0x40, f) // Allocate memory.
            let e := add(0x20, shl(5, l))
            for { let i := 0x20 } 1 {} {
                mstore(sub(f, i), mload(add(leaves, i)))
                i := add(i, 0x20)
                if eq(i, e) { break }
            }
            if iszero(lt(l, 2)) {
                for { let i := shl(5, sub(l, 2)) } 1 {} {
                    let left := mload(add(nodes, add(add(i, i), 0x20)))
                    let right := mload(add(nodes, add(add(i, i), 0x40)))
                    let c := shl(5, lt(left, right))
                    mstore(c, right)
                    mstore(xor(c, 0x20), left)
                    mstore(add(nodes, i), keccak256(0x00, 0x40))
                    if iszero(i) { break }
                    i := sub(i, 0x20)
                }
            }
        }
    }

    /// @dev Returns the root.
    function root(bytes32[] memory tree) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(add(0x20, tree))
            if iszero(mload(tree)) {
                mstore(0x00, 0x7a856a38) // `MerkleTreeOutOfBoundsAccess()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Returns the number of leaves.
    function numLeaves(bytes32[] memory tree) internal pure returns (uint256) {
        unchecked {
            return tree.length - (tree.length >> 1);
        }
    }

    /// @dev Returns the number of internal nodes.
    function numInternalNodes(bytes32[] memory tree) internal pure returns (uint256) {
        return tree.length >> 1;
    }

    /// @dev Returns the leaf at `leafIndex`.
    function leaf(bytes32[] memory tree, uint256 leafIndex)
        internal
        pure
        returns (bytes32 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(tree)
            if iszero(lt(leafIndex, sub(n, shr(1, n)))) {
                mstore(0x00, 0x7a856a38) // `MerkleTreeOutOfBoundsAccess()`.
                revert(0x1c, 0x04)
            }
            result := mload(add(tree, shl(5, sub(n, leafIndex))))
        }
    }

    /// @dev Returns the leaves at `leafIndices`.
    function gatherLeaves(bytes32[] memory tree, uint256[] memory leafIndices)
        internal
        pure
        returns (bytes32[] memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            let l := mload(leafIndices)
            mstore(result, l) // `.length`.
            let d := sub(leafIndices, result)
            let n := mload(tree)
            let o := add(result, 0x20)
            for { let i := 0 } iszero(eq(i, l)) { i := add(i, 1) } {
                let j := add(o, shl(5, i))
                let leafIndex := mload(add(j, d))
                if iszero(lt(leafIndex, sub(n, shr(1, n)))) {
                    mstore(0x00, 0x7a856a38) // `MerkleTreeOutOfBoundsAccess()`.
                    revert(0x1c, 0x04)
                }
                mstore(j, mload(add(tree, shl(5, sub(n, leafIndex)))))
            }
            mstore(0x40, add(o, shl(5, l))) // Allocate memory.
        }
    }

    /// @dev Returns the proof for the leaf at `leafIndex`.
    function leafProof(bytes32[] memory tree, uint256 leafIndex)
        internal
        pure
        returns (bytes32[] memory result)
    {
        uint256 nodeIndex;
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(tree)
            nodeIndex := sub(n, add(1, leafIndex))
            if iszero(lt(leafIndex, sub(n, shr(1, n)))) { nodeIndex := not(0) }
        }
        result = nodeProof(tree, nodeIndex);
    }

    /// @dev Returns the proof for the node at `nodeIndex`.
    /// This function can be used to prove the existence of internal nodes.
    function nodeProof(bytes32[] memory tree, uint256 nodeIndex)
        internal
        pure
        returns (bytes32[] memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            if iszero(lt(nodeIndex, mload(tree))) {
                mstore(0x00, 0x7a856a38) // `MerkleTreeOutOfBoundsAccess()`.
                revert(0x1c, 0x04)
            }
            let o := add(result, 0x20)
            for { let i := nodeIndex } i { i := shr(1, sub(i, 1)) } {
                mstore(o, mload(add(tree, shl(5, add(i, shl(1, and(1, i)))))))
                o := add(o, 0x20)
            }
            mstore(0x40, o) // Allocate memory.
            mstore(result, shr(5, sub(o, add(result, 0x20)))) // Store length.
        }
    }

    /// @dev Returns proof and corresponding flags for multiple leaves.
    /// The `leafIndices` must be non-empty and sorted in strictly ascending order.
    function multiProofForLeaves(bytes32[] memory tree, uint256[] memory leafIndices)
        internal
        pure
        returns (bytes32[] memory proof, bool[] memory flags)
    {
        /// @solidity memory-safe-assembly
        assembly {
            function gen(leafIndices_, t_, proof_, flags_) -> _flagsLen, _proofLen {
                let q_ := mload(0x40) // Circular buffer.
                let c_ := mload(leafIndices_) // Capacity of circular buffer.
                let e_ := c_ // End index of circular buffer.
                let b_ := 0 // Start index of circular buffer.
                for {
                    let n_ := mload(t_) // Num nodes.
                    let l_ := sub(n_, shr(1, n_)) // Num leaves.
                    let p_ := not(0)
                    let i_ := 0
                } 1 {} {
                    let j_ := mload(add(add(leafIndices_, 0x20), shl(5, i_))) // Leaf index.
                    if flags_ {
                        if iszero(lt(j_, l_)) {
                            mstore(0x00, 0x7a856a38) // `MerkleTreeOutOfBoundsAccess()`.
                            revert(0x1c, 0x04)
                        }
                        if iszero(sgt(j_, p_)) {
                            mstore(0x00, 0xe9729976) // `MerkleTreeInvalidLeafIndices()`.
                            revert(0x1c, 0x04)
                        }
                        p_ := j_
                    }
                    mstore(add(q_, shl(5, i_)), sub(n_, add(1, j_)))
                    i_ := add(i_, 1)
                    if eq(i_, e_) { break }
                }
                for {} 1 {} {
                    if iszero(lt(b_, e_)) { break }
                    let j_ := mload(add(q_, shl(5, mod(b_, c_)))) // Current.
                    if iszero(j_) { break }
                    b_ := add(b_, 1)
                    let s_ := add(j_, shl(1, and(j_, 1))) // Sibling (+1).
                    _flagsLen := add(_flagsLen, 0x20)
                    let f_ := and(eq(s_, add(1, mload(add(q_, shl(5, mod(b_, c_)))))), lt(b_, e_))
                    b_ := add(b_, f_)
                    _proofLen := add(_proofLen, shl(5, iszero(f_)))
                    if flags_ {
                        mstore(add(flags_, _flagsLen), f_)
                        mstore(mul(iszero(f_), add(proof_, _proofLen)), mload(add(t_, shl(5, s_))))
                    }
                    mstore(add(q_, shl(5, mod(e_, c_))), shr(1, sub(j_, 1)))
                    e_ := add(e_, 1)
                }
                _proofLen := shr(5, _proofLen)
                _flagsLen := shr(5, _flagsLen)
            }
            if iszero(mload(leafIndices)) {
                mstore(0x00, 0xe9729976) // `MerkleTreeInvalidLeafIndices()`.
                revert(0x1c, 0x04)
            }
            let flagsLen, proofLen := gen(leafIndices, tree, 0x00, 0x00)
            proof := mload(0x40)
            mstore(proof, proofLen)
            flags := add(add(proof, 0x20), shl(5, proofLen))
            mstore(flags, flagsLen)
            mstore(0x40, add(add(flags, 0x20), shl(5, flagsLen))) // Allocate memory.
            flagsLen, proofLen := gen(leafIndices, tree, proof, flags)
        }
    }

    /// @dev Returns a copy of leaves, with the length padded to a power of 2.
    function pad(bytes32[] memory leaves, bytes32 defaultFill)
        internal
        pure
        returns (bytes32[] memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            let l := mload(leaves)
            let p := sub(l, 1)
            if iszero(lt(p, 0xffffffff)) {
                mstore(0x00, 0xe7171dc4) // `MerkleTreeLeavesEmpty()`.
                revert(0x1c, mul(iszero(l), 0x04)) // If `p > 2**32 - 1`, revert with empty.
            }
            p := or(shr(1, p), p)
            p := or(shr(2, p), p)
            p := or(shr(4, p), p)
            p := or(shr(8, p), p)
            p := add(1, or(shr(16, p), p)) // Supports up to `2**32 - 1`.
            mstore(result, p) // Store length.
            mstore(0x40, add(result, add(0x20, shl(5, p)))) // Allocate memory.
            let d := sub(result, leaves)
            let copyEnd := add(add(leaves, 0x20), shl(5, l))
            let end := add(add(leaves, 0x20), shl(5, p))
            mstore(0x00, defaultFill)
            for { let i := add(leaves, 0x20) } 1 {} {
                mstore(add(i, d), mload(mul(i, lt(i, copyEnd))))
                i := add(i, 0x20)
                if eq(i, end) { break }
            }
        }
    }

    /// @dev Equivalent to `pad(leaves, bytes32(0))`.
    function pad(bytes32[] memory leaves) internal pure returns (bytes32[] memory result) {
        result = pad(leaves, bytes32(0));
    }
}
