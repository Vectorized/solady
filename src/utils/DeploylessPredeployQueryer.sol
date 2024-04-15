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
/// `3860b63d393d516020805190606051833b15607e575b5059926040908285528351938460051b9459523d604087015260005b858103603e578680590390f35b6000828683820101510138908688820151910147875af115607457603f19875903018482890101523d59523d6000593e84016031565b3d6000803e3d6000fd5b816000828193519083479101906040515af11560ad5783815114601f3d111660155763d1f6b81290526004601cfd5b3d81803e3d90fdfe`
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
                        selfbalance(),
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
            let l := mload(targetQueryCalldata)
            let n := shl(5, l)
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
            mstore(add(m, 0x20), l)
            return(m, sub(o, m))
        }
    }
}
