// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for efficiently performing keccak256 hashes.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/EfficientHashLib.sol)
library EfficientHashLib {
    function hash(bytes32 value0) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, value0)
            result := keccak256(0x00, 0x20)
        }
    }

    function hash(bytes32 value0, bytes32 value1) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, value0)
            mstore(0x20, value1)
            result := keccak256(0x00, 0x40)
        }
    }

    function hash(bytes32 value0, bytes32 value1, bytes32 value2)
        internal
        pure
        returns (bytes32 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(0x00, value0)
            mstore(0x20, value1)
            mstore(0x40, value2)
            result := keccak256(0x00, 0x60)
            mstore(0x40, m)
        }
    }

    function hash(bytes32 value0, bytes32 value1, bytes32 value2, bytes32 value3)
        internal
        pure
        returns (bytes32 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(0x00, value0)
            mstore(0x20, value1)
            mstore(0x40, value2)
            mstore(0x60, value3)
            result := keccak256(0x00, 0x80)
            mstore(0x40, m)
            mstore(0x60, 0)
        }
    }

    function hash(bytes32 value0, bytes32 value1, bytes32 value2, bytes32 value3, bytes32 value4)
        internal
        pure
        returns (bytes32 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, value0)
            mstore(add(m, 0x20), value1)
            mstore(add(m, 0x40), value2)
            mstore(add(m, 0x60), value3)
            mstore(add(m, 0x80), value4)
            result := keccak256(m, 0xa0)
        }
    }

    function hash(
        bytes32 value0,
        bytes32 value1,
        bytes32 value2,
        bytes32 value3,
        bytes32 value4,
        bytes32 value5
    ) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, value0)
            mstore(add(m, 0x20), value1)
            mstore(add(m, 0x40), value2)
            mstore(add(m, 0x60), value3)
            mstore(add(m, 0x80), value4)
            mstore(add(m, 0xa0), value5)
            result := keccak256(m, 0xc0)
        }
    }

    function hash(
        bytes32 value0,
        bytes32 value1,
        bytes32 value2,
        bytes32 value3,
        bytes32 value4,
        bytes32 value5,
        bytes32 value6
    ) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, value0)
            mstore(add(m, 0x20), value1)
            mstore(add(m, 0x40), value2)
            mstore(add(m, 0x60), value3)
            mstore(add(m, 0x80), value4)
            mstore(add(m, 0xa0), value5)
            mstore(add(m, 0xc0), value6)
            result := keccak256(m, 0xe0)
        }
    }

    function hash(bytes32[] memory buffer, uint256 n) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := keccak256(add(buffer, 0x20), shl(5, n))
        }
    }

    function set(bytes32[] memory buffer, uint256 i, bytes32 value) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(add(add(buffer, 0x20), shl(5, i)), value)
        }
    }

    function malloc(uint256 n) internal pure returns (bytes32[] memory buffer) {
        /// @solidity memory-safe-assembly
        assembly {
            buffer := mload(0x40)
            mstore(buffer, n)
            mstore(0x40, add(add(buffer, 0x20), shl(5, n)))
        }
    }

    function free(bytes32[] memory buffer) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            if eq(add(add(buffer, 0x20), shl(5, mload(buffer))), mload(0x40)) {
                mstore(0x40, buffer)
            }
        }
    }
}
