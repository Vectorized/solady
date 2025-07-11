# FixedPointMathLib

Arithmetic library with operations for fixed-point numbers.






<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### ExpOverflow()

```solidity
error ExpOverflow()
```

The operation failed, as the output exceeds the maximum value of uint256.

### FactorialOverflow()

```solidity
error FactorialOverflow()
```

The operation failed, as the output exceeds the maximum value of uint256.

### RPowOverflow()

```solidity
error RPowOverflow()
```

The operation failed, due to an overflow.

### MantissaOverflow()

```solidity
error MantissaOverflow()
```

The mantissa is too big to fit.

### MulWadFailed()

```solidity
error MulWadFailed()
```

The operation failed, due to an multiplication overflow.

### SMulWadFailed()

```solidity
error SMulWadFailed()
```

The operation failed, due to an multiplication overflow.

### DivWadFailed()

```solidity
error DivWadFailed()
```

The operation failed, either due to a multiplication overflow, or a division by a zero.

### SDivWadFailed()

```solidity
error SDivWadFailed()
```

The operation failed, either due to a multiplication overflow, or a division by a zero.

### MulDivFailed()

```solidity
error MulDivFailed()
```

The operation failed, either due to a multiplication overflow, or a division by a zero.

### DivFailed()

```solidity
error DivFailed()
```

The division failed, as the denominator is zero.

### FullMulDivFailed()

```solidity
error FullMulDivFailed()
```

The full precision multiply-divide operation failed, either due   
to the result being larger than 256 bits, or a division by a zero.

### LnWadUndefined()

```solidity
error LnWadUndefined()
```

The output is undefined, as the input is less-than-or-equal to zero.

### OutOfDomain()

```solidity
error OutOfDomain()
```

The input outside the acceptable domain.

## Constants

### WAD

```solidity
uint256 internal constant WAD = 1e18
```

The scalar of ETH and most ERC20s.

## Simplified Fixed Point Operations

### mulWad(uint256,uint256)

```solidity
function mulWad(uint256 x, uint256 y) internal pure returns (uint256 z)
```

Equivalent to `(x * y) / WAD` rounded down.

### sMulWad(int256,int256)

```solidity
function sMulWad(int256 x, int256 y) internal pure returns (int256 z)
```

Equivalent to `(x * y) / WAD` rounded down.

### rawMulWad(uint256,uint256)

```solidity
function rawMulWad(uint256 x, uint256 y)
    internal
    pure
    returns (uint256 z)
```

Equivalent to `(x * y) / WAD` rounded down, but without overflow checks.

### rawSMulWad(int256,int256)

```solidity
function rawSMulWad(int256 x, int256 y) internal pure returns (int256 z)
```

Equivalent to `(x * y) / WAD` rounded down, but without overflow checks.

### mulWadUp(uint256,uint256)

```solidity
function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256 z)
```

Equivalent to `(x * y) / WAD` rounded up.

### rawMulWadUp(uint256,uint256)

```solidity
function rawMulWadUp(uint256 x, uint256 y)
    internal
    pure
    returns (uint256 z)
```

Equivalent to `(x * y) / WAD` rounded up, but without overflow checks.

### divWad(uint256,uint256)

```solidity
function divWad(uint256 x, uint256 y) internal pure returns (uint256 z)
```

Equivalent to `(x * WAD) / y` rounded down.

### sDivWad(int256,int256)

```solidity
function sDivWad(int256 x, int256 y) internal pure returns (int256 z)
```

Equivalent to `(x * WAD) / y` rounded down.

### rawDivWad(uint256,uint256)

```solidity
function rawDivWad(uint256 x, uint256 y)
    internal
    pure
    returns (uint256 z)
```

Equivalent to `(x * WAD) / y` rounded down, but without overflow and divide by zero checks.

### rawSDivWad(int256,int256)

```solidity
function rawSDivWad(int256 x, int256 y) internal pure returns (int256 z)
```

Equivalent to `(x * WAD) / y` rounded down, but without overflow and divide by zero checks.

### divWadUp(uint256,uint256)

