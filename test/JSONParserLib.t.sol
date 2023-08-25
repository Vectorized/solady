// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {JSONParserLib} from "../src/utils/JSONParserLib.sol";
import {LibString} from "../src/utils/LibString.sol";

contract JSONParserLibTest is SoladyTest {
    using JSONParserLib for *;

    function testParseInvalidReverts() public {
        _checkParseReverts("");
        _checkParseReverts("e");
        _checkParseReverts("abc");
        _checkParseReverts("1,2");
        _checkParseReverts("[");
        _checkParseReverts("]");
        _checkParseReverts("{");
        _checkParseReverts("}");
        _checkParseReverts("[[]");
        _checkParseReverts("[][");
        _checkParseReverts("[][]");
        _checkParseReverts("[],[]");
        _checkParseReverts("[1,2");
        _checkParseReverts("[1");
        _checkParseReverts("[1,");
        _checkParseReverts("{}{");
        _checkParseReverts("{}{}");
        _checkParseReverts("{},{}");
        _checkParseReverts("{]");
        _checkParseReverts("{{}");
        _checkParseReverts("{}}");
        _checkParseReverts("[,]");
        _checkParseReverts("[0,]");
        _checkParseReverts("[0,1,]");
        _checkParseReverts("[0,,]");
        _checkParseReverts("[0,,1]");
        _checkParseReverts("[,0]");
        _checkParseReverts("{,}");
        _checkParseReverts('{"a"}');
        _checkParseReverts('{"a":"A",}');
        _checkParseReverts('{"a":"A","b":"B",}');
        _checkParseReverts('{"a":"A"b":"B"}');
        _checkParseReverts('{"a":"A",,"b":"B"}');
        _checkParseReverts('{,"a":"A","b":"B"}');
        _checkParseReverts('{"a"::"A"}');
        _checkParseReverts('{"a","A"}');
    }

    function testParseInvalidNumberReverts() public {
        _checkParseReverts("01234567890");
        _checkParseReverts("-1.234567890e-a");
        _checkParseReverts("-1.234567890e-");
        _checkParseReverts("-1.234567890e+a");
        _checkParseReverts("-1.234567890e+");
        _checkParseReverts("-1.234567890z");
        _checkParseReverts("-1.234567890e");
        _checkParseReverts("-00.234567890");
        _checkParseReverts("-.234567890");
        _checkParseReverts("-00");
        _checkParseReverts("--0");
        _checkParseReverts("00");
        _checkParseReverts("0.");
        _checkParseReverts("0..12");
        _checkParseReverts("0.0e");
        _checkParseReverts(".");
        _checkParseReverts("-");
        _checkParseReverts("+");
        _checkParseReverts("e");
        _checkParseReverts("+123");
        _checkParseReverts(".123");
        _checkParseReverts("e123");
        _checkParseReverts("-1.e+0");
        _checkParseReverts("0x");
    }

    function _checkParseReverts(string memory trimmed) internal {
        vm.expectRevert(JSONParserLib.ParsingFailed.selector);
        this.parsedValue(trimmed);
        string memory s = trimmed;
        for (uint256 i; i != 4; ++i) {
            vm.expectRevert(JSONParserLib.ParsingFailed.selector);
            this.parsedValue(_padWhiteSpace(s, i));
        }
    }

    function parsedValue(string memory s) public pure returns (string memory) {
        return s.parse().value();
    }

    function testParseNumber() public {
        _checkParseNumber("0");
        _checkParseNumber("-0");
        _checkParseNumber("-1.2e+0");
        _checkParseNumber("-1.2e+00");
        _checkParseNumber("-1.2e+001");
        _checkParseNumber("-1.2e+22");
        _checkParseNumber("-1.2e-22");
        _checkParseNumber("-1.2e22");
        _checkParseNumber("0.1");
        _checkParseNumber("0.123");
        _checkParseNumber("12345678901234567890123456789012345678901234567890");
        _checkParseNumber("1234567890");
        _checkParseNumber("123");
        _checkParseNumber("1");
    }

    function _checkParseNumber(string memory trimmed) internal {
        _checkSoloNumber(trimmed.parse(), trimmed);
        string memory s = trimmed;
        for (uint256 i; i != 4; ++i) {
            _checkSoloNumber(_padWhiteSpace(s, i).parse(), trimmed);
        }
    }

    function _checkSoloNumber(JSONParserLib.Item memory item, string memory trimmed) internal {
        for (uint256 i; i != 2; ++i) {
            assertEq(item.getType(), JSONParserLib.TYPE_NUMBER);
            assertEq(item.isNumber(), true);
            assertEq(item.value(), trimmed);
            _checkItemIsSolo(item);
        }
    }

    function testParseEmptyArrays() public {
        _checkParseEmptyArray("[]");
        _checkParseEmptyArray("[ ]");
        _checkParseEmptyArray("[  ]");
    }

    function _checkParseEmptyArray(string memory trimmed) internal {
        _checkSoloEmptyArray(trimmed.parse(), trimmed);
        string memory s = trimmed;
        for (uint256 i; i != 16; ++i) {
            _checkSoloEmptyArray(_padWhiteSpace(s, i).parse(), trimmed);
        }
    }

    function _checkSoloEmptyArray(JSONParserLib.Item memory item, string memory trimmed) internal {
        for (uint256 i; i != 2; ++i) {
            assertEq(item.getType(), JSONParserLib.TYPE_ARRAY);
            assertEq(item.isArray(), true);
            assertEq(item.value(), trimmed);
            _checkItemIsSolo(item);
        }
    }

    function testParseEmptyObjects() public {
        _checkParseEmptyObject("{}");
        _checkParseEmptyObject("{ }");
        _checkParseEmptyObject("{  }");
    }

    function _checkParseEmptyObject(string memory trimmed) internal {
        _checkSoloEmptyObject(trimmed.parse(), trimmed);
        string memory s = trimmed;
        for (uint256 i; i != 16; ++i) {
            _checkSoloEmptyObject(_padWhiteSpace(s, i).parse(), trimmed);
        }
    }

    function _checkSoloEmptyObject(JSONParserLib.Item memory item, string memory trimmed)
        internal
    {
        for (uint256 i; i != 2; ++i) {
            assertEq(item.getType(), JSONParserLib.TYPE_OBJECT);
            assertEq(item.isObject(), true);
            assertEq(item.value(), trimmed);
            _checkItemIsSolo(item);
        }
    }

    function _padWhiteSpace(string memory s, uint256 r) internal pure returns (string memory) {
        unchecked {
            uint256 q = r;
            r = r % 3;
            string memory p = r == 0 ? " " : r == 1 ? "\t" : r == 2 ? "\r" : "\n";
            q = 1 + q / 3;
            for (uint256 i; i != q; ++i) {
                s = string(abi.encodePacked(p, s, p));
            }
            return s;
        }
    }

    function testParseSimpleUintArray() public {
        string memory s;
        JSONParserLib.Item memory item;

        for (uint256 k; k != 9; ++k) {
            uint256 o = k == 0 ? 0 : 1 << (17 * k);
            string memory p = _padWhiteSpace("", k);
            for (uint256 j; j != 5; ++j) {
                s = "[";
                for (uint256 i; i != j; ++i) {
                    string memory x = LibString.toString(o + i);
                    if (i == 0) {
                        s = string(abi.encodePacked(s, p, x));
                    } else {
                        s = string(abi.encodePacked(s, p, ",", p, x));
                    }
                }
                s = string(abi.encodePacked(s, "]"));
                item = s.parse();
                assertEq(item.isArray(), true);
                assertEq(item.size(), j);
                for (uint256 i; i != j; ++i) {
                    string memory x = LibString.toString(o + i);
                    assertEq(item.children()[i].value(), x);
                    assertEq(item.children()[i].parent()._data, item._data);
                    assertEq(item.children()[i].parent().isArray(), true);
                    assertEq(item.at(i)._data, item.children()[i]._data);
                    assertEq(item.at(LibString.toString(i)).isUndefined(), true);
                }
            }
        }
    }

    function testParseSimpleArray() public {
        string memory s = '["hehe",12,"haha"]';
        JSONParserLib.Item memory item = s.parse();

        assertEq(item.isArray(), true);
        assertEq(item.size(), 3);
        _checkItemHasNoParent(item);

        assertEq(item.children()[0].value(), '"hehe"');
        assertEq(item.children()[0].index(), 0);
        assertEq(item.children()[0].getType(), JSONParserLib.TYPE_STRING);
        assertEq(item.children()[0].key(), "");
        assertEq(item.children()[0].parent()._data, item._data);
        assertEq(item.children()[0].parent().isArray(), true);

        assertEq(item.children()[1].value(), "12");
        assertEq(item.children()[1].index(), 1);
        assertEq(item.children()[1].key(), "");
        assertEq(item.children()[1].getType(), JSONParserLib.TYPE_NUMBER);
        assertEq(item.children()[1].parent()._data, item._data);
        assertEq(item.children()[1].parent().isArray(), true);

        assertEq(item.children()[2].value(), '"haha"');
        assertEq(item.children()[2].index(), 2);
        assertEq(item.children()[2].getType(), JSONParserLib.TYPE_STRING);
        assertEq(item.children()[2].key(), "");
        assertEq(item.children()[2].parent()._data, item._data);
        assertEq(item.children()[2].parent().isArray(), true);
    }

    function testParseSpecials() public {
        string memory s;
        JSONParserLib.Item memory item;

        for (uint256 k; k < 9; ++k) {
            s = _padWhiteSpace("true", k);
            item = s.parse();
            assertEq(item.getType(), JSONParserLib.TYPE_BOOLEAN);
            assertEq(item.isBoolean(), true);
            assertEq(item.isNull(), false);
            assertEq(item.value(), "true");
            assertEq(item.parent().isUndefined(), true);
            _checkItemIsSolo(item);

            s = _padWhiteSpace("false", k);
            item = s.parse();
            assertEq(item.getType(), JSONParserLib.TYPE_BOOLEAN);
            assertEq(item.isBoolean(), true);
            assertEq(item.isNull(), false);
            assertEq(item.value(), "false");
            _checkItemIsSolo(item);

            s = _padWhiteSpace("null", k);
            item = s.parse();
            assertEq(item.getType(), JSONParserLib.TYPE_NULL);
            assertEq(item.isBoolean(), false);
            assertEq(item.isNull(), true);
            assertEq(item.value(), "null");
            _checkItemIsSolo(item);
        }

        for (uint256 k; k != 4; ++k) {
            if (k == 0) s = "[true,false,null]";
            if (k == 1) s = "[ true , false , null ]";
            if (k == 2) s = '{"A":true,"B":false,"C":null}';
            if (k == 3) s = '{ "A" : true , "B" : false , "C" : null }';
            item = s.parse();
            assertEq(item.size(), 3);
            assertEq(item.children()[0].getType(), JSONParserLib.TYPE_BOOLEAN);
            assertEq(item.children()[0].value(), "true");
            assertEq(item.children()[1].getType(), JSONParserLib.TYPE_BOOLEAN);
            assertEq(item.children()[1].value(), "false");
            assertEq(item.children()[2].getType(), JSONParserLib.TYPE_NULL);
            assertEq(item.children()[2].value(), "null");
            if (k == 0 || k == 1) {
                for (uint256 i; i != 3; ++i) {
                    assertEq(item.children()[i].parent()._data, item._data);
                    assertEq(item.children()[i].parent().isArray(), true);
                    assertEq(item.children()[i].parent().isArray(), true);
                    assertEq(item.children()[i].index(), i);
                    assertEq(item.children()[i].key(), "");
                }
            }
            if (k == 2 || k == 3) {
                for (uint256 i; i != 3; ++i) {
                    assertEq(item.children()[i].parent()._data, item._data);
                    assertEq(item.children()[i].parent().isObject(), true);
                    assertEq(item.children()[i].index(), 0);
                }
                assertEq(item.children()[0].key(), '"A"');
                assertEq(item.children()[1].key(), '"B"');
                assertEq(item.children()[2].key(), '"C"');
            }
        }
    }

    function testParseObject() public {
        string memory s;
        JSONParserLib.Item memory item;

        s = '{"b": "B", "_": "x", "hehe": "HEHE", "_": "y", "_": "z"}';
        item = s.parse();

        assertEq(item.size(), 5);
        assertEq(item.at('"_"').value(), '"z"');
        assertEq(item.at('"b"').value(), '"B"');
        assertEq(item.at('"hehe"').value(), '"HEHE"');
        assertEq(item.at('"m"').value(), "");
        assertEq(item.at('"m"').isUndefined(), true);
    }

    function testParseRecursiveObject() public {
        string memory s;
        JSONParserLib.Item memory item;

        s = '{ "": [1,2, {"m": "M"}, {},[]], "X": {"hehe": "1", "h": [true,false, null], "": 0} }';
        item = s.parse();

        assertEq(item.isObject(), true);
        assertEq(item.children()[0].key(), '""');
        assertEq(item.children()[0].index(), 0);
        assertEq(item.children()[0].children()[0].value(), "1");
        assertEq(item.children()[0].children()[1].value(), "2");
        assertEq(item.children()[0].children()[2].value(), '{"m": "M"}');
        assertEq(item.children()[0].children()[2].children()[0].key(), '"m"');
        assertEq(item.children()[0].children()[2].children()[0].value(), '"M"');

        JSONParserLib.Item memory c = item.children()[0].children()[2].children()[0];
        assertEq(c.parent().parent().parent()._data, item._data);
        assertEq(c.parent().parent().parent().value(), item.value());
        assertEq(c.parent().parent().parent().parent().isUndefined(), true);

        assertEq(item.children()[1].key(), '"X"');
        assertEq(item.children()[1].index(), 0);
        assertEq(item.children()[1].value(), '{"hehe": "1", "h": [true,false, null], "": 0}');
        assertEq(item.children()[1].children()[0].key(), '"hehe"');
        assertEq(item.children()[1].children()[0].value(), '"1"');

        assertEq(item.children()[1].children()[1].key(), '"h"');
        assertEq(item.children()[1].children()[1].value(), "[true,false, null]");
        assertEq(item.children()[1].children()[1].children()[0].value(), "true");
        assertEq(item.children()[1].children()[1].children()[0].isBoolean(), true);
        assertEq(item.children()[1].children()[1].children()[1].value(), "false");
        assertEq(item.children()[1].children()[1].children()[1].isBoolean(), true);
        assertEq(item.children()[1].children()[1].children()[2].value(), "null");
        assertEq(item.children()[1].children()[1].children()[2].isNull(), true);

        assertEq(item.children()[1].children()[2].key(), '""');
        assertEq(item.children()[1].children()[2].value(), "0");
        assertEq(item.children()[1].children()[2].size(), 0);

        s = "[[[[[[[]]]]]]]";
        item = s.parse();
        assertEq(item.isArray(), true);

        s = '{"a":[[[{"z":"Z"}]]]}';
        item = s.parse();
        assertEq(item.isObject(), true);
    }

    function testParseString() public {
        _checkParseString('""');
        _checkParseString('"a"');
        _checkParseString('"ab"');
        _checkParseString('"\\""');
        _checkParseString('"\\\\"');
        _checkParseString('"\\/"');
        _checkParseString('"\\b"');
        _checkParseString('"\\f"');
        _checkParseString('"\\n"');
        _checkParseString('"\\r"');
        _checkParseString('"\\t"');
        _checkParseString('"\\u1234"');
        _checkParseString('"\\uabcd"');
        _checkParseString('"\\uABCD"');
        _checkParseString('"\\uef00"');
        _checkParseString('"\\u00EF"');
        _checkParseString('"\\u1234 "');
        _checkParseString('"\\uabcd "');
        _checkParseString('"\\uABCD "');
        _checkParseString('"\\uef00 "');
        _checkParseString('"\\u00EF "');
    }

    function _checkParseString(string memory s) internal {
        JSONParserLib.Item memory item;
        assertEq(this.parsedValue(s), s);
        for (uint256 k; k != 4; ++k) {
            item = _padWhiteSpace(s, k).parse();
            assertEq(item.value(), s);
            assertEq(item.isString(), true);
            _checkItemIsSolo(item);
        }
    }

    function testParseInvalidStringReverts() public {
        _checkParseReverts('"');
        _checkParseReverts('"""');
        _checkParseReverts('"\\"');
        _checkParseReverts('"\\\\\\"');
        _checkParseReverts('"\\u"');
        _checkParseReverts('"\\u1"');
        _checkParseReverts('"\\u12"');
        _checkParseReverts('"\\u123"');
        _checkParseReverts('"\\uxxxx"');
        _checkParseReverts('"\\u012g"');
        _checkParseReverts('"\\u1234');
    }

    function _checkItemIsSolo(JSONParserLib.Item memory item) internal {
        _checkItemHasNoParent(item);
        assertEq(item.size(), 0);
    }

    function _checkItemHasNoParent(JSONParserLib.Item memory item) internal {
        assertEq(item.parent().isUndefined(), true);
        assertEq(item.parent()._data, 0);
        assertEq(item.key(), "");
        assertEq(item.index(), 0);
        assertEq(item.parent().isObject(), false);
        assertEq(item.parent().isArray(), false);
        assertEq(item.isUndefined(), false);
    }
}
