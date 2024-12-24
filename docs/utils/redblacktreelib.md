# RedBlackTreeLib

Library for managing a red-black-tree in storage.


This implementation does not support the zero (i.e. empty) value.
This implementation supports up to 2147483647 values.



<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### ValueIsEmpty()

```solidity
error ValueIsEmpty()
```

The value cannot be zero.

### ValueAlreadyExists()

```solidity
error ValueAlreadyExists()
```

Cannot insert a value that already exists.

### ValueDoesNotExist()

```solidity
error ValueDoesNotExist()
```

Cannot remove a value that does not exist.

### PointerOutOfBounds()

```solidity
error PointerOutOfBounds()
```

The pointer is out of bounds.

### TreeIsFull()

```solidity
error TreeIsFull()
```

The tree is full.

## Structs

### Tree

```solidity
struct Tree {
    uint256 _spacer;
}
```

A red-black-tree in storage.

## Operations

### size(Tree)

```solidity
function size(Tree storage tree) internal view returns (uint256 result)
```

Returns the number of unique values in the tree.

### values(Tree)

```solidity
function values(Tree storage tree)
    internal
    view
    returns (uint256[] memory result)
```

Returns an array of all the values in the tree in ascending sorted order.   
WARNING! This function can exhaust the block gas limit if the tree is big.   
It is intended for usage in off-chain view functions.

### find(Tree,uint256)

```solidity
function find(Tree storage tree, uint256 x)
    internal
    view
    returns (bytes32 result)
```

Returns a pointer to the value `x`.   
If the value `x` is not in the tree, the returned pointer will be empty.

### nearest(Tree,uint256)

```solidity
function nearest(Tree storage tree, uint256 x)
    internal
    view
    returns (bytes32 result)
```

Returns a pointer to the nearest value to `x`.   
In a tie-breaker, the returned pointer will point to the smaller value.   
If the tree is empty, the returned pointer will be empty.

### nearestBefore(Tree,uint256)

```solidity
function nearestBefore(Tree storage tree, uint256 x)
    internal
    view
    returns (bytes32 result)
```

Returns a pointer to the nearest value lesser or equal to `x`.   
If there is no value lesser or equal to `x`, the returned pointer will be empty.

### nearestAfter(Tree,uint256)

```solidity
function nearestAfter(Tree storage tree, uint256 x)
    internal
    view
    returns (bytes32 result)
```

Returns a pointer to the nearest value greater or equal to `x`.   
If there is no value greater or equal to `x`, the returned pointer will be empty.

### exists(Tree,uint256)

```solidity
function exists(Tree storage tree, uint256 x)
    internal
    view
    returns (bool result)
```

Returns whether the value `x` exists.

### insert(Tree,uint256)

```solidity
function insert(Tree storage tree, uint256 x) internal
```

Inserts the value `x` into the tree.   
Reverts if the value `x` already exists.

### tryInsert(Tree,uint256)

```solidity
function tryInsert(Tree storage tree, uint256 x)
    internal
    returns (uint256 err)
```

Inserts the value `x` into the tree.   
Returns a non-zero error code upon failure instead of reverting   
(except for reverting if `x` is an empty value).

### remove(Tree,uint256)

```solidity
function remove(Tree storage tree, uint256 x) internal
```

Removes the value `x` from the tree.   
Reverts if the value does not exist.

### tryRemove(Tree,uint256)

```solidity
function tryRemove(Tree storage tree, uint256 x)
    internal
    returns (uint256 err)
```

Removes the value `x` from the tree.   
Returns a non-zero error code upon failure instead of reverting   
(except for reverting if `x` is an empty value).

### remove(bytes32)

```solidity
function remove(bytes32 ptr) internal
```

Removes the value at pointer `ptr` from the tree.   
Reverts if `ptr` is empty (i.e. value does not exist),   
or if `ptr` is out of bounds.   
After removal, `ptr` may point to another existing value.   
For safety, do not reuse `ptr` after calling remove on it.

### tryRemove(bytes32)

```solidity
function tryRemove(bytes32 ptr) internal returns (uint256 err)
```

Removes the value at pointer `ptr` from the tree.   
Returns a non-zero error code upon failure instead of reverting.

### value(bytes32)

```solidity
function value(bytes32 ptr) internal view returns (uint256 result)
```

Returns the value at pointer `ptr`.   
If `ptr` is empty, the result will be zero.

### first(Tree)

```solidity
function first(Tree storage tree) internal view returns (bytes32 result)
```

Returns a pointer to the smallest value in the tree.   
If the tree is empty, the returned pointer will be empty.

### last(Tree)

```solidity
function last(Tree storage tree) internal view returns (bytes32 result)
```

Returns a pointer to the largest value in the tree.   
If the tree is empty, the returned pointer will be empty.

### next(bytes32)

```solidity
function next(bytes32 ptr) internal view returns (bytes32 result)
```

Returns the pointer to the next largest value.   
If there is no next value, or if `ptr` is empty,   
the returned pointer will be empty.

### prev(bytes32)

```solidity
function prev(bytes32 ptr) internal view returns (bytes32 result)
```

Returns the pointer to the next smallest value.   
If there is no previous value, or if `ptr` is empty,   
the returned pointer will be empty.

### isEmpty(bytes32)

```solidity
function isEmpty(bytes32 ptr) internal pure returns (bool result)
```

Returns whether the pointer is empty.