```solidity
function divWadUp(uint256 x, uint256 y) internal pure returns (uint256 z)
```

Equivalent to `(x * WAD) / y` rounded up.

### rawDivWadUp(uint256,uint256)

```solidity
function rawDivWadUp(uint256 x, uint256 y)
    internal
    pure
    returns (uint256 z)
```

Equivalent to `(x * WAD) / y` rounded up, but without overflow and divide by zero checks.

### powWad(int256,int256)

```solidity
function powWad(int256 x, int256 y) internal pure returns (int256)
```

Equivalent to `x` to the power of `y`.   
because `x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)`.   
Note: This function is an approximation.

### expWad(int256)

```solidity
function expWad(int256 x) internal pure returns (int256 r)
```

Returns `exp(x)`, denominated in `WAD`.   
Credit to Remco Bloemen under MIT license: https://2π.com/22/exp-ln   
Note: This function is an approximation. Monotonically increasing.

### lnWad(int256)

```solidity
function lnWad(int256 x) internal pure returns (int256 r)
```

Returns `ln(x)`, denominated in `WAD`.   
Credit to Remco Bloemen under MIT license: https://2π.com/22/exp-ln   
Note: This function is an approximation. Monotonically increasing.

### lambertW0Wad(int256)

```solidity
function lambertW0Wad(int256 x) internal pure returns (int256 w)
```

Returns `W_0(x)`, denominated in `WAD`.   
See: https://en.wikipedia.org/wiki/Lambert_W_function   
a.k.a. Product log function. This is an approximation of the principal branch.   
Note: This function is an approximation. Monotonically increasing.

## General Number Utilities

### fullMulEq(uint256,uint256,uint256,uint256)

```solidity
function fullMulEq(uint256 a, uint256 b, uint256 x, uint256 y)
    internal
    pure
    returns (bool result)
```

Returns `a * b == x * y`, with full precision.

### fullMulDiv(uint256,uint256,uint256)

```solidity
function fullMulDiv(uint256 x, uint256 y, uint256 d)
    internal
    pure
    returns (uint256 z)
```

Calculates `floor(x * y / d)` with full precision.   
Throws if result overflows a uint256 or when `d` is zero.   
Credit to Remco Bloemen under MIT license: https://2π.com/21/muldiv

### fullMulDivUnchecked(uint256,uint256,uint256)

```solidity
function fullMulDivUnchecked(uint256 x, uint256 y, uint256 d)
    internal
    pure
    returns (uint256 z)
```

Calculates `floor(x * y / d)` with full precision.   
Behavior is undefined if `d` is zero or the final result cannot fit in 256 bits.   
Performs the full 512 bit calculation regardless.

### fullMulDivUp(uint256,uint256,uint256)

```solidity
function fullMulDivUp(uint256 x, uint256 y, uint256 d)
    internal
    pure
    returns (uint256 z)
```

Calculates `floor(x * y / d)` with full precision, rounded up.   
Throws if result overflows a uint256 or when `d` is zero.   
Credit to Uniswap-v3-core under MIT license:   
https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/FullMath.sol

### fullMulDivN(uint256,uint256,uint8)

```solidity
function fullMulDivN(uint256 x, uint256 y, uint8 n)
    internal
    pure
    returns (uint256 z)
```

Calculates `floor(x * y / 2 ** n)` with full precision.   
Throws if result overflows a uint256.   
Credit to Philogy under MIT license:   
https://github.com/SorellaLabs/angstrom/blob/main/contracts/src/libraries/X128MathLib.sol

### mulDiv(uint256,uint256,uint256)

```solidity
function mulDiv(uint256 x, uint256 y, uint256 d)
    internal
    pure
    returns (uint256 z)
```

Returns `floor(x * y / d)`.   
Reverts if `x * y` overflows, or `d` is zero.

### mulDivUp(uint256,uint256,uint256)

```solidity
function mulDivUp(uint256 x, uint256 y, uint256 d)
    internal
    pure
    returns (uint256 z)
```

Returns `ceil(x * y / d)`.   
Reverts if `x * y` overflows, or `d` is zero.

