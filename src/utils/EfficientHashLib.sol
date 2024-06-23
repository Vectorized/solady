// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for efficiently performing keccak256 hashes.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/EfficientHashLib.sol)
library EfficientHashLib {
    /// @dev Returns `keccak256(abi.encode(value0))`.
    function hash(bytes32 value0) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, value0)
            result := keccak256(0x00, 0x20)
        }
    }

    /// @dev Returns `keccak256(abi.encode(value0, value1))`.
    function hash(bytes32 value0, bytes32 value1) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, value0)
            mstore(0x20, value1)
            result := keccak256(0x00, 0x40)
        }
    }

    /// @dev Returns `keccak256(abi.encode(value0, value1, value2))`.
    function hash(bytes32 value0, bytes32 value1, bytes32 value2)
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
            result := keccak256(m, 0x60)
        }
    }

    /// @dev Returns `keccak256(abi.encode(value0, value1, value2, value3))`.
    function hash(bytes32 value0, bytes32 value1, bytes32 value2, bytes32 value3)
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
            result := keccak256(m, 0x80)
        }
    }

    /// @dev Returns `keccak256(abi.encode(value0, .., value4))`.
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

    /// @dev Returns `keccak256(abi.encode(value0, .., value5))`.
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

    /// @dev Returns `keccak256(abi.encode(value0, .., value6))`.
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

    /// @dev Returns `keccak256(abi.encode(value0, .., value7))`.
    function hash(
        bytes32 value0,
        bytes32 value1,
        bytes32 value2,
        bytes32 value3,
        bytes32 value4,
        bytes32 value5,
        bytes32 value6,
        bytes32 value7
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
            mstore(add(m, 0xe0), value7)
            result := keccak256(m, 0x100)
        }
    }

    /// @dev Returns `keccak256(abi.encode(buffer[0], .., value[n-1]))`.
    function hash(bytes32[] memory buffer, uint256 n) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := keccak256(add(buffer, 0x20), shl(5, n))
        }
    }

    /// @dev Sets `buffer[i]` to value.
    function set(bytes32[] memory buffer, uint256 i, bytes32 value) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(add(buffer, shl(5, add(1, i))), value)
        }
    }

    /// @dev Returns `new bytes32[](n)`, but without zeroing out the memory.
    function malloc(uint256 n) internal pure returns (bytes32[] memory buffer) {
        /// @solidity memory-safe-assembly
        assembly {
            buffer := mload(0x40)
            mstore(buffer, n)
            mstore(0x40, add(buffer, shl(5, add(1, n))))
        }
    }

    /// @dev Frees memory that has been created by `malloc`.
    function free(bytes32[] memory buffer) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let t := eq(add(buffer, shl(5, add(1, mload(buffer)))), m)
            mstore(0x40, xor(m, mul(xor(m, buffer), t)))
        }
    }
}
