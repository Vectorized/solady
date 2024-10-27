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
    bytes1 private constant _AUTH_DATA_FLAGS_UP = 0x01;

    /// @dev Bit 2 of the authenticator data struct, corresponding to the "User Verified" bit.
    /// See: https://www.w3.org/TR/webauthn-2/#flags.
    bytes1 private constant _AUTH_DATA_FLAGS_UV = 0x04;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              WEBAUTHN VERIFICATION OPERATIONS              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Verifies a Webauthn Authentication Assertion as described
    /// in https://www.w3.org/TR/webauthn-2/#sctn-verifying-assertion.
    ///
    /// We do not verify all the steps as described in the specification,
    /// only ones relevant to our context.
    /// Please carefully read through this list before usage.
    ///
    /// Specifically, we do verify the following:
    /// - Verify that authenticatorData (which comes from the authenticator,
    ////  such as iCloud Keychain) indicates a well-formed assertion with the user present
    ///   bit set. If `requireUV` is set, checks that the authenticator enforced user
    ///   verification. User verification should be required if, and only if,
    ///   `options.userVerification` is set to required in the request.
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
    ///   usage of the credentials. This is the default behaviour for created credentials
    ///   in common settings.
    /// - Does NOT verify that the `rpIdHash` in `authenticatorData` is the SHA-256 hash
    ///   of the RP ID expected by the Relying
    ///   Party: this means that we rely on the authenticator to properly enforce
    ///   credentials to be used only by the correct RP.
    ///   This is generally enforced with features like Apple App Site Association
    ///   and Google Asset Links. To protect from edge cases in which a previously-linked
    ///   RP ID is removed from the authorised RP IDs, we recommend that messages
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
        string memory encodedURL = Base64.encode(challenge, true, true);
        /// @solidity memory-safe-assembly
        assembly {
            let authData := mload(webAuthnAuth)
            let clientDataJSON := mload(add(webAuthnAuth, 0x20))
            let n := mload(clientDataJSON)
            {
                let c := mload(add(webAuthnAuth, 0x40)) // Challenge index in `clientDataJSON`.
                let t := mload(add(webAuthnAuth, 0x60)) // Type index in `clientDataJSON`.
                let l := mload(encodedURL) // Cache the length of `encodedURL`.
                let q := add(l, 13)
                mstore(encodedURL, shr(152, '"challenge":"'))
                result :=
                    and(
                        // 11. Verify that the value of C.type is the string webauthn.get.
                        // bytes("type":"webauthn.get").length = 21
                        and(
                            eq(
                                shr(88, mload(add(add(clientDataJSON, 0x20), t))),
                                shr(88, '"type":"webauthn.get"')
                            ),
                            and(lt(t, add(20, t)), lt(add(20, t), n))
                        ),
                        // 12. Verify that the value of C.challenge equals the base64url
                        // encoding of options.challenge.
                        and(
                            eq(
                                keccak256(add(add(clientDataJSON, 0x20), c), q),
                                keccak256(add(encodedURL, 19), q)
                            ),
                            and(
                                eq(and(0xff, mload(add(add(clientDataJSON, c), q))), 34),
                                and(lt(c, add(q, c)), lt(add(q, c), n))
                            )
                        )
                    )
                mstore(encodedURL, l) // Restore the length of `encodedURL`.
            }
            // Skip 13., 14., 15.
            let l := mload(authData) // Length of `authData`.
            let f := mul(gt(l, 0x20), byte(0, add(authData, 0x40))) // Flags in `authData`.
            // 16. Verify that the UP bit of the flags in `authData` is set.
            result := and(eq(and(f, _AUTH_DATA_FLAGS_UP), _AUTH_DATA_FLAGS_UP), result)
            // 17. If user verification is required for this assertion,
            // verify that the User Verified bit of the flags in `authData` is set.
            if requireUserVerification {
                result := and(eq(and(f, _AUTH_DATA_FLAGS_UV), _AUTH_DATA_FLAGS_UV), result)
            }
            let e := add(add(authData, 0x20), l) // Location of the word after `authData`.
            let w := mload(e) // Cache the word after `authData`.
            // 19. Let `hash` be the result of computing a hash over the cData using SHA-256.
            if iszero(staticcall(gas(), 2, add(clientDataJSON, 0x20), n, e, 0x20)) { invalid() }
            // 20. Using credentialPublicKey, verify that sig is a valid signature over the
            // binary concatenation of `authData` and `hash`.
            if iszero(staticcall(gas(), 2, add(authData, 0x20), add(l, 0x20), 0x00, 0x20)) {
                invalid()
            }
            mstore(e, w) // Restore the word after `authData`.
            messageHash := mload(0x00)
        }
        return result && P256.verifySignature(messageHash, webAuthnAuth.r, webAuthnAuth.s, x, y);
    }
}
