// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {JSONParserLib} from "../src/utils/JSONParserLib.sol";

contract JSONParserLibTest is SoladyTest {
    using JSONParserLib for *;

    function testParseNumber() public {
        JSONParserLib.Item memory item;
        JSONParserLib.Item[] memory children;

        // console.log(JSONParserLib.parse("  true  ").value());
        // console.log(JSONParserLib.parse("  true").value());
        // console.log(JSONParserLib.parse("  false  ").value());
        // console.log(JSONParserLib.parse("  false").value());
        // console.log(JSONParserLib.parse("  null  ").value());
        // console.log(JSONParserLib.parse("  null").value());

        item = JSONParserLib.parse('[1,2,[3,4],[5,6],7,"hehe", true]');
        children = item.children();
        for (uint256 i; i < children.length; ++i) {
            console.log(children[i].index());
            // console.log(children[i].value());
        }

        // item = JSONParserLib.parse('{"a":"A","b"  :  "B"}');
        // children = item.children();
        // for (uint256 i; i < children.length; ++i) {
        //     console.log(children[i].key());
        //     console.log(children[i].value());
        // }

        // console.log(JSONParserLib.parse("  01234567890  ").value());
        // console.log(JSONParserLib.parse("  -1.234567890e-22  ").value());
        // console.log(JSONParserLib.parse("  1234567890  ").value());
        // console.log(JSONParserLib.parse("  123  ").value());
        // console.log(JSONParserLib.parse("  1  ").value());
        // console.log(JSONParserLib.parse("    ").value());

        // console.log(JSONParserLib.parse(' "aabbcc"  ').value());
    }
}
