// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for reading contract metadata robustly.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/MetadataReaderLib.sol)
library MetadataReaderLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                METADATA READING OPERATIONS                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Best-effort string reading operations.
    // Should NOT revert if sufficient gas is provided.
    //
    // Performs the following in order:
    // 1. Returns the empty string for the following cases:
    //     - Reverts.
    //     - No returndata (e.g. function returns nothing, EOA).
    //     - Returns empty string.
    // 2. Try to `abi.decode` the returndata into a string.
    // 3. With any remaining gas, scans the returndata from start to end for the
    //    null byte '\0', to interpret the returndata as a null-terminated string.

    /// @dev Equivalent to `readString(abi.encodeWithSignature("name()"))`.
    function readName(address target) internal view returns (string memory) {
        return _string(target, _ptr(0x06fdde03));
    }

    /// @dev Equivalent to `readString(abi.encodeWithSignature("symbol()"))`.
    function readSymbol(address target) internal view returns (string memory) {
        return _string(target, _ptr(0x95d89b41));
    }

    /// @dev Performs a best-effort string query on `target` with `data` as the calldata.
    function readString(address target, bytes memory data) internal view returns (string memory) {
        return _string(target, _ptr(data));
    }

    // Best-effort unsigned integer reading operations.
    // Should NOT revert if sufficient gas is provided.
    //
    // Performs the following in order:
    // 1. Attempts to `abi.decode` the result into a uint256
    //    (equivalent across all Solidity uint types, downcast as needed).
    // 2. Returns zero for the following cases:
    //     - Reverts.
    //     - No returndata (e.g. function returns nothing, EOA).
    //     - Returns zero.
    //     - `abi.decode` failure.

    /// @dev Equivalent to `uint8(readUint(abi.encodeWithSignature("decimal()")))`.
    function readDecimals(address target) internal view returns (uint8) {
        return uint8(_uint(target, _ptr(0x313ce567)));
    }

    /// @dev Performs a best-effort uint query on `target` with `data` as the calldata.
    function readUint(address target, bytes memory data) internal view returns (uint256) {
        return _uint(target, _ptr(data));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Attempts to read and return a string at `target`.
    function _string(address target, bytes32 ptr) private view returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            for {} staticcall(gas(), target, add(ptr, 0x20), mload(ptr), 0x00, 0x20) {} {
                let m := mload(0x40)
                let j := add(0x20, m)
                // Try `abi.decode`.
                if iszero(lt(returndatasize(), 0x40)) {
                    let o := mload(0x00)
                    // If the string's offset is within bounds.
                    if iszero(gt(o, sub(returndatasize(), 0x20))) {
                        returndatacopy(m, o, 0x20)
                        let n := mload(m)
                        // If the string's end is within bounds.
                        if iszero(gt(n, sub(returndatasize(), add(o, 0x20)))) {
                            returndatacopy(j, add(o, 0x20), n) // Copy the string's contents.
                            mstore(add(j, n), 0) // Zeroize the slot after the string.
                            mstore(0x40, add(0x20, add(j, n))) // Allocate memory for the string.
                            result := m
                            break
                        }
                    }
                }
                // Try interpreting as null-terminated string.
                let i := j
                returndatacopy(j, 0, returndatasize())
                mstore8(add(j, returndatasize()), 0) // Place a '\0' at the end.
                for {} byte(0, mload(i)) { i := add(i, 1) } {} // Scan for '\0'.
                mstore(m, sub(i, j)) // Store the string's length.
                mstore(i, 0) // Zeroize the slot after the string.
                mstore(0x40, add(0x20, i)) // Allocate memory for the string.
                result := m
                break
            }
        }
    }

    /// @dev Attempts to read and return a uint at `target`.
    function _uint(address target, bytes32 ptr) private view returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result :=
                mul(
                    mload(0x20),
                    and( // The arguments of `and` are evaluated from right to left.
                        gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                        staticcall(gas(), target, add(ptr, 0x20), mload(ptr), 0x20, 0x20)
                    )
                )
        }
    }

    /// @dev Casts the `sel` into a pointer.
    function _ptr(uint256 sel) private pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x04, sel)
            mstore(result, 4)
        }
    }

    /// @dev Casts the `data` into a pointer.
    function _ptr(bytes memory data) private pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := data
        }
    }
}
