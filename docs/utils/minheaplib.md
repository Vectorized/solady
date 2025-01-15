# MinHeapLib

Library for managing a min-heap in storage or memory.






<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### HeapIsEmpty()

```solidity
error HeapIsEmpty()
```

The heap is empty.

## Structs

### Heap

```solidity
struct Heap {
    uint256[] data;
}
```

A heap in storage.

### MemHeap

```solidity
struct MemHeap {
    uint256[] data;
}
```

A heap in memory.

## Operations

Tips:   
- To use as a max-heap, bitwise negate the input and output values (e.g. `heap.push(~x)`).   
- To use on tuples, pack the tuple values into a single integer.   
- To use on signed integers, convert the signed integers into   
  their ordered unsigned counterparts via `uint256(x) + (1 << 255)`.

### root(Heap)

```solidity
function root(Heap storage heap) internal view returns (uint256 result)
```

Returns the minimum value of the heap.   
Reverts if the heap is empty.

### root(MemHeap)

```solidity
function root(MemHeap memory heap) internal pure returns (uint256 result)
```

Returns the minimum value of the heap.   
Reverts if the heap is empty.

### reserve(MemHeap,uint256)

```solidity
function reserve(MemHeap memory heap, uint256 minimum) internal pure
```

Reserves at least `minimum` slots of memory for the heap.   
Helps avoid reallocation if you already know the max size of the heap.

### smallest(Heap,uint256)

```solidity
function smallest(Heap storage heap, uint256 k)
    internal
    view
    returns (uint256[] memory a)
```

Returns an array of the `k` smallest items in the heap,   
sorted in ascending order, without modifying the heap.   
If the heap has less than `k` items, all items in the heap will be returned.

### smallest(MemHeap,uint256)

```solidity
function smallest(MemHeap memory heap, uint256 k)
    internal
    pure
    returns (uint256[] memory a)
```

Returns an array of the `k` smallest items in the heap,   
sorted in ascending order, without modifying the heap.   
If the heap has less than `k` items, all items in the heap will be returned.

### length(Heap)

```solidity
function length(Heap storage heap) internal view returns (uint256)
```

Returns the number of items in the heap.

### length(MemHeap)

```solidity
function length(MemHeap memory heap) internal pure returns (uint256)
```

Returns the number of items in the heap.

### push(Heap,uint256)

```solidity
function push(Heap storage heap, uint256 value) internal
```

Pushes the `value` onto the min-heap.

### push(MemHeap,uint256)

```solidity
function push(MemHeap memory heap, uint256 value) internal pure
```

Pushes the `value` onto the min-heap.

### pop(Heap)

```solidity
function pop(Heap storage heap) internal returns (uint256 popped)
```

Pops the minimum value from the min-heap.   
Reverts if the heap is empty.

### pop(MemHeap)

```solidity
function pop(MemHeap memory heap) internal pure returns (uint256 popped)
```

Pops the minimum value from the min-heap.   
Reverts if the heap is empty.

### pushPop(Heap,uint256)

```solidity
function pushPop(Heap storage heap, uint256 value)
    internal
    returns (uint256 popped)
```

Pushes the `value` onto the min-heap, and pops the minimum value.

### pushPop(MemHeap,uint256)

```solidity
function pushPop(MemHeap memory heap, uint256 value)
    internal
    pure
    returns (uint256 popped)
```

Pushes the `value` onto the min-heap, and pops the minimum value.

### replace(Heap,uint256)

```solidity
function replace(Heap storage heap, uint256 value)
    internal
    returns (uint256 popped)
```

Pops the minimum value, and pushes the new `value` onto the min-heap.   
Reverts if the heap is empty.

### replace(MemHeap,uint256)

```solidity
function replace(MemHeap memory heap, uint256 value)
    internal
    pure
    returns (uint256 popped)
```

Pops the minimum value, and pushes the new `value` onto the min-heap.   
Reverts if the heap is empty.

### enqueue(Heap,uint256,uint256)

```solidity
function enqueue(Heap storage heap, uint256 value, uint256 maxLength)
    internal
    returns (bool success, bool hasPopped, uint256 popped)
```

Pushes the `value` onto the min-heap, and pops the minimum value   
if the length of the heap exceeds `maxLength`.   
Reverts if `maxLength` is zero.   
- If the queue is not full:   
  (`success` = true, `hasPopped` = false, `popped` = 0)   
- If the queue is full, and `value` is not greater than the minimum value:   
  (`success` = false, `hasPopped` = false, `popped` = 0)   
- If the queue is full, and `value` is greater than the minimum value:   
  (`success` = true, `hasPopped` = true, `popped` = <minimum value>)   
Useful for implementing a bounded priority queue.   
It is technically possible for the heap size to exceed `maxLength`   
if `enqueue` has been previously called with a larger `maxLength`.   
In such a case, the heap will be treated exactly as if it is full,   
conditionally popping the minimum value if `value` is greater than it.   
Under normal usage, which keeps `maxLength` constant throughout   
the lifetime of a heap, this out-of-spec edge case will not be triggered.

### enqueue(MemHeap,uint256,uint256)

```solidity
function enqueue(MemHeap memory heap, uint256 value, uint256 maxLength)
    internal
    pure
    returns (bool success, bool hasPopped, uint256 popped)
```

Pushes the `value` onto the min-heap, and pops the minimum value   
if the length of the heap exceeds `maxLength`.   
Reverts if `maxLength` is zero.   
- If the queue is not full:   
  (`success` = true, `hasPopped` = false, `popped` = 0)   
- If the queue is full, and `value` is not greater than the minimum value:   
  (`success` = false, `hasPopped` = false, `popped` = 0)   
- If the queue is full, and `value` is greater than the minimum value:   
  (`success` = true, `hasPopped` = true, `popped` = <minimum value>)   
Useful for implementing a bounded priority queue.

### bumpFreeMemoryPointer()

```solidity
function bumpFreeMemoryPointer() internal pure
```

Increments the free memory pointer by a word and fills the word with 0.   
This is if you want to take extra precaution that the memory word slot before   
the `data` array in `MemHeap` doesn't contain a non-zero multiple of prime   
to masquerade as a prime-checksummed capacity.   
If you are not directly assigning some array to `data`,   
you don't have to worry about it.