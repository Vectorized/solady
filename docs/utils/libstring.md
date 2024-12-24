# LibString

Library for converting numbers into strings and other string operations.


<b>Note:</b>

For performance and bytecode compactness, most of the string operations are restricted to
byte strings (7-bit ASCII), except where otherwise specified.
Usage of byte string operations on charsets with runes spanning two or more bytes
can lead to undefined behavior.



<!-- customintro:start --><!-- customintro:end -->

## Structs

### StringStorage

```solidity
struct StringStorage {
    bytes32 _spacer;
}
```

Goated string storage struct that totally MOGs, no cap, fr.   
Uses less gas and bytecode than Solidity's native string storage. It's meta af.   
Packs length with the first 31 bytes if <255 bytes, so it’s mad tight.

## Custom Errors

### HexLengthInsufficient()

```solidity
error HexLengthInsufficient()
```

The length of the output is too small to contain all the hex digits.

### TooBigForSmallString()

```solidity
error TooBigForSmallString()
```

The length of the string is more than 32 bytes.

### StringNot7BitASCII()

```solidity
error StringNot7BitASCII()
```

The input string must be a 7-bit ASCII.

## Constants

### NOT_FOUND

```solidity
uint256 internal constant NOT_FOUND = type(uint256).max
```

The constant returned when the `search` is not found in the string.

### ALPHANUMERIC_7_BIT_ASCII

```solidity
uint128 internal constant ALPHANUMERIC_7_BIT_ASCII =
    0x7fffffe07fffffe03ff000000000000
```

Lookup for '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'.

### LETTERS_7_BIT_ASCII

```solidity
uint128 internal constant LETTERS_7_BIT_ASCII =
    0x7fffffe07fffffe0000000000000000
```

Lookup for 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'.

### LOWERCASE_7_BIT_ASCII

```solidity
uint128 internal constant LOWERCASE_7_BIT_ASCII =
    0x7fffffe000000000000000000000000
```

Lookup for 'abcdefghijklmnopqrstuvwxyz'.

### UPPERCASE_7_BIT_ASCII

```solidity
uint128 internal constant UPPERCASE_7_BIT_ASCII = 0x7fffffe0000000000000000
```

Lookup for 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.

### DIGITS_7_BIT_ASCII

```solidity
uint128 internal constant DIGITS_7_BIT_ASCII = 0x3ff000000000000
```

Lookup for '0123456789'.

### HEXDIGITS_7_BIT_ASCII

```solidity
uint128 internal constant HEXDIGITS_7_BIT_ASCII =
    0x7e0000007e03ff000000000000
```

Lookup for '0123456789abcdefABCDEF'.

### OCTDIGITS_7_BIT_ASCII

```solidity
uint128 internal constant OCTDIGITS_7_BIT_ASCII = 0xff000000000000
```

Lookup for '01234567'.

### PRINTABLE_7_BIT_ASCII

```solidity
uint128 internal constant PRINTABLE_7_BIT_ASCII =
    0x7fffffffffffffffffffffff00003e00
```

Lookup for '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~ \t\n\r\x0b\x0c'.

### PUNCTUATION_7_BIT_ASCII

```solidity
uint128 internal constant PUNCTUATION_7_BIT_ASCII =
    0x78000001f8000001fc00fffe00000000
```

Lookup for '!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~'.

### WHITESPACE_7_BIT_ASCII

```solidity
uint128 internal constant WHITESPACE_7_BIT_ASCII = 0x100003e00
```

Lookup for ' \t\n\r\x0b\x0c'.

## String Storage Operations

### set(StringStorage,string)

```solidity
function set(StringStorage storage $, string memory s) internal
```

Sets the value of the string storage `$` to `s`.

### setCalldata(StringStorage,string)

```solidity
function setCalldata(StringStorage storage $, string calldata s) internal
```

Sets the value of the string storage `$` to `s`.

### clear(StringStorage)

```solidity
function clear(StringStorage storage $) internal
```

Sets the value of the string storage `$` to the empty string.

### isEmpty(StringStorage)

```solidity
function isEmpty(StringStorage storage $) internal view returns (bool)
```

Returns whether the value stored is `$` is the empty string "".

### length(StringStorage)

```solidity
function length(StringStorage storage $) internal view returns (uint256)
```

Returns the length of the value stored in `$`.

### get(StringStorage)

```solidity
function get(StringStorage storage $)
    internal
    view
    returns (string memory)
```

