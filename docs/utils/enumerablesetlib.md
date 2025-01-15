# EnumerableSetLib

Library for managing enumerable sets in storage.


<b>Note:</b>

In many applications, the number of elements in an enumerable set is small.
This enumerable set implementation avoids storing the length and indices
for up to 3 elements. Once the length exceeds 3 for the first time, the length
and indices will be initialized. The amortized cost of adding elements is O(1).

The AddressSet implementation packs the length with the 0th entry.

All enumerable sets except Uint8Set use a pop and swap mechanism to remove elements.
This means that the iteration order of elements can change between element removals.



<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### IndexOutOfBounds()

```solidity
error IndexOutOfBounds()
```

The index must be less than the length.

### ValueIsZeroSentinel()

```solidity
error ValueIsZeroSentinel()
```

The value cannot be the zero sentinel.

## Structs

### AddressSet

```solidity
struct AddressSet {
    uint256 _spacer;
}
```

An enumerable address set in storage.

### Bytes32Set

```solidity
struct Bytes32Set {
    uint256 _spacer;
}
```

An enumerable bytes32 set in storage.

### Uint256Set

```solidity
struct Uint256Set {
    uint256 _spacer;
}
```

An enumerable uint256 set in storage.

### Int256Set

```solidity
struct Int256Set {
    uint256 _spacer;
}
```

An enumerable int256 set in storage.

### Uint8Set

```solidity
struct Uint8Set {
    uint256 data;
}
```

An enumerable uint8 set in storage. Useful for enums.

## Getters / Setters

### length(AddressSet)

```solidity
function length(AddressSet storage set)
    internal
    view
    returns (uint256 result)
```

Returns the number of elements in the set.

### length(Bytes32Set)

```solidity
function length(Bytes32Set storage set)
    internal
    view
    returns (uint256 result)
```

Returns the number of elements in the set.

### length(Uint256Set)

```solidity
function length(Uint256Set storage set)
    internal
    view
    returns (uint256 result)
```

Returns the number of elements in the set.

### length(Int256Set)

```solidity
function length(Int256Set storage set)
    internal
    view
    returns (uint256 result)
```

Returns the number of elements in the set.

### length(Uint8Set)

```solidity
function length(Uint8Set storage set)
    internal
    view
    returns (uint256 result)
```

Returns the number of elements in the set.

### contains(AddressSet,address)

```solidity
function contains(AddressSet storage set, address value)
    internal
    view
    returns (bool result)
```

Returns whether `value` is in the set.

### contains(Bytes32Set,bytes32)

```solidity
function contains(Bytes32Set storage set, bytes32 value)
    internal
    view
    returns (bool result)
```

Returns whether `value` is in the set.

### contains(Uint256Set,uint256)

```solidity
function contains(Uint256Set storage set, uint256 value)
    internal
    view
    returns (bool result)
```

Returns whether `value` is in the set.

### contains(Int256Set,int256)

```solidity
function contains(Int256Set storage set, int256 value)
    internal
    view
    returns (bool result)
```

Returns whether `value` is in the set.

### contains(Uint8Set,uint8)

```solidity
function contains(Uint8Set storage set, uint8 value)
    internal
    view
    returns (bool result)
```

Returns whether `value` is in the set.

### add(AddressSet,address)

```solidity
function add(AddressSet storage set, address value)
    internal
    returns (bool result)
```

Adds `value` to the set. Returns whether `value` was not in the set.

### add(Bytes32Set,bytes32)

```solidity
function add(Bytes32Set storage set, bytes32 value)
    internal
    returns (bool result)
```

Adds `value` to the set. Returns whether `value` was not in the set.

### add(Uint256Set,uint256)

```solidity
function add(Uint256Set storage set, uint256 value)
    internal
    returns (bool result)
```

Adds `value` to the set. Returns whether `value` was not in the set.

### add(Int256Set,int256)

```solidity
function add(Int256Set storage set, int256 value)
    internal
    returns (bool result)
```

Adds `value` to the set. Returns whether `value` was not in the set.

### add(Uint8Set,uint8)

```solidity
function add(Uint8Set storage set, uint8 value)
    internal
    returns (bool result)
```

Adds `value` to the set. Returns whether `value` was not in the set.

### remove(AddressSet,address)

```solidity
function remove(AddressSet storage set, address value)
    internal
    returns (bool result)
```

Removes `value` from the set. Returns whether `value` was in the set.

### remove(Bytes32Set,bytes32)

```solidity
function remove(Bytes32Set storage set, bytes32 value)
    internal
    returns (bool result)
```

Removes `value` from the set. Returns whether `value` was in the set.

### remove(Uint256Set,uint256)

```solidity
function remove(Uint256Set storage set, uint256 value)
    internal
    returns (bool result)
```

Removes `value` from the set. Returns whether `value` was in the set.

### remove(Int256Set,int256)

```solidity
function remove(Int256Set storage set, int256 value)
    internal
    returns (bool result)
```

Removes `value` from the set. Returns whether `value` was in the set.

### remove(Uint8Set,uint8)

```solidity
function remove(Uint8Set storage set, uint8 value)
    internal
    returns (bool result)
```

Removes `value` from the set. Returns whether `value` was in the set.

### values(AddressSet)

```solidity
function values(AddressSet storage set)
    internal
    view
    returns (address[] memory result)
```

Returns all of the values in the set.   
Note: This can consume more gas than the block gas limit for large sets.

### values(Bytes32Set)

```solidity
function values(Bytes32Set storage set)
    internal
    view
    returns (bytes32[] memory result)
```

Returns all of the values in the set.   
Note: This can consume more gas than the block gas limit for large sets.

### values(Uint256Set)

```solidity
function values(Uint256Set storage set)
    internal
    view
    returns (uint256[] memory result)
```

Returns all of the values in the set.   
Note: This can consume more gas than the block gas limit for large sets.

### values(Int256Set)

```solidity
function values(Int256Set storage set)
    internal
    view
    returns (int256[] memory result)
```

Returns all of the values in the set.   
Note: This can consume more gas than the block gas limit for large sets.

### values(Uint8Set)

```solidity
function values(Uint8Set storage set)
    internal
    view
    returns (uint8[] memory result)
```

Returns all of the values in the set.

### at(AddressSet,uint256)

```solidity
function at(AddressSet storage set, uint256 i)
    internal
    view
    returns (address result)
```

Returns the element at index `i` in the set. Reverts if `i` is out-of-bounds.

### at(Bytes32Set,uint256)

```solidity
function at(Bytes32Set storage set, uint256 i)
    internal
    view
    returns (bytes32 result)
```

Returns the element at index `i` in the set. Reverts if `i` is out-of-bounds.

### at(Uint256Set,uint256)

```solidity
function at(Uint256Set storage set, uint256 i)
    internal
    view
    returns (uint256 result)
```

Returns the element at index `i` in the set. Reverts if `i` is out-of-bounds.

### at(Int256Set,uint256)

```solidity
function at(Int256Set storage set, uint256 i)
    internal
    view
    returns (int256 result)
```

Returns the element at index `i` in the set. Reverts if `i` is out-of-bounds.

### at(Uint8Set,uint256)

```solidity
function at(Uint8Set storage set, uint256 i)
    internal
    view
    returns (uint8 result)
```

Returns the element at index `i` in the set. Reverts if `i` is out-of-bounds.