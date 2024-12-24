# EfficientHashLib

Library for efficiently performing keccak256 hashes.


<b>To avoid stack-too-deep, you can use:</b>

```
bytes32[] memory buffer = EfficientHashLib.malloc(10);
EfficientHashLib.set(buffer, 0, value0);
..
EfficientHashLib.set(buffer, 9, value9);
bytes32 finalHash = EfficientHashLib.hash(buffer);
```



<!-- customintro:start --><!-- customintro:end -->

## Malloc-less Hashing Operations

### hash(bytes32)

```solidity
function hash(bytes32 v0) internal pure returns (bytes32 result)
```

Returns `keccak256(abi.encode(v0))`.

### hash(uint256)

```solidity
function hash(uint256 v0) internal pure returns (bytes32 result)
```

Returns `keccak256(abi.encode(v0))`.

### hash(bytes32,bytes32)

```solidity
function hash(bytes32 v0, bytes32 v1)
    internal
    pure
    returns (bytes32 result)
```

Returns `keccak256(abi.encode(v0, v1))`.

### hash(uint256,uint256)

```solidity
function hash(uint256 v0, uint256 v1)
    internal
    pure
    returns (bytes32 result)
```

Returns `keccak256(abi.encode(v0, v1))`.

### hash(bytes32,bytes32,bytes32)

```solidity
function hash(bytes32 v0, bytes32 v1, bytes32 v2)
    internal
    pure
    returns (bytes32 result)
```

Returns `keccak256(abi.encode(v0, v1, v2))`.

### hash(uint256,uint256,uint256)

```solidity
function hash(uint256 v0, uint256 v1, uint256 v2)
    internal
    pure
    returns (bytes32 result)
```

Returns `keccak256(abi.encode(v0, v1, v2))`.

### hash(bytes32,bytes32,bytes32,bytes32)

```solidity
function hash(bytes32 v0, bytes32 v1, bytes32 v2, bytes32 v3)
    internal
    pure
    returns (bytes32 result)
```

Returns `keccak256(abi.encode(v0, v1, v2, v3))`.

### hash(uint256,uint256,uint256,uint256)

```solidity
function hash(uint256 v0, uint256 v1, uint256 v2, uint256 v3)
    internal
    pure
    returns (bytes32 result)
```

Returns `keccak256(abi.encode(v0, v1, v2, v3))`.

### hash(bytes32,bytes32,bytes32,bytes32,bytes32)

```solidity
function hash(bytes32 v0, bytes32 v1, bytes32 v2, bytes32 v3, bytes32 v4)
    internal
    pure
    returns (bytes32 result)
```

Returns `keccak256(abi.encode(v0, .., v4))`.

### hash(uint256,uint256,uint256,uint256,uint256)

```solidity
function hash(uint256 v0, uint256 v1, uint256 v2, uint256 v3, uint256 v4)
    internal
    pure
    returns (bytes32 result)
```

Returns `keccak256(abi.encode(v0, .., v4))`.

### hash(bytes32,bytes32,bytes32,bytes32,bytes32,bytes32)

```solidity
function hash(
    bytes32 v0,
    bytes32 v1,
    bytes32 v2,
    bytes32 v3,
    bytes32 v4,
    bytes32 v5
) internal pure returns (bytes32 result)
```

Returns `keccak256(abi.encode(v0, .., v5))`.

### hash(uint256,uint256,uint256,uint256,uint256,uint256)

```solidity
function hash(
    uint256 v0,
    uint256 v1,
    uint256 v2,
    uint256 v3,
    uint256 v4,
    uint256 v5
) internal pure returns (bytes32 result)
```

Returns `keccak256(abi.encode(v0, .., v5))`.

### hash(bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32)

```solidity
function hash(
    bytes32 v0,
    bytes32 v1,
    bytes32 v2,
    bytes32 v3,
    bytes32 v4,
    bytes32 v5,
    bytes32 v6
) internal pure returns (bytes32 result)
```

Returns `keccak256(abi.encode(v0, .., v6))`.

### hash(uint256,uint256,uint256,uint256,uint256,uint256,uint256)

```solidity
function hash(
    uint256 v0,
    uint256 v1,
    uint256 v2,
    uint256 v3,
    uint256 v4,
    uint256 v5,
    uint256 v6
) internal pure returns (bytes32 result)
```

Returns `keccak256(abi.encode(v0, .., v6))`.

### hash(bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32)

```solidity
function hash(
    bytes32 v0,
    bytes32 v1,
    bytes32 v2,
    bytes32 v3,
    bytes32 v4,
    bytes32 v5,
    bytes32 v6,
    bytes32 v7
) internal pure returns (bytes32 result)
```

Returns `keccak256(abi.encode(v0, .., v7))`.

### hash(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)

```solidity
function hash(
    uint256 v0,
    uint256 v1,
    uint256 v2,
    uint256 v3,
    uint256 v4,
    uint256 v5,
    uint256 v6,
    uint256 v7
) internal pure returns (bytes32 result)
```

