// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for reading contract metadata robustly.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/MetadataReaderLib.sol)
library MetadataReaderLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Default gas stipend for contract reads. High enough for most practical use cases
    /// (able to SLOAD about 1000 bytes of data), but low enough to prevent griefing.
    uint256 internal constant GAS_STIPEND_NO_GRIEF = 100000;

    /// @dev Default string byte length limit.
    uint256 internal constant STRING_LIMIT_DEFAULT = 1000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                METADATA READING OPERATIONS                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Best-effort string reading operations.
    // Should NOT revert as long as sufficient gas is provided.
    //
    // Performs the following in order:
    // 1. Returns the empty string for the following cases:
    //     - Reverts.
    //     - No returndata (e.g. function returns nothing, EOA).
    //     - Returns empty string.
    // 2. Attempts to `abi.decode` the returndata into a string.
    // 3. With any remaining gas, scans the returndata from start to end for the
    //    null byte '\0', to interpret the returndata as a null-terminated string.

    /// @dev Equivalent to `readString(abi.encodeWithSignature("name()"))`.
    function readName(address target) internal view returns (string memory) {
        return _string(target, _ptr(0x06fdde03), STRING_LIMIT_DEFAULT, GAS_STIPEND_NO_GRIEF);
    }

    /// @dev Equivalent to `readString(abi.encodeWithSignature("name()"), limit)`.
    function readName(address target, uint256 limit) internal view returns (string memory) {
        return _string(target, _ptr(0x06fdde03), limit, GAS_STIPEND_NO_GRIEF);
    }

    /// @dev Equivalent to `readString(abi.encodeWithSignature("name()"), limit, gasStipend)`.
    function readName(address target, uint256 limit, uint256 gasStipend)
        internal
        view
        returns (string memory)
    {
        return _string(target, _ptr(0x06fdde03), limit, gasStipend);
    }

    /// @dev Equivalent to `readString(abi.encodeWithSignature("symbol()"))`.
    function readSymbol(address target) internal view returns (string memory) {
        return _string(target, _ptr(0x95d89b41), STRING_LIMIT_DEFAULT, GAS_STIPEND_NO_GRIEF);
    }

    /// @dev Equivalent to `readString(abi.encodeWithSignature("symbol()"), limit)`.
    function readSymbol(address target, uint256 limit) internal view returns (string memory) {
        return _string(target, _ptr(0x95d89b41), limit, GAS_STIPEND_NO_GRIEF);
    }

    /// @dev Equivalent to `readString(abi.encodeWithSignature("symbol()"), limit, gasStipend)`.
    function readSymbol(address target, uint256 limit, uint256 gasStipend)
        internal
        view
        returns (string memory)
    {
        return _string(target, _ptr(0x95d89b41), limit, gasStipend);
    }

    /// @dev Performs a best-effort string query on `target` with `data` as the calldata.
    /// The string will be truncated to `STRING_LIMIT_DEFAULT` (1000) bytes.
    function readString(address target, bytes memory data) internal view returns (string memory) {
        return _string(target, _ptr(data), STRING_LIMIT_DEFAULT, GAS_STIPEND_NO_GRIEF);
    }

    /// @dev Performs a best-effort string query on `target` with `data` as the calldata.
    /// The string will be truncated to `limit` bytes.
    function readString(address target, bytes memory data, uint256 limit)
        internal
        view
        returns (string memory)
    {
        return _string(target, _ptr(data), limit, GAS_STIPEND_NO_GRIEF);
    }

    /// @dev Performs a best-effort string query on `target` with `data` as the calldata.
    /// The string will be truncated to `limit` bytes.
    function readString(address target, bytes memory data, uint256 limit, uint256 gasStipend)
        internal
        view
        returns (string memory)
    {
        return _string(target, _ptr(data), limit, gasStipend);
    }

    // Best-effort unsigned integer reading operations.
    // Should NOT revert as long as sufficient gas is provided.
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
        return uint8(_uint(target, _ptr(0x313ce567), GAS_STIPEND_NO_GRIEF));
    }

    /// @dev Equivalent to `uint8(readUint(abi.encodeWithSignature("decimal()"), gasStipend))`.
    function readDecimals(address target, uint256 gasStipend) internal view returns (uint8) {
        return uint8(_uint(target, _ptr(0x313ce567), gasStipend));
    }

    /// @dev Performs a best-effort uint query on `target` with `data` as the calldata.
    function readUint(address target, bytes memory data) internal view returns (uint256) {
        return _uint(target, _ptr(data), GAS_STIPEND_NO_GRIEF);
    }

    /// @dev Performs a best-effort uint query on `target` with `data` as the calldata.
    function readUint(address target, bytes memory data, uint256 gasStipend)
        internal
        view
        returns (uint256)
    {
        return _uint(target, _ptr(data), gasStipend);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Attempts to read and return a string at `target`.
    function _string(address target, bytes32 ptr, uint256 limit, uint256 gasStipend)
        private
        view
        returns (string memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            function min(x_, y_) -> _z {
                _z := xor(x_, mul(xor(x_, y_), lt(y_, x_)))
            }
            for {} staticcall(gasStipend, target, add(ptr, 0x20), mload(ptr), 0x00, 0x20) {} {
                let m := mload(0x40) // Grab the free memory pointer.
                let s := add(0x20, m) // Start of the string's bytes in memory.
                // Attempt to `abi.decode` if the returndatasize is greater or equal to 64.
                if iszero(lt(returndatasize(), 0x40)) {
                    let o := mload(0x00) // Load the string's offset in the returndata.
                    // If the string's offset is within bounds.
                    if iszero(gt(o, sub(returndatasize(), 0x20))) {
                        returndatacopy(m, o, 0x20) // Copy the string's length.
                        // If the full string's end is within bounds.
                        // Note: If the full string doesn't fit, the `abi.decode` must be aborted
                        // for compliance purposes, regardless if the truncated string can fit.
                        if iszero(gt(mload(m), sub(returndatasize(), add(o, 0x20)))) {
                            let n := min(mload(m), limit) // Truncate if needed.
                            mstore(m, n) // Overwrite the length.
                            returndatacopy(s, add(o, 0x20), n) // Copy the string's bytes.
                            mstore(add(s, n), 0) // Zeroize the slot after the string.
                            mstore(0x40, add(0x20, add(s, n))) // Allocate memory for the string.
                            result := m
                            break
                        }
                    }
                }
                // Try interpreting as a null-terminated string.
                let n := min(returndatasize(), limit) // Truncate if needed.
                returndatacopy(s, 0, n) // Copy the string's bytes.
                mstore8(add(s, n), 0) // Place a '\0' at the end.
                let i := s // Pointer to the next byte to scan.
                for {} byte(0, mload(i)) { i := add(i, 1) } {} // Scan for '\0'.
                mstore(m, sub(i, s)) // Store the string's length.
                mstore(i, 0) // Zeroize the slot after the string.
                mstore(0x40, add(0x20, i)) // Allocate memory for the string.
                result := m
                break
            }
        }
    }

    /// @dev Attempts to read and return a uint at `target`.
    function _uint(address target, bytes32 ptr, uint256 gasStipend)
        private
        view
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result :=
                mul(
                    mload(0x20),
                    and( // The arguments of `and` are evaluated from right to left.
                        gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                        staticcall(gasStipend, target, add(ptr, 0x20), mload(ptr), 0x20, 0x20)
                    )
                )
        }
    }

    /// @dev Casts the function selector `s` into a pointer.
    function _ptr(uint256 s) private pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Layout the calldata in the scratch space for temporary usage.
            mstore(0x04, s) // Store the function selector.
            mstore(result, 4) // Store the length.
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
