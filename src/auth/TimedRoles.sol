// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Timed multiroles authorization mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/auth/EnumerableRoles.sol)
///
/// @dev Note:
/// This implementation is agnostic to the Ownable that the contract inherits from.
/// It performs a self-staticcall to the `owner()` function to determine the owner.
/// This is useful for situations where the contract inherits from
/// OpenZeppelin's Ownable, such as in LayerZero's OApp contracts.
///
/// This implementation performs a self-staticcall to `MAX_TIMED_ROLE()` to determine
/// the maximum role that can be set/unset. If the inheriting contract does not
/// have `MAX_TIMED_ROLE()`, then any role can be set/unset.
///
/// This implementation allows for any uint256 role,
/// it does NOT take in a bitmask of roles.
/// This is to accommodate teams that are allergic to bitwise flags.
///
/// By default, the `owner()` is the only account that is authorized to set roles.
/// This behavior can be changed via overrides.
///
/// This implementation is compatible with any Ownable.
/// This implementation is NOT compatible with OwnableRoles.
///
/// Since roles can be become active or inactive, it does not make sense
/// to add enumeration here.
///
/// Names are deliberately prefixed with "Timed", so that this contract
/// can be used in conjunction with `EnumerableRoles`.
abstract contract TimedRoles {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The active time range of `role` for `holder` has been set.
    event TimedRoleSet(address indexed holder, uint256 indexed role, uint40 start, uint40 until);

    /// @dev `keccak256(bytes("TimedRoleSet(address,uint256,uint40,uint40)"))`.
    uint256 private constant _TIMED_ROLE_SET_EVENT_SIGNATURE =
        0xf7b5bcd44281f9bd7dfe7227dbb5c96dafa8587339fe558592433e9d02ade7d7;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Cannot set the role of the zero address.
    error TimedRoleHolderIsZeroAddress();

    /// @dev The role has exceeded the maximum role.
    error InvalidTimedRole();

    /// @dev Unauthorized to perform the action.
    error TimedRolesUnauthorized();

    /// @dev The `end` cannot be less than the `start`.
    /// We allow `start` to be `equal` to end to allow for a zero range.
    error InvalidTimedRoleRange();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The storage layout of the mapping is given by:
    /// ```
    ///     mstore(0x18, holder)
    ///     mstore(0x04, _TIMED_ROLES_SLOT_SEED)
    ///     mstore(0x00, role)
    ///     let timeRangeSlot := keccak256(0x00, 0x38)
    /// ```
    uint256 private constant _TIMED_ROLES_SLOT_SEED = 0x28900261;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  PUBLIC UPDATE FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sets the active time range of `role` of `holder` to [`start`, `end`).
    function setTimedRole(address holder, uint256 role, uint40 start, uint40 end)
        public
        payable
        virtual
    {
        _authorizeSetTimedRole(holder, role, start, end);
        _setTimedRole(holder, role, start, end);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   PUBLIC READ FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns whether the `role` is active for `holder`, as well as the active time range.
    function timedRoleActive(address holder, uint256 role)
        public
        view
        virtual
        returns (bool isActive, uint40 start, uint40 end)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x18, holder)
            mstore(0x04, _TIMED_ROLES_SLOT_SEED)
            mstore(0x00, role)
            let packed := sload(keccak256(0x00, 0x38))
            start := and(0xffffffffff, shr(40, packed))
            end := and(0xffffffffff, packed)
            isActive := lt(lt(timestamp(), start), lt(timestamp(), end))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Set the role for holder directly without authorization guard.
    function _setTimedRole(address holder, uint256 role, uint40 start, uint40 end)
        internal
        virtual
    {
        _validateTimedRole(role);
        /// @solidity memory-safe-assembly
        assembly {
            let holder_ := shl(96, holder)
            if iszero(holder_) {
                mstore(0x00, 0x093a136f) // `TimedRoleHolderIsZeroAddress()`.
                revert(0x1c, 0x04)
            }
            // Clean the upper bits.
            start := and(0xffffffffff, start)
            end := and(0xffffffffff, end)
            // Validate the range.
            if lt(end, start) {
                mstore(0x00, 0x3304dd8c) // `InvalidTimedRoleRange()`.
                revert(0x1c, 0x04)
            }
            // Store the range.
            mstore(0x18, holder)
            mstore(0x04, _TIMED_ROLES_SLOT_SEED)
            mstore(0x00, role)
            sstore(keccak256(0x00, 0x38), or(shl(40, start), end))
            // Emit the {TimedRoleSet} event.
            mstore(0x00, start)
            mstore(0x20, end)
            log3(0x00, 0x40, _TIMED_ROLE_SET_EVENT_SIGNATURE, shr(96, holder_), role)
        }
    }

    /// @dev Requires the role is not greater than `MAX_TIMED_ROLE()`.
    /// If `MAX_TIMED_ROLE()` is not implemented, this is an no-op.
    function _validateTimedRole(uint256 role) internal view virtual {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x32bc6439) // `MAX_TIMED_ROLE()`.
            if and(
                and(gt(role, mload(0x00)), gt(returndatasize(), 0x1f)),
                staticcall(gas(), address(), 0x1c, 0x04, 0x00, 0x20)
            ) {
                mstore(0x00, 0x802ee27f) // `InvalidTimedRole()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Checks that the caller is authorized to set the role.
    function _authorizeSetTimedRole(address holder, uint256 role, uint40 start, uint40 end)
        internal
        virtual
    {
        if (!_timedRolesSenderIsContractOwner()) _revertTimedRolesUnauthorized();
        // Silence compiler warning on unused variables.
        (holder, role, start, end) = (holder, role, start, end);
    }

    /// @dev Returns if `holder` has any roles in `encodedRoles`.
    /// `encodedRoles` is `abi.encode(SAMPLE_ROLE_0, SAMPLE_ROLE_1, ...)`.
    function _hasAnyTimedRoles(address holder, bytes memory encodedRoles)
        internal
        view
        virtual
        returns (bool result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x18, holder)
            mstore(0x04, _TIMED_ROLES_SLOT_SEED)
            let end := add(encodedRoles, shl(5, shr(5, mload(encodedRoles))))
            for {} lt(result, lt(encodedRoles, end)) {} {
                encodedRoles := add(0x20, encodedRoles)
                mstore(0x00, mload(encodedRoles))
                let packed := sload(keccak256(0x00, 0x38))
                result :=
                    lt(
                        lt(timestamp(), and(0xffffffffff, shr(40, packed))),
                        lt(timestamp(), and(0xffffffffff, packed))
                    )
            }
        }
    }

    /// @dev Reverts if `msg.sender` does not have `role`.
    function _checkTimedRole(uint256 role) internal view virtual {
        (bool isActive,,) = timedRoleActive(msg.sender, role);
        if (!isActive) _revertTimedRolesUnauthorized();
    }

    /// @dev Reverts if `msg.sender` does not have any role in `encodedRoles`.
    function _checkTimedRoles(bytes memory encodedRoles) internal view virtual {
        if (!_hasAnyTimedRoles(msg.sender, encodedRoles)) _revertTimedRolesUnauthorized();
    }

    /// @dev Reverts if `msg.sender` is not the contract owner and does not have `role`.
    function _checkOwnerOrTimedRole(uint256 role) internal view virtual {
        if (!_timedRolesSenderIsContractOwner()) _checkTimedRole(role);
    }

    /// @dev Reverts if `msg.sender` is not the contract owner and
    /// does not have any role in `encodedRoles`.
    function _checkOwnerOrTimedRoles(bytes memory encodedRoles) internal view virtual {
        if (!_timedRolesSenderIsContractOwner()) _checkTimedRoles(encodedRoles);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         MODIFIERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Marks a function as only callable by an account with `role`.
    modifier onlyTimedRole(uint256 role) virtual {
        _checkTimedRole(role);
        _;
    }

    /// @dev Marks a function as only callable by an account with any role in `encodedRoles`.
    /// `encodedRoles` is `abi.encode(SAMPLE_ROLE_0, SAMPLE_ROLE_1, ...)`.
    modifier onlyTimedRoles(bytes memory encodedRoles) virtual {
        _checkTimedRoles(encodedRoles);
        _;
    }

    /// @dev Marks a function as only callable by the owner or by an account with `role`.
    modifier onlyOwnerOrTimedRole(uint256 role) virtual {
        _checkOwnerOrTimedRole(role);
        _;
    }

    /// @dev Marks a function as only callable by the owner or
    /// by an account with any role in `encodedRoles`.
    /// Checks for ownership first, then checks for roles.
    /// `encodedRoles` is `abi.encode(SAMPLE_ROLE_0, SAMPLE_ROLE_1, ...)`.
    modifier onlyOwnerOrTimedRoles(bytes memory encodedRoles) virtual {
        _checkOwnerOrTimedRoles(encodedRoles);
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns if the `msg.sender` is equal to `owner()` on this contract.
    /// If the contract does not have `owner()` implemented, returns false.
    function _timedRolesSenderIsContractOwner() private view returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x8da5cb5b) // `owner()`.
            result :=
                and(
                    and(eq(caller(), mload(0x00)), gt(returndatasize(), 0x1f)),
                    staticcall(gas(), address(), 0x1c, 0x04, 0x00, 0x20)
                )
        }
    }

    /// @dev Reverts with `TimedRolesUnauthorized()`.
    function _revertTimedRolesUnauthorized() private pure {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0xb0c7b036) // `TimedRolesUnauthorized()`.
            revert(0x1c, 0x04)
        }
    }
}
