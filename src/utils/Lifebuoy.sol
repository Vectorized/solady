// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Class that allows for rescue of ETH, ERC20, ERC721 assets.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Lifebuoy.sol)
///
/// @dev This contract is intended to be inherited as widely as possible,
/// so that in the case where someone carelessly sends ETH, ERC20, ERC721
/// to the wrong chain or wrong address, we can still rescue the assets.
///
/// All rescue and rescue authorization functions require either:
/// - Caller is `owner()`
///   AND rescue not locked for owner.
/// - Caller is the deployer
///   AND caller is an EOA
///   AND the contract is not a proxy
///   AND rescue is not locked for the deployer.
contract Lifebuoy {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The caller is not authorized to rescue or lock the rescue function.
    error RescueUnauthorizedOrLocked();

    /// @dev The rescue operation has failed due to a failed transfer.
    error RescueFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         IMMUTABLES                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev For checking that the caller is the deployer and
    /// that the context is not a delegatecall
    /// (so that the implementation deployer cannot drain proxies).
    bytes32 internal immutable _lifebuoyDeployerHash;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The rescue locked flags slot is given by:
    /// `bytes32(~uint256(uint32(bytes4(keccak256("_RESCUE_LOCKED_FLAGS_SLOT_NOT")))))`.
    /// It is intentionally chosen to be a high value
    /// to avoid collision with lower slots.
    /// The choice of manual storage layout is to enable compatibility
    /// with both regular and upgradeable contracts.
    bytes32 internal constant _RESCUE_LOCKED_FLAGS_SLOT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffb8e2915b;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CONSTRUCTOR                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    constructor() payable {
        bytes32 hash;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, caller())
            mstore(0x20, address())
            hash := keccak256(0x00, 0x40)
        }
        _lifebuoyDeployerHash = hash;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              RESCUE AUTHORIZATION OPERATIONS               */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Requires that the rescue functions are not locked,
    /// and the caller is either the `owner()`, or the deployer (if not via a delegate call).
    function _checkRescuer() internal view virtual {
        (bool lockedForDeployer, bool lockedForOwner) = rescueLocked();
        bytes32 lifebuoyDeployerHash = _lifebuoyDeployerHash;
        /// @solidity memory-safe-assembly
        assembly {
            for {} 1 {} {
                // If the caller is an EOA, check if the caller is the deployer and
                // that the context is not a delegatecall. For safety, we will only allow EOAs
                // in case the contract is deployed via a factory with permissionless functions.
                // In the case where the mock is a proxy, it is highly likely that it will
                // have the appropriate `owner()` set.
                mstore(0x00, caller())
                mstore(0x20, address())
                if iszero(
                    or(
                        or(extcodesize(caller()), lockedForDeployer),
                        xor(keccak256(0x00, 0x40), lifebuoyDeployerHash)
                    )
                ) { break }
                // We'll do a self staticcall to `owner()` so that this is compatible
                // with any kind of Ownable contract, not just Solady's.
                mstore(0x08, 0x8da5cb5b0a0362e0) // `owner()` and `RescueUnauthorizedOrLocked()`.
                if and(
                    lt(lockedForOwner, eq(mload(0x00), caller())),
                    staticcall(gas(), address(), 0x20, 0x04, 0x00, 0x20)
                ) { break }
                revert(0x24, 0x04)
            }
        }
    }

    /// @dev Modifier that calls `_checkRescuer()`.
    modifier onlyRescuer() virtual {
        _checkRescuer();
        _;
    }

    /// @dev Locks rescue functions for the deployer.
    function lockRescueForDeployer() public virtual onlyRescuer {
        /// @solidity memory-safe-assembly
        assembly {
            let s := _RESCUE_LOCKED_FLAGS_SLOT
            sstore(s, or(sload(s), 1))
        }
    }

    /// @dev Locks rescue functions for the owner.
    function lockRescueForOwner() public virtual onlyRescuer {
        /// @solidity memory-safe-assembly
        assembly {
            let s := _RESCUE_LOCKED_FLAGS_SLOT
            sstore(s, or(sload(s), 2))
        }
    }

    /// @dev Returns the rescue locked status for the deployer and the owner.
    function rescueLocked() public view virtual returns (bool forDeployer, bool forOwner) {
        /// @solidity memory-safe-assembly
        assembly {
            let flags := sload(_RESCUE_LOCKED_FLAGS_SLOT)
            forDeployer := and(1, flags)
            forOwner := iszero(iszero(and(2, flags)))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     RESCUE OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` (in wei) ETH from the current contract to `to`.
    /// Reverts upon failure.
    function rescueETH(address to, uint256 amount) public virtual onlyRescuer {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(call(gas(), to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, 0xb8eaf7a1) // `RescueFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function rescueERC20(address token, address to, uint256 amount) public virtual onlyRescuer {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, shl(96, 0xa9059cbb)) // `transfer(address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0xb8eaf7a1) // `RescueFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Sends `tokenId` of ERC721 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function rescueERC721(address token, address to, uint256 tokenId) public virtual onlyRescuer {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, tokenId) // Store the `tokenId` argument.
            mstore(0x40, shr(96, shl(96, to))) // Store the `to` argument.
            mstore(0x20, address()) // Store the `from` argument.
            // `RescueFailed()` and `transferFrom(address,address,uint256)`.
            mstore(0x00, 0xb8eaf7a123b872dd)
            // Perform the transfer, reverting upon failure.
            if iszero(mul(extcodesize(token), call(gas(), token, 0, 0x1c, 0x64, codesize(), 0x00)))
            {
                revert(0x18, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }
}
