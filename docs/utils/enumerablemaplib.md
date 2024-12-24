# EnumerableMapLib

Library for managing enumerable maps in storage.






<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### EnumerableMapKeyNotFound()

```solidity
error EnumerableMapKeyNotFound()
```

The key does not exist in the enumerable map.

## Structs

### Bytes32ToBytes32Map

```solidity
struct Bytes32ToBytes32Map {
    EnumerableSetLib.Bytes32Set _keys;
    mapping(bytes32 => bytes32) _values;
}
```

A enumerable map of `bytes32` to `bytes32`.

### Bytes32ToUint256Map

```solidity
struct Bytes32ToUint256Map {
    EnumerableSetLib.Bytes32Set _keys;
    mapping(bytes32 => uint256) _values;
}
```

A enumerable map of `bytes32` to `uint256`.

### Bytes32ToAddressMap

```solidity
struct Bytes32ToAddressMap {
    EnumerableSetLib.Bytes32Set _keys;
    mapping(bytes32 => address) _values;
}
```

A enumerable map of `bytes32` to `address`.

### Uint256ToBytes32Map

```solidity
struct Uint256ToBytes32Map {
    EnumerableSetLib.Uint256Set _keys;
    mapping(uint256 => bytes32) _values;
}
```

A enumerable map of `uint256` to `bytes32`.

### Uint256ToUint256Map

```solidity
struct Uint256ToUint256Map {
    EnumerableSetLib.Uint256Set _keys;
    mapping(uint256 => uint256) _values;
}
```

A enumerable map of `uint256` to `uint256`.

### Uint256ToAddressMap

```solidity
struct Uint256ToAddressMap {
    EnumerableSetLib.Uint256Set _keys;
    mapping(uint256 => address) _values;
}
```

A enumerable map of `uint256` to `address`.

### AddressToBytes32Map

```solidity
struct AddressToBytes32Map {
    EnumerableSetLib.AddressSet _keys;
    mapping(address => bytes32) _values;
}
```

A enumerable map of `address` to `bytes32`.

### AddressToUint256Map

```solidity
struct AddressToUint256Map {
    EnumerableSetLib.AddressSet _keys;
    mapping(address => uint256) _values;
}
```

A enumerable map of `address` to `uint256`.

### AddressToAddressMap

```solidity
struct AddressToAddressMap {
    EnumerableSetLib.AddressSet _keys;
    mapping(address => address) _values;
}
```

A enumerable map of `address` to `address`.

## Getters / Setters

### set(Bytes32ToBytes32Map,bytes32,bytes32)

```solidity
function set(Bytes32ToBytes32Map storage map, bytes32 key, bytes32 value)
    internal
    returns (bool)
```

Adds a key-value pair to the map, or updates the value for an existing key.   
Returns true if `key` was added to the map, that is if it was not already present.

### remove(Bytes32ToBytes32Map,bytes32)

```solidity
function remove(Bytes32ToBytes32Map storage map, bytes32 key)
    internal
    returns (bool)
```

Removes a key-value pair from the map.   
Returns true if `key` was removed from the map, that is if it was present.

### contains(Bytes32ToBytes32Map,bytes32)

```solidity
function contains(Bytes32ToBytes32Map storage map, bytes32 key)
    internal
    view
    returns (bool)
```

Returns true if the key is in the map.

### length(Bytes32ToBytes32Map)

```solidity
function length(Bytes32ToBytes32Map storage map)
    internal
    view
    returns (uint256)
```

Returns the number of key-value pairs in the map.

### at(Bytes32ToBytes32Map,uint256)

```solidity
function at(Bytes32ToBytes32Map storage map, uint256 i)
    internal
    view
    returns (bytes32 key, bytes32 value)
```

Returns the key-value pair at index `i`. Reverts if `i` is out-of-bounds.

### tryGet(Bytes32ToBytes32Map,bytes32)

