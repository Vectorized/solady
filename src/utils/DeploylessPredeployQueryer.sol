// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Deployless queryer for predeploys.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/DeploylessPredeployQueryer.sol)
///
/// @dev
/// This contract is not meant to ever actually be deployed,
/// only mock deployed and used via a static `eth_call`.
///
/// Creation code (hex-encoded):
/// `608060405261019d80380380610014816100f6565b9283398101906080818303126100f1578051602080830151909291906001600160401b03908181116100f1578561004c918501610131565b9260408101519560608201519283116100f157859261006b9201610131565b94604051958691843b156100b3575b50505050600091389184825192019034905af1156100a9578082523d908201523d6000604083013e3d60600190f35b503d6000823e3d90fd5b8460011883528382519201903d905af1156100e757808451036100d9578284388061007a565b63d1f6b8126000526004601cfd5b833d6000823e3d90fd5b600080fd5b6040519190601f01601f191682016001600160401b0381118382101761011b57604052565b634e487b7160e01b600052604160045260246000fd5b919080601f840112156100f15782516001600160401b03811161011b57602090610163601f8201601f191683016100f6565b928184528282870101116100f15760005b81811061018957508260009394955001015290565b858101830151848201840152820161017456fe`
/// Compiled via:
/// `solc src/utils/DeploylessPredeployQueryer.sol --bin --optimize --via-ir --optimize-runs=1 --no-cbor-metadata --evm-version=london`
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
