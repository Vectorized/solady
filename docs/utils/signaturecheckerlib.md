# SignatureCheckerLib

Signature verification helper that supports both ECDSA signatures from EOAs and ERC1271 signatures from smart contract wallets like Argent and Gnosis safe.


<b>Note:</b>

- The signature checking functions use the ecrecover precompile (0x1).
- The `bytes memory signature` variants use the identity precompile (0x4)
to copy memory internally.
- Unlike ECDSA signatures, contract signatures are revocable.
- As of Solady version 0.0.134, all `bytes signature` variants accept both
regular 65-byte `(r, s, v)` and EIP-2098 `(r, vs)` short form signatures.
See: https://eips.ethereum.org/EIPS/eip-2098
This is for calldata efficiency on smart accounts prevalent on L2s.

<b>WARNING! Do NOT use signatures as unique identifiers:</b>
- Use a nonce in the digest to prevent replay attacks on the same contract.
- Use EIP-712 for the digest to prevent replay attacks across different chains and contracts.
EIP-712 also enables readable signing of typed data for better user safety.
This implementation does NOT check if a signature is non-malleable.



<!-- customintro:start --><!-- customintro:end -->

## Signature Checking Operations

### isValidSignatureNow(address,bytes32,bytes)

```solidity
function isValidSignatureNow(
    address signer,
    bytes32 hash,
    bytes memory signature
) internal view returns (bool isValid)
```

Returns whether `signature` is valid for `signer` and `hash`.   
If `signer.code.length == 0`, then validate with `ecrecover`, else   
it will validate with ERC1271 on `signer`.

### isValidSignatureNowCalldata(address,bytes32,bytes)

```solidity
function isValidSignatureNowCalldata(
    address signer,
    bytes32 hash,
    bytes calldata signature
) internal view returns (bool isValid)
```

Returns whether `signature` is valid for `signer` and `hash`.   
If `signer.code.length == 0`, then validate with `ecrecover`, else   
it will validate with ERC1271 on `signer`.

### isValidSignatureNow(address,bytes32,bytes32,bytes32)

```solidity
function isValidSignatureNow(
    address signer,
    bytes32 hash,
    bytes32 r,
    bytes32 vs
) internal view returns (bool isValid)
```

Returns whether the signature (`r`, `vs`) is valid for `signer` and `hash`.   
If `signer.code.length == 0`, then validate with `ecrecover`, else   
it will validate with ERC1271 on `signer`.

### isValidSignatureNow(address,bytes32,uint8,bytes32,bytes32)

```solidity
function isValidSignatureNow(
    address signer,
    bytes32 hash,
    uint8 v,
    bytes32 r,
    bytes32 s
) internal view returns (bool isValid)
```

Returns whether the signature (`v`, `r`, `s`) is valid for `signer` and `hash`.   
If `signer.code.length == 0`, then validate with `ecrecover`, else   
it will validate with ERC1271 on `signer`.

## ERC1271 Operations

Note: These ERC1271 operations do NOT have an ECDSA fallback.

### isValidERC1271SignatureNow(address,bytes32,bytes)

```solidity
function isValidERC1271SignatureNow(
    address signer,
    bytes32 hash,
    bytes memory signature
) internal view returns (bool isValid)
```

Returns whether `signature` is valid for `hash` for an ERC1271 `signer` contract.

### isValidERC1271SignatureNowCalldata(address,bytes32,bytes)

```solidity
function isValidERC1271SignatureNowCalldata(
    address signer,
    bytes32 hash,
    bytes calldata signature
) internal view returns (bool isValid)
```

Returns whether `signature` is valid for `hash` for an ERC1271 `signer` contract.

### isValidERC1271SignatureNow(address,bytes32,bytes32,bytes32)

```solidity
function isValidERC1271SignatureNow(
    address signer,
    bytes32 hash,
    bytes32 r,
    bytes32 vs
) internal view returns (bool isValid)
```

Returns whether the signature (`r`, `vs`) is valid for `hash`   
for an ERC1271 `signer` contract.

### isValidERC1271SignatureNow(address,bytes32,uint8,bytes32,bytes32)

```solidity
function isValidERC1271SignatureNow(
    address signer,
    bytes32 hash,
    uint8 v,
    bytes32 r,
    bytes32 s
) internal view returns (bool isValid)
```

Returns whether the signature (`v`, `r`, `s`) is valid for `hash`   
for an ERC1271 `signer` contract.

## ERC6492 Operations

Note: These ERC6492 operations now include an ECDSA fallback at the very end.   
The calldata variants are excluded for brevity.

### isValidERC6492SignatureNowAllowSideEffects(address,bytes32,bytes)

```solidity
function isValidERC6492SignatureNowAllowSideEffects(
    address signer,
    bytes32 hash,
    bytes memory signature
) internal returns (bool isValid)
```

Returns whether `signature` is valid for `hash`.   
If the signature is postfixed with the ERC6492 magic number, it will attempt to   
deploy / prepare the `signer` smart account before doing a regular ERC1271 check.   
Note: This function is NOT reentrancy safe.   
The verifier must be deployed.   
Otherwise, the function will return false if `signer` is not yet deployed / prepared.   
See: https://gist.github.com/Vectorized/011d6becff6e0a73e42fe100f8d7ef04   
With a dedicated verifier, this function is safe to use in contracts   
that have been granted special permissions.

### isValidERC6492SignatureNow(address,bytes32,bytes)

```solidity
function isValidERC6492SignatureNow(
    address signer,
    bytes32 hash,
    bytes memory signature
) internal returns (bool isValid)
```

Returns whether `signature` is valid for `hash`.   
If the signature is postfixed with the ERC6492 magic number, it will attempt   
to use a reverting verifier to deploy / prepare the `signer` smart account   
and do a `isValidSignature` check via the reverting verifier.   
Note: This function is reentrancy safe.   
The reverting verifier must be deployed.   
Otherwise, the function will return false if `signer` is not yet deployed / prepared.   
See: https://gist.github.com/Vectorized/846a474c855eee9e441506676800a9ad

## Hashing Operations

### toEthSignedMessageHash(bytes32)

```solidity
function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32 result)
```

Returns an Ethereum Signed Message, created from a `hash`.   
This produces a hash corresponding to the one signed with the   
[`eth_sign`](https://eth.wiki/json-rpc/API#eth_sign)   
JSON-RPC method as part of EIP-191.

### toEthSignedMessageHash(bytes)

```solidity
function toEthSignedMessageHash(bytes memory s)
    internal
    pure
    returns (bytes32 result)
```

Returns an Ethereum Signed Message, created from `s`.   
This produces a hash corresponding to the one signed with the   
[`eth_sign`](https://eth.wiki/json-rpc/API#eth_sign)   
JSON-RPC method as part of EIP-191.   
Note: Supports lengths of `s` up to 999999 bytes.

## Empty Calldata Helpers

### emptySignature()

```solidity
function emptySignature()
    internal
    pure
    returns (bytes calldata signature)
```

Returns an empty calldata bytes.