// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {LibRLE} from "../src/utils/LibRLE.sol";

bytes constant ascii = bytes('!\\"#$%&()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmnopqrstuvwxyz{|}~');

contract LibRLETest is SoladyTest {
    event log(bytes b);

    function test_encode() public {
        assertEq(LibRLE.encode(bytes(string(""))), bytes(""));
        assertEq(LibRLE.encode(bytes(string("11111aaaaabb"))), hex"053105610262");
        assertEq(LibRLE.encode(bytes(string("abcd"))), hex"0161016201630164");
        assertEq(
            LibRLE.encode(ascii),
            hex"0121015c0122012301240125012601280129012a012b012c012d012e012f0130013101320133013401350136013701380139013a013b013c013d013e013f0140014101420143014401450146014701480149014a014b014c014d014e014f0150015101520153015401550156015701580159015a015b015d015e015f0160016101620163016401650166016701680169016a016b016c016d016e016f0170017101720173017401750176017701780179017a017b017c017d017e"
        );
        // 256 times 0 encoding must be ff000100
        assertEq(
            LibRLE.encode(
                hex"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
            ),
            hex"ff000100"
        );
    }

    function test_decode() public {
        assertEq(LibRLE.decode(bytes("")), bytes(""));
        assertEq(LibRLE.decode(hex"056106310233"), bytes("aaaaa11111133"));
        assertEq(LibRLE.decode(hex"0a320f6b0163"), bytes("2222222222kkkkkkkkkkkkkkkc"));
    }

    function test_encodeWithDecode(string memory str) public {
        assertEq(LibRLE.decode(LibRLE.encode(bytes(str))), bytes(str));
    }

    function test_encodeWithDecode() public {
        assertEq(LibRLE.decode(LibRLE.encode(ascii)), ascii);
    }

    function test_revertWhenEncodeIsNotRight() public {
        vm.expectRevert();
        LibRLE.decode(hex"0001");
    }
}
