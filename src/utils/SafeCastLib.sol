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
        if (x >> 8 == uint256(0)) return uint8(x);
        _revertOverflow();
    }

    function toUint16(uint256 x) internal pure returns (uint16) {
        if (x >> 16 == uint256(0)) return uint16(x);
        _revertOverflow();
    }

    function toUint24(uint256 x) internal pure returns (uint24) {
        if (x >> 24 == uint256(0)) return uint24(x);
        _revertOverflow();
    }

    function toUint32(uint256 x) internal pure returns (uint32) {
        if (x >> 32 == uint256(0)) return uint32(x);
        _revertOverflow();
    }

    function toUint40(uint256 x) internal pure returns (uint40) {
        if (x >> 40 == uint256(0)) return uint40(x);
        _revertOverflow();
    }

    function toUint48(uint256 x) internal pure returns (uint48) {
        if (x >> 48 == uint256(0)) return uint48(x);
        _revertOverflow();
    }

    function toUint56(uint256 x) internal pure returns (uint56) {
        if (x >> 56 == uint256(0)) return uint56(x);
        _revertOverflow();
    }

    function toUint64(uint256 x) internal pure returns (uint64) {
        if (x >> 64 == uint256(0)) return uint64(x);
        _revertOverflow();
    }

    function toUint72(uint256 x) internal pure returns (uint72) {
        if (x >> 72 == uint256(0)) return uint72(x);
        _revertOverflow();
    }

    function toUint80(uint256 x) internal pure returns (uint80) {
        if (x >> 80 == uint256(0)) return uint80(x);
        _revertOverflow();
    }

    function toUint88(uint256 x) internal pure returns (uint88) {
        if (x >> 88 == uint256(0)) return uint88(x);
        _revertOverflow();
    }

    function toUint96(uint256 x) internal pure returns (uint96) {
        if (x >> 96 == uint256(0)) return uint96(x);
        _revertOverflow();
    }

    function toUint104(uint256 x) internal pure returns (uint104) {
        if (x >> 104 == uint256(0)) return uint104(x);
        _revertOverflow();
    }

    function toUint112(uint256 x) internal pure returns (uint112) {
        if (x >> 112 == uint256(0)) return uint112(x);
        _revertOverflow();
    }

    function toUint120(uint256 x) internal pure returns (uint120) {
        if (x >> 120 == uint256(0)) return uint120(x);
        _revertOverflow();
    }

    function toUint128(uint256 x) internal pure returns (uint128) {
        if (x >> 128 == uint256(0)) return uint128(x);
        _revertOverflow();
    }

    function toUint136(uint256 x) internal pure returns (uint136) {
        if (x >> 136 == uint256(0)) return uint136(x);
        _revertOverflow();
    }

    function toUint144(uint256 x) internal pure returns (uint144) {
        if (x >> 144 == uint256(0)) return uint144(x);
        _revertOverflow();
    }

    function toUint152(uint256 x) internal pure returns (uint152) {
        if (x >> 152 == uint256(0)) return uint152(x);
        _revertOverflow();
    }

    function toUint160(uint256 x) internal pure returns (uint160) {
        if (x >> 160 == uint256(0)) return uint160(x);
        _revertOverflow();
    }

    function toUint168(uint256 x) internal pure returns (uint168) {
        if (x >> 168 == uint256(0)) return uint168(x);
        _revertOverflow();
    }

    function toUint176(uint256 x) internal pure returns (uint176) {
        if (x >> 176 == uint256(0)) return uint176(x);
        _revertOverflow();
    }

    function toUint184(uint256 x) internal pure returns (uint184) {
        if (x >> 184 == uint256(0)) return uint184(x);
        _revertOverflow();
    }

    function toUint192(uint256 x) internal pure returns (uint192) {
        if (x >> 192 == uint256(0)) return uint192(x);
        _revertOverflow();
    }

    function toUint200(uint256 x) internal pure returns (uint200) {
        if (x >> 200 == uint256(0)) return uint200(x);
        _revertOverflow();
    }

    function toUint208(uint256 x) internal pure returns (uint208) {
        if (x >> 208 == uint256(0)) return uint208(x);
        _revertOverflow();
    }

    function toUint216(uint256 x) internal pure returns (uint216) {
        if (x >> 216 == uint256(0)) return uint216(x);
        _revertOverflow();
    }

    function toUint224(uint256 x) internal pure returns (uint224) {
        if (x >> 224 == uint256(0)) return uint224(x);
        _revertOverflow();
    }

    function toUint232(uint256 x) internal pure returns (uint232) {
        if (x >> 232 == uint256(0)) return uint232(x);
        _revertOverflow();
    }

    function toUint240(uint256 x) internal pure returns (uint240) {
        if (x >> 240 == uint256(0)) return uint240(x);
        _revertOverflow();
    }

    function toUint248(uint256 x) internal pure returns (uint248) {
        if (x >> 248 == uint256(0)) return uint248(x);
        _revertOverflow();
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*           SIGNED INTEGER SAFE CASTING OPERATIONS           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function toInt8(int256 x) internal pure returns (int8) {
        unchecked {
            if (((1 << 7) + uint256(x)) >> 8 == uint256(0)) return int8(x);
            _revertOverflow();
        }
    }

    function toInt16(int256 x) internal pure returns (int16) {
        unchecked {
            if (((1 << 15) + uint256(x)) >> 16 == uint256(0)) return int16(x);
            _revertOverflow();
        }
    }

    function toInt24(int256 x) internal pure returns (int24) {
        unchecked {
            if (((1 << 23) + uint256(x)) >> 24 == uint256(0)) return int24(x);
            _revertOverflow();
        }
    }

    function toInt32(int256 x) internal pure returns (int32) {
        unchecked {
            if (((1 << 31) + uint256(x)) >> 32 == uint256(0)) return int32(x);
            _revertOverflow();
        }
    }

    function toInt40(int256 x) internal pure returns (int40) {
        unchecked {
            if (((1 << 39) + uint256(x)) >> 40 == uint256(0)) return int40(x);
            _revertOverflow();
        }
    }

    function toInt48(int256 x) internal pure returns (int48) {
        unchecked {
            if (((1 << 47) + uint256(x)) >> 48 == uint256(0)) return int48(x);
            _revertOverflow();
        }
    }

    function toInt56(int256 x) internal pure returns (int56) {
        unchecked {
            if (((1 << 55) + uint256(x)) >> 56 == uint256(0)) return int56(x);
            _revertOverflow();
        }
    }

    function toInt64(int256 x) internal pure returns (int64) {
        unchecked {
            if (((1 << 63) + uint256(x)) >> 64 == uint256(0)) return int64(x);
            _revertOverflow();
        }
    }

    function toInt72(int256 x) internal pure returns (int72) {
        unchecked {
            if (((1 << 71) + uint256(x)) >> 72 == uint256(0)) return int72(x);
            _revertOverflow();
        }
    }

    function toInt80(int256 x) internal pure returns (int80) {
        unchecked {
            if (((1 << 79) + uint256(x)) >> 80 == uint256(0)) return int80(x);
            _revertOverflow();
        }
    }

    function toInt88(int256 x) internal pure returns (int88) {
        unchecked {
            if (((1 << 87) + uint256(x)) >> 88 == uint256(0)) return int88(x);
            _revertOverflow();
        }
    }

    function toInt96(int256 x) internal pure returns (int96) {
        unchecked {
            if (((1 << 95) + uint256(x)) >> 96 == uint256(0)) return int96(x);
            _revertOverflow();
        }
    }

    function toInt104(int256 x) internal pure returns (int104) {
        unchecked {
            if (((1 << 103) + uint256(x)) >> 104 == uint256(0)) return int104(x);
            _revertOverflow();
        }
    }

    function toInt112(int256 x) internal pure returns (int112) {
        unchecked {
            if (((1 << 111) + uint256(x)) >> 112 == uint256(0)) return int112(x);
            _revertOverflow();
        }
    }

    function toInt120(int256 x) internal pure returns (int120) {
        unchecked {
            if (((1 << 119) + uint256(x)) >> 120 == uint256(0)) return int120(x);
            _revertOverflow();
        }
    }

    function toInt128(int256 x) internal pure returns (int128) {
        unchecked {
            if (((1 << 127) + uint256(x)) >> 128 == uint256(0)) return int128(x);
            _revertOverflow();
        }
    }

    function toInt136(int256 x) internal pure returns (int136) {
        unchecked {
            if (((1 << 135) + uint256(x)) >> 136 == uint256(0)) return int136(x);
            _revertOverflow();
        }
    }

    function toInt144(int256 x) internal pure returns (int144) {
        unchecked {
            if (((1 << 143) + uint256(x)) >> 144 == uint256(0)) return int144(x);
            _revertOverflow();
        }
    }

    function toInt152(int256 x) internal pure returns (int152) {
        unchecked {
            if (((1 << 151) + uint256(x)) >> 152 == uint256(0)) return int152(x);
            _revertOverflow();
        }
    }

    function toInt160(int256 x) internal pure returns (int160) {
        unchecked {
            if (((1 << 159) + uint256(x)) >> 160 == uint256(0)) return int160(x);
            _revertOverflow();
        }
    }

    function toInt168(int256 x) internal pure returns (int168) {
        unchecked {
            if (((1 << 167) + uint256(x)) >> 168 == uint256(0)) return int168(x);
            _revertOverflow();
        }
    }

    function toInt176(int256 x) internal pure returns (int176) {
        unchecked {
            if (((1 << 175) + uint256(x)) >> 176 == uint256(0)) return int176(x);
            _revertOverflow();
        }
    }

    function toInt184(int256 x) internal pure returns (int184) {
        unchecked {
            if (((1 << 183) + uint256(x)) >> 184 == uint256(0)) return int184(x);
            _revertOverflow();
        }
    }

    function toInt192(int256 x) internal pure returns (int192) {
        unchecked {
            if (((1 << 191) + uint256(x)) >> 192 == uint256(0)) return int192(x);
            _revertOverflow();
        }
    }

    function toInt200(int256 x) internal pure returns (int200) {
        unchecked {
            if (((1 << 199) + uint256(x)) >> 200 == uint256(0)) return int200(x);
            _revertOverflow();
        }
    }

    function toInt208(int256 x) internal pure returns (int208) {
        unchecked {
            if (((1 << 207) + uint256(x)) >> 208 == uint256(0)) return int208(x);
            _revertOverflow();
        }
    }

    function toInt216(int256 x) internal pure returns (int216) {
        unchecked {
            if (((1 << 215) + uint256(x)) >> 216 == uint256(0)) return int216(x);
            _revertOverflow();
        }
    }

    function toInt224(int256 x) internal pure returns (int224) {
        unchecked {
            if (((1 << 223) + uint256(x)) >> 224 == uint256(0)) return int224(x);
            _revertOverflow();
        }
    }

    function toInt232(int256 x) internal pure returns (int232) {
        unchecked {
            if (((1 << 231) + uint256(x)) >> 232 == uint256(0)) return int232(x);
            _revertOverflow();
        }
    }

    function toInt240(int256 x) internal pure returns (int240) {
        unchecked {
            if (((1 << 239) + uint256(x)) >> 240 == uint256(0)) return int240(x);
            _revertOverflow();
        }
    }

    function toInt248(int256 x) internal pure returns (int248) {
        unchecked {
            if (((1 << 247) + uint256(x)) >> 248 == uint256(0)) return int248(x);
            _revertOverflow();
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               OTHER SAFE CASTING OPERATIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function toInt8(uint256 x) internal pure returns (int8) {
        if (x >> 7 == uint256(0)) return int8(int256(x));
        _revertOverflow();
    }

    function toInt16(uint256 x) internal pure returns (int16) {
        if (x >> 15 == uint256(0)) return int16(int256(x));
        _revertOverflow();
    }

    function toInt24(uint256 x) internal pure returns (int24) {
        if (x >> 23 == uint256(0)) return int24(int256(x));
        _revertOverflow();
    }

    function toInt32(uint256 x) internal pure returns (int32) {
        if (x >> 31 == uint256(0)) return int32(int256(x));
        _revertOverflow();
    }

    function toInt40(uint256 x) internal pure returns (int40) {
        if (x >> 39 == uint256(0)) return int40(int256(x));
        _revertOverflow();
    }

    function toInt48(uint256 x) internal pure returns (int48) {
        if (x >> 47 == uint256(0)) return int48(int256(x));
        _revertOverflow();
    }

    function toInt56(uint256 x) internal pure returns (int56) {
        if (x >> 55 == uint256(0)) return int56(int256(x));
        _revertOverflow();
    }

    function toInt64(uint256 x) internal pure returns (int64) {
        if (x >> 63 == uint256(0)) return int64(int256(x));
        _revertOverflow();
    }

    function toInt72(uint256 x) internal pure returns (int72) {
        if (x >> 71 == uint256(0)) return int72(int256(x));
        _revertOverflow();
    }

    function toInt80(uint256 x) internal pure returns (int80) {
        if (x >> 79 == uint256(0)) return int80(int256(x));
        _revertOverflow();
    }

    function toInt88(uint256 x) internal pure returns (int88) {
        if (x >> 87 == uint256(0)) return int88(int256(x));
        _revertOverflow();
    }

    function toInt96(uint256 x) internal pure returns (int96) {
        if (x >> 95 == uint256(0)) return int96(int256(x));
        _revertOverflow();
    }

    function toInt104(uint256 x) internal pure returns (int104) {
        if (x >> 103 == uint256(0)) return int104(int256(x));
        _revertOverflow();
    }

    function toInt112(uint256 x) internal pure returns (int112) {
        if (x >> 111 == uint256(0)) return int112(int256(x));
        _revertOverflow();
    }

    function toInt120(uint256 x) internal pure returns (int120) {
        if (x >> 119 == uint256(0)) return int120(int256(x));
        _revertOverflow();
    }

    function toInt128(uint256 x) internal pure returns (int128) {
        if (x >> 127 == uint256(0)) return int128(int256(x));
        _revertOverflow();
    }

    function toInt136(uint256 x) internal pure returns (int136) {
        if (x >> 135 == uint256(0)) return int136(int256(x));
        _revertOverflow();
    }

    function toInt144(uint256 x) internal pure returns (int144) {
        if (x >> 143 == uint256(0)) return int144(int256(x));
        _revertOverflow();
    }

    function toInt152(uint256 x) internal pure returns (int152) {
        if (x >> 151 == uint256(0)) return int152(int256(x));
        _revertOverflow();
    }

    function toInt160(uint256 x) internal pure returns (int160) {
        if (x >> 159 == uint256(0)) return int160(int256(x));
        _revertOverflow();
    }

    function toInt168(uint256 x) internal pure returns (int168) {
        if (x >> 167 == uint256(0)) return int168(int256(x));
        _revertOverflow();
    }

    function toInt176(uint256 x) internal pure returns (int176) {
        if (x >> 175 == uint256(0)) return int176(int256(x));
        _revertOverflow();
    }

    function toInt184(uint256 x) internal pure returns (int184) {
        if (x >> 183 == uint256(0)) return int184(int256(x));
        _revertOverflow();
    }

    function toInt192(uint256 x) internal pure returns (int192) {
        if (x >> 191 == uint256(0)) return int192(int256(x));
        _revertOverflow();
    }

    function toInt200(uint256 x) internal pure returns (int200) {
        if (x >> 199 == uint256(0)) return int200(int256(x));
        _revertOverflow();
    }

    function toInt208(uint256 x) internal pure returns (int208) {
        if (x >> 207 == uint256(0)) return int208(int256(x));
        _revertOverflow();
    }

    function toInt216(uint256 x) internal pure returns (int216) {
        if (x >> 215 == uint256(0)) return int216(int256(x));
        _revertOverflow();
    }

    function toInt224(uint256 x) internal pure returns (int224) {
        if (x >> 223 == uint256(0)) return int224(int256(x));
        _revertOverflow();
    }

    function toInt232(uint256 x) internal pure returns (int232) {
        if (x >> 231 == uint256(0)) return int232(int256(x));
        _revertOverflow();
    }

    function toInt240(uint256 x) internal pure returns (int240) {
        if (x >> 239 == uint256(0)) return int240(int256(x));
        _revertOverflow();
    }

    function toInt248(uint256 x) internal pure returns (int248) {
        if (x >> 247 == uint256(0)) return int248(int256(x));
        _revertOverflow();
    }

    function toInt256(uint256 x) internal pure returns (int256) {
        bool overflows;
        /// @solidity memory-safe-assembly
        assembly {
            overflows := slt(x, 0)
        }
        if (!overflows) return int256(x);
        _revertOverflow();
    }

    function toUint256(int256 x) internal pure returns (uint256) {
        bool overflows;
        /// @solidity memory-safe-assembly
        assembly {
            overflows := slt(x, 0)
        }
        if (!overflows) return uint256(x);
        _revertOverflow();
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
