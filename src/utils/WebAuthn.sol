// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Base64} from "./Base64.sol";
import {P256} from "./P256.sol";

/// @notice WebAuthn helper.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/WebAuthn.sol)
/// @author Modified from Daimo WebAuthn (https://github.com/daimo-eth/p256-verifier/blob/master/src/WebAuthn.sol)
/// @author Modified from Coinbase WebAuthn (https://github.com/base-org/webauthn-sol/blob/main/src/WebAuthn.sol)
library WebAuthn {
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
        // The index at which "challenge":"..." occurs in `clientDataJSON`.
        uint256 challengeIndex;
        // The index at which "type":"..." occurs in `clientDataJSON`.
        uint256 typeIndex;
        // The r value of secp256r1 signature
        bytes32 r;
        // The s value of secp256r1 signature
        bytes32 s;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Bit 0 of the authenticator data struct, corresponding to the "User Present" bit.
    /// See: https://www.w3.org/TR/webauthn-2/#flags.
    uint256 private constant _AUTH_DATA_FLAGS_UP = 0x01;

    /// @dev Bit 2 of the authenticator data struct, corresponding to the "User Verified" bit.
    /// See: https://www.w3.org/TR/webauthn-2/#flags.
    uint256 private constant _AUTH_DATA_FLAGS_UV = 0x04;

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
        WebAuthnAuth memory webAuthnAuth,
        bytes32 x,
        bytes32 y
    ) internal view returns (bool result) {
        bytes32 messageHash;
        string memory encoded = Base64.encode(challenge, true, true);
        /// @solidity memory-safe-assembly
        assembly {
            let clientDataJSON := mload(add(webAuthnAuth, 0x20))
            let n := mload(clientDataJSON) // `clientDataJSON`'s length.
            let o := add(clientDataJSON, 0x20) // Start of `clientData`'s bytes.
            {
                let c := mload(add(webAuthnAuth, 0x40)) // Challenge index in `clientDataJSON`.
                let t := mload(add(webAuthnAuth, 0x60)) // Type index in `clientDataJSON`.
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
            let authData := mload(webAuthnAuth)
            let l := mload(authData) // Length of `authData`.
            let r :=
                or(
                    // 16. Verify that the "User Present" flag is set.
                    _AUTH_DATA_FLAGS_UP,
                    // 17. Verify that the "User Verified" flag is set, if required.
                    mul(_AUTH_DATA_FLAGS_UV, iszero(iszero(requireUserVerification)))
                )
            result :=
                and(and(result, gt(l, 0x20)), eq(and(byte(0, mload(add(authData, 0x40))), r), r))
            if result {
                let p := add(authData, 0x20) // Start of `authData`'s bytes.
                let e := add(p, l) // Location of the word after `authData`.
                let w := mload(e) // Cache the word after `authData`.
                // 19. Compute `sha256(clientDataJSON)`.
                pop(staticcall(gas(), 2, o, n, e, 0x20))
                // 20. Compute `sha256(authData ‖ sha256(clientDataJSON))`.
                pop(staticcall(gas(), 2, p, add(l, 0x20), 0x00, returndatasize()))
                // `returndatasize()` is `0x20` on `sha256` success, and `0x00` otherwise.
                if iszero(returndatasize()) { invalid() }
                mstore(e, w) // Restore the word after `authData`, in case of reuse.
                messageHash := mload(0x00)
            }
        }
        // `P256.verifySignature` returns false if `s > N/2` due to the malleability check.
        return result && P256.verifySignature(messageHash, webAuthnAuth.r, webAuthnAuth.s, x, y);
    }
}
