# JSONParserLib

Library for parsing JSONs.






<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### ParsingFailed()

```solidity
error ParsingFailed()
```

The input is invalid.

## Constants

There are 6 types of variables in JSON (excluding undefined).

### TYPE_UNDEFINED

```solidity
uint8 internal constant TYPE_UNDEFINED = 0
```

For denoting that an item has not been initialized.   
A item returned from `parse` will never be of an undefined type.   
Parsing an invalid JSON string will simply revert.

### TYPE_ARRAY

```solidity
uint8 internal constant TYPE_ARRAY = 1
```

Type representing an array (e.g. `[1,2,3]`).

### TYPE_OBJECT

```solidity
uint8 internal constant TYPE_OBJECT = 2
```

Type representing an object (e.g. `{"a":"A","b":"B"}`).

### TYPE_NUMBER

```solidity
uint8 internal constant TYPE_NUMBER = 3
```

Type representing a number (e.g. `-1.23e+21`).

### TYPE_STRING

```solidity
uint8 internal constant TYPE_STRING = 4
```

Type representing a string (e.g. `"hello"`).

### TYPE_BOOLEAN

```solidity
uint8 internal constant TYPE_BOOLEAN = 5
```

Type representing a boolean (i.e. `true` or `false`).

### TYPE_NULL

```solidity
uint8 internal constant TYPE_NULL = 6
```

Type representing null (i.e. `null`).

## Structs

### Item

```solidity
struct Item {
    // Do NOT modify the `_data` directly.
    uint256 _data;
}
```

A pointer to a parsed JSON node.

## Json Parsing Operation

### parse(string)

```solidity
function parse(string memory s)
    internal
    pure
    returns (Item memory result)
```

Parses the JSON string `s`, and returns the root.   
Reverts if `s` is not a valid JSON as specified in RFC 8259.   
Object items WILL simply contain all their children, inclusive of repeated keys,   
in the same order which they appear in the JSON string.   
Note: For efficiency, this function WILL NOT make a copy of `s`.   
The parsed tree WILL contain offsets to `s`.   
Do NOT pass in a string that WILL be modified later on.

## Json Item Operations

<b>Note:</b>

- An item is a node in the JSON tree.   
- The value of a string item WILL be double-quoted, JSON encoded.   
- We make a distinction between `index` and `key`.   
  - Items in arrays are located by `index` (uint256).   
  - Items in objects are located by `key` (string).   
- Keys are always strings, double-quoted, JSON encoded.   
These design choices are made to balance between efficiency and ease-of-use.

### value(Item)

```solidity
function value(Item memory item)
    internal
    pure
    returns (string memory result)
```

Returns the string value of the item.   
This is its exact string representation in the original JSON string.   
The returned string WILL have leading and trailing whitespace trimmed.   
All inner whitespace WILL be preserved, exactly as it is in the original JSON string.   
If the item's type is string, the returned string WILL be double-quoted, JSON encoded.   
Note: This function lazily instantiates and caches the returned string.   
Do NOT modify the returned string.

### index(Item)

```solidity
function index(Item memory item) internal pure returns (uint256 result)
```

Returns the index of the item in the array.   
It the item's parent is not an array, returns 0.

### key(Item)

```solidity
function key(Item memory item)
    internal
    pure
    returns (string memory result)
```

Returns the key of the item in the object.   
It the item's parent is not an object, returns an empty string.   
The returned string WILL be double-quoted, JSON encoded.   
Note: This function lazily instantiates and caches the returned string.   
Do NOT modify the returned string.

### children(Item)

```solidity
function children(Item memory item)
    internal
    pure
    returns (Item[] memory result)
```

Returns the key of the item in the object.   
It the item is neither an array nor object, returns an empty array.   
Note: This function lazily instantiates and caches the returned array.   
Do NOT modify the returned array.

### size(Item)

```solidity
function size(Item memory item) internal pure returns (uint256 result)
```

Returns the number of children.   
It the item is neither an array nor object, returns zero.

### at(Item,uint256)

```solidity
function at(Item memory item, uint256 i)
    internal
    pure
    returns (Item memory result)
```

Returns the item at index `i` for (array).   
If `item` is not an array, the result's type WILL be undefined.   
If there is no item with the index, the result's type WILL be undefined.

### at(Item,string)

```solidity
function at(Item memory item, string memory k)
    internal
    pure
    returns (Item memory result)
```

Returns the item at key `k` for (object).   
If `item` is not an object, the result's type WILL be undefined.   
The key MUST be double-quoted, JSON encoded. This is for efficiency reasons.   
- Correct : `item.at('"k"')`.   
- Wrong   : `item.at("k")`.   
For duplicated keys, the last item with the key WILL be returned.   
If there is no item with the key, the result's type WILL be undefined.

### getType(Item)

```solidity
function getType(Item memory item) internal pure returns (uint8 result)
```

Returns the item's type.

### isUndefined(Item)

```solidity
function isUndefined(Item memory item)
    internal
    pure
    returns (bool result)
```

/// Note: All types are mutually exclusive.   
@dev Returns whether the item is of type undefined.

### isArray(Item)

```solidity
function isArray(Item memory item) internal pure returns (bool result)
```

Returns whether the item is of type array.

### isObject(Item)

```solidity
function isObject(Item memory item) internal pure returns (bool result)
```

Returns whether the item is of type object.

### isNumber(Item)

```solidity
function isNumber(Item memory item) internal pure returns (bool result)
```

Returns whether the item is of type number.

### isString(Item)

```solidity
function isString(Item memory item) internal pure returns (bool result)
```

Returns whether the item is of type string.

### isBoolean(Item)

```solidity
function isBoolean(Item memory item) internal pure returns (bool result)
```

Returns whether the item is of type boolean.

### isNull(Item)

```solidity
function isNull(Item memory item) internal pure returns (bool result)
```

Returns whether the item is of type null.

### parent(Item)

```solidity
function parent(Item memory item)
    internal
    pure
    returns (Item memory result)
```

Returns the item's parent.   
If the item does not have a parent, the result's type will be undefined.

## Utility Functions

### parseUint(string)

```solidity
function parseUint(string memory s)
    internal
    pure
    returns (uint256 result)
```

Parses an unsigned integer from a string (in decimal, i.e. base 10).   
Reverts if `s` is not a valid uint256 string matching the RegEx `^[0-9]+$`,   
or if the parsed number is too big for a uint256.

### parseInt(string)

```solidity
function parseInt(string memory s) internal pure returns (int256 result)
```

Parses a signed integer from a string (in decimal, i.e. base 10).   
Reverts if `s` is not a valid int256 string matching the RegEx `^[+-]?[0-9]+$`,   
or if the parsed number cannot fit within `[-2**255 .. 2**255 - 1]`.

### parseUintFromHex(string)

```solidity
function parseUintFromHex(string memory s)
    internal
    pure
    returns (uint256 result)
```

Parses an unsigned integer from a string (in hexadecimal, i.e. base 16).   
Reverts if `s` is not a valid uint256 hex string matching the RegEx   
`^(0[xX])?[0-9a-fA-F]+$`, or if the parsed number cannot fit within `[0 .. 2**256 - 1]`.

### decodeString(string)

```solidity
function decodeString(string memory s)
    internal
    pure
    returns (string memory result)
```

Decodes a JSON encoded string.   
The string MUST be double-quoted, JSON encoded.   
Reverts if the string is invalid.   
As you can see, it's pretty complex for a deceptively simple looking task.