// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Gas optimized P256 wrapper.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/P256.sol)
/// @author Modified from Daimo P256 Verifier (https://github.com/daimo-eth/p256-verifier/blob/master/src/P256.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/P256.sol)
library P256 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Address of the Solidity P256 verifier.
    /// Please make sure the contract is deployed onto the chain you are working on.
    /// See: https://gist.github.com/Vectorized/599b0d8a94d21bc74700eb1354e2f55c
    /// Unlike RIP-7212, this verifier returns `uint256(0)` on failure, to
    /// facilitate easier existence check. This verifier will also never revert.
    address internal constant VERIFIER = 0x000000000000D01eA45F9eFD5c54f037Fa57Ea1a;

    /// @dev The existence of this contract, as determined by non-empty bytecode,
    /// implies the existence of the RIP-7212 precompile.
    /// See: https://gist.github.com/Vectorized/3c69dcf4604b9e1216525cabcd06ee34
    /// This is to enable the optimization to skip the `VERIFIER` entirely
    /// when the `RIP_PRECOMPILE` returns empty returndata for an invalid signature.
    address internal constant CANARY = 0x0000000000001Ab2e8006Fd8B71907bf06a5BDEE;

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
                if iszero(extcodesize(CANARY)) {
                    // The verifier will never revert when given sufficient gas.
                    // The `invalid` upon `staticcall` failure is solely for gas estimation.
                    if iszero(staticcall(gas(), VERIFIER, m, 0xa0, 0x00, 0x20)) { invalid() }
                }
                // Unlike RIP-7212, the verifier returns `uint256(0)` on failure.
                // We shall not revert even if the verifier does not exist,
                // to allow for workflows where reverting can cause trouble.
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
                if iszero(extcodesize(CANARY)) {
                    // The verifier will never revert when given sufficient gas.
                    // The `invalid` upon `staticcall` failure is solely for gas estimation.
                    if iszero(staticcall(gas(), VERIFIER, m, 0xa0, 0x00, 0x20)) { invalid() }
                }
                // Unlike RIP-7212, the verifier returns `uint256(0)` on failure.
                // We shall not revert even if the verifier does not exist,
                // to allow for workflows where reverting can cause trouble.
            }
            // Optimize for happy path. Users are unlikely to pass in malleable signatures.
            isValid := lt(gt(s, _HALF_N), eq(1, mload(0x00)))
        }
    }

    /// @dev Returns if the RIP-7212 precompile exists.
    function hasPrecompile() internal view returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            // These values are taken from the standard Wycheproof test vectors.
            // https://github.com/C2SP/wycheproof/blob/aca47066256c167f0ce04d611d718cc85654341e/testvectors/ecdsa_webcrypto_test.json#L1197
            mstore(m, 0x532eaabd9574880dbf76b9b8cc00832c20a6ec113d682299550d7a6e0f345e25) // `hash`.
            mstore(add(m, 0x20), 0x5) // `r`.
            mstore(add(m, 0x40), 0x1) // `s`.
            mstore(add(m, 0x60), 0x4a03ef9f92eb268cafa601072489a56380fa0dc43171d7712813b3a19a1eb5e5) // `x`.
            mstore(add(m, 0x80), 0x3e213e28a608ce9a2f4a17fd830c6654018a79b3e0263d91a8ba90622df6f2f0) // `y`.
            // The `invalid` upon `staticcall` failure is solely for gas estimation.
            if iszero(staticcall(gas(), RIP_PRECOMPILE, m, 0xa0, m, 0x20)) { invalid() }
            result := eq(1, mload(m))
        }
    }

    /// @dev Returns if either the RIP-7212 precompile or the verifier exists.
    /// Since `verifySignature` is made not reverting, this function can be used to
    /// manually implement a revert if the current chain does not have the contracts
    /// to support secp256r1 signature recovery.
    function hasPrecompileOrVerifier() internal view returns (bool result) {
        result = hasPrecompile();
        /// @solidity memory-safe-assembly
        assembly {
            result := iszero(iszero(or(result, extcodesize(VERIFIER))))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      OTHER OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns `s` normalized to the lower half of the curve.
    function normalized(bytes32 s) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := xor(s, mul(xor(sub(N, s), s), gt(s, _HALF_N)))
        }
    }

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
