# LibSort

Optimized sorts and operations for sorted arrays.






<!-- customintro:start --><!-- customintro:end -->

## Insertion Sort

- Faster on small arrays (32 or lesser elements).   
- Faster on almost sorted arrays.   
- Smaller bytecode (about 300 bytes smaller than sort, which uses intro-quicksort).   
- May be suitable for view functions intended for off-chain querying.

### insertionSort(uint256[])

```solidity
function insertionSort(uint256[] memory a) internal pure
```

Sorts the array in-place with insertion sort.

### insertionSort(int256[])

```solidity
function insertionSort(int256[] memory a) internal pure
```

Sorts the array in-place with insertion sort.

### insertionSort(address[])

```solidity
function insertionSort(address[] memory a) internal pure
```

Sorts the array in-place with insertion sort.

### insertionSort(bytes32[])

```solidity
function insertionSort(bytes32[] memory a) internal pure
```

Sorts the array in-place with insertion sort.

## Intro-quicksort

- Faster on larger arrays (more than 32 elements).   
- Robust performance.   
- Larger bytecode.

### sort(uint256[])

```solidity
function sort(uint256[] memory a) internal pure
```

Sorts the array in-place with intro-quicksort.

### sort(int256[])

```solidity
function sort(int256[] memory a) internal pure
```

Sorts the array in-place with intro-quicksort.

### sort(address[])

```solidity
function sort(address[] memory a) internal pure
```

Sorts the array in-place with intro-quicksort.

### sort(bytes32[])

```solidity
function sort(bytes32[] memory a) internal pure
```

Sorts the array in-place with intro-quicksort.

## Other Useful Operations

For performance, the `uniquifySorted` methods will not revert if the   
array is not sorted -- it will simply remove consecutive duplicate elements.

### uniquifySorted(uint256[])

```solidity
function uniquifySorted(uint256[] memory a) internal pure
```

Removes duplicate elements from a ascendingly sorted memory array.

### uniquifySorted(int256[])

```solidity
function uniquifySorted(int256[] memory a) internal pure
```

Removes duplicate elements from a ascendingly sorted memory array.

### uniquifySorted(address[])

```solidity
function uniquifySorted(address[] memory a) internal pure
```

Removes duplicate elements from a ascendingly sorted memory array.

### uniquifySorted(bytes32[])

```solidity
function uniquifySorted(bytes32[] memory a) internal pure
```

Removes duplicate elements from a ascendingly sorted memory array.

### searchSorted(uint256[],uint256)

```solidity
function searchSorted(uint256[] memory a, uint256 needle)
    internal
    pure
    returns (bool found, uint256 index)
```

Returns whether `a` contains `needle`, and the index of `needle`.   
`index` precedence: equal to > nearest before > nearest after.

### searchSorted(int256[],int256)

```solidity
function searchSorted(int256[] memory a, int256 needle)
    internal
    pure
    returns (bool found, uint256 index)
```

Returns whether `a` contains `needle`, and the index of `needle`.   
`index` precedence: equal to > nearest before > nearest after.

### searchSorted(address[],address)

```solidity
function searchSorted(address[] memory a, address needle)
    internal
    pure
    returns (bool found, uint256 index)
```

Returns whether `a` contains `needle`, and the index of `needle`.   
`index` precedence: equal to > nearest before > nearest after.

### searchSorted(bytes32[],bytes32)

```solidity
function searchSorted(bytes32[] memory a, bytes32 needle)
    internal
    pure
    returns (bool found, uint256 index)
```

Returns whether `a` contains `needle`, and the index of `needle`.   
`index` precedence: equal to > nearest before > nearest after.

### inSorted(uint256[],uint256)

```solidity
function inSorted(uint256[] memory a, uint256 needle)
    internal
    pure
    returns (bool found)
```

Returns whether `a` contains `needle`.

### inSorted(int256[],int256)

```solidity
function inSorted(int256[] memory a, int256 needle)
    internal
    pure
    returns (bool found)
```

Returns whether `a` contains `needle`.

### inSorted(address[],address)

```solidity
function inSorted(address[] memory a, address needle)
    internal
    pure
    returns (bool found)
```

Returns whether `a` contains `needle`.

### inSorted(bytes32[],bytes32)

```solidity
function inSorted(bytes32[] memory a, bytes32 needle)
    internal
    pure
    returns (bool found)
```

Returns whether `a` contains `needle`.

### reverse(uint256[])

```solidity
function reverse(uint256[] memory a) internal pure
```

Reverses the array in-place.

### reverse(int256[])

```solidity
function reverse(int256[] memory a) internal pure
```

Reverses the array in-place.

### reverse(address[])

```solidity
function reverse(address[] memory a) internal pure
```

Reverses the array in-place.

### reverse(bytes32[])

```solidity
function reverse(bytes32[] memory a) internal pure
```

Reverses the array in-place.

### copy(uint256[])

```solidity
function copy(uint256[] memory a)
    internal
    pure
    returns (uint256[] memory result)
```

Returns a copy of the array.

### copy(int256[])

```solidity
function copy(int256[] memory a)
    internal
    pure
    returns (int256[] memory result)
```

Returns a copy of the array.

### copy(address[])

```solidity
function copy(address[] memory a)
    internal
    pure
    returns (address[] memory result)
```

Returns a copy of the array.

### copy(bytes32[])

```solidity
function copy(bytes32[] memory a)
    internal
    pure
    returns (bytes32[] memory result)
```

Returns a copy of the array.

### isSorted(uint256[])

```solidity
function isSorted(uint256[] memory a) internal pure returns (bool result)
```

Returns whether the array is sorted in ascending order.

### isSorted(int256[])

```solidity
function isSorted(int256[] memory a) internal pure returns (bool result)
```

