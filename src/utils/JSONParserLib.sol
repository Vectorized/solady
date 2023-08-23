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
    uint256 private constant _BITMASK_KEY_IS_INDEX = 1 << 11;
    uint256 private constant _BITPOS_STRING = 32 * 7;
    uint256 private constant _BITPOS_KEY = 32 * 6;
    uint256 private constant _BITPOS_KEY_LENGTH = 32 * 5;
    uint256 private constant _BITPOS_VALUE = 32 * 4;
    uint256 private constant _BITPOS_VALUE_LENGTH = 32 * 3;
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

    function parse(string memory s) internal returns (Item memory result) {
        bytes32 r = _workflow(_toInput(s), 1);
        assembly {
            result := r
        }
    }

    function value(Item memory item) internal returns (string memory result) {
        bytes32 r = _workflow(_toInput(item), 2);
        assembly {
            result := r
        }
    }

    function children(Item memory item) internal returns (Item[] memory result) {
        bytes32 r = _workflow(_toInput(item), 3);
        assembly {
            result := r
        }
    }

    function index(Item memory item) internal returns (uint256 result) {}

    function key(Item memory item) internal returns (string memory result) {}

    function isUndefined(Item memory item) internal returns (bool result) {}

    function isArray(Item memory item) internal returns (bool result) {}

    function isObject(Item memory item) internal returns (bool result) {}

    function isNumber(Item memory item) internal returns (bool result) {}

    function isString(Item memory item) internal returns (bool result) {}

    function isBool(Item memory item) internal returns (bool result) {}

    function isNull(Item memory item) internal returns (bool result) {}

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _workflow(bytes32 input, uint256 mode) private returns (bytes32 result) {
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
                    if iszero(and(shr(chr(_p), 4294977024), 1)) { break }
                }
            }

            function setPointer(packed_, bitpos_, p_) -> _packed {
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
                if and(shr(sub(c_, 45), 8185), 1) {
                    // Number.
                    _item, _p := parseNumber(s_, packed_, _p, e_)
                }
                if eq(c_, 91) {
                    // Array.
                    _item, _p := parseArray(s_, packed_, _p, e_)
                }
                if eq(c_, 123) { // Object.
                }
                if eq(c_, 34) {
                    // String.
                    _item, _p := parseString(s_, packed_, _p, e_)
                }
                if iszero(gt(add(_p, 4), e_)) {
                    let pStart_ := _p
                    let w_ := shr(224, mload(_p))
                    if eq(w_, 0x74727565) {
                        // true.
                        _p := add(_p, 4)
                        _item := mallocItem(s_, packed_, pStart_, _p, _TYPE_BOOL)
                    }
                    if eq(w_, 0x6e756c6c) {
                        // null.
                        _p := add(_p, 4)
                        _item := mallocItem(s_, packed_, pStart_, _p, _TYPE_NULL)
                    }
                }
                if iszero(gt(add(_p, 5), e_)) {
                    let pStart_ := _p
                    let w_ := shr(216, mload(_p))
                    if eq(w_, 0x66616c7365) {
                        // false.
                        _p := add(_p, 5)
                        _item := mallocItem(s_, packed_, pStart_, _p, _TYPE_BOOL)
                    }
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
                        let d_ := or(mload(_item), _BITMASK_KEY_IS_INDEX)
                        mstore(_item, setPointer(d_, _BITPOS_KEY, j_))
                        j_ := add(j_, 1)
                        log2(0, 0, _LOG_UINT256_SELECTOR, j_)
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

            function parseObject(s_, packed_, p_, e_) -> _item, _p {}

            function parseString(s_, packed_, p_, e_) -> _item, _p {
                for { _p := add(p_, 1) } 1 {} {
                    if iszero(lt(_p, e_)) { fail() }
                    let c_ := chr(_p)
                    if eq(c_, 34) { break } // '"'.
                    if iszero(eq(c_, 92)) {
                        // Not '\'.
                        _p := add(_p, 1)
                        continue
                    }
                    c_ := chr(add(_p, 1))
                    if eq(c_, 117) {
                        // 'u'.
                        _p := add(_p, 6)
                        continue
                    }
                    // '"', '\', '//', 'b', 'f', 'n', 'r', 't'.
                    if and(shr(sub(c_, 34), 6120500844678689411047425), 1) {
                        _p := add(_p, 2)
                        continue
                    }
                    _p := e_
                }
                _p := add(_p, 1)
                _item := mallocItem(s_, packed_, p_, _p, _TYPE_STRING)
            }

            function skipDigits(p_, e_, _atLeastOne) -> _p {
                for { _p := p_ } iszero(eq(_p, e_)) { _p := add(_p, 1) } {
                    if iszero(and(shr(sub(chr(_p), 48), 1023), 1)) { break }
                }
                if and(_atLeastOne, eq(_p, p_)) { fail() }
            }

            function parseNumber(s_, packed_, p_, e_) -> _item, _p {
                _p := p_
                if eq(byte(0, mload(_p)), 45) { _p := add(_p, 1) } // '-'.
                if iszero(and(shr(sub(chr(_p), 48), 1023), lt(_p, e_))) { fail() } // Not '0'..'9'.
                let c_ := chr(_p)
                _p := add(_p, 1)
                if iszero(eq(c_, 48)) { _p := skipDigits(_p, e_, 0) } // Not '0'.
                if and(lt(_p, e_), eq(chr(_p), 46)) { _p := skipDigits(add(_p, 1), e_, 1) }
                if and(lt(_p, e_), and(shr(sub(chr(_p), 69), 4294967297), 1)) {
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

            switch mode
            case 1 {
                let s := input
                let p := add(s, 0x20)
                let e := add(p, mload(s))
                result, p := parseValue(s, 0, p, e)
                if lt(p, e) { fail() }
            }
            case 2 {
                let packed := mload(input)
                result := getPointer(packed, _BITPOS_VALUE)
                if iszero(and(_BITMASK_VALUE_INITED, packed)) {
                    let s := getPointer(packed, _BITPOS_STRING)
                    let n := getPointer(packed, _BITPOS_VALUE_LENGTH)
                    result := copyString(s, result, n)
                    packed := setPointer(packed, _BITPOS_VALUE, result)
                    mstore(s, or(_BITMASK_VALUE_INITED, packed))
                }
            }
            case 3 {
                // Get children.
                result := children(input)
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
}
