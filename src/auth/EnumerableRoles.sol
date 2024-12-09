// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Enumerable multiroles authorization mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/auth/EnumerableRoles.sol)
///
/// @dev Note:
/// This implementation is agnostic to the Ownable that the contract inherits from.
/// It performs a self-staticcall to the `owner()` function to determine the owner.
/// This is useful for situations where the contract inherits from
/// OpenZeppelin's Ownable, such as in LayerZero's OApp contracts.
///
/// This implementation performs a self-staticcall to `MAX_ROLE()` to determine
/// the maximum role that can be set/unset. If the inheriting contract does not
/// have `MAX_ROLE()`, then any role can be set/unset.
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
abstract contract EnumerableRoles {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The status of `role` for `holder` has been set to `active`.
    event RoleSet(address indexed holder, uint256 indexed role, bool indexed active);

    /// @dev `keccak256(bytes("RoleSet(address,uint256,bool)"))`.
    uint256 private constant _ROLE_SET_EVENT_SIGNATURE =
        0xaddc47d7e02c95c00ec667676636d772a589ffbf0663cfd7cd4dd3d4758201b8;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The index is out of bounds of the role holders array.
    error RoleHoldersIndexOutOfBounds();

    /// @dev Cannot set the role of the zero address.
    error RoleHolderIsZeroAddress();

    /// @dev The role has exceeded the maximum role.
    error InvalidRole();

    /// @dev Unauthorized to perform the action.
    error EnumerableRolesUnauthorized();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The storage layout of the holders enumerable mapping is given by:
    /// ```
    ///     mstore(0x18, holder)
    ///     mstore(0x04, _ENUMERABLE_ROLES_SLOT_SEED)
    ///     mstore(0x00, role)
    ///     let rootSlot := keccak256(0x00, 0x24)
    ///     let positionSlot := keccak256(0x00, 0x38)
    ///     let holderSlot := add(rootSlot, sload(positionSlot))
    ///     let holderInStorage := shr(96, sload(holderSlot))
    ///     let length := shr(160, shl(160, sload(rootSlot)))
    /// ```
    uint256 private constant _ENUMERABLE_ROLES_SLOT_SEED = 0xee9853bb;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  PUBLIC UPDATE FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sets the status of `role` of `holder` to `active`.
    function setRole(address holder, uint256 role, bool active) public payable virtual {
        _authorizeSetRole(holder, role, active);
        _setRole(holder, role, active);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   PUBLIC READ FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns if `holder` has active `role`.
    function hasRole(address holder, uint256 role) public view virtual returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x18, holder)
            mstore(0x04, _ENUMERABLE_ROLES_SLOT_SEED)
            mstore(0x00, role)
            result := iszero(iszero(sload(keccak256(0x00, 0x38))))
        }
    }

    /// @dev Returns an array of the holders of `role`.
    function roleHolders(uint256 role) public view virtual returns (address[] memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(0x04, _ENUMERABLE_ROLES_SLOT_SEED)
            mstore(0x00, role)
            let rootSlot := keccak256(0x00, 0x24)
            let rootPacked := sload(rootSlot)
            let n := shr(160, shl(160, rootPacked))
            let o := add(0x20, result)
            mstore(o, shr(96, rootPacked))
            for { let i := 1 } lt(i, n) { i := add(i, 1) } {
                mstore(add(o, shl(5, i)), shr(96, sload(add(rootSlot, i))))
            }
            mstore(result, n)
            mstore(0x40, add(o, shl(5, n)))
        }
    }

    /// @dev Returns the total number of holders of `role`.
    function roleHolderCount(uint256 role) public view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x04, _ENUMERABLE_ROLES_SLOT_SEED)
            mstore(0x00, role)
            result := shr(160, shl(160, sload(keccak256(0x00, 0x24))))
        }
    }

    /// @dev Returns the holder of `role` at the index `i`.
    function roleHolderAt(uint256 role, uint256 i) public view virtual returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x04, _ENUMERABLE_ROLES_SLOT_SEED)
            mstore(0x00, role)
            let rootSlot := keccak256(0x00, 0x24)
            let rootPacked := sload(rootSlot)
            if iszero(lt(i, shr(160, shl(160, rootPacked)))) {
                mstore(0x00, 0x5694da8e) // `RoleHoldersIndexOutOfBounds()`.
                revert(0x1c, 0x04)
            }
            result := shr(96, rootPacked)
            if i { result := shr(96, sload(add(rootSlot, i))) }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Set the role for holder directly without authorization guard.
    function _setRole(address holder, uint256 role, bool active) internal virtual {
        _validateRole(role);
        /// @solidity memory-safe-assembly
        assembly {
            let holder_ := shl(96, holder)
            if iszero(holder_) {
                mstore(0x00, 0x82550143) // `RoleHolderIsZeroAddress()`.
                revert(0x1c, 0x04)
            }
            mstore(0x18, holder)
            mstore(0x04, _ENUMERABLE_ROLES_SLOT_SEED)
            mstore(0x00, role)
            let rootSlot := keccak256(0x00, 0x24)
            let n := shr(160, shl(160, sload(rootSlot)))
            let positionSlot := keccak256(0x00, 0x38)
            let position := sload(positionSlot)
            for {} 1 {} {
                if iszero(active) {
                    if iszero(position) { break }
                    let nSub := sub(n, 1)
                    if iszero(eq(sub(position, 1), nSub)) {
                        let lastHolder_ := shl(96, shr(96, sload(add(rootSlot, nSub))))
                        sstore(add(rootSlot, sub(position, 1)), lastHolder_)
                        sstore(add(rootSlot, nSub), 0)
                        mstore(0x24, lastHolder_)
                        sstore(keccak256(0x00, 0x38), position)
                    }
                    sstore(rootSlot, or(shl(96, shr(96, sload(rootSlot))), nSub))
                    sstore(positionSlot, 0)
                    break
                }
                if iszero(position) {
                    sstore(add(rootSlot, n), holder_)
                    sstore(positionSlot, add(n, 1))
                    sstore(rootSlot, add(sload(rootSlot), 1))
                }
                break
            }
            // forgefmt: disable-next-item
            log4(0x00, 0x00, _ROLE_SET_EVENT_SIGNATURE, shr(96, holder_), role, iszero(iszero(active)))
        }
    }

    /// @dev Requires the role is not greater than `MAX_ROLE()`.
    /// If `MAX_ROLE()` is not implemented, this is an no-op.
    function _validateRole(uint256 role) internal view virtual {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0xd24f19d5) // `MAX_ROLE()`.
            if and(
                and(gt(role, mload(0x00)), gt(returndatasize(), 0x1f)),
                staticcall(gas(), address(), 0x1c, 0x04, 0x00, 0x20)
            ) {
                mstore(0x00, 0xd954416a) // `InvalidRole()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Checks that the caller is authorized to set the role.
    function _authorizeSetRole(address holder, uint256 role, bool active) internal virtual {
        if (!_senderIsContractOwner()) _revertEnumerableRolesUnauthorized();
        // Silence compiler warning on unused variables.
        (holder, role, active) = (holder, role, active);
    }

    /// @dev Returns if `holder` has `role`.
    function _hasRole(address holder, uint256 role) internal view virtual returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x18, holder)
            mstore(0x04, _ENUMERABLE_ROLES_SLOT_SEED)
            mstore(0x00, role)
            result := sload(keccak256(0x00, 0x38))
        }
    }

    /// @dev Returns if `holder` has any roles in `encodedRoles`.
    /// `encodedRoles` is `abi.encode(SAMPLE_ROLE_0, SAMPLE_ROLE_1, ...)`.
    function _hasAnyRoles(address holder, bytes memory encodedRoles)
        internal
        view
        virtual
        returns (bool result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x18, holder)
            mstore(0x04, _ENUMERABLE_ROLES_SLOT_SEED)
            let end := add(encodedRoles, shl(5, shr(5, mload(encodedRoles))))
            for {} lt(result, lt(encodedRoles, end)) {} {
                encodedRoles := add(0x20, encodedRoles)
                mstore(0x00, mload(encodedRoles))
                result := sload(keccak256(0x00, 0x38))
            }
            result := iszero(iszero(result))
        }
    }

    /// @dev Reverts if `msg.sender` does not have `role`.
    function _checkRole(uint256 role) internal view virtual {
        if (!_hasRole(msg.sender, role)) _revertEnumerableRolesUnauthorized();
    }

    /// @dev Reverts if `msg.sender` does not have any role in `encodedRoles`.
    function _checkRoles(bytes memory encodedRoles) internal view virtual {
        if (!_hasAnyRoles(msg.sender, encodedRoles)) _revertEnumerableRolesUnauthorized();
    }

    /// @dev Reverts if `msg.sender` is not the contract owner and does not have `role`.
    function _checkOwnerOrRole(uint256 role) internal view virtual {
        if (!_senderIsContractOwner()) _checkRole(role);
    }

    /// @dev Reverts if `msg.sender` is not the contract owner and
    /// does not have any role in `encodedRoles`.
    function _checkOwnerOrRoles(bytes memory encodedRoles) internal view virtual {
        if (!_senderIsContractOwner()) _checkRoles(encodedRoles);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         MODIFIERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Marks a function as only callable by an account with `role`.
    modifier onlyRole(uint256 role) virtual {
        _checkRole(role);
        _;
    }

    /// @dev Marks a function as only callable by an account with any role in `encodedRoles`.
    /// `encodedRoles` is `abi.encode(SAMPLE_ROLE_0, SAMPLE_ROLE_1, ...)`.
    modifier onlyRoles(bytes memory encodedRoles) virtual {
        _checkRoles(encodedRoles);
        _;
    }

    /// @dev Marks a function as only callable by the owner or by an account with `role`.
    modifier onlyOwnerOrRole(uint256 role) virtual {
        _checkOwnerOrRole(role);
        _;
    }

    /// @dev Marks a function as only callable by the owner or
    /// by an account with any role in `encodedRoles`.
    /// Checks for ownership first, then checks for roles.
    /// `encodedRoles` is `abi.encode(SAMPLE_ROLE_0, SAMPLE_ROLE_1, ...)`.
    modifier onlyOwnerOrRoles(bytes memory encodedRoles) virtual {
        _checkOwnerOrRoles(encodedRoles);
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns if the `msg.sender` is equal to `owner()` on this contract.
    /// If the contract does not have `owner()` implemented, returns false.
    function _senderIsContractOwner() private view returns (bool result) {
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

    /// @dev Reverts with `EnumerableRolesUnauthorized()`.
    function _revertEnumerableRolesUnauthorized() private pure {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x99152cca) // `EnumerableRolesUnauthorized()`.
            revert(0x1c, 0x04)
        }
    }
}
