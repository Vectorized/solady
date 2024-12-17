// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Class that allows for rescue of ETH, ERC20, ERC721 tokens.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Lifebuoy.sol)
///
/// @dev This contract is created to mitigate the following disasters:
/// - Careless user sends tokens to the wrong chain or wrong contract.
/// - Careless dev deploys a contract without a withdraw function in attempt to rescue
///   careless user's tokens, due to deployment nonce mismatch caused by
///   script misfire / misconfiguration.
/// - Careless dev forgets to add a withdraw function to a NFT sale contract.
///
/// Note: if you are deploying via a untrusted `tx.origin`,
/// you MUST override `_lifebuoyDefaultDeployer` to return a trusted address.
///
/// For best safety:
/// - For non-escrow contracts, inherit Lifebuoy as much as possible,
///   and leave it unlocked.
/// - For escrow contracts, lock access as tight as possible,
///   as soon as possible. Or simply don't inherit Lifebuoy.
/// Escrow: Your contract is designed to hold ETH, ERC20s, ERC721s
/// (e.g. liquidity pools).
///
/// All rescue and rescue authorization functions require either:
/// - Caller is the deployer
///   AND the contract is not a proxy
///   AND `rescueLocked() & _LIFEBUOY_DEPLOYER_ACCESS_LOCK == 0`.
/// - Caller is `owner()`
///   AND `rescueLocked() & _LIFEBUOY_OWNER_ACCESS_LOCK == 0`.
///
/// The choice of using bit flags to represent locked statuses is for
/// efficiency, flexibility, convenience.
///
/// This contract is optimized with a priority on minimal bytecode size,
/// as the methods are not intended to be called often.
contract Lifebuoy {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The caller is not authorized to rescue or lock the rescue function.
    error RescueUnauthorizedOrLocked();

    /// @dev The rescue operation has failed due to a failed transfer.
    error RescueTransferFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    LOCK FLAGS CONSTANTS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // These flags are kept internal to avoid bloating up the function dispatch.
    // You can just copy paste this into your own code.

    /// @dev Flag to denote that the deployer's access is locked. (1)
    uint256 internal constant _LIFEBUOY_DEPLOYER_ACCESS_LOCK = 1 << 0;

    /// @dev Flag to denote that the `owner()`'s access is locked. (2)
    uint256 internal constant _LIFEBUOY_OWNER_ACCESS_LOCK = 1 << 1;

    /// @dev Flag to denote that the `lockRescue` function is locked. (4)
    uint256 internal constant _LIFEBUOY_LOCK_RESCUE_LOCK = 1 << 2;

    /// @dev Flag to denote that the `rescueETH` function is locked. (8)
    uint256 internal constant _LIFEBUOY_RESCUE_ETH_LOCK = 1 << 3;

    /// @dev Flag to denote that the `rescueERC20` function is locked. (16)
    uint256 internal constant _LIFEBUOY_RESCUE_ERC20_LOCK = 1 << 4;

    /// @dev Flag to denote that the `rescueERC721` function is locked. (32)
    uint256 internal constant _LIFEBUOY_RESCUE_ERC721_LOCK = 1 << 5;

    /// @dev Flag to denote that the `rescueERC1155` function is locked. (64)
    uint256 internal constant _LIFEBUOY_RESCUE_ERC1155_LOCK = 1 << 6;

    /// @dev Flag to denote that the `rescueERC6909` function is locked. (128)
    uint256 internal constant _LIFEBUOY_RESCUE_ERC6909_LOCK = 1 << 7;

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
        uint256 deployer = uint160(_lifebuoyDefaultDeployer());
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, address())
            mstore(0x20, deployer)
            hash := keccak256(0x00, 0x40)
        }
        _lifebuoyDeployerHash = hash;
    }

    /// @dev Returns `tx.origin` by default. Override to return another address if needed.
    ///
    /// Note: If you are deploying via a untrusted `tx.origin` (e.g. ERC4337 bundler)
    /// you MUST override this function to return a trusted address.
    function _lifebuoyDefaultDeployer() internal view virtual returns (address) {
        // I know about EIP7645, and I will stop it if it gets traction.
        // Worse case, I will add an `ecrecover` method. But not today.
        return tx.origin;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     RESCUE OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` (in wei) ETH from the current contract to `to`.
    /// Reverts upon failure.
    function rescueETH(address to, uint256 amount)
        public
        payable
        virtual
        onlyRescuer(_LIFEBUOY_RESCUE_ETH_LOCK)
    {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(call(gas(), to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, 0x7ec62e76) // `RescueTransferFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Does not check for existence of token or return data. Reverts upon failure.
    function rescueERC20(address token, address to, uint256 amount)
        public
        payable
        virtual
        onlyRescuer(_LIFEBUOY_RESCUE_ERC20_LOCK)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            // `RescueTransferFailed()` and `transfer(address,uint256)`.
            mstore(0x00, shl(96, 0x7ec62e76a9059cbb))
            if iszero(call(gas(), token, callvalue(), 0x10, 0x44, codesize(), 0x00)) {
                revert(0x0c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Sends `id` of ERC721 `token` from the current contract to `to`.
    /// Does not check for existence of token or return data. Reverts upon failure.
    function rescueERC721(address token, address to, uint256 id)
        public
        payable
        virtual
        onlyRescuer(_LIFEBUOY_RESCUE_ERC721_LOCK)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, id) // Store the `id` argument.
            mstore(0x40, shr(96, shl(96, to))) // Store the `to` argument.
            mstore(0x20, address()) // Store the `from` argument.
            // `RescueTransferFailed()` and `transferFrom(address,address,uint256)`.
            mstore(0x00, 0x7ec62e7623b872dd)
            if iszero(call(gas(), token, callvalue(), 0x1c, 0x64, codesize(), 0x00)) {
                revert(0x18, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends `amount` of `id` of ERC1155 `token` from the current contract to `to`.
    /// Does not check for existence of token or return data. Reverts upon failure.
    function rescueERC1155(
        address token,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public payable virtual onlyRescuer(_LIFEBUOY_RESCUE_ERC1155_LOCK) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            // `RescueTransferFailed()` and `safeTransferFrom(address,address,uint256,uint256,bytes)`.
            mstore(m, 0x7ec62e76f242432a)
            mstore(add(0x20, m), address()) // Store the `from` argument.
            mstore(add(0x40, m), shr(96, shl(96, to))) // Store the `to` argument.
            mstore(add(0x60, m), id) // Store the `id` argument.
            mstore(add(0x80, m), amount) // Store the `amount` argument.
            mstore(add(0xa0, m), 0xa0) // Store the offset to `data`.
            mstore(add(0xc0, m), data.length)
            calldatacopy(add(m, 0xe0), data.offset, data.length)
            // forgefmt: disable-next-item
            if iszero(
                call(gas(), token, callvalue(), add(m, 0x1c), add(0xc4, data.length), codesize(), 0x00)
            ) { revert(add(m, 0x18), 0x04) }
        }
    }

    /// @dev Sends `amount` of `id` of ERC6909 `token` from the current contract to `to`.
    /// Does not check for existence of token or return data. Reverts upon failure.
    function rescueERC6909(address token, address to, uint256 id, uint256 amount)
        public
        payable
        virtual
        onlyRescuer(_LIFEBUOY_RESCUE_ERC6909_LOCK)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, id) // Store the `id` argument.
            mstore(0x54, amount) // Store the `amount` argument.
            // `RescueTransferFailed()` and `transfer(address,uint256,uint256)`.
            mstore(0x00, shl(96, 0x7ec62e76095bcdb6))
            if iszero(call(gas(), token, callvalue(), 0x10, 0x64, codesize(), 0x00)) {
                revert(0x0c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              RESCUE AUTHORIZATION OPERATIONS               */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the flags denoting whether access to rescue functions
    /// (including `lockRescue`) is locked.
    function rescueLocked() public view virtual returns (uint256 locks) {
        /// @solidity memory-safe-assembly
        assembly {
            locks := sload(_RESCUE_LOCKED_FLAGS_SLOT)
        }
    }

    /// @dev Locks (i.e. permanently removes) access to rescue functions (including `lockRescue`).
    function lockRescue(uint256 locksToSet)
        public
        payable
        virtual
        onlyRescuer(_LIFEBUOY_LOCK_RESCUE_LOCK)
    {
        _lockRescue(locksToSet);
    }

    /// @dev Internal function to set the lock flags without going through access control.
    function _lockRescue(uint256 locksToSet) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            let s := _RESCUE_LOCKED_FLAGS_SLOT
            sstore(s, or(sload(s), locksToSet))
        }
    }

    /// @dev Requires that the rescue function being guarded is:
    /// 1. Not locked, AND
    /// 2. Called by either:
    ///   (a) The `owner()`, OR
    ///   (b) The deployer (if not via a delegate call and deployer is an EOA).
    function _checkRescuer(uint256 modeLock) internal view virtual {
        uint256 locks = rescueLocked();
        bytes32 h = _lifebuoyDeployerHash;
        /// @solidity memory-safe-assembly
        assembly {
            for {} 1 {} {
                // If the `modeLock` flag is true, set all bits in `locks` to true.
                locks := or(sub(0, iszero(iszero(and(modeLock, locks)))), locks)
                // Caller is the deployer
                // AND the contract is not a proxy
                // AND `locks & _LIFEBUOY_DEPLOYER_ACCESS_LOCK` is false.
                mstore(0x20, caller())
                mstore(and(locks, _LIFEBUOY_DEPLOYER_ACCESS_LOCK), address())
                if eq(keccak256(0x00, 0x40), h) { break }
                // If the caller is `owner()`
                // AND `locks & _LIFEBUOY_OWNER_ACCESS_LOCK` is false.
                mstore(0x08, 0x8da5cb5b0a0362e0) // `owner()` and `RescueUnauthorizedOrLocked()`.
                if and( // The arguments of `and` are evaluated from right to left.
                    lt(
                        and(locks, _LIFEBUOY_OWNER_ACCESS_LOCK),
                        and(gt(returndatasize(), 0x1f), eq(mload(0x00), caller()))
                    ),
                    staticcall(gas(), address(), 0x20, 0x04, 0x00, 0x20)
                ) { break }
                revert(0x24, 0x04)
            }
        }
    }

    /// @dev Modifier that calls `_checkRescuer()` at the start of the function.
    modifier onlyRescuer(uint256 modeLock) virtual {
        _checkRescuer(modeLock);
        _;
    }
}