### invMod(uint256,uint256)

```solidity
function invMod(uint256 a, uint256 n) internal pure returns (uint256 x)
```

Returns `x`, the modular multiplicative inverse of `a`, such that `(a * x) % n == 1`.

### divUp(uint256,uint256)

```solidity
function divUp(uint256 x, uint256 d) internal pure returns (uint256 z)
```

Returns `ceil(x / d)`.   
Reverts if `d` is zero.

### zeroFloorSub(uint256,uint256)

```solidity
function zeroFloorSub(uint256 x, uint256 y)
    internal
    pure
    returns (uint256 z)
```

Returns `max(0, x - y)`. Alias for `saturatingSub`.

### saturatingSub(uint256,uint256)

```solidity
function saturatingSub(uint256 x, uint256 y)
    internal
    pure
    returns (uint256 z)
```

Returns `max(0, x - y)`.

### saturatingAdd(uint256,uint256)

```solidity
function saturatingAdd(uint256 x, uint256 y)
    internal
    pure
    returns (uint256 z)
```

Returns `min(2 ** 256 - 1, x + y)`.

### saturatingMul(uint256,uint256)

```solidity
function saturatingMul(uint256 x, uint256 y)
    internal
    pure
    returns (uint256 z)
```

Returns `min(2 ** 256 - 1, x * y)`.

### ternary(bool,uint256,uint256)

```solidity
function ternary(bool condition, uint256 x, uint256 y)
    internal
    pure
    returns (uint256 z)
```

Returns `condition ? x : y`, without branching.

### ternary(bool,bytes32,bytes32)

```solidity
function ternary(bool condition, bytes32 x, bytes32 y)
    internal
    pure
    returns (bytes32 z)
```

Returns `condition ? x : y`, without branching.

### ternary(bool,address,address)

```solidity
function ternary(bool condition, address x, address y)
    internal
    pure
    returns (address z)
```

Returns `condition ? x : y`, without branching.

### coalesce(uint256,uint256)

```solidity
function coalesce(uint256 x, uint256 y) internal pure returns (uint256 z)
```

Returns `x != 0 ? x : y`, without branching.

### coalesce(bytes32,bytes32)

```solidity
function coalesce(bytes32 x, bytes32 y) internal pure returns (bytes32 z)
```

Returns `x != bytes32(0) ? x : y`, without branching.

### coalesce(address,address)

```solidity
function coalesce(address x, address y) internal pure returns (address z)
```

Returns `x != address(0) ? x : y`, without branching.

### rpow(uint256,uint256,uint256)

```solidity
function rpow(uint256 x, uint256 y, uint256 b)
    internal
    pure
    returns (uint256 z)
```

Exponentiate `x` to `y` by squaring, denominated in base `b`.   
Reverts if the computation overflows.

### sqrt(uint256)

```solidity
function sqrt(uint256 x) internal pure returns (uint256 z)
```

Returns the square root of `x`, rounded down.

### cbrt(uint256)

```solidity
function cbrt(uint256 x) internal pure returns (uint256 z)
```

Returns the cube root of `x`, rounded down.   
Credit to bout3fiddy and pcaversaccio under AGPLv3 license:   
https://github.com/pcaversaccio/snekmate/blob/main/src/snekmate/utils/math.vy   
Formally verified by xuwinnie:   
https://github.com/vectorized/solady/blob/main/audits/xuwinnie-solady-cbrt-proof.pdf

### sqrtWad(uint256)

```solidity
function sqrtWad(uint256 x) internal pure returns (uint256 z)
```

Returns the square root of `x`, denominated in `WAD`, rounded down.

### cbrtWad(uint256)

```solidity
function cbrtWad(uint256 x) internal pure returns (uint256 z)
```

Returns the cube root of `x`, denominated in `WAD`, rounded down.   
Formally verified by xuwinnie:   
https://github.com/vectorized/solady/blob/main/audits/xuwinnie-solady-cbrt-proof.pdf

### mulSqrt(uint256,uint256)

