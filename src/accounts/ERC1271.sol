// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {EIP712} from "../utils/EIP712.sol";
import {SignatureCheckerLib} from "../utils/SignatureCheckerLib.sol";

/// @notice ERC1271 mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/accounts/ERC1271.sol)
abstract contract ERC1271 is EIP712 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     ERC1271 OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the ERC1271 signer.
    /// Override to return the signer `isValidSignature` checks against.
    function _erc1271Signer() internal view virtual returns (address);

    /// @dev Validates the signature with ERC1271 return,
    /// so that this account can also be used as a signer.
    ///
    /// This implementation uses ECDSA recovery. It also uses a nested EIP-712 approach to
    /// prevent signature replays when a single EOA owns multiple smart contract accounts,
    /// while still enabling wallet UIs (e.g. Metamask) to show the EIP-712 values.
    ///
    /// For the nested EIP-712 workflow, the final hash will be:
    /// ```
    ///     keccak256(\x19\x01 || DOMAIN_SEP_A ||
    ///         hashStruct(Parent({
    ///             childHash: keccak256(\x19\x01 || DOMAIN_SEP_B || hashStruct(originalStruct)),
    ///             child: hashStruct(originalStruct)
    ///         }))
    ///     )
    /// ```
    /// where `||` denotes the concatenation operator for bytes.
    /// The signature will be `r || s || v || PARENT_TYPEHASH || DOMAIN_SEP_B || child`.
    ///
    /// The `DOMAIN_SEP_B` and `child` will be used to verify if `childHash` is indeed correct.
    ///
    /// For the `personal_sign` workflow, the final hash will be:
    /// ```
    ///     keccak256(\x19\x01 || DOMAIN_SEP_A ||
    ///         hashStruct(Parent({
    ///             childHash: personalSign(someBytes)
    ///         }))
    ///     )
    /// ```
    /// where `||` denotes the concatenation operator for bytes.
    /// The signature will be `r || s || v || PARENT_TYPEHASH || bytes32(0) || bytes32(anything)`.
    ///
    /// For demo and typescript code, see:
    /// https://github.com/junomonster/nested-eip-712
    ///
    /// The `hash` parameter is the `childHash`.
    function isValidSignature(bytes32 hash, bytes calldata signature)
        public
        view
        virtual
        returns (bytes4 result)
    {
        bool success;
        if (signature.length >= 0x60) {
            uint256 childHashMismatch;
            /// @solidity memory-safe-assembly
            assembly {
                // Truncate the `signature.length` by 3 words (96 bytes).
                signature.length := sub(signature.length, 0x60)
                let o := add(signature.offset, signature.length)
                for {} 1 {} {
                    mstore(0x00, calldataload(o)) // Store the `PARENT_TYPEHASH`.
                    mstore(0x20, hash) // Store the `childHash`.
                    let domainSepB := calldataload(add(o, 0x20))
                    // `personal_sign` workflow.
                    if iszero(domainSepB) {
                        hash := keccak256(0x00, 0x40) // Compute the parent's structHash.
                        break
                    }
                    let m := mload(0x40) // Cache the free memory pointer.
                    let childHash := hash
                    mstore(0x40, calldataload(add(o, 0x40))) // Store the child's structHash.
                    hash := keccak256(0x00, 0x60) // Compute the parent's structHash.
                    mstore(0x00, 0x1901) // Store the "\x19\x01" prefix.
                    mstore(0x20, domainSepB) // Store the `DOMAIN_SEP_B`
                    // The child's structHash is already at 0x40.
                    childHashMismatch := xor(keccak256(0x1e, 0x42), childHash)
                    mstore(0x40, m) // Restore the free memory pointer.
                    break
                }
            }
            if (childHashMismatch == 0) {
                success = SignatureCheckerLib.isValidSignatureNowCalldata(
                    _erc1271Signer(), _hashTypedData(hash), signature
                );
            }
        }
        /// @solidity memory-safe-assembly
        assembly {
            // `success ? bytes4(keccak256("isValidSignature(bytes32,bytes)")) : 0xffffffff`.
            result := shl(224, or(0x1626ba7e, sub(0, iszero(success))))
        }
    }
}
