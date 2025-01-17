# DynamicArrayLib

Library for memory arrays with automatic capacity resizing.






<!-- customintro:start --><!-- customintro:end -->

## Structs

### DynamicArray

```solidity
struct DynamicArray {
    uint256[] data;
}
```

Type to represent a dynamic array in memory.   
You can directly assign to `data`, and the `p` function will   
take care of the memory allocation.

## Constants

### NOT_FOUND

```solidity
uint256 internal constant NOT_FOUND = type(uint256).max
```

The constant returned when the element is not found in the array.

## Uint256 Array Operations

Low level minimalist uint256 array operations.   
If you don't need syntax sugar, it's recommended to use these.   
Some of these functions returns the same array for function chaining.   
e.g. `array.set(0, 1).set(1, 2)`.

### malloc(uint256)

```solidity
function malloc(uint256 n)
    internal
    pure
    returns (uint256[] memory result)
```

Returns a uint256 array with `n` elements. The elements are not zeroized.

### zeroize(uint256[])

```solidity
function zeroize(uint256[] memory a)
    internal
    pure
    returns (uint256[] memory result)
```

Zeroizes all the elements of `a`.

### get(uint256[],uint256)

```solidity
function get(uint256[] memory a, uint256 i)
    internal
    pure
    returns (uint256 result)
```

Returns the element at `a[i]`, without bounds checking.

### getUint256(uint256[],uint256)

```solidity
function getUint256(uint256[] memory a, uint256 i)
    internal
    pure
    returns (uint256 result)
```

Returns the element at `a[i]`, without bounds checking.

### getAddress(uint256[],uint256)

```solidity
function getAddress(uint256[] memory a, uint256 i)
    internal
    pure
    returns (address result)
```

Returns the element at `a[i]`, without bounds checking.

### getBool(uint256[],uint256)

```solidity
function getBool(uint256[] memory a, uint256 i)
    internal
    pure
    returns (bool result)
```

Returns the element at `a[i]`, without bounds checking.

### getBytes32(uint256[],uint256)

```solidity
function getBytes32(uint256[] memory a, uint256 i)
    internal
    pure
    returns (bytes32 result)
```

Returns the element at `a[i]`, without bounds checking.

### set(uint256[],uint256,uint256)

```solidity
function set(uint256[] memory a, uint256 i, uint256 data)
    internal
    pure
    returns (uint256[] memory result)
```

Sets `a.data[i]` to `data`, without bounds checking.

### set(uint256[],uint256,address)

```solidity
function set(uint256[] memory a, uint256 i, address data)
    internal
    pure
    returns (uint256[] memory result)
```

Sets `a.data[i]` to `data`, without bounds checking.

### set(uint256[],uint256,bool)

```solidity
function set(uint256[] memory a, uint256 i, bool data)
    internal
    pure
    returns (uint256[] memory result)
```

Sets `a.data[i]` to `data`, without bounds checking.

### set(uint256[],uint256,bytes32)

```solidity
function set(uint256[] memory a, uint256 i, bytes32 data)
    internal
    pure
    returns (uint256[] memory result)
```

Sets `a.data[i]` to `data`, without bounds checking.

### asAddressArray(uint256[])

```solidity
function asAddressArray(uint256[] memory a)
    internal
    pure
    returns (address[] memory result)
```

Casts `a` to `address[]`.

### asBoolArray(uint256[])

```solidity
function asBoolArray(uint256[] memory a)
    internal
    pure
    returns (bool[] memory result)
```

Casts `a` to `bool[]`.

### asBytes32Array(uint256[])

```solidity
function asBytes32Array(uint256[] memory a)
    internal
    pure
    returns (bytes32[] memory result)
```

Casts `a` to `bytes32[]`.

### toUint256Array(address[])

```solidity
function toUint256Array(address[] memory a)
    internal
    pure
    returns (uint256[] memory result)
```

Casts `a` to `uint256[]`.

### toUint256Array(bool[])

```solidity
function toUint256Array(bool[] memory a)
    internal
    pure
    returns (uint256[] memory result)
```

