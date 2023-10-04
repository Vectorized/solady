// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Pausable mixin, which allows children to implement an emergency stop.
///         This mixin is used through inheritance. It will make available the
///         modifiers `whenNotPaused` and `whenPaused`, which can be applied to
///         the functions of your contract. Note that they will not be pausable by
///         simply including this module, only once the modifiers are put in place.
/// @author 0x4non (https://github.com/vectorized/solady/blob/main/src/utils/Pausable.sol)
///
/// @dev Note:
/// This implementation is inspired on the OpenZeppelin implementation.
abstract contract Pausable {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The operation failed because the contract is paused.
    error EnforcedPause();

    /// @dev The operation failed because the contract is not paused.
    error ExpectedPause();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Emitted when the pause is triggered by `account`.
    event Paused(address account);

    /// @dev Emitted when the pause is lifted by `account`.
    event Unpaused(address account);

    /// @dev `keccak256(bytes("Paused(address)"))`.
    uint256 private constant _PAUSABLE_PAUSED_EVENT_SIGNATURE =
        0x62e78cea01bee320cd4e420270b5ea74000d11b0c9f74754ebdbfc544b05a258;

    /// @dev `keccak256(bytes("Unpaused(address)"))`.
    uint256 private constant _PAUSABLE_UNPAUSED_EVENT_SIGNATURE =
        0x5db9ee0a495bf2e6ff9c91a7834c1ba4fdd244a5e8aa4e537bd38aeae4b073aa;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The paused slot is given by: `not(_PAUSED_SLOT_NOT)`.
    /// It is intentionally chosen to be a high value
    /// to avoid collision with lower slots.
    /// The choice of manual storage layout is to enable compatibility
    /// with both regular and upgradeable contracts.
    /// bytes4(keccak256("PAUSED_SLOT")) = 0x873dfc84
    uint256 private constant _PAUSED_SLOT_NOT = 0x873dfc84;

    /// @dev If the contract is not paused, not(_PAUSED_SLOT_NOT)
    /// must be `_PAUSED_STATE` else is considered in `_NOT_PAUSED_STATE`.
    uint256 private constant _NOT_PAUSED_STATE = 1;
    uint256 private constant _PAUSED_STATE = 2;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    function _pause() internal virtual whenNotPaused {
        /// @solidity memory-safe-assembly
        assembly {
            let pausedSlot := not(_PAUSED_SLOT_NOT)
            sstore(pausedSlot, _PAUSED_STATE)
            // Emit the {Paused} event.
            mstore(0x00, caller())
            log1(0, 0x20, _PAUSABLE_PAUSED_EVENT_SIGNATURE)
        }
    }

    function _unpause() internal virtual whenPaused {
        /// @solidity memory-safe-assembly
        assembly {
            let pausedSlot := not(_PAUSED_SLOT_NOT)
            sstore(pausedSlot, _NOT_PAUSED_STATE)
            // Emit the {Unpaused} event.
            mstore(0x00, caller())
            log1(0, 0x20, _PAUSABLE_UNPAUSED_EVENT_SIGNATURE)
        }
    }

    /// @dev Throws if the contract is paused.
    function _checkNotPaused() internal view virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // If the `pausedSlot` value is in `_PAUSED_STATE`, revert.
            if eq(sload(not(_PAUSED_SLOT_NOT)), _PAUSED_STATE) {
                mstore(0x00, 0xd93c0665) // `EnforcedPause()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Throws if the contract is not paused.
    function _checkPaused() internal view virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // If the `pausedSlot` value is not in `_PAUSED_STATE`, revert.
            if iszero(eq(sload(not(_PAUSED_SLOT_NOT)), _PAUSED_STATE)) {
                mstore(0x00, 0x8dfc202b) // `ExpectedPause()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   PUBLIC READ FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns true if the contract is paused, and false otherwise.
    function paused() public view virtual returns (bool _paused) {
        /// @solidity memory-safe-assembly
        assembly {
            _paused := eq(sload(not(_PAUSED_SLOT_NOT)), _PAUSED_STATE)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         MODIFIERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Marks a function as only callable if the contract is paused.
    modifier whenPaused() virtual {
        _checkPaused();
        _;
    }

    /// @dev Marks a function as only callable if the contract is not paused.
    modifier whenNotPaused() virtual {
        _checkNotPaused();
        _;
    }
}
