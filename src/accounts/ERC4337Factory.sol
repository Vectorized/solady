// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibClone} from "../utils/LibClone.sol";

/// @notice Simple ERC4337 account factory implementation.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/accounts/ERC4337Factory.sol)
///
/// Note:
/// - Unlike the ERC1967Factory, this factory does NOT store any admin info on the factory itself.
///   The deployed ERC4337 accounts are minimal ERC1967 proxies to an ERC4337 implementation.
///   The proxy bytecode does NOT contain any upgrading logic.
/// - This factory does NOT contain any logic for upgrading the ERC4337 accounts.
///   Upgrading must be done via UUPS logic on the accounts themselves.
/// - The ERC4337 standard expects the factory to use deterministic deployment.
///   As such, this factory does not include any non-deterministic deployment methods.
contract ERC4337Factory {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         IMMUTABLES                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Address of the ERC4337 implementation.
    address public immutable implementation;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CONSTRUCTOR                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    constructor(address erc4337) payable {
        implementation = erc4337;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      DEPLOY FUNCTIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys an ERC4337 account with `salt` and returns its deterministic address.
    /// If the account is already deployed, it will simply return its address.
    /// Any `msg.value` will simply be forwarded to the account, regardless.
    function createAccount(address owner, bytes32 salt) public payable virtual returns (address) {
        // Constructor data is optional, and is omitted for easier Etherscan verification.
        (bool alreadyDeployed, address account) =
            LibClone.deployDeterministicERC1967(msg.value, implementation, salt);

        if (!alreadyDeployed) {
            LibClone.checkStartsWith(salt, owner);
            /// @solidity memory-safe-assembly
            assembly {
                mstore(0x14, owner) // Store the `owner` argument.
                mstore(0x00, 0xc4d66de8000000000000000000000000) // `initialize(address)`.
                if iszero(call(gas(), account, 0, 0x10, 0x24, codesize(), 0x00)) {
                    returndatacopy(mload(0x40), 0x00, returndatasize())
                    revert(mload(0x40), returndatasize())
                }
            }
        }
        return account;
    }

    /// @dev Returns the deterministic address of the account created via `createAccount`.
    function getAddress(bytes32 salt) public view virtual returns (address) {
        return LibClone.predictDeterministicAddressERC1967(implementation, salt, address(this));
    }

    /// @dev Returns the initialization code hash of the ERC4337 account (a minimal ERC1967 proxy).
    /// Used for mining vanity addresses with create2crunch.
    function initCodeHash() public view virtual returns (bytes32) {
        return LibClone.initCodeHashERC1967(implementation);
    }
}
