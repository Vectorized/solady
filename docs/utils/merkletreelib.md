# MerkleTreeLib

Library for generating Merkle trees.






<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### MerkleTreeLeafsEmpty()

```solidity
error MerkleTreeLeafsEmpty()
```

At least 1 leaf is required to build the tree.

### MerkleTreeOutOfBoundsAccess()

```solidity
error MerkleTreeOutOfBoundsAccess()
```

Attempt to access a node with an out-of-bounds index.   
Check if the tree has been built and has sufficient leafs and nodes.

### MerkleTreeInvalidLeafIndices()

```solidity
error MerkleTreeInvalidLeafIndices()
```

Leaf indices for multi proof must be strictly ascending and not empty.

## Merkle Tree Operations

### build(bytes32[])

```solidity
function build(bytes32[] memory leafs)
    internal
    pure
    returns (bytes32[] memory result)
```

Builds and return a complete Merkle tree.   
To make it a full Merkle tree, use `build(pad(leafs))`.

### root(bytes32[])

```solidity
function root(bytes32[] memory t) internal pure returns (bytes32 result)
```

Returns the root.

### numLeafs(bytes32[])

```solidity
function numLeafs(bytes32[] memory t) internal pure returns (uint256)
```

Returns the number of leafs.

### numInternalNodes(bytes32[])

```solidity
function numInternalNodes(bytes32[] memory t)
    internal
    pure
    returns (uint256)
```

Returns the number of internal nodes.

### leaf(bytes32[],uint256)

```solidity
function leaf(bytes32[] memory t, uint256 leafIndex)
    internal
    pure
    returns (bytes32 result)
```

Returns the leaf at `leafIndex`.

### leafProof(bytes32[],uint256)

```solidity
function leafProof(bytes32[] memory t, uint256 leafIndex)
    internal
    pure
    returns (bytes32[] memory result)
```

Returns the proof for the leaf at `leafIndex`.

### nodeProof(bytes32[],uint256)

```solidity
function nodeProof(bytes32[] memory t, uint256 nodeIndex)
    internal
    pure
    returns (bytes32[] memory result)
```

Returns the proof for the node at `nodeIndex`.   
This function can be used to prove the existence of internal nodes.

### leafsMultiProof(bytes32[],uint256[])

```solidity
function leafsMultiProof(bytes32[] memory t, uint256[] memory leafIndices)
    internal
    pure
    returns (bytes32[] memory proof, bool[] memory flags)
```

Returns proof and corresponding flags for multiple leafs.   
The `leafIndices` must be non-empty and sorted in strictly ascending order.

### pad(bytes32[],bytes32)

```solidity
function pad(bytes32[] memory leafs, bytes32 defaultFill)
    internal
    pure
    returns (bytes32[] memory result)
```

Returns a copy of leafs, with the length padded to a power of 2.