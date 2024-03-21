// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {EIP712} from "../utils/EIP712.sol";
import {SignatureCheckerLib} from "../utils/SignatureCheckerLib.sol";

/// @notice ERC1271 mixin with nested EIP-712 approach.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/accounts/ERC1271.sol)
/// @author Coinbase (https://github.com/coinbase/smart-wallet)
abstract contract ERC1271 is EIP712 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev `keccak256("CoinbaseSmartWalletMessage(bytes32 hash)")`.
    bytes32 internal constant _ERC1271_COINBASE_MESSAGE_TYPEHASH =
        0x9b493d222105fee7df163ab5d57f0bf1ffd2da04dd5fafbe10b54c41c1adc657;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     ERC1271 OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the ERC1271 signer.
    /// Override to return the signer `isValidSignature` checks against.
    function _erc1271Signer() internal view virtual returns (address);

    /// @dev Validates the signature with ERC1271 return,
    /// so that this account can also be used as a signer.
    ///
    /// For maximum widespread compatibility, this will first use Solady's default workflow.
    /// Upon failure, it will try with Coinbase wallet's workflow.
    function isValidSignature(bytes32 hash, bytes calldata signature)
        public
        view
        virtual
        returns (bytes4 result)
    {
        bool success =
            _isValidSignatureSolady(hash, signature) || _isValidSignatureCoinbase(hash, signature);
        /// @solidity memory-safe-assembly
        assembly {
            // `success ? bytes4(keccak256("isValidSignature(bytes32,bytes)")) : 0xffffffff`.
            // We use `0xffffffff` for invalid, in convention with the reference implementation.
            result := shl(224, or(0x1626ba7e, sub(0, iszero(success))))
        }
    }

    /// @dev ERC1271 signature validation (Solady default workflow).
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
    /// For the nested EIP-712 workflow, the final hash will be:
    /// ```
    ///     keccak256(\x19\x01 || DOMAIN_SEP_A ||
    ///         hashStruct(Parent({
    ///             child: hashStruct(originalStruct),
    ///             childHash: keccak256(\x19\x01 || DOMAIN_SEP_B || hashStruct(originalStruct))
    ///         }))
    ///     )
    /// ```
    /// where `||` denotes the concatenation operator for bytes.
    /// The signature will be `r || s || v || PARENT_TYPEHASH || DOMAIN_SEP_B || child`.
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
    /// Of course, if you are a wallet app maker and can update your app's UI at will,
    /// you can choose a more minimalistic signature scheme like
    /// `keccak256(abi.encode(address(this), hash))` instead of all these acrobatics.
    /// All these are just for widespead out-of-the-box compatibility with other wallet apps.
    function _isValidSignatureSolady(bytes32 hash, bytes calldata signature)
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
                    // The child's structHash is already at 0x40.
                    hash := keccak256(0x00, 0x60) // Compute the parent's structHash.
                    break
                }
                // Else, use the `personalSign` workflow.
                // If `signature.length` > 1 word (32 bytes), reduce by 1 word, else set to 0.
                signature.length := mul(gt(signature.length, 0x20), sub(signature.length, 0x20))
                // The `PARENT_TYPEHASH` is already at 0x40.
                mstore(0x60, hash) // Store the `childHash`.
                hash := keccak256(0x40, 0x40) // Compute the parent's structHash.
                mstore(0x60, 0) // Restore the zero pointer.
                break
            }
            mstore(0x40, m) // Restore the free memory pointer.
        }
        return SignatureCheckerLib.isValidSignatureNowCalldata(
            _erc1271Signer(), _hashTypedData(hash), signature
        );
    }

    /// @dev ERC1271 signature validation (Coinbase smart wallet workflow).
    /// See: https://github.com/coinbase/smart-wallet/blob/main/src/ERC1271.sol
    function _isValidSignatureCoinbase(bytes32 hash, bytes calldata signature)
        internal
        view
        virtual
        returns (bool)
    {
        if (signature.length <= 0x5f) return false;
        /// @solidity memory-safe-assembly
        assembly {
            let o := add(signature.offset, calldataload(signature.offset))
            o := add(o, calldataload(add(o, 0x20)))
            signature.length := calldataload(o)
            signature.offset := add(o, 0x20)
        }
        return SignatureCheckerLib.isValidSignatureNowCalldata(
            _erc1271Signer(), replaySafeHash(hash), signature
        );
    }

    /// @dev For Coinbase smart wallet SDK signature generation.
    /// The Coinbase SDK will expect the account to implement this function
    /// and use its result to generate the signature request.
    function replaySafeHash(bytes32 hash) public view virtual returns (bytes32) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, _ERC1271_COINBASE_MESSAGE_TYPEHASH)
            mstore(0x20, hash)
            hash := keccak256(0x00, 0x40)
        }
        return _hashTypedData(hash);
    }
}