Casts `a` to `uint256[]`.

### toUint256Array(bytes32[])

```solidity
function toUint256Array(bytes32[] memory a)
    internal
    pure
    returns (uint256[] memory result)
```

Casts `a` to `uint256[]`.

### truncate(uint256[],uint256)

```solidity
function truncate(uint256[] memory a, uint256 n)
    internal
    pure
    returns (uint256[] memory result)
```

Reduces the size of `a` to `n`.   
If `n` is greater than the size of `a`, this will be a no-op.

### free(uint256[])

```solidity
function free(uint256[] memory a)
    internal
    pure
    returns (uint256[] memory result)
```

Clears the array and attempts to free the memory if possible.

### hash(uint256[])

```solidity
function hash(uint256[] memory a) internal pure returns (bytes32 result)
```

Equivalent to `keccak256(abi.encodePacked(a))`.

### slice(uint256[],uint256,uint256)

```solidity
function slice(uint256[] memory a, uint256 start, uint256 end)
    internal
    pure
    returns (uint256[] memory result)
```

Returns a copy of `a` sliced from `start` to `end` (exclusive).

### slice(uint256[],uint256)

```solidity
function slice(uint256[] memory a, uint256 start)
    internal
    pure
    returns (uint256[] memory result)
```

Returns a copy of `a` sliced from `start` to the end of the array.

### copy(uint256[])

```solidity
function copy(uint256[] memory a)
    internal
    pure
    returns (uint256[] memory result)
```

Returns a copy of the array.

### contains(uint256[],uint256)

```solidity
function contains(uint256[] memory a, uint256 needle)
    internal
    pure
    returns (bool)
```

Returns if `needle` is in `a`.

### indexOf(uint256[],uint256,uint256)

```solidity
function indexOf(uint256[] memory a, uint256 needle, uint256 from)
    internal
    pure
    returns (uint256 result)
```

Returns the first index of `needle`, scanning forward from `from`.   
If `needle` is not in `a`, returns `NOT_FOUND`.

### indexOf(uint256[],uint256)

```solidity
function indexOf(uint256[] memory a, uint256 needle)
    internal
    pure
    returns (uint256 result)
```

Returns the first index of `needle`.   
If `needle` is not in `a`, returns `NOT_FOUND`.

### lastIndexOf(uint256[],uint256,uint256)

```solidity
function lastIndexOf(uint256[] memory a, uint256 needle, uint256 from)
    internal
    pure
    returns (uint256 result)
```

Returns the last index of `needle`, scanning backwards from `from`.   
If `needle` is not in `a`, returns `NOT_FOUND`.

### lastIndexOf(uint256[],uint256)

```solidity
function lastIndexOf(uint256[] memory a, uint256 needle)
    internal
    pure
    returns (uint256 result)
```

Returns the first index of `needle`.   
If `needle` is not in `a`, returns `NOT_FOUND`.

### directReturn(uint256[])

```solidity
function directReturn(uint256[] memory a) internal pure
```

Directly returns `a` without copying.

## Dynamic Array Operations

Some of these functions returns the same array for function chaining.   
e.g. `a.p("1").p("2")`.

### length(DynamicArray)

```solidity
function length(DynamicArray memory a) internal pure returns (uint256)
```

Shorthand for `a.data.length`.

### wrap(uint256[])

```solidity
function wrap(uint256[] memory a)
    internal
    pure
    returns (DynamicArray memory result)
```

Wraps `a` in a dynamic array struct.

### wrap(address[])

```solidity
function wrap(address[] memory a)
    internal
    pure
    returns (DynamicArray memory result)
```

Wraps `a` in a dynamic array struct.

### wrap(bool[])

```solidity
function wrap(bool[] memory a)
    internal
    pure
    returns (DynamicArray memory result)
```

Wraps `a` in a dynamic array struct.

### wrap(bytes32[])

```solidity
function wrap(bytes32[] memory a)
    internal
    pure
    returns (DynamicArray memory result)
```

Wraps `a` in a dynamic array struct.

### clear(DynamicArray)

