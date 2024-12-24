# LibBitmap

Library for storage of packed unsigned booleans.






<!-- customintro:start --><!-- customintro:end -->

## Constants

### NOT_FOUND

```solidity
uint256 internal constant NOT_FOUND = type(uint256).max
```

The constant returned when a bitmap scan does not find a result.

## Structs

### Bitmap

```solidity
struct Bitmap {
    mapping(uint256 => uint256) map;
}
```

A bitmap in storage.

## Operations

### get(Bitmap,uint256)

```solidity
function get(Bitmap storage bitmap, uint256 index)
    internal
    view
    returns (bool isSet)
```

Returns the boolean value of the bit at `index` in `bitmap`.

### set(Bitmap,uint256)

```solidity
function set(Bitmap storage bitmap, uint256 index) internal
```

Updates the bit at `index` in `bitmap` to true.

### unset(Bitmap,uint256)

```solidity
function unset(Bitmap storage bitmap, uint256 index) internal
```

Updates the bit at `index` in `bitmap` to false.

### toggle(Bitmap,uint256)

```solidity
function toggle(Bitmap storage bitmap, uint256 index)
    internal
    returns (bool newIsSet)
```

Flips the bit at `index` in `bitmap`.   
Returns the boolean result of the flipped bit.

### setTo(Bitmap,uint256,bool)

```solidity
function setTo(Bitmap storage bitmap, uint256 index, bool shouldSet)
    internal
```

Updates the bit at `index` in `bitmap` to `shouldSet`.

### setBatch(Bitmap,uint256,uint256)

```solidity
function setBatch(Bitmap storage bitmap, uint256 start, uint256 amount)
    internal
```

Consecutively sets `amount` of bits starting from the bit at `start`.

### unsetBatch(Bitmap,uint256,uint256)

```solidity
function unsetBatch(Bitmap storage bitmap, uint256 start, uint256 amount)
    internal
```

Consecutively unsets `amount` of bits starting from the bit at `start`.

### popCount(Bitmap,uint256,uint256)

```solidity
function popCount(Bitmap storage bitmap, uint256 start, uint256 amount)
    internal
    view
    returns (uint256 count)
```

Returns number of set bits within a range by   
scanning `amount` of bits starting from the bit at `start`.

### findLastSet(Bitmap,uint256)

```solidity
function findLastSet(Bitmap storage bitmap, uint256 upTo)
    internal
    view
    returns (uint256 setBitIndex)
```

Returns the index of the most significant set bit in `[0..upTo]`.   
If no set bit is found, returns `NOT_FOUND`.

### findFirstUnset(Bitmap,uint256,uint256)

```solidity
function findFirstUnset(Bitmap storage bitmap, uint256 begin, uint256 upTo)
    internal
    view
    returns (uint256 unsetBitIndex)
```

Returns the index of the least significant unset bit in `[begin..upTo]`.   
If no unset bit is found, returns `NOT_FOUND`.