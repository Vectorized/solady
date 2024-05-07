// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Upgradeable beacon for ERC1967 beacon proxies.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/UpgradeableBeacon.sol)
/// @author Modified from OpenZeppelin
/// (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/beacon/UpgradeableBeacon.sol)
///
/// @dev Note:
/// - The implementation is intended to be used with ERC1967 beacon proxies.
///   See: `LibClone.deployERC1967BeaconProxy` and related functions.
/// - For gas efficiency, the ownership functionality is baked into this contract.
///
/// Optimized creation code (hex-encoded):
/// `60406101c73d393d5160205180821760a01c3d3d3e803b1560875781684343a0dc92ed22dbfc558068911c5a209f08d5ec5e557fbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b3d38a23d7f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e03d38a3610132806100953d393df35b636d3e283b3d526004601cfdfe3d3560e01c635c60da1b14610120573d3560e01c80638da5cb5b1461010e5780633659cfe61460021b8163f2fde38b1460011b179063715018a6141780153d3d3e684343a0dc92ed22dbfc805490813303610101573d9260068116610089575b508290557f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e03d38a3005b925060048035938460a01c60243610173d3d3e146100ba5782156100ad573861005f565b637448fbae3d526004601cfd5b82803b156100f4578068911c5a209f08d5ec5e557fbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b3d38a2005b636d3e283b3d526004601cfd5b6382b429003d526004601cfd5b684343a0dc92ed22dbfc543d5260203df35b68911c5a209f08d5ec5e543d5260203df3`.
/// See: https://gist.github.com/Vectorized/365bd7f6e9a848010f00adb9e50a2516
///
/// To get the initialization code:
/// `abi.encodePacked(creationCode, abi.encode(initialOwner, initialImplementation))`
///
/// This optimized bytecode is compiled via Yul and is not verifiable via Etherscan
/// at the time of writing. For best gas efficiency, deploy the Yul version.
/// The Solidity version is provided as an interface / reference.
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

    /// @dev The storage slot for the implementation address.
    /// `uint72(bytes9(keccak256("_UPGRADEABLE_BEACON_IMPLEMENTATION_SLOT")))`.
    uint256 internal constant _UPGRADEABLE_BEACON_IMPLEMENTATION_SLOT = 0x911c5a209f08d5ec5e;

    /// @dev The storage slot for the owner address.
    /// `uint72(bytes9(keccak256("_UPGRADEABLE_BEACON_OWNER_SLOT")))`.
    uint256 internal constant _UPGRADEABLE_BEACON_OWNER_SLOT = 0x4343a0dc92ed22dbfc;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CONSTRUCTOR                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    constructor(address initialOwner, address initialImplementation) payable {
        _constructUpgradeableBeacon(initialOwner, initialImplementation);
    }

    /// @dev Called in the constructor. Override as required.
    function _constructUpgradeableBeacon(address initialOwner, address initialImplementation)
        internal
        virtual
    {
        _initializeUpgradeableBeacon(initialOwner, initialImplementation);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               UPGRADEABLE BEACON OPERATIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Required to be called in the constructor or initializer.
    /// This function does not guard against double-initialization.
    function _initializeUpgradeableBeacon(address initialOwner, address initialImplementation)
        internal
        virtual
    {
        // We don't need to check if `initialOwner` is the zero address here,
        // as some use cases may not want the beacon to be owned.
        _setOwner(initialOwner);
        _setImplementation(initialImplementation);
    }

    /// @dev Sets the implementation directly without authorization guard.
    function _setImplementation(address newImplementation) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            newImplementation := shr(96, shl(96, newImplementation)) // Clean the upper 96 bits.
            if iszero(extcodesize(newImplementation)) {
                mstore(0x00, 0x6d3e283b) // `NewImplementationHasNoCode()`.
                revert(0x1c, 0x04)
            }
            sstore(_UPGRADEABLE_BEACON_IMPLEMENTATION_SLOT, newImplementation) // Store the implementation.
            // Emit the {Upgraded} event.
            log2(codesize(), 0x00, _UPGRADED_EVENT_SIGNATURE, newImplementation)
        }
    }

    /// @dev Sets the owner directly without authorization guard.
    function _setOwner(address newOwner) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            newOwner := shr(96, shl(96, newOwner)) // Clean the upper 96 bits.
            let oldOwner := sload(_UPGRADEABLE_BEACON_OWNER_SLOT)
            sstore(_UPGRADEABLE_BEACON_OWNER_SLOT, newOwner) // Store the owner.
            // Emit the {OwnershipTransferred} event.
            log3(codesize(), 0x00, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, oldOwner, newOwner)
        }
    }

    /// @dev Returns the implementation stored in the beacon.
    /// See: https://eips.ethereum.org/EIPS/eip-1967#beacon-contract-address
    function implementation() public view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(_UPGRADEABLE_BEACON_IMPLEMENTATION_SLOT)
        }
    }

    /// @dev Returns the owner of the beacon.
    function owner() public view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(_UPGRADEABLE_BEACON_OWNER_SLOT)
        }
    }

    /// @dev Allows the owner to upgrade the implementation.
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
    }

    /// @dev Allows the owner to transfer the ownership to `newOwner`.
    function transferOwnership(address newOwner) public virtual onlyOwner {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(shl(96, newOwner)) {
                mstore(0x00, 0x7448fbae) // `NewOwnerIsZeroAddress()`.
                revert(0x1c, 0x04)
            }
        }
        _setOwner(newOwner);
    }

    /// @dev Allows the owner to renounce their ownership.
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /// @dev Throws if the sender is not the owner.
    function _checkOwner() internal view virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // If the caller is not the stored owner, revert.
            if iszero(eq(caller(), sload(_UPGRADEABLE_BEACON_OWNER_SLOT))) {
                mstore(0x00, 0x82b42900) // `Unauthorized()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         MODIFIERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Marks a function as only callable by the owner.
    modifier onlyOwner() virtual {
        _checkOwner();
        _;
    }
}
