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

    /// @dev Returns `keccak256(abi.encode(value0))`.
    function hash(bytes32 value0) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, value0)
            result := keccak256(0x00, 0x20)
        }
    }

    /// @dev Returns `keccak256(abi.encode(value0))`.
    function hash(uint256 value0) internal pure returns (bytes32 result) {
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

    /// @dev Returns `keccak256(abi.encode(value0, value1))`.
    function hash(uint256 value0, uint256 value1) internal pure returns (bytes32 result) {
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

    /// @dev Returns `keccak256(abi.encode(value0, value1, value2))`.
    function hash(uint256 value0, uint256 value1, uint256 value2)
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

    /// @dev Returns `keccak256(abi.encode(value0, value1, value2, value3))`.
    function hash(uint256 value0, uint256 value1, uint256 value2, uint256 value3)
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

    /// @dev Returns `keccak256(abi.encode(value0, .., value4))`.
    function hash(uint256 value0, uint256 value1, uint256 value2, uint256 value3, uint256 value4)
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

    /// @dev Returns `keccak256(abi.encode(value0, .., value5))`.
    function hash(
        uint256 value0,
        uint256 value1,
        uint256 value2,
        uint256 value3,
        uint256 value4,
        uint256 value5
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

    /// @dev Returns `keccak256(abi.encode(value0, .., value6))`.
    function hash(
        uint256 value0,
        uint256 value1,
        uint256 value2,
        uint256 value3,
        uint256 value4,
        uint256 value5,
        uint256 value6
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

    /// @dev Returns `keccak256(abi.encode(value0, .., value7))`.
    function hash(
        uint256 value0,
        uint256 value1,
        uint256 value2,
        uint256 value3,
        uint256 value4,
        uint256 value5,
        uint256 value6,
        uint256 value7
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

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*             BYTES32 BUFFER HASHING OPERATIONS              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns `keccak256(abi.encode(buffer[0], .., value[buffer.length - 1]))`.
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
