// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe integer casting library that reverts on overflow.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error Overflow();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*          UNSIGNED INTEGER SAFE CASTING OPERATIONS          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function toUint8(uint256 x) internal pure returns (uint8 y) {
        if (x >= 1 << 8) revert Overflow();
        y = uint8(x);
    }

    function toUint16(uint256 x) internal pure returns (uint16 y) {
        if (x >= 1 << 16) revert Overflow();
        y = uint16(x);
    }

    function toUint24(uint256 x) internal pure returns (uint24 y) {
        if (x >= 1 << 24) revert Overflow();
        y = uint24(x);
    }

    function toUint32(uint256 x) internal pure returns (uint32 y) {
        if (x >= 1 << 32) revert Overflow();
        y = uint32(x);
    }

    function toUint40(uint256 x) internal pure returns (uint40 y) {
        if (x >= 1 << 40) revert Overflow();
        y = uint40(x);
    }

    function toUint48(uint256 x) internal pure returns (uint48 y) {
        if (x >= 1 << 48) revert Overflow();
        y = uint48(x);
    }

    function toUint56(uint256 x) internal pure returns (uint56 y) {
        if (x >= 1 << 56) revert Overflow();
        y = uint56(x);
    }

    function toUint64(uint256 x) internal pure returns (uint64 y) {
        if (x >= 1 << 64) revert Overflow();
        y = uint64(x);
    }

    function toUint72(uint256 x) internal pure returns (uint72 y) {
        if (x >= 1 << 72) revert Overflow();
        y = uint72(x);
    }

    function toUint80(uint256 x) internal pure returns (uint80 y) {
        if (x >= 1 << 80) revert Overflow();
        y = uint80(x);
    }

    function toUint88(uint256 x) internal pure returns (uint88 y) {
        if (x >= 1 << 88) revert Overflow();
        y = uint88(x);
    }

    function toUint96(uint256 x) internal pure returns (uint96 y) {
        if (x >= 1 << 96) revert Overflow();
        y = uint96(x);
    }

    function toUint104(uint256 x) internal pure returns (uint104 y) {
        if (x >= 1 << 104) revert Overflow();
        y = uint104(x);
    }

    function toUint112(uint256 x) internal pure returns (uint112 y) {
        if (x >= 1 << 112) revert Overflow();
        y = uint112(x);
    }

    function toUint120(uint256 x) internal pure returns (uint120 y) {
        if (x >= 1 << 120) revert Overflow();
        y = uint120(x);
    }

    function toUint128(uint256 x) internal pure returns (uint128 y) {
        if (x >= 1 << 128) revert Overflow();
        y = uint128(x);
    }

    function toUint136(uint256 x) internal pure returns (uint136 y) {
        if (x >= 1 << 136) revert Overflow();
        y = uint136(x);
    }

    function toUint144(uint256 x) internal pure returns (uint144 y) {
        if (x >= 1 << 144) revert Overflow();
        y = uint144(x);
    }

    function toUint152(uint256 x) internal pure returns (uint152 y) {
        if (x >= 1 << 152) revert Overflow();
        y = uint152(x);
    }

    function toUint160(uint256 x) internal pure returns (uint160 y) {
        if (x >= 1 << 160) revert Overflow();
        y = uint160(x);
    }

    function toUint168(uint256 x) internal pure returns (uint168 y) {
        if (x >= 1 << 168) revert Overflow();
        y = uint168(x);
    }

    function toUint176(uint256 x) internal pure returns (uint176 y) {
        if (x >= 1 << 176) revert Overflow();
        y = uint176(x);
    }

    function toUint184(uint256 x) internal pure returns (uint184 y) {
        if (x >= 1 << 184) revert Overflow();
        y = uint184(x);
    }

    function toUint192(uint256 x) internal pure returns (uint192 y) {
        if (x >= 1 << 192) revert Overflow();
        y = uint192(x);
    }

    function toUint200(uint256 x) internal pure returns (uint200 y) {
        if (x >= 1 << 200) revert Overflow();
        y = uint200(x);
    }

    function toUint208(uint256 x) internal pure returns (uint208 y) {
        if (x >= 1 << 208) revert Overflow();
        y = uint208(x);
    }

    function toUint216(uint256 x) internal pure returns (uint216 y) {
        if (x >= 1 << 216) revert Overflow();
        y = uint216(x);
    }

    function toUint224(uint256 x) internal pure returns (uint224 y) {
        if (x >= 1 << 224) revert Overflow();
        y = uint224(x);
    }

    function toUint232(uint256 x) internal pure returns (uint232 y) {
        if (x >= 1 << 232) revert Overflow();
        y = uint232(x);
    }

    function toUint240(uint256 x) internal pure returns (uint240 y) {
        if (x >= 1 << 240) revert Overflow();
        y = uint240(x);
    }

    function toUint248(uint256 x) internal pure returns (uint248 y) {
        if (x >= 1 << 248) revert Overflow();
        y = uint248(x);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*           SIGNED INTEGER SAFE CASTING OPERATIONS           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function toInt8(int256 x) internal pure returns (int8 y) {
        y = int8(x);
        if (x != y) revert Overflow();
    }

    function toInt16(int256 x) internal pure returns (int16 y) {
        y = int16(x);
        if (x != y) revert Overflow();
    }

    function toInt24(int256 x) internal pure returns (int24 y) {
        y = int24(x);
        if (x != y) revert Overflow();
    }

    function toInt32(int256 x) internal pure returns (int32 y) {
        y = int32(x);
        if (x != y) revert Overflow();
    }

    function toInt40(int256 x) internal pure returns (int40 y) {
        y = int40(x);
        if (x != y) revert Overflow();
    }

    function toInt48(int256 x) internal pure returns (int48 y) {
        y = int48(x);
        if (x != y) revert Overflow();
    }

    function toInt56(int256 x) internal pure returns (int56 y) {
        y = int56(x);
        if (x != y) revert Overflow();
    }

    function toInt64(int256 x) internal pure returns (int64 y) {
        y = int64(x);
        if (x != y) revert Overflow();
    }

    function toInt72(int256 x) internal pure returns (int72 y) {
        y = int72(x);
        if (x != y) revert Overflow();
    }

    function toInt80(int256 x) internal pure returns (int80 y) {
        y = int80(x);
        if (x != y) revert Overflow();
    }

    function toInt88(int256 x) internal pure returns (int88 y) {
        y = int88(x);
        if (x != y) revert Overflow();
    }

    function toInt96(int256 x) internal pure returns (int96 y) {
        y = int96(x);
        if (x != y) revert Overflow();
    }

    function toInt104(int256 x) internal pure returns (int104 y) {
        y = int104(x);
        if (x != y) revert Overflow();
    }

    function toInt112(int256 x) internal pure returns (int112 y) {
        y = int112(x);
        if (x != y) revert Overflow();
    }

    function toInt120(int256 x) internal pure returns (int120 y) {
        y = int120(x);
        if (x != y) revert Overflow();
    }

    function toInt128(int256 x) internal pure returns (int128 y) {
        y = int128(x);
        if (x != y) revert Overflow();
    }

    function toInt136(int256 x) internal pure returns (int136 y) {
        y = int136(x);
        if (x != y) revert Overflow();
    }

    function toInt144(int256 x) internal pure returns (int144 y) {
        y = int144(x);
        if (x != y) revert Overflow();
    }

    function toInt152(int256 x) internal pure returns (int152 y) {
        y = int152(x);
        if (x != y) revert Overflow();
    }

    function toInt160(int256 x) internal pure returns (int160 y) {
        y = int160(x);
        if (x != y) revert Overflow();
    }

    function toInt168(int256 x) internal pure returns (int168 y) {
        y = int168(x);
        if (x != y) revert Overflow();
    }

    function toInt176(int256 x) internal pure returns (int176 y) {
        y = int176(x);
        if (x != y) revert Overflow();
    }

    function toInt184(int256 x) internal pure returns (int184 y) {
        y = int184(x);
        if (x != y) revert Overflow();
    }

    function toInt192(int256 x) internal pure returns (int192 y) {
        y = int192(x);
        if (x != y) revert Overflow();
    }

    function toInt200(int256 x) internal pure returns (int200 y) {
        y = int200(x);
        if (x != y) revert Overflow();
    }

    function toInt208(int256 x) internal pure returns (int208 y) {
        y = int208(x);
        if (x != y) revert Overflow();
    }

    function toInt216(int256 x) internal pure returns (int216 y) {
        y = int216(x);
        if (x != y) revert Overflow();
    }

    function toInt224(int256 x) internal pure returns (int224 y) {
        y = int224(x);
        if (x != y) revert Overflow();
    }

    function toInt232(int256 x) internal pure returns (int232 y) {
        y = int232(x);
        if (x != y) revert Overflow();
    }

    function toInt240(int256 x) internal pure returns (int240 y) {
        y = int240(x);
        if (x != y) revert Overflow();
    }

    function toInt248(int256 x) internal pure returns (int248 y) {
        y = int248(x);
        if (x != y) revert Overflow();
    }
}
