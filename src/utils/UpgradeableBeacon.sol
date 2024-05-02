// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Upgradeable beacon for ERC1967 beacon proxies.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/UpgradeableBeacon.sol)
/// @author Modified from OpenZeppelin
/// (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/beacon/UpgradeableBeacon.sol)
///
/// @dev Note:
/// - Etherscan proxy detection requires the beacon contract to be verifiable.
/// - For gas efficiency, the entirely of this contract is implemented in the
///   fallback method.
contract UpgradeableBeacon {
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

    /// @dev `keccak256(bytes("Upgraded(address)"))`.
    uint256 private constant _UPGRADED_EVENT_SIGNATURE =
        0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b;

    /// @dev `keccak256(bytes("OwnershipTransferred(address,address)"))`.
    uint256 private constant _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE =
        0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The storage slot for the owner address.
    /// `uint72(bytes9(keccak256("_UPGRADEABLE_BEACON_OWNER_SLOT")))`.
    uint256 internal constant _UPGRADEABLE_BEACON_OWNER_SLOT = 0x4343a0dc92ed22dbfc;

    /// @dev The storage slot for the implementation address.
    /// `uint72(bytes9(keccak256("_UPGRADEABLE_BEACON_IMPLEMENTATION_SLOT")))`.
    uint256 internal constant _UPGRADEABLE_BEACON_IMPLEMENTATION_SLOT = 0x911c5a209f08d5ec5e;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               UPGRADEABLE BEACON OPERATIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Required to be called in the constructor or initializer.
    function _initializeUpgradeableBeacon(address initialOwner, address initialImplementation) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits.
            initialOwner := shr(96, shl(96, initialOwner))
            initialImplementation := shr(96, shl(96, initialImplementation))
            if iszero(initialOwner) {
                mstore(0x00, 0x6d3e283b) // `NewImplementationHasNoCode()`.
                revert(0x1c, 0x04)   
            }
            if iszero(extcodesize(initialImplementation)) {
                mstore(0x00, 0x6d3e283b) // `NewImplementationHasNoCode()`.
                revert(0x1c, 0x04)
            }
            // Store the initial owner.
            sstore(_UPGRADEABLE_BEACON_OWNER_SLOT, initialOwner)
            // Store the initial implementation.
            sstore(_UPGRADEABLE_BEACON_IMPLEMENTATION_SLOT, initialOwner)
            // Emit the {Upgraded} event.
            log2(codesize(), 0x00, _UPGRADED_EVENT_SIGNATURE, initialImplementation)
            // Emit the {OwnershipTransferred} event.
            log3(0x00, 0x00, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, 0, initialOwner)
        }
    }

    fallback() external payable virtual {

    }


}

contract UpgradeableBeaconWithPublicABI {
    
}
