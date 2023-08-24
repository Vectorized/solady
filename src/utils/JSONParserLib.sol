// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for parsing JSONs.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/JSONParserLib.sol)
library JSONParserLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Cannot parse the malformed JSON string
    error ParsingFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // There are 6 types of variables in JSON (excluding undefined).

    /// @dev For denoting that an item has not been initialized.
    /// A item returned from `parse` will never be of an undefined type.
    /// Parsing a malformed JSON string will simply revert.
    uint8 internal constant TYPE_UNDEFINED = 0;

    /// @dev Type representing an array (e.g. `[1,2,3]`).
    uint8 internal constant TYPE_ARRAY = 1;

    /// @dev Type representing an object (e.g. `{"a":"A","b":"B"}`).
    uint8 internal constant TYPE_OBJECT = 2;

    /// @dev Type representing a number (e.g. `-1.23e+21`).
    uint8 internal constant TYPE_NUMBER = 3;

    /// @dev Type representing a string (e.g. `"hello"`).
    uint8 internal constant TYPE_STRING = 4;

    /// @dev Type representing a boolean (i.e. `true` or `false`).
    uint8 internal constant TYPE_BOOLEAN = 5;

    /// @dev Type representing null (i.e. `null`).
    uint8 internal constant TYPE_NULL = 6;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev A pointer to a parsed JSON node.
    struct Item {
        // Do NOT modify the `_data` directly.
        bytes32 _data;
    }

    // Private constants for packing `_data`.

    uint256 private constant _BITPOS_STRING = 32 * 7;
    uint256 private constant _BITPOS_KEY_LENGTH = 32 * 6;
    uint256 private constant _BITPOS_KEY = 32 * 5;
    uint256 private constant _BITPOS_VALUE_LENGTH = 32 * 4;
    uint256 private constant _BITPOS_VALUE = 32 * 3;
    uint256 private constant _BITPOS_CHILD = 32 * 2;
    uint256 private constant _BITPOS_SIBLING_OR_PARENT = 32 * 1;
    uint256 private constant _BITMASK_POINTER = 0xffffffff;
    uint256 private constant _BITMASK_TYPE = 0xff;
    uint256 private constant _BITMASK_KEY_INITED = 1 << 8;
    uint256 private constant _BITMASK_VALUE_INITED = 1 << 9;
    uint256 private constant _BITMASK_CHILDREN_INITED = 1 << 10;
    uint256 private constant _BITMASK_PARENT_IS_ARRAY = 1 << 11;
    uint256 private constant _BITMASK_PARENT_IS_OBJECT = 1 << 12;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OPERATIONS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Note: String items will be double-quoted, JSON encoded.
    // This is for efficiency purposes, to avoid decoding and re-encoding.
    // If you need to concatenate the strings, simply trim off the double-quotes,
    // concatenate, and add back the double-quotes.

    /// @dev Parses the JSON string `s`, and returns the root.
    ///
    /// Reverts if `s` is not a valid JSON as specified in RFC 8259.
    ///
    /// Note: For efficiency, this function will NOT make a copy of `s`.
    /// The parsed tree will contain offsets to `s`.
    /// Do NOT pass in a string that will be modified later on.
    function parse(string memory s) internal pure returns (Item memory result) {
        bytes32 r = _query(_toInput(s), 255);
        /// @solidity memory-safe-assembly
        assembly {
            result := r
        }
    }

    /// @dev Returns the string value of the item.
    ///
    /// If the item's type is string, the returned string will be double-quoted, JSON encoded.
    ///
    /// Note: This function lazily instantiates and caches the returned string.
    /// For efficiency, only call this function on required items.
    /// Do NOT modify the returned string.
    function value(Item memory item) internal pure returns (string memory result) {
        bytes32 r = _query(_toInput(item), 0);
        /// @solidity memory-safe-assembly
        assembly {
            result := r
        }
    }

    /// @dev Returns the index of the item in the array.
    /// It the item's parent is not an array, returns 0.
    function index(Item memory item) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let packed := mload(item)
            let t := iszero(iszero(and(packed, _BITMASK_PARENT_IS_ARRAY)))
            result := mul(t, and(_BITMASK_POINTER, shr(_BITPOS_KEY, packed)))
        }
    }

    /// @dev Returns the key of the item in the object.
    /// It the item's parent is not an object, returns an empty string.
    ///
    /// The returned string will be double-quoted, JSON encoded.
    ///
    /// Note: This function lazily instantiates and caches the returned string.
    /// For efficiency, only call this function on required items.
    /// Do NOT modify the returned string.
    function key(Item memory item) internal pure returns (string memory result) {
        bytes32 r = _query(_toInput(item), 1);
        /// @solidity memory-safe-assembly
        assembly {
            result := r
        }
    }

    /// @dev Returns the key of the item in the object.
    /// It the item's parent is not an object, returns an empty array.
    ///
    /// Note: This function lazily instantiates and caches the returned array.
    /// For efficiency, only call this function on required items.
    /// Do NOT modify the returned array.
    function children(Item memory item) internal pure returns (Item[] memory result) {
        bytes32 r = _query(_toInput(item), 3);
        /// @solidity memory-safe-assembly
        assembly {
            result := r
        }
    }

    /// @dev Returns the item's type.
    function getType(Item memory item) internal pure returns (uint8 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := and(mload(item), _BITMASK_TYPE)
        }
    }

    /// Note: All types are mutually exclusive.

    /// @dev Returns whether the item is of type undefined.
    function isUndefined(Item memory item) internal pure returns (bool result) {
        result = _isType(item, TYPE_UNDEFINED);
    }

    /// @dev Returns whether the item is of type array.
    function isArray(Item memory item) internal pure returns (bool result) {
        result = _isType(item, TYPE_ARRAY);
    }

    /// @dev Returns whether the item is of type object.
    function isObject(Item memory item) internal pure returns (bool result) {
        result = _isType(item, TYPE_OBJECT);
    }

    /// @dev Returns whether the item is of type number.
    function isNumber(Item memory item) internal pure returns (bool result) {
        result = _isType(item, TYPE_NUMBER);
    }

    /// @dev Returns whether the item is of type string.
    function isString(Item memory item) internal pure returns (bool result) {
        result = _isType(item, TYPE_STRING);
    }

    /// @dev Returns whether the item is of type boolean.
    function isBoolean(Item memory item) internal pure returns (bool result) {
        result = _isType(item, TYPE_BOOLEAN);
    }

    /// @dev Returns whether the item is of type null.
    function isNull(Item memory item) internal pure returns (bool result) {
        result = _isType(item, TYPE_NULL);
    }

    /// @dev Returns the item's parent (if any).
    function parent(Item memory item) internal pure returns (Item memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := and(shr(_BITPOS_SIBLING_OR_PARENT, mload(item)), _BITMASK_POINTER)
        }
    }

    /// @dev Returns whether the item's parent (if any) is of type Array.
    /// Use this over `parent().isArray()` for efficiency.
    function parentIsArray(Item memory item) internal pure returns (bool result) {
        result = _hasFlagSet(item, _BITMASK_PARENT_IS_ARRAY);
    }

    /// @dev Returns whether the item's parent (if any) is of type Object.
    /// Use this over `parent().isObject()` for efficiency.
    function parentIsObject(Item memory item) internal pure returns (bool result) {
        result = _hasFlagSet(item, _BITMASK_PARENT_IS_OBJECT);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Performs a query on the input with the given mode.
    function _query(bytes32 input, uint256 mode) private pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            function fail() {
                mstore(0x00, 0x10182796)
                revert(0x1c, 0x04)
            }

            function chr(p_) -> _c {
                _c := byte(0, mload(p_))
            }

            function skipWhitespace(pIn_, end_) -> _pOut {
                for { _pOut := pIn_ } 1 { _pOut := add(_pOut, 1) } {
                    // ' ', '\n', '\r', '\t'.
                    if iszero(and(shr(chr(_pOut), 0x100002600), 1)) { leave }
                    if eq(_pOut, end_) { leave }
                }
            }

            function setPointer(packed_, bitpos_, p_) -> _packed {
                // Perform an out-of-gas revert if `p_` exceeds `_BITMASK_POINTER`.
                returndatacopy(returndatasize(), returndatasize(), gt(p_, _BITMASK_POINTER))
                _packed := or(and(not(shl(bitpos_, _BITMASK_POINTER)), packed_), shl(bitpos_, p_))
            }

            function getPointer(packed_, bitpos_) -> _p {
                _p := and(_BITMASK_POINTER, shr(bitpos_, packed_))
            }

            function mallocItem(s_, packed_, pStart_, pCurr_, type_) -> _item {
                _item := mload(0x40)
                packed_ :=
                    setPointer(
                        setPointer(packed_, _BITPOS_VALUE, sub(pStart_, add(s_, 0x20))),
                        _BITPOS_VALUE_LENGTH,
                        sub(pCurr_, pStart_)
                    )
                mstore(_item, or(packed_, type_))
                mstore(0x40, add(_item, 0x20))
            }

            function parseValue(s_, sibling_, pIn_, end_) -> _item, _pOut {
                let packed_ := setPointer(0, _BITPOS_STRING, s_)
                packed_ := setPointer(packed_, _BITPOS_SIBLING_OR_PARENT, sibling_)
                _pOut := skipWhitespace(pIn_, end_)
                if eq(_pOut, end_) { leave }
                for { let c_ := chr(_pOut) } 1 {} {
                    // If starts with '"'.
                    if eq(c_, 34) {
                        let pStart_ := _pOut
                        _pOut := parseStringSub(s_, packed_, _pOut, end_)
                        _item := mallocItem(s_, packed_, pStart_, _pOut, TYPE_STRING)
                        break
                    }
                    // If starts with '['.
                    if eq(c_, 91) {
                        _item, _pOut := parseArray(s_, packed_, _pOut, end_)
                        break
                    }
                    // If starts with '{'.
                    if eq(c_, 123) {
                        _item, _pOut := parseObject(s_, packed_, _pOut, end_)
                        break
                    }
                    // If starts with any in '0123456789-'.
                    if and(shr(c_, shl(45, 0x1ff9)), 1) {
                        _item, _pOut := parseNumber(s_, packed_, _pOut, end_)
                        break
                    }
                    if iszero(gt(add(_pOut, 4), end_)) {
                        let pStart_ := _pOut
                        let w_ := shr(224, mload(_pOut))
                        // 'true' in hex format.
                        if eq(w_, 0x74727565) {
                            _pOut := add(_pOut, 4)
                            _item := mallocItem(s_, packed_, pStart_, _pOut, TYPE_BOOLEAN)
                            break
                        }
                        // 'null' in hex format.
                        if eq(w_, 0x6e756c6c) {
                            _pOut := add(_pOut, 4)
                            _item := mallocItem(s_, packed_, pStart_, _pOut, TYPE_NULL)
                            break
                        }
                    }
                    if iszero(gt(add(_pOut, 5), end_)) {
                        let pStart_ := _pOut
                        let w_ := shr(216, mload(_pOut))
                        // 'false' in hex format.
                        if eq(w_, 0x66616c7365) {
                            _pOut := add(_pOut, 5)
                            _item := mallocItem(s_, packed_, pStart_, _pOut, TYPE_BOOLEAN)
                            break
                        }
                    }
                    fail()
                }
                _pOut := skipWhitespace(_pOut, end_)
            }

            function parseArray(s_, packed_, pIn_, end_) -> _item, _pOut {
                let j_ := 0
                for { _pOut := add(pIn_, 1) } 1 { _pOut := add(_pOut, 1) } {
                    if iszero(lt(_pOut, end_)) { fail() }
                    if iszero(_item) {
                        _pOut := skipWhitespace(_pOut, end_)
                        if eq(chr(_pOut), 93) { break } // ']'.
                    }
                    _item, _pOut := parseValue(s_, _item, _pOut, end_)
                    if iszero(_item) { _pOut := end_ }
                    let d_ := or(mload(_item), _BITMASK_PARENT_IS_ARRAY)
                    mstore(_item, setPointer(d_, _BITPOS_KEY, j_))
                    j_ := add(j_, 1)
                    if lt(_pOut, end_) {
                        let c_ := chr(_pOut)
                        if eq(c_, 93) { break } // ']'.
                        if eq(c_, 44) { continue } // ','.
                    }
                    _pOut := end_
                }
                _pOut := add(_pOut, 1)
                packed_ := setPointer(packed_, _BITPOS_CHILD, _item)
                _item := mallocItem(s_, packed_, pIn_, _pOut, TYPE_ARRAY)
            }

            function parseObject(s_, packed_, pIn_, end_) -> _item, _pOut {
                for { _pOut := add(pIn_, 1) } 1 { _pOut := add(_pOut, 1) } {
                    if iszero(lt(_pOut, end_)) { fail() }
                    if iszero(_item) {
                        _pOut := skipWhitespace(_pOut, end_)
                        if eq(chr(_pOut), 125) { break } // '}'.
                    }
                    _pOut := skipWhitespace(_pOut, end_)
                    let pKeyStart_ := _pOut
                    let pKeyEnd_ := parseStringSub(s_, _item, _pOut, end_)
                    _pOut := skipWhitespace(pKeyEnd_, end_)
                    if iszero(and(lt(_pOut, end_), eq(chr(_pOut), 58))) { _pOut := end_ }
                    _pOut := add(_pOut, 1)
                    _item, _pOut := parseValue(s_, _item, _pOut, end_)
                    if iszero(_item) { _pOut := end_ }
                    let d_ := or(_BITMASK_PARENT_IS_OBJECT, mload(_item))
                    d_ := setPointer(d_, _BITPOS_KEY_LENGTH, sub(pKeyEnd_, pKeyStart_))
                    mstore(_item, setPointer(d_, _BITPOS_KEY, sub(pKeyStart_, add(s_, 0x20))))
                    if lt(_pOut, end_) {
                        let c_ := chr(_pOut)
                        if eq(c_, 125) { break } // '}'.
                        if eq(c_, 44) { continue } // ','.
                    }
                    _pOut := end_
                }
                _pOut := add(_pOut, 1)
                packed_ := setPointer(packed_, _BITPOS_CHILD, _item)
                _item := mallocItem(s_, packed_, pIn_, _pOut, TYPE_OBJECT)
            }

            function parseStringSub(s_, packed_, pIn_, end_) -> _pOut {
                for { _pOut := add(pIn_, 1) } 1 {} {
                    let c_ := chr(_pOut)
                    if iszero(mul(lt(_pOut, end_), xor(c_, 34))) { break } // '"'.
                    // Not '\'.
                    if iszero(eq(c_, 92)) {
                        _pOut := add(_pOut, 1)
                        continue
                    }
                    c_ := chr(add(_pOut, 1))
                    // 'u'.
                    if eq(c_, 117) {
                        _pOut := add(_pOut, 6)
                        continue
                    }
                    // '"', '\', '//', 'b', 'f', 'n', 'r', 't'.
                    if and(shr(sub(c_, 34), 0x510110400000000002001), 1) {
                        _pOut := add(_pOut, 2)
                        continue
                    }
                    _pOut := end_
                }
                if iszero(lt(_pOut, end_)) { fail() }
                _pOut := add(_pOut, 1)
            }

            function skip0To9s(pIn_, end_, atLeastOne_) -> _pOut {
                for { _pOut := pIn_ } iszero(eq(_pOut, end_)) { _pOut := add(_pOut, 1) } {
                    if iszero(and(shr(chr(_pOut), shl(48, 0x3ff)), 1)) { break } // Not '0'..'9'.
                }
                if and(atLeastOne_, eq(pIn_, _pOut)) { fail() }
            }

            function parseNumber(s_, packed_, pIn_, end_) -> _item, _pOut {
                _pOut := pIn_
                if eq(byte(0, mload(_pOut)), 45) { _pOut := add(_pOut, 1) } // '-'.
                if iszero(and(shr(chr(_pOut), shl(48, 0x3ff)), lt(_pOut, end_))) { fail() } // Not '0'..'9'.
                let c_ := chr(_pOut)
                _pOut := add(_pOut, 1)
                if iszero(eq(c_, 48)) { _pOut := skip0To9s(_pOut, end_, 0) } // Not '0'.
                // '.'.
                if and(lt(_pOut, end_), eq(chr(_pOut), 46)) {
                    _pOut := skip0To9s(add(_pOut, 1), end_, 1)
                }
                // 'E', 'e'.
                if and(lt(_pOut, end_), and(shr(chr(_pOut), shl(69, 0x100000001)), 1)) {
                    _pOut := add(_pOut, 1)
                    _pOut := add(_pOut, and(shr(chr(_pOut), shl(43, 5)), lt(_pOut, end_))) // '+', '-'.
                    _pOut := skip0To9s(_pOut, end_, 1)
                }
                _item := mallocItem(s_, packed_, pIn_, _pOut, TYPE_NUMBER)
            }

            function copyString(s_, offset_, len_) -> _sCopy {
                _sCopy := mload(0x40)
                s_ := add(s_, offset_)
                let w_ := not(0x1f)
                for { let i_ := and(add(len_, 0x1f), w_) } 1 {} {
                    mstore(add(_sCopy, i_), mload(add(s_, i_)))
                    i_ := add(i_, w_) // `sub(i_, 0x20)`.
                    if iszero(i_) { break }
                }
                mstore(_sCopy, len_) // Copy the length.
                mstore(add(add(_sCopy, 0x20), len_), 0) // Zeroize the last slot.
                mstore(0x40, add(add(_sCopy, 0x40), len_)) // Allocate memory.
            }

            function value(item_) -> _value {
                let packed_ := mload(item_)
                _value := getPointer(packed_, _BITPOS_VALUE) // The offset in the string.
                if iszero(and(_BITMASK_VALUE_INITED, packed_)) {
                    let s_ := getPointer(packed_, _BITPOS_STRING)
                    let len_ := getPointer(packed_, _BITPOS_VALUE_LENGTH)
                    _value := copyString(s_, _value, len_)
                    packed_ := setPointer(packed_, _BITPOS_VALUE, _value)
                    mstore(s_, or(_BITMASK_VALUE_INITED, packed_))
                }
            }

            function children(item_) -> _arr {
                _arr := 0x60 // Initialize to the zero pointer.
                let packed_ := mload(item_)
                if or(iszero(packed_), iszero(item_)) { leave }
                let t_ := and(_BITMASK_TYPE, packed_)
                if or(eq(t_, TYPE_ARRAY), eq(t_, TYPE_OBJECT)) {
                    if and(packed_, _BITMASK_CHILDREN_INITED) {
                        _arr := getPointer(packed_, _BITPOS_CHILD)
                        leave
                    }
                    _arr := mload(0x40)
                    let o_ := add(_arr, 0x20)
                    for { let h_ := getPointer(packed_, _BITPOS_CHILD) } h_ {} {
                        mstore(o_, h_)
                        let q_ := mload(h_)
                        let y_ := getPointer(q_, _BITPOS_SIBLING_OR_PARENT)
                        mstore(h_, setPointer(q_, _BITPOS_SIBLING_OR_PARENT, item_))
                        h_ := y_
                        o_ := add(o_, 0x20)
                    }
                    let w_ := not(0x1f)
                    let n_ := add(w_, sub(o_, _arr))
                    mstore(_arr, shr(5, n_))
                    mstore(0x40, o_)
                    packed_ := setPointer(packed_, _BITPOS_CHILD, _arr)
                    mstore(item_, or(_BITMASK_CHILDREN_INITED, packed_))
                    // Reverse the array.
                    if iszero(lt(n_, 0x40)) {
                        let lo_ := add(_arr, 0x20)
                        let hi_ := add(_arr, n_)
                        for {} 1 {} {
                            let temp_ := mload(lo_)
                            mstore(lo_, mload(hi_))
                            mstore(hi_, temp_)
                            hi_ := add(hi_, w_)
                            lo_ := add(lo_, 0x20)
                            if iszero(lt(lo_, hi_)) { break }
                        }
                    }
                }
            }

            function getString(item_, bitpos_, bitposLength_, bitmaskInited_) -> _result {
                _result := 0x60 // Initialize to the zero pointer.
                let packed_ := mload(item_)
                if or(iszero(item_), iszero(packed_)) { leave }
                _result := getPointer(packed_, bitpos_)
                if iszero(and(bitmaskInited_, packed_)) {
                    let s_ := getPointer(packed_, _BITPOS_STRING)
                    let n := getPointer(packed_, bitposLength_)
                    _result := copyString(s_, _result, n)
                    mstore(item_, or(bitmaskInited_, setPointer(packed_, bitpos_, _result)))
                }
            }

            switch mode
            // Get value.
            case 0 {
                result :=
                    getString(input, _BITPOS_VALUE, _BITPOS_VALUE_LENGTH, _BITMASK_VALUE_INITED)
            }
            // Get key.
            case 1 {
                result := 0x60 // Initialize to the zero pointer.
                if and(mload(input), _BITMASK_PARENT_IS_OBJECT) {
                    result := getString(input, _BITPOS_KEY, _BITPOS_KEY_LENGTH, _BITMASK_KEY_INITED)
                }
            }
            // Get children.
            case 3 { result := children(input) }
            // Parse.
            default {
                let s := input
                let p := add(s, 0x20)
                let e := add(p, mload(s))
                result, p := parseValue(s, 0, p, e)
                if or(lt(p, e), iszero(result)) { fail() }
            }
        }
    }

    /// @dev Casts the input to a bytes32.
    function _toInput(string memory input) private pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := input
        }
    }

    /// @dev Casts the input to a bytes32.
    function _toInput(Item memory input) private pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := input
        }
    }

    /// @dev Returns whether the input is of type `t`.
    function _isType(Item memory input, uint256 t) private pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := eq(and(mload(input), _BITMASK_TYPE), t)
        }
    }

    /// @dev Returns whether the input has flag `f` set to true.
    function _hasFlagSet(Item memory input, uint256 f) private pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := iszero(iszero(and(mload(input), f)))
        }
    }
}
