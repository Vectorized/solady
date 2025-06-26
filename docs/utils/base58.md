# Base58

Library to encode strings in Base58.






<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### Base58DecodingError()

```solidity
error Base58DecodingError()
```

An unrecognized character was encountered during decoding.

## Encoding / Decoding

### encode(bytes)

```solidity
function encode(bytes memory data)
    internal
    pure
    returns (string memory result)
```

Encodes `data` into a Base58 string.

### decode(string)

```solidity
function decode(string memory encoded)
    internal
    pure
    returns (bytes memory result)
```

Decodes `encoded`, a Base58 string, into the original bytes.