Returns `keccak256(abi.encode(v0, .., v7))`.

### hash(bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32)

```solidity
function hash(
    bytes32 v0,
    bytes32 v1,
    bytes32 v2,
    bytes32 v3,
    bytes32 v4,
    bytes32 v5,
    bytes32 v6,
    bytes32 v7,
    bytes32 v8
) internal pure returns (bytes32 result)
```

Returns `keccak256(abi.encode(v0, .., v8))`.

### hash(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)

```solidity
function hash(
    uint256 v0,
    uint256 v1,
    uint256 v2,
    uint256 v3,
    uint256 v4,
    uint256 v5,
    uint256 v6,
    uint256 v7,
    uint256 v8
) internal pure returns (bytes32 result)
```

Returns `keccak256(abi.encode(v0, .., v8))`.

### hash(bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32)

```solidity
function hash(
    bytes32 v0,
    bytes32 v1,
    bytes32 v2,
    bytes32 v3,
    bytes32 v4,
    bytes32 v5,
    bytes32 v6,
    bytes32 v7,
    bytes32 v8,
    bytes32 v9
) internal pure returns (bytes32 result)
```

Returns `keccak256(abi.encode(v0, .., v9))`.

### hash(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)

```solidity
function hash(
    uint256 v0,
    uint256 v1,
    uint256 v2,
    uint256 v3,
    uint256 v4,
    uint256 v5,
    uint256 v6,
    uint256 v7,
    uint256 v8,
    uint256 v9
) internal pure returns (bytes32 result)
```

Returns `keccak256(abi.encode(v0, .., v9))`.

### hash(bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32)

```solidity
function hash(
    bytes32 v0,
    bytes32 v1,
    bytes32 v2,
    bytes32 v3,
    bytes32 v4,
    bytes32 v5,
    bytes32 v6,
    bytes32 v7,
    bytes32 v8,
    bytes32 v9,
    bytes32 v10
) internal pure returns (bytes32 result)
```

Returns `keccak256(abi.encode(v0, .., v10))`.

### hash(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)

```solidity
function hash(
    uint256 v0,
    uint256 v1,
    uint256 v2,
    uint256 v3,
    uint256 v4,
    uint256 v5,
    uint256 v6,
    uint256 v7,
    uint256 v8,
    uint256 v9,
    uint256 v10
) internal pure returns (bytes32 result)
```

Returns `keccak256(abi.encode(v0, .., v10))`.

### hash(bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32)

```solidity
function hash(
    bytes32 v0,
    bytes32 v1,
    bytes32 v2,
    bytes32 v3,
    bytes32 v4,
    bytes32 v5,
    bytes32 v6,
    bytes32 v7,
    bytes32 v8,
    bytes32 v9,
    bytes32 v10,
    bytes32 v11
) internal pure returns (bytes32 result)
```

Returns `keccak256(abi.encode(v0, .., v11))`.

### hash(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)

```solidity
function hash(
    uint256 v0,
    uint256 v1,
    uint256 v2,
    uint256 v3,
    uint256 v4,
    uint256 v5,
    uint256 v6,
    uint256 v7,
    uint256 v8,
    uint256 v9,
    uint256 v10,
    uint256 v11
) internal pure returns (bytes32 result)
```

Returns `keccak256(abi.encode(v0, .., v11))`.

### hash(bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32)

```solidity
function hash(
    bytes32 v0,
    bytes32 v1,
    bytes32 v2,
    bytes32 v3,
    bytes32 v4,
    bytes32 v5,
    bytes32 v6,
    bytes32 v7,
    bytes32 v8,
    bytes32 v9,
    bytes32 v10,
    bytes32 v11,
    bytes32 v12
) internal pure returns (bytes32 result)
```

Returns `keccak256(abi.encode(v0, .., v12))`.

### hash(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)

```solidity
function hash(
    uint256 v0,
    uint256 v1,
    uint256 v2,
    uint256 v3,
    uint256 v4,
    uint256 v5,
    uint256 v6,
    uint256 v7,
    uint256 v8,
    uint256 v9,
    uint256 v10,
    uint256 v11,
    uint256 v12
) internal pure returns (bytes32 result)
```

Returns `keccak256(abi.encode(v0, .., v12))`.

### hash(bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32,bytes32)

```solidity
function hash(
    bytes32 v0,
    bytes32 v1,
    bytes32 v2,
    bytes32 v3,
    bytes32 v4,
    bytes32 v5,
    bytes32 v6,
    bytes32 v7,
    bytes32 v8,
    bytes32 v9,
    bytes32 v10,
    bytes32 v11,
    bytes32 v12,
    bytes32 v13
) internal pure returns (bytes32 result)
```

Returns `keccak256(abi.encode(v0, .., v13))`.

### hash(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)

