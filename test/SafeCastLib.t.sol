// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {SafeCastLib} from "../src/utils/SafeCastLib.sol";

contract SafeCastLibTest is SoladyTest {
    function testSafeCastToUint(uint256 x) public {
        assertEq(SafeCastLib.toUint8(uint8(x)), uint8(x));
        if (x >= (1 << 8)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint8(x);
        assertEq(SafeCastLib.toUint16(uint16(x)), uint16(x));
        if (x >= (1 << 16)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint16(x);
        assertEq(SafeCastLib.toUint24(uint24(x)), uint24(x));
        if (x >= (1 << 24)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint24(x);
        assertEq(SafeCastLib.toUint32(uint32(x)), uint32(x));
        if (x >= (1 << 32)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint32(x);
        assertEq(SafeCastLib.toUint40(uint40(x)), uint40(x));
        if (x >= (1 << 40)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint40(x);
        assertEq(SafeCastLib.toUint48(uint48(x)), uint48(x));
        if (x >= (1 << 48)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint48(x);
        assertEq(SafeCastLib.toUint56(uint56(x)), uint56(x));
        if (x >= (1 << 56)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint56(x);
        assertEq(SafeCastLib.toUint64(uint64(x)), uint64(x));
        if (x >= (1 << 64)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint64(x);
        assertEq(SafeCastLib.toUint72(uint72(x)), uint72(x));
        if (x >= (1 << 72)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint72(x);
        assertEq(SafeCastLib.toUint80(uint80(x)), uint80(x));
        if (x >= (1 << 80)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint80(x);
        assertEq(SafeCastLib.toUint88(uint88(x)), uint88(x));
        if (x >= (1 << 88)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint88(x);
        assertEq(SafeCastLib.toUint96(uint96(x)), uint96(x));
        if (x >= (1 << 96)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint96(x);
        assertEq(SafeCastLib.toUint104(uint104(x)), uint104(x));
        if (x >= (1 << 104)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint104(x);
        assertEq(SafeCastLib.toUint112(uint112(x)), uint112(x));
        if (x >= (1 << 112)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint112(x);
        assertEq(SafeCastLib.toUint120(uint120(x)), uint120(x));
        if (x >= (1 << 120)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint120(x);
        assertEq(SafeCastLib.toUint128(uint128(x)), uint128(x));
        if (x >= (1 << 128)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint128(x);
        assertEq(SafeCastLib.toUint136(uint136(x)), uint136(x));
        if (x >= (1 << 136)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint136(x);
        assertEq(SafeCastLib.toUint144(uint144(x)), uint144(x));
        if (x >= (1 << 144)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint144(x);
        assertEq(SafeCastLib.toUint152(uint152(x)), uint152(x));
        if (x >= (1 << 152)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint152(x);
        assertEq(SafeCastLib.toUint160(uint160(x)), uint160(x));
        if (x >= (1 << 160)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint160(x);
        assertEq(SafeCastLib.toUint168(uint168(x)), uint168(x));
        if (x >= (1 << 168)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint168(x);
        assertEq(SafeCastLib.toUint176(uint176(x)), uint176(x));
        if (x >= (1 << 176)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint176(x);
        assertEq(SafeCastLib.toUint184(uint184(x)), uint184(x));
        if (x >= (1 << 184)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint184(x);
        assertEq(SafeCastLib.toUint192(uint192(x)), uint192(x));
        if (x >= (1 << 192)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint192(x);
        assertEq(SafeCastLib.toUint200(uint200(x)), uint200(x));
        if (x >= (1 << 200)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint200(x);
        assertEq(SafeCastLib.toUint208(uint208(x)), uint208(x));
        if (x >= (1 << 208)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint208(x);
        assertEq(SafeCastLib.toUint216(uint216(x)), uint216(x));
        if (x >= (1 << 216)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint216(x);
        assertEq(SafeCastLib.toUint224(uint224(x)), uint224(x));
        if (x >= (1 << 224)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint224(x);
        assertEq(SafeCastLib.toUint232(uint232(x)), uint232(x));
        if (x >= (1 << 232)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint232(x);
        assertEq(SafeCastLib.toUint240(uint240(x)), uint240(x));
        if (x >= (1 << 240)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint240(x);
        assertEq(SafeCastLib.toUint248(uint248(x)), uint248(x));
        if (x >= (1 << 248)) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toUint248(x);
    }

    function testSafeCastToUint() public {
        unchecked {
            for (uint256 i; i != 256; ++i) {
                testSafeCastToUint(1 << i);
                testSafeCastToUint(type(uint256).max >> i);
                testSafeCastToUint(_random());
            }
        }
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

    function testSafeCastToInt(int256 x) public {
        assertEq(SafeCastLib.toInt8(int8(x)), int8(x));
        if (int8(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt8(x);
        assertEq(SafeCastLib.toInt16(int16(x)), int16(x));
        if (int16(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt16(x);
        assertEq(SafeCastLib.toInt24(int24(x)), int24(x));
        if (int24(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt24(x);
        assertEq(SafeCastLib.toInt32(int32(x)), int32(x));
        if (int32(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt32(x);
        assertEq(SafeCastLib.toInt40(int40(x)), int40(x));
        if (int40(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt40(x);
        assertEq(SafeCastLib.toInt48(int48(x)), int48(x));
        if (int48(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt48(x);
        assertEq(SafeCastLib.toInt56(int56(x)), int56(x));
        if (int56(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt56(x);
        assertEq(SafeCastLib.toInt64(int64(x)), int64(x));
        if (int64(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt64(x);
        assertEq(SafeCastLib.toInt72(int72(x)), int72(x));
        if (int72(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt72(x);
        assertEq(SafeCastLib.toInt80(int80(x)), int80(x));
        if (int80(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt80(x);
        assertEq(SafeCastLib.toInt88(int88(x)), int88(x));
        if (int88(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt88(x);
        assertEq(SafeCastLib.toInt96(int96(x)), int96(x));
        if (int96(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt96(x);
        assertEq(SafeCastLib.toInt104(int104(x)), int104(x));
        if (int104(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt104(x);
        assertEq(SafeCastLib.toInt112(int112(x)), int112(x));
        if (int112(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt112(x);
        assertEq(SafeCastLib.toInt120(int120(x)), int120(x));
        if (int120(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt120(x);
        assertEq(SafeCastLib.toInt128(int128(x)), int128(x));
        if (int128(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt128(x);
        assertEq(SafeCastLib.toInt136(int136(x)), int136(x));
        if (int136(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt136(x);
        assertEq(SafeCastLib.toInt144(int144(x)), int144(x));
        if (int144(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt144(x);
        assertEq(SafeCastLib.toInt152(int152(x)), int152(x));
        if (int152(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt152(x);
        assertEq(SafeCastLib.toInt160(int160(x)), int160(x));
        if (int160(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt160(x);
        assertEq(SafeCastLib.toInt168(int168(x)), int168(x));
        if (int168(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt168(x);
        assertEq(SafeCastLib.toInt176(int176(x)), int176(x));
        if (int176(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt176(x);
        assertEq(SafeCastLib.toInt184(int184(x)), int184(x));
        if (int184(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt184(x);
        assertEq(SafeCastLib.toInt192(int192(x)), int192(x));
        if (int192(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt192(x);
        assertEq(SafeCastLib.toInt200(int200(x)), int200(x));
        if (int200(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt200(x);
        assertEq(SafeCastLib.toInt208(int208(x)), int208(x));
        if (int208(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt208(x);
        assertEq(SafeCastLib.toInt216(int216(x)), int216(x));
        if (int216(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt216(x);
        assertEq(SafeCastLib.toInt224(int224(x)), int224(x));
        if (int224(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt224(x);
        assertEq(SafeCastLib.toInt232(int232(x)), int232(x));
        if (int232(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt232(x);
        assertEq(SafeCastLib.toInt240(int240(x)), int240(x));
        if (int240(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt240(x);
        assertEq(SafeCastLib.toInt248(int248(x)), int248(x));
        if (int248(x) != x) vm.expectRevert(SafeCastLib.Overflow.selector);
        SafeCastLib.toInt248(x);
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
