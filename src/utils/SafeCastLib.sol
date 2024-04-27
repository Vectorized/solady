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

    function toUint8(uint256 x) internal pure returns (uint8) {
        if (x >= 1 << 8) _revertOverflow();
        return uint8(x);
    }

    function toUint16(uint256 x) internal pure returns (uint16) {
        if (x >= 1 << 16) _revertOverflow();
        return uint16(x);
    }

    function toUint24(uint256 x) internal pure returns (uint24) {
        if (x >= 1 << 24) _revertOverflow();
        return uint24(x);
    }

    function toUint32(uint256 x) internal pure returns (uint32) {
        if (x >= 1 << 32) _revertOverflow();
        return uint32(x);
    }

    function toUint40(uint256 x) internal pure returns (uint40) {
        if (x >= 1 << 40) _revertOverflow();
        return uint40(x);
    }

    function toUint48(uint256 x) internal pure returns (uint48) {
        if (x >= 1 << 48) _revertOverflow();
        return uint48(x);
    }

    function toUint56(uint256 x) internal pure returns (uint56) {
        if (x >= 1 << 56) _revertOverflow();
        return uint56(x);
    }

    function toUint64(uint256 x) internal pure returns (uint64) {
        if (x >= 1 << 64) _revertOverflow();
        return uint64(x);
    }

    function toUint72(uint256 x) internal pure returns (uint72) {
        if (x >= 1 << 72) _revertOverflow();
        return uint72(x);
    }

    function toUint80(uint256 x) internal pure returns (uint80) {
        if (x >= 1 << 80) _revertOverflow();
        return uint80(x);
    }

    function toUint88(uint256 x) internal pure returns (uint88) {
        if (x >= 1 << 88) _revertOverflow();
        return uint88(x);
    }

    function toUint96(uint256 x) internal pure returns (uint96) {
        if (x >= 1 << 96) _revertOverflow();
        return uint96(x);
    }

    function toUint104(uint256 x) internal pure returns (uint104) {
        if (x >= 1 << 104) _revertOverflow();
        return uint104(x);
    }

    function toUint112(uint256 x) internal pure returns (uint112) {
        if (x >= 1 << 112) _revertOverflow();
        return uint112(x);
    }

    function toUint120(uint256 x) internal pure returns (uint120) {
        if (x >= 1 << 120) _revertOverflow();
        return uint120(x);
    }

    function toUint128(uint256 x) internal pure returns (uint128) {
        if (x >= 1 << 128) _revertOverflow();
        return uint128(x);
    }

    function toUint136(uint256 x) internal pure returns (uint136) {
        if (x >= 1 << 136) _revertOverflow();
        return uint136(x);
    }

    function toUint144(uint256 x) internal pure returns (uint144) {
        if (x >= 1 << 144) _revertOverflow();
        return uint144(x);
    }

    function toUint152(uint256 x) internal pure returns (uint152) {
        if (x >= 1 << 152) _revertOverflow();
        return uint152(x);
    }

    function toUint160(uint256 x) internal pure returns (uint160) {
        if (x >= 1 << 160) _revertOverflow();
        return uint160(x);
    }

    function toUint168(uint256 x) internal pure returns (uint168) {
        if (x >= 1 << 168) _revertOverflow();
        return uint168(x);
    }

    function toUint176(uint256 x) internal pure returns (uint176) {
        if (x >= 1 << 176) _revertOverflow();
        return uint176(x);
    }

    function toUint184(uint256 x) internal pure returns (uint184) {
        if (x >= 1 << 184) _revertOverflow();
        return uint184(x);
    }

    function toUint192(uint256 x) internal pure returns (uint192) {
        if (x >= 1 << 192) _revertOverflow();
        return uint192(x);
    }

    function toUint200(uint256 x) internal pure returns (uint200) {
        if (x >= 1 << 200) _revertOverflow();
        return uint200(x);
    }

    function toUint208(uint256 x) internal pure returns (uint208) {
        if (x >= 1 << 208) _revertOverflow();
        return uint208(x);
    }

    function toUint216(uint256 x) internal pure returns (uint216) {
        if (x >= 1 << 216) _revertOverflow();
        return uint216(x);
    }

    function toUint224(uint256 x) internal pure returns (uint224) {
        if (x >= 1 << 224) _revertOverflow();
        return uint224(x);
    }

    function toUint232(uint256 x) internal pure returns (uint232) {
        if (x >= 1 << 232) _revertOverflow();
        return uint232(x);
    }

    function toUint240(uint256 x) internal pure returns (uint240) {
        if (x >= 1 << 240) _revertOverflow();
        return uint240(x);
    }

    function toUint248(uint256 x) internal pure returns (uint248) {
        if (x >= 1 << 248) _revertOverflow();
        return uint248(x);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*           SIGNED INTEGER SAFE CASTING OPERATIONS           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function toInt8(int256 x) internal pure returns (int8 y) {
        if (x != (y = int8(x))) _revertOverflow();
    }

    function toInt16(int256 x) internal pure returns (int16 y) {
        if (x != (y = int16(x))) _revertOverflow();
    }

    function toInt24(int256 x) internal pure returns (int24 y) {
        if (x != (y = int24(x))) _revertOverflow();
    }

    function toInt32(int256 x) internal pure returns (int32 y) {
        if (x != (y = int32(x))) _revertOverflow();
    }

    function toInt40(int256 x) internal pure returns (int40 y) {
        if (x != (y = int40(x))) _revertOverflow();
    }

    function toInt48(int256 x) internal pure returns (int48 y) {
        if (x != (y = int48(x))) _revertOverflow();
    }

    function toInt56(int256 x) internal pure returns (int56 y) {
        if (x != (y = int56(x))) _revertOverflow();
    }

    function toInt64(int256 x) internal pure returns (int64 y) {
        if (x != (y = int64(x))) _revertOverflow();
    }

    function toInt72(int256 x) internal pure returns (int72 y) {
        if (x != (y = int72(x))) _revertOverflow();
    }

    function toInt80(int256 x) internal pure returns (int80 y) {
        if (x != (y = int80(x))) _revertOverflow();
    }

    function toInt88(int256 x) internal pure returns (int88 y) {
        if (x != (y = int88(x))) _revertOverflow();
    }

    function toInt96(int256 x) internal pure returns (int96 y) {
        if (x != (y = int96(x))) _revertOverflow();
    }

    function toInt104(int256 x) internal pure returns (int104 y) {
        if (x != (y = int104(x))) _revertOverflow();
    }

    function toInt112(int256 x) internal pure returns (int112 y) {
        if (x != (y = int112(x))) _revertOverflow();
    }

    function toInt120(int256 x) internal pure returns (int120 y) {
        if (x != (y = int120(x))) _revertOverflow();
    }

    function toInt128(int256 x) internal pure returns (int128 y) {
        if (x != (y = int128(x))) _revertOverflow();
    }

    function toInt136(int256 x) internal pure returns (int136 y) {
        if (x != (y = int136(x))) _revertOverflow();
    }

    function toInt144(int256 x) internal pure returns (int144 y) {
        if (x != (y = int144(x))) _revertOverflow();
    }

    function toInt152(int256 x) internal pure returns (int152 y) {
        if (x != (y = int152(x))) _revertOverflow();
    }

    function toInt160(int256 x) internal pure returns (int160 y) {
        if (x != (y = int160(x))) _revertOverflow();
    }

    function toInt168(int256 x) internal pure returns (int168 y) {
        if (x != (y = int168(x))) _revertOverflow();
    }

    function toInt176(int256 x) internal pure returns (int176 y) {
        if (x != (y = int176(x))) _revertOverflow();
    }

    function toInt184(int256 x) internal pure returns (int184 y) {
        if (x != (y = int184(x))) _revertOverflow();
    }

    function toInt192(int256 x) internal pure returns (int192 y) {
        if (x != (y = int192(x))) _revertOverflow();
    }

    function toInt200(int256 x) internal pure returns (int200 y) {
        if (x != (y = int200(x))) _revertOverflow();
    }

    function toInt208(int256 x) internal pure returns (int208 y) {
        if (x != (y = int208(x))) _revertOverflow();
    }

    function toInt216(int256 x) internal pure returns (int216 y) {
        if (x != (y = int216(x))) _revertOverflow();
    }

    function toInt224(int256 x) internal pure returns (int224 y) {
        if (x != (y = int224(x))) _revertOverflow();
    }

    function toInt232(int256 x) internal pure returns (int232 y) {
        if (x != (y = int232(x))) _revertOverflow();
    }

    function toInt240(int256 x) internal pure returns (int240 y) {
        if (x != (y = int240(x))) _revertOverflow();
    }

    function toInt248(int256 x) internal pure returns (int248 y) {
        if (x != (y = int248(x))) _revertOverflow();
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               OTHER SAFE CASTING OPERATIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function toInt8(uint256 x) internal pure returns (int8) {
        if (x >= 1 << 7) _revertOverflow();
        return int8(int256(x));
    }

    function toInt16(uint256 x) internal pure returns (int16) {
        if (x >= 1 << 15) _revertOverflow();
        return int16(int256(x));
    }

    function toInt24(uint256 x) internal pure returns (int24) {
        if (x >= 1 << 23) _revertOverflow();
        return int24(int256(x));
    }

    function toInt32(uint256 x) internal pure returns (int32) {
        if (x >= 1 << 31) _revertOverflow();
        return int32(int256(x));
    }

    function toInt40(uint256 x) internal pure returns (int40) {
        if (x >= 1 << 39) _revertOverflow();
        return int40(int256(x));
    }

    function toInt48(uint256 x) internal pure returns (int48) {
        if (x >= 1 << 47) _revertOverflow();
        return int48(int256(x));
    }

    function toInt56(uint256 x) internal pure returns (int56) {
        if (x >= 1 << 55) _revertOverflow();
        return int56(int256(x));
    }

    function toInt64(uint256 x) internal pure returns (int64) {
        if (x >= 1 << 63) _revertOverflow();
        return int64(int256(x));
    }

    function toInt72(uint256 x) internal pure returns (int72) {
        if (x >= 1 << 71) _revertOverflow();
        return int72(int256(x));
    }

    function toInt80(uint256 x) internal pure returns (int80) {
        if (x >= 1 << 79) _revertOverflow();
        return int80(int256(x));
    }

    function toInt88(uint256 x) internal pure returns (int88) {
        if (x >= 1 << 87) _revertOverflow();
        return int88(int256(x));
    }

    function toInt96(uint256 x) internal pure returns (int96) {
        if (x >= 1 << 95) _revertOverflow();
        return int96(int256(x));
    }

    function toInt104(uint256 x) internal pure returns (int104) {
        if (x >= 1 << 103) _revertOverflow();
        return int104(int256(x));
    }

    function toInt112(uint256 x) internal pure returns (int112) {
        if (x >= 1 << 111) _revertOverflow();
        return int112(int256(x));
    }

    function toInt120(uint256 x) internal pure returns (int120) {
        if (x >= 1 << 119) _revertOverflow();
        return int120(int256(x));
    }

    function toInt128(uint256 x) internal pure returns (int128) {
        if (x >= 1 << 127) _revertOverflow();
        return int128(int256(x));
    }

    function toInt136(uint256 x) internal pure returns (int136) {
        if (x >= 1 << 135) _revertOverflow();
        return int136(int256(x));
    }

    function toInt144(uint256 x) internal pure returns (int144) {
        if (x >= 1 << 143) _revertOverflow();
        return int144(int256(x));
    }

    function toInt152(uint256 x) internal pure returns (int152) {
        if (x >= 1 << 151) _revertOverflow();
        return int152(int256(x));
    }

    function toInt160(uint256 x) internal pure returns (int160) {
        if (x >= 1 << 159) _revertOverflow();
        return int160(int256(x));
    }

    function toInt168(uint256 x) internal pure returns (int168) {
        if (x >= 1 << 167) _revertOverflow();
        return int168(int256(x));
    }

    function toInt176(uint256 x) internal pure returns (int176) {
        if (x >= 1 << 175) _revertOverflow();
        return int176(int256(x));
    }

    function toInt184(uint256 x) internal pure returns (int184) {
        if (x >= 1 << 183) _revertOverflow();
        return int184(int256(x));
    }

    function toInt192(uint256 x) internal pure returns (int192) {
        if (x >= 1 << 191) _revertOverflow();
        return int192(int256(x));
    }

    function toInt200(uint256 x) internal pure returns (int200) {
        if (x >= 1 << 199) _revertOverflow();
        return int200(int256(x));
    }

    function toInt208(uint256 x) internal pure returns (int208) {
        if (x >= 1 << 207) _revertOverflow();
        return int208(int256(x));
    }

    function toInt216(uint256 x) internal pure returns (int216) {
        if (x >= 1 << 215) _revertOverflow();
        return int216(int256(x));
    }

    function toInt224(uint256 x) internal pure returns (int224) {
        if (x >= 1 << 223) _revertOverflow();
        return int224(int256(x));
    }

    function toInt232(uint256 x) internal pure returns (int232) {
        if (x >= 1 << 231) _revertOverflow();
        return int232(int256(x));
    }

    function toInt240(uint256 x) internal pure returns (int240) {
        if (x >= 1 << 239) _revertOverflow();
        return int240(int256(x));
    }

    function toInt248(uint256 x) internal pure returns (int248) {
        if (x >= 1 << 247) _revertOverflow();
        return int248(int256(x));
    }

    function toInt256(uint256 x) internal pure returns (int256) {
        if (x >= 1 << 255) _revertOverflow();
        return int256(x);
    }

    function toUint256(int256 x) internal pure returns (uint256) {
        if (x < 0) _revertOverflow();
        return uint256(x);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _revertOverflow() private pure {
        /// @solidity memory-safe-assembly
        assembly {
            // Store the function selector of `Overflow()`.
            mstore(0x00, 0x35278d12)
            // Revert with (offset, size).
            revert(0x1c, 0x04)
        }
    }
}
