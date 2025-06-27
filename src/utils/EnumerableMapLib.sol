// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {EnumerableSetLib} from "./EnumerableSetLib.sol";

/// @notice Library for managing enumerable maps in storage.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/EnumerableMapLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/EnumerableMap.sol)
library EnumerableMapLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The key does not exist in the enumerable map.
    error EnumerableMapKeyNotFound();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev An enumerable map of `bytes32` to `bytes32`.
    struct Bytes32ToBytes32Map {
        EnumerableSetLib.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /// @dev An enumerable map of `bytes32` to `uint256`.
    struct Bytes32ToUint256Map {
        EnumerableSetLib.Bytes32Set _keys;
        mapping(bytes32 => uint256) _values;
    }

    /// @dev An enumerable map of `bytes32` to `address`.
    struct Bytes32ToAddressMap {
        EnumerableSetLib.Bytes32Set _keys;
        mapping(bytes32 => address) _values;
    }

    /// @dev An enumerable map of `uint256` to `bytes32`.
    struct Uint256ToBytes32Map {
        EnumerableSetLib.Uint256Set _keys;
        mapping(uint256 => bytes32) _values;
    }

    /// @dev An enumerable map of `uint256` to `uint256`.
    struct Uint256ToUint256Map {
        EnumerableSetLib.Uint256Set _keys;
        mapping(uint256 => uint256) _values;
    }

    /// @dev An enumerable map of `uint256` to `address`.
    struct Uint256ToAddressMap {
        EnumerableSetLib.Uint256Set _keys;
        mapping(uint256 => address) _values;
    }

    /// @dev An enumerable map of `address` to `bytes32`.
    struct AddressToBytes32Map {
        EnumerableSetLib.AddressSet _keys;
        mapping(address => bytes32) _values;
    }

    /// @dev An enumerable map of `address` to `uint256`.
    struct AddressToUint256Map {
        EnumerableSetLib.AddressSet _keys;
        mapping(address => uint256) _values;
    }

    /// @dev An enumerable map of `address` to `address`.
    struct AddressToAddressMap {
        EnumerableSetLib.AddressSet _keys;
        mapping(address => address) _values;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     GETTERS / SETTERS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Adds a key-value pair to the map, or updates the value for an existing key.
    /// Returns true if `key` was added to the map, that is if it was not already present.
    function set(Bytes32ToBytes32Map storage map, bytes32 key, bytes32 value)
        internal
        returns (bool)
    {
        map._values[key] = value;
        return EnumerableSetLib.add(map._keys, key);
    }

    /// @dev Adds a key-value pair to the map, or updates the value for an existing key.
    /// Returns true if `key` was added to the map, that is if it was not already present.
    /// Reverts if the map grows bigger than the custom on-the-fly capacity `cap`.
    function set(Bytes32ToBytes32Map storage map, bytes32 key, bytes32 value, uint256 cap)
        internal
        returns (bool)
    {
        map._values[key] = value;
        return EnumerableSetLib.add(map._keys, key, cap);
    }

    /// @dev Removes a key-value pair from the map.
    /// Returns true if `key` was removed from the map, that is if it was present.
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return EnumerableSetLib.remove(map._keys, key);
    }

    /// @dev Shorthand for `isAdd ? map.set(key, value, cap) : map.remove(key)`.
    function update(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value,
        bool isAdd,
        uint256 cap
    ) internal returns (bool) {
        return isAdd ? set(map, key, value, cap) : remove(map, key);
    }

    /// @dev Returns true if the key is in the map.
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return EnumerableSetLib.contains(map._keys, key);
    }

    /// @dev Returns the number of key-value pairs in the map.
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return EnumerableSetLib.length(map._keys);
    }

    /// @dev Returns the key-value pair at index `i`. Reverts if `i` is out-of-bounds.
    function at(Bytes32ToBytes32Map storage map, uint256 i)
        internal
        view
        returns (bytes32 key, bytes32 value)
    {
        value = map._values[key = EnumerableSetLib.at(map._keys, i)];
    }

    /// @dev Tries to return the value associated with the key.
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key)
        internal
        view
        returns (bool exists, bytes32 value)
    {
        exists = (value = map._values[key]) != bytes32(0) || contains(map, key);
    }

    /// @dev Returns the value for the key. Reverts if the key is not found.
    function get(Bytes32ToBytes32Map storage map, bytes32 key)
        internal
        view
        returns (bytes32 value)
    {
        if ((value = map._values[key]) == bytes32(0)) if (!contains(map, key)) _revertNotFound();
    }

    /// @dev Returns the keys. May run out-of-gas if the map is too big.
    function keys(Bytes32ToBytes32Map storage map) internal view returns (bytes32[] memory) {
        return EnumerableSetLib.values(map._keys);
    }

    /// @dev Adds a key-value pair to the map, or updates the value for an existing key.
    /// Returns true if `key` was added to the map, that is if it was not already present.
    function set(Bytes32ToUint256Map storage map, bytes32 key, uint256 value)
        internal
        returns (bool)
    {
        map._values[key] = value;
        return EnumerableSetLib.add(map._keys, key);
    }

    /// @dev Adds a key-value pair to the map, or updates the value for an existing key.
    /// Returns true if `key` was added to the map, that is if it was not already present.
    /// Reverts if the map grows bigger than the custom on-the-fly capacity `cap`.
    function set(Bytes32ToUint256Map storage map, bytes32 key, uint256 value, uint256 cap)
        internal
        returns (bool)
    {
        map._values[key] = value;
        return EnumerableSetLib.add(map._keys, key, cap);
    }

    /// @dev Removes a key-value pair from the map.
    /// Returns true if `key` was removed from the map, that is if it was present.
    function remove(Bytes32ToUint256Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return EnumerableSetLib.remove(map._keys, key);
    }

    /// @dev Shorthand for `isAdd ? map.set(key, value, cap) : map.remove(key)`.
    function update(
        Bytes32ToUint256Map storage map,
        bytes32 key,
        uint256 value,
        bool isAdd,
        uint256 cap
    ) internal returns (bool) {
        return isAdd ? set(map, key, value, cap) : remove(map, key);
    }

    /// @dev Returns true if the key is in the map.
    function contains(Bytes32ToUint256Map storage map, bytes32 key) internal view returns (bool) {
        return EnumerableSetLib.contains(map._keys, key);
    }

    /// @dev Returns the number of key-value pairs in the map.
    function length(Bytes32ToUint256Map storage map) internal view returns (uint256) {
        return EnumerableSetLib.length(map._keys);
    }

    /// @dev Returns the key-value pair at index `i`. Reverts if `i` is out-of-bounds.
    function at(Bytes32ToUint256Map storage map, uint256 i)
        internal
        view
        returns (bytes32 key, uint256 value)
    {
        value = map._values[key = EnumerableSetLib.at(map._keys, i)];
    }

    /// @dev Tries to return the value associated with the key.
    function tryGet(Bytes32ToUint256Map storage map, bytes32 key)
        internal
        view
        returns (bool exists, uint256 value)
    {
        exists = (value = map._values[key]) != uint256(0) || contains(map, key);
    }

    /// @dev Returns the value for the key. Reverts if the key is not found.
    function get(Bytes32ToUint256Map storage map, bytes32 key)
        internal
        view
        returns (uint256 value)
    {
        if ((value = map._values[key]) == uint256(0)) if (!contains(map, key)) _revertNotFound();
    }

    /// @dev Returns the keys. May run out-of-gas if the map is too big.
    function keys(Bytes32ToUint256Map storage map) internal view returns (bytes32[] memory) {
        return EnumerableSetLib.values(map._keys);
    }

    /// @dev Adds a key-value pair to the map, or updates the value for an existing key.
    /// Returns true if `key` was added to the map, that is if it was not already present.
    function set(Bytes32ToAddressMap storage map, bytes32 key, address value)
        internal
        returns (bool)
    {
        map._values[key] = value;
        return EnumerableSetLib.add(map._keys, key);
    }

    /// @dev Adds a key-value pair to the map, or updates the value for an existing key.
    /// Returns true if `key` was added to the map, that is if it was not already present.
    /// Reverts if the map grows bigger than the custom on-the-fly capacity `cap`.
    function set(Bytes32ToAddressMap storage map, bytes32 key, address value, uint256 cap)
        internal
        returns (bool)
    {
        map._values[key] = value;
        return EnumerableSetLib.add(map._keys, key, cap);
    }

    /// @dev Removes a key-value pair from the map.
    /// Returns true if `key` was removed from the map, that is if it was present.
    function remove(Bytes32ToAddressMap storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return EnumerableSetLib.remove(map._keys, key);
    }

    /// @dev Shorthand for `isAdd ? map.set(key, value, cap) : map.remove(key)`.
    function update(
        Bytes32ToAddressMap storage map,
        bytes32 key,
        address value,
        bool isAdd,
        uint256 cap
    ) internal returns (bool) {
        return isAdd ? set(map, key, value, cap) : remove(map, key);
    }

    /// @dev Returns true if the key is in the map.
    function contains(Bytes32ToAddressMap storage map, bytes32 key) internal view returns (bool) {
        return EnumerableSetLib.contains(map._keys, key);
    }

    /// @dev Returns the number of key-value pairs in the map.
    function length(Bytes32ToAddressMap storage map) internal view returns (uint256) {
        return EnumerableSetLib.length(map._keys);
    }

    /// @dev Returns the key-value pair at index `i`. Reverts if `i` is out-of-bounds.
    function at(Bytes32ToAddressMap storage map, uint256 i)
        internal
        view
        returns (bytes32 key, address value)
    {
        value = map._values[key = EnumerableSetLib.at(map._keys, i)];
    }

    /// @dev Tries to return the value associated with the key.
    function tryGet(Bytes32ToAddressMap storage map, bytes32 key)
        internal
        view
        returns (bool exists, address value)
    {
        exists = (value = map._values[key]) != address(0) || contains(map, key);
    }

    /// @dev Returns the value for the key. Reverts if the key is not found.
    function get(Bytes32ToAddressMap storage map, bytes32 key)
        internal
        view
        returns (address value)
    {
        if ((value = map._values[key]) == address(0)) if (!contains(map, key)) _revertNotFound();
    }

    /// @dev Returns the keys. May run out-of-gas if the map is too big.
    function keys(Bytes32ToAddressMap storage map) internal view returns (bytes32[] memory) {
        return EnumerableSetLib.values(map._keys);
    }

    /// @dev Adds a key-value pair to the map, or updates the value for an existing key.
    /// Returns true if `key` was added to the map, that is if it was not already present.
    function set(Uint256ToBytes32Map storage map, uint256 key, bytes32 value)
        internal
        returns (bool)
    {
        map._values[key] = value;
        return EnumerableSetLib.add(map._keys, key);
    }

    /// @dev Adds a key-value pair to the map, or updates the value for an existing key.
    /// Returns true if `key` was added to the map, that is if it was not already present.
    /// Reverts if the map grows bigger than the custom on-the-fly capacity `cap`.
    function set(Uint256ToBytes32Map storage map, uint256 key, bytes32 value, uint256 cap)
        internal
        returns (bool)
    {
        map._values[key] = value;
        return EnumerableSetLib.add(map._keys, key, cap);
    }

    /// @dev Removes a key-value pair from the map.
    /// Returns true if `key` was removed from the map, that is if it was present.
    function remove(Uint256ToBytes32Map storage map, uint256 key) internal returns (bool) {
        delete map._values[key];
        return EnumerableSetLib.remove(map._keys, key);
    }

    /// @dev Shorthand for `isAdd ? map.set(key, value, cap) : map.remove(key)`.
    function update(
        Uint256ToBytes32Map storage map,
        uint256 key,
        bytes32 value,
        bool isAdd,
        uint256 cap
    ) internal returns (bool) {
        return isAdd ? set(map, key, value, cap) : remove(map, key);
    }

    /// @dev Returns true if the key is in the map.
    function contains(Uint256ToBytes32Map storage map, uint256 key) internal view returns (bool) {
        return EnumerableSetLib.contains(map._keys, key);
    }

    /// @dev Returns the number of key-value pairs in the map.
    function length(Uint256ToBytes32Map storage map) internal view returns (uint256) {
        return EnumerableSetLib.length(map._keys);
    }

    /// @dev Returns the key-value pair at index `i`. Reverts if `i` is out-of-bounds.
    function at(Uint256ToBytes32Map storage map, uint256 i)
        internal
        view
        returns (uint256 key, bytes32 value)
    {
        value = map._values[key = EnumerableSetLib.at(map._keys, i)];
    }

    /// @dev Tries to return the value associated with the key.
    function tryGet(Uint256ToBytes32Map storage map, uint256 key)
        internal
        view
        returns (bool exists, bytes32 value)
    {
        exists = (value = map._values[key]) != bytes32(0) || contains(map, key);
    }

    /// @dev Returns the value for the key. Reverts if the key is not found.
    function get(Uint256ToBytes32Map storage map, uint256 key)
        internal
        view
        returns (bytes32 value)
    {
        if ((value = map._values[key]) == bytes32(0)) if (!contains(map, key)) _revertNotFound();
    }

    /// @dev Returns the keys. May run out-of-gas if the map is too big.
    function keys(Uint256ToBytes32Map storage map) internal view returns (uint256[] memory) {
        return EnumerableSetLib.values(map._keys);
    }

    /// @dev Adds a key-value pair to the map, or updates the value for an existing key.
    /// Returns true if `key` was added to the map, that is if it was not already present.
    function set(Uint256ToUint256Map storage map, uint256 key, uint256 value)
        internal
        returns (bool)
    {
        map._values[key] = value;
        return EnumerableSetLib.add(map._keys, key);
    }

    /// @dev Adds a key-value pair to the map, or updates the value for an existing key.
    /// Returns true if `key` was added to the map, that is if it was not already present.
    /// Reverts if the map grows bigger than the custom on-the-fly capacity `cap`.
    function set(Uint256ToUint256Map storage map, uint256 key, uint256 value, uint256 cap)
        internal
        returns (bool)
    {
        map._values[key] = value;
        return EnumerableSetLib.add(map._keys, key, cap);
    }

    /// @dev Removes a key-value pair from the map.
    /// Returns true if `key` was removed from the map, that is if it was present.
    function remove(Uint256ToUint256Map storage map, uint256 key) internal returns (bool) {
        delete map._values[key];
        return EnumerableSetLib.remove(map._keys, key);
    }

    /// @dev Shorthand for `isAdd ? map.set(key, value, cap) : map.remove(key)`.
    function update(
        Uint256ToUint256Map storage map,
        uint256 key,
        uint256 value,
        bool isAdd,
        uint256 cap
    ) internal returns (bool) {
        return isAdd ? set(map, key, value, cap) : remove(map, key);
    }

    /// @dev Returns true if the key is in the map.
    function contains(Uint256ToUint256Map storage map, uint256 key) internal view returns (bool) {
        return EnumerableSetLib.contains(map._keys, key);
    }

    /// @dev Returns the number of key-value pairs in the map.
    function length(Uint256ToUint256Map storage map) internal view returns (uint256) {
        return EnumerableSetLib.length(map._keys);
    }

    /// @dev Returns the key-value pair at index `i`. Reverts if `i` is out-of-bounds.
    function at(Uint256ToUint256Map storage map, uint256 i)
        internal
        view
        returns (uint256 key, uint256 value)
    {
        value = map._values[key = EnumerableSetLib.at(map._keys, i)];
    }

    /// @dev Tries to return the value associated with the key.
    function tryGet(Uint256ToUint256Map storage map, uint256 key)
        internal
        view
        returns (bool exists, uint256 value)
    {
        exists = (value = map._values[key]) != uint256(0) || contains(map, key);
    }

    /// @dev Returns the value for the key. Reverts if the key is not found.
    function get(Uint256ToUint256Map storage map, uint256 key)
        internal
        view
        returns (uint256 value)
    {
        if ((value = map._values[key]) == uint256(0)) if (!contains(map, key)) _revertNotFound();
    }

    /// @dev Returns the keys. May run out-of-gas if the map is too big.
    function keys(Uint256ToUint256Map storage map) internal view returns (uint256[] memory) {
        return EnumerableSetLib.values(map._keys);
    }

    /// @dev Adds a key-value pair to the map, or updates the value for an existing key.
    /// Returns true if `key` was added to the map, that is if it was not already present.
    function set(Uint256ToAddressMap storage map, uint256 key, address value)
        internal
        returns (bool)
    {
        map._values[key] = value;
        return EnumerableSetLib.add(map._keys, key);
    }

    /// @dev Adds a key-value pair to the map, or updates the value for an existing key.
    /// Returns true if `key` was added to the map, that is if it was not already present.
    /// Reverts if the map grows bigger than the custom on-the-fly capacity `cap`.
    function set(Uint256ToAddressMap storage map, uint256 key, address value, uint256 cap)
        internal
        returns (bool)
    {
        map._values[key] = value;
        return EnumerableSetLib.add(map._keys, key, cap);
    }

    /// @dev Removes a key-value pair from the map.
    /// Returns true if `key` was removed from the map, that is if it was present.
    function remove(Uint256ToAddressMap storage map, uint256 key) internal returns (bool) {
        delete map._values[key];
        return EnumerableSetLib.remove(map._keys, key);
    }

    /// @dev Shorthand for `isAdd ? map.set(key, value, cap) : map.remove(key)`.
    function update(
        Uint256ToAddressMap storage map,
        uint256 key,
        address value,
        bool isAdd,
        uint256 cap
    ) internal returns (bool) {
        return isAdd ? set(map, key, value, cap) : remove(map, key);
    }

    /// @dev Returns true if the key is in the map.
    function contains(Uint256ToAddressMap storage map, uint256 key) internal view returns (bool) {
        return EnumerableSetLib.contains(map._keys, key);
    }

    /// @dev Returns the number of key-value pairs in the map.
    function length(Uint256ToAddressMap storage map) internal view returns (uint256) {
        return EnumerableSetLib.length(map._keys);
    }

    /// @dev Returns the key-value pair at index `i`. Reverts if `i` is out-of-bounds.
    function at(Uint256ToAddressMap storage map, uint256 i)
        internal
        view
        returns (uint256 key, address value)
    {
        value = map._values[key = EnumerableSetLib.at(map._keys, i)];
    }

    /// @dev Tries to return the value associated with the key.
    function tryGet(Uint256ToAddressMap storage map, uint256 key)
        internal
        view
        returns (bool exists, address value)
    {
        exists = (value = map._values[key]) != address(0) || contains(map, key);
    }

    /// @dev Returns the value for the key. Reverts if the key is not found.
    function get(Uint256ToAddressMap storage map, uint256 key)
        internal
        view
        returns (address value)
    {
        if ((value = map._values[key]) == address(0)) if (!contains(map, key)) _revertNotFound();
    }

    /// @dev Returns the keys. May run out-of-gas if the map is too big.
    function keys(Uint256ToAddressMap storage map) internal view returns (uint256[] memory) {
        return EnumerableSetLib.values(map._keys);
    }

    /// @dev Adds a key-value pair to the map, or updates the value for an existing key.
    /// Returns true if `key` was added to the map, that is if it was not already present.
    function set(AddressToBytes32Map storage map, address key, bytes32 value)
        internal
        returns (bool)
    {
        map._values[key] = value;
        return EnumerableSetLib.add(map._keys, key);
    }

    /// @dev Adds a key-value pair to the map, or updates the value for an existing key.
    /// Returns true if `key` was added to the map, that is if it was not already present.
    /// Reverts if the map grows bigger than the custom on-the-fly capacity `cap`.
    function set(AddressToBytes32Map storage map, address key, bytes32 value, uint256 cap)
        internal
        returns (bool)
    {
        map._values[key] = value;
        return EnumerableSetLib.add(map._keys, key, cap);
    }

    /// @dev Removes a key-value pair from the map.
    /// Returns true if `key` was removed from the map, that is if it was present.
    function remove(AddressToBytes32Map storage map, address key) internal returns (bool) {
        delete map._values[key];
        return EnumerableSetLib.remove(map._keys, key);
    }

    /// @dev Shorthand for `isAdd ? map.set(key, value, cap) : map.remove(key)`.
    function update(
        AddressToBytes32Map storage map,
        address key,
        bytes32 value,
        bool isAdd,
        uint256 cap
    ) internal returns (bool) {
        return isAdd ? set(map, key, value, cap) : remove(map, key);
    }

    /// @dev Returns true if the key is in the map.
    function contains(AddressToBytes32Map storage map, address key) internal view returns (bool) {
        return EnumerableSetLib.contains(map._keys, key);
    }

    /// @dev Returns the number of key-value pairs in the map.
    function length(AddressToBytes32Map storage map) internal view returns (uint256) {
        return EnumerableSetLib.length(map._keys);
    }

    /// @dev Returns the key-value pair at index `i`. Reverts if `i` is out-of-bounds.
    function at(AddressToBytes32Map storage map, uint256 i)
        internal
        view
        returns (address key, bytes32 value)
    {
        value = map._values[key = EnumerableSetLib.at(map._keys, i)];
    }

    /// @dev Tries to return the value associated with the key.
    function tryGet(AddressToBytes32Map storage map, address key)
        internal
        view
        returns (bool exists, bytes32 value)
    {
        exists = (value = map._values[key]) != bytes32(0) || contains(map, key);
    }

    /// @dev Returns the value for the key. Reverts if the key is not found.
    function get(AddressToBytes32Map storage map, address key)
        internal
        view
        returns (bytes32 value)
    {
        if ((value = map._values[key]) == bytes32(0)) if (!contains(map, key)) _revertNotFound();
    }

    /// @dev Returns the keys. May run out-of-gas if the map is too big.
    function keys(AddressToBytes32Map storage map) internal view returns (address[] memory) {
        return EnumerableSetLib.values(map._keys);
    }

    /// @dev Adds a key-value pair to the map, or updates the value for an existing key.
    /// Returns true if `key` was added to the map, that is if it was not already present.
    function set(AddressToUint256Map storage map, address key, uint256 value)
        internal
        returns (bool)
    {
        map._values[key] = value;
        return EnumerableSetLib.add(map._keys, key);
    }

    /// @dev Adds a key-value pair to the map, or updates the value for an existing key.
    /// Returns true if `key` was added to the map, that is if it was not already present.
    /// Reverts if the map grows bigger than the custom on-the-fly capacity `cap`.
    function set(AddressToUint256Map storage map, address key, uint256 value, uint256 cap)
        internal
        returns (bool)
    {
        map._values[key] = value;
        return EnumerableSetLib.add(map._keys, key, cap);
    }

    /// @dev Removes a key-value pair from the map.
    /// Returns true if `key` was removed from the map, that is if it was present.
    function remove(AddressToUint256Map storage map, address key) internal returns (bool) {
        delete map._values[key];
        return EnumerableSetLib.remove(map._keys, key);
    }

    /// @dev Shorthand for `isAdd ? map.set(key, value, cap) : map.remove(key)`.
    function update(
        AddressToUint256Map storage map,
        address key,
        uint256 value,
        bool isAdd,
        uint256 cap
    ) internal returns (bool) {
        return isAdd ? set(map, key, value, cap) : remove(map, key);
    }

    /// @dev Returns true if the key is in the map.
    function contains(AddressToUint256Map storage map, address key) internal view returns (bool) {
        return EnumerableSetLib.contains(map._keys, key);
    }

    /// @dev Returns the number of key-value pairs in the map.
    function length(AddressToUint256Map storage map) internal view returns (uint256) {
        return EnumerableSetLib.length(map._keys);
    }

    /// @dev Returns the key-value pair at index `i`. Reverts if `i` is out-of-bounds.
    function at(AddressToUint256Map storage map, uint256 i)
        internal
        view
        returns (address key, uint256 value)
    {
        value = map._values[key = EnumerableSetLib.at(map._keys, i)];
    }

    /// @dev Tries to return the value associated with the key.
    function tryGet(AddressToUint256Map storage map, address key)
        internal
        view
        returns (bool exists, uint256 value)
    {
        exists = (value = map._values[key]) != uint256(0) || contains(map, key);
    }

    /// @dev Returns the value for the key. Reverts if the key is not found.
    function get(AddressToUint256Map storage map, address key)
        internal
        view
        returns (uint256 value)
    {
        if ((value = map._values[key]) == uint256(0)) if (!contains(map, key)) _revertNotFound();
    }

    /// @dev Returns the keys. May run out-of-gas if the map is too big.
    function keys(AddressToUint256Map storage map) internal view returns (address[] memory) {
        return EnumerableSetLib.values(map._keys);
    }

    /// @dev Adds a key-value pair to the map, or updates the value for an existing key.
    /// Returns true if `key` was added to the map, that is if it was not already present.
    function set(AddressToAddressMap storage map, address key, address value)
        internal
        returns (bool)
    {
        map._values[key] = value;
        return EnumerableSetLib.add(map._keys, key);
    }

    /// @dev Adds a key-value pair to the map, or updates the value for an existing key.
    /// Returns true if `key` was added to the map, that is if it was not already present.
    /// Reverts if the map grows bigger than the custom on-the-fly capacity `cap`.
    function set(AddressToAddressMap storage map, address key, address value, uint256 cap)
        internal
        returns (bool)
    {
        map._values[key] = value;
        return EnumerableSetLib.add(map._keys, key, cap);
    }

    /// @dev Removes a key-value pair from the map.
    /// Returns true if `key` was removed from the map, that is if it was present.
    function remove(AddressToAddressMap storage map, address key) internal returns (bool) {
        delete map._values[key];
        return EnumerableSetLib.remove(map._keys, key);
    }

    /// @dev Shorthand for `isAdd ? map.set(key, value, cap) : map.remove(key)`.
    function update(
        AddressToAddressMap storage map,
        address key,
        address value,
        bool isAdd,
        uint256 cap
    ) internal returns (bool) {
        return isAdd ? set(map, key, value, cap) : remove(map, key);
    }

    /// @dev Returns true if the key is in the map.
    function contains(AddressToAddressMap storage map, address key) internal view returns (bool) {
        return EnumerableSetLib.contains(map._keys, key);
    }

    /// @dev Returns the number of key-value pairs in the map.
    function length(AddressToAddressMap storage map) internal view returns (uint256) {
        return EnumerableSetLib.length(map._keys);
    }

    /// @dev Returns the key-value pair at index `i`. Reverts if `i` is out-of-bounds.
    function at(AddressToAddressMap storage map, uint256 i)
        internal
        view
        returns (address key, address value)
    {
        value = map._values[key = EnumerableSetLib.at(map._keys, i)];
    }

    /// @dev Tries to return the value associated with the key.
    function tryGet(AddressToAddressMap storage map, address key)
        internal
        view
        returns (bool exists, address value)
    {
        exists = (value = map._values[key]) != address(0) || contains(map, key);
    }

    /// @dev Returns the value for the key. Reverts if the key is not found.
    function get(AddressToAddressMap storage map, address key)
        internal
        view
        returns (address value)
    {
        if ((value = map._values[key]) == address(0)) if (!contains(map, key)) _revertNotFound();
    }

    /// @dev Returns the keys. May run out-of-gas if the map is too big.
    function keys(AddressToAddressMap storage map) internal view returns (address[] memory) {
        return EnumerableSetLib.values(map._keys);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Reverts with `EnumerableMapKeyNotFound()`.
    function _revertNotFound() private pure {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x88682bf3) // `EnumerableMapKeyNotFound()`.
            revert(0x1c, 0x04)
        }
    }
}
