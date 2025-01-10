# LibTransient

Library for transient storage operations.


<b>Note:</b>

The functions postfixed with `Compat` will only use transient storage on L1.
L2s are super cheap anyway.
For best safety, always clear the storage after use.



<!-- customintro:start --><!-- customintro:end -->

## Structs

### TUint256

```solidity
struct TUint256 {
    uint256 _spacer;
}
```

Pointer struct to a `uint256` in transient storage.

### TInt256

```solidity
struct TInt256 {
    uint256 _spacer;
}
```

Pointer struct to a `int256` in transient storage.

### TBytes32

```solidity
struct TBytes32 {
    uint256 _spacer;
}
```

Pointer struct to a `bytes32` in transient storage.

### TAddress

```solidity
struct TAddress {
    uint256 _spacer;
}
```

Pointer struct to a `address` in transient storage.

### TBool

```solidity
struct TBool {
    uint256 _spacer;
}
```

Pointer struct to a `bool` in transient storage.

### TBytes

```solidity
struct TBytes {
    uint256 _spacer;
}
```

Pointer struct to a `bytes` in transient storage.

## Uint256 Operations

### tUint256(bytes32)

```solidity
function tUint256(bytes32 tSlot)
    internal
    pure
    returns (TUint256 storage ptr)
```

Returns a pointer to a `uint256` in transient storage.

### tUint256(uint256)

```solidity
function tUint256(uint256 tSlot)
    internal
    pure
    returns (TUint256 storage ptr)
```

Returns a pointer to a `uint256` in transient storage.

### get(TUint256)

```solidity
function get(TUint256 storage ptr) internal view returns (uint256 result)
```

Returns the value at transient `ptr`.

### getCompat(TUint256)

```solidity
function getCompat(TUint256 storage ptr)
    internal
    view
    returns (uint256 result)
```

Returns the value at transient `ptr`.

### set(TUint256,uint256)

```solidity
function set(TUint256 storage ptr, uint256 value) internal
```

Sets the value at transient `ptr`.

### setCompat(TUint256,uint256)

```solidity
function setCompat(TUint256 storage ptr, uint256 value) internal
```

Sets the value at transient `ptr`.

### clear(TUint256)

```solidity
function clear(TUint256 storage ptr) internal
```

Clears the value at transient `ptr`.

### clearCompat(TUint256)

```solidity
function clearCompat(TUint256 storage ptr) internal
```

Clears the value at transient `ptr`.

### inc(TUint256)

```solidity
function inc(TUint256 storage ptr) internal returns (uint256 newValue)
```

Increments the value at transient `ptr` by 1.

### incCompat(TUint256)

```solidity
function incCompat(TUint256 storage ptr)
    internal
    returns (uint256 newValue)
```

Increments the value at transient `ptr` by 1.

### inc(TUint256,uint256)

```solidity
function inc(TUint256 storage ptr, uint256 delta)
    internal
    returns (uint256 newValue)
```

Increments the value at transient `ptr` by `delta`.

### incCompat(TUint256,uint256)

```solidity
function incCompat(TUint256 storage ptr, uint256 delta)
    internal
    returns (uint256 newValue)
```

Increments the value at transient `ptr` by `delta`.

### dec(TUint256)

```solidity
function dec(TUint256 storage ptr) internal returns (uint256 newValue)
```

Decrements the value at transient `ptr` by 1.

### decCompat(TUint256)

```solidity
function decCompat(TUint256 storage ptr)
    internal
    returns (uint256 newValue)
```

Decrements the value at transient `ptr` by `delta`.

### dec(TUint256,uint256)

```solidity
function dec(TUint256 storage ptr, uint256 delta)
    internal
    returns (uint256 newValue)
```

Decrements the value at transient `ptr` by `delta`.

### decCompat(TUint256,uint256)

```solidity
function decCompat(TUint256 storage ptr, uint256 delta)
    internal
    returns (uint256 newValue)
```

Decrements the value at transient `ptr` by `delta`.

### incSigned(TUint256,int256)

```solidity
function incSigned(TUint256 storage ptr, int256 delta)
    internal
    returns (uint256 newValue)
```

Increments the value at transient `ptr` by `delta`.

### incSignedCompat(TUint256,int256)

```solidity
function incSignedCompat(TUint256 storage ptr, int256 delta)
    internal
    returns (uint256 newValue)
```

Increments the value at transient `ptr` by `delta`.

### decSigned(TUint256,int256)

