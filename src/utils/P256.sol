// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Gas optimized P256 wrapper.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/P256.sol)
/// @author Modified from Daimo P256 Verifier (https://github.com/daimo-eth/p256-verifier/blob/master/src/P256.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/P256.sol)
library P256 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CUSTOM ERRORS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unable to verify the P256 signature, due to missing
    /// RIP-7212 P256 verifier precompile and missing Solidity P256 verifier.
    error P256VerificationFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Address of the Solidity P256 verifier.
    /// Please make sure the contract is deployed onto the chain you are working on.
    /// See: https://gist.github.com/Vectorized/599b0d8a94d21bc74700eb1354e2f55c
    /// Unlike RIP-7212, this verifier returns `uint256(0)` on failure, to
    /// facilitate easier existence check. This verifier will also never revert.
    address internal constant VERIFIER = 0x000000000000cB83347bEB24C695BBb85dBe99b7;

    /// @dev Address of the RIP-7212 P256 verifier precompile.
    /// Currently, we don't support EIP-7212's precompile at 0x0b as it has not been finalized.
    /// See: https://github.com/ethereum/RIPs/blob/master/RIPS/rip-7212.md
    address internal constant RIP_PRECOMPILE = 0x0000000000000000000000000000000000000100;

    /// @dev The order of the secp256r1 elliptic curve.
    uint256 internal constant N = 0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551;

    /// @dev `N/2`. Used for checking the malleability of the signature.
    uint256 private constant _HALF_N =
        0x7fffffff800000007fffffffffffffffde737d56d38bcf4279dce5617e3192a8;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                P256 VERIFICATION OPERATIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns if the signature (`r`, `s`) is valid for `hash` and public key (`x`, `y`).
    /// Does NOT include the malleability check.
    function verifySignatureAllowMalleability(
        bytes32 hash,
        bytes32 r,
        bytes32 s,
        bytes32 x,
        bytes32 y
    ) internal view returns (bool isValid) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, hash)
            mstore(add(m, 0x20), r)
            mstore(add(m, 0x40), s)
            mstore(add(m, 0x60), x)
            mstore(add(m, 0x80), y)
            mstore(0x00, 0) // Zeroize the return slot before the staticcalls.
            pop(staticcall(gas(), RIP_PRECOMPILE, m, 0xa0, 0x00, 0x20))
            // RIP-7212 dictates that success returns `uint256(1)`.
            // But failure returns zero returndata, which is ambiguous.
            if iszero(returndatasize()) {
                pop(staticcall(gas(), VERIFIER, m, 0xa0, returndatasize(), 0x20))
                // Unlike RIP-7212, the verifier returns `uint256(0)` on failure,
                // allowing us to use the returndatasize to determine existence.
                if iszero(returndatasize()) {
                    mstore(returndatasize(), 0xd0d5039b) // `P256VerificationFailed()`.
                    revert(0x1c, 0x04)
                }
            }
            isValid := eq(1, mload(0x00))
        }
    }

    /// @dev Returns if the signature (`r`, `s`) is valid for `hash` and public key (`x`, `y`).
    /// Includes the malleability check.
    function verifySignature(bytes32 hash, bytes32 r, bytes32 s, bytes32 x, bytes32 y)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, hash)
            mstore(add(m, 0x20), r)
            mstore(add(m, 0x40), s)
            mstore(add(m, 0x60), x)
            mstore(add(m, 0x80), y)
            mstore(0x00, 0) // Zeroize the return slot before the staticcalls.
            pop(staticcall(gas(), RIP_PRECOMPILE, m, 0xa0, 0x00, 0x20))
            // RIP-7212 dictates that success returns `uint256(1)`.
            // But failure returns zero returndata, which is ambiguous.
            if iszero(returndatasize()) {
                pop(staticcall(gas(), VERIFIER, m, 0xa0, returndatasize(), 0x20))
                // Unlike RIP-7212, the verifier returns `uint256(0)` on failure,
                // allowing us to use the returndatasize to determine existence.
                if iszero(returndatasize()) {
                    mstore(returndatasize(), 0xd0d5039b) // `P256VerificationFailed()`.
                    revert(0x1c, 0x04)
                }
            }
            // Optimize for happy path. Users are unlikely to pass in malleable signatures.
            isValid := lt(gt(s, _HALF_N), eq(1, mload(0x00)))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      OTHER OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Helper function for `abi.decode(encoded, (bytes32, bytes32))`.
    /// If `encoded.length < 64`, `(x, y)` will be `(0, 0)`, which is an invalid point.
    function tryDecodePoint(bytes memory encoded) internal pure returns (bytes32 x, bytes32 y) {
        /// @solidity memory-safe-assembly
        assembly {
            let t := gt(mload(encoded), 0x3f)
            x := mul(mload(add(encoded, 0x20)), t)
            y := mul(mload(add(encoded, 0x40)), t)
        }
    }

    /// @dev Helper function for `abi.decode(encoded, (bytes32, bytes32))`.
    /// If `encoded.length < 64`, `(x, y)` will be `(0, 0)`, which is an invalid point.
    function tryDecodePointCalldata(bytes calldata encoded)
        internal
        pure
        returns (bytes32 x, bytes32 y)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let t := gt(encoded.length, 0x3f)
            x := mul(calldataload(encoded.offset), t)
            y := mul(calldataload(add(encoded.offset, 0x20)), t)
        }
    }
}
