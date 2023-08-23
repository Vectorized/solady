// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {JSONParserLib} from "../src/utils/JSONParserLib.sol";

contract JSONParserLibTest is SoladyTest {
    using JSONParserLib for *;

    function testParseNumber() public {
        // console.log(JSONParserLib.parse("  01234567890  ").value());
        console.log(JSONParserLib.parse("  -1.234567890e-22  ").value());
        console.log(JSONParserLib.parse("  1234567890  ").value());
        console.log(JSONParserLib.parse("  123  ").value());
        console.log(JSONParserLib.parse("  1  ").value());
        console.log(JSONParserLib.parse("    ").value());

        console.log(JSONParserLib.parse(' "aabbcc"  ').value());
    }
}
