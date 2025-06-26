# Base58

Library to encode strings in Base58.






<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### Base58DecodingError()

```solidity
error Base58DecodingError()
```

An unrecognized character or overflow was encountered during decoding.

## Encoding / Decoding

### encode(bytes)

```solidity
function encode(bytes memory data)
    internal
    pure
    returns (string memory result)
```

Encodes `data` into a Base58 string.

### encodeWord(bytes32)

```solidity
function encodeWord(bytes32 data)
    internal
    pure
    returns (string memory result)
```

Encodes the `data` word into a Base58 string.

### decode(string)

```solidity
function decode(string memory encoded)
    internal
    pure
    returns (bytes memory result)
```

Decodes `encoded`, a Base58 string, into the original bytes.

### decodeWord(string)

```solidity
function decodeWord(string memory encoded)
    internal
    pure
    returns (bytes32 result)
```

Decodes `encoded`, a Base58 string, into the original word.