```solidity
function decSigned(TUint256 storage ptr, int256 delta)
    internal
    returns (uint256 newValue)
```

Decrements the value at transient `ptr` by `delta`.

### decSignedCompat(TUint256,int256)

```solidity
function decSignedCompat(TUint256 storage ptr, int256 delta)
    internal
    returns (uint256 newValue)
```

Decrements the value at transient `ptr` by `delta`.

## Int256 Operations

### tInt256(bytes32)

```solidity
function tInt256(bytes32 tSlot)
    internal
    pure
    returns (TInt256 storage ptr)
```

Returns a pointer to a `int256` in transient storage.

### tInt256(uint256)

```solidity
function tInt256(uint256 tSlot)
    internal
    pure
    returns (TInt256 storage ptr)
```

Returns a pointer to a `int256` in transient storage.

### get(TInt256)

```solidity
function get(TInt256 storage ptr) internal view returns (int256 result)
```

Returns the value at transient `ptr`.

### getCompat(TInt256)

```solidity
function getCompat(TInt256 storage ptr)
    internal
    view
    returns (int256 result)
```

Returns the value at transient `ptr`.

### set(TInt256,int256)

```solidity
function set(TInt256 storage ptr, int256 value) internal
```

Sets the value at transient `ptr`.

### setCompat(TInt256,int256)

```solidity
function setCompat(TInt256 storage ptr, int256 value) internal
```

Sets the value at transient `ptr`.

### clear(TInt256)

```solidity
function clear(TInt256 storage ptr) internal
```

Clears the value at transient `ptr`.

### clearCompat(TInt256)

```solidity
function clearCompat(TInt256 storage ptr) internal
```

Clears the value at transient `ptr`.

### inc(TInt256)

```solidity
function inc(TInt256 storage ptr) internal returns (int256 newValue)
```

Increments the value at transient `ptr` by 1.

### incCompat(TInt256)

```solidity
function incCompat(TInt256 storage ptr)
    internal
    returns (int256 newValue)
```

Increments the value at transient `ptr` by 1.

### inc(TInt256,int256)

```solidity
function inc(TInt256 storage ptr, int256 delta)
    internal
    returns (int256 newValue)
```

Increments the value at transient `ptr` by `delta`.

### incCompat(TInt256,int256)

```solidity
function incCompat(TInt256 storage ptr, int256 delta)
    internal
    returns (int256 newValue)
```

Increments the value at transient `ptr` by `delta`.

### dec(TInt256)

```solidity
function dec(TInt256 storage ptr) internal returns (int256 newValue)
```

Decrements the value at transient `ptr` by 1.

### decCompat(TInt256)

```solidity
function decCompat(TInt256 storage ptr)
    internal
    returns (int256 newValue)
```

Decrements the value at transient `ptr` by 1.

### dec(TInt256,int256)

```solidity
function dec(TInt256 storage ptr, int256 delta)
    internal
    returns (int256 newValue)
```

Decrements the value at transient `ptr` by `delta`.

### decCompat(TInt256,int256)

```solidity
function decCompat(TInt256 storage ptr, int256 delta)
    internal
    returns (int256 newValue)
```

Decrements the value at transient `ptr` by `delta`.

## Bytes32 Operations

### tBytes32(bytes32)

```solidity
function tBytes32(bytes32 tSlot)
    internal
    pure
    returns (TBytes32 storage ptr)
```

Returns a pointer to a `bytes32` in transient storage.

### tBytes32(uint256)

```solidity
function tBytes32(uint256 tSlot)
    internal
    pure
    returns (TBytes32 storage ptr)
```

Returns a pointer to a `bytes32` in transient storage.

### get(TBytes32)

```solidity
function get(TBytes32 storage ptr) internal view returns (bytes32 result)
```

Returns the value at transient `ptr`.

### getCompat(TBytes32)

```solidity
function getCompat(TBytes32 storage ptr)
    internal
    view
    returns (bytes32 result)
```

Returns the value at transient `ptr`.

### set(TBytes32,bytes32)

```solidity
function set(TBytes32 storage ptr, bytes32 value) internal
```

Sets the value at transient `ptr`.

### setCompat(TBytes32,bytes32)

```solidity
function setCompat(TBytes32 storage ptr, bytes32 value) internal
```

Sets the value at transient `ptr`.

### clear(TBytes32)

```solidity
function clear(TBytes32 storage ptr) internal
```

Clears the value at transient `ptr`.

### clearCompat(TBytes32)

```solidity
function clearCompat(TBytes32 storage ptr) internal
```