Returns the value stored in `$`.

### bytesStorage(StringStorage)

```solidity
function bytesStorage(StringStorage storage $)
    internal
    pure
    returns (LibBytes.BytesStorage storage casted)
```

Helper to cast `$` to a `BytesStorage`.

## Decimal Operations

### toString(uint256)

```solidity
function toString(uint256 value)
    internal
    pure
    returns (string memory result)
```

Returns the base 10 decimal representation of `value`.

### toString(int256)

```solidity
function toString(int256 value)
    internal
    pure
    returns (string memory result)
```

Returns the base 10 decimal representation of `value`.

## Hexadecimal Operations

### toHexString(uint256,uint256)

```solidity
function toHexString(uint256 value, uint256 byteCount)
    internal
    pure
    returns (string memory result)
```

Returns the hexadecimal representation of `value`,   
left-padded to an input length of `byteCount` bytes.   
The output is prefixed with "0x" encoded using 2 hexadecimal digits per byte,   
giving a total length of `byteCount * 2 + 2` bytes.   
Reverts if `byteCount` is too small for the output to contain all the digits.

### toHexStringNoPrefix(uint256,uint256)

```solidity
function toHexStringNoPrefix(uint256 value, uint256 byteCount)
    internal
    pure
    returns (string memory result)
```

Returns the hexadecimal representation of `value`,   
left-padded to an input length of `byteCount` bytes.   
The output is not prefixed with "0x" and is encoded using 2 hexadecimal digits per byte,   
giving a total length of `byteCount * 2` bytes.   
Reverts if `byteCount` is too small for the output to contain all the digits.

### toHexString(uint256)

```solidity
function toHexString(uint256 value)
    internal
    pure
    returns (string memory result)
```

Returns the hexadecimal representation of `value`.   
The output is prefixed with "0x" and encoded using 2 hexadecimal digits per byte.   
As address are 20 bytes long, the output will left-padded to have   
a length of `20 * 2 + 2` bytes.

### toMinimalHexString(uint256)

```solidity
function toMinimalHexString(uint256 value)
    internal
    pure
    returns (string memory result)
```

Returns the hexadecimal representation of `value`.   
The output is prefixed with "0x".   
The output excludes leading "0" from the `toHexString` output.   
`0x00: "0x0", 0x01: "0x1", 0x12: "0x12", 0x123: "0x123"`.

### toMinimalHexStringNoPrefix(uint256)

```solidity
function toMinimalHexStringNoPrefix(uint256 value)
    internal
    pure
    returns (string memory result)
```

Returns the hexadecimal representation of `value`.   
The output excludes leading "0" from the `toHexStringNoPrefix` output.   
`0x00: "0", 0x01: "1", 0x12: "12", 0x123: "123"`.

### toHexStringNoPrefix(uint256)

```solidity
function toHexStringNoPrefix(uint256 value)
    internal
    pure
    returns (string memory result)
```

Returns the hexadecimal representation of `value`.   
The output is encoded using 2 hexadecimal digits per byte.   
As address are 20 bytes long, the output will left-padded to have   
a length of `20 * 2` bytes.

### toHexStringChecksummed(address)

```solidity
function toHexStringChecksummed(address value)
    internal
    pure
    returns (string memory result)
```

Returns the hexadecimal representation of `value`.   
The output is prefixed with "0x", encoded using 2 hexadecimal digits per byte,   
and the alphabets are capitalized conditionally according to   
https://eips.ethereum.org/EIPS/eip-55

### toHexString(address)

```solidity
function toHexString(address value)
    internal
    pure
    returns (string memory result)
```

Returns the hexadecimal representation of `value`.   
The output is prefixed with "0x" and encoded using 2 hexadecimal digits per byte.

### toHexStringNoPrefix(address)

```solidity
function toHexStringNoPrefix(address value)
    internal
    pure
    returns (string memory result)
```

Returns the hexadecimal representation of `value`.   
The output is encoded using 2 hexadecimal digits per byte.

### toHexString(bytes)

```solidity
function toHexString(bytes memory raw)
    internal
    pure
    returns (string memory result)
```

Returns the hex encoded string from the raw bytes.   
The output is encoded using 2 hexadecimal digits per byte.

### toHexStringNoPrefix(bytes)

```solidity
function toHexStringNoPrefix(bytes memory raw)
    internal
    pure
    returns (string memory result)
```

Returns the hex encoded string from the raw bytes.   
The output is encoded using 2 hexadecimal digits per byte.

