# LibMap

Library for storage of packed unsigned integers.






<!-- customintro:start --><!-- customintro:end -->

## Structs

### Uint8Map

```solidity
struct Uint8Map {
    mapping(uint256 => uint256) map;
}
```

A uint8 map in storage.

### Uint16Map

```solidity
struct Uint16Map {
    mapping(uint256 => uint256) map;
}
```

A uint16 map in storage.

### Uint32Map

```solidity
struct Uint32Map {
    mapping(uint256 => uint256) map;
}
```

A uint32 map in storage.

### Uint40Map

```solidity
struct Uint40Map {
    mapping(uint256 => uint256) map;
}
```

A uint40 map in storage. Useful for storing timestamps up to 34841 A.D.

### Uint64Map

```solidity
struct Uint64Map {
    mapping(uint256 => uint256) map;
}
```

A uint64 map in storage.

### Uint128Map

```solidity
struct Uint128Map {
    mapping(uint256 => uint256) map;
}
```

A uint128 map in storage.

## Getters / Setters

### get(Uint8Map,uint256)

```solidity
function get(Uint8Map storage map, uint256 index)
    internal
    view
    returns (uint8 result)
```

Returns the uint8 value at `index` in `map`.

### set(Uint8Map,uint256,uint8)

```solidity
function set(Uint8Map storage map, uint256 index, uint8 value) internal
```

Updates the uint8 value at `index` in `map`.

### get(Uint16Map,uint256)

```solidity
function get(Uint16Map storage map, uint256 index)
    internal
    view
    returns (uint16 result)
```

Returns the uint16 value at `index` in `map`.

### set(Uint16Map,uint256,uint16)

```solidity
function set(Uint16Map storage map, uint256 index, uint16 value) internal
```

Updates the uint16 value at `index` in `map`.

### get(Uint32Map,uint256)

```solidity
function get(Uint32Map storage map, uint256 index)
    internal
    view
    returns (uint32 result)
```

Returns the uint32 value at `index` in `map`.

### set(Uint32Map,uint256,uint32)

```solidity
function set(Uint32Map storage map, uint256 index, uint32 value) internal
```

Updates the uint32 value at `index` in `map`.

### get(Uint40Map,uint256)

```solidity
function get(Uint40Map storage map, uint256 index)
    internal
    view
    returns (uint40 result)
```

Returns the uint40 value at `index` in `map`.

### set(Uint40Map,uint256,uint40)

```solidity
function set(Uint40Map storage map, uint256 index, uint40 value) internal
```

Updates the uint40 value at `index` in `map`.

### get(Uint64Map,uint256)

```solidity
function get(Uint64Map storage map, uint256 index)
    internal
    view
    returns (uint64 result)
```

Returns the uint64 value at `index` in `map`.

### set(Uint64Map,uint256,uint64)

```solidity
function set(Uint64Map storage map, uint256 index, uint64 value) internal
```

Updates the uint64 value at `index` in `map`.

### get(Uint128Map,uint256)

```solidity
function get(Uint128Map storage map, uint256 index)
    internal
    view
    returns (uint128 result)
```

Returns the uint128 value at `index` in `map`.

### set(Uint128Map,uint256,uint128)

```solidity
function set(Uint128Map storage map, uint256 index, uint128 value)
    internal
```

Updates the uint128 value at `index` in `map`.

### get(mapping(uint256)

```solidity
function get(
    mapping(uint256 => uint256) storage map,
    uint256 index,
    uint256 bitWidth
) internal view returns (uint256 result)
```

Returns the value at `index` in `map`.

### set(mapping(uint256)

```solidity
function set(
    mapping(uint256 => uint256) storage map,
    uint256 index,
    uint256 value,
    uint256 bitWidth
) internal
```

Updates the value at `index` in `map`.

## Binary Search

The following functions search in the range of [`start`, `end`)   
(i.e. `start <= index < end`).   
The range must be sorted in ascending order.   
`index` precedence: equal to > nearest before > nearest after.   
An invalid search range will simply return `(found = false, index = start)`.

### searchSorted(Uint8Map,uint8,uint256,uint256)

```solidity
function searchSorted(
    Uint8Map storage map,
    uint8 needle,
    uint256 start,
    uint256 end
) internal view returns (bool found, uint256 index)
```

Returns whether `map` contains `needle`, and the index of `needle`.

### searchSorted(Uint16Map,uint16,uint256,uint256)

```solidity
function searchSorted(
    Uint16Map storage map,
    uint16 needle,
    uint256 start,
    uint256 end
) internal view returns (bool found, uint256 index)
```

Returns whether `map` contains `needle`, and the index of `needle`.

### searchSorted(Uint32Map,uint32,uint256,uint256)

```solidity
function searchSorted(
    Uint32Map storage map,
    uint32 needle,
    uint256 start,
    uint256 end
) internal view returns (bool found, uint256 index)
```

Returns whether `map` contains `needle`, and the index of `needle`.

### searchSorted(Uint40Map,uint40,uint256,uint256)

```solidity
function searchSorted(
    Uint40Map storage map,
    uint40 needle,
    uint256 start,
    uint256 end
) internal view returns (bool found, uint256 index)
```

Returns whether `map` contains `needle`, and the index of `needle`.

### searchSorted(Uint64Map,uint64,uint256,uint256)

```solidity
function searchSorted(
    Uint64Map storage map,
    uint64 needle,
    uint256 start,
    uint256 end
) internal view returns (bool found, uint256 index)
```

Returns whether `map` contains `needle`, and the index of `needle`.

### searchSorted(Uint128Map,uint128,uint256,uint256)

```solidity
function searchSorted(
    Uint128Map storage map,
    uint128 needle,
    uint256 start,
    uint256 end
) internal view returns (bool found, uint256 index)
```

Returns whether `map` contains `needle`, and the index of `needle`.

### searchSorted(mapping(uint256)

```solidity
function searchSorted(
    mapping(uint256 => uint256) storage map,
    uint256 needle,
    uint256 start,
    uint256 end,
    uint256 bitWidth
) internal view returns (bool found, uint256 index)
```

Returns whether `map` contains `needle`, and the index of `needle`.