```solidity
function clear(DynamicArray memory a)
    internal
    pure
    returns (DynamicArray memory result)
```

Clears the array without deallocating the memory.

### free(DynamicArray)

```solidity
function free(DynamicArray memory a)
    internal
    pure
    returns (DynamicArray memory result)
```

Clears the array and attempts to free the memory if possible.

### resize(DynamicArray,uint256)

```solidity
function resize(DynamicArray memory a, uint256 n)
    internal
    pure
    returns (DynamicArray memory result)
```

Resizes the array to contain `n` elements. New elements will be zeroized.

### expand(DynamicArray,uint256)

```solidity
function expand(DynamicArray memory a, uint256 n)
    internal
    pure
    returns (DynamicArray memory result)
```

Increases the size of `a` to `n`.   
If `n` is less than the size of `a`, this will be a no-op.   
This method does not zeroize any newly created elements.

### truncate(DynamicArray,uint256)

```solidity
function truncate(DynamicArray memory a, uint256 n)
    internal
    pure
    returns (DynamicArray memory result)
```

Reduces the size of `a` to `n`.   
If `n` is greater than the size of `a`, this will be a no-op.

### reserve(DynamicArray,uint256)

```solidity
function reserve(DynamicArray memory a, uint256 minimum)
    internal
    pure
    returns (DynamicArray memory result)
```

Reserves at least `minimum` amount of contiguous memory.

### p(DynamicArray,uint256)

```solidity
function p(DynamicArray memory a, uint256 data)
    internal
    pure
    returns (DynamicArray memory result)
```

Appends `data` to `a`.

### p(DynamicArray,address)

```solidity
function p(DynamicArray memory a, address data)
    internal
    pure
    returns (DynamicArray memory result)
```

Appends `data` to `a`.

### p(DynamicArray,bool)

```solidity
function p(DynamicArray memory a, bool data)
    internal
    pure
    returns (DynamicArray memory result)
```

Appends `data` to `a`.

### p(DynamicArray,bytes32)

```solidity
function p(DynamicArray memory a, bytes32 data)
    internal
    pure
    returns (DynamicArray memory result)
```

Appends `data` to `a`.

### p()

```solidity
function p() internal pure returns (DynamicArray memory result)
```

Shorthand for returning an empty array.

### p(uint256)

```solidity
function p(uint256 data)
    internal
    pure
    returns (DynamicArray memory result)
```

Shorthand for `p(p(), data)`.

### p(address)

```solidity
function p(address data)
    internal
    pure
    returns (DynamicArray memory result)
```

Shorthand for `p(p(), data)`.

### p(bool)

```solidity
function p(bool data) internal pure returns (DynamicArray memory result)
```

Shorthand for `p(p(), data)`.

### p(bytes32)

```solidity
function p(bytes32 data)
    internal
    pure
    returns (DynamicArray memory result)
```

Shorthand for `p(p(), data)`.

### pop(DynamicArray)

```solidity
function pop(DynamicArray memory a)
    internal
    pure
    returns (uint256 result)
```

Removes and returns the last element of `a`.   
Returns 0 and does not pop anything if the array is empty.

### popUint256(DynamicArray)

```solidity
function popUint256(DynamicArray memory a)
    internal
    pure
    returns (uint256 result)
```

Removes and returns the last element of `a`.   
Returns 0 and does not pop anything if the array is empty.

### popAddress(DynamicArray)

```solidity
function popAddress(DynamicArray memory a)
    internal
    pure
    returns (address result)
```

Removes and returns the last element of `a`.   
Returns 0 and does not pop anything if the array is empty.

### popBool(DynamicArray)

```solidity
function popBool(DynamicArray memory a)
    internal
    pure
    returns (bool result)
```

Removes and returns the last element of `a`.   
Returns 0 and does not pop anything if the array is empty.

### popBytes32(DynamicArray)

```solidity
function popBytes32(DynamicArray memory a)
    internal
    pure
    returns (bytes32 result)
```

Removes and returns the last element of `a`.   
Returns 0 and does not pop anything if the array is empty.

