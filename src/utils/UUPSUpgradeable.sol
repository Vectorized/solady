// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice An upgradeability mechanism designed for UUPS pattern.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/UUPSUpgradeable.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/utils/UUPSUpgradeable.sol)
abstract contract UUPSUpgradeable {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The upgrade failed.
    error UpgradeFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Emitted when contract is upgraded with `implementation`.
    event Upgraded(address indexed implementation);

    /// @dev `keccak256(bytes("Upgraded(address)"))`.
    bytes32 private constant _UPGRADED_EVENT_SIGNATURE =
        0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ERC-1967 storage slot for the implementation in the proxy.
    /// `uint256(keccak256("eip1967.proxy.implementation")) - 1`.
    bytes32 internal constant _ERC1967_IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       UUPS Functions                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Function must be authorized msg.sender for upgrade contract.
    function _authorizeUpgrade() internal virtual;

    /// @dev Implementation of the ERC1822 {proxiableUUID} function.
    /// @dev This returns the storage slot used by the implementation.
    function proxiableUUID() external pure returns (bytes32) {
        return _ERC1967_IMPLEMENTATION_SLOT;
    }

    /// @dev Upgrades the implementation of th proxy to `newImplementation`.
    /// Then, delegate calls to newImplementation with abi encoded `data`.
    /// The caller of this function must be `_authorizeUpgrade`.
    function upgradeToAndCall(address newImplementation, bytes calldata data)
        public
        payable
        virtual
    {
        _authorizeUpgrade();
        /// @solidity memory-safe-assembly
        assembly {
            // cleaning address upper dirty bits
            newImplementation := and(newImplementation, 0xffffffffffffffffffffffffffffffffffffffff)

            mstore(0x01, 0x52d1902d) // bytes4(keccak256("proxiableUUID()"))

            // Upgraded contract must return `_ERC1967_IMPLEMENTATION_SLOT`
            if iszero(
                eq(
                    mload(staticcall(gas(), newImplementation, 0x1d, 0x04, 0x01, 0x20)),
                    _ERC1967_IMPLEMENTATION_SLOT
                )
            ) {
                mstore(0x01, 0x55299b49) // `UpgradeFailed()`.
                revert(0x1d, 0x04)
            }

            // copy calldata into memory
            calldatacopy(0x00, data.offset, data.length)

            // delegate call to `newImplementation` and revert upon failed
            if iszero(delegatecall(gas(), newImplementation, 0x00, data.length, codesize(), 0x00)) {
                returndatacopy(0x00, 0x00, returndatasize())
                revert(0x00, returndatasize())
            }

            // update the new implementation address to `_ERC1967_IMPLEMENTATION_SLOT`.
            sstore(_ERC1967_IMPLEMENTATION_SLOT, newImplementation)
            // Emit the {Upgraded} event.
            log2(codesize(), 0x00, _UPGRADED_EVENT_SIGNATURE, newImplementation)
            returndatacopy(0x00, 0x00, returndatasize())
            return(0x00, returndatasize())
        }
    }

    /// @dev Upgrades the implementation of th proxy to `newImplementation`.
    /// The caller of this function must be `_authorizeUpgrade`.
    function upgradeTo(address newImplementation) public virtual {
        _authorizeUpgrade();
        /// @solidity memory-safe-assembly
        assembly {
            // cleaning address upper dirty bits
            newImplementation := and(newImplementation, 0xffffffffffffffffffffffffffffffffffffffff)

            mstore(0x01, 0x52d1902d) // bytes4(keccak256("proxiableUUID()"))

            // Upgraded contract must return `_ERC1967_IMPLEMENTATION_SLOT`
            if iszero(
                eq(
                    mload(staticcall(gas(), newImplementation, 0x1d, 0x04, 0x01, 0x20)),
                    _ERC1967_IMPLEMENTATION_SLOT
                )
            ) {
                mstore(0x01, 0x55299b49) // `UpgradeFailed()`.
                revert(0x1d, 0x04)
            }

            // update the new implementation address to `_ERC1967_IMPLEMENTATION_SLOT`.
            sstore(_ERC1967_IMPLEMENTATION_SLOT, newImplementation)

            // Emit the {Upgraded} event.
            log2(codesize(), 0x00, _UPGRADED_EVENT_SIGNATURE, newImplementation)
        }
    }
}
