# WebAuthn

WebAuthn helper.






<!-- customintro:start --><!-- customintro:end -->

## Structs

### WebAuthnAuth

```solidity
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
```

Helps make encoding and decoding easier, alleviates stack-too-deep.

## Webauthn Verification Operations

### verify(bytes,bool,WebAuthnAuth,bytes32,bytes32)

```solidity
function verify(
    bytes memory challenge,
    bool requireUserVerification,
    WebAuthnAuth memory auth,
    bytes32 x,
    bytes32 y
) internal view returns (bool result)
```

Verifies a Webauthn Authentication Assertion.   
See: https://www.w3.org/TR/webauthn-2/#sctn-verifying-assertion.   
We do not verify all the steps as described in the specification, only ones   
relevant to our context. Please carefully read through this list before usage.   
Specifically, we do verify the following:   
- Verify that `authenticatorData` (which comes from the authenticator,   
  such as iCloud Keychain) indicates a well-formed assertion with the   
  "User Present" bit set. If `requireUserVerification` is set, checks that the   
  authenticator enforced user verification. User verification should be required   
  if, and only if, `options.userVerification` is set to required in the request.   
- Verifies that the client JSON is of type "webauthn.get",   
  i.e. the client was responding to a request to assert authentication.   
- Verifies that the client JSON contains the requested challenge.   
- Verifies that (r, s) constitute a valid signature over both the   
  `authData` and client JSON, for public key (x, y).   
We make some assumptions about the particular use case of this verifier,   
so we do NOT verify the following:   
- Does NOT verify that the origin in the `clientDataJSON` matches the   
  Relying Party's origin: it is considered the authenticator's responsibility to   
  ensure that the user is interacting with the correct RP. This is enforced by   
  most high quality authenticators properly, particularly the iCloud Keychain   
  and Google Password Manager were tested.   
- Does NOT verify That `topOrigin` in `clientDataJSON` is well-formed:   
  We assume it would never be present, i.e. the credentials are never used in a   
  cross-origin/iframe context. The website/app set up should disallow cross-origin   
  usage of the credentials. This is the default behavior for created credentials   
  in common settings.   
- Does NOT verify that the `rpIdHash` in `authenticatorData` is the SHA-256 hash   
  of the RP ID expected by the Relying Party:   
  this means that we rely on the authenticator to properly enforce   
  credentials to be used only by the correct RP.   
  This is generally enforced with features like Apple App Site Association   
  and Google Asset Links. To protect from edge cases in which a previously-linked   
  RP ID is removed from the authorized RP IDs, we recommend that messages   
  signed by the authenticator include some expiry mechanism.   
- Does NOT verify the credential backup state: this assumes the credential backup   
  state is NOT used as part of Relying Party business logic or policy.   
- Does NOT verify the values of the client extension outputs:   
  this assumes that the Relying Party does not use client extension outputs.   
- Does NOT verify the signature counter: signature counters are intended to enable   
  risk scoring for the Relying Party. This assumes risk scoring is not used as part   
  of Relying Party business logic or policy.   
- Does NOT verify the attestation object: this assumes that   
  response.attestationObject is NOT present in the response,   
  i.e. the RP does not intend to verify an attestation.

### verify(bytes,bool,bytes,string,uint256,uint256,bytes32,bytes32,bytes32,bytes32)

```solidity
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
) internal view returns (bool)
```

Plain variant of verify.

## Encoding / Decoding Helpers

### encodeAuth(WebAuthnAuth)

```solidity
function encodeAuth(WebAuthnAuth memory auth)
    internal
    pure
    returns (bytes memory)
```

Returns `abi.encode(auth)`.

### tryDecodeAuth(bytes)

```solidity
function tryDecodeAuth(bytes memory encodedAuth)
    internal
    pure
    returns (WebAuthnAuth memory decoded)
```

Performs a best-effort attempt to `abi.decode(auth)`. Won't revert.   
If any fields cannot be successfully extracted, `decoded` will not be populated,   
which will cause `verify` to return false (as `clientDataJSON` is empty).

### tryEncodeAuthCompact(WebAuthnAuth)

```solidity
function tryEncodeAuthCompact(WebAuthnAuth memory auth)
    internal
    pure
    returns (bytes memory result)
```

Returns the compact encoding of `auth`:   
```solidity   
abi.encodePacked(   
    uint16(auth.authenticatorData.length),   
    bytes(auth.authenticatorData),   
    bytes(auth.clientDataJSON),   
    uint16(auth.challengeIndex),   
    uint16(auth.typeIndex),   
    bytes32(auth.r),   
    bytes32(auth.s)   
)   
```   
Returns the empty string if any length or index exceeds 16 bits.

### tryDecodeAuthCompact(bytes)

```solidity
function tryDecodeAuthCompact(bytes memory encodedAuth)
    internal
    pure
    returns (WebAuthnAuth memory decoded)
```

Approximately the same gas as `tryDecodeAuth`, but helps save on calldata.   
If any fields cannot be successfully extracted, `decoded` will not be populated,   
which will cause `verify` to return false (as `clientDataJSON` is empty).

### tryDecodeAuthCompactCalldata(bytes)

```solidity
function tryDecodeAuthCompactCalldata(bytes calldata encodedAuth)
    internal
    pure
    returns (WebAuthnAuth memory decoded)
```

Calldata variant of `tryDecodeAuthCompact`.