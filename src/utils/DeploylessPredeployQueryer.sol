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
/// `38607d3d393d5160208051606051833b156045575b506000928391389184825192019034905af115603c578082523d90523d8160403e3d60600190f35b503d81803e3d90fd5b8260008281935190833d9101906040515af11560745783815114601f3d111660145763d1f6b81290526004601cfd5b3d81803e3d90fdfe`
/// See: https://gist.github.com/Vectorized/f77fce00a03dfa99aee526d2a77fd2aa
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
                if iszero(and(gt(returndatasize(), 0x1f), eq(mload(m), target))) {
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
