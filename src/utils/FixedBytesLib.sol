// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for bytes1 to bytes32.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/FixedBytesLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedBytesLib.sol)
library FixedBytesLib {
    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes1 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 1)
            mstore(add(result, 0x20), shl(248, shr(248, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes2 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 2)
            mstore(add(result, 0x20), shl(240, shr(240, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes3 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 3)
            mstore(add(result, 0x20), shl(232, shr(232, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes4 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 4)
            mstore(add(result, 0x20), shl(224, shr(224, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes5 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 5)
            mstore(add(result, 0x20), shl(216, shr(216, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes6 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 6)
            mstore(add(result, 0x20), shl(208, shr(208, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes7 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 7)
            mstore(add(result, 0x20), shl(200, shr(200, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes8 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 8)
            mstore(add(result, 0x20), shl(192, shr(192, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes9 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 9)
            mstore(add(result, 0x20), shl(184, shr(184, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes10 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 10)
            mstore(add(result, 0x20), shl(176, shr(176, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes11 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 11)
            mstore(add(result, 0x20), shl(168, shr(168, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes12 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 12)
            mstore(add(result, 0x20), shl(160, shr(160, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes13 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 13)
            mstore(add(result, 0x20), shl(152, shr(152, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes14 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 14)
            mstore(add(result, 0x20), shl(144, shr(144, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes15 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 15)
            mstore(add(result, 0x20), shl(136, shr(136, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes16 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 16)
            mstore(add(result, 0x20), shl(128, shr(128, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes17 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 17)
            mstore(add(result, 0x20), shl(120, shr(120, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes18 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 18)
            mstore(add(result, 0x20), shl(112, shr(112, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes19 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 19)
            mstore(add(result, 0x20), shl(104, shr(104, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes20 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 20)
            mstore(add(result, 0x20), shl(96, shr(96, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes21 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 21)
            mstore(add(result, 0x20), shl(88, shr(88, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes22 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 22)
            mstore(add(result, 0x20), shl(80, shr(80, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes23 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 23)
            mstore(add(result, 0x20), shl(72, shr(72, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes24 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 24)
            mstore(add(result, 0x20), shl(64, shr(64, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes25 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 25)
            mstore(add(result, 0x20), shl(56, shr(56, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes26 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 26)
            mstore(add(result, 0x20), shl(48, shr(48, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes27 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 27)
            mstore(add(result, 0x20), shl(40, shr(40, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes28 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 28)
            mstore(add(result, 0x20), shl(32, shr(32, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes29 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 29)
            mstore(add(result, 0x20), shl(24, shr(24, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes30 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 30)
            mstore(add(result, 0x20), shl(16, shr(16, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes31 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 31)
            mstore(add(result, 0x20), shl(8, shr(8, x)))
            mstore(0x40, add(result, 0x40))
        }
    }

    /// @dev Returns `abi.encodePacked(x)`, but more efficiently.
    function toBytes(bytes32 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 32)
            mstore(add(result, 0x20), shl(0, shr(0, x)))
            mstore(0x40, add(result, 0x40))
        }
    }
}
