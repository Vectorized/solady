// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe integer casting library that reverts on overflow.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*          UNSIGNED INTEGER SAFE CASTING OPERATIONS          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function toUint8(uint256 x) internal pure returns (uint8 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(8, x))
            y := x
        }
    }

    function toUint16(uint256 x) internal pure returns (uint16 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(16, x))
            y := x
        }
    }

    function toUint24(uint256 x) internal pure returns (uint24 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(24, x))
            y := x
        }
    }

    function toUint32(uint256 x) internal pure returns (uint32 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(32, x))
            y := x
        }
    }

    function toUint40(uint256 x) internal pure returns (uint40 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(40, x))
            y := x
        }
    }

    function toUint48(uint256 x) internal pure returns (uint48 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(48, x))
            y := x
        }
    }

    function toUint56(uint256 x) internal pure returns (uint56 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(56, x))
            y := x
        }
    }

    function toUint64(uint256 x) internal pure returns (uint64 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(64, x))
            y := x
        }
    }

    function toUint72(uint256 x) internal pure returns (uint72 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(72, x))
            y := x
        }
    }

    function toUint80(uint256 x) internal pure returns (uint80 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(80, x))
            y := x
        }
    }

    function toUint88(uint256 x) internal pure returns (uint88 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(88, x))
            y := x
        }
    }

    function toUint96(uint256 x) internal pure returns (uint96 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(96, x))
            y := x
        }
    }

    function toUint104(uint256 x) internal pure returns (uint104 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(104, x))
            y := x
        }
    }

    function toUint112(uint256 x) internal pure returns (uint112 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(112, x))
            y := x
        }
    }

    function toUint120(uint256 x) internal pure returns (uint120 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(120, x))
            y := x
        }
    }

    function toUint128(uint256 x) internal pure returns (uint128 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(128, x))
            y := x
        }
    }

    function toUint136(uint256 x) internal pure returns (uint136 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(136, x))
            y := x
        }
    }

    function toUint144(uint256 x) internal pure returns (uint144 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(144, x))
            y := x
        }
    }

    function toUint152(uint256 x) internal pure returns (uint152 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(152, x))
            y := x
        }
    }

    function toUint160(uint256 x) internal pure returns (uint160 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(160, x))
            y := x
        }
    }

    function toUint168(uint256 x) internal pure returns (uint168 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(168, x))
            y := x
        }
    }

    function toUint176(uint256 x) internal pure returns (uint176 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(176, x))
            y := x
        }
    }

    function toUint184(uint256 x) internal pure returns (uint184 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(184, x))
            y := x
        }
    }

    function toUint192(uint256 x) internal pure returns (uint192 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(192, x))
            y := x
        }
    }

    function toUint200(uint256 x) internal pure returns (uint200 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(200, x))
            y := x
        }
    }

    function toUint208(uint256 x) internal pure returns (uint208 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(208, x))
            y := x
        }
    }

    function toUint216(uint256 x) internal pure returns (uint216 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(216, x))
            y := x
        }
    }

    function toUint224(uint256 x) internal pure returns (uint224 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(224, x))
            y := x
        }
    }

    function toUint232(uint256 x) internal pure returns (uint232 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(232, x))
            y := x
        }
    }

    function toUint240(uint256 x) internal pure returns (uint240 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(240, x))
            y := x
        }
    }

    function toUint248(uint256 x) internal pure returns (uint248 y) {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(248, x))
            y := x
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*           SIGNED INTEGER SAFE CASTING OPERATIONS           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function toInt8(int256 x) internal pure returns (int8 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(0, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }

    function toInt16(int256 x) internal pure returns (int16 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(1, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }

    function toInt24(int256 x) internal pure returns (int24 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(2, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }

    function toInt32(int256 x) internal pure returns (int32 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(3, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }

    function toInt40(int256 x) internal pure returns (int40 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(4, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }

    function toInt48(int256 x) internal pure returns (int48 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(5, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }

    function toInt56(int256 x) internal pure returns (int56 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(6, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }

    function toInt64(int256 x) internal pure returns (int64 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(7, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }

    function toInt72(int256 x) internal pure returns (int72 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(8, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }

    function toInt80(int256 x) internal pure returns (int80 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(9, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }

    function toInt88(int256 x) internal pure returns (int88 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(10, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }

    function toInt96(int256 x) internal pure returns (int96 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(11, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }

    function toInt104(int256 x) internal pure returns (int104 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(12, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }

    function toInt112(int256 x) internal pure returns (int112 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(13, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }

    function toInt120(int256 x) internal pure returns (int120 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(14, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }

    function toInt128(int256 x) internal pure returns (int128 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(15, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }

    function toInt136(int256 x) internal pure returns (int136 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(16, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }

    function toInt144(int256 x) internal pure returns (int144 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(17, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }

    function toInt152(int256 x) internal pure returns (int152 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(18, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }

    function toInt160(int256 x) internal pure returns (int160 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(19, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }

    function toInt168(int256 x) internal pure returns (int168 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(20, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }

    function toInt176(int256 x) internal pure returns (int176 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(21, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }

    function toInt184(int256 x) internal pure returns (int184 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(22, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }

    function toInt192(int256 x) internal pure returns (int192 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(23, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }

    function toInt200(int256 x) internal pure returns (int200 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(24, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }

    function toInt208(int256 x) internal pure returns (int208 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(25, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }

    function toInt216(int256 x) internal pure returns (int216 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(26, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }

    function toInt224(int256 x) internal pure returns (int224 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(27, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }

    function toInt232(int256 x) internal pure returns (int232 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(28, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }

    function toInt240(int256 x) internal pure returns (int240 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(29, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }

    function toInt248(int256 x) internal pure returns (int248 y) {
        /// @solidity memory-safe-assembly
        assembly {
            y := signextend(30, x)
            returndatacopy(returndatasize(), returndatasize(), xor(x, y))
        }
    }
}
