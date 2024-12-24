# LibZip

Library for compressing and decompressing bytes.


<b>Note:</b>

The accompanying solady.js library includes implementations of
FastLZ and calldata operations for convenience.



<!-- customintro:start --><!-- customintro:end -->

## Fast LZ Operations

LZ77 implementation based on FastLZ.   
Equivalent to level 1 compression and decompression at the following commit:   
https://github.com/ariya/FastLZ/commit/344eb4025f9ae866ebf7a2ec48850f7113a97a42   
Decompression is backwards compatible.

### flzCompress(bytes)

```solidity
function flzCompress(bytes memory data)
    internal
    pure
    returns (bytes memory result)
```

Returns the compressed `data`.

### flzDecompress(bytes)

```solidity
function flzDecompress(bytes memory data)
    internal
    pure
    returns (bytes memory result)
```

Returns the decompressed `data`.

## Calldata Operations

Calldata compression and decompression using selective run length encoding:   
- Sequences of 0x00 (up to 128 consecutive).   
- Sequences of 0xff (up to 32 consecutive).   
A run length encoded block consists of two bytes:   
(0) 0x00   
(1) A control byte with the following bit layout:   
- [7]     `0: 0x00, 1: 0xff`.   
- [0..6]  `runLength - 1`.   
The first 4 bytes are bitwise negated so that the compressed calldata   
can be dispatched into the `fallback` and `receive` functions.

### cdCompress(bytes)

```solidity
function cdCompress(bytes memory data)
    internal
    pure
    returns (bytes memory result)
```

Returns the compressed `data`.

### cdDecompress(bytes)

```solidity
function cdDecompress(bytes memory data)
    internal
    pure
    returns (bytes memory result)
```

Returns the decompressed `data`.

### cdFallback()

```solidity
function cdFallback() internal
```

To be called in the `fallback` function.   
```solidity   
fallback() external payable { LibZip.cdFallback(); }   
receive() external payable {}   
Silence compiler warning to add a `receive` function.   
```   
For efficiency, this function will directly return the results, terminating the context.   
If called internally, it must be called at the end of the function.