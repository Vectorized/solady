// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {EIP712} from "../utils/EIP712.sol";
import {SignatureCheckerLib} from "../utils/SignatureCheckerLib.sol";

/// @notice Input hash helper for predeploy smart accounts using Solady ERC1271.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/accounts/ERC1271InputGenerator.sol)
/// @author Coinbase (https://github.com/coinbase/smart-wallet/blob/main/src/utils/ERC1271InputGenerator.sol)
///
/// @dev
/// This contract is not meant to ever actually be deployed,
/// only mock deployed and used via a static `eth_call`.
///
/// May be useful for generating ERC-6492 compliant signatures.
/// Inspired by Ambire's DeploylessUniversalSigValidator
/// (https://github.com/AmbireTech/signature-validator/blob/main/contracts/DeploylessUniversalSigValidator.sol)
abstract contract ERC1271InputGenerator {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Account deployment via `accountFactory` with `factoryCalldata` failed.
    error AccountDeploymentFailed();

    /// @dev Account returned from call to `accountFactory` does not match passed account.
    error ReturnedAddressDoesNotMatchAccount();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                ERC1271 INPUT HASH GENERATOR                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    constructor(
        address account,
        bytes32 hash,
        bytes32 parentTypehash,
        bytes32 child,
        address accountFactory,
        bytes memory factoryCalldata
    ) {
        /// @solidity memory-safe-assembly
        assembly {
            // If the account already exists, call `replaySafeHash` and return the result.
            if extcodesize(account) {
                // TODO.
            }
        }
    }
}
