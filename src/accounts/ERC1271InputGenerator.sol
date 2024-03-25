// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Deployless input hash generator for predeploy smart accounts using Solady ERC1271.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/accounts/ERC1271InputGenerator.sol)
/// @author Coinbase (https://github.com/coinbase/smart-wallet/blob/main/src/utils/ERC1271InputGenerator.sol)
///
/// @dev
/// This contract is not meant to ever actually be deployed,
/// only mock deployed and used via a static `eth_call`.
///
/// For a minimal compilation:
/// `solc src/accounts/ERC1271InputGenerator.sol --bin --optimize  --optimize-runs=1 --no-cbor-metadata`.
///
/// May be useful for generating ERC-6492 compliant signatures.
/// Inspired by Ambire's DeploylessUniversalSigValidator
/// (https://github.com/AmbireTech/signature-validator/blob/main/contracts/DeploylessUniversalSigValidator.sol)
contract ERC1271InputGenerator {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Account returned from call to `accountFactory` does not match passed account.
    error ReturnedAddressDoesNotMatchAccount();

    /// @dev The returned hash is less than 32 bytes.
    error InvalidReturnedHash();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                ERC1271 INPUT HASH GENERATOR                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns `bytes32(0), account.replaySafeHash(hash, parentTypeHash, child)`.
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
            let m := mload(0x40)
            // If the account does not exist, deploy it.
            if iszero(extcodesize(account)) {
                if iszero(
                    call(
                        gas(),
                        accountFactory,
                        0,
                        add(factoryCalldata, 0x20),
                        mload(factoryCalldata),
                        m,
                        0x20
                    )
                ) {
                    returndatacopy(m, 0x00, returndatasize())
                    revert(m, returndatasize())
                }
                if iszero(and(gt(returndatasize(), 0x1f), eq(mload(m), account))) {
                    mstore(0x00, 0xf3f7c8da) // `ReturnedAddressDoesNotMatchAccount()`.
                    revert(0x1c, 0x04)
                }
            }
            mstore(0x00, 0xb776324f) // `replaySafeHash(bytes32,bytes32,bytes32)`.
            mstore(0x20, hash)
            mstore(0x40, parentTypehash)
            mstore(0x60, child)
            if iszero(staticcall(gas(), account, 0x1c, 0x64, 0x20, 0x20)) {
                returndatacopy(m, 0x00, returndatasize())
                revert(m, returndatasize())
            }
            if iszero(gt(returndatasize(), 0x1f)) {
                mstore(0x00, 0xfac5869a) // `InvalidReturnedHash()`.
                revert(0x1c, 0x04)
            }
            // The contract bytecode must start with 0, which essentially prefixes the
            // contract with STOP, as the starting byte of the hash may be an invalid opcode.
            mstore(0x00, 0x00)
            return(0x00, 0x40)
        }
    }
}