```solidity
function tryGet(Bytes32ToBytes32Map storage map, bytes32 key)
    internal
    view
    returns (bool exists, bytes32 value)
```

Tries to return the value associated with the key.

### get(Bytes32ToBytes32Map,bytes32)

```solidity
function get(Bytes32ToBytes32Map storage map, bytes32 key)
    internal
    view
    returns (bytes32 value)
```

Returns the value for the key. Reverts if the key is not found.

### keys(Bytes32ToBytes32Map)

```solidity
function keys(Bytes32ToBytes32Map storage map)
    internal
    view
    returns (bytes32[] memory)
```

Returns the keys. May run out-of-gas if the map is too big.

### set(Bytes32ToUint256Map,bytes32,uint256)

```solidity
function set(Bytes32ToUint256Map storage map, bytes32 key, uint256 value)
    internal
    returns (bool)
```

Adds a key-value pair to the map, or updates the value for an existing key.   
Returns true if `key` was added to the map, that is if it was not already present.

### remove(Bytes32ToUint256Map,bytes32)

```solidity
function remove(Bytes32ToUint256Map storage map, bytes32 key)
    internal
    returns (bool)
```

Removes a key-value pair from the map.   
Returns true if `key` was removed from the map, that is if it was present.

### contains(Bytes32ToUint256Map,bytes32)

```solidity
function contains(Bytes32ToUint256Map storage map, bytes32 key)
    internal
    view
    returns (bool)
```

Returns true if the key is in the map.

### length(Bytes32ToUint256Map)

```solidity
function length(Bytes32ToUint256Map storage map)
    internal
    view
    returns (uint256)
```

Returns the number of key-value pairs in the map.

### at(Bytes32ToUint256Map,uint256)

```solidity
function at(Bytes32ToUint256Map storage map, uint256 i)
    internal
    view
    returns (bytes32 key, uint256 value)
```

Returns the key-value pair at index `i`. Reverts if `i` is out-of-bounds.

### tryGet(Bytes32ToUint256Map,bytes32)

```solidity
function tryGet(Bytes32ToUint256Map storage map, bytes32 key)
    internal
    view
    returns (bool exists, uint256 value)
```

Tries to return the value associated with the key.

### get(Bytes32ToUint256Map,bytes32)

```solidity
function get(Bytes32ToUint256Map storage map, bytes32 key)
    internal
    view
    returns (uint256 value)
```

Returns the value for the key. Reverts if the key is not found.

### keys(Bytes32ToUint256Map)

```solidity
function keys(Bytes32ToUint256Map storage map)
    internal
    view
    returns (bytes32[] memory)
```

Returns the keys. May run out-of-gas if the map is too big.

### set(Bytes32ToAddressMap,bytes32,address)

```solidity
function set(Bytes32ToAddressMap storage map, bytes32 key, address value)
    internal
    returns (bool)
```

Adds a key-value pair to the map, or updates the value for an existing key.   
Returns true if `key` was added to the map, that is if it was not already present.

### remove(Bytes32ToAddressMap,bytes32)

```solidity
function remove(Bytes32ToAddressMap storage map, bytes32 key)
    internal
    returns (bool)
```

Removes a key-value pair from the map.   
Returns true if `key` was removed from the map, that is if it was present.

### contains(Bytes32ToAddressMap,bytes32)

```solidity
function contains(Bytes32ToAddressMap storage map, bytes32 key)
    internal
    view
    returns (bool)
```

Returns true if the key is in the map.

### length(Bytes32ToAddressMap)

```solidity
function length(Bytes32ToAddressMap storage map)
    internal
    view
    returns (uint256)
```

Returns the number of key-value pairs in the map.

### at(Bytes32ToAddressMap,uint256)

```solidity
function at(Bytes32ToAddressMap storage map, uint256 i)
    internal
    view
    returns (bytes32 key, address value)
```

Returns the key-value pair at index `i`. Reverts if `i` is out-of-bounds.

### tryGet(Bytes32ToAddressMap,bytes32)

