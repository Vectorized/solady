// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ECDSA.sol";

/// @notice Signature verification helper that supports both ECDSA signatures from EOAs
/// and ERC1271 signatures from smart contract wallets like Argent and Gnosis safe.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SignatureCheckerLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/SignatureChecker.sol)
library SignatureCheckerLib {
    /// @dev Returns whether `signature` is valid for `signer` and `hash`.
    /// If `signer` is a smart contract, the signature is validated with ERC1271.
    /// Otherwise, the signature is validated with `ECDSA.recover`.
    ///
    /// Note: unlike ECDSA signatures, contract signatures are revocable.
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes calldata signature
    ) internal view returns (bool isValid) {
        if (signer == address(0)) return false;

        if (ECDSA.recover(hash, signature) == signer) return true;

        /// @solidity memory-safe-assembly
        assembly {
            // Load the free memory pointer.
            // Simply using the free memory usually costs less if many slots are needed.
            let m := mload(0x40)

            // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
            let f := shl(224, 0x1626ba7e)
            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(m, f)
            mstore(add(m, 0x04), hash)
            mstore(add(m, 0x24), 0x40) // The offset of the `signature` in the calldata.
            // Copy the `signature` and its length over.
            calldatacopy(add(m, 0x44), sub(signature.offset, 0x20), 0x61)

            isValid := and(
                and(
                    // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                    eq(mload(0x00), f),
                    // Whether the returndata is exactly 0x20 bytes (1 word) long.
                    eq(returndatasize(), 0x20)
                ),
                // Whether the staticcall does not revert.
                // This must be placed at the end of the `and` clause,
                // as the arguments are evaluated from right to left.
                staticcall(
                    gas(), // Remaining gas.
                    signer, // The `signer` address.
                    m, // Offset of calldata in memory.
                    0xa5, // Length of calldata in memory.
                    0x00, // Offset of returndata.
                    0x20 // Length of returndata to write.
                )
            )
        }
    }

    /// @dev Returns whether the signature (`r`, `vs`) is valid for `signer` and `hash`.
    /// If `signer` is a smart contract, the signature is validated with ERC1271.
    /// Otherwise, the signature is validated with `ECDSA.recover`.
    ///
    /// Note: unlike ECDSA signatures, contract signatures are revocable.
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal view returns (bool isValid) {
        if (signer == address(0)) return false;

        if (ECDSA.recover(hash, r, vs) == signer) return true;

        /// @solidity memory-safe-assembly
        assembly {
            // Load the free memory pointer.
            // Simply using the free memory usually costs less if many slots are needed.
            let m := mload(0x40)

            // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
            let f := shl(224, 0x1626ba7e)
            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
            mstore(add(m, 0x04), hash)
            mstore(add(m, 0x24), 0x40) // The offset of the `signature` in the calldata.
            mstore(add(m, 0x44), 65) // Store the length of the signature.
            mstore(add(m, 0x64), r) // Store `r` of the signature.
            mstore(add(m, 0x84), shr(1, shl(1, vs))) // Store `s` of the signature.
            mstore8(add(m, 0xa4), add(shr(255, vs), 27)) // Store `v` of the signature.

            isValid := and(
                and(
                    // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                    eq(mload(0x00), f),
                    // Whether the returndata is exactly 0x20 bytes (1 word) long.
                    eq(returndatasize(), 0x20)
                ),
                // Whether the staticcall does not revert.
                // This must be placed at the end of the `and` clause,
                // as the arguments are evaluated from right to left.
                staticcall(
                    gas(), // Remaining gas.
                    signer, // The `signer` address.
                    m, // Offset of calldata in memory.
                    0xa5, // Length of calldata in memory.
                    0x00, // Offset of returndata.
                    0x20 // Length of returndata to write.
                )
            )
        }
    }

    /// @dev Returns whether the signature (`v`, `r`, `s`) is valid for `signer` and `hash`.
    /// If `signer` is a smart contract, the signature is validated with ERC1271.
    /// Otherwise, the signature is validated with `ECDSA.recover`.
    ///
    /// Note: unlike ECDSA signatures, contract signatures are revocable.
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool isValid) {
        if (signer == address(0)) return false;

        if (ECDSA.recover(hash, v, r, s) == signer) return true;

        /// @solidity memory-safe-assembly
        assembly {
            // Load the free memory pointer.
            // Simply using the free memory usually costs less if many slots are needed.
            let m := mload(0x40)

            // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
            let f := shl(224, 0x1626ba7e)
            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
            mstore(add(m, 0x04), hash)
            mstore(add(m, 0x24), 0x40) // The offset of the `signature` in the calldata.
            mstore(add(m, 0x44), 65) // Store the length of the signature.
            mstore(add(m, 0x64), r) // Store `r` of the signature.
            mstore(add(m, 0x84), s) // Store `s` of the signature.
            mstore8(add(m, 0xa4), v) // Store `v` of the signature.

            isValid := and(
                and(
                    // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                    eq(mload(0x00), f),
                    // Whether the returndata is exactly 0x20 bytes (1 word) long.
                    eq(returndatasize(), 0x20)
                ),
                // Whether the staticcall does not revert.
                // This must be placed at the end of the `and` clause,
                // as the arguments are evaluated from right to left.
                staticcall(
                    gas(), // Remaining gas.
                    signer, // The `signer` address.
                    m, // Offset of calldata in memory.
                    0xa5, // Length of calldata in memory.
                    0x00, // Offset of returndata.
                    0x20 // Length of returndata to write.
                )
            )
        }
    }
}
