// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {SafeCastLib} from "../src/utils/SafeCastLib.sol";

contract SafeCastLibTest is SoladyTest {
    function testSafeCastUintToUint(uint256 x, uint256 r) public {
        do {
            r = r % 31;
            if (r == 0) {
                assertEq(SafeCastLib.toUint8(uint8(x)), uint8(x));
                if (x >= 1 << 8) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint8(x);
                } else {
                    assertEq(SafeCastLib.toUint8(x), uint8(x));
                }
            }
            if (r == 1) {
                assertEq(SafeCastLib.toUint16(uint16(x)), uint16(x));
                if (x >= 1 << 16) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint16(x);
                } else {
                    assertEq(SafeCastLib.toUint16(x), uint16(x));
                }
            }
            if (r == 2) {
                assertEq(SafeCastLib.toUint24(uint24(x)), uint24(x));
                if (x >= 1 << 24) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint24(x);
                } else {
                    assertEq(SafeCastLib.toUint24(x), uint24(x));
                }
            }
            if (r == 3) {
                assertEq(SafeCastLib.toUint32(uint32(x)), uint32(x));
                if (x >= 1 << 32) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint32(x);
                } else {
                    assertEq(SafeCastLib.toUint32(x), uint32(x));
                }
            }
            if (r == 4) {
                assertEq(SafeCastLib.toUint40(uint40(x)), uint40(x));
                if (x >= 1 << 40) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint40(x);
                } else {
                    assertEq(SafeCastLib.toUint40(x), uint40(x));
                }
            }
            if (r == 5) {
                assertEq(SafeCastLib.toUint48(uint48(x)), uint48(x));
                if (x >= 1 << 48) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint48(x);
                } else {
                    assertEq(SafeCastLib.toUint48(x), uint48(x));
                }
            }
            if (r == 6) {
                assertEq(SafeCastLib.toUint56(uint56(x)), uint56(x));
                if (x >= 1 << 56) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint56(x);
                } else {
                    assertEq(SafeCastLib.toUint56(x), uint56(x));
                }
            }
            if (r == 7) {
                assertEq(SafeCastLib.toUint64(uint64(x)), uint64(x));
                if (x >= 1 << 64) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint64(x);
                } else {
                    assertEq(SafeCastLib.toUint64(x), uint64(x));
                }
            }
            if (r == 8) {
                assertEq(SafeCastLib.toUint72(uint72(x)), uint72(x));
                if (x >= 1 << 72) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint72(x);
                } else {
                    assertEq(SafeCastLib.toUint72(x), uint72(x));
                }
            }
            if (r == 9) {
                assertEq(SafeCastLib.toUint80(uint80(x)), uint80(x));
                if (x >= 1 << 80) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint80(x);
                } else {
                    assertEq(SafeCastLib.toUint80(x), uint80(x));
                }
            }
            if (r == 10) {
                assertEq(SafeCastLib.toUint88(uint88(x)), uint88(x));
                if (x >= 1 << 88) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint88(x);
                } else {
                    assertEq(SafeCastLib.toUint88(x), uint88(x));
                }
            }
            if (r == 11) {
                assertEq(SafeCastLib.toUint96(uint96(x)), uint96(x));
                if (x >= 1 << 96) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint96(x);
                } else {
                    assertEq(SafeCastLib.toUint96(x), uint96(x));
                }
            }
            if (r == 12) {
                assertEq(SafeCastLib.toUint104(uint104(x)), uint104(x));
                if (x >= 1 << 104) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint104(x);
                } else {
                    assertEq(SafeCastLib.toUint104(x), uint104(x));
                }
            }
            if (r == 13) {
                assertEq(SafeCastLib.toUint112(uint112(x)), uint112(x));
                if (x >= 1 << 112) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint112(x);
                } else {
                    assertEq(SafeCastLib.toUint112(x), uint112(x));
                }
            }
            if (r == 14) {
                assertEq(SafeCastLib.toUint120(uint120(x)), uint120(x));
                if (x >= 1 << 120) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint120(x);
                } else {
                    assertEq(SafeCastLib.toUint120(x), uint120(x));
                }
            }
            if (r == 15) {
                assertEq(SafeCastLib.toUint128(uint128(x)), uint128(x));
                if (x >= 1 << 128) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint128(x);
                } else {
                    assertEq(SafeCastLib.toUint128(x), uint128(x));
                }
            }
            if (r == 16) {
                assertEq(SafeCastLib.toUint136(uint136(x)), uint136(x));
                if (x >= 1 << 136) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint136(x);
                } else {
                    assertEq(SafeCastLib.toUint136(x), uint136(x));
                }
            }
            if (r == 17) {
                assertEq(SafeCastLib.toUint144(uint144(x)), uint144(x));
                if (x >= 1 << 144) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint144(x);
                } else {
                    assertEq(SafeCastLib.toUint144(x), uint144(x));
                }
            }
            if (r == 18) {
                assertEq(SafeCastLib.toUint152(uint152(x)), uint152(x));
                if (x >= 1 << 152) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint152(x);
                } else {
                    assertEq(SafeCastLib.toUint152(x), uint152(x));
                }
            }
            if (r == 19) {
                assertEq(SafeCastLib.toUint160(uint160(x)), uint160(x));
                if (x >= 1 << 160) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint160(x);
                } else {
                    assertEq(SafeCastLib.toUint160(x), uint160(x));
                }
            }
            if (r == 20) {
                assertEq(SafeCastLib.toUint168(uint168(x)), uint168(x));
                if (x >= 1 << 168) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint168(x);
                } else {
                    assertEq(SafeCastLib.toUint168(x), uint168(x));
                }
            }
            if (r == 21) {
                assertEq(SafeCastLib.toUint176(uint176(x)), uint176(x));
                if (x >= 1 << 176) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint176(x);
                } else {
                    assertEq(SafeCastLib.toUint176(x), uint176(x));
                }
            }
            if (r == 22) {
                assertEq(SafeCastLib.toUint184(uint184(x)), uint184(x));
                if (x >= 1 << 184) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint184(x);
                } else {
                    assertEq(SafeCastLib.toUint184(x), uint184(x));
                }
            }
            if (r == 23) {
                assertEq(SafeCastLib.toUint192(uint192(x)), uint192(x));
                if (x >= 1 << 192) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint192(x);
                } else {
                    assertEq(SafeCastLib.toUint192(x), uint192(x));
                }
            }
            if (r == 24) {
                assertEq(SafeCastLib.toUint200(uint200(x)), uint200(x));
                if (x >= 1 << 200) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint200(x);
                } else {
                    assertEq(SafeCastLib.toUint200(x), uint200(x));
                }
            }
            if (r == 25) {
                assertEq(SafeCastLib.toUint208(uint208(x)), uint208(x));
                if (x >= 1 << 208) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint208(x);
                } else {
                    assertEq(SafeCastLib.toUint208(x), uint208(x));
                }
            }
            if (r == 26) {
                assertEq(SafeCastLib.toUint216(uint216(x)), uint216(x));
                if (x >= 1 << 216) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint216(x);
                } else {
                    assertEq(SafeCastLib.toUint216(x), uint216(x));
                }
            }
            if (r == 27) {
                assertEq(SafeCastLib.toUint224(uint224(x)), uint224(x));
                if (x >= 1 << 224) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint224(x);
                } else {
                    assertEq(SafeCastLib.toUint224(x), uint224(x));
                }
            }
            if (r == 28) {
                assertEq(SafeCastLib.toUint232(uint232(x)), uint232(x));
                if (x >= 1 << 232) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint232(x);
                } else {
                    assertEq(SafeCastLib.toUint232(x), uint232(x));
                }
            }
            if (r == 29) {
                assertEq(SafeCastLib.toUint240(uint240(x)), uint240(x));
                if (x >= 1 << 240) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint240(x);
                } else {
                    assertEq(SafeCastLib.toUint240(x), uint240(x));
                }
            }
            if (r == 30) {
                assertEq(SafeCastLib.toUint248(uint248(x)), uint248(x));
                if (x >= 1 << 248) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toUint248(x);
                } else {
                    assertEq(SafeCastLib.toUint248(x), uint248(x));
                }
            }
            r = _random();
            x = _random();
        } while (_random() % 2 == 0);
    }

    function testSafeCastToUintBench() public {
        unchecked {
            uint256 sum;
            for (uint256 i; i != 127; ++i) {
                sum += uint256(SafeCastLib.toUint8(i));
                sum += uint256(SafeCastLib.toUint16(i));
                sum += uint256(SafeCastLib.toUint24(i));
                sum += uint256(SafeCastLib.toUint32(i));
                sum += uint256(SafeCastLib.toUint40(i));
                sum += uint256(SafeCastLib.toUint48(i));
                sum += uint256(SafeCastLib.toUint56(i));
                sum += uint256(SafeCastLib.toUint64(i));
                sum += uint256(SafeCastLib.toUint72(i));
                sum += uint256(SafeCastLib.toUint80(i));
                sum += uint256(SafeCastLib.toUint88(i));
                sum += uint256(SafeCastLib.toUint96(i));
                sum += uint256(SafeCastLib.toUint104(i));
                sum += uint256(SafeCastLib.toUint112(i));
                sum += uint256(SafeCastLib.toUint120(i));
                sum += uint256(SafeCastLib.toUint128(i));
                sum += uint256(SafeCastLib.toUint136(i));
                sum += uint256(SafeCastLib.toUint144(i));
                sum += uint256(SafeCastLib.toUint152(i));
                sum += uint256(SafeCastLib.toUint160(i));
                sum += uint256(SafeCastLib.toUint168(i));
                sum += uint256(SafeCastLib.toUint176(i));
                sum += uint256(SafeCastLib.toUint184(i));
                sum += uint256(SafeCastLib.toUint192(i));
                sum += uint256(SafeCastLib.toUint200(i));
                sum += uint256(SafeCastLib.toUint208(i));
                sum += uint256(SafeCastLib.toUint216(i));
                sum += uint256(SafeCastLib.toUint224(i));
                sum += uint256(SafeCastLib.toUint232(i));
                sum += uint256(SafeCastLib.toUint240(i));
                sum += uint256(SafeCastLib.toUint248(i));
            }
            assertTrue(sum > 100);
        }
    }

    function testSafeCastInt256ToInt(int256 x, uint256 r) public {
        do {
            r = r % 31;
            if (r == 0) {
                assertEq(SafeCastLib.toInt8(int8(x)), int8(x));
                if (int8(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt8(x);
                } else {
                    assertEq(SafeCastLib.toInt8(x), int8(x));
                }
            }
            if (r == 1) {
                assertEq(SafeCastLib.toInt16(int16(x)), int16(x));
                if (int16(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt16(x);
                } else {
                    assertEq(SafeCastLib.toInt16(x), int16(x));
                }
            }
            if (r == 2) {
                assertEq(SafeCastLib.toInt24(int24(x)), int24(x));
                if (int24(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt24(x);
                } else {
                    assertEq(SafeCastLib.toInt24(x), int24(x));
                }
            }
            if (r == 3) {
                assertEq(SafeCastLib.toInt32(int32(x)), int32(x));
                if (int32(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt32(x);
                } else {
                    assertEq(SafeCastLib.toInt32(x), int32(x));
                }
            }
            if (r == 4) {
                assertEq(SafeCastLib.toInt40(int40(x)), int40(x));
                if (int40(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt40(x);
                } else {
                    assertEq(SafeCastLib.toInt40(x), int40(x));
                }
            }
            if (r == 5) {
                assertEq(SafeCastLib.toInt48(int48(x)), int48(x));
                if (int48(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt48(x);
                } else {
                    assertEq(SafeCastLib.toInt48(x), int48(x));
                }
            }
            if (r == 6) {
                assertEq(SafeCastLib.toInt56(int56(x)), int56(x));
                if (int56(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt56(x);
                } else {
                    assertEq(SafeCastLib.toInt56(x), int56(x));
                }
            }
            if (r == 7) {
                assertEq(SafeCastLib.toInt64(int64(x)), int64(x));
                if (int64(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt64(x);
                } else {
                    assertEq(SafeCastLib.toInt64(x), int64(x));
                }
            }
            if (r == 8) {
                assertEq(SafeCastLib.toInt72(int72(x)), int72(x));
                if (int72(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt72(x);
                } else {
                    assertEq(SafeCastLib.toInt72(x), int72(x));
                }
            }
            if (r == 9) {
                assertEq(SafeCastLib.toInt80(int80(x)), int80(x));
                if (int80(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt80(x);
                } else {
                    assertEq(SafeCastLib.toInt80(x), int80(x));
                }
            }
            if (r == 10) {
                assertEq(SafeCastLib.toInt88(int88(x)), int88(x));
                if (int88(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt88(x);
                } else {
                    assertEq(SafeCastLib.toInt88(x), int88(x));
                }
            }
            if (r == 11) {
                assertEq(SafeCastLib.toInt96(int96(x)), int96(x));
                if (int96(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt96(x);
                } else {
                    assertEq(SafeCastLib.toInt96(x), int96(x));
                }
            }
            if (r == 12) {
                assertEq(SafeCastLib.toInt104(int104(x)), int104(x));
                if (int104(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt104(x);
                } else {
                    assertEq(SafeCastLib.toInt104(x), int104(x));
                }
            }
            if (r == 13) {
                assertEq(SafeCastLib.toInt112(int112(x)), int112(x));
                if (int112(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt112(x);
                } else {
                    assertEq(SafeCastLib.toInt112(x), int112(x));
                }
            }
            if (r == 14) {
                assertEq(SafeCastLib.toInt120(int120(x)), int120(x));
                if (int120(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt120(x);
                } else {
                    assertEq(SafeCastLib.toInt120(x), int120(x));
                }
            }
            if (r == 15) {
                assertEq(SafeCastLib.toInt128(int128(x)), int128(x));
                if (int128(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt128(x);
                } else {
                    assertEq(SafeCastLib.toInt128(x), int128(x));
                }
            }
            if (r == 16) {
                assertEq(SafeCastLib.toInt136(int136(x)), int136(x));
                if (int136(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt136(x);
                } else {
                    assertEq(SafeCastLib.toInt136(x), int136(x));
                }
            }
            if (r == 17) {
                assertEq(SafeCastLib.toInt144(int144(x)), int144(x));
                if (int144(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt144(x);
                } else {
                    assertEq(SafeCastLib.toInt144(x), int144(x));
                }
            }
            if (r == 18) {
                assertEq(SafeCastLib.toInt152(int152(x)), int152(x));
                if (int152(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt152(x);
                } else {
                    assertEq(SafeCastLib.toInt152(x), int152(x));
                }
            }
            if (r == 19) {
                assertEq(SafeCastLib.toInt160(int160(x)), int160(x));
                if (int160(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt160(x);
                } else {
                    assertEq(SafeCastLib.toInt160(x), int160(x));
                }
            }
            if (r == 20) {
                assertEq(SafeCastLib.toInt168(int168(x)), int168(x));
                if (int168(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt168(x);
                } else {
                    assertEq(SafeCastLib.toInt168(x), int168(x));
                }
            }
            if (r == 21) {
                assertEq(SafeCastLib.toInt176(int176(x)), int176(x));
                if (int176(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt176(x);
                } else {
                    assertEq(SafeCastLib.toInt176(x), int176(x));
                }
            }
            if (r == 22) {
                assertEq(SafeCastLib.toInt184(int184(x)), int184(x));
                if (int184(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt184(x);
                } else {
                    assertEq(SafeCastLib.toInt184(x), int184(x));
                }
            }
            if (r == 23) {
                assertEq(SafeCastLib.toInt192(int192(x)), int192(x));
                if (int192(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt192(x);
                } else {
                    assertEq(SafeCastLib.toInt192(x), int192(x));
                }
            }
            if (r == 24) {
                assertEq(SafeCastLib.toInt200(int200(x)), int200(x));
                if (int200(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt200(x);
                } else {
                    assertEq(SafeCastLib.toInt200(x), int200(x));
                }
            }
            if (r == 25) {
                assertEq(SafeCastLib.toInt208(int208(x)), int208(x));
                if (int208(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt208(x);
                } else {
                    assertEq(SafeCastLib.toInt208(x), int208(x));
                }
            }
            if (r == 26) {
                assertEq(SafeCastLib.toInt216(int216(x)), int216(x));
                if (int216(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt216(x);
                } else {
                    assertEq(SafeCastLib.toInt216(x), int216(x));
                }
            }
            if (r == 27) {
                assertEq(SafeCastLib.toInt224(int224(x)), int224(x));
                if (int224(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt224(x);
                } else {
                    assertEq(SafeCastLib.toInt224(x), int224(x));
                }
            }
            if (r == 28) {
                assertEq(SafeCastLib.toInt232(int232(x)), int232(x));
                if (int232(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt232(x);
                } else {
                    assertEq(SafeCastLib.toInt232(x), int232(x));
                }
            }
            if (r == 29) {
                assertEq(SafeCastLib.toInt240(int240(x)), int240(x));
                if (int240(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt240(x);
                } else {
                    assertEq(SafeCastLib.toInt240(x), int240(x));
                }
            }
            if (r == 30) {
                assertEq(SafeCastLib.toInt248(int248(x)), int248(x));
                if (int248(x) != x) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt248(x);
                } else {
                    assertEq(SafeCastLib.toInt248(x), int248(x));
                }
            }
            r = _random();
            x = int256(_random());
        } while (_random() % 2 == 0);
    }

    function testSafeCastUint256ToInt(uint256 x, uint256 r) public {
        do {
            r = _random() % 31;
            if (r == 0) {
                assertEq(SafeCastLib.toInt8(int256(int8(int256(x)))), int256(int8(int256(x))));
                if (x >= 1 << 7) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt8(x);
                } else {
                    assertEq(SafeCastLib.toInt8(x), int8(int256(x)));
                }
            }
            if (r == 1) {
                assertEq(SafeCastLib.toInt16(int256(int16(int256(x)))), int256(int16(int256(x))));
                if (x >= 1 << 15) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt16(x);
                } else {
                    assertEq(SafeCastLib.toInt16(x), int16(int256(x)));
                }
            }
            if (r == 2) {
                assertEq(SafeCastLib.toInt24(int256(int24(int256(x)))), int256(int24(int256(x))));
                if (x >= 1 << 23) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt24(x);
                } else {
                    assertEq(SafeCastLib.toInt24(x), int24(int256(x)));
                }
            }
            if (r == 3) {
                assertEq(SafeCastLib.toInt32(int256(int32(int256(x)))), int256(int32(int256(x))));
                if (x >= 1 << 31) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt32(x);
                } else {
                    assertEq(SafeCastLib.toInt32(x), int32(int256(x)));
                }
            }
            if (r == 4) {
                assertEq(SafeCastLib.toInt40(int256(int40(int256(x)))), int256(int40(int256(x))));
                if (x >= 1 << 39) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt40(x);
                } else {
                    assertEq(SafeCastLib.toInt40(x), int40(int256(x)));
                }
            }
            if (r == 5) {
                assertEq(SafeCastLib.toInt48(int256(int48(int256(x)))), int256(int48(int256(x))));
                if (x >= 1 << 47) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt48(x);
                } else {
                    assertEq(SafeCastLib.toInt48(x), int48(int256(x)));
                }
            }
            if (r == 6) {
                assertEq(SafeCastLib.toInt56(int256(int56(int256(x)))), int256(int56(int256(x))));
                if (x >= 1 << 55) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt56(x);
                } else {
                    assertEq(SafeCastLib.toInt56(x), int56(int256(x)));
                }
            }
            if (r == 7) {
                assertEq(SafeCastLib.toInt64(int256(int64(int256(x)))), int256(int64(int256(x))));
                if (x >= 1 << 63) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt64(x);
                } else {
                    assertEq(SafeCastLib.toInt64(x), int64(int256(x)));
                }
            }
            if (r == 8) {
                assertEq(SafeCastLib.toInt72(int256(int72(int256(x)))), int256(int72(int256(x))));
                if (x >= 1 << 71) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt72(x);
                } else {
                    assertEq(SafeCastLib.toInt72(x), int72(int256(x)));
                }
            }
            if (r == 9) {
                assertEq(SafeCastLib.toInt80(int256(int80(int256(x)))), int256(int80(int256(x))));
                if (x >= 1 << 79) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt80(x);
                } else {
                    assertEq(SafeCastLib.toInt80(x), int80(int256(x)));
                }
            }
            if (r == 10) {
                assertEq(SafeCastLib.toInt88(int256(int88(int256(x)))), int256(int88(int256(x))));
                if (x >= 1 << 87) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt88(x);
                } else {
                    assertEq(SafeCastLib.toInt88(x), int88(int256(x)));
                }
            }
            if (r == 11) {
                assertEq(SafeCastLib.toInt96(int256(int96(int256(x)))), int256(int96(int256(x))));
                if (x >= 1 << 95) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt96(x);
                } else {
                    assertEq(SafeCastLib.toInt96(x), int96(int256(x)));
                }
            }
            if (r == 12) {
                assertEq(SafeCastLib.toInt104(int256(int104(int256(x)))), int256(int104(int256(x))));
                if (x >= 1 << 103) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt104(x);
                } else {
                    assertEq(SafeCastLib.toInt104(x), int104(int256(x)));
                }
            }
            if (r == 13) {
                assertEq(SafeCastLib.toInt112(int256(int112(int256(x)))), int256(int112(int256(x))));
                if (x >= 1 << 111) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt112(x);
                } else {
                    assertEq(SafeCastLib.toInt112(x), int112(int256(x)));
                }
            }
            if (r == 14) {
                assertEq(SafeCastLib.toInt120(int256(int120(int256(x)))), int256(int120(int256(x))));
                if (x >= 1 << 119) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt120(x);
                } else {
                    assertEq(SafeCastLib.toInt120(x), int120(int256(x)));
                }
            }
            if (r == 15) {
                assertEq(SafeCastLib.toInt128(int256(int128(int256(x)))), int256(int128(int256(x))));
                if (x >= 1 << 127) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt128(x);
                } else {
                    assertEq(SafeCastLib.toInt128(x), int128(int256(x)));
                }
            }
            if (r == 16) {
                assertEq(SafeCastLib.toInt136(int256(int136(int256(x)))), int256(int136(int256(x))));
                if (x >= 1 << 135) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt136(x);
                } else {
                    assertEq(SafeCastLib.toInt136(x), int136(int256(x)));
                }
            }
            if (r == 17) {
                assertEq(SafeCastLib.toInt144(int256(int144(int256(x)))), int256(int144(int256(x))));
                if (x >= 1 << 143) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt144(x);
                } else {
                    assertEq(SafeCastLib.toInt144(x), int144(int256(x)));
                }
            }
            if (r == 18) {
                assertEq(SafeCastLib.toInt152(int256(int152(int256(x)))), int256(int152(int256(x))));
                if (x >= 1 << 151) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt152(x);
                } else {
                    assertEq(SafeCastLib.toInt152(x), int152(int256(x)));
                }
            }
            if (r == 19) {
                assertEq(SafeCastLib.toInt160(int256(int160(int256(x)))), int256(int160(int256(x))));
                if (x >= 1 << 159) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt160(x);
                } else {
                    assertEq(SafeCastLib.toInt160(x), int160(int256(x)));
                }
            }
            if (r == 20) {
                assertEq(SafeCastLib.toInt168(int256(int168(int256(x)))), int256(int168(int256(x))));
                if (x >= 1 << 167) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt168(x);
                } else {
                    assertEq(SafeCastLib.toInt168(x), int168(int256(x)));
                }
            }
            if (r == 21) {
                assertEq(SafeCastLib.toInt176(int256(int176(int256(x)))), int256(int176(int256(x))));
                if (x >= 1 << 175) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt176(x);
                } else {
                    assertEq(SafeCastLib.toInt176(x), int176(int256(x)));
                }
            }
            if (r == 22) {
                assertEq(SafeCastLib.toInt184(int256(int184(int256(x)))), int256(int184(int256(x))));
                if (x >= 1 << 183) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt184(x);
                } else {
                    assertEq(SafeCastLib.toInt184(x), int184(int256(x)));
                }
            }
            if (r == 23) {
                assertEq(SafeCastLib.toInt192(int256(int192(int256(x)))), int256(int192(int256(x))));
                if (x >= 1 << 191) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt192(x);
                } else {
                    assertEq(SafeCastLib.toInt192(x), int192(int256(x)));
                }
            }
            if (r == 24) {
                assertEq(SafeCastLib.toInt200(int256(int200(int256(x)))), int256(int200(int256(x))));
                if (x >= 1 << 199) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt200(x);
                } else {
                    assertEq(SafeCastLib.toInt200(x), int200(int256(x)));
                }
            }
            if (r == 25) {
                assertEq(SafeCastLib.toInt208(int256(int208(int256(x)))), int256(int208(int256(x))));
                if (x >= 1 << 207) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt208(x);
                } else {
                    assertEq(SafeCastLib.toInt208(x), int208(int256(x)));
                }
            }
            if (r == 26) {
                assertEq(SafeCastLib.toInt216(int256(int216(int256(x)))), int256(int216(int256(x))));
                if (x >= 1 << 215) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt216(x);
                } else {
                    assertEq(SafeCastLib.toInt216(x), int216(int256(x)));
                }
            }
            if (r == 27) {
                assertEq(SafeCastLib.toInt224(int256(int224(int256(x)))), int256(int224(int256(x))));
                if (x >= 1 << 223) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt224(x);
                } else {
                    assertEq(SafeCastLib.toInt224(x), int224(int256(x)));
                }
            }
            if (r == 28) {
                assertEq(SafeCastLib.toInt232(int256(int232(int256(x)))), int256(int232(int256(x))));
                if (x >= 1 << 231) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt232(x);
                } else {
                    assertEq(SafeCastLib.toInt232(x), int232(int256(x)));
                }
            }
            if (r == 29) {
                assertEq(SafeCastLib.toInt240(int256(int240(int256(x)))), int256(int240(int256(x))));
                if (x >= 1 << 239) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt240(x);
                } else {
                    assertEq(SafeCastLib.toInt240(x), int240(int256(x)));
                }
            }
            if (r == 30) {
                assertEq(SafeCastLib.toInt248(int256(int248(int256(x)))), int256(int248(int256(x))));
                if (x >= 1 << 247) {
                    vm.expectRevert(SafeCastLib.Overflow.selector);
                    SafeCastLib.toInt248(x);
                } else {
                    assertEq(SafeCastLib.toInt248(x), int248(int256(x)));
                }
            }
            r = _random();
            x = _random();
        } while (_random() % 2 == 0);
    }

    function testSafeCastToInt256(uint256 x) public {
        if (x > uint256(type(int256).max)) {
            vm.expectRevert(SafeCastLib.Overflow.selector);
            SafeCastLib.toInt256(x);
        } else {
            assertEq(SafeCastLib.toInt256(x), int256(x));
        }
    }

    function testSafeCastToUint256(int256 x) public {
        if (x < 0) {
            vm.expectRevert(SafeCastLib.Overflow.selector);
            SafeCastLib.toUint256(x);
        } else {
            assertEq(SafeCastLib.toUint256(x), uint256(x));
        }
    }

    function testSafeCastToIntBench() public {
        unchecked {
            int256 sum;
            for (int256 i; i != 127; ++i) {
                sum += int256(SafeCastLib.toInt8(i));
                sum += int256(SafeCastLib.toInt16(i));
                sum += int256(SafeCastLib.toInt24(i));
                sum += int256(SafeCastLib.toInt32(i));
                sum += int256(SafeCastLib.toInt40(i));
                sum += int256(SafeCastLib.toInt48(i));
                sum += int256(SafeCastLib.toInt56(i));
                sum += int256(SafeCastLib.toInt64(i));
                sum += int256(SafeCastLib.toInt72(i));
                sum += int256(SafeCastLib.toInt80(i));
                sum += int256(SafeCastLib.toInt88(i));
                sum += int256(SafeCastLib.toInt96(i));
                sum += int256(SafeCastLib.toInt104(i));
                sum += int256(SafeCastLib.toInt112(i));
                sum += int256(SafeCastLib.toInt120(i));
                sum += int256(SafeCastLib.toInt128(i));
                sum += int256(SafeCastLib.toInt136(i));
                sum += int256(SafeCastLib.toInt144(i));
                sum += int256(SafeCastLib.toInt152(i));
                sum += int256(SafeCastLib.toInt160(i));
                sum += int256(SafeCastLib.toInt168(i));
                sum += int256(SafeCastLib.toInt176(i));
                sum += int256(SafeCastLib.toInt184(i));
                sum += int256(SafeCastLib.toInt192(i));
                sum += int256(SafeCastLib.toInt200(i));
                sum += int256(SafeCastLib.toInt208(i));
                sum += int256(SafeCastLib.toInt216(i));
                sum += int256(SafeCastLib.toInt224(i));
                sum += int256(SafeCastLib.toInt232(i));
                sum += int256(SafeCastLib.toInt240(i));
                sum += int256(SafeCastLib.toInt248(i));
            }
            assertTrue(sum > 100);
        }
    }
}
