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
/// have `MAX_ROLE()`, then any uint8 role can be set/unset.
///
/// This implementation uses uint8 to represent roles.
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

    /// @dev The holder's role has been set to `active`.
    event RoleSet(address indexed holder, uint8 indexed role, bool indexed active);

    /// @dev `keccak256(bytes("RoleSet(address,uint8,bool)"))`.
    uint256 private constant _ROLES_SET_EVENT_SIGNATURE =
        0x0fccee3898c0c79430d961e5ee34c89293d582fe44d52db41df7b874ccbdb352;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The index is out of bounds of the role holders array.
    error RoleHoldersIndexOutOfBounds();

    /// @dev Cannot set the role of the zero address.
    error RoleHolderIsZeroAddress();

    /// @dev The role has exceeded the maximum role.
    error RoleExceedsMaxRole();

    /// @dev Unauthorized to perform the action.
    error EnumerableRolesUnauthorized();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The roles slot of `holder` is given by:
    /// ```
    ///     mstore(0x09, _ENUMERABLE_ROLES_SLOT_SEED)
    ///     mstore(0x00, holder)
    ///     let rolesSlot := keccak256(0x0c, 0x1d)
    /// ```
    /// This automatically ignores the upper bits of the `holder` in case
    /// they are not clean, as well as keep the `keccak256` under 32-bytes.
    ///
    /// The storage layout of the holders enumerable mapping is given by:
    /// ```
    ///     let rootSlot := or(shl(248, role), _ENUMERABLE_ROLES_SLOT_SEED)
    ///     mstore(0x20, rootSlot)
    ///     mstore(0x00, shr(96, shl(96, holder)))
    ///     let positionSlot := keccak256(0x00, 0x40)
    ///     let holderSlot := add(rootSlot, sload(positionSlot))
    ///     let holderInStorage := shr(96, sload(holderSlot))
    ///     let lazyLength := shr(160, shl(160, sload(rootSlot)))
    /// ```
    uint256 private constant _ENUMERABLE_ROLES_SLOT_SEED = 0xee9853bbac11ba612c;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  PUBLIC UPDATE FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sets the status of `role` of `holder` to `active`.
    function setRole(address holder, uint8 role, bool active) public payable virtual {
        if (!_isContactOwner(msg.sender)) _revertEnumerableRolesUnauthorized();
        _setRole(holder, role, active);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   PUBLIC READ FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns if `holder` has `role`.
    function hasRole(address holder, uint8 role) public view virtual returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x09, _ENUMERABLE_ROLES_SLOT_SEED)
            mstore(0x00, holder)
            result := and(1, shr(and(0xff, role), sload(keccak256(0x0c, 0x1d))))
        }
    }

    /// @dev Returns an array of roles of `holder`.
    function rolesOf(address holder) public view virtual returns (uint8[] memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(0x09, _ENUMERABLE_ROLES_SLOT_SEED)
            mstore(0x00, holder)
            let ptr := add(result, 0x20)
            let o := 0
            for { let packed := sload(keccak256(0x0c, 0x1d)) } packed {} {
                if iszero(and(packed, 0xffff)) {
                    o := add(o, 16)
                    packed := shr(16, packed)
                    continue
                }
                mstore(ptr, o)
                ptr := add(ptr, shl(5, and(packed, 1)))
                o := add(o, 1)
                packed := shr(1, packed)
            }
            mstore(result, shr(5, sub(ptr, add(result, 0x20))))
            mstore(0x40, ptr)
        }
    }

    /// @dev Returns an array of the holders of `role`.
    function roleHolders(uint8 role) public view virtual returns (address[] memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            let rootSlot := or(shl(248, role), _ENUMERABLE_ROLES_SLOT_SEED)
            let rootPacked := sload(rootSlot)
            let n := shr(160, shl(160, rootPacked))
            let o := add(0x20, result)
            let v := shr(96, rootPacked)
            mstore(o, v)
            for {} 1 {} {
                if iszero(n) {
                    if v {
                        n := 1
                        v := shr(96, sload(add(rootSlot, n)))
                        if v {
                            n := 2
                            mstore(add(o, 0x20), v)
                            v := shr(96, sload(add(rootSlot, n)))
                            if v {
                                n := 3
                                mstore(add(o, 0x40), v)
                            }
                        }
                    }
                    break
                }
                n := shr(1, n)
                for { let i := 1 } lt(i, n) { i := add(i, 1) } {
                    mstore(add(o, shl(5, i)), shr(96, sload(add(rootSlot, i))))
                }
                break
            }
            mstore(result, n)
            mstore(0x40, add(o, shl(5, n)))
        }
    }

    /// @dev Returns the total number of holders of `role`.
    function roleHoldersCount(uint8 role) public view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let rootSlot := or(shl(248, role), _ENUMERABLE_ROLES_SLOT_SEED)
            let rootPacked := sload(rootSlot)
            let n := shr(160, shl(160, rootPacked))
            result := shr(1, n)
            for {} iszero(or(iszero(shr(96, rootPacked)), n)) {} {
                result := 1
                if iszero(sload(add(rootSlot, result))) { break }
                result := 2
                if iszero(sload(add(rootSlot, result))) { break }
                result := 3
                break
            }
        }
    }

    /// @dev Returns the holder of `role` at the index `i`.
    function roleHolderAt(uint8 role, uint256 i) public view virtual returns (address result) {
        uint256 n = roleHoldersCount(role);
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(lt(i, n)) {
                mstore(0x00, 0x5694da8e) // `RoleHoldersIndexOutOfBounds()`.
                revert(0x1c, 0x04)
            }
            result := shr(96, sload(add(or(shl(248, role), _ENUMERABLE_ROLES_SLOT_SEED), i)))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Set the role for holder directly without authorization guard.
    function _setRole(address holder, uint8 role, bool active) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            role := and(0xff, role)
            mstore(0x00, 0xd24f19d5) // `MAX_ROLE()`.
            if and(
                and(gt(role, mload(0x00)), gt(returndatasize(), 0x1f)),
                staticcall(gas(), address(), 0x1c, 0x04, 0x00, 0x20)
            ) {
                mstore(0x00, 0xcd1bae22) // `RoleExceedsMaxRole()`.
                revert(0x1c, 0x04)
            }

            holder := shr(96, shl(96, holder))
            if iszero(holder) {
                mstore(0x00, 0x82550143) // `RoleHolderIsZeroAddress()`.
                revert(0x1c, 0x04)
            }

            let rootSlot := or(shl(248, role), _ENUMERABLE_ROLES_SLOT_SEED)
            let rootPacked := sload(rootSlot)
            let n := shr(160, shl(160, rootPacked))
            mstore(0x09, _ENUMERABLE_ROLES_SLOT_SEED)
            mstore(0x00, holder)
            let rolesSlot := keccak256(0x0c, 0x1d)
            switch active
            case 0 {
                sstore(rolesSlot, and(sload(rolesSlot), not(shl(role, 1))))
                for {} 1 {} {
                    if iszero(n) {
                        if eq(shr(96, rootPacked), holder) {
                            sstore(rootSlot, sload(add(rootSlot, 1)))
                            sstore(add(rootSlot, 1), sload(add(rootSlot, 2)))
                            sstore(add(rootSlot, 2), 0)
                            break
                        }
                        if eq(shr(96, sload(add(rootSlot, 1))), holder) {
                            sstore(add(rootSlot, 1), sload(add(rootSlot, 2)))
                            sstore(add(rootSlot, 2), 0)
                            break
                        }
                        if eq(shr(96, sload(add(rootSlot, 2))), holder) {
                            sstore(add(rootSlot, 2), 0)
                            break
                        }
                        break
                    }
                    mstore(0x20, rootSlot)
                    mstore(0x00, holder)
                    let p := keccak256(0x00, 0x40)
                    let position := sload(p)
                    if iszero(position) { break }
                    n := sub(shr(1, n), 1)
                    if iszero(eq(sub(position, 1), n)) {
                        let lastValue := shr(96, sload(add(rootSlot, n)))
                        sstore(add(rootSlot, sub(position, 1)), shl(96, lastValue))
                        sstore(add(rootSlot, n), 0)
                        mstore(0x00, lastValue)
                        sstore(keccak256(0x00, 0x40), position)
                    }
                    sstore(rootSlot, or(shl(96, shr(96, sload(rootSlot))), or(shl(1, n), 1)))
                    sstore(p, 0)
                    break
                }
            }
            default {
                sstore(rolesSlot, or(sload(rolesSlot), shl(role, 1)))
                for {} 1 {} {
                    mstore(0x20, rootSlot)
                    if iszero(n) {
                        let v0 := shr(96, rootPacked)
                        if iszero(v0) {
                            sstore(rootSlot, shl(96, holder))
                            break
                        }
                        if eq(v0, holder) { break }
                        let v1 := shr(96, sload(add(rootSlot, 1)))
                        if iszero(v1) {
                            sstore(add(rootSlot, 1), shl(96, holder))
                            break
                        }
                        if eq(v1, holder) { break }
                        let v2 := shr(96, sload(add(rootSlot, 2)))
                        if iszero(v2) {
                            sstore(add(rootSlot, 2), shl(96, holder))
                            break
                        }
                        if eq(v2, holder) { break }
                        mstore(0x00, v0)
                        sstore(keccak256(0x00, 0x40), 1)
                        mstore(0x00, v1)
                        sstore(keccak256(0x00, 0x40), 2)
                        mstore(0x00, v2)
                        sstore(keccak256(0x00, 0x40), 3)
                        rootPacked := or(rootPacked, 7)
                        n := 7
                    }
                    mstore(0x00, holder)
                    let p := keccak256(0x00, 0x40)
                    if iszero(sload(p)) {
                        n := shr(1, n)
                        sstore(add(rootSlot, n), shl(96, holder))
                        sstore(p, add(1, n))
                        sstore(rootSlot, add(2, rootPacked))
                        break
                    }
                    break
                }
            }
            log4(0x00, 0x00, _ROLES_SET_EVENT_SIGNATURE, holder, role, iszero(iszero(active)))
        }
    }

    /// @dev Returns if `sender` is equal to `owner()` on this contract.
    /// If the contract does not have `owner()` implemented, returns false.
    function _isContactOwner(address sender) internal view virtual returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x8da5cb5b) // `owner()`.
            result :=
                and(
                    lt(shl(96, xor(sender, mload(0x00))), gt(returndatasize(), 0x1f)),
                    staticcall(gas(), address(), 0x1c, 0x04, 0x00, 0x20)
                )
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
            let end := add(encodedRoles, shl(5, mload(encodedRoles)))
            for {} iszero(eq(encodedRoles, end)) {} {
                encodedRoles := add(0x20, encodedRoles)
                result := or(mload(encodedRoles), result)
            }
            mstore(0x09, _ENUMERABLE_ROLES_SLOT_SEED)
            mstore(0x00, holder)
            result := iszero(iszero(and(result, sload(keccak256(0x0c, 0x1d)))))
        }
    }

    /// @dev Throws if the sender does not have any roles in `encodedRoles`.
    function _checkRoles(bytes memory encodedRoles) internal view virtual {
        if (!_hasAnyRoles(msg.sender, encodedRoles)) _revertEnumerableRolesUnauthorized();
    }

    /// @dev Throws if the sender does not have any roles in `encodedRoles`.
    function _checkOwnerOrRoles(bytes memory encodedRoles) internal view virtual {
        if (!_isContactOwner(msg.sender)) _checkRoles(encodedRoles);
    }

    /// @dev Reverts with `EnumerableRolesUnauthorized()`.
    function _revertEnumerableRolesUnauthorized() internal pure virtual {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x99152cca) // `EnumerableRolesUnauthorized()`.
            revert(0x1c, 0x04)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         MODIFIERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Marks a function as only callable by an account with any role in `encodedRoles`.
    /// `encodedRoles` is `abi.encode(SAMPLE_ROLE_0, SAMPLE_ROLE_1, ...)`.
    modifier onlyRoles(bytes memory encodedRoles) virtual {
        _checkRoles(encodedRoles);
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
}
