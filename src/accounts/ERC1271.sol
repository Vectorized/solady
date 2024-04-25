// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {EIP712} from "../utils/EIP712.sol";
import {SignatureCheckerLib} from "../utils/SignatureCheckerLib.sol";

/// @notice ERC1271 mixin with nested EIP-712 approach.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/accounts/ERC1271.sol)
abstract contract ERC1271 is EIP712 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev `keccak256("PersonalSign(bytes prefixed)")`.
    bytes32 internal constant _PERSONAL_SIGN_TYPEHASH =
        0x983e65e5148e570cd828ead231ee759a8d7958721a768f93bc4483ba005c32de;

    /// @dev `keccak256("AccountDomain(bytes1 fields,string name,string version,uint256 chainId,address verifyingContract,bytes32 salt,uint256[] extensions)")`.
    bytes32 internal constant _ACCOUNT_DOMAIN_TYPEHASH =
        0xf9397b815e3b748615251a6cf42deb547d35771d98dc90539cd5607ffa5c19a3;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     ERC1271 OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the ERC1271 signer.
    /// Override to return the signer `isValidSignature` checks against.
    function _erc1271Signer() internal view virtual returns (address);

    /// @dev Returns whether the `msg.sender` is considered safe, such
    /// that we don't need to use the nested EIP-712 workflow.
    /// Override to return true for more callers.
    /// See: https://mirror.xyz/curiousapple.eth/pFqAdW2LiJ-6S4sg_u1z08k4vK6BCJ33LcyXpnNb8yU
    function _erc1271CallerIsSafe() internal view virtual returns (bool) {
        // The canonical `MulticallerWithSender` at 0x000000000000D9ECebf3C23529de49815Dac1c4c
        // is known to include the account in the hash to be signed.
        return msg.sender == 0x000000000000D9ECebf3C23529de49815Dac1c4c;
    }

    /// @dev Returns the struct hash of the `eip712Domain()`.
    /// Used in the nested EIP-712 workflow.
    /// We'll refer to the EIP-712 domain as the account domain to make it more end-user-friendly.
    function _erc1271AccountDomainStructHash() internal view virtual returns (bytes32 result) {
        (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        ) = eip712Domain();
        /// @solidity memory-safe-assembly
        assembly {
            // This is essentially `keccak256(abi.encode(_ACCOUNT_DOMAIN_TYPEHASH, ...))`.
            // We'll just compute it on-the-fly as efficiently as we can.
            let m := mload(0x40) // Grab the free memory pointer.
            mstore(m, _ACCOUNT_DOMAIN_TYPEHASH)
            mstore(add(m, 0x20), shl(248, shr(248, fields)))
            mstore(add(m, 0x40), keccak256(add(name, 0x20), mload(name)))
            mstore(add(m, 0x60), keccak256(add(version, 0x20), mload(version)))
            mstore(add(m, 0x80), chainId)
            mstore(add(m, 0xa0), shr(96, shl(96, verifyingContract)))
            mstore(add(m, 0xc0), salt)
            mstore(add(m, 0xe0), keccak256(add(extensions, 0x20), shl(5, mload(extensions))))
            result := keccak256(m, 0x100)
        }
    }

    /// @dev Validates the signature with ERC1271 return,
    /// so that this account can also be used as a signer.
    function isValidSignature(bytes32 hash, bytes calldata signature)
        public
        view
        virtual
        returns (bytes4 result)
    {
        bool success = _erc1271IsValidSignature(hash, signature);
        /// @solidity memory-safe-assembly
        assembly {
            // `success ? bytes4(keccak256("isValidSignature(bytes32,bytes)")) : 0xffffffff`.
            // We use `0xffffffff` for invalid, in convention with the reference implementation.
            result := shl(224, or(0x1626ba7e, sub(0, iszero(success))))
        }
    }

    /// @dev Returns whether the `signature` is valid for the `hash.
    function _erc1271IsValidSignature(bytes32 hash, bytes calldata signature)
        internal
        view
        virtual
        returns (bool)
    {
        return _erc1271IsValidSignatureViaSafeCaller(hash, signature)
            || _erc1271IsValidSignatureViaNestedEIP712(hash, signature)
            || _erc1271IsValidSignatureViaRPC(hash, signature);
    }

    /// @dev Performs the signature validation without nested EIP-712 if the caller is
    /// a safe caller. A safe caller must include the address of this account in the hash.
    function _erc1271IsValidSignatureViaSafeCaller(bytes32 hash, bytes calldata signature)
        internal
        view
        virtual
        returns (bool result)
    {
        if (_erc1271CallerIsSafe()) {
            result =
                SignatureCheckerLib.isValidSignatureNowCalldata(_erc1271Signer(), hash, signature);
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
    ///     keccak256(\x19\x01 || DOMAIN_SEP_B ||
    ///         hashStruct(Parent({
    ///             childHash: keccak256(\x19\x01 || DOMAIN_SEP_B || hashStruct(originalStruct)),
    ///             child: hashStruct(originalStruct),
    ///             accountDomain: hashStruct(eip712Domain())
    ///         }))
    ///     )
    /// ```
    /// where `||` denotes the concatenation operator for bytes.
    /// The order of Parent's fields is important: `childHash` comes before `child`.
    ///
    /// For `accountDomain`, see `_ACCOUNT_DOMAIN_TYPEHASH` and `_erc1271AccountDomainStructHash`.
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
    ///         hashStruct(PersonalSign({
    ///             prefixed: keccak256(bytes(\x19Ethereum Signed Message:\n ||
    ///                 base10(bytes(someString).length) || someString))
    ///         }))
    ///     )
    /// ```
    /// where `||` denotes the concatenation operator for bytes.
    ///
    /// The parent type hash will be `keccak256("PersonalSign(bytes prefixed)")`.
    /// The signature will be `r || s || v`.
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
    function _erc1271IsValidSignatureViaNestedEIP712(bytes32 hash, bytes calldata signature)
        internal
        view
        virtual
        returns (bool result)
    {
        bytes32 accountDomainStructHash = _erc1271AccountDomainStructHash();
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            let o := add(signature.offset, sub(signature.length, 0x60))
            calldatacopy(0x00, o, 0x60) // Copy the `DOMAIN_SEP_B` and child struct hash.
            mstore(0x00, 0x1901) // Store the "\x19\x01" prefix, overwriting 0x00.
            for {} 1 {} {
                // Use the nested EIP-712 workflow if the reconstructed `childHash` matches,
                // and the signature is at least 96 bytes long.
                if iszero(or(xor(keccak256(0x1e, 0x42), hash), lt(signature.length, 0x60))) {
                    // Truncate the `signature.length` by 3 words (96 bytes).
                    signature.length := sub(signature.length, 0x60)
                    mstore(m, calldataload(o)) // Store the `PARENT_TYPEHASH`.
                    mstore(add(m, 0x20), hash) // Store the `childHash`.
                    mstore(add(m, 0x40), mload(0x40)) // Store the child struct hash.
                    mstore(add(m, 0x60), accountDomainStructHash)
                    // We expect that `DOMAIN_SEP_B` would have already include chain ID if needed.
                    // The "\x19\x01" prefix is already at 0x00.
                    // `DOMAIN_SEP_B` is already at 0x20.
                    mstore(0x40, keccak256(m, 0x80)) // Compute and store the parent struct hash.
                    hash := keccak256(0x1e, 0x42)
                    result := 1 // Use `result` to temporarily denote if we will use `DOMAIN_SEP_B`.
                    break
                }
                // Else, use the `personalSign` workflow.
                mstore(0x00, _PERSONAL_SIGN_TYPEHASH)
                mstore(0x20, hash) // Store the `prefixed`.
                hash := keccak256(0x00, 0x40) // Compute the parent struct hash.
                break
            }
            mstore(0x40, m) // Restore the free memory pointer.
        }
        if (!result) hash = _hashTypedData(hash);
        result = SignatureCheckerLib.isValidSignatureNowCalldata(_erc1271Signer(), hash, signature);
    }

    /// @dev Performs the signature validation without nested EIP-712 to allow for easy sign ins.
    /// This function must always return false or revert if called on-chain.
    function _erc1271IsValidSignatureViaRPC(bytes32 hash, bytes calldata signature)
        internal
        view
        virtual
        returns (bool result)
    {
        // Non-zero gasprice is a heuristic to check if a call is on-chain,
        // but we can't fully depend on it because it can be manipulated.
        // See: https://x.com/NoahCitron/status/1580359718341484544
        if (tx.gasprice == 0) {
            /// @solidity memory-safe-assembly
            assembly {
                let gasBurnHash := 0x31d8f1c26729207294 // uint72(bytes9(keccak256("gasBurnHash"))).
                let m := mload(0x40) // Cache the free memory pointer.
                mstore(gasprice(), 0x1626ba7e) // `isValidSignature(bytes32,bytes)`.
                mstore(0x20, gasBurnHash)
                mstore(0x40, 0x40)
                let gasToBurn := or(add(0xffff, gaslimit()), gaslimit())
                // Burns gas computationally efficiently. Also, requires that `gas > gasToBurn`.
                if or(eq(hash, gasBurnHash), lt(gas(), gasToBurn)) { invalid() }
                // Make a call to this with `gasBurnHash`, efficiently burning the gas provided.
                // No valid transaction can consume more than the gaslimit.
                // See: https://ethereum.github.io/yellowpaper/paper.pdf
                // Most RPCs perform calls with a gas budget greater than the gaslimit.
                pop(staticcall(gasToBurn, address(), 0x1c, 0x64, gasprice(), gasprice()))
                mstore(0x40, m) // Restore the free memory pointer.
            }
            result =
                SignatureCheckerLib.isValidSignatureNowCalldata(_erc1271Signer(), hash, signature);
        }
    }
}
