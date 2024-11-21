// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Minimal batch executor mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/accounts/ERC7821.sol)
abstract contract ERC7821 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Call struct for the `execute` function.
    struct Call {
        address target;
        uint256 value;
        bytes data;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           ERRORS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The execution mode is not supported.
    error UnsupportedExecutionMode();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   FUNCTIONS TO OVERRIDE                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Ensures that `execute` can only be called by the correct caller or `opData`.
    function _authorizeExecute(Call[] calldata calls, bytes calldata opData) internal virtual;

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
    /// - `0x01000000000078210001...`: supports optional `opData`.
    /// - `0x01000000000000000000...`: does not support optional `opData`.
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
        returns (bytes[] memory results)
    {
        if (!supportsExecutionMode(mode)) {
            /// @solidity memory-safe-assembly
            assembly {
                mstore(0x00, 0x7f181275) // `UnsupportedExecutionMode()`.
                revert(0x1c, 0x04)
            }
        }
        Call[] calldata calls;
        bytes calldata opData;
        /// @solidity memory-safe-assembly
        assembly {
            opData.length := 0
            let end := add(executionData.offset, executionData.length)
            let o := calldataload(executionData.offset)
            if or(lt(executionData.length, 0x20), shr(64, o)) { invalid() }
            o := add(executionData.offset, o)
            calls.offset := add(o, 0x20)
            calls.length := calldataload(o)
            if or(gt(add(calls.offset, shl(5, calls.length)), end), shr(64, calls.length)) {
                invalid()
            }

            // If the offset of `executionData` allows for `opData`.
            if iszero(lt(calldataload(executionData.offset), 0x40)) {
                // If the mode is not the general atomic batch execution mode.
                if xor(and(shr(mul(22, 8), mode), 0xffff00000000ffffffff), 0x01000000000000000000) {
                    let p := calldataload(add(executionData.offset, 0x20))
                    if shr(64, p) { invalid() }
                    p := add(executionData.offset, p)
                    opData.length := calldataload(p)
                    opData.offset := add(p, 0x20)
                    if or(shr(64, p), gt(add(opData.offset, opData.length), end)) { invalid() }
                }
            }
        }
        _authorizeExecute(calls, opData);
        return _execute(calls);
    }

    /// @dev Provided for execution mode support detection.
    function supportsExecutionMode(bytes32 mode) public pure virtual returns (bool result) {
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
            result := and(shr(mul(22, 8), mode), 0xffff00000000ffffffff)
            result := or(eq(result, 0x01000000000078210001), eq(result, 0x01000000000000000000))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      INTERNAL HELPERS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Executes the `calls` and returns the results.
    /// Reverts and bubbles up error if any call fails.
    function _execute(Call[] calldata calls) internal virtual returns (bytes[] memory results) {
        /// @solidity memory-safe-assembly
        assembly {
            results := mload(0x40) // Grab the free memory pointer.
            mstore(results, calls.length) // Store the length of results.
            mstore(0x40, add(add(results, 0x20), shl(5, calls.length))) // Allocate memory.
        }
        for (uint256 i; i != calls.length;) {
            address target;
            uint256 value;
            bytes calldata data;
            /// @solidity memory-safe-assembly
            assembly {
                // Directly extract `calls[i]` without bounds checks.
                let c := add(calls.offset, calldataload(add(calls.offset, shl(5, i))))
                target := calldataload(c)
                value := calldataload(add(c, 0x20))
                let o := add(c, calldataload(add(c, 0x40)))
                data.offset := add(o, 0x20)
                data.length := calldataload(o)
                i := add(i, 1)
            }
            bytes memory r = _execute(target, value, data);
            /// @solidity memory-safe-assembly
            assembly {
                mstore(add(results, shl(5, i)), r) // Set `results[i]` to `r`.
            }
        }
    }

    /// @dev Executes the `calls` and returns the result.
    /// Reverts and bubbles up error if any call fails.
    function _execute(address target, uint256 value, bytes calldata data)
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
        }
    }
}
