// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Receiver} from "./Receiver.sol";

/// @notice Minimal account to be spawned and controlled by a mothership.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/accounts/Pod.sol)
abstract contract Pod is Receiver {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Call struct for the `executeBatch` function.
    struct Call {
        address target;
        uint256 value;
        bytes data;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The function selector is not recognized.
    error FnSelectorNotRecognized();

    /// @dev The caller is not mothership.
    error CallerNotMothership();

    /// @dev The mothership is already been initialized.
    error MothershipAlreadyInitialized();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  CONSTANTS AND IMMUTABLES                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The Pod `Mothership` slot is given by:
    /// `uint72(bytes9(keccak256("_MOTHERSHIP_SLOT")))`.
    uint256 internal constant _MOTHERSHIP_SLOT = 0xe40cb4b49e7f0723b2;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   MOTHERSHIP OPERATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the mothership contract.
    function mothership() public view virtual returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := shr(96, sload(_MOTHERSHIP_SLOT))
        }
    }

    /// @dev Sets the mothership directly without any emitting event.
    /// Call this function in the initializer or constructor, if any.
    /// Reverts if the mothership has already been initialized.
    function _initializeMothership(address initialMothership) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            let s := _MOTHERSHIP_SLOT
            if sload(s) {
                mstore(0x00, 0xcc62e56e) // `MothershipAlreadyInitialized()`.
                revert(0x1c, 0x04)
            }
            sstore(s, or(s, shl(96, initialMothership)))
        }
    }

    /// @dev Sets the mothership directly without any emitting event.
    /// Expose this in a guarded public function if needed.
    function _setMothership(address newMothership) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            let s := _MOTHERSHIP_SLOT
            sstore(s, or(s, shl(96, newMothership)))
        }
    }

    /// @dev Requires that the caller is the mothership.
    /// This is called in the `onlyMothership` modifier.
    function _checkMothership() internal view virtual {
        if (msg.sender != mothership()) revert CallerNotMothership();
    }

    /// @dev Requires that the caller is the mothership.
    modifier onlyMothership() virtual {
        _checkMothership();
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    EXECUTION OPERATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Execute a call from this account.
    /// Reverts and bubbles up error if call fails.
    /// Returns the result of the call.
    function execute(address target, uint256 value, bytes calldata data)
        public
        payable
        virtual
        onlyMothership
        returns (bytes memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
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

    /// @dev Execute a sequence of calls from this account.
    /// Reverts and bubbles up error if any call fails.
    /// Returns the results of the calls.
    function executeBatch(Call[] calldata calls)
        public
        payable
        virtual
        onlyMothership
        returns (bytes[] memory results)
    {
        /// @solidity memory-safe-assembly
        assembly {
            results := mload(0x40)
            mstore(results, calls.length)
            let r := add(0x20, results)
            let m := add(r, shl(5, calls.length))
            calldatacopy(r, calls.offset, shl(5, calls.length))
            for { let end := m } iszero(eq(r, end)) { r := add(r, 0x20) } {
                let e := add(calls.offset, mload(r))
                let o := add(e, calldataload(add(e, 0x40)))
                calldatacopy(m, add(o, 0x20), calldataload(o))
                // forgefmt: disable-next-item
                if iszero(call(gas(), calldataload(e), calldataload(add(e, 0x20)),
                    m, calldataload(o), codesize(), 0x00)) {
                    // Bubble up the revert if the call reverts.
                    returndatacopy(m, 0x00, returndatasize())
                    revert(m, returndatasize())
                }
                mstore(r, m) // Append `m` into `results`.
                mstore(m, returndatasize()) // Store the length,
                let p := add(m, 0x20)
                returndatacopy(p, 0x00, returndatasize()) // and copy the returndata.
                m := add(p, returndatasize()) // Advance `m`.
            }
            mstore(0x40, m) // Allocate the memory.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OVERRIDES                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Handle token callbacks. Reverts If no token callback is triggered.
    fallback() external payable virtual override(Receiver) receiverFallback {
        revert FnSelectorNotRecognized();
    }
}
