// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for reading contract metadata.
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
    // 2. Try to `abi.decode` the returndata into a string
    //    with a maximum supported returndatasize of 16777215 bytes.
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
            for {} staticcall(gas(), target, add(ptr, 0x20), mload(ptr), 0x00, 0x00) {} {
                let m := mload(0x40)
                let l := returndatasize()
                l := xor(l, mul(lt(0xffffff, l), xor(0xffffff, l)))
                returndatacopy(m, 0, l)
                if iszero(lt(l, 0x40)) {
                    let o := mload(m)
                    if iszero(gt(o, sub(l, 0x20))) {
                        let n := mload(add(m, o))
                        if iszero(gt(n, sub(l, add(o, 0x20)))) {
                            let z := add(0x20, n)
                            returndatacopy(m, o, z)
                            mstore(add(m, z), 0)
                            mstore(0x40, add(0x20, add(m, z)))
                            result := m
                            break
                        }
                    }
                }
                let i := 0
                mstore8(add(m, l), 0)
                for {} byte(0, mload(add(i, m))) { i := add(i, 1) } {}
                mstore(m, i)
                let j := add(0x20, m)
                returndatacopy(j, 0, i)
                mstore(add(j, i), 0)
                mstore(0x40, add(0x20, add(j, i)))
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