### get(DynamicArray,uint256)

```solidity
function get(DynamicArray memory a, uint256 i)
    internal
    pure
    returns (uint256 result)
```

Returns the element at `a.data[i]`, without bounds checking.

### getUint256(DynamicArray,uint256)

```solidity
function getUint256(DynamicArray memory a, uint256 i)
    internal
    pure
    returns (uint256 result)
```

Returns the element at `a.data[i]`, without bounds checking.

### getAddress(DynamicArray,uint256)

```solidity
function getAddress(DynamicArray memory a, uint256 i)
    internal
    pure
    returns (address result)
```

Returns the element at `a.data[i]`, without bounds checking.

### getBool(DynamicArray,uint256)

```solidity
function getBool(DynamicArray memory a, uint256 i)
    internal
    pure
    returns (bool result)
```

Returns the element at `a.data[i]`, without bounds checking.

### getBytes32(DynamicArray,uint256)

```solidity
function getBytes32(DynamicArray memory a, uint256 i)
    internal
    pure
    returns (bytes32 result)
```

Returns the element at `a.data[i]`, without bounds checking.

### set(DynamicArray,uint256,uint256)

```solidity
function set(DynamicArray memory a, uint256 i, uint256 data)
    internal
    pure
    returns (DynamicArray memory result)
```

Sets `a.data[i]` to `data`, without bounds checking.

### set(DynamicArray,uint256,address)

```solidity
function set(DynamicArray memory a, uint256 i, address data)
    internal
    pure
    returns (DynamicArray memory result)
```

Sets `a.data[i]` to `data`, without bounds checking.

### set(DynamicArray,uint256,bool)

```solidity
function set(DynamicArray memory a, uint256 i, bool data)
    internal
    pure
    returns (DynamicArray memory result)
```

Sets `a.data[i]` to `data`, without bounds checking.

### set(DynamicArray,uint256,bytes32)

```solidity
function set(DynamicArray memory a, uint256 i, bytes32 data)
    internal
    pure
    returns (DynamicArray memory result)
```

Sets `a.data[i]` to `data`, without bounds checking.

### asUint256Array(DynamicArray)

```solidity
function asUint256Array(DynamicArray memory a)
    internal
    pure
    returns (uint256[] memory result)
```

Returns the underlying array as a `uint256[]`.

### asAddressArray(DynamicArray)

```solidity
function asAddressArray(DynamicArray memory a)
    internal
    pure
    returns (address[] memory result)
```

Returns the underlying array as a `address[]`.

### asBoolArray(DynamicArray)

```solidity
function asBoolArray(DynamicArray memory a)
    internal
    pure
    returns (bool[] memory result)
```

Returns the underlying array as a `bool[]`.

### asBytes32Array(DynamicArray)

```solidity
function asBytes32Array(DynamicArray memory a)
    internal
    pure
    returns (bytes32[] memory result)
```

Returns the underlying array as a `bytes32[]`.

### slice(DynamicArray,uint256,uint256)

```solidity
function slice(DynamicArray memory a, uint256 start, uint256 end)
    internal
    pure
    returns (DynamicArray memory result)
```

Returns a copy of `a` sliced from `start` to `end` (exclusive).

### slice(DynamicArray,uint256)

```solidity
function slice(DynamicArray memory a, uint256 start)
    internal
    pure
    returns (DynamicArray memory result)
```

Returns a copy of `a` sliced from `start` to the end of the array.

### copy(DynamicArray)

```solidity
function copy(DynamicArray memory a)
    internal
    pure
    returns (DynamicArray memory result)
```

Returns a copy of `a`.

### contains(DynamicArray,uint256)

```solidity
function contains(DynamicArray memory a, uint256 needle)
    internal
    pure
    returns (bool)
```

Returns if `needle` is in `a`.

### contains(DynamicArray,address)

```solidity
function contains(DynamicArray memory a, address needle)
    internal
    pure
    returns (bool)
```

Returns if `needle` is in `a`.

### contains(DynamicArray,bytes32)