```solidity
function tryGet(Bytes32ToAddressMap storage map, bytes32 key)
    internal
    view
    returns (bool exists, address value)
```

Tries to return the value associated with the key.

### get(Bytes32ToAddressMap,bytes32)

```solidity
function get(Bytes32ToAddressMap storage map, bytes32 key)
    internal
    view
    returns (address value)
```

Returns the value for the key. Reverts if the key is not found.

### keys(Bytes32ToAddressMap)

```solidity
function keys(Bytes32ToAddressMap storage map)
    internal
    view
    returns (bytes32[] memory)
```

Returns the keys. May run out-of-gas if the map is too big.

### set(Uint256ToBytes32Map,uint256,bytes32)

```solidity
function set(Uint256ToBytes32Map storage map, uint256 key, bytes32 value)
    internal
    returns (bool)
```

Adds a key-value pair to the map, or updates the value for an existing key.   
Returns true if `key` was added to the map, that is if it was not already present.

### remove(Uint256ToBytes32Map,uint256)

```solidity
function remove(Uint256ToBytes32Map storage map, uint256 key)
    internal
    returns (bool)
```

Removes a key-value pair from the map.   
Returns true if `key` was removed from the map, that is if it was present.

### contains(Uint256ToBytes32Map,uint256)

```solidity
function contains(Uint256ToBytes32Map storage map, uint256 key)
    internal
    view
    returns (bool)
```

Returns true if the key is in the map.

### length(Uint256ToBytes32Map)

```solidity
function length(Uint256ToBytes32Map storage map)
    internal
    view
    returns (uint256)
```

Returns the number of key-value pairs in the map.

### at(Uint256ToBytes32Map,uint256)

```solidity
function at(Uint256ToBytes32Map storage map, uint256 i)
    internal
    view
    returns (uint256 key, bytes32 value)
```

Returns the key-value pair at index `i`. Reverts if `i` is out-of-bounds.

### tryGet(Uint256ToBytes32Map,uint256)

```solidity
function tryGet(Uint256ToBytes32Map storage map, uint256 key)
    internal
    view
    returns (bool exists, bytes32 value)
```

Tries to return the value associated with the key.

### get(Uint256ToBytes32Map,uint256)

```solidity
function get(Uint256ToBytes32Map storage map, uint256 key)
    internal
    view
    returns (bytes32 value)
```

Returns the value for the key. Reverts if the key is not found.

### keys(Uint256ToBytes32Map)

```solidity
function keys(Uint256ToBytes32Map storage map)
    internal
    view
    returns (uint256[] memory)
```

Returns the keys. May run out-of-gas if the map is too big.

### set(Uint256ToUint256Map,uint256,uint256)

```solidity
function set(Uint256ToUint256Map storage map, uint256 key, uint256 value)
    internal
    returns (bool)
```

Adds a key-value pair to the map, or updates the value for an existing key.   
Returns true if `key` was added to the map, that is if it was not already present.

### remove(Uint256ToUint256Map,uint256)

```solidity
function remove(Uint256ToUint256Map storage map, uint256 key)
    internal
    returns (bool)
```

Removes a key-value pair from the map.   
Returns true if `key` was removed from the map, that is if it was present.

### contains(Uint256ToUint256Map,uint256)

```solidity
function contains(Uint256ToUint256Map storage map, uint256 key)
    internal
    view
    returns (bool)
```

Returns true if the key is in the map.

### length(Uint256ToUint256Map)

```solidity
function length(Uint256ToUint256Map storage map)
    internal
    view
    returns (uint256)
```

Returns the number of key-value pairs in the map.

### at(Uint256ToUint256Map,uint256)

```solidity
function at(Uint256ToUint256Map storage map, uint256 i)
    internal
    view
    returns (uint256 key, uint256 value)
```

Returns the key-value pair at index `i`. Reverts if `i` is out-of-bounds.

### tryGet(Uint256ToUint256Map,uint256)

