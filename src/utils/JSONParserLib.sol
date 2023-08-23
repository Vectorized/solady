// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for parsing JSONs.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/JSONParserLib.sol)
library JSONParserLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Cannot parse the JSON string. It may be malformed.
    error ParsingFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev A pointer to a parsed JSON node.
    struct Item {
        bytes32 _data;
    }

    uint256 private constant _BITMASK_KEY_INITED = 1 << 8;
    uint256 private constant _BITMASK_VALUE_INITED = 1 << 9;
    uint256 private constant _BITMASK_CHILDREN_INITED = 1 << 10;
    uint256 private constant _BITMASK_PARENT_IS_ARRAY = 1 << 11;
    uint256 private constant _BITMASK_PARENT_IS_OBJECT = 1 << 12;
    uint256 private constant _BITPOS_STRING = 32 * 7;
    uint256 private constant _BITPOS_KEY_LENGTH = 32 * 6;
    uint256 private constant _BITPOS_KEY = 32 * 5;
    uint256 private constant _BITPOS_VALUE_LENGTH = 32 * 4;
    uint256 private constant _BITPOS_VALUE = 32 * 3;
    uint256 private constant _BITPOS_CHILD = 32 * 2;
    uint256 private constant _BITPOS_SIBLING = 32 * 1;
    uint256 private constant _BITMASK_POINTER = 0xffffffff;
    uint256 private constant _BITMASK_TYPE = 0xff;
    uint256 private constant _TYPE_UNDEFINED = 1;
    uint256 private constant _TYPE_ARRAY = 1;
    uint256 private constant _TYPE_OBJECT = 2;
    uint256 private constant _TYPE_NUMBER = 3;
    uint256 private constant _TYPE_STRING = 4;
    uint256 private constant _TYPE_BOOL = 5;
    uint256 private constant _TYPE_NULL = 6;

    event LogUint256(uint256 indexed i);

    uint256 private constant _LOG_UINT256_SELECTOR =
        0x535266f26566acd2ef175615d9f1140b36f149b810b33fb93143236a69912c32;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OPERATIONS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Parses the JSON string `s`, and returns the root.
    ///
    /// Note: For efficiency, this function will NOT make a copy of `s`.
    /// The parsed tree will contain offsets to `s`.
    /// Do NOT pass in a string that will be modified later on.
    function parse(string memory s) internal returns (Item memory result) {
        bytes32 r = _query(_toInput(s), 255);
        assembly {
            result := r
        }
    }

    /// @dev Returns the string value of the item.
    /// If the item's type is string, the returned string will be double-quoted.
    ///
    /// Note: This function lazily instantiates and caches the returned string.
    /// For efficiency, only call this function on required items.
    /// Do NOT modify the returned string.
    function value(Item memory item) internal returns (string memory result) {
        bytes32 r = _query(_toInput(item), 0);
        assembly {
            result := r
        }
    }

    /// @dev Returns the index of the item in the array.
    /// It the item's parent is not an array, returns 0.
    function index(Item memory item) internal returns (uint256 result) {
        assembly {
            if and(mload(item), _BITMASK_PARENT_IS_ARRAY) {
                result := and(_BITMASK_POINTER, shr(_BITPOS_KEY, mload(item)))
            }
        }
    }

    /// @dev Returns the key of the item in the object.
    /// It the item's parent is not an object, returns the empty string.
    ///
    /// Note: This function lazily instantiates and caches the returned string.
    /// For efficiency, only call this function on required items.
    /// Do NOT modify the returned string.
    function key(Item memory item) internal returns (string memory result) {
        bytes32 r = _query(_toInput(item), 1);
        assembly {
            result := r
        }
    }

    /// @dev Returns the key of the item in the object.
    /// It the item's parent is not an object, returns the empty string.
    ///
    /// Note: This function lazily instantiates and caches the returned array.
    /// For efficiency, only call this function on required items.
    /// Do NOT modify the returned array.
    function children(Item memory item) internal returns (Item[] memory result) {
        bytes32 r = _query(_toInput(item), 3);
        assembly {
            result := r
        }
    }

    function isUndefined(Item memory item) internal returns (bool result) {
        result = _isType(item, _TYPE_UNDEFINED);
    }

    function isArray(Item memory item) internal returns (bool result) {
        result = _isType(item, _TYPE_ARRAY);
    }

    function isObject(Item memory item) internal returns (bool result) {
        result = _isType(item, _TYPE_OBJECT);
    }

    function isNumber(Item memory item) internal returns (bool result) {
        result = _isType(item, _TYPE_NUMBER);
    }

    function isString(Item memory item) internal returns (bool result) {
        result = _isType(item, _TYPE_STRING);
    }

    function isBool(Item memory item) internal returns (bool result) {
        result = _isType(item, _TYPE_BOOL);
    }

    function isNull(Item memory item) internal returns (bool result) {
        result = _isType(item, _TYPE_NULL);
    }

    function parentIsArray(Item memory item) internal returns (bool result) {
        result = _hasFlagSet(item, _BITMASK_PARENT_IS_ARRAY);
    }

    function parentIsObject(Item memory item) internal returns (bool result) {
        result = _hasFlagSet(item, _BITMASK_PARENT_IS_OBJECT);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _query(bytes32 input, uint256 mode) private returns (bytes32 result) {
        assembly {
            function fail() {
                mstore(0x00, 0x10182796)
                revert(0x1c, 0x04)
            }

            function chr(p_) -> _c {
                _c := byte(0, mload(p_))
            }

            function skipWhitespace(p_, e_) -> _p {
                for { _p := p_ } iszero(eq(_p, e_)) { _p := add(_p, 1) } {
                    if iszero(and(shr(chr(_p), 0x100002600), 1)) { break }
                }
            }

            function setPointer(packed_, bitpos_, p_) -> _packed {
                returndatacopy(gas(), returndatasize(), gt(p_, _BITMASK_POINTER))
                _packed := or(and(not(shl(bitpos_, _BITMASK_POINTER)), packed_), shl(bitpos_, p_))
            }

            function getPointer(packed_, bitpos_) -> _p {
                _p := and(_BITMASK_POINTER, shr(bitpos_, packed_))
            }

            function mallocItem(s_, packed_, pStart_, pCurr_, type_) -> _item {
                _item := mload(0x40)
                packed_ := setPointer(packed_, _BITPOS_VALUE, sub(pStart_, add(s_, 0x20)))
                packed_ := setPointer(packed_, _BITPOS_VALUE_LENGTH, sub(pCurr_, pStart_))
                mstore(_item, or(packed_, type_))
                mstore(0x40, add(_item, 0x20))
            }

            function parseValue(s_, b_, p_, e_) -> _item, _p {
                let packed_ := setPointer(0, _BITPOS_STRING, s_)
                packed_ := setPointer(packed_, _BITPOS_SIBLING, b_)
                _p := skipWhitespace(p_, e_)
                if eq(_p, e_) { leave }
                let c_ := chr(_p)
                for {} 1 {} {
                    // If starts with any in '0123456789-'.
                    if and(shr(sub(c_, 45), 0x1ff9), 1) {
                        _item, _p := parseNumber(s_, packed_, _p, e_)
                        break
                    }
                    // If starts with '['.
                    if eq(c_, 91) {
                        _item, _p := parseArray(s_, packed_, _p, e_)
                        break
                    }
                    // If starts with '{'.
                    if eq(c_, 123) {
                        _item, _p := parseObject(s_, packed_, _p, e_)
                        break
                    }
                    // If starts with '"'.
                    if eq(c_, 34) {
                        let pStart_ := _p
                        _p := parseStringSub(s_, packed_, _p, e_)
                        _item := mallocItem(s_, packed_, pStart_, _p, _TYPE_STRING)
                        break
                    }
                    if iszero(gt(add(_p, 4), e_)) {
                        let pStart_ := _p
                        let w_ := shr(224, mload(_p))
                        // 'true' in hex format.
                        if eq(w_, 0x74727565) {
                            _p := add(_p, 4)
                            _item := mallocItem(s_, packed_, pStart_, _p, _TYPE_BOOL)
                            break
                        }
                        // 'null' in hex format.
                        if eq(w_, 0x6e756c6c) {
                            _p := add(_p, 4)
                            _item := mallocItem(s_, packed_, pStart_, _p, _TYPE_NULL)
                            break
                        }
                    }
                    if iszero(gt(add(_p, 5), e_)) {
                        let pStart_ := _p
                        let w_ := shr(216, mload(_p))
                        // 'false' in hex format.
                        if eq(w_, 0x66616c7365) {
                            _p := add(_p, 5)
                            _item := mallocItem(s_, packed_, pStart_, _p, _TYPE_BOOL)
                            break
                        }
                    }
                    fail()
                }
                _p := skipWhitespace(_p, e_)
            }

            function parseArray(s_, packed_, p_, e_) -> _item, _p {
                let j_ := 0
                for { _p := add(p_, 1) } 1 { _p := add(_p, 1) } {
                    if iszero(lt(_p, e_)) { fail() }
                    if eq(chr(_p), 93) { break } // ']'.
                    _item, _p := parseValue(s_, _item, _p, e_)
                    if _item {
                        let d_ := or(mload(_item), _BITMASK_PARENT_IS_ARRAY)
                        mstore(_item, setPointer(d_, _BITPOS_KEY, j_))
                        j_ := add(j_, 1)
                    }
                    if lt(_p, e_) {
                        let c_ := chr(_p)
                        if eq(c_, 93) { break } // ']'.
                        if eq(c_, 44) { continue } // ','.
                    }
                    _p := e_
                }
                _p := add(_p, 1)
                packed_ := setPointer(packed_, _BITPOS_CHILD, _item)
                _item := mallocItem(s_, packed_, p_, _p, _TYPE_ARRAY)
            }

            function parseObject(s_, packed_, p_, e_) -> _item, _p {
                for { _p := add(p_, 1) } 1 { _p := add(_p, 1) } {
                    if iszero(lt(_p, e_)) { fail() }
                    if eq(chr(_p), 125) { break } // '}'.
                    _p := skipWhitespace(_p, e_)
                    let pKeyStart_ := _p
                    let pKeyEnd_ := parseStringSub(s_, _item, _p, e_)
                    _p := skipWhitespace(pKeyEnd_, e_)
                    if iszero(and(lt(_p, e_), eq(chr(_p), 58))) { _p := e_ }
                    _p := add(_p, 1)
                    _item, _p := parseValue(s_, _item, _p, e_)
                    if iszero(_item) { _p := e_ }
                    let d_ := or(_BITMASK_PARENT_IS_OBJECT, mload(_item))
                    d_ := setPointer(d_, _BITPOS_KEY_LENGTH, sub(pKeyEnd_, pKeyStart_))
                    mstore(_item, setPointer(d_, _BITPOS_KEY, sub(pKeyStart_, add(s_, 0x20))))
                    if lt(_p, e_) {
                        let c_ := chr(_p)
                        if eq(c_, 125) { break } // '}'.
                        if eq(c_, 44) { continue } // ','.
                    }
                    _p := e_
                }
                _p := add(_p, 1)
                packed_ := setPointer(packed_, _BITPOS_CHILD, _item)
                _item := mallocItem(s_, packed_, p_, _p, _TYPE_OBJECT)
            }

            function parseStringSub(s_, packed_, p_, e_) -> _p {
                for { _p := add(p_, 1) } 1 {} {
                    let c_ := chr(_p)
                    if iszero(mul(lt(_p, e_), xor(c_, 34))) { break } // '"'.
                    // Not '\'.
                    if iszero(eq(c_, 92)) {
                        _p := add(_p, 1)
                        continue
                    }
                    c_ := chr(add(_p, 1))
                    // 'u'.
                    if eq(c_, 117) {
                        _p := add(_p, 6)
                        continue
                    }
                    // '"', '\', '//', 'b', 'f', 'n', 'r', 't'.
                    if and(shr(sub(c_, 34), 0x510110400000000002001), 1) {
                        _p := add(_p, 2)
                        continue
                    }
                    _p := e_
                }
                if iszero(lt(_p, e_)) { fail() }
                _p := add(_p, 1)
            }

            function skipDigits(p_, e_, _atLeastOne) -> _p {
                for { _p := p_ } iszero(eq(_p, e_)) { _p := add(_p, 1) } {
                    if iszero(and(shr(chr(_p), 0x3ff000000000000), 1)) { break }
                }
                if and(_atLeastOne, eq(_p, p_)) { fail() }
            }

            function parseNumber(s_, packed_, p_, e_) -> _item, _p {
                _p := p_
                if eq(byte(0, mload(_p)), 45) { _p := add(_p, 1) } // '-'.
                if iszero(and(shr(chr(_p), 0x3ff000000000000), lt(_p, e_))) { fail() } // Not '0'..'9'.
                let c_ := chr(_p)
                _p := add(_p, 1)
                if iszero(eq(c_, 48)) { _p := skipDigits(_p, e_, 0) } // Not '0'.
                if and(lt(_p, e_), eq(chr(_p), 46)) { _p := skipDigits(add(_p, 1), e_, 1) }
                if and(lt(_p, e_), and(shr(sub(chr(_p), 69), 0x100000001), 1)) {
                    // 'E', 'e'.
                    _p := add(_p, 1)
                    _p := add(_p, or(lt(_p, e_), and(shr(sub(chr(_p), 43), 3), 1))) // '-', '+'.
                    _p := skipDigits(_p, e_, 1)
                }
                _item := mallocItem(s_, packed_, p_, _p, _TYPE_NUMBER)
            }

            function copyString(s_, o_, n_) -> _d {
                _d := mload(0x40)
                s_ := add(s_, o_)
                for { let i_ := 0 } lt(i_, n_) {} {
                    i_ := add(i_, 0x20)
                    mstore(add(_d, i_), mload(add(s_, i_)))
                }
                mstore(_d, n_) // Copy the length.
                mstore(add(add(_d, 0x40), n_), 0) // Zeroize the last slot.
                mstore(0x40, add(add(_d, 0x60), n_)) // Allocate memory.
            }

            function value(item_) -> _v {
                let packed_ := mload(item_)
                _v := getPointer(packed_, _BITPOS_VALUE)
                if iszero(and(_BITMASK_VALUE_INITED, packed_)) {
                    let s_ := getPointer(packed_, _BITPOS_STRING)
                    let n_ := getPointer(packed_, _BITPOS_VALUE_LENGTH)
                    _v := copyString(s_, _v, n_)
                    packed_ := setPointer(packed_, _BITPOS_VALUE, _v)
                    mstore(s_, or(_BITMASK_VALUE_INITED, packed_))
                }
            }

            function children(item_) -> _arr {
                _arr := 0x60 // Initialize to the zero pointer.
                let packed_ := mload(item_)
                let t_ := and(_BITMASK_TYPE, packed_)
                if or(eq(t_, _TYPE_ARRAY), eq(t_, _TYPE_OBJECT)) {
                    if and(packed_, _BITMASK_CHILDREN_INITED) {
                        _arr := getPointer(packed_, _BITPOS_CHILD)
                        leave
                    }
                    _arr := mload(0x40)
                    let o_ := add(_arr, 0x20)
                    for { let h_ := getPointer(packed_, _BITPOS_CHILD) } h_ {} {
                        mstore(o_, h_)
                        h_ := getPointer(mload(h_), _BITPOS_SIBLING)
                        o_ := add(o_, 0x20)
                    }
                    let n_ := shr(5, sub(o_, add(_arr, 0x20)))
                    mstore(_arr, n_)
                    mstore(0x40, o_)
                    // Reverse the array.
                    if iszero(lt(n_, 2)) {
                        let l_ := add(_arr, 0x20)
                        let h_ := add(_arr, shl(5, n_))
                        for {} 1 {} {
                            let t := mload(l_)
                            mstore(l_, mload(h_))
                            mstore(h_, t)
                            h_ := sub(h_, 0x20)
                            l_ := add(l_, 0x20)
                            if iszero(lt(l_, h_)) { break }
                        }
                    }
                    packed_ := setPointer(packed_, _BITPOS_CHILD, _arr)
                    mstore(item_, or(_BITMASK_CHILDREN_INITED, packed_))
                }
            }

            function getString(item_, bitpos_, bitposLength_, bitmaskInited_) -> _result {
                let packed_ := mload(item_)
                _result := getPointer(packed_, bitpos_)
                if iszero(and(bitmaskInited_, packed_)) {
                    let s_ := getPointer(packed_, _BITPOS_STRING)
                    let n := getPointer(packed_, bitposLength_)
                    _result := copyString(s_, _result, n)
                    mstore(item_, or(bitmaskInited_, setPointer(packed_, bitpos_, _result)))
                }
            }

            switch mode
            case 0 {
                result :=
                    getString(input, _BITPOS_VALUE, _BITPOS_VALUE_LENGTH, _BITMASK_VALUE_INITED)
            }
            case 1 {
                // Get key.
                result := 0x60
                if and(mload(input), _BITMASK_PARENT_IS_OBJECT) {
                    result := getString(input, _BITPOS_KEY, _BITPOS_KEY_LENGTH, _BITMASK_KEY_INITED)
                }
            }
            case 3 {
                // Get children.
                result := children(input)
            }
            default {
                let s := input
                let p := add(s, 0x20)
                let e := add(p, mload(s))
                result, p := parseValue(s, 0, p, e)
                if lt(p, e) { fail() }
            }
        }
    }

    function _toInput(string memory input) private returns (bytes32 result) {
        assembly {
            result := input
        }
    }

    function _toInput(Item memory input) private returns (bytes32 result) {
        assembly {
            result := input
        }
    }

    function _isType(Item memory input, uint256 t) private returns (bool result) {
        assembly {
            result := eq(and(mload(input), _BITMASK_TYPE), t)
        }
    }

    function _hasFlagSet(Item memory input, uint256 f) private returns (bool result) {
        assembly {
            result := iszero(iszero(and(mload(input), f)))
        }
    }
}