Returns whether the array is sorted in ascending order.

### isSorted(address[])

```solidity
function isSorted(address[] memory a) internal pure returns (bool result)
```

Returns whether the array is sorted in ascending order.

### isSorted(bytes32[])

```solidity
function isSorted(bytes32[] memory a) internal pure returns (bool result)
```

Returns whether the array is sorted in ascending order.

### isSortedAndUniquified(uint256[])

```solidity
function isSortedAndUniquified(uint256[] memory a)
    internal
    pure
    returns (bool result)
```

Returns whether the array is strictly ascending (sorted and uniquified).

### isSortedAndUniquified(int256[])

```solidity
function isSortedAndUniquified(int256[] memory a)
    internal
    pure
    returns (bool result)
```

Returns whether the array is strictly ascending (sorted and uniquified).

### isSortedAndUniquified(address[])

```solidity
function isSortedAndUniquified(address[] memory a)
    internal
    pure
    returns (bool result)
```

Returns whether the array is strictly ascending (sorted and uniquified).

### isSortedAndUniquified(bytes32[])

```solidity
function isSortedAndUniquified(bytes32[] memory a)
    internal
    pure
    returns (bool result)
```

Returns whether the array is strictly ascending (sorted and uniquified).

### difference(uint256[],uint256[])

```solidity
function difference(uint256[] memory a, uint256[] memory b)
    internal
    pure
    returns (uint256[] memory c)
```

Returns the sorted set difference of `a` and `b`.   
Note: Behaviour is undefined if inputs are not sorted and uniquified.

### difference(int256[],int256[])

```solidity
function difference(int256[] memory a, int256[] memory b)
    internal
    pure
    returns (int256[] memory c)
```

Returns the sorted set difference between `a` and `b`.   
Note: Behaviour is undefined if inputs are not sorted and uniquified.

### difference(address[],address[])

```solidity
function difference(address[] memory a, address[] memory b)
    internal
    pure
    returns (address[] memory c)
```

Returns the sorted set difference between `a` and `b`.   
Note: Behaviour is undefined if inputs are not sorted and uniquified.

### difference(bytes32[],bytes32[])

```solidity
function difference(bytes32[] memory a, bytes32[] memory b)
    internal
    pure
    returns (bytes32[] memory c)
```

Returns the sorted set difference between `a` and `b`.   
Note: Behaviour is undefined if inputs are not sorted and uniquified.

### intersection(uint256[],uint256[])

```solidity
function intersection(uint256[] memory a, uint256[] memory b)
    internal
    pure
    returns (uint256[] memory c)
```

Returns the sorted set intersection between `a` and `b`.   
Note: Behaviour is undefined if inputs are not sorted and uniquified.

### intersection(int256[],int256[])

```solidity
function intersection(int256[] memory a, int256[] memory b)
    internal
    pure
    returns (int256[] memory c)
```

Returns the sorted set intersection between `a` and `b`.   
Note: Behaviour is undefined if inputs are not sorted and uniquified.

### intersection(address[],address[])

```solidity
function intersection(address[] memory a, address[] memory b)
    internal
    pure
    returns (address[] memory c)
```

Returns the sorted set intersection between `a` and `b`.   
Note: Behaviour is undefined if inputs are not sorted and uniquified.

### intersection(bytes32[],bytes32[])

```solidity
function intersection(bytes32[] memory a, bytes32[] memory b)
    internal
    pure
    returns (bytes32[] memory c)
```

Returns the sorted set intersection between `a` and `b`.   
Note: Behaviour is undefined if inputs are not sorted and uniquified.

### union(uint256[],uint256[])

```solidity
function union(uint256[] memory a, uint256[] memory b)
    internal
    pure
    returns (uint256[] memory c)
```

Returns the sorted set union of `a` and `b`.   
Note: Behaviour is undefined if inputs are not sorted and uniquified.

### union(int256[],int256[])

```solidity
function union(int256[] memory a, int256[] memory b)
    internal
    pure
    returns (int256[] memory c)
```

Returns the sorted set union of `a` and `b`.   
Note: Behaviour is undefined if inputs are not sorted and uniquified.

### union(address[],address[])

```solidity
function union(address[] memory a, address[] memory b)
    internal
    pure
    returns (address[] memory c)
```

Returns the sorted set union between `a` and `b`.   
Note: Behaviour is undefined if inputs are not sorted and uniquified.

### union(bytes32[],bytes32[])

```solidity
function union(bytes32[] memory a, bytes32[] memory b)
    internal
    pure
    returns (bytes32[] memory c)
```

Returns the sorted set union between `a` and `b`.   
Note: Behaviour is undefined if inputs are not sorted and uniquified.

### clean(address[])

```solidity
function clean(address[] memory a) internal pure
```

Cleans the upper 96 bits of the addresses.   
In case `a` is produced via assembly and might have dirty upper bits.

### groupSum(uint256[],uint256[])

```solidity
function groupSum(uint256[] memory keys, uint256[] memory values)
    internal
    pure
```

Sorts and uniquifies `keys`. Updates `values` with the grouped sums by key.

### groupSum(address[],uint256[])

```solidity
function groupSum(address[] memory keys, uint256[] memory values)
    internal
    pure
```

Sorts and uniquifies `keys`. Updates `values` with the grouped sums by key.

### groupSum(bytes32[],uint256[])

```solidity
function groupSum(bytes32[] memory keys, uint256[] memory values)
    internal
    pure
```

Sorts and uniquifies `keys`. Updates `values` with the grouped sums by key.

### groupSum(int256[],uint256[])

```solidity
function groupSum(int256[] memory keys, uint256[] memory values)
    internal
    pure
```

Sorts and uniquifies `keys`. Updates `values` with the grouped sums by key.