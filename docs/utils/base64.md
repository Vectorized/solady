# Base64

Library to encode strings in Base64.






<!-- customintro:start --><!-- customintro:end -->

## Encoding / Decoding

### encode(bytes,bool,bool)

```solidity
function encode(bytes memory data, bool fileSafe, bool noPadding)
    internal
    pure
    returns (string memory result)
```

Encodes `data` using the base64 encoding described in RFC 4648.   
See: https://datatracker.ietf.org/doc/html/rfc4648   
@param fileSafe  Whether to replace '+' with '-' and '/' with '_'.   
@param noPadding Whether to strip away the padding.

### encode(bytes)

```solidity
function encode(bytes memory data)
    internal
    pure
    returns (string memory result)
```

Encodes `data` using the base64 encoding described in RFC 4648.   
Equivalent to `encode(data, false, false)`.

### encode(bytes,bool)

```solidity
function encode(bytes memory data, bool fileSafe)
    internal
    pure
    returns (string memory result)
```

Encodes `data` using the base64 encoding described in RFC 4648.   
Equivalent to `encode(data, fileSafe, false)`.

### decode(string)

```solidity
function decode(string memory data)
    internal
    pure
    returns (bytes memory result)
```

Decodes base64 encoded `data`.   
Supports:   
- RFC 4648 (both standard and file-safe mode).   
- RFC 3501 (63: ',').   
Does not support:   
- Line breaks.   
Note: For performance reasons,   
this function will NOT revert on invalid `data` inputs.   
Outputs for invalid inputs will simply be undefined behaviour.   
It is the user's responsibility to ensure that the `data`   
is a valid base64 encoded string.