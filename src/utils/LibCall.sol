// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for making calls.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibCall.sol)
/// @author Modified from ExcessivelySafeCall (https://github.com/nomad-xyz/ExcessivelySafeCall)
///
/// @dev Note:
/// - The arguments of the functions may differ from the libraries.
///   Please read the functions carefully before use.
library LibCall {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The target of the call is not a contract.
    error TargetIsNotContract();

    /// @dev The data is too short to contain a function selector.
    error DataTooShort();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  CONTRACT CALL OPERATIONS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // These functions will revert if called on a non-contract
    // (i.e. address without code).
    // They will bubble up the revert if the call fails.

    /// @dev Makes a call to `target`, with `data` and `value`.
    function callContract(address target, uint256 value, bytes memory data)
        internal
        returns (bytes memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            if iszero(call(gas(), target, value, add(data, 0x20), mload(data), codesize(), 0x00)) {
                // Bubble up the revert if the call reverts.
                returndatacopy(result, 0x00, returndatasize())
                revert(result, returndatasize())
            }
            if iszero(returndatasize()) {
                if iszero(extcodesize(target)) {
                    mstore(0x00, 0x5a836a5f) // `TargetIsNotContract()`.
                    revert(0x1c, 0x04)
                }
            }
            mstore(result, returndatasize()) // Store the length.
            let o := add(result, 0x20)
            returndatacopy(o, 0x00, returndatasize()) // Copy the returndata.
            mstore(0x40, add(o, returndatasize())) // Allocate the memory.
        }
    }

    /// @dev Makes a call to `target`, with `data`.
    function callContract(address target, bytes memory data)
        internal
        returns (bytes memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            if iszero(call(gas(), target, 0, add(data, 0x20), mload(data), codesize(), 0x00)) {
                // Bubble up the revert if the call reverts.
                returndatacopy(result, 0x00, returndatasize())
                revert(result, returndatasize())
            }
            if iszero(returndatasize()) {
                if iszero(extcodesize(target)) {
                    mstore(0x00, 0x5a836a5f) // `TargetIsNotContract()`.
                    revert(0x1c, 0x04)
                }
            }
            mstore(result, returndatasize()) // Store the length.
            let o := add(result, 0x20)
            returndatacopy(o, 0x00, returndatasize()) // Copy the returndata.
            mstore(0x40, add(o, returndatasize())) // Allocate the memory.
        }
    }

    /// @dev Makes a static call to `target`, with `data`.
    function staticCallContract(address target, bytes memory data)
        internal
        view
        returns (bytes memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            if iszero(staticcall(gas(), target, add(data, 0x20), mload(data), codesize(), 0x00)) {
                // Bubble up the revert if the call reverts.
                returndatacopy(result, 0x00, returndatasize())
                revert(result, returndatasize())
            }
            if iszero(returndatasize()) {
                if iszero(extcodesize(target)) {
                    mstore(0x00, 0x5a836a5f) // `TargetIsNotContract()`.
                    revert(0x1c, 0x04)
                }
            }
            mstore(result, returndatasize()) // Store the length.
            let o := add(result, 0x20)
            returndatacopy(o, 0x00, returndatasize()) // Copy the returndata.
            mstore(0x40, add(o, returndatasize())) // Allocate the memory.
        }
    }

    /// @dev Makes a delegate call to `target`, with `data`.
    function delegateCallContract(address target, bytes memory data)
        internal
        returns (bytes memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            if iszero(delegatecall(gas(), target, add(data, 0x20), mload(data), codesize(), 0x00)) {
                // Bubble up the revert if the call reverts.
                returndatacopy(result, 0x00, returndatasize())
                revert(result, returndatasize())
            }
            if iszero(returndatasize()) {
                if iszero(extcodesize(target)) {
                    mstore(0x00, 0x5a836a5f) // `TargetIsNotContract()`.
                    revert(0x1c, 0x04)
                }
            }
            mstore(result, returndatasize()) // Store the length.
            let o := add(result, 0x20)
            returndatacopy(o, 0x00, returndatasize()) // Copy the returndata.
            mstore(0x40, add(o, returndatasize())) // Allocate the memory.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    TRY CALL OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // These functions enable gas limited calls to be performed,
    // with a cap on the number of return data bytes to be copied.
    // The can be used to ensure that the calling contract will not
    // run out-of-gas.

    /// @dev Makes a call to `target`, with `data` and `value`.
    /// The call is given a gas limit of `gasStipend`,
    /// and up to `maxCopy` bytes of return data can be copied.
    function tryCall(
        address target,
        uint256 value,
        uint256 gasStipend,
        uint16 maxCopy,
        bytes memory data
    ) internal returns (bool success, bool exceededMaxCopy, bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            success :=
                call(gasStipend, target, value, add(data, 0x20), mload(data), codesize(), 0x00)
            let n := returndatasize()
            if gt(returndatasize(), and(0xffff, maxCopy)) {
                n := and(0xffff, maxCopy)
                exceededMaxCopy := 1
            }
            mstore(result, n) // Store the length.
            let o := add(result, 0x20)
            returndatacopy(o, 0x00, n) // Copy the returndata.
            mstore(0x40, add(o, n)) // Allocate the memory.
        }
    }

    /// @dev Makes a call to `target`, with `data`.
    /// The call is given a gas limit of `gasStipend`,
    /// and up to `maxCopy` bytes of return data can be copied.
    function tryStaticCall(address target, uint256 gasStipend, uint16 maxCopy, bytes memory data)
        internal
        view
        returns (bool success, bool exceededMaxCopy, bytes memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            success :=
                staticcall(gasStipend, target, add(data, 0x20), mload(data), codesize(), 0x00)
            let n := returndatasize()
            if gt(returndatasize(), and(0xffff, maxCopy)) {
                n := and(0xffff, maxCopy)
                exceededMaxCopy := 1
            }
            mstore(result, n) // Store the length.
            let o := add(result, 0x20)
            returndatacopy(o, 0x00, n) // Copy the returndata.
            mstore(0x40, add(o, n)) // Allocate the memory.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      OTHER OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Bubbles up the revert.
    function bubbleUpRevert(bytes memory revertReturnData) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            revert(add(0x20, revertReturnData), mload(revertReturnData))
        }
    }

    /// @dev In-place replaces the function selector of encoded contract call data.
    function setSelector(bytes4 newSelector, bytes memory data) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(gt(mload(data), 0x03)) {
                mstore(0x00, 0x0acec8bd) // `DataTooShort()`.
                revert(0x1c, 0x04)
            }
            let o := add(data, 0x20)
            mstore(o, or(shr(32, shl(32, mload(o))), newSelector))
        }
    }
}
