// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {LibZip} from "../src/utils/LibZip.sol";

bytes constant ascii = bytes(
    '!\\"#$%&()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmnopqrstuvwxyz{|}~'
);

contract LibZipTest is SoladyTest {
    function testRLECompress() public {
        assertEq(LibZip.rleCompress(bytes(string(""))), bytes(""));
        assertEq(LibZip.rleCompress(bytes(string("11111aaaaabb"))), hex"053105610262");
        assertEq(LibZip.rleCompress(bytes(string("abcd"))), hex"0161016201630164");
        assertEq(
            LibZip.rleCompress(ascii),
            hex"0121015c0122012301240125012601280129012a012b012c012d012e012f0130013101320133013401350136013701380139013a013b013c013d013e013f0140014101420143014401450146014701480149014a014b014c014d014e014f0150015101520153015401550156015701580159015a015b015d015e015f0160016101620163016401650166016701680169016a016b016c016d016e016f0170017101720173017401750176017701780179017a017b017c017d017e"
        );
        // 256 times 0 encoding must be ff000100
        assertEq(
            LibZip.rleCompress(
                hex"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
            ),
            hex"ff000100"
        );
    }

    function testRLEDecompress() public {
        assertEq(LibZip.rleDecompress(bytes("")), bytes(""));
        assertEq(LibZip.rleDecompress(hex"056106310233"), bytes("aaaaa11111133"));
        assertEq(LibZip.rleDecompress(hex"0a320f6b0163"), bytes("2222222222kkkkkkkkkkkkkkkc"));
    }

    function testRLECompressWithrleDecompress(string memory str) public {
        assertEq(LibZip.rleDecompress(LibZip.rleCompress(bytes(str))), bytes(str));
    }

    function testRLECompressWithrleDecompress() public {
        assertEq(LibZip.rleDecompress(LibZip.rleCompress(ascii)), ascii);
    }

    function testrevertWhenrleCompressIsNotRight() public {
        vm.expectRevert();
        LibZip.rleDecompress(hex"0001");
    }
}
