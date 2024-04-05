// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Deployless queryer for predeploys.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/DeploylessPredeployQueryer.sol)
/// @author Wilson Cusack (Coinbase)
/// (https://github.com/coinbase/smart-wallet/blob/main/src/utils/ERC1271InputGenerator.sol)
/// (https://github.com/wilsoncusack/scw-tx/blob/main/utils/ERC1271.ts)
///
/// @dev
/// This contract is not meant to ever actually be deployed,
/// only mock deployed and used via a static `eth_call`.
///
/// Creation code (hex-encoded):
/// `3860ec3d393d516020805191606051813b1560b4575b50601f9291921992603f9380603f380116938051918260051b90604097604083890101966000906000955b858703605e578a808b8b8b81845260018060fb1b0316908301520390f35b90919293949598838c838b8d820101510138918c820151910147875af11560aa578486918c8e8d603f1983850301920101523d81523d868c83013e3d0101169888019594939291906040565b8a843d90823e3d90fd5b8260008281935190833d9101906040515af11560e35781815114601f3d111660155763d1f6b81290526004601cfd5b3d81803e3d90fdfe`
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

    /// @dev The code of the deployed contract can be `abi.decoded` into an array of bytes,
    /// where each entry can be `abi.decoded` into the required variables.
    ///
    /// For example, if `targetQueryCalldata`'s 0th call is expected to return a `uint256`,
    /// you will use `abi.decode(abi.decode(deployed.code, (bytes[]))[0], (uint256))` to
    /// get the returned `uint256`.
    constructor(
        address target,
        bytes[] memory targetQueryCalldata,
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
            let n := shl(5, mload(targetQueryCalldata))
            let r := add(m, 0x40)
            let o := add(r, n)
            for { let i := 0 } iszero(eq(i, n)) { i := add(0x20, i) } {
                let j := mload(add(add(targetQueryCalldata, 0x20), i))
                if iszero(
                    call(gas(), target, selfbalance(), add(j, 0x20), mload(j), codesize(), 0x00)
                ) {
                    returndatacopy(m, 0x00, returndatasize())
                    revert(m, returndatasize())
                }
                mstore(add(r, i), sub(o, r))
                mstore(o, returndatasize())
                returndatacopy(add(o, 0x20), 0x00, returndatasize())
                o := and(add(add(o, returndatasize()), 0x3f), not(0x1f))
            }
            mstore(m, 0x20)
            mstore(add(m, 0x20), shr(5, n))
            return(m, sub(o, m))
        }
    }
}