```solidity
function mulSqrt(uint256 x, uint256 y) internal pure returns (uint256 z)
```

Returns `sqrt(x * y)`. Also called the geometric mean.

### factorial(uint256)

```solidity
function factorial(uint256 x) internal pure returns (uint256 z)
```

Returns the factorial of `x`.

### log2(uint256)

```solidity
function log2(uint256 x) internal pure returns (uint256 r)
```

Returns the log2 of `x`.   
Equivalent to computing the index of the most significant bit (MSB) of `x`.   
Returns 0 if `x` is zero.

### log2Up(uint256)

```solidity
function log2Up(uint256 x) internal pure returns (uint256 r)
```

Returns the log2 of `x`, rounded up.   
Returns 0 if `x` is zero.

### log10(uint256)

```solidity
function log10(uint256 x) internal pure returns (uint256 r)
```

Returns the log10 of `x`.   
Returns 0 if `x` is zero.

### log10Up(uint256)

```solidity
function log10Up(uint256 x) internal pure returns (uint256 r)
```

Returns the log10 of `x`, rounded up.   
Returns 0 if `x` is zero.

### log256(uint256)

```solidity
function log256(uint256 x) internal pure returns (uint256 r)
```

Returns the log256 of `x`.   
Returns 0 if `x` is zero.

### log256Up(uint256)

```solidity
function log256Up(uint256 x) internal pure returns (uint256 r)
```

Returns the log256 of `x`, rounded up.   
Returns 0 if `x` is zero.

### sci(uint256)

```solidity
function sci(uint256 x)
    internal
    pure
    returns (uint256 mantissa, uint256 exponent)
```

Returns the scientific notation format `mantissa * 10 ** exponent` of `x`.   
Useful for compressing prices (e.g. using 25 bit mantissa and 7 bit exponent).

### packSci(uint256)

```solidity
function packSci(uint256 x) internal pure returns (uint256 packed)
```

Convenience function for packing `x` into a smaller number using `sci`.   
The `mantissa` will be in bits [7..255] (the upper 249 bits).   
The `exponent` will be in bits [0..6] (the lower 7 bits).   
Use `SafeCastLib` to safely ensure that the `packed` number is small   
enough to fit in the desired unsigned integer type:   
```solidity   
uint32 packed = SafeCastLib.toUint32(FixedPointMathLib.packSci(777 ether));   
```

### unpackSci(uint256)

```solidity
function unpackSci(uint256 packed)
    internal
    pure
    returns (uint256 unpacked)
```

Convenience function for unpacking a packed number from `packSci`.

### avg(uint256,uint256)

```solidity
function avg(uint256 x, uint256 y) internal pure returns (uint256 z)
```

Returns the average of `x` and `y`. Rounds towards zero.

### avg(int256,int256)

```solidity
function avg(int256 x, int256 y) internal pure returns (int256 z)
```

Returns the average of `x` and `y`. Rounds towards negative infinity.

### abs(int256)

```solidity
function abs(int256 x) internal pure returns (uint256 z)
```

Returns the absolute value of `x`.

### dist(uint256,uint256)

```solidity
function dist(uint256 x, uint256 y) internal pure returns (uint256 z)
```

Returns the absolute distance between `x` and `y`.

### dist(int256,int256)

```solidity
function dist(int256 x, int256 y) internal pure returns (uint256 z)
```

Returns the absolute distance between `x` and `y`.

### min(uint256,uint256)

```solidity
function min(uint256 x, uint256 y) internal pure returns (uint256 z)
```

Returns the minimum of `x` and `y`.

### min(int256,int256)

```solidity
function min(int256 x, int256 y) internal pure returns (int256 z)
```

Returns the minimum of `x` and `y`.

### max(uint256,uint256)

```solidity
function max(uint256 x, uint256 y) internal pure returns (uint256 z)
```

Returns the maximum of `x` and `y`.

### max(int256,int256)

```solidity
function max(int256 x, int256 y) internal pure returns (int256 z)
```

Returns the maximum of `x` and `y`.

### clamp(uint256,uint256,uint256)

