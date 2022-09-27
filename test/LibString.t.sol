// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/TestPlus.sol";
import {LibString} from "../src/utils/LibString.sol";

contract LibStringTest is TestPlus {
    function testToStringZero() public {
        assertEq(keccak256(bytes(LibString.toString(0))), keccak256(bytes("0")));
    }

    function testToStringPositiveNumber() public {
        assertEq(keccak256(bytes(LibString.toString(4132))), keccak256(bytes("4132")));
    }

    function testToStringUint256Max() public {
        assertEq(
            keccak256(bytes(LibString.toString(type(uint256).max))),
            keccak256(bytes("115792089237316195423570985008687907853269984665640564039457584007913129639935"))
        );
    }

    function testToStringZeroBrutalized() public {
        string memory s0 = LibString.toString(0);
        assembly {
            mstore(mload(0x40), not(0))
            mstore(0x40, add(mload(0x40), 0x20))
        }
        string memory s1 = LibString.toString(0);
        assembly {
            mstore(mload(0x40), not(0))
            mstore(0x40, add(mload(0x40), 0x20))
        }
        assertEq(keccak256(bytes(s0)), keccak256(bytes("0")));
        assertEq(keccak256(bytes(s1)), keccak256(bytes("0")));
    }

    function testToStringPositiveNumberBrutalized() public {
        string memory s0 = LibString.toString(4132);
        assembly {
            mstore(mload(0x40), not(0))
            mstore(0x40, add(mload(0x40), 0x20))
        }
        string memory s1 = LibString.toString(4132);
        assembly {
            mstore(mload(0x40), not(0))
            mstore(0x40, add(mload(0x40), 0x20))
        }
        assertEq(keccak256(bytes(s0)), keccak256(bytes("4132")));
        assertEq(keccak256(bytes(s1)), keccak256(bytes("4132")));
    }

    function testToStringUint256MaxBrutalized() public {
        string memory s0 = LibString.toString(type(uint256).max);
        assembly {
            mstore(mload(0x40), not(0))
            mstore(0x40, add(mload(0x40), 0x20))
        }
        string memory s1 = LibString.toString(type(uint256).max);
        assembly {
            mstore(mload(0x40), not(0))
            mstore(0x40, add(mload(0x40), 0x20))
        }
        assertEq(
            keccak256(bytes(s0)),
            keccak256(bytes("115792089237316195423570985008687907853269984665640564039457584007913129639935"))
        );
        assertEq(
            keccak256(bytes(s1)),
            keccak256(bytes("115792089237316195423570985008687907853269984665640564039457584007913129639935"))
        );
    }

    function testToStringZeroRightPadded(uint256 x) public pure {
        _checkStringIsZeroRightPadded(LibString.toString(x));
    }

    function testToHexStringZero() public {
        assertEq(keccak256(bytes(LibString.toHexString(0))), keccak256(bytes("0x00")));
    }

    function testToHexStringPositiveNumber() public {
        assertEq(keccak256(bytes(LibString.toHexString(0x4132))), keccak256(bytes("0x4132")));
    }

    function testToHexStringUint256Max() public {
        assertEq(
            keccak256(bytes(LibString.toHexString(type(uint256).max))),
            keccak256(bytes("0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"))
        );
    }

    function testToHexStringFixedLengthPositiveNumberLong() public {
        assertEq(
            keccak256(bytes(LibString.toHexString(0x4132, 32))),
            keccak256(bytes("0x0000000000000000000000000000000000000000000000000000000000004132"))
        );
    }

    function testToHexStringFixedLengthPositiveNumberShort() public {
        assertEq(keccak256(bytes(LibString.toHexString(0x4132, 2))), keccak256(bytes("0x4132")));
    }

    function testToHexStringZeroRightPadded(uint256 x) public pure {
        _checkStringIsZeroRightPadded(LibString.toHexString(x));
    }

    function testToHexStringFixedLengthInsufficientLength() public {
        vm.expectRevert(LibString.HexLengthInsufficient.selector);
        LibString.toHexString(0x4132, 1);
    }

    function testToHexStringFixedLengthUint256Max() public {
        assertEq(
            keccak256(bytes(LibString.toHexString(type(uint256).max, 32))),
            keccak256(bytes("0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"))
        );
    }

    function testToHexStringFixedLengthZeroRightPadded(uint256 x, uint256 randomness) public pure {
        uint256 minLength = (bytes(LibString.toHexString(x)).length - 2) * 2;
        uint256 length = (randomness % 32) + minLength;
        _checkStringIsZeroRightPadded(LibString.toHexString(x, length));
    }

    function testFromAddressToHexString() public {
        assertEq(
            keccak256(bytes(LibString.toHexString(address(0xA9036907dCcae6a1E0033479B12E837e5cF5a02f)))),
            keccak256(bytes("0xa9036907dccae6a1e0033479b12e837e5cf5a02f"))
        );
    }

    function testAddressToHexStringZeroRightPadded(address x) public pure {
        _checkStringIsZeroRightPadded(LibString.toHexString(x));
    }

    function testFromAddressToHexStringWithLeadingZeros() public {
        assertEq(
            keccak256(bytes(LibString.toHexString(address(0x0000E0Ca771e21bD00057F54A68C30D400000000)))),
            keccak256(bytes("0x0000e0ca771e21bd00057f54a68c30d400000000"))
        );
    }

    function testStringReplaceShort() public {
        assertEq(LibString.replace("abc", "", "_@"), "_@a_@b_@c_@");
        assertEq(LibString.replace("abc", "a", "_"), "_bc");
        assertEq(LibString.replace("abc", "b", "_"), "a_c");
        assertEq(LibString.replace("abc", "c", "_"), "ab_");
        assertEq(LibString.replace("abc", "ab", "_"), "_c");
        assertEq(LibString.replace("abc", "bc", "_"), "a_");
        assertEq(LibString.replace("abc", "ac", "_"), "abc");
        assertEq(LibString.replace("abc", "a", ""), "bc");
        assertEq(LibString.replace("abc", "", ""), "abc");
        assertEq(LibString.replace("abc", "d", "x"), "abc");
    }

    function testStringReplaceMedium() public {
        // prettier-ignore
        string memory subject = "70708741044725766535585242414884609539555049888764130733849700923779599488691391677696419266840";
        string memory search = "46095395550498887641307338497009";
        string memory replacement = "320807383223517906783031356692334377159141";
        // prettier-ignore
        string memory expectedResult = "707087410447257665355852424148832080738322351790678303135669233437715914123779599488691391677696419266840";
        assertEq(LibString.replace(subject, search, replacement), expectedResult);
    }

    function testStringReplaceLong() public {
        // prettier-ignore
        string memory subject = "01234567890123456789012345678901_search_search_search_search_search_search_23456789012345678901234567890123456789_search_search_search_search_search_search";
        string memory search = "search_search_search_search_search_search";
        string memory replacement = "REPLACEMENT_REPLACEMENT_REPLACEMENT_REPLACEMENT_REPLACEMENT";
        // prettier-ignore
        string memory expectedResult = "01234567890123456789012345678901_REPLACEMENT_REPLACEMENT_REPLACEMENT_REPLACEMENT_REPLACEMENT_23456789012345678901234567890123456789_REPLACEMENT_REPLACEMENT_REPLACEMENT_REPLACEMENT_REPLACEMENT";
        assertEq(LibString.replace(subject, search, replacement), expectedResult);
    }

    function testStringReplace(uint256 randomness) public brutalizeMemory {
        string memory filler = _generateString(randomness, "ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        string memory search = _generateString(randomness, "abcdefghijklmnopqrstuvwxyz");
        string memory replacement = _generateString(randomness, "0123456790_-+/=|{}<>!");
        if (bytes(search).length != 0) {
            string memory subject = string(
                bytes.concat(bytes(filler), bytes(search), bytes(filler), bytes(search), bytes(filler))
            );
            _roundUpFreeMemoryPointer();
            _brutalizeFreeMemoryStart();
            string memory expectedResult = string(
                bytes.concat(bytes(filler), bytes(replacement), bytes(filler), bytes(replacement), bytes(filler))
            );
            _roundUpFreeMemoryPointer();
            _brutalizeFreeMemoryStart();
            string memory replaced = LibString.replace(subject, search, replacement);
            _brutalizeFreeMemoryStart();
            _checkStringIsZeroRightPadded(replaced);
            assertEq(replaced, expectedResult);
        } else {
            string memory expectedResult = string(
                bytes.concat(
                    bytes(replacement),
                    bytes(" "),
                    bytes(replacement),
                    bytes(" "),
                    bytes(replacement),
                    bytes(" "),
                    bytes(replacement)
                )
            );
            string memory replaced = LibString.replace("   ", search, replacement);
            assertEq(replaced, expectedResult);
        }
    }

    function testStringIndexOf(uint256 randomness) public brutalizeMemory {
        string memory filler0 = _generateString(randomness, "ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        string memory filler1 = _generateString(randomness, "ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        string memory search = _generateString(randomness, "abcdefghijklmnopqrstuvwxyz");

        string memory subject = string(bytes.concat(bytes(filler0), bytes(search), bytes(filler1)));

        uint256 from = _generateFrom(randomness, subject);

        if (bytes(search).length == 0) {
            if (from > bytes(subject).length) {
                assertEq(LibString.indexOf(subject, search, from), bytes(subject).length);
            } else {
                assertEq(LibString.indexOf(subject, search, from), from);
            }
        } else {
            if (from > bytes(filler0).length) {
                assertEq(LibString.indexOf(subject, search, from), LibString.NOT_FOUND);
            } else {
                assertEq(LibString.indexOf(subject, search, from), bytes(filler0).length);
            }
        }
    }

    function testStringIndexOf() public {
        string memory subject = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
        assertEq(LibString.indexOf(subject, ""), 0);
        assertEq(LibString.indexOf(subject, "", 16), 16);
        assertEq(LibString.indexOf(subject, "", 17), 17);
        assertEq(LibString.indexOf(subject, "", 52), 52);
        assertEq(LibString.indexOf(subject, "", 53), 52);
        assertEq(LibString.indexOf(subject, "", 555), 52);
        assertEq(LibString.indexOf(subject, "abc", 0), 0);
        assertEq(LibString.indexOf(subject, "abc", 1), LibString.NOT_FOUND);
        assertEq(LibString.indexOf(subject, "bcd"), 1);
        assertEq(LibString.indexOf(subject, "XYZ"), 49);
        assertEq(LibString.indexOf(subject, "qrstuvwxyzABCDEFGHIJKLMNOPQRSTUVW"), 16);
        assertEq(LibString.indexOf(subject, "qrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"), 16);
        assertEq(LibString.indexOf(subject, "qrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", 16), 16);
        assertEq(LibString.indexOf(subject, "qrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", 17), LibString.NOT_FOUND);

        assertEq(LibString.indexOf("abcabcabc", "abc"), 0);
        assertEq(LibString.indexOf("abcabcabc", "abc", 1), 3);

        assertEq(LibString.indexOf("a", "bcd"), LibString.NOT_FOUND);
        assertEq(LibString.indexOf("a", "bcd", 0), LibString.NOT_FOUND);
        assertEq(LibString.indexOf("accd", "bcd"), LibString.NOT_FOUND);
        assertEq(LibString.indexOf("", "bcd"), LibString.NOT_FOUND);
    }

    function testStringLastIndexOf(uint256 randomness) public brutalizeMemory {
        string memory filler0 = _generateString(randomness, "ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        string memory filler1 = _generateString(randomness, "ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        string memory search = _generateString(randomness, "abcdefghijklmnopqrstuvwxyz");

        string memory subject = string(bytes.concat(bytes(filler0), bytes(search), bytes(filler1)));

        uint256 from = _generateFrom(randomness, subject);

        if (bytes(search).length == 0) {
            if (from > bytes(subject).length) {
                assertEq(LibString.lastIndexOf(subject, search, from), bytes(subject).length);
            } else {
                assertEq(LibString.lastIndexOf(subject, search, from), from);
            }
        } else {
            if (from < bytes(filler0).length) {
                assertEq(LibString.lastIndexOf(subject, search, from), LibString.NOT_FOUND);
            } else {
                assertEq(LibString.lastIndexOf(subject, search, from), bytes(filler0).length);
            }
        }
    }

    function testStringLastIndexOf() public {
        string memory subject = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
        assertEq(LibString.lastIndexOf(subject, "", 0), 0);
        assertEq(LibString.lastIndexOf(subject, "", 16), 16);
        assertEq(LibString.lastIndexOf(subject, "", 17), 17);
        assertEq(LibString.lastIndexOf(subject, "", 52), 52);
        assertEq(LibString.lastIndexOf(subject, "", 53), 52);
        assertEq(LibString.lastIndexOf(subject, "", 555), 52);
        assertEq(LibString.lastIndexOf(subject, "abc"), 0);
        assertEq(LibString.lastIndexOf(subject, "abc", 0), 0);
        assertEq(LibString.lastIndexOf(subject, "abc", 1), 0);
        assertEq(LibString.lastIndexOf(subject, "abc", 3), 0);
        assertEq(LibString.lastIndexOf(subject, "bcd"), 1);
        assertEq(LibString.lastIndexOf(subject, "bcd", 1), 1);
        assertEq(LibString.lastIndexOf(subject, "bcd", 0), LibString.NOT_FOUND);
        assertEq(LibString.lastIndexOf(subject, "XYZ"), 49);
        assertEq(LibString.lastIndexOf(subject, "qrstuvwxyzABCDEFGHIJKLMNOPQRSTUVW"), 16);
        assertEq(LibString.lastIndexOf(subject, "qrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"), 16);
        assertEq(LibString.lastIndexOf(subject, "qrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", 52), 16);
        assertEq(LibString.lastIndexOf(subject, "qrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", 51), 16);
        assertEq(LibString.lastIndexOf(subject, "qrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", 16), 16);
        assertEq(LibString.lastIndexOf(subject, "qrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", 15), LibString.NOT_FOUND);

        assertEq(LibString.lastIndexOf("abcabcabc", "abc"), 6);
        assertEq(LibString.lastIndexOf("abcabcabc", "abc", 5), 3);

        assertEq(LibString.lastIndexOf("a", "bcd"), LibString.NOT_FOUND);
        assertEq(LibString.lastIndexOf("a", "bcd", 0), LibString.NOT_FOUND);
        assertEq(LibString.lastIndexOf("accd", "bcd"), LibString.NOT_FOUND);
        assertEq(LibString.lastIndexOf("", "bcd"), LibString.NOT_FOUND);
    }

    function testStringStartsWith(uint256 randomness) public brutalizeMemory {
        string memory filler = _generateString(randomness, "ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        string memory search = _generateString(randomness, "abcdefghijklmnopqrstuvwxyz");

        if (bytes(search).length == 0) {
            string memory subject = string(bytes.concat(bytes(filler), bytes(search)));
            assertEq(LibString.startsWith(subject, search), true);
        }

        if (randomness & 1 == 1) {
            string memory subject = string(bytes.concat(bytes(search), bytes(filler)));
            assertEq(LibString.startsWith(subject, search), true);
        }

        if (bytes(filler).length != 0 && bytes(search).length != 0) {
            string memory subject = string(bytes.concat(bytes(filler), bytes(search)));
            assertEq(LibString.startsWith(subject, search), false);
        }
    }

    function testStringStartsWith() public {
        string memory subject = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
        assertEq(LibString.startsWith(subject, "abc"), true);
        assertEq(LibString.startsWith(subject, "abcdefghijklmnopqrstuvwxyzABCDEFG"), true);
        assertEq(LibString.startsWith(subject, "bcd"), false);
        assertEq(LibString.startsWith(subject, "bcdefghijklmnopqrstuvwxyzABCDEFGH"), false);

        assertEq(LibString.startsWith("", ""), true);
        assertEq(LibString.startsWith("bc", ""), true);
        assertEq(LibString.startsWith("bc", "bc"), true);
        assertEq(LibString.startsWith("bc", "abc"), false);
        assertEq(LibString.startsWith("", "abc"), false);
    }

    function testStringEndsWith(uint256 randomness) public brutalizeMemory {
        string memory filler = _generateString(randomness, "ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        string memory search = _generateString(randomness, "abcdefghijklmnopqrstuvwxyz");

        if (bytes(search).length == 0) {
            string memory subject = string(bytes.concat(bytes(search), bytes(filler)));
            assertEq(LibString.endsWith(subject, search), true);
        }

        if (randomness & 1 == 1) {
            string memory subject = string(bytes.concat(bytes(filler), bytes(search)));
            assertEq(LibString.endsWith(subject, search), true);
        }

        if (bytes(filler).length != 0 && bytes(search).length != 0) {
            string memory subject = string(bytes.concat(bytes(search), bytes(filler)));
            assertEq(LibString.endsWith(subject, search), false);
        }
    }

    function testStringEndsWith() public {
        string memory subject = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
        assertEq(LibString.endsWith(subject, "XYZ"), true);
        assertEq(LibString.endsWith(subject, "pqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"), true);
        assertEq(LibString.endsWith(subject, "WXY"), false);
        assertEq(LibString.endsWith(subject, "opqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXY"), false);

        assertEq(LibString.endsWith("", ""), true);
        assertEq(LibString.endsWith("bc", ""), true);
        assertEq(LibString.endsWith("bc", "bc"), true);
        assertEq(LibString.endsWith("bc", "abc"), false);
        assertEq(LibString.endsWith("", "abc"), false);
    }

    function testStringRepeat(string memory subject, uint256 times) public brutalizeMemory {
        times = times % 8;
        string memory repeated = LibString.repeat(subject, times);
        _brutalizeFreeMemoryStart();
        string memory expectedResult = _repeatOriginal(subject, times);
        _brutalizeFreeMemoryStart();
        _checkStringIsZeroRightPadded(repeated);
        assertEq(repeated, expectedResult);
    }

    function testStringRepeat() public {
        assertEq(LibString.repeat("", 0), "");
        assertEq(LibString.repeat("", 100), "");
        assertEq(LibString.repeat("a", 0), "");
        assertEq(LibString.repeat("a", 1), "a");
        assertEq(LibString.repeat("a", 3), "aaa");
        assertEq(LibString.repeat("abc", 0), "");
        assertEq(LibString.repeat("abc", 1), "abc");
        assertEq(LibString.repeat("abc", 3), "abcabcabc");
        assertEq(LibString.repeat("efghi", 3), "efghiefghiefghi");
    }

    function testStringRepeatOriginal() public {
        assertEq(_repeatOriginal("", 0), "");
        assertEq(_repeatOriginal("", 100), "");
        assertEq(_repeatOriginal("a", 0), "");
        assertEq(_repeatOriginal("a", 1), "a");
        assertEq(_repeatOriginal("a", 3), "aaa");
        assertEq(_repeatOriginal("abc", 0), "");
        assertEq(_repeatOriginal("abc", 1), "abc");
        assertEq(_repeatOriginal("abc", 3), "abcabcabc");
        assertEq(_repeatOriginal("efghi", 3), "efghiefghiefghi");
    }

    function testStringSlice(uint256 randomness) public brutalizeMemory {
        string memory filler0 = _generateString(randomness, "ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        string memory expectedResult = _generateString(randomness, "abcdefghijklmnopqrstuvwxyz");
        string memory filler1 = _generateString(randomness, "ABCDEFGHIJKLMNOPQRSTUVWXYZ");

        string memory subject = string(bytes.concat(bytes(filler0), bytes(expectedResult), bytes(filler1)));

        uint256 start = bytes(filler0).length;
        uint256 end = start + bytes(expectedResult).length;

        string memory slice = LibString.slice(subject, start, end);
        _checkStringIsZeroRightPadded(slice);
        assertEq(slice, expectedResult);
    }

    function testStringSlice() public {
        assertEq(LibString.slice("", 0, 1), "");
        assertEq(LibString.slice("", 1, 0), "");
        assertEq(LibString.slice("", 0, 0), "");
        assertEq(LibString.slice("", 0), "");
        assertEq(LibString.slice("", 1), "");

        assertEq(LibString.slice("a", 0), "a");
        assertEq(LibString.slice("a", 1), "");
        assertEq(LibString.slice("a", 3), "");

        assertEq(LibString.slice("abc", 0), "abc");
        assertEq(LibString.slice("abc", 1), "bc");
        assertEq(LibString.slice("abc", 1, 2), "b");
        assertEq(LibString.slice("abc", 3), "");

        string memory subject = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
        assertEq(LibString.slice(subject, 0), subject);
        assertEq(LibString.slice(subject, 1), "bcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ");
        assertEq(LibString.slice(subject, 1, 51), "bcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXY");
        assertEq(LibString.slice(subject, 11, 41), "lmnopqrstuvwxyzABCDEFGHIJKLMNO");
        assertEq(LibString.slice(subject, 21, 31), "vwxyzABCDE");
        assertEq(LibString.slice(subject, 31, 21), "");
    }

    function testStringIndicesOf(uint256 randomness) public brutalizeMemory {
        string memory filler0 = _generateString(randomness, "ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        string memory filler1 = _generateString(randomness, "ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        string memory search = _generateString(randomness, "abcdefghijklmnopqrstuvwxyz");

        string memory subject;

        unchecked {
            uint256[] memory indices;
            if (randomness & 1 == 0) {
                subject = string(bytes.concat(bytes(filler0), bytes(search), bytes(filler1)));
                indices = new uint256[](1);
                indices[0] = bytes(filler0).length;
            } else {
                subject = string(bytes.concat(bytes(filler0), bytes(filler1)));
                indices = new uint256[](0);
            }

            if (bytes(search).length == 0) {
                indices = new uint256[](bytes(subject).length + 1);
                for (uint256 i; i < indices.length; ++i) {
                    indices[i] = i;
                }
            }
            assertEq(LibString.indicesOf(subject, search), indices);
        }
    }

    function testStringIndicesOf() public {
        uint256[] memory indices;

        indices = new uint256[](3);
        indices[0] = 0;
        indices[1] = 2;
        indices[2] = 4;
        assertEq(LibString.indicesOf("ababa", "a"), indices);

        indices = new uint256[](6);
        indices[0] = 0;
        indices[1] = 1;
        indices[2] = 2;
        indices[3] = 3;
        indices[4] = 4;
        indices[5] = 5;
        assertEq(LibString.indicesOf("ababa", ""), indices);

        indices = new uint256[](2);
        indices[0] = 1;
        indices[1] = 3;
        assertEq(LibString.indicesOf("ababa", "b"), indices);

        indices = new uint256[](2);
        indices[0] = 0;
        indices[1] = 2;
        assertEq(LibString.indicesOf("ababa", "ab"), indices);

        indices = new uint256[](2);
        indices[0] = 1;
        indices[1] = 3;
        assertEq(LibString.indicesOf("ababa", "ba"), indices);

        indices = new uint256[](1);
        indices[0] = 1;
        assertEq(LibString.indicesOf("ababa", "bab"), indices);

        indices = new uint256[](1);
        indices[0] = 0;
        assertEq(LibString.indicesOf("ababa", "ababa"), indices);

        indices = new uint256[](1);
        indices[0] = 0;
        assertEq(LibString.indicesOf("", ""), indices);

        indices = new uint256[](0);
        assertEq(LibString.indicesOf("ababa", "c"), indices);

        indices = new uint256[](0);
        assertEq(LibString.indicesOf("ababab", "abababa"), indices);
    }

    function testStringSplit(uint256 randomness) public brutalizeMemory {
        string memory filler0 = _generateString(randomness, "ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        string memory filler1 = _generateString(randomness, "ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        string memory delimiter = _generateString(randomness, "abcdefghijklmnopqrstuvwxyz");

        string memory subject = string(bytes.concat(bytes(filler0), bytes(delimiter), bytes(filler1)));

        unchecked {
            string[] memory elements;
            if (bytes(delimiter).length == 0) {
                elements = new string[](bytes(subject).length);
                for (uint256 i; i < elements.length; ++i) {
                    elements[i] = LibString.slice(subject, i, i + 1);
                }
            } else {
                elements = new string[](2);
                elements[0] = filler0;
                elements[1] = filler1;
            }
            _roundUpFreeMemoryPointer();
            string[] memory splitted = LibString.split(subject, delimiter);
            _brutalizeFreeMemoryStart();
            assertTrue(_stringArraysAreSame(splitted, elements));
            for (uint256 i; i < splitted.length; ++i) {
                _checkStringIsZeroRightPadded(splitted[i]);
            }
        }
    }

    function testStringSplit() public {
        string[] memory elements;

        elements = new string[](4);
        elements[0] = "";
        elements[1] = "b";
        elements[2] = "b";
        elements[3] = "";
        assertTrue(_stringArraysAreSame(LibString.split("ababa", "a"), elements));

        elements = new string[](3);
        elements[0] = "a";
        elements[1] = "a";
        elements[2] = "a";
        assertTrue(_stringArraysAreSame(LibString.split("ababa", "b"), elements));

        elements = new string[](5);
        elements[0] = "a";
        elements[1] = "b";
        elements[2] = "a";
        elements[3] = "b";
        elements[4] = "a";
        assertTrue(_stringArraysAreSame(LibString.split("ababa", ""), elements));

        elements = new string[](2);
        elements[0] = "a";
        elements[1] = "b";
        assertTrue(_stringArraysAreSame(LibString.split("ab", ""), elements));

        elements = new string[](1);
        elements[0] = "a";
        assertTrue(_stringArraysAreSame(LibString.split("a", ""), elements));

        elements = new string[](0);
        assertTrue(_stringArraysAreSame(LibString.split("", ""), elements));
    }

    function testStringConcat(string memory a, string memory b) public brutalizeMemory {
        string memory concatenated = LibString.concat(a, b);
        _roundUpFreeMemoryPointer();
        _brutalizeFreeMemoryStart();
        string memory expectedResult = string(bytes.concat(bytes(a), bytes(b)));
        _roundUpFreeMemoryPointer();
        _brutalizeFreeMemoryStart();
        _checkStringIsZeroRightPadded(concatenated);
        assertEq(concatenated, expectedResult);
    }

    function testStringConcat() public {
        assertEq(
            LibString.concat(
                "bcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXY",
                "12345678901234567890123456789012345678901234567890"
            ),
            "bcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXY12345678901234567890123456789012345678901234567890"
        );
        assertEq(LibString.concat("", "b"), "b");
        assertEq(LibString.concat("", "b"), "b");
        assertEq(LibString.concat("a", "b"), "ab");
        assertEq(LibString.concat("a", ""), "a");
        assertEq(LibString.concat("", ""), "");
    }

    function testStringConcatOriginal() public {
        assertEq(
            string(
                bytes.concat(
                    bytes("bcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXY"),
                    bytes("12345678901234567890123456789012345678901234567890")
                )
            ),
            "bcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXY12345678901234567890123456789012345678901234567890"
        );
        assertEq(string(bytes.concat(bytes(""), bytes("b"))), "b");
        assertEq(string(bytes.concat(bytes(""), bytes("b"))), "b");
        assertEq(string(bytes.concat(bytes("a"), bytes("b"))), "ab");
        assertEq(string(bytes.concat(bytes("a"), bytes(""))), "a");
        assertEq(string(bytes.concat(bytes(""), bytes(""))), "");
    }

    function testStringPackAndUnpackOneDifferential(string memory a) public brutalizeMemory {
        // Ensure the input strings are zero-right padded, so that the comparison is clean.
        a = LibString.slice(a, 0);
        bytes32 packed = LibString.packOne(a);
        unchecked {
            if (bytes(a).length < 32) {
                assertEq(packed, bytes32(abi.encodePacked(uint8(bytes(a).length), a)));
            } else {
                assertEq(packed, bytes32(0));
            }
        }
    }

    function testStringPackAndUnpackOne(string memory a) public brutalizeMemory {
        _roundUpFreeMemoryPointer();
        bytes32 packed = LibString.packOne(a);
        string memory unpacked = LibString.unpackOne(packed);
        _checkStringIsZeroRightPadded(unpacked);
        _brutalizeFreeMemoryStart();

        if (bytes(a).length < 32) {
            assertEq(unpacked, a);
        } else {
            assertEq(packed, bytes32(0));
            assertEq(unpacked, "");
        }
    }

    function testStringPackAndUnpackOne() public {
        unchecked {
            testStringPackAndUnpackOne("");
            testStringPackAndUnpackOne("Hehe");
            testStringPackAndUnpackOne("abcdefghijklmnopqrstuvwxyzABCD");
            testStringPackAndUnpackOne("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ");
        }
    }

    function testStringPackAndUnpackTwoDifferential(string memory a, string memory b) public brutalizeMemory {
        // Ensure the input strings are zero-right padded, so that the comparison is clean.
        a = LibString.slice(a, 0);
        b = LibString.slice(b, 0);
        bytes32 packed = LibString.packTwo(a, b);
        unchecked {
            if (bytes(a).length + bytes(b).length < 31) {
                assertEq(packed, bytes32(abi.encodePacked(uint8(bytes(a).length), a, uint8(bytes(b).length), b)));
            } else {
                assertEq(packed, bytes32(0));
            }
        }
    }

    function testStringPackAndUnpackTwo(string memory a, string memory b) public brutalizeMemory {
        bytes32 packed = LibString.packTwo(a, b);
        _roundUpFreeMemoryPointer();
        (string memory unpackedA, string memory unpackedB) = LibString.unpackTwo(packed);
        _checkStringIsZeroRightPadded(unpackedA);
        _checkStringIsZeroRightPadded(unpackedB);
        _brutalizeFreeMemoryStart();

        unchecked {
            if (bytes(a).length + bytes(b).length < 31) {
                assertEq(unpackedA, a);
                assertEq(unpackedB, b);
            } else {
                assertEq(packed, bytes32(0));
                assertEq(unpackedA, "");
                assertEq(unpackedB, "");
            }
        }
    }

    function testStringPackAndUnpackTwo() public {
        unchecked {
            testStringPackAndUnpackTwo("", "");
            testStringPackAndUnpackTwo("", "");
            testStringPackAndUnpackTwo("a", "");
            testStringPackAndUnpackTwo("", "b");
            testStringPackAndUnpackTwo("abcdefghijklmnopqrstuvwxyzABCD", "");
            testStringPackAndUnpackTwo("The strongest community I've ever seen", "NGL");
            testStringPackAndUnpackTwo("", "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ");
        }
    }

    function testStringDirectReturn(string memory a) public {
        assertEq(this.returnString(a), a);
        // Unfortunately, we can't actually test if {directReturn} will actually zero right pad here.
    }

    function returnString(string memory a) external pure returns (string memory) {
        LibString.directReturn(a);
    }

    function _repeatOriginal(string memory subject, uint256 times) internal pure returns (string memory) {
        unchecked {
            string memory result;
            if (!(times == 0 || bytes(subject).length == 0)) {
                for (uint256 i; i < times; ++i) {
                    result = string(bytes.concat(bytes(result), bytes(subject)));
                }
            }
            _roundUpFreeMemoryPointer();
            return result;
        }
    }

    function _generateFrom(uint256 randomness, string memory subject) internal view returns (uint256 from) {
        assembly {
            mstore(0x00, xor(randomness, gas()))
            let r := keccak256(0x00, 0x20)
            switch and(r, 7)
            case 0 {
                // Ensure that the function tested does not revert for
                // all ranges of `from`.
                mstore(0x00, r)
                from := shl(and(r, 255), keccak256(0x00, 0x20))
            }
            default {
                from := mod(r, add(mload(subject), 10))
            }
        }
    }

    function _generateString(uint256 randomness, string memory byteChoices)
        internal
        view
        returns (string memory result)
    {
        assembly {
            if mload(byteChoices) {
                mstore(0x00, randomness)
                mstore(0x20, gas())

                result := mload(0x40)
                let resultLength := and(keccak256(0x00, 0x40), 0x7f)
                mstore(0x40, and(add(add(result, 0x40), resultLength), not(31)))
                mstore(result, resultLength)

                // prettier-ignore
                for { let i := 0 } lt(i, resultLength) { i := add(i, 1) } {
                    mstore(0x20, gas())
                    mstore8(
                        add(add(result, 0x20), i), 
                        mload(add(add(byteChoices, 1), mod(keccak256(0x00, 0x40), mload(byteChoices))))
                    )
                }
            }
        }
    }

    function _checkStringIsZeroRightPadded(string memory s) internal pure {
        bool failed;
        assembly {
            let lastAlignedWord := mload(add(add(s, 0x20), and(mload(s), not(31))))
            let remainder := and(mload(s), 31)
            if remainder {
                if shl(mul(8, remainder), lastAlignedWord) {
                    failed := 1
                }
            }
        }
        if (failed) revert("String is not zero right padded!");
    }

    function _stringArraysAreSame(string[] memory a, string[] memory b) internal pure returns (bool) {
        unchecked {
            if (a.length != b.length) {
                return false;
            }
            for (uint256 i; i < a.length; ++i) {
                if (keccak256(bytes(a[i])) != keccak256(bytes(b[i]))) {
                    return false;
                }
            }
            return true;
        }
    }
}
