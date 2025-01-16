// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Receiver} from "./Receiver.sol";

/// @notice Minimal batch executor mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/accounts/ERC7821.sol)
///
/// @dev This contract can be inherited to create fully-fledged smart accounts.
/// If you merely want to combine approve-swap transactions into a single transaction
/// using [EIP-7702](https://eips.ethereum.org/EIPS/eip-7702), you will need to implement basic
/// [ERC-1271](https://eips.ethereum.org/EIPS/eip-1271) `isValidSignature` functionality to
/// validate signatures with `ecrecover` against the EOA address. This is necessary because some
/// signature checks skip `ecrecover` if the signer has code. For a basic EOA batch executor,
/// please refer to [BEBE](https://github.com/vectorized/bebe), which inherits from this class.
contract ERC7821 is Receiver {
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

    /// @dev Executes the calls in `executionData`.
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
    /// - If `msg.sender` is an authorized entry point, then `execute` MAY accept
    ///   calls from the entry point, and MAY use `opData` for specialized logic.
    ///
    /// `opData` may be used to store additional data for authentication,
    /// paymaster data, gas limits, etc.
    function execute(bytes32 mode, bytes calldata executionData) public payable virtual {
        uint256 id = _executionModeId(mode);
        Call[] calldata calls;
        bytes calldata opData;
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(id) {
                mstore(0x00, 0x7f181275) // `UnsupportedExecutionMode()`.
                revert(0x1c, 0x04)
            }
            // Use inline assembly to extract the calls and optional `opData` efficiently.
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
        _execute(mode, executionData, calls, opData);
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
        // - [6..9]   ( 4 bytes)  `0x78210001` or `0x00000000`.
        // - [10..31] (22 bytes)  Unused. Free for use.
        /// @solidity memory-safe-assembly
        assembly {
            let m := and(shr(mul(22, 8), mode), 0xffff00000000ffffffff)
            id := or(shl(1, eq(m, 0x01000000000078210001)), eq(m, 0x01000000000000000000))
        }
    }

    /// @dev Executes the calls.
    /// Reverts and bubbles up error if any call fails.
    /// The `mode` and `executionData` are passed along in case there's a need to use them.
    function _execute(
        bytes32 mode,
        bytes calldata executionData,
        Call[] calldata calls,
        bytes calldata opData
    ) internal virtual {
        // Silence compiler warning on unused variables.
        mode = mode;
        executionData = executionData;
        // Very basic auth to only allow this contract to be called by itself.
        // Override this function to perform more complex auth with `opData`.
        if (opData.length == uint256(0)) {
            require(msg.sender == address(this));
            // Remember to return `_execute(calls, extraData)` when you override this function.
            return _execute(calls, bytes32(0));
        }
        revert(); // In your override, replace this with logic to operate on `opData`.
    }

    /// @dev Executes the calls.
    /// Reverts and bubbles up error if any call fails.
    /// `extraData` can be any supplementary data (e.g. a memory pointer, some hash).
    function _execute(Call[] calldata calls, bytes32 extraData) internal virtual {
        unchecked {
            uint256 i;
            if (calls.length == uint256(0)) return;
            do {
                (address target, uint256 value, bytes calldata data) = _get(calls, i);
                _execute(target, value, data, extraData);
            } while (++i != calls.length);
        }
    }

    /// @dev Executes the call.
    /// Reverts and bubbles up error if any call fails.
    /// `extraData` can be any supplementary data (e.g. a memory pointer, some hash).
    function _execute(address target, uint256 value, bytes calldata data, bytes32 extraData)
        internal
        virtual
    {
        /// @solidity memory-safe-assembly
        assembly {
            extraData := extraData // Silence unused variable compiler warning.
            let m := mload(0x40) // Grab the free memory pointer.
            calldatacopy(m, data.offset, data.length)
            if iszero(call(gas(), target, value, m, data.length, codesize(), 0x00)) {
                // Bubble up the revert if the call reverts.
                returndatacopy(m, 0x00, returndatasize())
                revert(m, returndatasize())
            }
        }
    }

    /// @dev Convenience function for getting `calls[i]`, without bounds checks.
    function _get(Call[] calldata calls, uint256 i)
        internal
        view
        virtual
        returns (address target, uint256 value, bytes calldata data)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let c := add(calls.offset, calldataload(add(calls.offset, shl(5, i))))
            // Replaces `target` with `address(this)` if `address(0)` is provided.
            // We'll skip cleaning the upper 96 bits of `target` as it is ignored in `call`.
            target := or(mul(address(), iszero(calldataload(c))), calldataload(c))
            value := calldataload(add(c, 0x20))
            let o := add(c, calldataload(add(c, 0x40)))
            data.offset := add(o, 0x20)
            data.length := calldataload(o)
        }
    }
}
