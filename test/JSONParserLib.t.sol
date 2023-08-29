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
        _checkParseReverts("1,2]");
        _checkParseReverts("[1");
        _checkParseReverts("1]");
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
        _checkParseReverts("{1}");
        _checkParseReverts("{:}");
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
        _checkParseReverts("1 e 1");
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

    function parsedValue(string memory s) public view miniBrutalizeMemory returns (string memory) {
        s = s.parse().value();
        _checkMemory(s);
        return s;
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
        _checkParseNumber("12345e12345678901234567890123456789012345678901234567890");
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
                    assertEq(item.atIndex(i)._data, item.children()[i]._data);
                    assertEq(item.atKey(LibString.toString(i))._data, 0);
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

    function testParseSpecials() public miniBrutalizeMemory {
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

        s = '{"b": "B", "_": "x", "hehe": "HEHE", "_": "y", "v": 12345, "_": "z"}';
        item = s.parse();

        assertEq(item.isObject(), true);
        assertEq(item.size(), 6);

        for (uint256 i; i < item.size(); ++i) {
            assertEq(item.atIndex(i).isUndefined(), true);
            assertEq(item.children()[i].parent()._data, item._data);
        }
        assertEq(item.atKey('"_"').value(), '"z"');
        assertEq(item.atKey('"b"').value(), '"B"');
        assertEq(item.atKey('"v"').value(), "12345");
        assertEq(item.atKey('"hehe"').value(), '"HEHE"');
        assertEq(item.atKey('"m"').value(), "");
        assertEq(item.atKey('"m"').isUndefined(), true);
    }

    function testParseValidObjectDoesNotRevert(string memory key, string memory value) public {
        _limitStringLength(key);
        _limitStringLength(value);
        string memory s = string(
            abi.encodePacked(
                '{"', LibString.escapeJSON(key), '":"', LibString.escapeJSON(value), '"}'
            )
        );
        this.parsedValue(s);
    }

    function testParseRecursiveObject() public miniBrutalizeMemory {
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
        _checkParseString('"012345678901234567890123456789"');
        _checkParseString('"0123456789012345678901234567890"');
        _checkParseString('"01234567890123456789012345678901"');
        _checkParseString('"012345678901234567890123456789012"');
        _checkParseString('"0123456789012345678901234567890123"');
        _checkParseString('"  d"');
        _checkParseString('"d  "');
        _checkParseString('"  d  "');
        _checkParseString('"\\""');
        _checkParseString('"\\\\"');
        _checkParseString('"\\/"');
        _checkParseString('"\\b"');
        _checkParseString('"\\f"');
        _checkParseString('"\\n"');
        _checkParseString('"\\r"');
        _checkParseString('"\\t"');
        _checkParseString('"  \\u1234 \\"\\"\\\\ \\b\\f \\n\\r "');
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
            assertEq(item.value(), s);
            _checkItemIsSolo(item);
        }
    }

    function testParseInvalidStringReverts() public {
        _checkParseReverts('"');
        _checkParseReverts('"""');
        _checkParseReverts('""""');
        _checkParseReverts('"""""');
        _checkParseReverts('"abc" "');
        _checkParseReverts('"abc" ""');
        _checkParseReverts('"abc""abc"');
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

    function testParseGas() public {
        string memory s =
            '{"animation_url":"","artist":"Daniel Allan","artwork":{"mimeType":"image/gif","uri":"ar://J5NZ-e2NUcQj1OuuhpTjAKtdW_nqwnwo5FypF_a6dE4","nft":null},"attributes":[{"trait_type":"Criteria","value":"Song Edition"}],"bpm":null,"credits":null,"description":"Criteria is an 8-track project between Daniel Allan and Reo Cragun.\n\nA fusion of electronic music and hip-hop - Criteria brings together the best of both worlds and is meant to bring web3 music to a wider audience.\n\nThe collection consists of 2500 editions with activations across Sound, Bonfire, OnCyber, Spinamp and Arpeggi.","duration":105,"external_url":"https://www.sound.xyz/danielallan/criteria","genre":"Pop","image":"ar://J5NZ-e2NUcQj1OuuhpTjAKtdW_nqwnwo5FypF_a6dE4","isrc":null,"key":null,"license":null,"locationCreated":null,"losslessAudio":"","lyrics":null,"mimeType":"audio/wave","nftSerialNumber":11,"name":"Criteria #11","originalReleaseDate":null,"project":null,"publisher":null,"recordLabel":null,"tags":null,"title":"Criteria","trackNumber":1,"version":"sound-edition-20220930","visualizer":null}';
        assertEq(s.parse().isObject(), true);
    }

    function testParseUint() public {
        assertEq(this.parseUint("0"), 0);
        assertEq(this.parseUint("1"), 1);
        assertEq(this.parseUint("123"), 123);
        assertEq(this.parseUint("0123"), 123);
        assertEq(this.parseUint("000123"), 123);
        assertEq(this.parseUint("12345678901234567890"), 12345678901234567890);
        string memory s;
        s = "115792089237316195423570985008687907853269984665640564039457584007913129639935";
        assertEq(this.parseUint(s), type(uint256).max);
    }

    function testParseInvalidUintReverts() public {
        _checkParseInvalidUintReverts("");
        _checkParseInvalidUintReverts("-");
        _checkParseInvalidUintReverts("a");
        _checkParseInvalidUintReverts(" ");
        _checkParseInvalidUintReverts(" 123 ");
        _checkParseInvalidUintReverts("123:");
        _checkParseInvalidUintReverts(":");
        string memory s;
        s = "115792089237316195423570985008687907853269984665640564039457584007913129639936";
        _checkParseInvalidUintReverts(s);
        s = "115792089237316195423570985008687907853269984665640564039457584007913129639937";
        _checkParseInvalidUintReverts(s);
        s = "115792089237316195423570985008687907853269984665640564039457584007913129639999";
        _checkParseInvalidUintReverts(s);
        s = "115792089237316195423570985008687907853269984665640564039457584007913129640001";
        _checkParseInvalidUintReverts(s);
        s = "115792089237316195423570985008687907853269984665640564039457584007913129640035";
        _checkParseInvalidUintReverts(s);
        s = "215792089237316195423570985008687907853269984665640564039457584007913129639935";
        _checkParseInvalidUintReverts(s);
        s = "222222222222222222222222222222222222222222222222222222222222222222222222222222";
        _checkParseInvalidUintReverts(s);
        s = "1215792089237316195423570985008687907853269984665640564039457584007913129639935";
        _checkParseInvalidUintReverts(s);
    }

    function _checkParseInvalidUintReverts(string memory s) internal {
        vm.expectRevert(JSONParserLib.ParsingFailed.selector);
        this.parseUint(s);
    }

    function parseUint(string memory s) public view miniBrutalizeMemory returns (uint256) {
        return s.parseUint();
    }

    function testParseInt() public {
        _checkParseInt("0", 0);
        _checkParseInt("1", 1);
        _checkParseInt("+1", 1);
        _checkParseInt("+01", 1);
        _checkParseInt("+001", 1);
        _checkParseInt("+0", 0);
        _checkParseInt("+1", 1);
        _checkParseInt("+12", 12);
        _checkParseInt("-12", -12);
        string memory s;
        s = "-57896044618658097711785492504343953926634992332820282019728792003956564819967";
        _checkParseInt(s, -type(int256).max);
        s = "+57896044618658097711785492504343953926634992332820282019728792003956564819967";
        _checkParseInt(s, type(int256).max);
        s = "57896044618658097711785492504343953926634992332820282019728792003956564819967";
        _checkParseInt(s, type(int256).max);
    }

    function testParseInvalidIntReverts() public {
        _checkParseInvalidIntReverts("");
        _checkParseInvalidIntReverts("-");
        _checkParseInvalidIntReverts("+");
        _checkParseInvalidIntReverts("--");
        _checkParseInvalidIntReverts("++");
        _checkParseInvalidIntReverts("a");
        _checkParseInvalidIntReverts(" ");
        _checkParseInvalidIntReverts(" 123 ");
        _checkParseInvalidIntReverts("123:");
        _checkParseInvalidIntReverts(":");
        _checkParseInvalidIntReverts(":123");
        string memory s;
        s = "-57896044618658097711785492504343953926634992332820282019728792003956564819968";
        _checkParseInvalidIntReverts(s);
        s = "+57896044618658097711785492504343953926634992332820282019728792003956564819968";
        _checkParseInvalidIntReverts(s);
    }

    function _checkParseInt(string memory s, int256 x) internal {
        bytes32 hashBefore = keccak256(bytes(s));
        assertEq(this.parseInt(s), x);
        assertEq(keccak256(bytes(s)), hashBefore);
    }

    function _checkParseInvalidIntReverts(string memory s) internal {
        vm.expectRevert(JSONParserLib.ParsingFailed.selector);
        this.parseInt(s);
    }

    function parseInt(string memory s) public view miniBrutalizeMemory returns (int256) {
        return s.parseInt();
    }

    function testDecodeString() public {
        assertEq(this.decodeString('""'), "");
        assertEq(this.decodeString('"abc"'), "abc");
        assertEq(this.decodeString('" abc  "'), " abc  ");
        assertEq(this.decodeString('"\\""'), '"');
        assertEq(this.decodeString('"\\/"'), "/");
        assertEq(this.decodeString('"\\\\"'), "\\");
        assertEq(this.decodeString('"\\b"'), hex"08");
        assertEq(this.decodeString('"\\f"'), hex"0c");
        assertEq(this.decodeString('"\\n"'), "\n");
        assertEq(this.decodeString('"\\r"'), "\r");
        assertEq(this.decodeString('"\\t"'), "\t");
        assertEq(this.decodeString('"\\u0020"'), " ");
        bytes32 expectedHash;
        expectedHash = 0x40b2b6558413427ef2da03b1452640d701458e0ce57114db6b7423ae3b5fe857;
        assertEq(keccak256(bytes(this.decodeString('"\\u039e"'))), expectedHash); // Greek uppercase Xi.
        expectedHash = 0xecab436111d5a82d983bd4630c03c83f424d2a2dd8465c31fd950b9ec8d005fb;
        assertEq(keccak256(bytes(this.decodeString('"\\u2661"'))), expectedHash); // Heart.
        expectedHash = 0x367c272ea502ac6e9f085c1baddc52d0ac0224f1b7d1e8621202620efa3ba084;
        assertEq(keccak256(bytes(this.decodeString('"\\uD83D\\ude00"'))), expectedHash); // Smiley emoji.
    }

    function testDecodeEncodedStringDoesNotRevert(string memory s) public {
        _limitStringLength(s);
        s = string(abi.encodePacked('"', LibString.escapeJSON(s), '"'));
        this.decodeString(s);
        assertEq(this.parsedValue(s), s);
    }

    function _limitStringLength(string memory s) internal {
        uint256 r = _random();
        /// @solidity memory-safe-assembly
        assembly {
            let limit := 16
            if eq(1, and(r, 3)) { limit := 80 }
            let n := mload(s)
            if gt(n, limit) { mstore(s, limit) }
        }
    }

    function testDecodeInvalidStringReverts() public {
        _checkDecodeInvalidStringReverts("");
        _checkDecodeInvalidStringReverts('"');
        _checkDecodeInvalidStringReverts(' "" ');
        _checkDecodeInvalidStringReverts(' ""');
        _checkDecodeInvalidStringReverts('"" ');
        _checkDecodeInvalidStringReverts('"\\z"');
        _checkDecodeInvalidStringReverts('"\\u"');
        _checkDecodeInvalidStringReverts('"\\u1"');
        _checkDecodeInvalidStringReverts('"\\u111"');
        _checkDecodeInvalidStringReverts('"\\uxxxx"');
        _checkDecodeInvalidStringReverts('"\\uD83D"'); // Only half of a Smiley emoji.
    }

    function _checkDecodeInvalidStringReverts(string memory s) internal {
        vm.expectRevert(JSONParserLib.ParsingFailed.selector);
        this.decodeString(s);
    }

    function decodeString(string memory s)
        public
        view
        miniBrutalizeMemory
        returns (string memory)
    {
        return JSONParserLib.decodeString(s);
    }

    function testParseUint(uint256 x) public {
        string memory s = LibString.toString(x);
        assertEq(this.parsedValue(s), s);
        assertEq(this.parseUint(s), x);
    }

    modifier miniBrutalizeMemory() {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, gas())
            mstore(0x00, keccak256(0x00, 0x20))
            mstore(0x20, not(mload(0x00)))
            codecopy(mload(0x40), 0, codesize())
        }
        _;
    }
}
