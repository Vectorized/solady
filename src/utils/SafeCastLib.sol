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
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(8, x))
            y := x
        }
    }

    function toUint16(uint256 x) internal pure returns (uint16 y) {
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(16, x))
            y := x
        }
    }

    function toUint24(uint256 x) internal pure returns (uint24 y) {
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(24, x))
            y := x
        }
    }

    function toUint32(uint256 x) internal pure returns (uint32 y) {
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(32, x))
            y := x
        }
    }

    function toUint40(uint256 x) internal pure returns (uint40 y) {
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(40, x))
            y := x
        }
    }

    function toUint48(uint256 x) internal pure returns (uint48 y) {
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(48, x))
            y := x
        }
    }

    function toUint56(uint256 x) internal pure returns (uint56 y) {
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(56, x))
            y := x
        }
    }

    function toUint64(uint256 x) internal pure returns (uint64 y) {
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(64, x))
            y := x
        }
    }

    function toUint72(uint256 x) internal pure returns (uint72 y) {
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(72, x))
            y := x
        }
    }

    function toUint80(uint256 x) internal pure returns (uint80 y) {
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(80, x))
            y := x
        }
    }

    function toUint88(uint256 x) internal pure returns (uint88 y) {
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(88, x))
            y := x
        }
    }

    function toUint96(uint256 x) internal pure returns (uint96 y) {
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(96, x))
            y := x
        }
    }

    function toUint104(uint256 x) internal pure returns (uint104 y) {
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(104, x))
            y := x
        }
    }

    function toUint112(uint256 x) internal pure returns (uint112 y) {
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(112, x))
            y := x
        }
    }

    function toUint120(uint256 x) internal pure returns (uint120 y) {
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(120, x))
            y := x
        }
    }

    function toUint128(uint256 x) internal pure returns (uint128 y) {
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(128, x))
            y := x
        }
    }

    function toUint136(uint256 x) internal pure returns (uint136 y) {
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(136, x))
            y := x
        }
    }

    function toUint144(uint256 x) internal pure returns (uint144 y) {
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(144, x))
            y := x
        }
    }

    function toUint152(uint256 x) internal pure returns (uint152 y) {
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(152, x))
            y := x
        }
    }

    function toUint160(uint256 x) internal pure returns (uint160 y) {
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(160, x))
            y := x
        }
    }

    function toUint168(uint256 x) internal pure returns (uint168 y) {
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(168, x))
            y := x
        }
    }

    function toUint176(uint256 x) internal pure returns (uint176 y) {
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(176, x))
            y := x
        }
    }

    function toUint184(uint256 x) internal pure returns (uint184 y) {
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(184, x))
            y := x
        }
    }

    function toUint192(uint256 x) internal pure returns (uint192 y) {
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(192, x))
            y := x
        }
    }

    function toUint200(uint256 x) internal pure returns (uint200 y) {
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(200, x))
            y := x
        }
    }

    function toUint208(uint256 x) internal pure returns (uint208 y) {
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(208, x))
            y := x
        }
    }

    function toUint216(uint256 x) internal pure returns (uint216 y) {
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(216, x))
            y := x
        }
    }

    function toUint224(uint256 x) internal pure returns (uint224 y) {
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(224, x))
            y := x
        }
    }

    function toUint232(uint256 x) internal pure returns (uint232 y) {
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(232, x))
            y := x
        }
    }

    function toUint240(uint256 x) internal pure returns (uint240 y) {
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(240, x))
            y := x
        }
    }

    function toUint248(uint256 x) internal pure returns (uint248 y) {
        assembly {
            returndatacopy(returndatasize(), returndatasize(), shr(248, x))
            y := x
        }
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