## Rune String Operations

### runeCount(string)

```solidity
function runeCount(string memory s)
    internal
    pure
    returns (uint256 result)
```

Returns the number of UTF characters in the string.

### is7BitASCII(string)

```solidity
function is7BitASCII(string memory s) internal pure returns (bool result)
```

Returns if this string is a 7-bit ASCII string.   
(i.e. all characters codes are in [0..127])

### is7BitASCII(string,uint128)

```solidity
function is7BitASCII(string memory s, uint128 allowed)
    internal
    pure
    returns (bool result)
```

Returns if this string is a 7-bit ASCII string,   
AND all characters are in the `allowed` lookup.   
Note: If `s` is empty, returns true regardless of `allowed`.

### to7BitASCIIAllowedLookup(string)

```solidity
function to7BitASCIIAllowedLookup(string memory s)
    internal
    pure
    returns (uint128 result)
```

Converts the bytes in the 7-bit ASCII string `s` to   
an allowed lookup for use in `is7BitASCII(s, allowed)`.   
To save runtime gas, you can cache the result in an immutable variable.

## Byte String Operations

For performance and bytecode compactness, byte string operations are restricted   
to 7-bit ASCII strings. All offsets are byte offsets, not UTF character offsets.   
Usage of byte string operations on charsets with runes spanning two or more bytes   
can lead to undefined behavior.

### replace(string,string,string)

```solidity
function replace(
    string memory subject,
    string memory needle,
    string memory replacement
) internal pure returns (string memory)
```

Returns `subject` all occurrences of `needle` replaced with `replacement`.

### indexOf(string,string,uint256)

```solidity
function indexOf(string memory subject, string memory needle, uint256 from)
    internal
    pure
    returns (uint256)
```

Returns the byte index of the first location of `needle` in `subject`,   
needleing from left to right, starting from `from`.   
Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `needle` is not found.

### indexOf(string,string)

```solidity
function indexOf(string memory subject, string memory needle)
    internal
    pure
    returns (uint256)
```

Returns the byte index of the first location of `needle` in `subject`,   
needleing from left to right.   
Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `needle` is not found.

### lastIndexOf(string,string,uint256)

```solidity
function lastIndexOf(
    string memory subject,
    string memory needle,
    uint256 from
) internal pure returns (uint256)
```

Returns the byte index of the first location of `needle` in `subject`,   
needleing from right to left, starting from `from`.   
Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `needle` is not found.

### lastIndexOf(string,string)

```solidity
function lastIndexOf(string memory subject, string memory needle)
    internal
    pure
    returns (uint256)
```

Returns the byte index of the first location of `needle` in `subject`,   
needleing from right to left.   
Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `needle` is not found.

### contains(string,string)

```solidity
function contains(string memory subject, string memory needle)
    internal
    pure
    returns (bool)
```

Returns true if `needle` is found in `subject`, false otherwise.

### startsWith(string,string)

```solidity
function startsWith(string memory subject, string memory needle)
    internal
    pure
    returns (bool)
```

Returns whether `subject` starts with `needle`.

### endsWith(string,string)

```solidity
function endsWith(string memory subject, string memory needle)
    internal
    pure
    returns (bool)
```

Returns whether `subject` ends with `needle`.

### repeat(string,uint256)

```solidity
function repeat(string memory subject, uint256 times)
    internal
    pure
    returns (string memory)
```

Returns `subject` repeated `times`.

### slice(string,uint256,uint256)

```solidity
function slice(string memory subject, uint256 start, uint256 end)
    internal
    pure
    returns (string memory)
```

Returns a copy of `subject` sliced from `start` to `end` (exclusive).   
`start` and `end` are byte offsets.

### slice(string,uint256)

```solidity
function slice(string memory subject, uint256 start)
    internal
    pure
    returns (string memory)
```

Returns a copy of `subject` sliced from `start` to the end of the string.   
`start` is a byte offset.

### indicesOf(string,string)

```solidity
function indicesOf(string memory subject, string memory needle)
    internal
    pure
    returns (uint256[] memory)
```

Returns all the indices of `needle` in `subject`.   
The indices are byte offsets.

### split(string,string)

```solidity
function split(string memory subject, string memory delimiter)
    internal
    pure
    returns (string[] memory result)
```

Returns a arrays of strings based on the `delimiter` inside of the `subject` string.

### concat(string,string)

