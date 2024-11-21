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
    /*                   FUNCTIONS TO OVERRIDE                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Ensures that `execute` can only be called by the correct caller or `opData`.
    function _authorizeExecute(Call[] calldata calls, bytes calldata opData) internal virtual;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    EXECUTION OPERATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Executes the `calls` and returns the results.
    /// Reverts and bubbles up error if any call fails.
    function execute(Call[] calldata calls, bytes calldata opData)
        public
        payable
        virtual
        returns (bytes[] memory results)
    {
        _authorizeExecute(calls, opData);
        return _execute(calls);
    }

    /// @dev This function is provided for frontends to detect support.
    function minimalBatchExecutorVersion() public pure virtual returns (uint256) {
        return 1; // This number may change.
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