```solidity
function hash(
    uint256 v0,
    uint256 v1,
    uint256 v2,
    uint256 v3,
    uint256 v4,
    uint256 v5,
    uint256 v6,
    uint256 v7,
    uint256 v8,
    uint256 v9,
    uint256 v10,
    uint256 v11,
    uint256 v12,
    uint256 v13
) internal pure returns (bytes32 result)
```

Returns `keccak256(abi.encode(v0, .., v13))`.

## Bytes32 Buffer Hashing Operations

### hash(bytes32[])

```solidity
function hash(bytes32[] memory buffer)
    internal
    pure
    returns (bytes32 result)
```

Returns `keccak256(abi.encode(buffer[0], .., buffer[buffer.length - 1]))`.

### set(bytes32[],uint256,bytes32)

```solidity
function set(bytes32[] memory buffer, uint256 i, bytes32 value)
    internal
    pure
    returns (bytes32[] memory)
```

Sets `buffer[i]` to `value`, without a bounds check.   
Returns the `buffer` for function chaining.

### set(bytes32[],uint256,uint256)

```solidity
function set(bytes32[] memory buffer, uint256 i, uint256 value)
    internal
    pure
    returns (bytes32[] memory)
```

Sets `buffer[i]` to `value`, without a bounds check.   
Returns the `buffer` for function chaining.

### malloc(uint256)

```solidity
function malloc(uint256 n)
    internal
    pure
    returns (bytes32[] memory buffer)
```

Returns `new bytes32[](n)`, without zeroing out the memory.

### free(bytes32[])

```solidity
function free(bytes32[] memory buffer) internal pure
```

Frees memory that has been allocated for `buffer`.   
No-op if `buffer.length` is zero, or if new memory has been allocated after `buffer`.

## Equality Checks

### eq(bytes32,bytes)

```solidity
function eq(bytes32 a, bytes memory b)
    internal
    pure
    returns (bool result)
```

Returns `a == abi.decode(b, (bytes32))`.

### eq(bytes,bytes32)

```solidity
function eq(bytes memory a, bytes32 b)
    internal
    pure
    returns (bool result)
```

Returns `abi.decode(a, (bytes32)) == a`.

## Byte Slice Hashing Operations

### hash(bytes,uint256,uint256)

```solidity
function hash(bytes memory b, uint256 start, uint256 end)
    internal
    pure
    returns (bytes32 result)
```

Returns the keccak256 of the slice from `start` to `end` (exclusive).   
`start` and `end` are byte offsets.

### hash(bytes,uint256)

```solidity
function hash(bytes memory b, uint256 start)
    internal
    pure
    returns (bytes32 result)
```

Returns the keccak256 of the slice from `start` to the end of the bytes.

### hash(bytes)

```solidity
function hash(bytes memory b) internal pure returns (bytes32 result)
```

Returns the keccak256 of the bytes.

### hashCalldata(bytes,uint256,uint256)

```solidity
function hashCalldata(bytes calldata b, uint256 start, uint256 end)
    internal
    pure
    returns (bytes32 result)
```

Returns the keccak256 of the slice from `start` to `end` (exclusive).   
`start` and `end` are byte offsets.

### hashCalldata(bytes,uint256)

```solidity
function hashCalldata(bytes calldata b, uint256 start)
    internal
    pure
    returns (bytes32 result)
```

Returns the keccak256 of the slice from `start` to the end of the bytes.

### hashCalldata(bytes)

```solidity
function hashCalldata(bytes calldata b)
    internal
    pure
    returns (bytes32 result)
```

Returns the keccak256 of the bytes.

## SHA2-256 Helpers

### sha2(bytes32)

```solidity
function sha2(bytes32 b) internal view returns (bytes32 result)
```

Returns `sha256(abi.encode(b))`. Yes, it's more efficient.

### sha2(bytes,uint256,uint256)

```solidity
function sha2(bytes memory b, uint256 start, uint256 end)
    internal
    view
    returns (bytes32 result)
```

Returns the sha256 of the slice from `start` to `end` (exclusive).   
`start` and `end` are byte offsets.

### sha2(bytes,uint256)

```solidity
function sha2(bytes memory b, uint256 start)
    internal
    view
    returns (bytes32 result)
```

Returns the sha256 of the slice from `start` to the end of the bytes.

### sha2(bytes)

```solidity
function sha2(bytes memory b) internal view returns (bytes32 result)
```

Returns the sha256 of the bytes.

### sha2Calldata(bytes,uint256,uint256)

```solidity
function sha2Calldata(bytes calldata b, uint256 start, uint256 end)
    internal
    view
    returns (bytes32 result)
```

Returns the sha256 of the slice from `start` to `end` (exclusive).   
`start` and `end` are byte offsets.

### sha2Calldata(bytes,uint256)

```solidity
function sha2Calldata(bytes calldata b, uint256 start)
    internal
    view
    returns (bytes32 result)
```

Returns the sha256 of the slice from `start` to the end of the bytes.

### sha2Calldata(bytes)

```solidity
function sha2Calldata(bytes calldata b)
    internal
    view
    returns (bytes32 result)
```

Returns the sha256 of the bytes.