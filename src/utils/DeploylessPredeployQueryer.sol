// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Deployless queryer for predeploys.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/DeploylessPredeployQueryer.sol)
///
/// @dev
/// This contract is not meant to ever actually be deployed,
/// only mock deployed and used via a static `eth_call`.
///
/// For a minimal bytecode compilation:
/// `solc src/utils/DeploylessPredeployQueryer.sol --bin --optimize --via-ir --optimize-runs=1 --no-cbor-metadata --evm-version=paris`.
///
/// May be useful for generating ERC-6492 compliant signatures.
/// Inspired by Ambire's DeploylessUniversalSigValidator
/// (https://github.com/AmbireTech/signature-validator/blob/main/contracts/DeploylessUniversalSigValidator.sol)
contract DeploylessPredeployQueryer {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The returned address by the factory does not match the provided address.
    error ReturnedAddressMismatch();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CONSTRUCTOR                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The code of the deployed contract can be `abi.decoded` into bytes,
    /// which can be `abi.decoded` into the required variables.
    ///
    /// For example, if `targetQueryCalldata` is expected to return a `uint256`,
    /// you will use `abi.decode(abi.decode(deployed.code, (bytes)), (uint256))` to
    /// get the returned `uint256`.
    constructor(
        address target,
        bytes memory targetQueryCalldata,
        address factory,
        bytes memory factoryCalldata
    ) payable {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            // If the target does not exist, deploy it.
            if iszero(extcodesize(target)) {
                mstore(m, xor(1, target))
                if iszero(
                    call(
                        gas(),
                        factory,
                        returndatasize(),
                        add(factoryCalldata, 0x20),
                        mload(factoryCalldata),
                        m,
                        0x20
                    )
                ) {
                    returndatacopy(m, 0x00, returndatasize())
                    revert(m, returndatasize())
                }
                if iszero(eq(mload(m), target)) {
                    mstore(0x00, 0xd1f6b812) // `ReturnedAddressMismatch()`.
                    revert(0x1c, 0x04)
                }
            }
            if iszero(
                call(
                    gas(),
                    target,
                    callvalue(),
                    add(targetQueryCalldata, 0x20),
                    mload(targetQueryCalldata),
                    codesize(),
                    0x00
                )
            ) {
                returndatacopy(m, 0x00, returndatasize())
                revert(m, returndatasize())
            }
            mstore(m, 0x20)
            mstore(add(m, 0x20), returndatasize())
            returndatacopy(add(m, 0x40), 0x00, returndatasize())
            return(m, add(0x60, returndatasize()))
        }
    }
}
