// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Timed multiroles authorization mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/auth/TimedRoles.sol)
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
/// can be used in conjunction with `EnumerableRoles` without collisions.
abstract contract TimedRoles {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The active time range of the timed role has been set.
    event TimedRoleSet(address indexed holder, uint256 indexed timedRole, uint40 begin, uint40 end);

    /// @dev `keccak256(bytes("TimedRoleSet(address,uint256,uint40,uint40)"))`.
    uint256 private constant _TIMED_ROLE_SET_EVENT_SIGNATURE =
        0xf7b5bcd44281f9bd7dfe7227dbb5c96dafa8587339fe558592433e9d02ade7d7;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Cannot set the timed role of the zero address.
    error TimedRoleHolderIsZeroAddress();

    /// @dev The timed role has exceeded the maximum timed role.
    error InvalidTimedRole();

    /// @dev Unauthorized to perform the action.
    error TimedRolesUnauthorized();

    /// @dev The `end` cannot be less than the `begin`.
    /// We allow `begin` to be equal to `end` to allow for a zero range.
    error InvalidTimedRoleRange();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The storage layout of the mapping is given by:
    /// ```
    ///     mstore(0x18, holder)
    ///     mstore(0x04, _TIMED_ROLES_SLOT_SEED)
    ///     mstore(0x00, timedRole)
    ///     let activeTimeRangeSlot := keccak256(0x00, 0x38)
    /// ```
    /// Bits Layout:
    /// - [0..39]    `end`.
    /// - [216..255] `begin`.
    uint256 private constant _TIMED_ROLES_SLOT_SEED = 0x28900261;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  PUBLIC UPDATE FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sets the active time range of `timedRole` of `holder` to [`begin`, `end`).
    /// The `timedRole` is active when `begin <= block.timestamp && block.timestamp < end`.
    function setTimedRole(address holder, uint256 timedRole, uint40 begin, uint40 end)
        public
        payable
        virtual
    {
        _authorizeSetTimedRole(holder, timedRole, begin, end);
        _setTimedRole(holder, timedRole, begin, end);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   PUBLIC READ FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns whether the `timedRole` is active for `holder` and the active time range.
    function timedRoleActive(address holder, uint256 timedRole)
        public
        view
        virtual
        returns (bool isActive, uint40 begin, uint40 end)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x18, holder)
            mstore(0x04, _TIMED_ROLES_SLOT_SEED)
            mstore(0x00, timedRole)
            let packed := sload(keccak256(0x00, 0x38))
            begin := shr(216, packed)
            end := and(0xffffffffff, packed)
            isActive := lt(lt(timestamp(), begin), lt(timestamp(), end))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Set the timed role for holder directly without authorization guard.
    function _setTimedRole(address holder, uint256 timedRole, uint40 begin, uint40 end)
        internal
        virtual
    {
        _validateTimedRole(timedRole);
        /// @solidity memory-safe-assembly
        assembly {
            let holder_ := shl(96, holder)
            if iszero(holder_) {
                mstore(0x00, 0x093a136f) // `TimedRoleHolderIsZeroAddress()`.
                revert(0x1c, 0x04)
            }
            // Clean the upper bits.
            begin := and(0xffffffffff, begin)
            end := and(0xffffffffff, end)
            // Validate the range.
            if lt(end, begin) {
                mstore(0x00, 0x3304dd8c) // `InvalidTimedRoleRange()`.
                revert(0x1c, 0x04)
            }
            // Store the range.
            mstore(0x18, holder)
            mstore(0x04, _TIMED_ROLES_SLOT_SEED)
            mstore(0x00, timedRole)
            sstore(keccak256(0x00, 0x38), or(shl(216, begin), end))
            // Emit the {TimedRoleSet} event.
            mstore(0x00, begin)
            mstore(0x20, end)
            log3(0x00, 0x40, _TIMED_ROLE_SET_EVENT_SIGNATURE, shr(96, holder_), timedRole)
        }
    }

    /// @dev Requires the timedRole is not greater than `MAX_TIMED_ROLE()`.
    /// If `MAX_TIMED_ROLE()` is not implemented, this is an no-op.
    function _validateTimedRole(uint256 timedRole) internal view virtual {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x32bc6439) // `MAX_TIMED_ROLE()`.
            if and(
                and(gt(timedRole, mload(0x00)), gt(returndatasize(), 0x1f)),
                staticcall(gas(), address(), 0x1c, 0x04, 0x00, 0x20)
            ) {
                mstore(0x00, 0x802ee27f) // `InvalidTimedRole()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Checks that the caller is authorized to set the timed role.
    function _authorizeSetTimedRole(address holder, uint256 timedRole, uint40 begin, uint40 end)
        internal
        virtual
    {
        if (!_timedRolesSenderIsContractOwner()) _revertTimedRolesUnauthorized();
        // Silence compiler warning on unused variables.
        (holder, timedRole, begin, end) = (holder, timedRole, begin, end);
    }

    /// @dev Returns if `holder` has any roles in `encodedTimeRoles`.
    /// `encodedTimeRoles` is `abi.encode(SAMPLE_TIMED_ROLE_0, SAMPLE_TIMED_ROLE_1, ...)`.
    function _hasAnyTimedRoles(address holder, bytes memory encodedTimeRoles)
        internal
        view
        virtual
        returns (bool result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x18, holder)
            mstore(0x04, _TIMED_ROLES_SLOT_SEED)
            let e := add(encodedTimeRoles, shl(5, shr(5, mload(encodedTimeRoles))))
            for {} lt(result, lt(encodedTimeRoles, e)) {} {
                encodedTimeRoles := add(0x20, encodedTimeRoles)
                mstore(0x00, mload(encodedTimeRoles))
                let p := sload(keccak256(0x00, 0x38))
                result := lt(lt(timestamp(), shr(216, p)), lt(timestamp(), and(0xffffffffff, p)))
            }
        }
    }

    /// @dev Reverts if `msg.sender` does not have `timedRole`.
    function _checkTimedRole(uint256 timedRole) internal view virtual {
        (bool isActive,,) = timedRoleActive(msg.sender, timedRole);
        if (!isActive) _revertTimedRolesUnauthorized();
    }

    /// @dev Reverts if `msg.sender` does not have any timed role in `encodedTimedRoles`.
    function _checkTimedRoles(bytes memory encodedTimedRoles) internal view virtual {
        if (!_hasAnyTimedRoles(msg.sender, encodedTimedRoles)) _revertTimedRolesUnauthorized();
    }

    /// @dev Reverts if `msg.sender` is not the contract owner and does not have `timedRole`.
    function _checkOwnerOrTimedRole(uint256 timedRole) internal view virtual {
        if (!_timedRolesSenderIsContractOwner()) _checkTimedRole(timedRole);
    }

    /// @dev Reverts if `msg.sender` is not the contract owner and
    /// does not have any timed role in `encodedTimedRoles`.
    function _checkOwnerOrTimedRoles(bytes memory encodedTimedRoles) internal view virtual {
        if (!_timedRolesSenderIsContractOwner()) _checkTimedRoles(encodedTimedRoles);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         MODIFIERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Marks a function as only callable by an account with `timedRole`.
    modifier onlyTimedRole(uint256 timedRole) virtual {
        _checkTimedRole(timedRole);
        _;
    }

    /// @dev Marks a function as only callable by an account with any role in `encodedTimedRoles`.
    /// `encodedTimedRoles` is `abi.encode(SAMPLE_TIMED_ROLE_0, SAMPLE_TIMED_ROLE_1, ...)`.
    modifier onlyTimedRoles(bytes memory encodedTimedRoles) virtual {
        _checkTimedRoles(encodedTimedRoles);
        _;
    }

    /// @dev Marks a function as only callable by the owner or by an account with `timedRole`.
    modifier onlyOwnerOrTimedRole(uint256 timedRole) virtual {
        _checkOwnerOrTimedRole(timedRole);
        _;
    }

    /// @dev Marks a function as only callable by the owner or
    /// by an account with any role in `encodedTimedRoles`.
    /// Checks for ownership first, then checks for roles.
    /// `encodedTimedRoles` is `abi.encode(SAMPLE_TIMED_ROLE_0, SAMPLE_TIMED_ROLE_1, ...)`.
    modifier onlyOwnerOrTimedRoles(bytes memory encodedTimedRoles) virtual {
        _checkOwnerOrTimedRoles(encodedTimedRoles);
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
