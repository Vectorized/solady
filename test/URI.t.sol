// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {URI} from "../src/utils/URI.sol";
import {LibString} from "../src/utils/LibString.sol";

contract Base64Test is SoladyTest {
    function testURIEncodeAndDecodeWithEmptyString() public {
        _testURIEncodeComponentAndDecodeComponent("", "");
    }

    function testURIEncodeAndDecodeWithShortUnescapedStrings() public {
        _testURIEncodeComponentAndDecodeComponent("W", "W");
        _testURIEncodeComponentAndDecodeComponent("Wi", "Wi");
        _testURIEncodeComponentAndDecodeComponent("Wiz", "Wiz");
        _testURIEncodeComponentAndDecodeComponent("Wiza", "Wiza");
        _testURIEncodeComponentAndDecodeComponent("Wizar", "Wizar");
        _testURIEncodeComponentAndDecodeComponent("Wizard", "Wizard");
        _testURIEncodeComponentAndDecodeComponent("Wizards", "Wizards");
        _testURIEncodeComponentAndDecodeComponent(
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz123456789",
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz123456789"
        );
    }

    function testURIEncodeAndDecodeWithUnreservedMarks() public {
        // None of these characters are encoded, they are not reserved by URI standard
        _testURIEncodeComponentAndDecodeComponent("-.!~*'()", "-.!~*'()");
    }

    function testURIEncodeAndDecodeWithReservedMarks() public {
        // All of these characters are encoded, they are reserved by URI standard
        _testURIEncodeComponentAndDecodeComponent(
            ";/?:@&=+$,# ", "%3B%2F%3F%3A%40%26%3D%2B%24%2C%23%20"
        );
    }

    function testURIEncodeAndDecodeWithUnicode() public {
        _testURIEncodeComponentAndDecodeComponent(unicode"шеллы", "%D1%88%D0%B5%D0%BB%D0%BB%D1%8B");
        _testURIEncodeComponentAndDecodeComponent(unicode"😃", "%F0%9F%98%83");
    }

    function testURIEncodeAndDecodeWithAlphanumericsAndSpace() public {
        // Space is encoded as %20, not the alphanumerics
        _testURIEncodeComponentAndDecodeComponent("Hello World", "Hello%20World");
    }

    function testURIEncodeAndDecodeWithMixOfReservedAndUnreservedMarks() public {
        // Space is encoded as %20, not ! or the alphanumerics
        _testURIEncodeComponentAndDecodeComponent("Hello World!", "Hello%20World!");
    }

    function testURIDecodeHandlesLowerAndUpperCaseHexChars() public {
        assertEq(URI.decodeComponent("%3B%2F%3F%3A%40%26%3D%2B%24%2C%23%20"), ";/?:@&=+$,# ");
        assertEq(URI.decodeComponent("%3b%2f%3f%3a%40%26%3d%2b%24%2c%23%20"), ";/?:@&=+$,# ");
    }

    function testURIDecodeRevertsOnInvalidEncodedString() public {
        vm.expectRevert();
        URI.decodeComponent("%3B%%%%%fadflj####a");
        // this should not revert, this is exactly how the function is implemented in JS
        URI.decodeComponent(";;;");
    }

    function _testURIEncodeComponentAndDecodeComponent(string memory input, string memory output)
        internal
    {
        assertEq(URI.encodeComponent(input), output);
        assertEq(URI.decodeComponent(output), input);
    }
}