```solidity
function tryGet(Uint256ToUint256Map storage map, uint256 key)
    internal
    view
    returns (bool exists, uint256 value)
```

Tries to return the value associated with the key.

### get(Uint256ToUint256Map,uint256)

```solidity
function get(Uint256ToUint256Map storage map, uint256 key)
    internal
    view
    returns (uint256 value)
```

Returns the value for the key. Reverts if the key is not found.

### keys(Uint256ToUint256Map)

```solidity
function keys(Uint256ToUint256Map storage map)
    internal
    view
    returns (uint256[] memory)
```

Returns the keys. May run out-of-gas if the map is too big.

### set(Uint256ToAddressMap,uint256,address)

```solidity
function set(Uint256ToAddressMap storage map, uint256 key, address value)
    internal
    returns (bool)
```

Adds a key-value pair to the map, or updates the value for an existing key.   
Returns true if `key` was added to the map, that is if it was not already present.

### remove(Uint256ToAddressMap,uint256)

```solidity
function remove(Uint256ToAddressMap storage map, uint256 key)
    internal
    returns (bool)
```

Removes a key-value pair from the map.   
Returns true if `key` was removed from the map, that is if it was present.

### contains(Uint256ToAddressMap,uint256)

```solidity
function contains(Uint256ToAddressMap storage map, uint256 key)
    internal
    view
    returns (bool)
```

Returns true if the key is in the map.

### length(Uint256ToAddressMap)

```solidity
function length(Uint256ToAddressMap storage map)
    internal
    view
    returns (uint256)
```

Returns the number of key-value pairs in the map.

### at(Uint256ToAddressMap,uint256)

```solidity
function at(Uint256ToAddressMap storage map, uint256 i)
    internal
    view
    returns (uint256 key, address value)
```

Returns the key-value pair at index `i`. Reverts if `i` is out-of-bounds.

### tryGet(Uint256ToAddressMap,uint256)

```solidity
function tryGet(Uint256ToAddressMap storage map, uint256 key)
    internal
    view
    returns (bool exists, address value)
```

Tries to return the value associated with the key.

### get(Uint256ToAddressMap,uint256)

```solidity
function get(Uint256ToAddressMap storage map, uint256 key)
    internal
    view
    returns (address value)
```

Returns the value for the key. Reverts if the key is not found.

### keys(Uint256ToAddressMap)

```solidity
function keys(Uint256ToAddressMap storage map)
    internal
    view
    returns (uint256[] memory)
```

Returns the keys. May run out-of-gas if the map is too big.

### set(AddressToBytes32Map,address,bytes32)

```solidity
function set(AddressToBytes32Map storage map, address key, bytes32 value)
    internal
    returns (bool)
```

Adds a key-value pair to the map, or updates the value for an existing key.   
Returns true if `key` was added to the map, that is if it was not already present.

### remove(AddressToBytes32Map,address)

```solidity
function remove(AddressToBytes32Map storage map, address key)
    internal
    returns (bool)
```

Removes a key-value pair from the map.   
Returns true if `key` was removed from the map, that is if it was present.

### contains(AddressToBytes32Map,address)

```solidity
function contains(AddressToBytes32Map storage map, address key)
    internal
    view
    returns (bool)
```

Returns true if the key is in the map.

### length(AddressToBytes32Map)

```solidity
function length(AddressToBytes32Map storage map)
    internal
    view
    returns (uint256)
```

Returns the number of key-value pairs in the map.

### at(AddressToBytes32Map,uint256)

```solidity
function at(AddressToBytes32Map storage map, uint256 i)
    internal
    view
    returns (address key, bytes32 value)
```

Returns the key-value pair at index `i`. Reverts if `i` is out-of-bounds.

### tryGet(AddressToBytes32Map,address)

```solidity
function tryGet(AddressToBytes32Map storage map, address key)
    internal
    view
    returns (bool exists, bytes32 value)
```

Tries to return the value associated with the key.

