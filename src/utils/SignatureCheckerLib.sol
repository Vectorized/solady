// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Signature verification helper that supports both ECDSA signatures from EOAs
/// and ERC1271 signatures from smart contract wallets like Argent and Gnosis safe.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SignatureCheckerLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/SignatureChecker.sol)
///
/// @dev Note: Unlike ECDSA signatures, contract signatures are revocable.
library SignatureCheckerLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The number which `s` must not exceed in order for
    /// the signature to be non-malleable.
    bytes32 private constant _MALLEABILITY_THRESHOLD =
        0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               SIGNATURE CHECKING OPERATIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns whether `signature` is valid for `signer` and `hash`.
    /// If `signer` is a smart contract, the signature is validated with ERC1271.
    /// Otherwise, the signature is validated with `ECDSA.recover`.
    function isValidSignatureNow(address signer, bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits of `signer` in case they are dirty.
            for { signer := shr(96, shl(96, signer)) } signer {} {
                // Load the free memory pointer.
                // Simply using the free memory usually costs less if many slots are needed.
                let m := mload(0x40)

                let signatureLength := mload(signature)
                // If the signature is exactly 65 bytes in length.
                if iszero(xor(signatureLength, 65)) {
                    // Copy `r` and `s`.
                    mstore(add(m, 0x40), mload(add(signature, 0x20))) // `r`.
                    let s := mload(add(signature, 0x40))
                    mstore(add(m, 0x60), s)
                    // If `s` in lower half order, such that the signature is not malleable.
                    if iszero(gt(s, _MALLEABILITY_THRESHOLD)) {
                        mstore(m, hash)
                        // Compute `v` and store it in the memory.
                        mstore(add(m, 0x20), byte(0, mload(add(signature, 0x60))))
                        pop(
                            staticcall(
                                gas(), // Amount of gas left for the transaction.
                                0x01, // Address of `ecrecover`.
                                m, // Start of input.
                                0x80, // Size of input.
                                m, // Start of output.
                                0x20 // Size of output.
                            )
                        )
                        // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                        if mul(eq(mload(m), signer), returndatasize()) {
                            isValid := 1
                            break
                        }
                    }
                }

                // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
                let f := shl(224, 0x1626ba7e)
                // Write the abi-encoded calldata into memory, beginning with the function selector.
                mstore(m, f)
                mstore(add(m, 0x04), hash)
                mstore(add(m, 0x24), 0x40) // The offset of the `signature` in the calldata.
                {
                    let j := add(m, 0x44)
                    mstore(j, signatureLength) // The signature length.
                    // Copy the `signature` over.
                    for { let i := 0 } 1 {} {
                        i := add(i, 0x20)
                        mstore(add(j, i), mload(add(signature, i)))
                        if iszero(lt(i, signatureLength)) { break }
                    }
                }

                // forgefmt: disable-next-item
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
                        add(signatureLength, 0x64), // Length of calldata in memory.
                        0x00, // Offset of returndata.
                        0x20 // Length of returndata to write.
                    )
                )
                break
            }
        }
    }

    /// @dev Returns whether `signature` is valid for `signer` and `hash`.
    /// If `signer` is a smart contract, the signature is validated with ERC1271.
    /// Otherwise, the signature is validated with `ECDSA.recover`.
    function isValidSignatureNowCalldata(address signer, bytes32 hash, bytes calldata signature)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits of `signer` in case they are dirty.
            for { signer := shr(96, shl(96, signer)) } signer {} {
                // Load the free memory pointer.
                // Simply using the free memory usually costs less if many slots are needed.
                let m := mload(0x40)

                // If the signature is exactly 65 bytes in length.
                if iszero(xor(signature.length, 65)) {
                    // Directly copy `r` and `s` from the calldata.
                    calldatacopy(add(m, 0x40), signature.offset, 0x40)
                    // If `s` in lower half order, such that the signature is not malleable.
                    if iszero(gt(mload(add(m, 0x60)), _MALLEABILITY_THRESHOLD)) {
                        mstore(m, hash)
                        // Compute `v` and store it in the memory.
                        mstore(add(m, 0x20), byte(0, calldataload(add(signature.offset, 0x40))))
                        pop(
                            staticcall(
                                gas(), // Amount of gas left for the transaction.
                                0x01, // Address of `ecrecover`.
                                m, // Start of input.
                                0x80, // Size of input.
                                m, // Start of output.
                                0x20 // Size of output.
                            )
                        )
                        // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                        if mul(eq(mload(m), signer), returndatasize()) {
                            isValid := 1
                            break
                        }
                    }
                }

                // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
                let f := shl(224, 0x1626ba7e)
                // Write the abi-encoded calldata into memory, beginning with the function selector.
                mstore(m, f)
                mstore(add(m, 0x04), hash)
                mstore(add(m, 0x24), 0x40) // The offset of the `signature` in the calldata.
                mstore(add(m, 0x44), signature.length) // The signature length
                // Copy the `signature` over.
                calldatacopy(add(m, 0x64), signature.offset, signature.length)

                // forgefmt: disable-next-item
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
                        add(signature.length, 0x64), // Length of calldata in memory.
                        0x00, // Offset of returndata.
                        0x20 // Length of returndata to write.
                    )
                )
                break
            }
        }
    }

    /// @dev Returns whether the signature (`r`, `vs`) is valid for `signer` and `hash`.
    /// If `signer` is a smart contract, the signature is validated with ERC1271.
    /// Otherwise, the signature is validated with `ECDSA.recover`.
    function isValidSignatureNow(address signer, bytes32 hash, bytes32 r, bytes32 vs)
        internal
        view
        returns (bool isValid)
    {
        uint8 v;
        bytes32 s;
        /// @solidity memory-safe-assembly
        assembly {
            s := shr(1, shl(1, vs))
            v := add(shr(255, vs), 27)
        }
        isValid = isValidSignatureNow(signer, hash, v, r, s);
    }

    /// @dev Returns whether the signature (`v`, `r`, `s`) is valid for `signer` and `hash`.
    /// If `signer` is a smart contract, the signature is validated with ERC1271.
    /// Otherwise, the signature is validated with `ECDSA.recover`.
    function isValidSignatureNow(address signer, bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits of `signer` in case they are dirty.
            for { signer := shr(96, shl(96, signer)) } signer {} {
                // Load the free memory pointer.
                // Simply using the free memory usually costs less if many slots are needed.
                let m := mload(0x40)

                // Clean the excess bits of `v` in case they are dirty.
                v := and(v, 0xff)
                // If `s` in lower half order, such that the signature is not malleable.
                if iszero(gt(s, _MALLEABILITY_THRESHOLD)) {
                    mstore(m, hash)
                    mstore(add(m, 0x20), v)
                    mstore(add(m, 0x40), r)
                    mstore(add(m, 0x60), s)
                    pop(
                        staticcall(
                            gas(), // Amount of gas left for the transaction.
                            0x01, // Address of `ecrecover`.
                            m, // Start of input.
                            0x80, // Size of input.
                            m, // Start of output.
                            0x20 // Size of output.
                        )
                    )
                    // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                    if mul(eq(mload(m), signer), returndatasize()) {
                        isValid := 1
                        break
                    }
                }

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

                // forgefmt: disable-next-item
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
                break
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     ERC1271 OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns whether `signature` is valid for `hash`
    /// for an ERC1271 `signer` contract.
    function isValidERC1271SignatureNow(address signer, bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Load the free memory pointer.
            // Simply using the free memory usually costs less if many slots are needed.
            let m := mload(0x40)

            let signatureLength := mload(signature)

            // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
            let f := shl(224, 0x1626ba7e)
            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(m, f)
            mstore(add(m, 0x04), hash)
            mstore(add(m, 0x24), 0x40) // The offset of the `signature` in the calldata.
            {
                let j := add(m, 0x44)
                mstore(j, signatureLength) // The signature length.
                // Copy the `signature` over.
                for { let i := 0 } 1 {} {
                    i := add(i, 0x20)
                    mstore(add(j, i), mload(add(signature, i)))
                    if iszero(lt(i, signatureLength)) { break }
                }
            }

            // forgefmt: disable-next-item
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
                    add(signatureLength, 0x64), // Length of calldata in memory.
                    0x00, // Offset of returndata.
                    0x20 // Length of returndata to write.
                )
            )
        }
    }

    /// @dev Returns whether `signature` is valid for `hash`
    /// for an ERC1271 `signer` contract.
    function isValidERC1271SignatureNowCalldata(
        address signer,
        bytes32 hash,
        bytes calldata signature
    ) internal view returns (bool isValid) {
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
            mstore(add(m, 0x44), signature.length) // The signature length
            // Copy the `signature` over.
            calldatacopy(add(m, 0x64), signature.offset, signature.length)

            // forgefmt: disable-next-item
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
                    add(signature.length, 0x64), // Length of calldata in memory.
                    0x00, // Offset of returndata.
                    0x20 // Length of returndata to write.
                )
            )
        }
    }

    /// @dev Returns whether the signature (`r`, `vs`) is valid for `hash`
    /// for an ERC1271 `signer` contract.
    function isValidERC1271SignatureNow(address signer, bytes32 hash, bytes32 r, bytes32 vs)
        internal
        view
        returns (bool isValid)
    {
        uint8 v;
        bytes32 s;
        /// @solidity memory-safe-assembly
        assembly {
            s := shr(1, shl(1, vs))
            v := add(shr(255, vs), 27)
        }
        isValid = isValidERC1271SignatureNow(signer, hash, v, r, s);
    }

    /// @dev Returns whether the signature (`v`, `r`, `s`) is valid for `hash`
    /// for an ERC1271 `signer` contract.
    function isValidERC1271SignatureNow(address signer, bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        internal
        view
        returns (bool isValid)
    {
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

            // forgefmt: disable-next-item
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

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   EMPTY CALLDATA HELPERS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns an empty calldata bytes.
    function emptySignature() internal pure returns (bytes calldata signature) {
        /// @solidity memory-safe-assembly
        assembly {
            signature.length := 0
        }
    }
}
