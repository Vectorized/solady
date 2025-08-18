# LibBit

Library for bit twiddling and boolean operations.






<!-- customintro:start --><!-- customintro:end -->

## Bit Twiddling Operations

### fls(uint256)

```solidity
function fls(uint256 x) internal pure returns (uint256 r)
```

Find last set.   
Returns the index of the most significant bit of `x`,   
counting from the least significant bit position.   
If `x` is zero, returns 256.

### clz(uint256)

```solidity
function clz(uint256 x) internal pure returns (uint256 r)
```

Count leading zeros.   
Returns the number of zeros preceding the most significant one bit.   
If `x` is zero, returns 256.

### ffs(uint256)

```solidity
function ffs(uint256 x) internal pure returns (uint256 r)
```

Find first set.   
Returns the index of the least significant bit of `x`,   
counting from the least significant bit position.   
If `x` is zero, returns 256.   
Equivalent to `ctz` (count trailing zeros), which gives   
the number of zeros following the least significant one bit.

### popCount(uint256)

```solidity
function popCount(uint256 x) internal pure returns (uint256 c)
```

Returns the number of set bits in `x`.

### countZeroBytes(uint256)

```solidity
function countZeroBytes(uint256 x) internal pure returns (uint256 c)
```

Returns the number of zero bytes in `x`.   
To get the number of non-zero bytes, simply do `32 - countZeroBytes(x)`.

### countZeroBytes(bytes)

```solidity
function countZeroBytes(bytes memory s) internal pure returns (uint256 c)
```

Returns the number of zero bytes in `s`.   
To get the number of non-zero bytes, simply do `s.length - countZeroBytes(s)`.

### countZeroBytesCalldata(bytes)

```solidity
function countZeroBytesCalldata(bytes calldata s)
    internal
    pure
    returns (uint256 c)
```

Returns the number of zero bytes in `s`.   
To get the number of non-zero bytes, simply do `s.length - countZeroBytes(s)`.

### isPo2(uint256)

```solidity
function isPo2(uint256 x) internal pure returns (bool result)
```

Returns whether `x` is a power of 2.

### reverseBits(uint256)

```solidity
function reverseBits(uint256 x) internal pure returns (uint256 r)
```

Returns `x` reversed at the bit level.

### reverseBytes(uint256)

```solidity
function reverseBytes(uint256 x) internal pure returns (uint256 r)
```

Returns `x` reversed at the byte level.

### commonBitPrefix(uint256,uint256)

```solidity
function commonBitPrefix(uint256 x, uint256 y)
    internal
    pure
    returns (uint256)
```

Returns the common prefix of `x` and `y` at the bit level.

### commonNibblePrefix(uint256,uint256)

```solidity
function commonNibblePrefix(uint256 x, uint256 y)
    internal
    pure
    returns (uint256)
```

Returns the common prefix of `x` and `y` at the nibble level.

### commonBytePrefix(uint256,uint256)

```solidity
function commonBytePrefix(uint256 x, uint256 y)
    internal
    pure
    returns (uint256)
```

Returns the common prefix of `x` and `y` at the byte level.

### toNibbles(bytes)

```solidity
function toNibbles(bytes memory s)
    internal
    pure
    returns (bytes memory result)
```

hex"ABCD" -> hex"0A0B0C0D".

## Boolean Operations

A Solidity bool on the stack or memory is represented as a 256-bit word.   
Non-zero values are true, zero is false.   
A clean bool is either 0 (false) or 1 (true) under the hood.   
Usually, if not always, the bool result of a regular Solidity expression,   
or the argument of a public/external function will be a clean bool.   
You can usually use the raw variants for more performance.   
If uncertain, test (best with exact compiler settings).   
Or use the non-raw variants (compiler can sometimes optimize out the double `iszero`s).

### rawAnd(bool,bool)

```solidity
function rawAnd(bool x, bool y) internal pure returns (bool z)
```

Returns `x & y`. Inputs must be clean.

### and(bool,bool)

```solidity
function and(bool x, bool y) internal pure returns (bool z)
```

Returns `x & y`.

### and(bool,bool,bool)

```solidity
function and(bool w, bool x, bool y) internal pure returns (bool z)
```

Returns `w & x & y`.

### and(bool,bool,bool,bool)

```solidity
function and(bool v, bool w, bool x, bool y)
    internal
    pure
    returns (bool z)
```

Returns `v & w & x & y`.

### rawOr(bool,bool)

```solidity
function rawOr(bool x, bool y) internal pure returns (bool z)
```

Returns `x | y`. Inputs must be clean.

### or(bool,bool)

```solidity
function or(bool x, bool y) internal pure returns (bool z)
```

Returns `x | y`.

### or(bool,bool,bool)

```solidity
function or(bool w, bool x, bool y) internal pure returns (bool z)
```

Returns `w | x | y`.

### or(bool,bool,bool,bool)

```solidity
function or(bool v, bool w, bool x, bool y)
    internal
    pure
    returns (bool z)
```

Returns `v | w | x | y`.

### rawToUint(bool)

```solidity
function rawToUint(bool b) internal pure returns (uint256 z)
```

Returns 1 if `b` is true, else 0. Input must be clean.

### toUint(bool)

```solidity
function toUint(bool b) internal pure returns (uint256 z)
```

Returns 1 if `b` is true, else 0.