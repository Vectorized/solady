// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// This file is auto-generated.

/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
/*                          STRUCTS                           */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

/// @dev Helps make encoding and decoding easier, alleviates stack-too-deep.
struct WebAuthnAuth {
    // The WebAuthn authenticator data.
    // See: https://www.w3.org/TR/webauthn-2/#dom-authenticatorassertionresponse-authenticatordata.
    bytes authenticatorData;
    // The WebAuthn client data JSON.
    // See: https://www.w3.org/TR/webauthn-2/#dom-authenticatorresponse-clientdatajson.
    string clientDataJSON;
    // Start index of "challenge":"..." in `clientDataJSON`.
    uint256 challengeIndex;
    // Start index of "type":"..." in `clientDataJSON`.
    uint256 typeIndex;
    // The r value of secp256r1 signature.
    bytes32 r;
    // The s value of secp256r1 signature.
    bytes32 s;
}

using WebAuthn for WebAuthnAuth global;

import {Base64} from "../Base64.sol";
import {P256} from "../P256.sol";

/// @notice WebAuthn helper.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/g/WebAuthn.sol)
/// @author Modified from Daimo WebAuthn (https://github.com/daimo-eth/p256-verifier/blob/master/src/WebAuthn.sol)
/// @author Modified from Coinbase WebAuthn (https://github.com/base-org/webauthn-sol/blob/main/src/WebAuthn.sol)
library WebAuthn {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              WEBAUTHN VERIFICATION OPERATIONS              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Verifies a Webauthn Authentication Assertion.
    /// See: https://www.w3.org/TR/webauthn-2/#sctn-verifying-assertion.
    ///
    /// We do not verify all the steps as described in the specification, only ones
    /// relevant to our context. Please carefully read through this list before usage.
    ///
    /// Specifically, we do verify the following:
    /// - Verify that `authenticatorData` (which comes from the authenticator,
    ///   such as iCloud Keychain) indicates a well-formed assertion with the
    ///   "User Present" bit set. If `requireUserVerification` is set, checks that the
    ///   authenticator enforced user verification. User verification should be required
    ///   if, and only if, `options.userVerification` is set to required in the request.
    /// - Verifies that the client JSON is of type "webauthn.get",
    ///   i.e. the client was responding to a request to assert authentication.
    /// - Verifies that the client JSON contains the requested challenge.
    /// - Verifies that (r, s) constitute a valid signature over both the
    ///   `authData` and client JSON, for public key (x, y).
    ///
    /// We make some assumptions about the particular use case of this verifier,
    /// so we do NOT verify the following:
    /// - Does NOT verify that the origin in the `clientDataJSON` matches the
    ///   Relying Party's origin: it is considered the authenticator's responsibility to
    ///   ensure that the user is interacting with the correct RP. This is enforced by
    ///   most high quality authenticators properly, particularly the iCloud Keychain
    ///   and Google Password Manager were tested.
    /// - Does NOT verify That `topOrigin` in `clientDataJSON` is well-formed:
    ///   We assume it would never be present, i.e. the credentials are never used in a
    ///   cross-origin/iframe context. The website/app set up should disallow cross-origin
    ///   usage of the credentials. This is the default behavior for created credentials
    ///   in common settings.
    /// - Does NOT verify that the `rpIdHash` in `authenticatorData` is the SHA-256 hash
    ///   of the RP ID expected by the Relying Party:
    ///   this means that we rely on the authenticator to properly enforce
    ///   credentials to be used only by the correct RP.
    ///   This is generally enforced with features like Apple App Site Association
    ///   and Google Asset Links. To protect from edge cases in which a previously-linked
    ///   RP ID is removed from the authorized RP IDs, we recommend that messages
    ///   signed by the authenticator include some expiry mechanism.
    /// - Does NOT verify the credential backup state: this assumes the credential backup
    ///   state is NOT used as part of Relying Party business logic or policy.
    /// - Does NOT verify the values of the client extension outputs:
    ///   this assumes that the Relying Party does not use client extension outputs.
    /// - Does NOT verify the signature counter: signature counters are intended to enable
    ///   risk scoring for the Relying Party. This assumes risk scoring is not used as part
    ///   of Relying Party business logic or policy.
    /// - Does NOT verify the attestation object: this assumes that
    ///   response.attestationObject is NOT present in the response,
    ///   i.e. the RP does not intend to verify an attestation.
    function verify(
        bytes memory challenge,
        bool requireUserVerification,
        WebAuthnAuth memory auth,
        bytes32 x,
        bytes32 y
    ) internal view returns (bool result) {
        bytes32 messageHash;
        string memory encoded = Base64.encode(challenge, true, true);
        /// @solidity memory-safe-assembly
        assembly {
            let clientDataJSON := mload(add(auth, 0x20))
            let n := mload(clientDataJSON) // `clientDataJSON`'s length.
            let o := add(clientDataJSON, 0x20) // Start of `clientData`'s bytes.
            {
                let c := mload(add(auth, 0x40)) // Challenge index in `clientDataJSON`.
                let t := mload(add(auth, 0x60)) // Type index in `clientDataJSON`.
                let l := mload(encoded) // Cache `encoded`'s length.
                let q := add(l, 0x0d) // Length of `encoded` prefixed with '"challenge":"'.
                mstore(encoded, shr(152, '"challenge":"')) // Temp prefix with '"challenge":"'.
                result :=
                    and(
                        // 11. Verify JSON's type. Also checks for possible addition overflows.
                        and(
                            eq(shr(88, mload(add(o, t))), shr(88, '"type":"webauthn.get"')),
                            lt(shr(128, or(t, c)), lt(add(0x14, t), n))
                        ),
                        // 12. Verify JSON's challenge. Includes a check for the closing '"'.
                        and(
                            eq(keccak256(add(o, c), q), keccak256(add(encoded, 0x13), q)),
                            and(eq(byte(0, mload(add(add(o, c), q))), 34), lt(add(q, c), n))
                        )
                    )
                mstore(encoded, l) // Restore `encoded`'s length, in case of string interning.
            }
            // Skip 13., 14., 15.
            let l := mload(mload(auth)) // Length of `authenticatorData`.
            // 16. Verify that the "User Present" flag is set (bit 0).
            // 17. Verify that the "User Verified" flag is set (bit 2), if required.
            // See: https://www.w3.org/TR/webauthn-2/#flags.
            let u := or(1, shl(2, iszero(iszero(requireUserVerification))))
            result := and(and(result, gt(l, 0x20)), eq(and(mload(add(mload(auth), 0x21)), u), u))
            if result {
                let p := add(mload(auth), 0x20) // Start of `authenticatorData`'s bytes.
                let e := add(p, l) // Location of the word after `authenticatorData`.
                let w := mload(e) // Cache the word after `authenticatorData`.
                // 19. Compute `sha256(clientDataJSON)`.
                // 20. Compute `sha256(authenticatorData ‖ sha256(clientDataJSON))`.
                // forgefmt: disable-next-item
                messageHash := mload(staticcall(gas(),
                    shl(1, staticcall(gas(), 2, o, n, e, 0x20)), p, add(l, 0x20), 0x01, 0x20))
                mstore(e, w) // Restore the word after `authenticatorData`, in case of reuse.
                // `returndatasize()` is `0x20` on `sha256` success, and `0x00` otherwise.
                if iszero(returndatasize()) { invalid() }
            }
        }
        // `P256.verifySignature` returns false if `s > N/2` due to the malleability check.
        if (result) result = P256.verifySignature(messageHash, auth.r, auth.s, x, y);
    }

    /// @dev Plain variant of verify.
    function verify(
        bytes memory challenge,
        bool requireUserVerification,
        bytes memory authenticatorData,
        string memory clientDataJSON,
        uint256 challengeIndex,
        uint256 typeIndex,
        bytes32 r,
        bytes32 s,
        bytes32 x,
        bytes32 y
    ) internal view returns (bool) {
        return verify(
            challenge,
            requireUserVerification,
            WebAuthnAuth(authenticatorData, clientDataJSON, challengeIndex, typeIndex, r, s),
            x,
            y
        );
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                ENCODING / DECODING HELPERS                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns `abi.encode(auth)`.
    function encodeAuth(WebAuthnAuth memory auth) internal pure returns (bytes memory) {
        return abi.encode(auth);
    }

    /// @dev Performs a best-effort attempt to `abi.decode(auth)`. Won't revert.
    /// If any fields cannot be successfully extracted, `decoded` will not be populated,
    /// which will cause `verify` to return false (as `clientDataJSON` is empty).
    function tryDecodeAuth(bytes memory encodedAuth)
        internal
        pure
        returns (WebAuthnAuth memory decoded)
    {
        /// @solidity memory-safe-assembly
        assembly {
            for { let n := mload(encodedAuth) } iszero(lt(n, 0xc0)) {} {
                let o := add(encodedAuth, 0x20) // Start of `encodedAuth`'s bytes.
                let e := add(o, n) // End of `encodedAuth` in memory.
                let p := add(mload(o), o) // Start of `encodedAuth`.
                if or(gt(add(p, 0xc0), e), lt(p, o)) { break }
                let authenticatorData := add(mload(p), p)
                let clientDataJSON := add(mload(add(p, 0x20)), p)
                if or(
                    or(gt(authenticatorData, e), lt(authenticatorData, p)),
                    or(gt(clientDataJSON, e), lt(clientDataJSON, p))
                ) { break }
                if or(
                    gt(add(add(authenticatorData, 0x20), mload(authenticatorData)), e),
                    gt(add(add(clientDataJSON, 0x20), mload(clientDataJSON)), e)
                ) { break }
                mstore(decoded, authenticatorData) // `authenticatorData`.
                mstore(add(decoded, 0x20), clientDataJSON) // `clientDataJSON`.
                mstore(add(decoded, 0x40), mload(add(p, 0x40))) // `challengeIndex`.
                mstore(add(decoded, 0x60), mload(add(p, 0x60))) // `typeIndex`.
                mstore(add(decoded, 0x80), mload(add(p, 0x80))) // `r`.
                mstore(add(decoded, 0xa0), mload(add(p, 0xa0))) // `s`.
                break
            }
        }
    }

    /// @dev Returns the compact encoding of `auth`:
    /// ```
    ///     abi.encodePacked(
    ///         uint16(auth.authenticatorData.length),
    ///         bytes(auth.authenticatorData),
    ///         bytes(auth.clientDataJSON),
    ///         uint16(auth.challengeIndex),
    ///         uint16(auth.typeIndex),
    ///         bytes32(auth.r),
    ///         bytes32(auth.s)
    ///     )
    /// ```
    /// Returns the empty string if any length or index exceeds 16 bits.
    function tryEncodeAuthCompact(WebAuthnAuth memory auth)
        internal
        pure
        returns (bytes memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            function copyBytes(o_, s_, c_) -> _e {
                mstore(o_, shl(240, mload(s_)))
                o_ := add(o_, c_)
                _e := add(o_, mload(s_)) // The end of the bytes.
                for { let d_ := sub(add(0x20, s_), o_) } 1 {} {
                    mstore(o_, mload(add(d_, o_)))
                    o_ := add(o_, 0x20)
                    if iszero(lt(o_, _e)) { break }
                }
            }
            let clientDataJSON := mload(add(0x20, auth))
            let c := mload(add(0x40, auth)) // `challengeIndex`.
            let t := mload(add(0x60, auth)) // `typeIndex`.
            // If none of the lengths are more than `0xffff`.
            if iszero(shr(16, or(or(t, c), or(mload(mload(auth)), mload(clientDataJSON))))) {
                result := mload(0x40)
                // `authenticatorData`, `clientDataJSON`.
                let o := copyBytes(copyBytes(add(result, 0x20), mload(auth), 2), clientDataJSON, 0)
                mstore(o, or(shl(240, c), shl(224, t))) // `challengeIndex`, `typeIndex`.
                mstore(add(o, 0x04), mload(add(0x80, auth))) // `r`.
                mstore(add(o, 0x24), mload(add(0xa0, auth))) // `s`.
                mstore(result, sub(add(o, 0x24), result)) // Store the length.
                mstore(add(o, 0x44), 0) // Zeroize the slot after the string.
                mstore(0x40, add(o, 0x64)) // Allocate memory .
            }
        }
    }

    /// @dev Approximately the same gas as `tryDecodeAuth`, but helps save on calldata.
    /// If any fields cannot be successfully extracted, `decoded` will not be populated,
    /// which will cause `verify` to return false (as `clientDataJSON` is empty).
    function tryDecodeAuthCompact(bytes memory encodedAuth)
        internal
        pure
        returns (WebAuthnAuth memory decoded)
    {
        /// @solidity memory-safe-assembly
        assembly {
            function extractBytes(o_, l_) -> _m {
                _m := mload(0x40) // Grab the free memory pointer.
                let s_ := add(_m, 0x20)
                for { let i_ := 0 } 1 {} {
                    mstore(add(s_, i_), mload(add(o_, i_)))
                    i_ := add(i_, 0x20)
                    if iszero(lt(i_, l_)) { break }
                }
                mstore(_m, l_) // Store the length.
                mstore(add(l_, s_), 0) // Zeroize the slot after the string.
                mstore(0x40, add(0x20, add(l_, s_))) // Allocate memory.
            }
            let n := mload(encodedAuth)
            if iszero(lt(n, 0x46)) {
                let o := add(encodedAuth, 0x20) // Start of `encodedAuth`'s bytes.
                let e := add(o, n) // End of `encodedAuth` in memory.
                n := shr(240, mload(o)) // Length of `authenticatorData`.
                let a := add(o, 0x02) // Start of `authenticatorData`.
                let c := add(a, n) // Start of `clientDataJSON`.
                let j := sub(e, 0x44) // Start of `challengeIndex`.
                if iszero(gt(c, j)) {
                    mstore(decoded, extractBytes(a, n)) // `authenticatorData`.
                    mstore(add(decoded, 0x20), extractBytes(c, sub(j, c))) // `clientDataJSON`.
                    mstore(add(decoded, 0x40), shr(240, mload(j))) // `challengeIndex`.
                    mstore(add(decoded, 0x60), shr(240, mload(add(j, 0x02)))) // `typeIndex`.
                    mstore(add(decoded, 0x80), mload(add(j, 0x04))) // `r`.
                    mstore(add(decoded, 0xa0), mload(add(j, 0x24))) // `s`.
                }
            }
        }
    }

    /// @dev Calldata variant of `tryDecodeAuthCompact`.
    function tryDecodeAuthCompactCalldata(bytes calldata encodedAuth)
        internal
        pure
        returns (WebAuthnAuth memory decoded)
    {
        /// @solidity memory-safe-assembly
        assembly {
            function extractBytes(o_, l_) -> _m {
                _m := mload(0x40) // Grab the free memory pointer.
                let s_ := add(_m, 0x20)
                calldatacopy(s_, o_, l_)
                mstore(_m, l_) // Store the length.
                mstore(add(l_, s_), 0) // Zeroize the slot after the string.
                mstore(0x40, add(0x20, add(l_, s_))) // Allocate memory.
            }
            if iszero(lt(encodedAuth.length, 0x46)) {
                let e := add(encodedAuth.offset, encodedAuth.length) // End of `encodedAuth`.
                let n := shr(240, calldataload(encodedAuth.offset)) // Length of `authenticatorData`.
                let a := add(encodedAuth.offset, 0x02) // Start of `authenticatorData`.
                let c := add(a, n) // Start of `clientDataJSON`.
                let j := sub(e, 0x44) // Start of `challengeIndex`.
                if iszero(gt(c, j)) {
                    mstore(decoded, extractBytes(a, n)) // `authenticatorData`.
                    mstore(add(decoded, 0x20), extractBytes(c, sub(j, c))) // `clientDataJSON`.
                    mstore(add(decoded, 0x40), shr(240, calldataload(j))) // `challengeIndex`.
                    mstore(add(decoded, 0x60), shr(240, calldataload(add(j, 0x02)))) // `typeIndex`.
                    mstore(add(decoded, 0x80), calldataload(add(j, 0x04))) // `r`.
                    mstore(add(decoded, 0xa0), calldataload(add(j, 0x24))) // `s`.
                }
            }
        }
    }
}
