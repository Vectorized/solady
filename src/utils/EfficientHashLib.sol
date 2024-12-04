// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for efficiently performing keccak256 hashes.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/EfficientHashLib.sol)
/// @dev To avoid stack-too-deep, you can use:
/// ```
/// bytes32[] memory buffer = EfficientHashLib.malloc(10);
/// EfficientHashLib.set(buffer, 0, value0);
/// ..
/// EfficientHashLib.set(buffer, 9, value9);
/// bytes32 finalHash = EfficientHashLib.hash(buffer);
/// ```
library EfficientHashLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               MALLOC-LESS HASHING OPERATIONS               */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns `keccak256(abi.encode(v0))`.
    function hash(bytes32 v0) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, v0)
            result := keccak256(0x00, 0x20)
        }
    }

    /// @dev Returns `keccak256(abi.encode(v0))`.
    function hash(uint256 v0) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, v0)
            result := keccak256(0x00, 0x20)
        }
    }

    /// @dev Returns `keccak256(abi.encode(v0, v1))`.
    function hash(bytes32 v0, bytes32 v1) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, v0)
            mstore(0x20, v1)
            result := keccak256(0x00, 0x40)
        }
    }

    /// @dev Returns `keccak256(abi.encode(v0, v1))`.
    function hash(uint256 v0, uint256 v1) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, v0)
            mstore(0x20, v1)
            result := keccak256(0x00, 0x40)
        }
    }

    /// @dev Returns `keccak256(abi.encode(v0, v1, v2))`.
    function hash(bytes32 v0, bytes32 v1, bytes32 v2) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, v0)
            mstore(add(m, 0x20), v1)
            mstore(add(m, 0x40), v2)
            result := keccak256(m, 0x60)
        }
    }

    /// @dev Returns `keccak256(abi.encode(v0, v1, v2))`.
    function hash(uint256 v0, uint256 v1, uint256 v2) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, v0)
            mstore(add(m, 0x20), v1)
            mstore(add(m, 0x40), v2)
            result := keccak256(m, 0x60)
        }
    }

    /// @dev Returns `keccak256(abi.encode(v0, v1, v2, v3))`.
    function hash(bytes32 v0, bytes32 v1, bytes32 v2, bytes32 v3)
        internal
        pure
        returns (bytes32 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, v0)
            mstore(add(m, 0x20), v1)
            mstore(add(m, 0x40), v2)
            mstore(add(m, 0x60), v3)
            result := keccak256(m, 0x80)
        }
    }

    /// @dev Returns `keccak256(abi.encode(v0, v1, v2, v3))`.
    function hash(uint256 v0, uint256 v1, uint256 v2, uint256 v3)
        internal
        pure
        returns (bytes32 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, v0)
            mstore(add(m, 0x20), v1)
            mstore(add(m, 0x40), v2)
            mstore(add(m, 0x60), v3)
            result := keccak256(m, 0x80)
        }
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v4))`.
    function hash(bytes32 v0, bytes32 v1, bytes32 v2, bytes32 v3, bytes32 v4)
        internal
        pure
        returns (bytes32 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, v0)
            mstore(add(m, 0x20), v1)
            mstore(add(m, 0x40), v2)
            mstore(add(m, 0x60), v3)
            mstore(add(m, 0x80), v4)
            result := keccak256(m, 0xa0)
        }
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v4))`.
    function hash(uint256 v0, uint256 v1, uint256 v2, uint256 v3, uint256 v4)
        internal
        pure
        returns (bytes32 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, v0)
            mstore(add(m, 0x20), v1)
            mstore(add(m, 0x40), v2)
            mstore(add(m, 0x60), v3)
            mstore(add(m, 0x80), v4)
            result := keccak256(m, 0xa0)
        }
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v5))`.
    function hash(bytes32 v0, bytes32 v1, bytes32 v2, bytes32 v3, bytes32 v4, bytes32 v5)
        internal
        pure
        returns (bytes32 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, v0)
            mstore(add(m, 0x20), v1)
            mstore(add(m, 0x40), v2)
            mstore(add(m, 0x60), v3)
            mstore(add(m, 0x80), v4)
            mstore(add(m, 0xa0), v5)
            result := keccak256(m, 0xc0)
        }
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v5))`.
    function hash(uint256 v0, uint256 v1, uint256 v2, uint256 v3, uint256 v4, uint256 v5)
        internal
        pure
        returns (bytes32 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, v0)
            mstore(add(m, 0x20), v1)
            mstore(add(m, 0x40), v2)
            mstore(add(m, 0x60), v3)
            mstore(add(m, 0x80), v4)
            mstore(add(m, 0xa0), v5)
            result := keccak256(m, 0xc0)
        }
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v6))`.
    function hash(
        bytes32 v0,
        bytes32 v1,
        bytes32 v2,
        bytes32 v3,
        bytes32 v4,
        bytes32 v5,
        bytes32 v6
    ) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, v0)
            mstore(add(m, 0x20), v1)
            mstore(add(m, 0x40), v2)
            mstore(add(m, 0x60), v3)
            mstore(add(m, 0x80), v4)
            mstore(add(m, 0xa0), v5)
            mstore(add(m, 0xc0), v6)
            result := keccak256(m, 0xe0)
        }
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v6))`.
    function hash(
        uint256 v0,
        uint256 v1,
        uint256 v2,
        uint256 v3,
        uint256 v4,
        uint256 v5,
        uint256 v6
    ) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, v0)
            mstore(add(m, 0x20), v1)
            mstore(add(m, 0x40), v2)
            mstore(add(m, 0x60), v3)
            mstore(add(m, 0x80), v4)
            mstore(add(m, 0xa0), v5)
            mstore(add(m, 0xc0), v6)
            result := keccak256(m, 0xe0)
        }
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v7))`.
    function hash(
        bytes32 v0,
        bytes32 v1,
        bytes32 v2,
        bytes32 v3,
        bytes32 v4,
        bytes32 v5,
        bytes32 v6,
        bytes32 v7
    ) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, v0)
            mstore(add(m, 0x20), v1)
            mstore(add(m, 0x40), v2)
            mstore(add(m, 0x60), v3)
            mstore(add(m, 0x80), v4)
            mstore(add(m, 0xa0), v5)
            mstore(add(m, 0xc0), v6)
            mstore(add(m, 0xe0), v7)
            result := keccak256(m, 0x100)
        }
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v7))`.
    function hash(
        uint256 v0,
        uint256 v1,
        uint256 v2,
        uint256 v3,
        uint256 v4,
        uint256 v5,
        uint256 v6,
        uint256 v7
    ) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, v0)
            mstore(add(m, 0x20), v1)
            mstore(add(m, 0x40), v2)
            mstore(add(m, 0x60), v3)
            mstore(add(m, 0x80), v4)
            mstore(add(m, 0xa0), v5)
            mstore(add(m, 0xc0), v6)
            mstore(add(m, 0xe0), v7)
            result := keccak256(m, 0x100)
        }
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v8))`.
    function hash(
        bytes32 v0,
        bytes32 v1,
        bytes32 v2,
        bytes32 v3,
        bytes32 v4,
        bytes32 v5,
        bytes32 v6,
        bytes32 v7,
        bytes32 v8
    ) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, v0)
            mstore(add(m, 0x20), v1)
            mstore(add(m, 0x40), v2)
            mstore(add(m, 0x60), v3)
            mstore(add(m, 0x80), v4)
            mstore(add(m, 0xa0), v5)
            mstore(add(m, 0xc0), v6)
            mstore(add(m, 0xe0), v7)
            mstore(add(m, 0x100), v8)
            result := keccak256(m, 0x120)
        }
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v8))`.
    function hash(
        uint256 v0,
        uint256 v1,
        uint256 v2,
        uint256 v3,
        uint256 v4,
        uint256 v5,
        uint256 v6,
        uint256 v7,
        uint256 v8
    ) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, v0)
            mstore(add(m, 0x20), v1)
            mstore(add(m, 0x40), v2)
            mstore(add(m, 0x60), v3)
            mstore(add(m, 0x80), v4)
            mstore(add(m, 0xa0), v5)
            mstore(add(m, 0xc0), v6)
            mstore(add(m, 0xe0), v7)
            mstore(add(m, 0x100), v8)
            result := keccak256(m, 0x120)
        }
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v9))`.
    function hash(
        bytes32 v0,
        bytes32 v1,
        bytes32 v2,
        bytes32 v3,
        bytes32 v4,
        bytes32 v5,
        bytes32 v6,
        bytes32 v7,
        bytes32 v8,
        bytes32 v9
    ) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, v0)
            mstore(add(m, 0x20), v1)
            mstore(add(m, 0x40), v2)
            mstore(add(m, 0x60), v3)
            mstore(add(m, 0x80), v4)
            mstore(add(m, 0xa0), v5)
            mstore(add(m, 0xc0), v6)
            mstore(add(m, 0xe0), v7)
            mstore(add(m, 0x100), v8)
            mstore(add(m, 0x120), v9)
            result := keccak256(m, 0x140)
        }
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v9))`.
    function hash(
        uint256 v0,
        uint256 v1,
        uint256 v2,
        uint256 v3,
        uint256 v4,
        uint256 v5,
        uint256 v6,
        uint256 v7,
        uint256 v8,
        uint256 v9
    ) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, v0)
            mstore(add(m, 0x20), v1)
            mstore(add(m, 0x40), v2)
            mstore(add(m, 0x60), v3)
            mstore(add(m, 0x80), v4)
            mstore(add(m, 0xa0), v5)
            mstore(add(m, 0xc0), v6)
            mstore(add(m, 0xe0), v7)
            mstore(add(m, 0x100), v8)
            mstore(add(m, 0x120), v9)
            result := keccak256(m, 0x140)
        }
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v10))`.
    function hash(
        bytes32 v0,
        bytes32 v1,
        bytes32 v2,
        bytes32 v3,
        bytes32 v4,
        bytes32 v5,
        bytes32 v6,
        bytes32 v7,
        bytes32 v8,
        bytes32 v9,
        bytes32 v10
    ) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, v0)
            mstore(add(m, 0x20), v1)
            mstore(add(m, 0x40), v2)
            mstore(add(m, 0x60), v3)
            mstore(add(m, 0x80), v4)
            mstore(add(m, 0xa0), v5)
            mstore(add(m, 0xc0), v6)
            mstore(add(m, 0xe0), v7)
            mstore(add(m, 0x100), v8)
            mstore(add(m, 0x120), v9)
            mstore(add(m, 0x140), v10)
            result := keccak256(m, 0x160)
        }
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v10))`.
    function hash(
        uint256 v0,
        uint256 v1,
        uint256 v2,
        uint256 v3,
        uint256 v4,
        uint256 v5,
        uint256 v6,
        uint256 v7,
        uint256 v8,
        uint256 v9,
        uint256 v10
    ) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, v0)
            mstore(add(m, 0x20), v1)
            mstore(add(m, 0x40), v2)
            mstore(add(m, 0x60), v3)
            mstore(add(m, 0x80), v4)
            mstore(add(m, 0xa0), v5)
            mstore(add(m, 0xc0), v6)
            mstore(add(m, 0xe0), v7)
            mstore(add(m, 0x100), v8)
            mstore(add(m, 0x120), v9)
            mstore(add(m, 0x140), v10)
            result := keccak256(m, 0x160)
        }
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v11))`.
    function hash(
        bytes32 v0,
        bytes32 v1,
        bytes32 v2,
        bytes32 v3,
        bytes32 v4,
        bytes32 v5,
        bytes32 v6,
        bytes32 v7,
        bytes32 v8,
        bytes32 v9,
        bytes32 v10,
        bytes32 v11
    ) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, v0)
            mstore(add(m, 0x20), v1)
            mstore(add(m, 0x40), v2)
            mstore(add(m, 0x60), v3)
            mstore(add(m, 0x80), v4)
            mstore(add(m, 0xa0), v5)
            mstore(add(m, 0xc0), v6)
            mstore(add(m, 0xe0), v7)
            mstore(add(m, 0x100), v8)
            mstore(add(m, 0x120), v9)
            mstore(add(m, 0x140), v10)
            mstore(add(m, 0x160), v11)
            result := keccak256(m, 0x180)
        }
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v11))`.
    function hash(
        uint256 v0,
        uint256 v1,
        uint256 v2,
        uint256 v3,
        uint256 v4,
        uint256 v5,
        uint256 v6,
        uint256 v7,
        uint256 v8,
        uint256 v9,
        uint256 v10,
        uint256 v11
    ) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, v0)
            mstore(add(m, 0x20), v1)
            mstore(add(m, 0x40), v2)
            mstore(add(m, 0x60), v3)
            mstore(add(m, 0x80), v4)
            mstore(add(m, 0xa0), v5)
            mstore(add(m, 0xc0), v6)
            mstore(add(m, 0xe0), v7)
            mstore(add(m, 0x100), v8)
            mstore(add(m, 0x120), v9)
            mstore(add(m, 0x140), v10)
            mstore(add(m, 0x160), v11)
            result := keccak256(m, 0x180)
        }
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v12))`.
    function hash(
        bytes32 v0,
        bytes32 v1,
        bytes32 v2,
        bytes32 v3,
        bytes32 v4,
        bytes32 v5,
        bytes32 v6,
        bytes32 v7,
        bytes32 v8,
        bytes32 v9,
        bytes32 v10,
        bytes32 v11,
        bytes32 v12
    ) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, v0)
            mstore(add(m, 0x20), v1)
            mstore(add(m, 0x40), v2)
            mstore(add(m, 0x60), v3)
            mstore(add(m, 0x80), v4)
            mstore(add(m, 0xa0), v5)
            mstore(add(m, 0xc0), v6)
            mstore(add(m, 0xe0), v7)
            mstore(add(m, 0x100), v8)
            mstore(add(m, 0x120), v9)
            mstore(add(m, 0x140), v10)
            mstore(add(m, 0x160), v11)
            mstore(add(m, 0x180), v12)
            result := keccak256(m, 0x1a0)
        }
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v12))`.
    function hash(
        uint256 v0,
        uint256 v1,
        uint256 v2,
        uint256 v3,
        uint256 v4,
        uint256 v5,
        uint256 v6,
        uint256 v7,
        uint256 v8,
        uint256 v9,
        uint256 v10,
        uint256 v11,
        uint256 v12
    ) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, v0)
            mstore(add(m, 0x20), v1)
            mstore(add(m, 0x40), v2)
            mstore(add(m, 0x60), v3)
            mstore(add(m, 0x80), v4)
            mstore(add(m, 0xa0), v5)
            mstore(add(m, 0xc0), v6)
            mstore(add(m, 0xe0), v7)
            mstore(add(m, 0x100), v8)
            mstore(add(m, 0x120), v9)
            mstore(add(m, 0x140), v10)
            mstore(add(m, 0x160), v11)
            mstore(add(m, 0x180), v12)
            result := keccak256(m, 0x1a0)
        }
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v13))`.
    function hash(
        bytes32 v0,
        bytes32 v1,
        bytes32 v2,
        bytes32 v3,
        bytes32 v4,
        bytes32 v5,
        bytes32 v6,
        bytes32 v7,
        bytes32 v8,
        bytes32 v9,
        bytes32 v10,
        bytes32 v11,
        bytes32 v12,
        bytes32 v13
    ) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, v0)
            mstore(add(m, 0x20), v1)
            mstore(add(m, 0x40), v2)
            mstore(add(m, 0x60), v3)
            mstore(add(m, 0x80), v4)
            mstore(add(m, 0xa0), v5)
            mstore(add(m, 0xc0), v6)
            mstore(add(m, 0xe0), v7)
            mstore(add(m, 0x100), v8)
            mstore(add(m, 0x120), v9)
            mstore(add(m, 0x140), v10)
            mstore(add(m, 0x160), v11)
            mstore(add(m, 0x180), v12)
            mstore(add(m, 0x1a0), v13)
            result := keccak256(m, 0x1c0)
        }
    }

    /// @dev Returns `keccak256(abi.encode(v0, .., v13))`.
    function hash(
        uint256 v0,
        uint256 v1,
        uint256 v2,
        uint256 v3,
        uint256 v4,
        uint256 v5,
        uint256 v6,
        uint256 v7,
        uint256 v8,
        uint256 v9,
        uint256 v10,
        uint256 v11,
        uint256 v12,
        uint256 v13
    ) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, v0)
            mstore(add(m, 0x20), v1)
            mstore(add(m, 0x40), v2)
            mstore(add(m, 0x60), v3)
            mstore(add(m, 0x80), v4)
            mstore(add(m, 0xa0), v5)
            mstore(add(m, 0xc0), v6)
            mstore(add(m, 0xe0), v7)
            mstore(add(m, 0x100), v8)
            mstore(add(m, 0x120), v9)
            mstore(add(m, 0x140), v10)
            mstore(add(m, 0x160), v11)
            mstore(add(m, 0x180), v12)
            mstore(add(m, 0x1a0), v13)
            result := keccak256(m, 0x1c0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*             BYTES32 BUFFER HASHING OPERATIONS              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns `keccak256(abi.encode(buffer[0], .., buffer[buffer.length - 1]))`.
    function hash(bytes32[] memory buffer) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := keccak256(add(buffer, 0x20), shl(5, mload(buffer)))
        }
    }

    /// @dev Sets `buffer[i]` to `value`, without a bounds check.
    /// Returns the `buffer` for function chaining.
    function set(bytes32[] memory buffer, uint256 i, bytes32 value)
        internal
        pure
        returns (bytes32[] memory)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(add(buffer, shl(5, add(1, i))), value)
        }
        return buffer;
    }

    /// @dev Sets `buffer[i]` to `value`, without a bounds check.
    /// Returns the `buffer` for function chaining.
    function set(bytes32[] memory buffer, uint256 i, uint256 value)
        internal
        pure
        returns (bytes32[] memory)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(add(buffer, shl(5, add(1, i))), value)
        }
        return buffer;
    }

    /// @dev Returns `new bytes32[](n)`, without zeroing out the memory.
    function malloc(uint256 n) internal pure returns (bytes32[] memory buffer) {
        /// @solidity memory-safe-assembly
        assembly {
            buffer := mload(0x40)
            mstore(buffer, n)
            mstore(0x40, add(shl(5, add(1, n)), buffer))
        }
    }

    /// @dev Frees memory that has been allocated for `buffer`.
    /// No-op if `buffer.length` is zero, or if new memory has been allocated after `buffer`.
    function free(bytes32[] memory buffer) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(buffer)
            mstore(shl(6, lt(iszero(n), eq(add(shl(5, add(1, n)), buffer), mload(0x40)))), buffer)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      EQUALITY CHECKS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns `a == abi.decode(b, (bytes32))`.
    function eq(bytes32 a, bytes memory b) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := and(eq(0x20, mload(b)), eq(a, mload(add(b, 0x20))))
        }
    }

    /// @dev Returns `abi.decode(a, (bytes32)) == a`.
    function eq(bytes memory a, bytes32 b) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := and(eq(0x20, mload(a)), eq(b, mload(add(a, 0x20))))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               BYTE SLICE HASHING OPERATIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the keccak256 of the slice from `start` to `end` (exclusive).
    /// `start` and `end` are byte offsets.
    function hash(bytes memory b, uint256 start, uint256 end)
        internal
        pure
        returns (bytes32 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(b)
            end := xor(end, mul(xor(end, n), lt(n, end)))
            start := xor(start, mul(xor(start, n), lt(n, start)))
            result := keccak256(add(add(b, 0x20), start), mul(gt(end, start), sub(end, start)))
        }
    }

    /// @dev Returns the keccak256 of the slice from `start` to the end of the bytes.
    function hash(bytes memory b, uint256 start) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(b)
            start := xor(start, mul(xor(start, n), lt(n, start)))
            result := keccak256(add(add(b, 0x20), start), mul(gt(n, start), sub(n, start)))
        }
    }

    /// @dev Returns the keccak256 of the bytes.
    function hash(bytes memory b) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := keccak256(add(b, 0x20), mload(b))
        }
    }

    /// @dev Returns the keccak256 of the slice from `start` to `end` (exclusive).
    /// `start` and `end` are byte offsets.
    function hashCalldata(bytes calldata b, uint256 start, uint256 end)
        internal
        pure
        returns (bytes32 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            end := xor(end, mul(xor(end, b.length), lt(b.length, end)))
            start := xor(start, mul(xor(start, b.length), lt(b.length, start)))
            let n := mul(gt(end, start), sub(end, start))
            calldatacopy(mload(0x40), add(b.offset, start), n)
            result := keccak256(mload(0x40), n)
        }
    }

    /// @dev Returns the keccak256 of the slice from `start` to the end of the bytes.
    function hashCalldata(bytes calldata b, uint256 start) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            start := xor(start, mul(xor(start, b.length), lt(b.length, start)))
            let n := mul(gt(b.length, start), sub(b.length, start))
            calldatacopy(mload(0x40), add(b.offset, start), n)
            result := keccak256(mload(0x40), n)
        }
    }

    /// @dev Returns the keccak256 of the bytes.
    function hashCalldata(bytes calldata b) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            calldatacopy(mload(0x40), b.offset, b.length)
            result := keccak256(mload(0x40), b.length)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      SHA2-256 HELPERS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns `sha256(abi.encode(b))`. Yes, it's more efficient.
    function sha2(bytes32 b) internal view returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, b)
            result := mload(staticcall(gas(), 2, 0x00, 0x20, 0x01, 0x20))
            if iszero(returndatasize()) { invalid() }
        }
    }

    /// @dev Returns the sha256 of the slice from `start` to `end` (exclusive).
    /// `start` and `end` are byte offsets.
    function sha2(bytes memory b, uint256 start, uint256 end)
        internal
        view
        returns (bytes32 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(b)
            end := xor(end, mul(xor(end, n), lt(n, end)))
            start := xor(start, mul(xor(start, n), lt(n, start)))
            // forgefmt: disable-next-item
            result := mload(staticcall(gas(), 2, add(add(b, 0x20), start),
                mul(gt(end, start), sub(end, start)), 0x01, 0x20))
            if iszero(returndatasize()) { invalid() }
        }
    }

    /// @dev Returns the sha256 of the slice from `start` to the end of the bytes.
    function sha2(bytes memory b, uint256 start) internal view returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(b)
            start := xor(start, mul(xor(start, n), lt(n, start)))
            // forgefmt: disable-next-item
            result := mload(staticcall(gas(), 2, add(add(b, 0x20), start),
                mul(gt(n, start), sub(n, start)), 0x01, 0x20))
            if iszero(returndatasize()) { invalid() }
        }
    }

    /// @dev Returns the sha256 of the bytes.
    function sha2(bytes memory b) internal view returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(staticcall(gas(), 2, add(b, 0x20), mload(b), 0x01, 0x20))
            if iszero(returndatasize()) { invalid() }
        }
    }

    /// @dev Returns the sha256 of the slice from `start` to `end` (exclusive).
    /// `start` and `end` are byte offsets.
    function sha2Calldata(bytes calldata b, uint256 start, uint256 end)
        internal
        view
        returns (bytes32 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            end := xor(end, mul(xor(end, b.length), lt(b.length, end)))
            start := xor(start, mul(xor(start, b.length), lt(b.length, start)))
            let n := mul(gt(end, start), sub(end, start))
            calldatacopy(mload(0x40), add(b.offset, start), n)
            result := mload(staticcall(gas(), 2, mload(0x40), n, 0x01, 0x20))
            if iszero(returndatasize()) { invalid() }
        }
    }

    /// @dev Returns the sha256 of the slice from `start` to the end of the bytes.
    function sha2Calldata(bytes calldata b, uint256 start) internal view returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            start := xor(start, mul(xor(start, b.length), lt(b.length, start)))
            let n := mul(gt(b.length, start), sub(b.length, start))
            calldatacopy(mload(0x40), add(b.offset, start), n)
            result := mload(staticcall(gas(), 2, mload(0x40), n, 0x01, 0x20))
            if iszero(returndatasize()) { invalid() }
        }
    }

    /// @dev Returns the sha256 of the bytes.
    function sha2Calldata(bytes calldata b) internal view returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            calldatacopy(mload(0x40), b.offset, b.length)
            result := mload(staticcall(gas(), 2, mload(0x40), b.length, 0x01, 0x20))
            if iszero(returndatasize()) { invalid() }
        }
    }
}