### get(AddressToBytes32Map,address)

```solidity
function get(AddressToBytes32Map storage map, address key)
    internal
    view
    returns (bytes32 value)
```

Returns the value for the key. Reverts if the key is not found.

### keys(AddressToBytes32Map)

```solidity
function keys(AddressToBytes32Map storage map)
    internal
    view
    returns (address[] memory)
```

Returns the keys. May run out-of-gas if the map is too big.

### set(AddressToUint256Map,address,uint256)

```solidity
function set(AddressToUint256Map storage map, address key, uint256 value)
    internal
    returns (bool)
```

Adds a key-value pair to the map, or updates the value for an existing key.   
Returns true if `key` was added to the map, that is if it was not already present.

### remove(AddressToUint256Map,address)

```solidity
function remove(AddressToUint256Map storage map, address key)
    internal
    returns (bool)
```

Removes a key-value pair from the map.   
Returns true if `key` was removed from the map, that is if it was present.

### contains(AddressToUint256Map,address)

```solidity
function contains(AddressToUint256Map storage map, address key)
    internal
    view
    returns (bool)
```

Returns true if the key is in the map.

### length(AddressToUint256Map)

```solidity
function length(AddressToUint256Map storage map)
    internal
    view
    returns (uint256)
```

Returns the number of key-value pairs in the map.

### at(AddressToUint256Map,uint256)

```solidity
function at(AddressToUint256Map storage map, uint256 i)
    internal
    view
    returns (address key, uint256 value)
```

Returns the key-value pair at index `i`. Reverts if `i` is out-of-bounds.

### tryGet(AddressToUint256Map,address)

```solidity
function tryGet(AddressToUint256Map storage map, address key)
    internal
    view
    returns (bool exists, uint256 value)
```

Tries to return the value associated with the key.

### get(AddressToUint256Map,address)

```solidity
function get(AddressToUint256Map storage map, address key)
    internal
    view
    returns (uint256 value)
```

Returns the value for the key. Reverts if the key is not found.

### keys(AddressToUint256Map)

```solidity
function keys(AddressToUint256Map storage map)
    internal
    view
    returns (address[] memory)
```

Returns the keys. May run out-of-gas if the map is too big.

### set(AddressToAddressMap,address,address)

```solidity
function set(AddressToAddressMap storage map, address key, address value)
    internal
    returns (bool)
```

Adds a key-value pair to the map, or updates the value for an existing key.   
Returns true if `key` was added to the map, that is if it was not already present.

### remove(AddressToAddressMap,address)

```solidity
function remove(AddressToAddressMap storage map, address key)
    internal
    returns (bool)
```

Removes a key-value pair from the map.   
Returns true if `key` was removed from the map, that is if it was present.

### contains(AddressToAddressMap,address)

```solidity
function contains(AddressToAddressMap storage map, address key)
    internal
    view
    returns (bool)
```

Returns true if the key is in the map.

### length(AddressToAddressMap)

```solidity
function length(AddressToAddressMap storage map)
    internal
    view
    returns (uint256)
```

Returns the number of key-value pairs in the map.

### at(AddressToAddressMap,uint256)

```solidity
function at(AddressToAddressMap storage map, uint256 i)
    internal
    view
    returns (address key, address value)
```

Returns the key-value pair at index `i`. Reverts if `i` is out-of-bounds.

### tryGet(AddressToAddressMap,address)

```solidity
function tryGet(AddressToAddressMap storage map, address key)
    internal
    view
    returns (bool exists, address value)
```

Tries to return the value associated with the key.

### get(AddressToAddressMap,address)

```solidity
function get(AddressToAddressMap storage map, address key)
    internal
    view
    returns (address value)
```

Returns the value for the key. Reverts if the key is not found.

### keys(AddressToAddressMap)

```solidity
function keys(AddressToAddressMap storage map)
    internal
    view
    returns (address[] memory)
```

Returns the keys. May run out-of-gas if the map is too big.