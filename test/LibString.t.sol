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

    function testFromAddressToHexString() public {
        assertEq(
            keccak256(bytes(LibString.toHexString(address(0xA9036907dCcae6a1E0033479B12E837e5cF5a02f)))),
            keccak256(bytes("0xa9036907dccae6a1e0033479b12e837e5cf5a02f"))
        );
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

    function testStringReplace(uint256 randomness, bytes calldata brutalizeWith) public brutalizeMemory(brutalizeWith) {
        string memory filler = _generateString(randomness, "ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        string memory search = _generateString(randomness, "abcdefghijklmnopqrstuvwxyz");
        string memory replacement = _generateString(randomness, "0123456790_-+/=|{}<>!");
        if (bytes(search).length != 0) {
            string memory subject = string(
                bytes.concat(bytes(filler), bytes(search), bytes(filler), bytes(search), bytes(filler))
            );
            string memory expectedResult = string(
                bytes.concat(bytes(filler), bytes(replacement), bytes(filler), bytes(replacement), bytes(filler))
            );
            assertEq(LibString.replace(subject, search, replacement), expectedResult);
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
            assertEq(LibString.replace("   ", search, replacement), expectedResult);
        }
    }

    function testIndexOf(uint256 randomness, bytes calldata brutalizeWith) public brutalizeMemory(brutalizeWith) {
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

    function testIndexOf() public {
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

        assertEq(LibString.indexOf("a", "bcd"), LibString.NOT_FOUND);
        assertEq(LibString.indexOf("a", "bcd", 0), LibString.NOT_FOUND);
        assertEq(LibString.indexOf("accd", "bcd"), LibString.NOT_FOUND);
        assertEq(LibString.indexOf("", "bcd"), LibString.NOT_FOUND);
    }

    function testLastIndexOf(uint256 randomness, bytes calldata brutalizeWith) public brutalizeMemory(brutalizeWith) {
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

    function testLastIndexOf() public {
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

        assertEq(LibString.lastIndexOf("a", "bcd"), LibString.NOT_FOUND);
        assertEq(LibString.lastIndexOf("a", "bcd", 0), LibString.NOT_FOUND);
        assertEq(LibString.lastIndexOf("accd", "bcd"), LibString.NOT_FOUND);
        assertEq(LibString.lastIndexOf("", "bcd"), LibString.NOT_FOUND);
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
}
