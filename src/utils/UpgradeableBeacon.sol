// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Upgradeable beacon for ERC1967 beacon proxies.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/UpgradeableBeacon.sol)
/// @author Modified from OpenZeppelin
/// (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/beacon/UpgradeableBeacon.sol)
///
/// @dev Note:
/// - The implementation is intended to be used with ERC1967 beacon proxies.
///   See: `LibClone.deployERC1967` and related functions.
/// - For gas efficiency, the entirety of the contract (including basic ownable functionality)
///   is implemented in the fallback method. Thus, an interface is provided for easy querying.
interface IUpgradeableBeacon {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The new implementation is not a deployed contract.
    error NewImplementationHasNoCode();

    /// @dev The caller is not authorized to perform the operation.
    error Unauthorized();

    /// @dev The `newOwner` cannot be the zero address.
    error NewOwnerIsZeroAddress();

    /// @dev The function selector is not recognized.
    error FnSelectorNotRecognized();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Emitted when the proxy's implementation is upgraded.
    event Upgraded(address indexed implementation);

    /// @dev The ownership is transferred from `oldOwner` to `newOwner`.
    /// This event is intentionally kept the same as OpenZeppelin's Ownable to be
    /// compatible with indexers and [EIP-173](https://eips.ethereum.org/EIPS/eip-173),
    /// despite it not being as lightweight as a single argument event.
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               UPGRADEABLE BEACON OPERATIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the implementation stored in the beacon.
    /// See: https://eips.ethereum.org/EIPS/eip-1967#beacon-contract-address
    function implementation() external view returns (address);

    /// @dev Returns the owner of the beacon.
    function owner() external view returns (address);

    /// @dev Allows the owner to upgrade the implementation.
    function upgradeTo(address newImplementation) external;

    /// @dev Allows the owner to transfer the ownership to `newOwner`.
    function transferOwnership(address newOwner) external;

    /// @dev Allows the owner to renounce their ownership.
    function renounceOwnership() external;
}

/// @dev This contract implements `IUpgradeableBeacon`.
contract UpgradeableBeacon {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev `keccak256(bytes("Upgraded(address)"))`.
    uint256 private constant _UPGRADED_EVENT_SIGNATURE =
        0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b;

    /// @dev `keccak256(bytes("OwnershipTransferred(address,address)"))`.
    uint256 private constant _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE =
        0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The storage slot for the implementation address.
    /// `uint72(bytes9(keccak256("_UPGRADEABLE_BEACON_IMPLEMENTATION_SLOT")))`.
    /// The storage slot for the owner address is given by:
    /// `_UPGRADEABLE_BEACON_IMPLEMENTATION_SLOT + 1`.
    uint256 internal constant _UPGRADEABLE_BEACON_IMPLEMENTATION_SLOT = 0x911c5a209f08d5ec5e;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               UPGRADEABLE BEACON OPERATIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Required to be called in the constructor or initializer.
    /// This function does not guard against double-initialization.
    function _initializeUpgradeableBeacon(address initialOwner, address initialImplementation)
        internal
        virtual
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits.
            initialOwner := shr(96, shl(96, initialOwner))
            initialImplementation := shr(96, shl(96, initialImplementation))
            if iszero(initialOwner) {
                mstore(0x00, 0x7448fbae) // `NewOwnerIsZeroAddress()`.
                revert(0x1c, 0x04)
            }
            if iszero(extcodesize(initialImplementation)) {
                mstore(0x00, 0x6d3e283b) // `NewImplementationHasNoCode()`.
                revert(0x1c, 0x04)
            }
            let implementationSlot := _UPGRADEABLE_BEACON_IMPLEMENTATION_SLOT
            // Store the initial owner.
            sstore(add(1, implementationSlot), initialOwner)
            // Store the initial implementation.
            sstore(implementationSlot, initialImplementation)
            // Emit the {Upgraded} event.
            log2(codesize(), 0x00, _UPGRADED_EVENT_SIGNATURE, initialImplementation)
            // Emit the {OwnershipTransferred} event.
            log3(codesize(), 0x00, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, 0, initialOwner)
        }
    }

    /// @dev Modifier for the fallback function.
    modifier upgradeableBeaconFallback() virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // `implementation()`.
            if eq(0x5c60da1b, shr(224, calldataload(0x00))) {
                mstore(0x00, sload(_UPGRADEABLE_BEACON_IMPLEMENTATION_SLOT))
                return(0x00, 0x20)
            }
            let implementationSlot := _UPGRADEABLE_BEACON_IMPLEMENTATION_SLOT
            let ownerSlot := add(1, implementationSlot)
            let sel := shr(224, calldataload(0x00))
            // `owner()`.
            if eq(0x8da5cb5b, sel) {
                mstore(0x00, sload(ownerSlot))
                return(0x00, 0x20)
            }
            let mode :=
                or(
                    eq(0x715018a6, sel), // `renounceOwnership()`.
                    or(
                        shl(1, eq(0xf2fde38b, sel)), // `transferOwnership(address)`.
                        shl(2, eq(0x3659cfe6, sel)) // `upgradeTo(address)`.
                    )
                )
            if mode {
                let oldOwner := sload(ownerSlot)
                // Require that the caller is the current owner.
                if iszero(eq(caller(), oldOwner)) {
                    mstore(0x00, 0x82b42900) // `Unauthorized()`.
                    revert(0x1c, 0x04)
                }
                let a := 0
                // `transferOwnership(address)`, `upgradeTo(address)`.
                if and(mode, 6) {
                    a := calldataload(0x04)
                    // Require that the calldata is at least (32 + 4) bytes
                    // and the address does not have dirty upper bits.
                    returndatacopy(
                        0x00, returndatasize(), or(lt(calldatasize(), 0x24), shr(160, a))
                    )
                    // `upgradeTo(address)`.
                    if eq(mode, 4) {
                        if iszero(extcodesize(a)) {
                            mstore(0x00, 0x6d3e283b) // `NewImplementationHasNoCode()`.
                            revert(0x1c, 0x04)
                        }
                        // Store the new implementation.
                        sstore(implementationSlot, a)
                        // Emit the {Upgraded} event.
                        log2(codesize(), 0x00, _UPGRADED_EVENT_SIGNATURE, a)
                        // Early return.
                        return(codesize(), 0x00)
                    }
                    // `transferOwnership(address)` and `a == address(0)`.
                    if iszero(a) {
                        mstore(0x00, 0x7448fbae) // `NewOwnerIsZeroAddress()`.
                        revert(0x1c, 0x04)
                    }
                }
                // `renounceOwnership()`, `transferOwnership(address)`.
                // Store the new owner.
                sstore(ownerSlot, a)
                // Emit the {OwnershipTransferred} event.
                log3(codesize(), 0x00, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, oldOwner, a)
                // Early return.
                return(codesize(), 0x00)
            }
        }
        _;
    }

    fallback() external payable virtual upgradeableBeaconFallback {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x3c10b94e) // `FnSelectorNotRecognized()`.
            revert(0x1c, 0x04)
        }
    }
}
