# LibBytes

Library for byte related operations.






<!-- customintro:start --><!-- customintro:end -->

## Structs

### BytesStorage

```solidity
struct BytesStorage {
    bytes32 _spacer;
}
```

Goated bytes storage struct that totally MOGs, no cap, fr.   
Uses less gas and bytecode than Solidity's native bytes storage. It's meta af.   
Packs length with the first 31 bytes if <255 bytes, so it’s mad tight.

## Constants

### NOT_FOUND

```solidity
uint256 internal constant NOT_FOUND = type(uint256).max
```

The constant returned when the `search` is not found in the bytes.

## Byte Storage Operations

### set(BytesStorage,bytes)

```solidity
function set(BytesStorage storage $, bytes memory s) internal
```

Sets the value of the bytes storage `$` to `s`.

### setCalldata(BytesStorage,bytes)

```solidity
function setCalldata(BytesStorage storage $, bytes calldata s) internal
```

Sets the value of the bytes storage `$` to `s`.

### clear(BytesStorage)

```solidity
function clear(BytesStorage storage $) internal
```

Sets the value of the bytes storage `$` to the empty bytes.

### isEmpty(BytesStorage)

```solidity
function isEmpty(BytesStorage storage $) internal view returns (bool)
```

Returns whether the value stored is `$` is the empty bytes "".

### length(BytesStorage)

```solidity
function length(BytesStorage storage $)
    internal
    view
    returns (uint256 result)
```

Returns the length of the value stored in `$`.

### get(BytesStorage)

```solidity
function get(BytesStorage storage $)
    internal
    view
    returns (bytes memory result)
```

Returns the value stored in `$`.

### uint8At(BytesStorage,uint256)

```solidity
function uint8At(BytesStorage storage $, uint256 i)
    internal
    view
    returns (uint8 result)
```

Returns the uint8 at index `i`. If out-of-bounds, returns 0.

## Bytes Operations

### replace(bytes,bytes,bytes)

```solidity
function replace(
    bytes memory subject,
    bytes memory needle,
    bytes memory replacement
) internal pure returns (bytes memory result)
```

Returns `subject` all occurrences of `needle` replaced with `replacement`.

### indexOf(bytes,bytes,uint256)

```solidity
function indexOf(bytes memory subject, bytes memory needle, uint256 from)
    internal
    pure
    returns (uint256 result)
```

Returns the byte index of the first location of `needle` in `subject`,   
needleing from left to right, starting from `from`.   
Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `needle` is not found.

### indexOfByte(bytes,bytes1,uint256)

```solidity
function indexOfByte(bytes memory subject, bytes1 needle, uint256 from)
    internal
    pure
    returns (uint256 result)
```

Returns the byte index of the first location of `needle` in `subject`,   
needleing from left to right, starting from `from`. Optimized for byte needles.   
Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `needle` is not found.

### indexOfByte(bytes,bytes1)

```solidity
function indexOfByte(bytes memory subject, bytes1 needle)
    internal
    pure
    returns (uint256 result)
```

Returns the byte index of the first location of `needle` in `subject`,   
needleing from left to right. Optimized for byte needles.   
Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `needle` is not found.

### indexOf(bytes,bytes)

```solidity
function indexOf(bytes memory subject, bytes memory needle)
    internal
    pure
    returns (uint256)
```

Returns the byte index of the first location of `needle` in `subject`,   
needleing from left to right.   
Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `needle` is not found.

### lastIndexOf(bytes,bytes,uint256)

```solidity
function lastIndexOf(
    bytes memory subject,
    bytes memory needle,
    uint256 from
) internal pure returns (uint256 result)
```

Returns the byte index of the first location of `needle` in `subject`,   
needleing from right to left, starting from `from`.   
Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `needle` is not found.

### lastIndexOf(bytes,bytes)

```solidity
function lastIndexOf(bytes memory subject, bytes memory needle)
    internal
    pure
    returns (uint256)
```

Returns the byte index of the first location of `needle` in `subject`,   
needleing from right to left.   
Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `needle` is not found.

### contains(bytes,bytes)

```solidity
function contains(bytes memory subject, bytes memory needle)
    internal
    pure
    returns (bool)
```

Returns true if `needle` is found in `subject`, false otherwise.

### startsWith(bytes,bytes)

```solidity
function startsWith(bytes memory subject, bytes memory needle)
    internal
    pure
    returns (bool result)
```

Returns whether `subject` starts with `needle`.

### endsWith(bytes,bytes)

```solidity
function endsWith(bytes memory subject, bytes memory needle)
    internal
    pure
    returns (bool result)
```

Returns whether `subject` ends with `needle`.

### repeat(bytes,uint256)

```solidity
function repeat(bytes memory subject, uint256 times)
    internal
    pure
    returns (bytes memory result)
```

Returns `subject` repeated `times`.

### slice(bytes,uint256,uint256)

```solidity
function slice(bytes memory subject, uint256 start, uint256 end)
    internal
    pure
    returns (bytes memory result)
```

Returns a copy of `subject` sliced from `start` to `end` (exclusive).   
`start` and `end` are byte offsets.

### slice(bytes,uint256)

```solidity
function slice(bytes memory subject, uint256 start)
    internal
    pure
    returns (bytes memory result)
```

