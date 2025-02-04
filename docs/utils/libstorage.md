# LibStorage

Library for basic storage operations.






<!-- customintro:start --><!-- customintro:end -->

## Structs

### Bump

```solidity
struct Bump {
    uint256 _current;
}
```

Generates a storage slot that can be invalidated.

### Ref

```solidity
struct Ref {
    uint256 value;
}
```

Pointer struct to a `uint256` in storage.   
We have opted for a `uint256` as the inner type,   
as it requires less casting to get / set specific bits.

## Operations

### slot(Bump)

```solidity
function slot(Bump storage b) internal view returns (bytes32 result)
```

Returns the current storage slot pointed by the bump.   
Use inline-assembly to cast the result to a desired custom data type storage pointer.

### invalidate(Bump)

```solidity
function invalidate(Bump storage b) internal
```

Makes the bump point to a whole new storage slot.

### bump(bytes32)

```solidity
function bump(bytes32 sSlot) internal pure returns (Bump storage $)
```

Returns a bump at the storage slot.

### bump(uint256)

```solidity
function bump(uint256 sSlot) internal pure returns (Bump storage $)
```

Returns a bump at the storage slot.

### ref(bytes32)

```solidity
function ref(bytes32 sSlot) internal pure returns (Ref storage $)
```

Returns a pointer to a `uint256` in storage.

### ref(uint256)

```solidity
function ref(uint256 sSlot) internal pure returns (Ref storage $)
```

Returns a pointer to a `uint256` in storage.