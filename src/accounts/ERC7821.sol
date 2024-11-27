// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Minimal batch executor mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/accounts/ERC7821.sol)
contract ERC7821 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Call struct for the `execute` function.
    struct Call {
        address target; // Replaced as `address(this)` if `address(0)`.
        uint256 value; // Amount of native currency (i.e. Ether) to send.
        bytes data; // Calldata to send with the call.
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The execution mode is not supported.
    error UnsupportedExecutionMode();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    EXECUTION OPERATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Executes the `calls` in `executionData` and returns the results.
    /// The `results` are the returned data from each call.
    /// Reverts and bubbles up error if any call fails.
    ///
    /// `executionData` encoding:
    /// - If `opData` is empty, `executionData` is simply `abi.encode(calls)`.
    /// - Else, `executionData` is `abi.encode(calls, opData)`.
    ///   See: https://eips.ethereum.org/EIPS/eip-7579
    ///
    /// Supported modes:
    /// - `bytes32(0x01000000000000000000...)`: does not support optional `opData`.
    /// - `bytes32(0x01000000000078210001...)`: supports optional `opData`.
    ///
    /// Authorization checks:
    /// - If `opData` is empty, the implementation SHOULD require that
    ///   `msg.sender == address(this)`.
    /// - If `opData` is not empty, the implementation SHOULD use the signature
    ///   encoded in `opData` to determine if the caller can perform the execution.
    ///
    /// `opData` may be used to store additional data for authentication,
    /// paymaster data, gas limits, etc.
    function execute(bytes32 mode, bytes calldata executionData)
        public
        payable
        virtual
        returns (bytes[] memory)
    {
        uint256 id = _executionModeId(mode);
        Call[] calldata calls;
        bytes calldata opData;
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(id) {
                mstore(0x00, 0x7f181275) // `UnsupportedExecutionMode()`.
                revert(0x1c, 0x04)
            }
            // Use inline assembly to extract the `calls` and optional `opData` efficiently.
            opData.length := 0
            let o := add(executionData.offset, calldataload(executionData.offset))
            calls.offset := add(o, 0x20)
            calls.length := calldataload(o)
            // If the offset of `executionData` allows for `opData`, and the mode supports it.
            if gt(eq(id, 2), gt(0x40, calldataload(executionData.offset))) {
                let q := add(executionData.offset, calldataload(add(0x20, executionData.offset)))
                opData.offset := add(q, 0x20)
                opData.length := calldataload(q)
            }
        }
        return _execute(calls, opData);
    }

    /// @dev Provided for execution mode support detection.
    function supportsExecutionMode(bytes32 mode) public view virtual returns (bool result) {
        return _executionModeId(mode) != 0;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      INTERNAL HELPERS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev 0: invalid mode, 1: no `opData` support, 2: with `opData` support.
    function _executionModeId(bytes32 mode) internal view virtual returns (uint256 id) {
        // Only supports atomic batched executions.
        // For the encoding scheme, see: https://eips.ethereum.org/EIPS/eip-7579
        // Bytes Layout:
        // - [0]      ( 1 byte )  `0x01` for batch call.
        // - [1]      ( 1 byte )  `0x00` for revert on any failure.
        // - [2..5]   ( 4 bytes)  Reserved by ERC7579 for future standardization.
        // - [6..8]   ( 4 bytes)  `0x78210001` or `0x00000000`.
        // - [9..31]  (22 bytes)  Unused. Free for use.
        /// @solidity memory-safe-assembly
        assembly {
            let m := and(shr(mul(22, 8), mode), 0xffff00000000ffffffff)
            id := or(shl(1, eq(m, 0x01000000000078210001)), eq(m, 0x01000000000000000000))
        }
    }

    /// @dev Executes the `calls` and returns the results.
    /// Reverts and bubbles up error if any call fails.
    function _execute(Call[] calldata calls, bytes calldata opData)
        internal
        virtual
        returns (bytes[] memory)
    {
        // Very basic auth to only allow this contract to be called by itself.
        // Override this function to perform more complex auth with `opData`.
        if (opData.length == uint256(0)) {
            require(msg.sender == address(this));
            // Remember to return `_execute(calls, extraData)` when you override this function.
            return _execute(calls, bytes32(0));
        }
        revert(); // In your override, replace this with logic to operate on `opData`.
    }

    /// @dev Executes the `calls` and returns the results.
    /// Reverts and bubbles up error if any call fails.
    /// `extraData` can be any supplementary data (e.g. a memory pointer, some hash).
    function _execute(Call[] calldata calls, bytes32 extraData)
        internal
        virtual
        returns (bytes[] memory results)
    {
        /// @solidity memory-safe-assembly
        assembly {
            results := mload(0x40) // Grab the free memory pointer.
            mstore(results, calls.length) // Store the length of results.
            mstore(0x40, add(add(results, 0x20), shl(5, calls.length))) // Allocate memory.
        }
        uint256 n = calls.length << 5;
        for (uint256 j; j != n;) {
            address target;
            uint256 value;
            bytes calldata data;
            /// @solidity memory-safe-assembly
            assembly {
                // Directly extract `calls[i]` without bounds checks.
                let c := add(calls.offset, calldataload(add(calls.offset, j)))
                // Replaces `target` with `address(this)` if `address(0)` is provided.
                target := or(mul(address(), iszero(calldataload(c))), calldataload(c))
                value := calldataload(add(c, 0x20))
                let o := add(c, calldataload(add(c, 0x40)))
                data.offset := add(o, 0x20)
                data.length := calldataload(o)
                j := add(j, 0x20)
            }
            bytes memory r = _execute(target, value, data, extraData);
            /// @solidity memory-safe-assembly
            assembly {
                mstore(add(results, j), r) // Set `results[i]` to `r`.
            }
        }
    }

    /// @dev Executes the `calls` and returns the result.
    /// Reverts and bubbles up error if any call fails.
    /// `extraData` can be any supplementary data (e.g. a memory pointer, some hash).
    function _execute(address target, uint256 value, bytes calldata data, bytes32 extraData)
        internal
        virtual
        returns (bytes memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40) // Grab the free memory pointer.
            calldatacopy(result, data.offset, data.length)
            if iszero(call(gas(), target, value, result, data.length, codesize(), 0x00)) {
                // Bubble up the revert if the call reverts.
                returndatacopy(result, 0x00, returndatasize())
                revert(result, returndatasize())
            }
            mstore(result, returndatasize()) // Store the length.
            let o := add(result, 0x20)
            returndatacopy(o, 0x00, returndatasize()) // Copy the returndata.
            mstore(0x40, add(o, returndatasize())) // Allocate the memory.
            extraData := extraData // Silence unused variable compiler warning.
        }
    }
}
