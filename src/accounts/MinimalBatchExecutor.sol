// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Minimal batch executor mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/accounts/MinimalBatchExecutor.sol)
abstract contract MinimalBatchExecutor {
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
    /*                          EXECUTE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Executes the `calls` and returns the results.
    /// Reverts and bubbles up error if any call fails.
    /// `executionData` is `abi.encodePacked(abi.encode(calls), opData)`.
    function execute(bytes32 encodedMode, bytes calldata executionData)
        public
        payable
        virtual
        returns (bytes[] memory results)
    {
        if (!supportsExecutionMode(encodedMode)) {
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
            let o := add(executionData.offset, calldataload(executionData.offset))
            calls.offset := add(o, 0x20)
            calls.length := calldataload(o)
            opData.length := and(0xffffffff, encodedMode)
            opData.offset := sub(add(executionData.offset, executionData.length), opData.length)
        }
        _authorizeExecute(calls, opData);
        return _execute(calls);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         SIGNALING                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev This function is provided for frontends to detect support.
    function supportsExecutionMode(bytes32 encodedMode) public pure virtual returns (bool result) {
        // Only supports atomic batched executions.
        // For the encoding scheme, see: https://eips.ethereum.org/EIPS/eip-7579
        // Bits Layout:
        // - [0]       (1 byte)   `0x01` for batch call.
        // - [1]       (1 byte)   `0x00` for revert on any failure.
        // - [2..5]    (4 bytes)  Reserved by ERC7579 for future standardization.
        // - [6..7]    (2 bytes)  `0x9999`.
        // - [8..9]    (2 bytes)  Version in hex format.
        // - [9..27]   (18 bytes) Unused. Free for use.
        // - [28..31]  (4 bytes)  uint32 (big-endian) length of `opData`.
        return bytes10(encodedMode) & 0xffff00000000ffffffff == 0x01000000000099990001;
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
