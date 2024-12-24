# LibRLP

Library for RLP encoding and CREATE address computation.






<!-- customintro:start --><!-- customintro:end -->

## Structs

### List

```solidity
struct List {
    // Do NOT modify the `_data` directly.
    uint256 _data;
}
```

A pointer to a RLP item list in memory.

## Create Address Prediction

### computeAddress(address,uint256)

```solidity
function computeAddress(address deployer, uint256 nonce)
    internal
    pure
    returns (address deployed)
```

Returns the address where a contract will be stored if deployed via   
`deployer` with `nonce` using the `CREATE` opcode.   
For the specification of the Recursive Length Prefix (RLP)   
encoding scheme, please refer to p. 19 of the Ethereum Yellow Paper   
(https://ethereum.github.io/yellowpaper/paper.pdf)   
and the Ethereum Wiki (https://eth.wiki/fundamentals/rlp).   
Based on the EIP-161 (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-161.md)   
specification, all contract accounts on the Ethereum mainnet are initiated with   
`nonce = 1`. Thus, the first contract address created by another contract   
is calculated with a non-zero nonce.   
The theoretical allowed limit, based on EIP-2681   
(https://eips.ethereum.org/EIPS/eip-2681), for an account nonce is 2**64-2.   
Caution! This function will NOT check that the nonce is within the theoretical range.   
This is for performance, as exceeding the range is extremely impractical.   
It is the user's responsibility to ensure that the nonce is valid   
(e.g. no dirty bits after packing / unpacking).   
This is equivalent to:   
`address(uint160(uint256(keccak256(LibRLP.p(deployer).p(nonce).encode()))))`.   
Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.

## Rlp Encoding Operations

Note:   
- addresses are treated like byte strings of length 20, agnostic of leading zero bytes.   
- uint256s are converted to byte strings, stripped of leading zero bytes, and encoded.   
- bools are converted to uint256s (`b ? 1 : 0`), then encoded with the uint256.   
- For bytes1 to bytes32, you must manually convert them to bytes memory   
  with `abi.encodePacked(x)` before encoding.

### p()

```solidity
function p() internal pure returns (List memory result)
```

Returns a new empty list.

### p(uint256)

```solidity
function p(uint256 x) internal pure returns (List memory result)
```

Returns a new list with `x` as the only element. Equivalent to `LibRLP.p().p(x)`.

### p(address)

```solidity
function p(address x) internal pure returns (List memory result)
```

Returns a new list with `x` as the only element. Equivalent to `LibRLP.p().p(x)`.

### p(bool)

```solidity
function p(bool x) internal pure returns (List memory result)
```

Returns a new list with `x` as the only element. Equivalent to `LibRLP.p().p(x)`.

### p(bytes)

```solidity
function p(bytes memory x) internal pure returns (List memory result)
```

Returns a new list with `x` as the only element. Equivalent to `LibRLP.p().p(x)`.

### p(List)

```solidity
function p(List memory x) internal pure returns (List memory result)
```

Returns a new list with `x` as the only element. Equivalent to `LibRLP.p().p(x)`.

### p(List,uint256)

```solidity
function p(List memory list, uint256 x)
    internal
    pure
    returns (List memory result)
```

Appends `x` to `list`. Returns `list` for function chaining.

### p(List,address)

```solidity
function p(List memory list, address x)
    internal
    pure
    returns (List memory result)
```

Appends `x` to `list`. Returns `list` for function chaining.

### p(List,bool)

```solidity
function p(List memory list, bool x)
    internal
    pure
    returns (List memory result)
```

Appends `x` to `list`. Returns `list` for function chaining.

### p(List,bytes)

```solidity
function p(List memory list, bytes memory x)
    internal
    pure
    returns (List memory result)
```

Appends `x` to `list`. Returns `list` for function chaining.

### p(List,List)

```solidity
function p(List memory list, List memory x)
    internal
    pure
    returns (List memory result)
```

Appends `x` to `list`. Returns `list` for function chaining.

### encode(List)

```solidity
function encode(List memory list)
    internal
    pure
    returns (bytes memory result)
```

Returns the RLP encoding of `list`.

### encode(uint256)

```solidity
function encode(uint256 x) internal pure returns (bytes memory result)
```

Returns the RLP encoding of `x`.

### encode(address)

```solidity
function encode(address x) internal pure returns (bytes memory result)
```

Returns the RLP encoding of `x`.

### encode(bool)

```solidity
function encode(bool x) internal pure returns (bytes memory result)
```

Returns the RLP encoding of `x`.

### encode(bytes)

```solidity
function encode(bytes memory x)
    internal
    pure
    returns (bytes memory result)
```

Returns the RLP encoding of `x`.