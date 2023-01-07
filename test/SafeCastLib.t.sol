// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/TestPlus.sol";
import {SafeCastLib} from "../src/utils/SafeCastLib.sol";

contract SafeCastLibTest is TestPlus {
    function testSafeCastToUint(uint256 x) public randomizeReturndatasize {
        assertEq(SafeCastLib.toUint8(uint8(x)), uint8(x));
        if (x >= (1 << 8)) vm.expectRevert();
        SafeCastLib.toUint8(x);
        assertEq(SafeCastLib.toUint16(uint16(x)), uint16(x));
        if (x >= (1 << 16)) vm.expectRevert();
        SafeCastLib.toUint16(x);
        assertEq(SafeCastLib.toUint24(uint24(x)), uint24(x));
        if (x >= (1 << 24)) vm.expectRevert();
        SafeCastLib.toUint24(x);
        assertEq(SafeCastLib.toUint32(uint32(x)), uint32(x));
        if (x >= (1 << 32)) vm.expectRevert();
        SafeCastLib.toUint32(x);
        assertEq(SafeCastLib.toUint40(uint40(x)), uint40(x));
        if (x >= (1 << 40)) vm.expectRevert();
        SafeCastLib.toUint40(x);
        assertEq(SafeCastLib.toUint48(uint48(x)), uint48(x));
        if (x >= (1 << 48)) vm.expectRevert();
        SafeCastLib.toUint48(x);
        assertEq(SafeCastLib.toUint56(uint56(x)), uint56(x));
        if (x >= (1 << 56)) vm.expectRevert();
        SafeCastLib.toUint56(x);
        assertEq(SafeCastLib.toUint64(uint64(x)), uint64(x));
        if (x >= (1 << 64)) vm.expectRevert();
        SafeCastLib.toUint64(x);
        assertEq(SafeCastLib.toUint72(uint72(x)), uint72(x));
        if (x >= (1 << 72)) vm.expectRevert();
        SafeCastLib.toUint72(x);
        assertEq(SafeCastLib.toUint80(uint80(x)), uint80(x));
        if (x >= (1 << 80)) vm.expectRevert();
        SafeCastLib.toUint80(x);
        assertEq(SafeCastLib.toUint88(uint88(x)), uint88(x));
        if (x >= (1 << 88)) vm.expectRevert();
        SafeCastLib.toUint88(x);
        assertEq(SafeCastLib.toUint96(uint96(x)), uint96(x));
        if (x >= (1 << 96)) vm.expectRevert();
        SafeCastLib.toUint96(x);
        assertEq(SafeCastLib.toUint104(uint104(x)), uint104(x));
        if (x >= (1 << 104)) vm.expectRevert();
        SafeCastLib.toUint104(x);
        assertEq(SafeCastLib.toUint112(uint112(x)), uint112(x));
        if (x >= (1 << 112)) vm.expectRevert();
        SafeCastLib.toUint112(x);
        assertEq(SafeCastLib.toUint120(uint120(x)), uint120(x));
        if (x >= (1 << 120)) vm.expectRevert();
        SafeCastLib.toUint120(x);
        assertEq(SafeCastLib.toUint128(uint128(x)), uint128(x));
        if (x >= (1 << 128)) vm.expectRevert();
        SafeCastLib.toUint128(x);
        assertEq(SafeCastLib.toUint136(uint136(x)), uint136(x));
        if (x >= (1 << 136)) vm.expectRevert();
        SafeCastLib.toUint136(x);
        assertEq(SafeCastLib.toUint144(uint144(x)), uint144(x));
        if (x >= (1 << 144)) vm.expectRevert();
        SafeCastLib.toUint144(x);
        assertEq(SafeCastLib.toUint152(uint152(x)), uint152(x));
        if (x >= (1 << 152)) vm.expectRevert();
        SafeCastLib.toUint152(x);
        assertEq(SafeCastLib.toUint160(uint160(x)), uint160(x));
        if (x >= (1 << 160)) vm.expectRevert();
        SafeCastLib.toUint160(x);
        assertEq(SafeCastLib.toUint168(uint168(x)), uint168(x));
        if (x >= (1 << 168)) vm.expectRevert();
        SafeCastLib.toUint168(x);
        assertEq(SafeCastLib.toUint176(uint176(x)), uint176(x));
        if (x >= (1 << 176)) vm.expectRevert();
        SafeCastLib.toUint176(x);
        assertEq(SafeCastLib.toUint184(uint184(x)), uint184(x));
        if (x >= (1 << 184)) vm.expectRevert();
        SafeCastLib.toUint184(x);
        assertEq(SafeCastLib.toUint192(uint192(x)), uint192(x));
        if (x >= (1 << 192)) vm.expectRevert();
        SafeCastLib.toUint192(x);
        assertEq(SafeCastLib.toUint200(uint200(x)), uint200(x));
        if (x >= (1 << 200)) vm.expectRevert();
        SafeCastLib.toUint200(x);
        assertEq(SafeCastLib.toUint208(uint208(x)), uint208(x));
        if (x >= (1 << 208)) vm.expectRevert();
        SafeCastLib.toUint208(x);
        assertEq(SafeCastLib.toUint216(uint216(x)), uint216(x));
        if (x >= (1 << 216)) vm.expectRevert();
        SafeCastLib.toUint216(x);
        assertEq(SafeCastLib.toUint224(uint224(x)), uint224(x));
        if (x >= (1 << 224)) vm.expectRevert();
        SafeCastLib.toUint224(x);
        assertEq(SafeCastLib.toUint232(uint232(x)), uint232(x));
        if (x >= (1 << 232)) vm.expectRevert();
        SafeCastLib.toUint232(x);
        assertEq(SafeCastLib.toUint240(uint240(x)), uint240(x));
        if (x >= (1 << 240)) vm.expectRevert();
        SafeCastLib.toUint240(x);
        assertEq(SafeCastLib.toUint248(uint248(x)), uint248(x));
        if (x >= (1 << 248)) vm.expectRevert();
        SafeCastLib.toUint248(x);
    }

    function testSafeCastToUint(uint256 x, uint8 s) public randomizeReturndatasize {
        x = x >> uint256(s);
        assertEq(this.toUint8(uint8(x)), uint8(x));
        if (x >= (1 << 8)) vm.expectRevert();
        this.toUint8(x);
        assertEq(this.toUint16(uint16(x)), uint16(x));
        if (x >= (1 << 16)) vm.expectRevert();
        this.toUint16(x);
        assertEq(this.toUint24(uint24(x)), uint24(x));
        if (x >= (1 << 24)) vm.expectRevert();
        this.toUint24(x);
        assertEq(this.toUint32(uint32(x)), uint32(x));
        if (x >= (1 << 32)) vm.expectRevert();
        this.toUint32(x);
        assertEq(this.toUint40(uint40(x)), uint40(x));
        if (x >= (1 << 40)) vm.expectRevert();
        this.toUint40(x);
        assertEq(this.toUint48(uint48(x)), uint48(x));
        if (x >= (1 << 48)) vm.expectRevert();
        this.toUint48(x);
        assertEq(this.toUint56(uint56(x)), uint56(x));
        if (x >= (1 << 56)) vm.expectRevert();
        this.toUint56(x);
        assertEq(this.toUint64(uint64(x)), uint64(x));
        if (x >= (1 << 64)) vm.expectRevert();
        this.toUint64(x);
        assertEq(this.toUint72(uint72(x)), uint72(x));
        if (x >= (1 << 72)) vm.expectRevert();
        this.toUint72(x);
        assertEq(this.toUint80(uint80(x)), uint80(x));
        if (x >= (1 << 80)) vm.expectRevert();
        this.toUint80(x);
        assertEq(this.toUint88(uint88(x)), uint88(x));
        if (x >= (1 << 88)) vm.expectRevert();
        this.toUint88(x);
        assertEq(this.toUint96(uint96(x)), uint96(x));
        if (x >= (1 << 96)) vm.expectRevert();
        this.toUint96(x);
        assertEq(this.toUint104(uint104(x)), uint104(x));
        if (x >= (1 << 104)) vm.expectRevert();
        this.toUint104(x);
        assertEq(this.toUint112(uint112(x)), uint112(x));
        if (x >= (1 << 112)) vm.expectRevert();
        this.toUint112(x);
        assertEq(this.toUint120(uint120(x)), uint120(x));
        if (x >= (1 << 120)) vm.expectRevert();
        this.toUint120(x);
        assertEq(this.toUint128(uint128(x)), uint128(x));
        if (x >= (1 << 128)) vm.expectRevert();
        this.toUint128(x);
        assertEq(this.toUint136(uint136(x)), uint136(x));
        if (x >= (1 << 136)) vm.expectRevert();
        this.toUint136(x);
        assertEq(this.toUint144(uint144(x)), uint144(x));
        if (x >= (1 << 144)) vm.expectRevert();
        this.toUint144(x);
        assertEq(this.toUint152(uint152(x)), uint152(x));
        if (x >= (1 << 152)) vm.expectRevert();
        this.toUint152(x);
        assertEq(this.toUint160(uint160(x)), uint160(x));
        if (x >= (1 << 160)) vm.expectRevert();
        this.toUint160(x);
        assertEq(this.toUint168(uint168(x)), uint168(x));
        if (x >= (1 << 168)) vm.expectRevert();
        this.toUint168(x);
        assertEq(this.toUint176(uint176(x)), uint176(x));
        if (x >= (1 << 176)) vm.expectRevert();
        this.toUint176(x);
        assertEq(this.toUint184(uint184(x)), uint184(x));
        if (x >= (1 << 184)) vm.expectRevert();
        this.toUint184(x);
        assertEq(this.toUint192(uint192(x)), uint192(x));
        if (x >= (1 << 192)) vm.expectRevert();
        this.toUint192(x);
        assertEq(this.toUint200(uint200(x)), uint200(x));
        if (x >= (1 << 200)) vm.expectRevert();
        this.toUint200(x);
        assertEq(this.toUint208(uint208(x)), uint208(x));
        if (x >= (1 << 208)) vm.expectRevert();
        this.toUint208(x);
        assertEq(this.toUint216(uint216(x)), uint216(x));
        if (x >= (1 << 216)) vm.expectRevert();
        this.toUint216(x);
        assertEq(this.toUint224(uint224(x)), uint224(x));
        if (x >= (1 << 224)) vm.expectRevert();
        this.toUint224(x);
        assertEq(this.toUint232(uint232(x)), uint232(x));
        if (x >= (1 << 232)) vm.expectRevert();
        this.toUint232(x);
        assertEq(this.toUint240(uint240(x)), uint240(x));
        if (x >= (1 << 240)) vm.expectRevert();
        this.toUint240(x);
        assertEq(this.toUint248(uint248(x)), uint248(x));
        if (x >= (1 << 248)) vm.expectRevert();
        this.toUint248(x);
    }

    function testSafeCastToUint() public {
        unchecked {
            for (uint256 i; i != 256; ++i) {
                testSafeCastToUint(1 << i);
                testSafeCastToUint(_random());
                testSafeCastToUint(type(uint256).max, uint8(i));
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

    function testSafeCastToInt(int256 x) public randomizeReturndatasize {
        assertEq(SafeCastLib.toInt8(int8(x)), int8(x));
        if (int8(x) != x) vm.expectRevert();
        SafeCastLib.toInt8(x);
        assertEq(SafeCastLib.toInt16(int16(x)), int16(x));
        if (int16(x) != x) vm.expectRevert();
        SafeCastLib.toInt16(x);
        assertEq(SafeCastLib.toInt24(int24(x)), int24(x));
        if (int24(x) != x) vm.expectRevert();
        SafeCastLib.toInt24(x);
        assertEq(SafeCastLib.toInt32(int32(x)), int32(x));
        if (int32(x) != x) vm.expectRevert();
        SafeCastLib.toInt32(x);
        assertEq(SafeCastLib.toInt40(int40(x)), int40(x));
        if (int40(x) != x) vm.expectRevert();
        SafeCastLib.toInt40(x);
        assertEq(SafeCastLib.toInt48(int48(x)), int48(x));
        if (int48(x) != x) vm.expectRevert();
        SafeCastLib.toInt48(x);
        assertEq(SafeCastLib.toInt56(int56(x)), int56(x));
        if (int56(x) != x) vm.expectRevert();
        SafeCastLib.toInt56(x);
        assertEq(SafeCastLib.toInt64(int64(x)), int64(x));
        if (int64(x) != x) vm.expectRevert();
        SafeCastLib.toInt64(x);
        assertEq(SafeCastLib.toInt72(int72(x)), int72(x));
        if (int72(x) != x) vm.expectRevert();
        SafeCastLib.toInt72(x);
        assertEq(SafeCastLib.toInt80(int80(x)), int80(x));
        if (int80(x) != x) vm.expectRevert();
        SafeCastLib.toInt80(x);
        assertEq(SafeCastLib.toInt88(int88(x)), int88(x));
        if (int88(x) != x) vm.expectRevert();
        SafeCastLib.toInt88(x);
        assertEq(SafeCastLib.toInt96(int96(x)), int96(x));
        if (int96(x) != x) vm.expectRevert();
        SafeCastLib.toInt96(x);
        assertEq(SafeCastLib.toInt104(int104(x)), int104(x));
        if (int104(x) != x) vm.expectRevert();
        SafeCastLib.toInt104(x);
        assertEq(SafeCastLib.toInt112(int112(x)), int112(x));
        if (int112(x) != x) vm.expectRevert();
        SafeCastLib.toInt112(x);
        assertEq(SafeCastLib.toInt120(int120(x)), int120(x));
        if (int120(x) != x) vm.expectRevert();
        SafeCastLib.toInt120(x);
        assertEq(SafeCastLib.toInt128(int128(x)), int128(x));
        if (int128(x) != x) vm.expectRevert();
        SafeCastLib.toInt128(x);
        assertEq(SafeCastLib.toInt136(int136(x)), int136(x));
        if (int136(x) != x) vm.expectRevert();
        SafeCastLib.toInt136(x);
        assertEq(SafeCastLib.toInt144(int144(x)), int144(x));
        if (int144(x) != x) vm.expectRevert();
        SafeCastLib.toInt144(x);
        assertEq(SafeCastLib.toInt152(int152(x)), int152(x));
        if (int152(x) != x) vm.expectRevert();
        SafeCastLib.toInt152(x);
        assertEq(SafeCastLib.toInt160(int160(x)), int160(x));
        if (int160(x) != x) vm.expectRevert();
        SafeCastLib.toInt160(x);
        assertEq(SafeCastLib.toInt168(int168(x)), int168(x));
        if (int168(x) != x) vm.expectRevert();
        SafeCastLib.toInt168(x);
        assertEq(SafeCastLib.toInt176(int176(x)), int176(x));
        if (int176(x) != x) vm.expectRevert();
        SafeCastLib.toInt176(x);
        assertEq(SafeCastLib.toInt184(int184(x)), int184(x));
        if (int184(x) != x) vm.expectRevert();
        SafeCastLib.toInt184(x);
        assertEq(SafeCastLib.toInt192(int192(x)), int192(x));
        if (int192(x) != x) vm.expectRevert();
        SafeCastLib.toInt192(x);
        assertEq(SafeCastLib.toInt200(int200(x)), int200(x));
        if (int200(x) != x) vm.expectRevert();
        SafeCastLib.toInt200(x);
        assertEq(SafeCastLib.toInt208(int208(x)), int208(x));
        if (int208(x) != x) vm.expectRevert();
        SafeCastLib.toInt208(x);
        assertEq(SafeCastLib.toInt216(int216(x)), int216(x));
        if (int216(x) != x) vm.expectRevert();
        SafeCastLib.toInt216(x);
        assertEq(SafeCastLib.toInt224(int224(x)), int224(x));
        if (int224(x) != x) vm.expectRevert();
        SafeCastLib.toInt224(x);
        assertEq(SafeCastLib.toInt232(int232(x)), int232(x));
        if (int232(x) != x) vm.expectRevert();
        SafeCastLib.toInt232(x);
        assertEq(SafeCastLib.toInt240(int240(x)), int240(x));
        if (int240(x) != x) vm.expectRevert();
        SafeCastLib.toInt240(x);
        assertEq(SafeCastLib.toInt248(int248(x)), int248(x));
        if (int248(x) != x) vm.expectRevert();
        SafeCastLib.toInt248(x);
    }

    function testSafeCastToInt(int256 x, uint8 s) public randomizeReturndatasize {
        /// @solidity memory-safe-assembly
        assembly {
            x := shl(and(s, 0xff), x)
        }
        assertEq(SafeCastLib.toInt8(int8(x)), int8(x));
        if (int8(x) != x) vm.expectRevert();
        SafeCastLib.toInt8(x);
        assertEq(SafeCastLib.toInt16(int16(x)), int16(x));
        if (int16(x) != x) vm.expectRevert();
        SafeCastLib.toInt16(x);
        assertEq(SafeCastLib.toInt24(int24(x)), int24(x));
        if (int24(x) != x) vm.expectRevert();
        SafeCastLib.toInt24(x);
        assertEq(SafeCastLib.toInt32(int32(x)), int32(x));
        if (int32(x) != x) vm.expectRevert();
        SafeCastLib.toInt32(x);
        assertEq(SafeCastLib.toInt40(int40(x)), int40(x));
        if (int40(x) != x) vm.expectRevert();
        SafeCastLib.toInt40(x);
        assertEq(SafeCastLib.toInt48(int48(x)), int48(x));
        if (int48(x) != x) vm.expectRevert();
        SafeCastLib.toInt48(x);
        assertEq(SafeCastLib.toInt56(int56(x)), int56(x));
        if (int56(x) != x) vm.expectRevert();
        SafeCastLib.toInt56(x);
        assertEq(SafeCastLib.toInt64(int64(x)), int64(x));
        if (int64(x) != x) vm.expectRevert();
        SafeCastLib.toInt64(x);
        assertEq(SafeCastLib.toInt72(int72(x)), int72(x));
        if (int72(x) != x) vm.expectRevert();
        SafeCastLib.toInt72(x);
        assertEq(SafeCastLib.toInt80(int80(x)), int80(x));
        if (int80(x) != x) vm.expectRevert();
        SafeCastLib.toInt80(x);
        assertEq(SafeCastLib.toInt88(int88(x)), int88(x));
        if (int88(x) != x) vm.expectRevert();
        SafeCastLib.toInt88(x);
        assertEq(SafeCastLib.toInt96(int96(x)), int96(x));
        if (int96(x) != x) vm.expectRevert();
        SafeCastLib.toInt96(x);
        assertEq(SafeCastLib.toInt104(int104(x)), int104(x));
        if (int104(x) != x) vm.expectRevert();
        SafeCastLib.toInt104(x);
        assertEq(SafeCastLib.toInt112(int112(x)), int112(x));
        if (int112(x) != x) vm.expectRevert();
        SafeCastLib.toInt112(x);
        assertEq(SafeCastLib.toInt120(int120(x)), int120(x));
        if (int120(x) != x) vm.expectRevert();
        SafeCastLib.toInt120(x);
        assertEq(SafeCastLib.toInt128(int128(x)), int128(x));
        if (int128(x) != x) vm.expectRevert();
        SafeCastLib.toInt128(x);
        assertEq(SafeCastLib.toInt136(int136(x)), int136(x));
        if (int136(x) != x) vm.expectRevert();
        SafeCastLib.toInt136(x);
        assertEq(SafeCastLib.toInt144(int144(x)), int144(x));
        if (int144(x) != x) vm.expectRevert();
        SafeCastLib.toInt144(x);
        assertEq(SafeCastLib.toInt152(int152(x)), int152(x));
        if (int152(x) != x) vm.expectRevert();
        SafeCastLib.toInt152(x);
        assertEq(SafeCastLib.toInt160(int160(x)), int160(x));
        if (int160(x) != x) vm.expectRevert();
        SafeCastLib.toInt160(x);
        assertEq(SafeCastLib.toInt168(int168(x)), int168(x));
        if (int168(x) != x) vm.expectRevert();
        SafeCastLib.toInt168(x);
        assertEq(SafeCastLib.toInt176(int176(x)), int176(x));
        if (int176(x) != x) vm.expectRevert();
        SafeCastLib.toInt176(x);
        assertEq(SafeCastLib.toInt184(int184(x)), int184(x));
        if (int184(x) != x) vm.expectRevert();
        SafeCastLib.toInt184(x);
        assertEq(SafeCastLib.toInt192(int192(x)), int192(x));
        if (int192(x) != x) vm.expectRevert();
        SafeCastLib.toInt192(x);
        assertEq(SafeCastLib.toInt200(int200(x)), int200(x));
        if (int200(x) != x) vm.expectRevert();
        SafeCastLib.toInt200(x);
        assertEq(SafeCastLib.toInt208(int208(x)), int208(x));
        if (int208(x) != x) vm.expectRevert();
        SafeCastLib.toInt208(x);
        assertEq(SafeCastLib.toInt216(int216(x)), int216(x));
        if (int216(x) != x) vm.expectRevert();
        SafeCastLib.toInt216(x);
        assertEq(SafeCastLib.toInt224(int224(x)), int224(x));
        if (int224(x) != x) vm.expectRevert();
        SafeCastLib.toInt224(x);
        assertEq(SafeCastLib.toInt232(int232(x)), int232(x));
        if (int232(x) != x) vm.expectRevert();
        SafeCastLib.toInt232(x);
        assertEq(SafeCastLib.toInt240(int240(x)), int240(x));
        if (int240(x) != x) vm.expectRevert();
        SafeCastLib.toInt240(x);
        assertEq(SafeCastLib.toInt248(int248(x)), int248(x));
        if (int248(x) != x) vm.expectRevert();
        SafeCastLib.toInt248(x);
    }

    function testSafeCastToInt() public {
        unchecked {
            for (uint256 i; i != 256; ++i) {
                int256 casted;
                /// @solidity memory-safe-assembly
                assembly {
                    casted := shl(i, 1)
                }
                testSafeCastToInt(casted);
                testSafeCastToInt(int256(_random()));
                testSafeCastToInt(int256(type(uint256).max), uint8(i));
            }
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

    function toUint8(uint256 x) external view randomizeReturndatasize returns (uint8 y) {
        y = SafeCastLib.toUint8(x);
    }

    function toUint16(uint256 x) external view randomizeReturndatasize returns (uint16 y) {
        y = SafeCastLib.toUint16(x);
    }

    function toUint24(uint256 x) external view randomizeReturndatasize returns (uint24 y) {
        y = SafeCastLib.toUint24(x);
    }

    function toUint32(uint256 x) external view randomizeReturndatasize returns (uint32 y) {
        y = SafeCastLib.toUint32(x);
    }

    function toUint40(uint256 x) external view randomizeReturndatasize returns (uint40 y) {
        y = SafeCastLib.toUint40(x);
    }

    function toUint48(uint256 x) external view randomizeReturndatasize returns (uint48 y) {
        y = SafeCastLib.toUint48(x);
    }

    function toUint56(uint256 x) external view randomizeReturndatasize returns (uint56 y) {
        y = SafeCastLib.toUint56(x);
    }

    function toUint64(uint256 x) external view randomizeReturndatasize returns (uint64 y) {
        y = SafeCastLib.toUint64(x);
    }

    function toUint72(uint256 x) external view randomizeReturndatasize returns (uint72 y) {
        y = SafeCastLib.toUint72(x);
    }

    function toUint80(uint256 x) external view randomizeReturndatasize returns (uint80 y) {
        y = SafeCastLib.toUint80(x);
    }

    function toUint88(uint256 x) external view randomizeReturndatasize returns (uint88 y) {
        y = SafeCastLib.toUint88(x);
    }

    function toUint96(uint256 x) external view randomizeReturndatasize returns (uint96 y) {
        y = SafeCastLib.toUint96(x);
    }

    function toUint104(uint256 x) external view randomizeReturndatasize returns (uint104 y) {
        y = SafeCastLib.toUint104(x);
    }

    function toUint112(uint256 x) external view randomizeReturndatasize returns (uint112 y) {
        y = SafeCastLib.toUint112(x);
    }

    function toUint120(uint256 x) external view randomizeReturndatasize returns (uint120 y) {
        y = SafeCastLib.toUint120(x);
    }

    function toUint128(uint256 x) external view randomizeReturndatasize returns (uint128 y) {
        y = SafeCastLib.toUint128(x);
    }

    function toUint136(uint256 x) external view randomizeReturndatasize returns (uint136 y) {
        y = SafeCastLib.toUint136(x);
    }

    function toUint144(uint256 x) external view randomizeReturndatasize returns (uint144 y) {
        y = SafeCastLib.toUint144(x);
    }

    function toUint152(uint256 x) external view randomizeReturndatasize returns (uint152 y) {
        y = SafeCastLib.toUint152(x);
    }

    function toUint160(uint256 x) external view randomizeReturndatasize returns (uint160 y) {
        y = SafeCastLib.toUint160(x);
    }

    function toUint168(uint256 x) external view randomizeReturndatasize returns (uint168 y) {
        y = SafeCastLib.toUint168(x);
    }

    function toUint176(uint256 x) external view randomizeReturndatasize returns (uint176 y) {
        y = SafeCastLib.toUint176(x);
    }

    function toUint184(uint256 x) external view randomizeReturndatasize returns (uint184 y) {
        y = SafeCastLib.toUint184(x);
    }

    function toUint192(uint256 x) external view randomizeReturndatasize returns (uint192 y) {
        y = SafeCastLib.toUint192(x);
    }

    function toUint200(uint256 x) external view randomizeReturndatasize returns (uint200 y) {
        y = SafeCastLib.toUint200(x);
    }

    function toUint208(uint256 x) external view randomizeReturndatasize returns (uint208 y) {
        y = SafeCastLib.toUint208(x);
    }

    function toUint216(uint256 x) external view randomizeReturndatasize returns (uint216 y) {
        y = SafeCastLib.toUint216(x);
    }

    function toUint224(uint256 x) external view randomizeReturndatasize returns (uint224 y) {
        y = SafeCastLib.toUint224(x);
    }

    function toUint232(uint256 x) external view randomizeReturndatasize returns (uint232 y) {
        y = SafeCastLib.toUint232(x);
    }

    function toUint240(uint256 x) external view randomizeReturndatasize returns (uint240 y) {
        y = SafeCastLib.toUint240(x);
    }

    function toUint248(uint256 x) external view randomizeReturndatasize returns (uint248 y) {
        y = SafeCastLib.toUint248(x);
    }

    function toInt8(int256 x) external view randomizeReturndatasize returns (int8 y) {
        y = SafeCastLib.toInt8(x);
    }

    function toInt16(int256 x) external view randomizeReturndatasize returns (int16 y) {
        y = SafeCastLib.toInt16(x);
    }

    function toInt24(int256 x) external view randomizeReturndatasize returns (int24 y) {
        y = SafeCastLib.toInt24(x);
    }

    function toInt32(int256 x) external view randomizeReturndatasize returns (int32 y) {
        y = SafeCastLib.toInt32(x);
    }

    function toInt40(int256 x) external view randomizeReturndatasize returns (int40 y) {
        y = SafeCastLib.toInt40(x);
    }

    function toInt48(int256 x) external view randomizeReturndatasize returns (int48 y) {
        y = SafeCastLib.toInt48(x);
    }

    function toInt56(int256 x) external view randomizeReturndatasize returns (int56 y) {
        y = SafeCastLib.toInt56(x);
    }

    function toInt64(int256 x) external view randomizeReturndatasize returns (int64 y) {
        y = SafeCastLib.toInt64(x);
    }

    function toInt72(int256 x) external view randomizeReturndatasize returns (int72 y) {
        y = SafeCastLib.toInt72(x);
    }

    function toInt80(int256 x) external view randomizeReturndatasize returns (int80 y) {
        y = SafeCastLib.toInt80(x);
    }

    function toInt88(int256 x) external view randomizeReturndatasize returns (int88 y) {
        y = SafeCastLib.toInt88(x);
    }

    function toInt96(int256 x) external view randomizeReturndatasize returns (int96 y) {
        y = SafeCastLib.toInt96(x);
    }

    function toInt104(int256 x) external view randomizeReturndatasize returns (int104 y) {
        y = SafeCastLib.toInt104(x);
    }

    function toInt112(int256 x) external view randomizeReturndatasize returns (int112 y) {
        y = SafeCastLib.toInt112(x);
    }

    function toInt120(int256 x) external view randomizeReturndatasize returns (int120 y) {
        y = SafeCastLib.toInt120(x);
    }

    function toInt128(int256 x) external view randomizeReturndatasize returns (int128 y) {
        y = SafeCastLib.toInt128(x);
    }

    function toInt136(int256 x) external view randomizeReturndatasize returns (int136 y) {
        y = SafeCastLib.toInt136(x);
    }

    function toInt144(int256 x) external view randomizeReturndatasize returns (int144 y) {
        y = SafeCastLib.toInt144(x);
    }

    function toInt152(int256 x) external view randomizeReturndatasize returns (int152 y) {
        y = SafeCastLib.toInt152(x);
    }

    function toInt160(int256 x) external view randomizeReturndatasize returns (int160 y) {
        y = SafeCastLib.toInt160(x);
    }

    function toInt168(int256 x) external view randomizeReturndatasize returns (int168 y) {
        y = SafeCastLib.toInt168(x);
    }

    function toInt176(int256 x) external view randomizeReturndatasize returns (int176 y) {
        y = SafeCastLib.toInt176(x);
    }

    function toInt184(int256 x) external view randomizeReturndatasize returns (int184 y) {
        y = SafeCastLib.toInt184(x);
    }

    function toInt192(int256 x) external view randomizeReturndatasize returns (int192 y) {
        y = SafeCastLib.toInt192(x);
    }

    function toInt200(int256 x) external view randomizeReturndatasize returns (int200 y) {
        y = SafeCastLib.toInt200(x);
    }

    function toInt208(int256 x) external view randomizeReturndatasize returns (int208 y) {
        y = SafeCastLib.toInt208(x);
    }

    function toInt216(int256 x) external view randomizeReturndatasize returns (int216 y) {
        y = SafeCastLib.toInt216(x);
    }

    function toInt224(int256 x) external view randomizeReturndatasize returns (int224 y) {
        y = SafeCastLib.toInt224(x);
    }

    function toInt232(int256 x) external view randomizeReturndatasize returns (int232 y) {
        y = SafeCastLib.toInt232(x);
    }

    function toInt240(int256 x) external view randomizeReturndatasize returns (int240 y) {
        y = SafeCastLib.toInt240(x);
    }

    function toInt248(int256 x) external view randomizeReturndatasize returns (int248 y) {
        y = SafeCastLib.toInt248(x);
    }

    modifier randomizeReturndatasize() {
        if (_random() & 1 == 0) {
            uint256 n = _bound(_random(), 0, 65536);
            /// @solidity memory-safe-assembly
            assembly {
                pop(staticcall(gas(), 0x04, 0x00, n, 0x00, 0x00))
                if iszero(eq(returndatasize(), n)) { revert(0, 0) }
            }
        }
        _;
    }
}
