# LibPRNG

Library for generating pseudorandom numbers.






<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### InvalidInitialLazyShufflerLength()

```solidity
error InvalidInitialLazyShufflerLength()
```

The initial length must be greater than zero and less than `2**32 - 1`.

### InvalidNewLazyShufflerLength()

```solidity
error InvalidNewLazyShufflerLength()
```

The new length must not be less than the current length.

### LazyShufflerNotInitialized()

```solidity
error LazyShufflerNotInitialized()
```

The lazy shuffler has not been initialized.

### LazyShufflerAlreadyInitialized()

```solidity
error LazyShufflerAlreadyInitialized()
```

Cannot double initialize the lazy shuffler.

### LazyShuffleFinished()

```solidity
error LazyShuffleFinished()
```

The lazy shuffle has finished.

### LazyShufflerGetOutOfBounds()

```solidity
error LazyShufflerGetOutOfBounds()
```

The queried index is out of bounds.

## Constants

### WAD

```solidity
uint256 internal constant WAD = 1e18
```

The scalar of ETH and most ERC20s.

## Structs

### PRNG

```solidity
struct PRNG {
    uint256 state;
}
```

A pseudorandom number state in memory.

### LazyShuffler

```solidity
struct LazyShuffler {
    // Bits Layout:
    // - [0..31]    `numShuffled`
    // - [32..223]  `permutationSlot`
    // - [224..255] `length`
    uint256 _state;
}
```

A lazy Fisher-Yates shuffler for a range `[0..n)` in storage.

## Operations

### seed(PRNG,uint256)

```solidity
function seed(PRNG memory prng, uint256 state) internal pure
```

Seeds the `prng` with `state`.

### next(PRNG)

```solidity
function next(PRNG memory prng) internal pure returns (uint256 result)
```

Returns the next pseudorandom uint256.   
All bits of the returned uint256 pass the NIST Statistical Test Suite.

### uniform(PRNG,uint256)

```solidity
function uniform(PRNG memory prng, uint256 upper)
    internal
    pure
    returns (uint256 result)
```

Returns a pseudorandom uint256, uniformly distributed   
between 0 (inclusive) and `upper` (exclusive).   
If your modulus is big, this method is recommended   
for uniform sampling to avoid modulo bias.   
For uniform sampling across all uint256 values,   
or for small enough moduli such that the bias is negligible,   
use {next} instead.

### standardNormalWad(PRNG)

```solidity
function standardNormalWad(PRNG memory prng)
    internal
    pure
    returns (int256 result)
```

Returns a sample from the standard normal distribution denominated in `WAD`.

### exponentialWad(PRNG)

```solidity
function exponentialWad(PRNG memory prng)
    internal
    pure
    returns (uint256 result)
```

Returns a sample from the unit exponential distribution denominated in `WAD`.

## Memory Array Shuffling Operations

### shuffle(PRNG,uint256[])

```solidity
function shuffle(PRNG memory prng, uint256[] memory a) internal pure
```

Shuffles the array in-place with Fisher-Yates shuffle.

### shuffle(PRNG,int256[])

```solidity
function shuffle(PRNG memory prng, int256[] memory a) internal pure
```

Shuffles the array in-place with Fisher-Yates shuffle.

### shuffle(PRNG,address[])

```solidity
function shuffle(PRNG memory prng, address[] memory a) internal pure
```

Shuffles the array in-place with Fisher-Yates shuffle.

### shuffle(PRNG,uint256[],uint256)

```solidity
function shuffle(PRNG memory prng, uint256[] memory a, uint256 k)
    internal
    pure
```

Partially shuffles the array in-place with Fisher-Yates shuffle.   
The first `k` elements will be uniformly sampled without replacement.

### shuffle(PRNG,int256[],uint256)

```solidity
function shuffle(PRNG memory prng, int256[] memory a, uint256 k)
    internal
    pure
```

Partially shuffles the array in-place with Fisher-Yates shuffle.   
The first `k` elements will be uniformly sampled without replacement.

### shuffle(PRNG,address[],uint256)

```solidity
function shuffle(PRNG memory prng, address[] memory a, uint256 k)
    internal
    pure
```

Partially shuffles the array in-place with Fisher-Yates shuffle.   
The first `k` elements will be uniformly sampled without replacement.

### shuffle(PRNG,bytes)

```solidity
function shuffle(PRNG memory prng, bytes memory a) internal pure
```

Shuffles the bytes in-place with Fisher-Yates shuffle.

## Storage-based Range Lazy Shuffling Operations

### initialize(LazyShuffler,uint256)

```solidity
function initialize(LazyShuffler storage $, uint256 n) internal
```

Initializes the state for lazy-shuffling the range `[0..n)`.   
Reverts if `n == 0 || n >= 2**32 - 1`.   
Reverts if `$` has already been initialized.   
If you need to reduce the length after initialization, just use a fresh new `$`.

### grow(LazyShuffler,uint256)

```solidity
function grow(LazyShuffler storage $, uint256 n) internal
```

Increases the length of `$`.   
Reverts if `$` has not been initialized.

### restart(LazyShuffler)

```solidity
function restart(LazyShuffler storage $) internal
```

Restarts the shuffler by setting `numShuffled` to zero,   
such that all elements can be drawn again.   
Restarting does NOT clear the internal permutation, nor changes the length.   
Even with the same sequence of randomness, reshuffling can yield different results.

### numShuffled(LazyShuffler)

```solidity
function numShuffled(LazyShuffler storage $)
    internal
    view
    returns (uint256 result)
```

Returns the number of elements that have been shuffled.

### length(LazyShuffler)

```solidity
function length(LazyShuffler storage $)
    internal
    view
    returns (uint256 result)
```

Returns the length of `$`.   
Returns zero if `$` is not initialized, else a non-zero value less than `2**32 - 1`.

### initialized(LazyShuffler)

```solidity
function initialized(LazyShuffler storage $)
    internal
    view
    returns (bool result)
```

Returns if `$` has been initialized.

### finished(LazyShuffler)

```solidity
function finished(LazyShuffler storage $)
    internal
    view
    returns (bool result)
```

Returns if there are any more elements left to shuffle.   
Reverts if `$` is not initialized.

### get(LazyShuffler,uint256)

```solidity
function get(LazyShuffler storage $, uint256 index)
    internal
    view
    returns (uint256 result)
```

Returns the current value stored at `index`, accounting for all historical shuffling.   
Reverts if `index` is greater than or equal to the `length` of `$`.

### next(LazyShuffler,uint256)

```solidity
function next(LazyShuffler storage $, uint256 randomness)
    internal
    returns (uint256 chosen)
```

Does a single Fisher-Yates shuffle step, increments the `numShuffled` in `$`,   
and returns the next value in the shuffled range.   
`randomness` can be taken from a good-enough source, or a higher quality source like VRF.   
Reverts if there are no more values to shuffle, which includes the case if `$` is not initialized.