```solidity
function contains(DynamicArray memory a, bytes32 needle)
    internal
    pure
    returns (bool)
```

Returns if `needle` is in `a`.

### indexOf(DynamicArray,uint256,uint256)

```solidity
function indexOf(DynamicArray memory a, uint256 needle, uint256 from)
    internal
    pure
    returns (uint256)
```

Returns the first index of `needle`, scanning forward from `from`.   
If `needle` is not in `a`, returns `NOT_FOUND`.

### indexOf(DynamicArray,address,uint256)

```solidity
function indexOf(DynamicArray memory a, address needle, uint256 from)
    internal
    pure
    returns (uint256)
```

Returns the first index of `needle`, scanning forward from `from`.   
If `needle` is not in `a`, returns `NOT_FOUND`.

### indexOf(DynamicArray,bytes32,uint256)

```solidity
function indexOf(DynamicArray memory a, bytes32 needle, uint256 from)
    internal
    pure
    returns (uint256)
```

Returns the first index of `needle`, scanning forward from `from`.   
If `needle` is not in `a`, returns `NOT_FOUND`.

### indexOf(DynamicArray,uint256)

```solidity
function indexOf(DynamicArray memory a, uint256 needle)
    internal
    pure
    returns (uint256)
```

Returns the first index of `needle`.   
If `needle` is not in `a`, returns `NOT_FOUND`.

### indexOf(DynamicArray,address)

```solidity
function indexOf(DynamicArray memory a, address needle)
    internal
    pure
    returns (uint256)
```

Returns the first index of `needle`.   
If `needle` is not in `a`, returns `NOT_FOUND`.

### indexOf(DynamicArray,bytes32)

```solidity
function indexOf(DynamicArray memory a, bytes32 needle)
    internal
    pure
    returns (uint256)
```

Returns the first index of `needle`.   
If `needle` is not in `a`, returns `NOT_FOUND`.

### lastIndexOf(DynamicArray,uint256,uint256)

```solidity
function lastIndexOf(DynamicArray memory a, uint256 needle, uint256 from)
    internal
    pure
    returns (uint256)
```

Returns the last index of `needle`, scanning backwards from `from`.   
If `needle` is not in `a`, returns `NOT_FOUND`.

### lastIndexOf(DynamicArray,address,uint256)

```solidity
function lastIndexOf(DynamicArray memory a, address needle, uint256 from)
    internal
    pure
    returns (uint256)
```

Returns the last index of `needle`, scanning backwards from `from`.   
If `needle` is not in `a`, returns `NOT_FOUND`.

### lastIndexOf(DynamicArray,bytes32,uint256)

```solidity
function lastIndexOf(DynamicArray memory a, bytes32 needle, uint256 from)
    internal
    pure
    returns (uint256)
```

Returns the last index of `needle`, scanning backwards from `from`.   
If `needle` is not in `a`, returns `NOT_FOUND`.

### lastIndexOf(DynamicArray,uint256)

```solidity
function lastIndexOf(DynamicArray memory a, uint256 needle)
    internal
    pure
    returns (uint256)
```

Returns the last index of `needle`.   
If `needle` is not in `a`, returns `NOT_FOUND`.

### lastIndexOf(DynamicArray,address)

```solidity
function lastIndexOf(DynamicArray memory a, address needle)
    internal
    pure
    returns (uint256)
```

Returns the last index of `needle`.   
If `needle` is not in `a`, returns `NOT_FOUND`.

### lastIndexOf(DynamicArray,bytes32)

```solidity
function lastIndexOf(DynamicArray memory a, bytes32 needle)
    internal
    pure
    returns (uint256)
```

Returns the last index of `needle`.   
If `needle` is not in `a`, returns `NOT_FOUND`.

### hash(DynamicArray)

```solidity
function hash(DynamicArray memory a)
    internal
    pure
    returns (bytes32 result)
```

Equivalent to `keccak256(abi.encodePacked(a.data))`.

### directReturn(DynamicArray)

```solidity
function directReturn(DynamicArray memory a) internal pure
```

Directly returns `a` without copying.