```solidity
function concat(string memory a, string memory b)
    internal
    pure
    returns (string memory)
```

Returns a concatenated string of `a` and `b`.   
Cheaper than `string.concat()` and does not de-align the free memory pointer.

### toCase(string,bool)

```solidity
function toCase(string memory subject, bool toUpper)
    internal
    pure
    returns (string memory result)
```

Returns a copy of the string in either lowercase or UPPERCASE.   
WARNING! This function is only compatible with 7-bit ASCII strings.

### fromSmallString(bytes32)

```solidity
function fromSmallString(bytes32 s)
    internal
    pure
    returns (string memory result)
```

Returns a string from a small bytes32 string.   
`s` must be null-terminated, or behavior will be undefined.

### normalizeSmallString(bytes32)

```solidity
function normalizeSmallString(bytes32 s)
    internal
    pure
    returns (bytes32 result)
```

Returns the small string, with all bytes after the first null byte zeroized.

### toSmallString(string)

```solidity
function toSmallString(string memory s)
    internal
    pure
    returns (bytes32 result)
```

Returns the string as a normalized null-terminated small string.

### lower(string)

```solidity
function lower(string memory subject)
    internal
    pure
    returns (string memory result)
```

Returns a lowercased copy of the string.   
WARNING! This function is only compatible with 7-bit ASCII strings.

### upper(string)

```solidity
function upper(string memory subject)
    internal
    pure
    returns (string memory result)
```

Returns an UPPERCASED copy of the string.   
WARNING! This function is only compatible with 7-bit ASCII strings.

### escapeHTML(string)

```solidity
function escapeHTML(string memory s)
    internal
    pure
    returns (string memory result)
```

Escapes the string to be used within HTML tags.

### escapeJSON(string,bool)

```solidity
function escapeJSON(string memory s, bool addDoubleQuotes)
    internal
    pure
    returns (string memory result)
```

Escapes the string to be used within double-quotes in a JSON.   
If `addDoubleQuotes` is true, the result will be enclosed in double-quotes.

### escapeJSON(string)

```solidity
function escapeJSON(string memory s)
    internal
    pure
    returns (string memory result)
```

Escapes the string to be used within double-quotes in a JSON.

### encodeURIComponent(string)

```solidity
function encodeURIComponent(string memory s)
    internal
    pure
    returns (string memory result)
```

Encodes `s` so that it can be safely used in a URI,   
just like `encodeURIComponent` in JavaScript.   
See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent   
See: https://datatracker.ietf.org/doc/html/rfc2396   
See: https://datatracker.ietf.org/doc/html/rfc3986

### eq(string,string)

```solidity
function eq(string memory a, string memory b)
    internal
    pure
    returns (bool result)
```

Returns whether `a` equals `b`.

### eqs(string,bytes32)

```solidity
function eqs(string memory a, bytes32 b)
    internal
    pure
    returns (bool result)
```

Returns whether `a` equals `b`, where `b` is a null-terminated small string.

### cmp(string,string)

```solidity
function cmp(string memory a, string memory b)
    internal
    pure
    returns (int256)
```

Returns 0 if `a == b`, -1 if `a < b`, +1 if `a > b`.   
If `a` == b[:a.length]`, and `a.length < b.length`, returns -1.

### packOne(string)

```solidity
function packOne(string memory a) internal pure returns (bytes32 result)
```

Packs a single string with its length into a single word.   
Returns `bytes32(0)` if the length is zero or greater than 31.

### unpackOne(bytes32)

```solidity
function unpackOne(bytes32 packed)
    internal
    pure
    returns (string memory result)
```

Unpacks a string packed using {packOne}.   
Returns the empty string if `packed` is `bytes32(0)`.   
If `packed` is not an output of {packOne}, the output behavior is undefined.

### packTwo(string,string)

```solidity
function packTwo(string memory a, string memory b)
    internal
    pure
    returns (bytes32 result)
```

Packs two strings with their lengths into a single word.   
Returns `bytes32(0)` if combined length is zero or greater than 30.

### unpackTwo(bytes32)

```solidity
function unpackTwo(bytes32 packed)
    internal
    pure
    returns (string memory resultA, string memory resultB)
```

Unpacks strings packed using {packTwo}.   
Returns the empty strings if `packed` is `bytes32(0)`.   
If `packed` is not an output of {packTwo}, the output behavior is undefined.

### directReturn(string)

```solidity
function directReturn(string memory a) internal pure
```

Directly returns `a` without copying.