Clears the value at transient `ptr`.

## Address Operations

### tAddress(bytes32)

```solidity
function tAddress(bytes32 tSlot)
    internal
    pure
    returns (TAddress storage ptr)
```

Returns a pointer to a `address` in transient storage.

### tAddress(uint256)

```solidity
function tAddress(uint256 tSlot)
    internal
    pure
    returns (TAddress storage ptr)
```

Returns a pointer to a `address` in transient storage.

### get(TAddress)

```solidity
function get(TAddress storage ptr) internal view returns (address result)
```

Returns the value at transient `ptr`.

### getCompat(TAddress)

```solidity
function getCompat(TAddress storage ptr)
    internal
    view
    returns (address result)
```

Returns the value at transient `ptr`.

### set(TAddress,address)

```solidity
function set(TAddress storage ptr, address value) internal
```

Sets the value at transient `ptr`.

### setCompat(TAddress,address)

```solidity
function setCompat(TAddress storage ptr, address value) internal
```

Sets the value at transient `ptr`.

### clear(TAddress)

```solidity
function clear(TAddress storage ptr) internal
```

Clears the value at transient `ptr`.

### clearCompat(TAddress)

```solidity
function clearCompat(TAddress storage ptr) internal
```

Clears the value at transient `ptr`.

## Bool Operations

### tBool(bytes32)

```solidity
function tBool(bytes32 tSlot) internal pure returns (TBool storage ptr)
```

Returns a pointer to a `bool` in transient storage.

### tBool(uint256)

```solidity
function tBool(uint256 tSlot) internal pure returns (TBool storage ptr)
```

Returns a pointer to a `bool` in transient storage.

### get(TBool)

```solidity
function get(TBool storage ptr) internal view returns (bool result)
```

Returns the value at transient `ptr`.

### getCompat(TBool)

```solidity
function getCompat(TBool storage ptr) internal view returns (bool result)
```

Returns the value at transient `ptr`.

### set(TBool,bool)

```solidity
function set(TBool storage ptr, bool value) internal
```

Sets the value at transient `ptr`.

### setCompat(TBool,bool)

```solidity
function setCompat(TBool storage ptr, bool value) internal
```

Sets the value at transient `ptr`.

### clear(TBool)

```solidity
function clear(TBool storage ptr) internal
```

Clears the value at transient `ptr`.

### clearCompat(TBool)

```solidity
function clearCompat(TBool storage ptr) internal
```

Clears the value at transient `ptr`.

## Bytes Operations

### tBytes(bytes32)

```solidity
function tBytes(bytes32 tSlot) internal pure returns (TBytes storage ptr)
```

Returns a pointer to a `bytes` in transient storage.

### tBytes(uint256)

```solidity
function tBytes(uint256 tSlot) internal pure returns (TBytes storage ptr)
```

Returns a pointer to a `bytes` in transient storage.

### length(TBytes)

```solidity
function length(TBytes storage ptr)
    internal
    view
    returns (uint256 result)
```

Returns the length of the bytes stored at transient `ptr`.

### lengthCompat(TBytes)

```solidity
function lengthCompat(TBytes storage ptr)
    internal
    view
    returns (uint256 result)
```

Returns the length of the bytes stored at transient `ptr`.

### get(TBytes)

```solidity
function get(TBytes storage ptr)
    internal
    view
    returns (bytes memory result)
```

Returns the bytes stored at transient `ptr`.

### getCompat(TBytes)

```solidity
function getCompat(TBytes storage ptr)
    internal
    view
    returns (bytes memory result)
```

Returns the bytes stored at transient `ptr`.

### set(TBytes,bytes)

```solidity
function set(TBytes storage ptr, bytes memory value) internal
```

Sets the value at transient `ptr`.

### setCompat(TBytes,bytes)

```solidity
function setCompat(TBytes storage ptr, bytes memory value) internal
```

Sets the value at transient `ptr`.

### setCalldata(TBytes,bytes)

```solidity
function setCalldata(TBytes storage ptr, bytes calldata value) internal
```

Sets the value at transient `ptr`.

### setCalldataCompat(TBytes,bytes)

```solidity
function setCalldataCompat(TBytes storage ptr, bytes calldata value)
    internal
```

Sets the value at transient `ptr`.

### clear(TBytes)

```solidity
function clear(TBytes storage ptr) internal
```

Clears the value at transient `ptr`.

### clearCompat(TBytes)

```solidity
function clearCompat(TBytes storage ptr) internal
```

Clears the value at transient `ptr`.