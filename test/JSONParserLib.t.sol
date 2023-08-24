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
        _checkParseReverts("{\"a\"}");
        _checkParseReverts("{\"a\":\"A\",}");
        _checkParseReverts("{\"a\":\"A\",\"b\":\"B\",}");
        _checkParseReverts("{\"a\":\"A\"\"b\":\"B\"}");
        _checkParseReverts("{\"a\":\"A\",,\"b\":\"B\"}");
        _checkParseReverts("{,\"a\":\"A\",\"b\":\"B\"}");
        _checkParseReverts("{\"a\"::\"A\"}");
        _checkParseReverts("{\"a\",\"A\"}");
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

    function _checkParseReverts(string memory striped) internal {
        vm.expectRevert(JSONParserLib.ParsingFailed.selector);
        this.parsedValue(striped);
        string memory s = striped;
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

    function _checkParseNumber(string memory striped) internal {
        _checkSoloNumber(striped.parse(), striped);
        string memory s = striped;
        for (uint256 i; i != 4; ++i) {
            _checkSoloNumber(_padWhiteSpace(s, i).parse(), striped);
        }
    }

    function _checkSoloNumber(JSONParserLib.Item memory item, string memory striped) internal {
        for (uint256 i; i != 2; ++i) {
            assertEq(item.getType(), JSONParserLib.TYPE_NUMBER);
            assertEq(item.isNumber(), true);
            assertEq(item.value(), striped);
            _checkItemIsSolo(item);
        }
    }

    function testParseEmptyArrays() public {
        _checkParseEmptyArray("[]");
        _checkParseEmptyArray("[ ]");
        _checkParseEmptyArray("[  ]");
    }

    function _checkParseEmptyArray(string memory striped) internal {
        _checkSoloEmptyArray(striped.parse(), striped);
        string memory s = striped;
        for (uint256 i; i != 16; ++i) {
            _checkSoloEmptyArray(_padWhiteSpace(s, i).parse(), striped);
        }
    }

    function _checkSoloEmptyArray(JSONParserLib.Item memory item, string memory striped) internal {
        for (uint256 i; i != 2; ++i) {
            assertEq(item.getType(), JSONParserLib.TYPE_ARRAY);
            assertEq(item.isArray(), true);
            assertEq(item.value(), striped);
            _checkItemIsSolo(item);
        }
    }

    function testParseEmptyObjects() public {
        _checkParseEmptyObject("{}");
        _checkParseEmptyObject("{ }");
        _checkParseEmptyObject("{  }");
    }

    function _checkParseEmptyObject(string memory striped) internal {
        _checkSoloEmptyObject(striped.parse(), striped);
        string memory s = striped;
        for (uint256 i; i != 16; ++i) {
            _checkSoloEmptyObject(_padWhiteSpace(s, i).parse(), striped);
        }
    }

    function _checkSoloEmptyObject(JSONParserLib.Item memory item, string memory striped)
        internal
    {
        for (uint256 i; i != 2; ++i) {
            assertEq(item.getType(), JSONParserLib.TYPE_OBJECT);
            assertEq(item.isObject(), true);
            assertEq(item.value(), striped);
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
                assertEq(item.children().length, j);
                for (uint256 i; i != j; ++i) {
                    string memory x = LibString.toString(o + i);
                    assertEq(item.children()[i].value(), x);
                    assertEq(item.children()[i].parent()._data, item._data);
                    assertEq(item.children()[i].parentIsArray(), true);
                }
            }
        }
    }

    function testParseSimpleArray() public {
        string memory s = "[\"hehe\",12,\"haha\"]";
        JSONParserLib.Item memory item = s.parse();

        assertEq(item.isArray(), true);
        assertEq(item.children().length, 3);
        _checkItemHasNoParent(item);

        assertEq(item.children()[0].value(), "\"hehe\"");
        assertEq(item.children()[0].index(), 0);
        assertEq(item.children()[0].getType(), JSONParserLib.TYPE_STRING);
        assertEq(item.children()[0].key(), "");
        assertEq(item.children()[0].parent()._data, item._data);
        assertEq(item.children()[0].parentIsArray(), true);

        assertEq(item.children()[1].value(), "12");
        assertEq(item.children()[1].index(), 1);
        assertEq(item.children()[1].key(), "");
        assertEq(item.children()[1].getType(), JSONParserLib.TYPE_NUMBER);
        assertEq(item.children()[1].parent()._data, item._data);
        assertEq(item.children()[1].parentIsArray(), true);

        assertEq(item.children()[2].value(), "\"haha\"");
        assertEq(item.children()[2].index(), 2);
        assertEq(item.children()[2].getType(), JSONParserLib.TYPE_STRING);
        assertEq(item.children()[2].key(), "");
        assertEq(item.children()[2].parent()._data, item._data);
        assertEq(item.children()[2].parentIsArray(), true);
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
            if (k == 2) s = "{\"A\":true,\"B\":false,\"C\":null}";
            if (k == 3) s = "{ \"A\" : true , \"B\" : false , \"C\" : null }";
            item = s.parse();
            assertEq(item.children()[0].getType(), JSONParserLib.TYPE_BOOLEAN);
            assertEq(item.children()[0].value(), "true");
            assertEq(item.children()[1].getType(), JSONParserLib.TYPE_BOOLEAN);
            assertEq(item.children()[1].value(), "false");
            assertEq(item.children()[2].getType(), JSONParserLib.TYPE_NULL);
            assertEq(item.children()[2].value(), "null");
        }
    }

    function _checkItemIsSolo(JSONParserLib.Item memory item) internal {
        _checkItemHasNoParent(item);
        assertEq(item.children().length, 0);
    }

    function _checkItemHasNoParent(JSONParserLib.Item memory item) internal {
        assertEq(item.parent().isUndefined(), true);
        assertEq(item.parent()._data, 0);
        assertEq(item.key(), "");
        assertEq(item.index(), 0);
        assertEq(item.parentIsObject(), false);
        assertEq(item.parentIsArray(), false);
        assertEq(item.isUndefined(), false);
    }
}
