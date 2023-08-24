// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {JSONParserLib} from "../src/utils/JSONParserLib.sol";

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
        for (uint256 i; i != 2; ++i) {
            s = string(abi.encodePacked(" ", s));
            vm.expectRevert(JSONParserLib.ParsingFailed.selector);
            this.parsedValue(s);
            s = string(abi.encodePacked(s, " "));
            vm.expectRevert(JSONParserLib.ParsingFailed.selector);
            this.parsedValue(s);
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
        _checkNumberWithoutParent(striped.parse(), striped);
        string memory s = striped;
        for (uint256 i; i != 4; ++i) {
            _checkNumberWithoutParent(_padWhiteSpace(s, i).parse(), striped);
        }
    }

    function _checkNumberWithoutParent(JSONParserLib.Item memory item, string memory striped)
        internal
    {
        for (uint256 i; i != 2; ++i) {
            assertEq(item.getType(), JSONParserLib.TYPE_NUMBER);
            assertEq(item.isNumber(), true);
            assertEq(item.key(), "");
            assertEq(item.index(), 0);
            assertEq(item.value(), striped);
            assertEq(item.isUndefined(), false);
            assertEq(item.parent().isUndefined(), true);
            assertEq(item.parentIsArray(), false);
            assertEq(item.parentIsObject(), false);
            assertEq(item.children().length, 0);
        }
    }

    function testParseEmptyArrays() public {
        _checkParseEmptyArray("[]");
        _checkParseEmptyArray("[ ]");
        _checkParseEmptyArray("[  ]");
    }

    function _checkParseEmptyArray(string memory striped) internal {
        _checkEmptyArrayWithoutParent(striped.parse(), striped);
        string memory s = striped;
        for (uint256 i; i != 16; ++i) {
            _checkEmptyArrayWithoutParent(_padWhiteSpace(s, i).parse(), striped);
        }
    }

    function _checkEmptyArrayWithoutParent(JSONParserLib.Item memory item, string memory striped)
        internal
    {
        for (uint256 i; i != 2; ++i) {
            assertEq(item.getType(), JSONParserLib.TYPE_ARRAY);
            assertEq(item.isArray(), true);
            assertEq(item.key(), "");
            assertEq(item.index(), 0);
            assertEq(item.value(), striped);
            assertEq(item.isUndefined(), false);
            assertEq(item.parent().isUndefined(), true);
            assertEq(item.parentIsArray(), false);
            assertEq(item.parentIsObject(), false);
            assertEq(item.children().length, 0);
        }
    }

    function testParseEmptyObjects() public {
        _checkParseEmptyObject("{}");
        _checkParseEmptyObject("{ }");
        _checkParseEmptyObject("{  }");
    }

    function _checkParseEmptyObject(string memory striped) internal {
        _checkEmptyObjectWithoutParent(striped.parse(), striped);
        string memory s = striped;
        for (uint256 i; i != 16; ++i) {
            _checkEmptyObjectWithoutParent(_padWhiteSpace(s, i).parse(), striped);
        }
    }

    function _checkEmptyObjectWithoutParent(JSONParserLib.Item memory item, string memory striped)
        internal
    {
        for (uint256 i; i != 2; ++i) {
            assertEq(item.getType(), JSONParserLib.TYPE_OBJECT);
            assertEq(item.isObject(), true);
            assertEq(item.key(), "");
            assertEq(item.index(), 0);
            assertEq(item.value(), striped);
            assertEq(item.isUndefined(), false);
            assertEq(item.parent().isUndefined(), true);
            assertEq(item.parentIsArray(), false);
            assertEq(item.parentIsObject(), false);
            assertEq(item.children().length, 0);
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

    function testParseSimpleArrays() public {}

    function testParseNumber2() public {
        // JSONParserLib.Item memory item;
        // JSONParserLib.Item[] memory children;
        // assertEq(item.value(), "");
        // assertTrue(item.isUndefined());
        // // console.log(".parse() true  ").value());
        // // console.log(".parse() true").value());
        // // console.log(".parse() false  ").value());
        // // console.log(".parse() false").value());
        // // console.log(".parse() null  ").value());
        // // console.log(".parse() null").value());

        // // item = '[.parse(),2,[3,4],[5,6],7,"hehe", true]');
        // // children = item.children();
        // // for (uint256 i; i < children.length; ++i) {
        // //     console.log(children[i].index());
        // //     // console.log(children[i].value());
        // // }

        // // item = '{".parse()":"A","b"  :  "B"}');
        // // children = item.children();
        // // for (uint256 i; i < children.length; ++i) {
        // //     console.log(children[i].key());
        // //     console.log(children[i].value());
        // // }

        // // console.log(".parse() 01234567890  ").value());
        // console.log(".parse() -1.234567890e+22  ").value());
        // console.log(".parse() -1.234567890e-22  ").value());
        // console.log(".parse() -1.234567890e22  ").value());
        // console.log(".parse() 1234567890  ").value());
        // console.log(".parse() 123  ").value());
        // console.log(".parse() 1  ").value());
        // // console.log(".parse()   ").value());

        // console.log('.parse()"aabbcc"  ').value());

        // string memory s =
        //     '{"animation_url":"","artist":"Daniel Allan","artwork":{"mimeType":"image/gif","uri":"ar://J5NZ-e2NUcQj1OuuhpTjAKtdW_nqwnwo5FypF_a6dE4","nft":null},"attributes":[{"trait_type":"Criteria","value":"Song Edition"}],"bpm":null,"credits":null,"description":"Criteria is an 8-track project between Daniel Allan and Reo Cragun.\n\nA fusion of electronic music and hip-hop - Criteria brings together the best of both worlds and is meant to bring web3 music to a wider audience.\n\nThe collection consists of 2500 editions with activations across Sound, Bonfire, OnCyber, Spinamp and Arpeggi.","duration":105,"external_url":"https://www.sound.xyz/danielallan/criteria","genre":"Pop","image":"ar://J5NZ-e2NUcQj1OuuhpTjAKtdW_nqwnwo5FypF_a6dE4","isrc":null,"key":null,"license":null,"locationCreated":null,"losslessAudio":"","lyrics":null,"mimeType":"audio/wave","nftSerialNumber":11,"name":"Criteria #11","originalReleaseDate":null,"project":null,"publisher":null,"recordLabel":null,"tags":null,"title":"Criteria","trackNumber":1,"version":"sound-edition-20220930","visualizer":null}';
        // item = s.parse();
        // children = item.children();
        // for (uint256 i; i < children.length; ++i) {
        //     console.log(children[i].key());
        // }
        // assertEq(item.getType(), JSONParserLib.TYPE_OBJECT);
        // assertTrue(item.isObject());
        // console.log(item.children()[0].parent().value());
    }
}