```solidity
function clamp(uint256 x, uint256 minValue, uint256 maxValue)
    internal
    pure
    returns (uint256 z)
```

Returns `x`, bounded to `minValue` and `maxValue`.

### clamp(int256,int256,int256)

```solidity
function clamp(int256 x, int256 minValue, int256 maxValue)
    internal
    pure
    returns (int256 z)
```

Returns `x`, bounded to `minValue` and `maxValue`.

### gcd(uint256,uint256)

```solidity
function gcd(uint256 x, uint256 y) internal pure returns (uint256 z)
```

Returns greatest common divisor of `x` and `y`.

### lerp(uint256,uint256,uint256,uint256,uint256)

```solidity
function lerp(uint256 a, uint256 b, uint256 t, uint256 begin, uint256 end)
    internal
    pure
    returns (uint256)
```

Returns `a + (b - a) * (t - begin) / (end - begin)`,   
with `t` clamped between `begin` and `end` (inclusive).   
Agnostic to the order of (`a`, `b`) and (`end`, `begin`).   
If `begins == end`, returns `t <= begin ? a : b`.

### lerp(int256,int256,int256,int256,int256)

```solidity
function lerp(int256 a, int256 b, int256 t, int256 begin, int256 end)
    internal
    pure
    returns (int256)
```

Returns `a + (b - a) * (t - begin) / (end - begin)`.   
with `t` clamped between `begin` and `end` (inclusive).   
Agnostic to the order of (`a`, `b`) and (`end`, `begin`).   
If `begins == end`, returns `t <= begin ? a : b`.

### isEven(uint256)

```solidity
function isEven(uint256 x) internal pure returns (bool)
```

Returns if `x` is an even number. Some people may need this.

## Raw Number Operations

### rawAdd(uint256,uint256)

```solidity
function rawAdd(uint256 x, uint256 y) internal pure returns (uint256 z)
```

Returns `x + y`, without checking for overflow.

### rawAdd(int256,int256)

```solidity
function rawAdd(int256 x, int256 y) internal pure returns (int256 z)
```

Returns `x + y`, without checking for overflow.

### rawSub(uint256,uint256)

```solidity
function rawSub(uint256 x, uint256 y) internal pure returns (uint256 z)
```

Returns `x - y`, without checking for underflow.

### rawSub(int256,int256)

```solidity
function rawSub(int256 x, int256 y) internal pure returns (int256 z)
```

Returns `x - y`, without checking for underflow.

### rawMul(uint256,uint256)

```solidity
function rawMul(uint256 x, uint256 y) internal pure returns (uint256 z)
```

Returns `x * y`, without checking for overflow.

### rawMul(int256,int256)

```solidity
function rawMul(int256 x, int256 y) internal pure returns (int256 z)
```

Returns `x * y`, without checking for overflow.

### rawDiv(uint256,uint256)

```solidity
function rawDiv(uint256 x, uint256 y) internal pure returns (uint256 z)
```

Returns `x / y`, returning 0 if `y` is zero.

### rawSDiv(int256,int256)

```solidity
function rawSDiv(int256 x, int256 y) internal pure returns (int256 z)
```

Returns `x / y`, returning 0 if `y` is zero.

### rawMod(uint256,uint256)

```solidity
function rawMod(uint256 x, uint256 y) internal pure returns (uint256 z)
```

Returns `x % y`, returning 0 if `y` is zero.

### rawSMod(int256,int256)

```solidity
function rawSMod(int256 x, int256 y) internal pure returns (int256 z)
```

Returns `x % y`, returning 0 if `y` is zero.

### rawAddMod(uint256,uint256,uint256)

```solidity
function rawAddMod(uint256 x, uint256 y, uint256 d)
    internal
    pure
    returns (uint256 z)
```

Returns `(x + y) % d`, return 0 if `d` if zero.

### rawMulMod(uint256,uint256,uint256)

```solidity
function rawMulMod(uint256 x, uint256 y, uint256 d)
    internal
    pure
    returns (uint256 z)
```

Returns `(x * y) % d`, return 0 if `d` if zero.