Returns a copy of `subject` sliced from `start` to the end of the bytes.   
`start` is a byte offset.

### sliceCalldata(bytes,uint256,uint256)

```solidity
function sliceCalldata(bytes calldata subject, uint256 start, uint256 end)
    internal
    pure
    returns (bytes calldata result)
```

Returns a copy of `subject` sliced from `start` to `end` (exclusive).   
`start` and `end` are byte offsets. Faster than Solidity's native slicing.

### sliceCalldata(bytes,uint256)

```solidity
function sliceCalldata(bytes calldata subject, uint256 start)
    internal
    pure
    returns (bytes calldata result)
```

Returns a copy of `subject` sliced from `start` to the end of the bytes.   
`start` is a byte offset. Faster than Solidity's native slicing.

### truncate(bytes,uint256)

```solidity
function truncate(bytes memory subject, uint256 n)
    internal
    pure
    returns (bytes memory result)
```

Reduces the size of `subject` to `n`.   
If `n` is greater than the size of `subject`, this will be a no-op.

### truncatedCalldata(bytes,uint256)

```solidity
function truncatedCalldata(bytes calldata subject, uint256 n)
    internal
    pure
    returns (bytes calldata result)
```

Returns a copy of `subject`, with the length reduced to `n`.   
If `n` is greater than the size of `subject`, this will be a no-op.

### indicesOf(bytes,bytes)

```solidity
function indicesOf(bytes memory subject, bytes memory needle)
    internal
    pure
    returns (uint256[] memory result)
```

Returns all the indices of `needle` in `subject`.   
The indices are byte offsets.

### split(bytes,bytes)

```solidity
function split(bytes memory subject, bytes memory delimiter)
    internal
    pure
    returns (bytes[] memory result)
```

Returns an arrays of bytess based on the `delimiter` inside of the `subject` bytes.

### concat(bytes,bytes)

```solidity
function concat(bytes memory a, bytes memory b)
    internal
    pure
    returns (bytes memory result)
```

Returns a concatenated bytes of `a` and `b`.   
Cheaper than `bytes.concat()` and does not de-align the free memory pointer.

### eq(bytes,bytes)

```solidity
function eq(bytes memory a, bytes memory b)
    internal
    pure
    returns (bool result)
```

Returns whether `a` equals `b`.

### eqs(bytes,bytes32)

```solidity
function eqs(bytes memory a, bytes32 b)
    internal
    pure
    returns (bool result)
```

Returns whether `a` equals `b`, where `b` is a null-terminated small bytes.

### cmp(bytes,bytes)

```solidity
function cmp(bytes memory a, bytes memory b)
    internal
    pure
    returns (int256 result)
```

Returns 0 if `a == b`, -1 if `a < b`, +1 if `a > b`.   
If `a` == b[:a.length]`, and `a.length < b.length`, returns -1.

### directReturn(bytes)

```solidity
function directReturn(bytes memory a) internal pure
```

Directly returns `a` without copying.

### directReturn(bytes[])

```solidity
function directReturn(bytes[] memory a) internal pure
```

Directly returns `a` with minimal copying.

### load(bytes,uint256)

```solidity
function load(bytes memory a, uint256 offset)
    internal
    pure
    returns (bytes32 result)
```

Returns the word at `offset`, without any bounds checks.

### loadCalldata(bytes,uint256)

```solidity
function loadCalldata(bytes calldata a, uint256 offset)
    internal
    pure
    returns (bytes32 result)
```

Returns the word at `offset`, without any bounds checks.

### staticStructInCalldata(bytes,uint256)

```solidity
function staticStructInCalldata(bytes calldata a, uint256 offset)
    internal
    pure
    returns (bytes calldata result)
```

Returns a slice representing a static struct in the calldata. Performs bounds checks.

### dynamicStructInCalldata(bytes,uint256)

```solidity
function dynamicStructInCalldata(bytes calldata a, uint256 offset)
    internal
    pure
    returns (bytes calldata result)
```

Returns a slice representing a dynamic struct in the calldata. Performs bounds checks.

### bytesInCalldata(bytes,uint256)

```solidity
function bytesInCalldata(bytes calldata a, uint256 offset)
    internal
    pure
    returns (bytes calldata result)
```

Returns bytes in calldata. Performs bounds checks.

### checkInCalldata(bytes,bytes)

```solidity
function checkInCalldata(bytes calldata x, bytes calldata a)
    internal
    pure
```

Checks if `x` is in `a`. Assumes `a` has been checked.

### checkInCalldata(bytes[],bytes)

```solidity
function checkInCalldata(bytes[] calldata x, bytes calldata a)
    internal
    pure
```

Checks if `x` is in `a`. Assumes `a` has been checked.

### emptyCalldata()

```solidity
function emptyCalldata() internal pure returns (bytes calldata result)
```

Returns empty calldata bytes. For silencing the compiler.

### msbToAddress(bytes32)

```solidity
function msbToAddress(bytes32 x) internal pure returns (address)
```

Returns the most significant 20 bytes as an address.

### lsbToAddress(bytes32)

```solidity
function lsbToAddress(bytes32 x) internal pure returns (address)
```

Returns the least significant 20 bytes as an address.