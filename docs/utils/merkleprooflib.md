# MerkleProofLib

Gas optimized verification of proof of inclusion for a leaf in a Merkle tree.






<!-- customintro:start --><!-- customintro:end -->

## Merkle Proof Verification Operations

### verify(bytes32[],bytes32,bytes32)

```solidity
function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf)
    internal
    pure
    returns (bool isValid)
```

Returns whether `leaf` exists in the Merkle tree with `root`, given `proof`.

### verifyCalldata(bytes32[],bytes32,bytes32)

```solidity
function verifyCalldata(
    bytes32[] calldata proof,
    bytes32 root,
    bytes32 leaf
) internal pure returns (bool isValid)
```

Returns whether `leaf` exists in the Merkle tree with `root`, given `proof`.

### verifyMultiProof(bytes32[],bytes32,bytes32[],bool[])

```solidity
function verifyMultiProof(
    bytes32[] memory proof,
    bytes32 root,
    bytes32[] memory leafs,
    bool[] memory flags
) internal pure returns (bool isValid)
```

Returns whether all `leafs` exist in the Merkle tree with `root`,   
given `proof` and `flags`.   

<b>Note:</b>

- Breaking the invariant `flags.length == (leafs.length - 1) + proof.length`   
  will always return false.   
- The sum of the lengths of `proof` and `leafs` must never overflow.   
- Any non-zero word in the `flags` array is treated as true.   
- The memory offset of `proof` must be non-zero   
  (i.e. `proof` is not pointing to the scratch space).

### verifyMultiProofCalldata(bytes32[],bytes32,bytes32[],bool[])

```solidity
function verifyMultiProofCalldata(
    bytes32[] calldata proof,
    bytes32 root,
    bytes32[] calldata leafs,
    bool[] calldata flags
) internal pure returns (bool isValid)
```

Returns whether all `leafs` exist in the Merkle tree with `root`,   
given `proof` and `flags`.   

<b>Note:</b>

- Breaking the invariant `flags.length == (leafs.length - 1) + proof.length`   
  will always return false.   
- Any non-zero word in the `flags` array is treated as true.   
- The calldata offset of `proof` must be non-zero   
  (i.e. `proof` is from a regular Solidity function with a 4-byte selector).

## Empty Calldata Helpers

### emptyProof()

```solidity
function emptyProof() internal pure returns (bytes32[] calldata proof)
```

Returns an empty calldata bytes32 array.

### emptyLeafs()

```solidity
function emptyLeafs() internal pure returns (bytes32[] calldata leafs)
```

Returns an empty calldata bytes32 array.

### emptyFlags()

```solidity
function emptyFlags() internal pure returns (bool[] calldata flags)
```

Returns an empty calldata bool array.