// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {EIP712} from "../utils/EIP712.sol";
import {SignatureCheckerLib} from "../utils/SignatureCheckerLib.sol";

/// @notice ERC1271 mixin with nested EIP-712 approach.
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
    /// For maximum widespread compatibility, it will first use Solady's nested EIP-712 workflow.
    /// Upon failure, it will try with the RPC workflow intended only for offchain calls.
    function isValidSignature(bytes32 hash, bytes calldata signature)
        public
        view
        virtual
        returns (bytes4 result)
    {
        bool success = _isValidSignatureViaNestedEIP712(hash, signature)
            || _isValidSignatureViaRPC(hash, signature);
        /// @solidity memory-safe-assembly
        assembly {
            // `success ? bytes4(keccak256("isValidSignature(bytes32,bytes)")) : 0xffffffff`.
            // We use `0xffffffff` for invalid, in convention with the reference implementation.
            result := shl(224, or(0x1626ba7e, sub(0, iszero(success))))
        }
    }

    /// @dev ERC1271 signature validation (Nested EIP-712 workflow).
    ///
    /// This implementation uses ECDSA recovery. It also uses a nested EIP-712 approach to
    /// prevent signature replays when a single EOA owns multiple smart contract accounts,
    /// while still enabling wallet UIs (e.g. Metamask) to show the EIP-712 values.
    ///
    /// The `hash` parameter to this method is the `childHash`.
    /// __________________________________________________________________________________________
    ///
    /// Glossary:
    ///
    /// - `DOMAIN_SEP_B`: The domain separator of the `childHash`.
    ///   Provided by the front end. Intended to be the domain separator of the contract
    ///   that will call `isValidSignature` on this account.
    ///
    /// - `DOMAIN_SEP_A`: The domain separator of this account.
    ///   See: `EIP712._domainSeparator()`.
    ///
    /// - `Parent`: The parent struct type.
    ///   To be defined by the front end, such that `child` can be visible via EIP-712.
    /// __________________________________________________________________________________________
    ///
    /// For the default nested EIP-712 workflow, the final hash will be:
    /// ```
    ///     keccak256(\x19\x01 || DOMAIN_SEP_A ||
    ///         hashStruct(Parent({
    ///             childHash: keccak256(\x19\x01 || DOMAIN_SEP_B || hashStruct(originalStruct)),
    ///             child: hashStruct(originalStruct)
    ///         }))
    ///     )
    /// ```
    /// where `||` denotes the concatenation operator for bytes.
    /// The order of Parent's fields is important: `childHash` comes before `child`.
    ///
    /// The signature will be `r || s || v || PARENT_TYPEHASH || DOMAIN_SEP_B || child`,
    /// where `child` is the bytes32 struct hash of the original struct.
    ///
    /// The `DOMAIN_SEP_B` and `child` will be used to verify if `childHash` is indeed correct.
    /// __________________________________________________________________________________________
    ///
    /// For the `personalSign` workflow, the final hash will be:
    /// ```
    ///     keccak256(\x19\x01 || DOMAIN_SEP_A ||
    ///         hashStruct(Parent({
    ///             childHash: keccak256(\x19Ethereum Signed Message:\n ||
    ///                 base10(bytes(someString).length) || someString)
    ///         }))
    ///     )
    /// ```
    /// where `||` denotes the concatenation operator for bytes.
    /// The signature will be `r || s || v || PARENT_TYPEHASH`.
    /// __________________________________________________________________________________________
    ///
    /// For demo and typescript code, see:
    /// - https://github.com/junomonster/nested-eip-712
    /// - https://github.com/frangio/eip712-wrapper-for-eip1271
    ///
    /// Their nomenclature may differ from ours, although the high-level idea is similar.
    ///
    /// Of course, if you are a wallet app maker and can update your app's UI at will,
    /// you can choose a more minimalistic signature scheme like
    /// `keccak256(abi.encode(address(this), hash))` instead of all these acrobatics.
    /// All these are just for widespead out-of-the-box compatibility with other wallet apps.
    function _isValidSignatureViaNestedEIP712(bytes32 hash, bytes calldata signature)
        internal
        view
        virtual
        returns (bool)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            let o := add(signature.offset, sub(signature.length, 0x60))
            calldatacopy(0x00, o, 0x60) // Copy the `DOMAIN_SEP_B` and child's structHash.
            mstore(0x00, 0x1901) // Store the "\x19\x01" prefix, overwriting 0x00.
            for {} 1 {} {
                // Use the nested EIP-712 workflow if the reconstructed `childHash` matches,
                // and the signature is at least 96 bytes long.
                if iszero(or(xor(keccak256(0x1e, 0x42), hash), lt(signature.length, 0x60))) {
                    // Truncate the `signature.length` by 3 words (96 bytes).
                    signature.length := sub(signature.length, 0x60)
                    mstore(0x00, calldataload(o)) // Store the `PARENT_TYPEHASH`.
                    mstore(0x20, hash) // Store the `childHash`.
                    // The `child` struct hash is already at 0x40.
                    hash := keccak256(0x00, 0x60) // Compute the `parent` struct hash.
                    break
                }
                // Else, use the `personalSign` workflow.
                // If `signature.length` > 1 word (32 bytes), reduce by 1 word, else set to 0.
                signature.length := mul(gt(signature.length, 0x20), sub(signature.length, 0x20))
                // The `PARENT_TYPEHASH` is already at 0x40.
                mstore(0x60, hash) // Store the `childHash`.
                hash := keccak256(0x40, 0x40) // Compute the `parent` struct hash.
                mstore(0x60, 0) // Restore the zero pointer.
                break
            }
            mstore(0x40, m) // Restore the free memory pointer.
        }
        return SignatureCheckerLib.isValidSignatureNowCalldata(
            _erc1271Signer(), _hashTypedData(hash), signature
        );
    }

    /// @dev Performs the signature validation without nested EIP-712 to allow for easy sign ins.
    /// This function must always return false or revert if called on-chain.
    function _isValidSignatureViaRPC(bytes32 hash, bytes calldata signature)
        internal
        view
        virtual
        returns (bool)
    {
        // Non-zero gasprice is a heuristic to check if a call is on-chain,
        // but we can't fully depend on it because it can be manipulated.
        // See: https://x.com/NoahCitron/status/1580359718341484544
        if (tx.gasprice != 0) return false;
        /// @solidity memory-safe-assembly
        assembly {
            let gasBurnHash := 0x31d8f1c26729207294 // uint72(bytes9(keccak256("gasBurnHash"))).
            if eq(hash, gasBurnHash) { invalid() } // Burns gas computationally efficiently.
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x00, 0x1626ba7e) // `isValidSignature(bytes32,bytes)`.
            mstore(0x20, gasBurnHash)
            mstore(0x40, 0x40)
            // Make a call to this with `gasBurnHash`, efficiently burning the gas provided.
            // No valid transaction can consume more than the gaslimit.
            // See: https://ethereum.github.io/yellowpaper/paper.pdf
            // Most RPCs perform calls with a gas budget greater than the gaslimit.
            pop(staticcall(add(100000, gaslimit()), address(), 0x1c, 0x64, 0x00, 0x00))
            mstore(0x40, m) // Restore the free memory pointer.
        }
        return SignatureCheckerLib.isValidSignatureNowCalldata(_erc1271Signer(), hash, signature);
    }
}
