// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/TestPlus.sol";
import {LibString} from "../src/utils/LibString.sol";

contract LibStringTest is TestPlus {
    function testToStringZero() public {
        assertEq(LibString.toString(uint256(0)), "0");
    }

    function testToStringPositiveNumber() public {
        assertEq(LibString.toString(uint256(4132)), "4132");
    }

    function testToStringUint256Max() public {
        assertEq(
            LibString.toString(type(uint256).max),
            "115792089237316195423570985008687907853269984665640564039457584007913129639935"
        );
    }

    function testToStringZeroBrutalized() public brutalizeMemory {
        string memory s0 = LibString.toString(uint256(0));
        /// @solidity memory-safe-assembly
        assembly {
            mstore(mload(0x40), not(0))
            mstore(0x40, add(mload(0x40), 0x20))
        }
        string memory s1 = LibString.toString(uint256(0));
        /// @solidity memory-safe-assembly
        assembly {
            mstore(mload(0x40), not(0))
            mstore(0x40, add(mload(0x40), 0x20))
        }
        assertEq(s0, "0");
        assertEq(s1, "0");
    }

    function testToStringPositiveNumberBrutalized() public brutalizeMemory {
        string memory s0 = LibString.toString(uint256(4132));
        /// @solidity memory-safe-assembly
        assembly {
            mstore(mload(0x40), not(0))
            mstore(0x40, add(mload(0x40), 0x20))
        }
        string memory s1 = LibString.toString(uint256(4132));
        /// @solidity memory-safe-assembly
        assembly {
            mstore(mload(0x40), not(0))
            mstore(0x40, add(mload(0x40), 0x20))
        }
        assertEq(s0, "4132");
        assertEq(s1, "4132");
    }

    function testToStringUint256MaxBrutalized() public brutalizeMemory {
        string memory s0 = LibString.toString(type(uint256).max);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(mload(0x40), not(0))
            mstore(0x40, add(mload(0x40), 0x20))
        }
        string memory s1 = LibString.toString(type(uint256).max);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(mload(0x40), not(0))
            mstore(0x40, add(mload(0x40), 0x20))
        }
        assertEq(
            s0, "115792089237316195423570985008687907853269984665640564039457584007913129639935"
        );
        assertEq(
            s1, "115792089237316195423570985008687907853269984665640564039457584007913129639935"
        );
    }

    function testToStringZeroRightPadded(uint256 x) public view brutalizeMemory {
        _checkMemory(LibString.toString(x));
    }

    function testToStringSignedDifferential(int256 x) public brutalizeMemory {
        assertEq(LibString.toString(x), _toStringSignedOriginal(x));
    }

    function testToStringSignedMemory(int256 x) public view brutalizeMemory {
        _roundUpFreeMemoryPointer();
        uint256 freeMemoryPointer;
        /// @solidity memory-safe-assembly
        assembly {
            freeMemoryPointer := mload(0x40)
        }
        string memory str = LibString.toString(x);
        /// @solidity memory-safe-assembly
        assembly {
            if lt(str, freeMemoryPointer) { revert(0, 0) }
        }
        _checkMemory(str);
    }

    function testToStringSignedGas() public pure {
        for (int256 x = -10; x < 10; ++x) {
            LibString.toString(x);
        }
    }

    function testToStringSignedOriginalGas() public pure {
        for (int256 x = -10; x < 10; ++x) {
            _toStringSignedOriginal(x);
        }
    }

    function _toStringSignedOriginal(int256 x) internal pure returns (string memory) {
        unchecked {
            return x >= 0
                ? LibString.toString(uint256(x))
                : string(abi.encodePacked("-", LibString.toString(uint256(-x))));
        }
    }

    function testToHexStringZero() public {
        assertEq(LibString.toHexString(0), "0x00");
    }

    function testToHexStringPositiveNumber() public {
        assertEq(LibString.toHexString(0x4132), "0x4132");
    }

    function testToHexStringUint256Max() public {
        assertEq(
            LibString.toHexString(type(uint256).max),
            "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
        );
    }

    function testToHexStringFixedLengthPositiveNumberLong() public {
        assertEq(
            LibString.toHexString(0x4132, 32),
            "0x0000000000000000000000000000000000000000000000000000000000004132"
        );
    }

    function testToHexStringFixedLengthPositiveNumberShort() public {
        assertEq(LibString.toHexString(0x4132, 2), "0x4132");
    }

    function testToHexStringZeroRightPadded(uint256 x) public pure {
        _checkMemory(LibString.toHexString(x));
    }

    function testToHexStringFixedLengthInsufficientLength() public {
        vm.expectRevert(LibString.HexLengthInsufficient.selector);
        LibString.toHexString(0x4132, 1);
    }

    function testToHexStringFixedLengthUint256Max() public {
        assertEq(
            LibString.toHexString(type(uint256).max, 32),
            "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
        );
    }

    function testToHexStringFixedLengthZeroRightPadded(uint256 x, uint256 randomness) public pure {
        uint256 minLength = (bytes(LibString.toHexString(x)).length - 2) * 2;
        uint256 length = (randomness % 32) + minLength;
        _checkMemory(LibString.toHexString(x, length));
    }

    function testFromAddressToHexString() public {
        assertEq(
            LibString.toHexString(0xA9036907dCcae6a1E0033479B12E837e5cF5a02f),
            "0xa9036907dccae6a1e0033479b12e837e5cf5a02f"
        );
    }

    function testAddressToHexStringZeroRightPadded(address x) public pure {
        _checkMemory(LibString.toHexString(x));
    }

    function testFromAddressToHexStringWithLeadingZeros() public {
        assertEq(
            LibString.toHexString(0x0000E0Ca771e21bD00057F54A68C30D400000000),
            "0x0000e0ca771e21bd00057f54a68c30d400000000"
        );
    }

    function testFromAddressToHexStringChecksumed() public {
        // All caps.
        assertEq(
            LibString.toHexStringChecksumed(0x52908400098527886E0F7030069857D2E4169EE7),
            "0x52908400098527886E0F7030069857D2E4169EE7"
        );
        assertEq(
            LibString.toHexStringChecksumed(0x8617E340B3D01FA5F11F306F4090FD50E238070D),
            "0x8617E340B3D01FA5F11F306F4090FD50E238070D"
        );
        // All lower.
        assertEq(
            LibString.toHexStringChecksumed(0xde709f2102306220921060314715629080e2fb77),
            "0xde709f2102306220921060314715629080e2fb77"
        );
        assertEq(
            LibString.toHexStringChecksumed(0x27b1fdb04752bbc536007a920d24acb045561c26),
            "0x27b1fdb04752bbc536007a920d24acb045561c26"
        );
        // Normal.
        assertEq(
            LibString.toHexStringChecksumed(0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed),
            "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed"
        );
        assertEq(
            LibString.toHexStringChecksumed(0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359),
            "0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359"
        );
        assertEq(
            LibString.toHexStringChecksumed(0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB),
            "0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB"
        );
        assertEq(
            LibString.toHexStringChecksumed(0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb),
            "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb"
        );
    }

    function testFromAddressToHexStringChecksumedDifferential(uint256 randomness)
        public
        brutalizeMemory
    {
        address r;
        /// @solidity memory-safe-assembly
        assembly {
            r := randomness
        }
        string memory expectedResult = LibString.toHexString(r);
        /// @solidity memory-safe-assembly
        assembly {
            let o := add(expectedResult, 0x22)
            let hashed := keccak256(o, 40)
            // forgefmt: disable-next-item
            for { let i := 0 } iszero(eq(i, 20)) { i := add(i, 1) } {
                let temp := byte(i, hashed)
                let p := add(o, add(i, i))
                let c0 := byte(0, mload(p))
                let c1 := byte(1, mload(p))
                if and(gt(c1, 58), gt(and(temp, 15), 7)) {
                    mstore8(add(p, 1), sub(c1, 32))    
                }
                if and(gt(c0, 58), gt(shr(4, temp), 7)) {
                    mstore8(p, sub(c0, 32))    
                }
            }
        }
        string memory checksumed = LibString.toHexStringChecksumed(r);
        _checkMemory(checksumed);
        assertEq(checksumed, expectedResult);
    }

    function testHexStringNoPrefixVariants(uint256 x, uint256 randomness) public brutalizeMemory {
        string memory noPrefix = LibString.toHexStringNoPrefix(x);
        _checkMemory(noPrefix);
        string memory expectedResult = LibString.concat("0x", noPrefix);
        string memory withPrefix = LibString.toHexString(x);
        _checkMemory(withPrefix);
        assertEq(withPrefix, expectedResult);

        uint256 length;
        /// @solidity memory-safe-assembly
        assembly {
            length := add(shr(1, mload(noPrefix)), and(randomness, 63))
        }
        _roundUpFreeMemoryPointer();
        noPrefix = LibString.toHexStringNoPrefix(x, length);
        _checkMemory(noPrefix);
        expectedResult = LibString.concat("0x", noPrefix);
        _roundUpFreeMemoryPointer();
        withPrefix = LibString.toHexString(x, length);
        _checkMemory(withPrefix);
        assertEq(withPrefix, expectedResult);

        address xAddress;
        /// @solidity memory-safe-assembly
        assembly {
            xAddress := x
        }
        _roundUpFreeMemoryPointer();
        noPrefix = LibString.toHexStringNoPrefix(xAddress);
        _checkMemory(noPrefix);
        expectedResult = LibString.concat("0x", noPrefix);
        _roundUpFreeMemoryPointer();
        withPrefix = LibString.toHexString(xAddress);
        _checkMemory(withPrefix);
        assertEq(withPrefix, expectedResult);
    }

    function testBytesToHexStringNoPrefix() public {
        assertEq(LibString.toHexStringNoPrefix(""), "");
        assertEq(LibString.toHexStringNoPrefix("A"), "41");
        assertEq(
            LibString.toHexStringNoPrefix("ABCDEFGHIJKLMNOPQRSTUVWXYZ"),
            "4142434445464748494a4b4c4d4e4f505152535455565758595a"
        );
    }

    function testBytesToHexStringNoPrefix(bytes memory raw) public brutalizeMemory {
        string memory converted = LibString.toHexStringNoPrefix(raw);
        _checkMemory(converted);
        unchecked {
            bytes memory hexChars = "0123456789abcdef";
            for (uint256 i; i != raw.length; ++i) {
                uint256 t = uint8(bytes1(raw[i]));
                assertTrue(hexChars[t & 15] == bytes(converted)[i * 2 + 1]);
                assertTrue(hexChars[(t >> 4) & 15] == bytes(converted)[i * 2]);
            }
        }
    }

    function testBytesToHexString() public {
        assertEq(LibString.toHexString(""), "0x");
        assertEq(LibString.toHexString("A"), "0x41");
        assertEq(
            LibString.toHexString("ABCDEFGHIJKLMNOPQRSTUVWXYZ"),
            "0x4142434445464748494a4b4c4d4e4f505152535455565758595a"
        );
    }

    function testBytesToHexString(bytes memory raw) public brutalizeMemory {
        string memory converted = LibString.toHexString(raw);
        _checkMemory(converted);
        unchecked {
            bytes memory hexChars = "0123456789abcdef";
            for (uint256 i; i != raw.length; ++i) {
                uint256 t = uint8(bytes1(raw[i]));
                assertTrue(hexChars[t & 15] == bytes(converted)[i * 2 + 1 + 2]);
                assertTrue(hexChars[(t >> 4) & 15] == bytes(converted)[i * 2 + 2]);
            }
        }
    }

    function testStringRuneCountDifferential(string memory s) public {
        assertEq(LibString.runeCount(s), _runeCountOriginal(s));
    }

    function testStringRuneCount() public {
        unchecked {
            string memory runes = new string(256);
            for (uint256 i; i < 256; ++i) {
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(add(add(runes, 0x20), i), i)
                }
            }
            for (uint256 i; i < 256; ++i) {
                string memory s = _generateString(runes);
                testStringRuneCountDifferential(s);
            }
        }
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
        // forgefmt: disable-next-item
        string memory subject = "70708741044725766535585242414884609539555049888764130733849700923779599488691391677696419266840";
        string memory search = "46095395550498887641307338497009";
        string memory replacement = "320807383223517906783031356692334377159141";
        // forgefmt: disable-next-item
        string memory expectedResult = "707087410447257665355852424148832080738322351790678303135669233437715914123779599488691391677696419266840";
        assertEq(LibString.replace(subject, search, replacement), expectedResult);
    }

    function testStringReplaceLong() public {
        // forgefmt: disable-next-item
        string memory subject = "01234567890123456789012345678901_search_search_search_search_search_search_23456789012345678901234567890123456789_search_search_search_search_search_search";
        string memory search = "search_search_search_search_search_search";
        string memory replacement = "REPLACEMENT_REPLACEMENT_REPLACEMENT_REPLACEMENT_REPLACEMENT";
        // forgefmt: disable-next-item
        string memory expectedResult = "01234567890123456789012345678901_REPLACEMENT_REPLACEMENT_REPLACEMENT_REPLACEMENT_REPLACEMENT_23456789012345678901234567890123456789_REPLACEMENT_REPLACEMENT_REPLACEMENT_REPLACEMENT_REPLACEMENT";
        assertEq(LibString.replace(subject, search, replacement), expectedResult);
    }

    function testStringReplace(uint256) public brutalizeMemory {
        string memory filler = _generateString("ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        string memory search = _generateString("abcdefghijklmnopqrstuvwxyz");
        string memory replacement = _generateString("0123456790_-+/=|{}<>!");
        if (bytes(search).length != 0) {
            string memory subject = string(
                bytes.concat(
                    bytes(filler), bytes(search), bytes(filler), bytes(search), bytes(filler)
                )
            );
            _roundUpFreeMemoryPointer();
            string memory expectedResult = string(
                bytes.concat(
                    bytes(filler),
                    bytes(replacement),
                    bytes(filler),
                    bytes(replacement),
                    bytes(filler)
                )
            );
            _roundUpFreeMemoryPointer();
            string memory replaced = LibString.replace(subject, search, replacement);
            _checkMemory(replaced);
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

    function testStringIndexOf(uint256) public brutalizeMemory {
        string memory filler0 = _generateString("ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        string memory filler1 = _generateString("ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        string memory search = _generateString("abcdefghijklmnopqrstuvwxyz");

        string memory subject = string(bytes.concat(bytes(filler0), bytes(search), bytes(filler1)));

        uint256 from = _generateFrom(subject);

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
        assertEq(
            LibString.indexOf(subject, "qrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", 17),
            LibString.NOT_FOUND
        );

        assertEq(LibString.indexOf("abcabcabc", "abc"), 0);
        assertEq(LibString.indexOf("abcabcabc", "abc", 1), 3);

        assertEq(LibString.indexOf("a", "bcd"), LibString.NOT_FOUND);
        assertEq(LibString.indexOf("a", "bcd", 0), LibString.NOT_FOUND);
        assertEq(LibString.indexOf("accd", "bcd"), LibString.NOT_FOUND);
        assertEq(LibString.indexOf("", "bcd"), LibString.NOT_FOUND);
    }

    function testStringLastIndexOf(uint256) public brutalizeMemory {
        string memory filler0 = _generateString("ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        string memory filler1 = _generateString("ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        string memory search = _generateString("abcdefghijklmnopqrstuvwxyz");

        string memory subject = string(bytes.concat(bytes(filler0), bytes(search), bytes(filler1)));

        uint256 from = _generateFrom(subject);

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
        assertEq(
            LibString.lastIndexOf(subject, "qrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", 15),
            LibString.NOT_FOUND
        );

        assertEq(LibString.lastIndexOf("abcabcabc", "abc"), 6);
        assertEq(LibString.lastIndexOf("abcabcabc", "abc", 5), 3);

        assertEq(LibString.lastIndexOf("a", "bcd"), LibString.NOT_FOUND);
        assertEq(LibString.lastIndexOf("a", "bcd", 0), LibString.NOT_FOUND);
        assertEq(LibString.lastIndexOf("accd", "bcd"), LibString.NOT_FOUND);
        assertEq(LibString.lastIndexOf("", "bcd"), LibString.NOT_FOUND);
    }

    function testStringStartsWith(uint256) public brutalizeMemory {
        string memory filler = _generateString("ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        string memory search = _generateString("abcdefghijklmnopqrstuvwxyz");

        if (bytes(search).length == 0) {
            string memory subject = string(bytes.concat(bytes(filler), bytes(search)));
            assertEq(LibString.startsWith(subject, search), true);
        }

        if (_random() & 1 == 1) {
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

    function testStringEndsWith(uint256) public brutalizeMemory {
        string memory filler = _generateString("ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        string memory search = _generateString("abcdefghijklmnopqrstuvwxyz");

        if (bytes(search).length == 0) {
            string memory subject = string(bytes.concat(bytes(search), bytes(filler)));
            assertEq(LibString.endsWith(subject, search), true);
        }

        if (_random() & 1 == 1) {
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
        string memory expectedResult = _repeatOriginal(subject, times);
        _checkMemory(repeated);
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

    function testStringSlice(uint256) public brutalizeMemory {
        string memory filler0 = _generateString("ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        string memory expectedResult = _generateString("abcdefghijklmnopqrstuvwxyz");
        string memory filler1 = _generateString("ABCDEFGHIJKLMNOPQRSTUVWXYZ");

        string memory subject =
            string(bytes.concat(bytes(filler0), bytes(expectedResult), bytes(filler1)));

        uint256 start = bytes(filler0).length;
        uint256 end = start + bytes(expectedResult).length;

        _roundUpFreeMemoryPointer();
        string memory slice = LibString.slice(subject, start, end);
        _checkMemory(slice);
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
        assertEq(
            LibString.slice(subject, 1, 51), "bcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXY"
        );
        assertEq(LibString.slice(subject, 11, 41), "lmnopqrstuvwxyzABCDEFGHIJKLMNO");
        assertEq(LibString.slice(subject, 21, 31), "vwxyzABCDE");
        assertEq(LibString.slice(subject, 31, 21), "");
    }

    function testStringIndicesOf(uint256) public brutalizeMemory {
        string memory filler0 = _generateString("ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        string memory filler1 = _generateString("ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        string memory search = _generateString("abcdefghijklmnopqrstuvwxyz");

        string memory subject;

        unchecked {
            uint256[] memory indices;
            if (_random() & 1 == 0) {
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

    function testStringSplit(uint256) public brutalizeMemory {
        string memory filler0 = _generateString("ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        string memory filler1 = _generateString("ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        string memory delimiter = _generateString("abcdefghijklmnopqrstuvwxyz");

        string memory subject =
            string(bytes.concat(bytes(filler0), bytes(delimiter), bytes(filler1)));

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
            assertTrue(_stringArraysAreSame(splitted, elements));
            for (uint256 i; i < splitted.length; ++i) {
                _checkMemory(splitted[i]);
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
        elements[0] = "ab";
        assertTrue(_stringArraysAreSame(LibString.split("ab", " "), elements));

        elements = new string[](1);
        elements[0] = "a";
        assertTrue(_stringArraysAreSame(LibString.split("a", ""), elements));

        elements = new string[](0);
        assertTrue(_stringArraysAreSame(LibString.split("", ""), elements));
    }

    function testStringConcat(string memory a, string memory b) public brutalizeMemory {
        string memory concatenated = LibString.concat(a, b);
        _checkMemory(concatenated);
        string memory expectedResult = string(bytes.concat(bytes(a), bytes(b)));
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

    function testStringEscapeHTML() public {
        assertEq(LibString.escapeHTML(""), "");
        assertEq(LibString.escapeHTML("abc"), "abc");
        assertEq(LibString.escapeHTML('abc"_123'), "abc&quot;_123");
        assertEq(LibString.escapeHTML("abc&_123"), "abc&amp;_123");
        assertEq(LibString.escapeHTML("abc'_123"), "abc&#39;_123");
        assertEq(LibString.escapeHTML("abc<_123"), "abc&lt;_123");
        assertEq(LibString.escapeHTML("abc>_123"), "abc&gt;_123");
    }

    function testStringEscapeHTML(uint256) public brutalizeMemory {
        string[] memory originalChars = new string[](5);
        originalChars[0] = '"';
        originalChars[1] = "&";
        originalChars[2] = "'";
        originalChars[3] = "<";
        originalChars[4] = ">";

        string[] memory escapedChars = new string[](5);
        escapedChars[0] = "&quot;";
        escapedChars[1] = "&amp;";
        escapedChars[2] = "&#39;";
        escapedChars[3] = "&lt;";
        escapedChars[4] = "&gt;";

        string memory filler0 = _generateString("ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        string memory filler1 = _generateString("ABCDEFGHIJKLMNOPQRSTUVWXYZ");

        uint256 r = _random() % 5;

        string memory expectedResult =
            string(bytes.concat(bytes(filler0), bytes(escapedChars[r]), bytes(filler1)));

        string memory input =
            string(bytes.concat(bytes(filler0), bytes(originalChars[r]), bytes(filler1)));

        _roundUpFreeMemoryPointer();
        string memory escaped = LibString.escapeHTML(input);
        _checkMemory(escaped);

        assertEq(expectedResult, escaped);
    }

    function testStringEscapeJSON() public {
        assertEq(LibString.escapeJSON(""), "");
        assertEq(LibString.escapeJSON("abc"), "abc");
        assertEq(LibString.escapeJSON('abc"_123'), 'abc\\"_123');
        assertEq(LibString.escapeJSON("abc\\_123"), "abc\\\\_123");
        assertEq(LibString.escapeJSON("abc\x08_123"), "abc\\b_123");
        assertEq(LibString.escapeJSON("abc\x0c_123"), "abc\\f_123");
        assertEq(LibString.escapeJSON("abc\n_123"), "abc\\n_123");
        assertEq(LibString.escapeJSON("abc\r_123"), "abc\\r_123");
        assertEq(LibString.escapeJSON("abc\t_123"), "abc\\t_123");
    }

    function testStringEscapeJSONHexEncode() public brutalizeMemory {
        unchecked {
            for (uint256 i; i <= 0x1f; ++i) {
                if (i != 0x8 && i != 0x9 && i != 0x0a && i != 0x0c && i != 0x0d) {
                    string memory input =
                        string(bytes.concat(bytes("abc"), bytes1(uint8(i)), bytes("_123")));
                    string memory hexCode = LibString.replace(LibString.toHexString(i), "0x", "00");
                    string memory expectedOutput =
                        string(bytes.concat(bytes("abc\\u"), bytes(hexCode), bytes("_123")));
                    string memory escaped = LibString.escapeJSON(input);
                    _checkMemory(escaped);
                    assertEq(escaped, expectedOutput);
                }
            }
        }
    }

    function testStringEq(string memory a, string memory b) public {
        assertEq(LibString.eq(a, b), keccak256(bytes(a)) == keccak256(bytes(b)));
    }

    function testStringPackAndUnpackOneDifferential(string memory a) public brutalizeMemory {
        a = LibString.slice(a, 0);
        bytes32 packed = LibString.packOne(a);
        unchecked {
            if (bytes(a).length < 32) {
                bytes memory expectedResultBytes = abi.encodePacked(uint8(bytes(a).length), a);
                bytes32 expectedResult;
                /// @solidity memory-safe-assembly
                assembly {
                    expectedResult := mload(add(expectedResultBytes, 0x20))
                }
                assertEq(packed, expectedResult);
            } else {
                assertEq(packed, bytes32(0));
            }
        }
    }

    function testStringPackAndUnpackOne(string memory a) public brutalizeMemory {
        _roundUpFreeMemoryPointer();
        bytes32 packed = LibString.packOne(a);
        string memory unpacked = LibString.unpackOne(packed);
        _checkMemory(unpacked);

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

    function testStringPackAndUnpackTwoDifferential(string memory a, string memory b)
        public
        brutalizeMemory
    {
        a = LibString.slice(a, 0);
        b = LibString.slice(b, 0);
        bytes32 packed = LibString.packTwo(a, b);
        unchecked {
            if (bytes(a).length + bytes(b).length < 31) {
                bytes memory expectedResultBytes =
                    abi.encodePacked(uint8(bytes(a).length), a, uint8(bytes(b).length), b);
                bytes32 expectedResult;
                /// @solidity memory-safe-assembly
                assembly {
                    expectedResult := mload(add(expectedResultBytes, 0x20))
                }
                assertEq(packed, expectedResult);
            } else {
                assertEq(packed, bytes32(0));
            }
        }
    }

    function testStringPackAndUnpackTwo(string memory a, string memory b) public brutalizeMemory {
        bytes32 packed = LibString.packTwo(a, b);
        _roundUpFreeMemoryPointer();
        (string memory unpackedA, string memory unpackedB) = LibString.unpackTwo(packed);
        _checkMemory(unpackedA);
        _checkMemory(unpackedB);

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
    }

    function testStringDirectReturn() public {
        testStringDirectReturn("");
        testStringDirectReturn("aaa");
        testStringDirectReturn("98729");
    }

    function returnString(string memory a) external pure returns (string memory) {
        LibString.directReturn(a);
    }

    function testStringLowerDifferential(string memory s) public {
        string memory expectedResult = _lowerOriginal(s);
        _roundUpFreeMemoryPointer();
        string memory result = LibString.lower(s);
        _checkMemory(result);
        assertEq(result, expectedResult);
    }

    function testStringLowerDifferential() public {
        unchecked {
            string memory ascii = new string(128);
            for (uint256 i; i < 128; ++i) {
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(add(add(ascii, 0x20), i), i)
                }
            }
            for (uint256 i; i < 256; ++i) {
                string memory s = _generateString(ascii);
                testStringLowerDifferential(s);
            }
        }
    }

    function testStringLowerOriginal() public {
        assertEq(_lowerOriginal("@AZ["), "@az[");
    }

    function testStringUpperDifferential(string memory s) public {
        string memory expectedResult = _upperOriginal(s);
        _roundUpFreeMemoryPointer();
        string memory result = LibString.upper(s);
        _checkMemory(result);
        assertEq(result, expectedResult);
    }

    function testStringUpperDifferential() public {
        unchecked {
            string memory ascii = new string(128);
            for (uint256 i; i < 128; ++i) {
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(add(add(ascii, 0x20), i), i)
                }
            }
            for (uint256 i; i < 256; ++i) {
                string memory s = _generateString(ascii);
                testStringUpperDifferential(s);
            }
        }
    }

    function testStringUpperOriginal() public {
        assertEq(_upperOriginal("`az}"), "`AZ}");
    }

    function _lowerOriginal(string memory subject) internal pure returns (string memory result) {
        unchecked {
            uint256 n = bytes(subject).length;
            result = new string(n);
            for (uint256 i; i != n; ++i) {
                /// @solidity memory-safe-assembly
                assembly {
                    let b := byte(0, mload(add(add(subject, 0x20), i)))
                    mstore8(
                        add(add(result, 0x20), i), add(b, mul(0x20, and(lt(0x40, b), lt(b, 0x5b))))
                    )
                }
            }
        }
    }

    function _upperOriginal(string memory subject) internal pure returns (string memory result) {
        unchecked {
            uint256 n = bytes(subject).length;
            result = new string(n);
            for (uint256 i; i != n; ++i) {
                /// @solidity memory-safe-assembly
                assembly {
                    let b := byte(0, mload(add(add(subject, 0x20), i)))
                    mstore8(
                        add(add(result, 0x20), i), sub(b, mul(0x20, and(lt(0x60, b), lt(b, 0x7b))))
                    )
                }
            }
        }
    }

    function _runeCountOriginal(string memory s) internal pure returns (uint256) {
        unchecked {
            uint256 len;
            uint256 i = 0;
            uint256 bytelength = bytes(s).length;
            for (len = 0; i < bytelength; len++) {
                bytes1 b = bytes(s)[i];
                if (b < 0x80) {
                    i += 1;
                } else if (b < 0xE0) {
                    i += 2;
                } else if (b < 0xF0) {
                    i += 3;
                } else if (b < 0xF8) {
                    i += 4;
                } else if (b < 0xFC) {
                    i += 5;
                } else {
                    i += 6;
                }
            }
            return len;
        }
    }

    function _repeatOriginal(string memory subject, uint256 times)
        internal
        pure
        returns (string memory)
    {
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

    function _generateFrom(string memory subject) internal view returns (uint256) {
        unchecked {
            if (_random() % 8 == 0) {
                return _random() << (_random() & 255);
            }
            return _random() % (bytes(subject).length + 10);
        }
    }

    function _generateString(string memory byteChoices)
        internal
        view
        returns (string memory result)
    {
        uint256 randomness = _random();
        uint256 resultLength = _randomStringLength();
        /// @solidity memory-safe-assembly
        assembly {
            if mload(byteChoices) {
                result := mload(0x40)
                mstore(0x00, randomness)
                mstore(0x40, and(add(add(result, 0x40), resultLength), not(31)))
                mstore(result, resultLength)

                // forgefmt: disable-next-item
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

    function _randomStringLength() internal view returns (uint256 r) {
        r = _random() % 256;
        if (r < 64) return _random() % 128;
        if (r < 128) return _random() % 64;
        return _random() % 16;
    }

    function _stringArraysAreSame(string[] memory a, string[] memory b)
        internal
        pure
        returns (bool)
    {
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
