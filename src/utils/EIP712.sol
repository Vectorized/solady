// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Contract for EIP-712 typed structured data hashing and signing.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/EIP712.sol)
/// @author Modified from Solbase (https://github.com/Sol-DAO/solbase/blob/main/src/utils/EIP712.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/EIP712.sol)
abstract contract EIP712 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   OPERATIONS TO OVERRIDE                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Please override this function to return the keccak256 of the domain name.
    /// ```
    ///     function _domainNameHash() internal pure override returns (bytes32) {
    ///         return keccak256(bytes("Solady"));
    ///     }
    /// ```
    function _domainNameHash() internal pure virtual returns (bytes32);

    /// @dev Please override this function to return the keccak256 of the domain version.
    /// ```
    ///     function _domainVersionHash() internal pure override returns (bytes32) {
    ///         return keccak256(bytes("1"));
    ///     }
    /// ```
    function _domainVersionHash() internal pure virtual returns (bytes32);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     HASHING OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the EIP-712 domain separator.
    function _domainSeparator() internal view returns (bytes32 separator) {
        bytes32 domainNameHash = _domainNameHash();
        bytes32 domainVersionHash = _domainVersionHash();
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Load the free memory pointer.
            // Store the domain type hash.
            // `keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")`.
            mstore(m, 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f)
            mstore(add(m, 0x20), domainNameHash)
            mstore(add(m, 0x40), domainVersionHash)
            mstore(add(m, 0x60), chainid())
            mstore(add(m, 0x80), address())
            separator := keccak256(m, 0xa0)
        }
    }

    /// @dev Returns the hash of the fully encoded EIP-712 message for this domain,
    /// given `structHash`, as defined in
    /// https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct.
    ///
    /// The hash can be used together with {ECDSA-recover} to obtain the signer of a message:
    /// ```
    ///     bytes32 digest = _hashTypedData(keccak256(abi.encode(
    ///         keccak256("Mail(address to,string contents)"),
    ///         mailTo,
    ///         keccak256(bytes(mailContents))
    ///     )));
    ///     address signer = ECDSA.recover(digest, signature);
    /// ```
    function _hashTypedData(bytes32 structHash) internal view returns (bytes32 digest) {
        bytes32 domainNameHash = _domainNameHash();
        bytes32 domainVersionHash = _domainVersionHash();
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Load the free memory pointer.
            // Compute the domain type hash.
            // `keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")`.
            mstore(m, 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f)
            mstore(add(m, 0x20), domainNameHash)
            mstore(add(m, 0x40), domainVersionHash)
            mstore(add(m, 0x60), chainid())
            mstore(add(m, 0x80), address())
            // Compute the digest.
            mstore(0x00, 0x1901001122334455)
            mstore(0x1a, keccak256(m, 0xa0))
            mstore(0x3a, structHash)
            digest := keccak256(0x18, 0x42)
            // Restore the part of the free memory slot that was overwritten.
            mstore(0x3a, 0)
        }
    }
}
