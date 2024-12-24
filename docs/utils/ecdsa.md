# ECDSA

Gas optimized ECDSA wrapper.


<b>Note:</b>

- The recovery functions use the ecrecover precompile (0x1).
- As of Solady version 0.0.68, the `recover` variants will revert upon recovery failure.
This is for more safety by default.
Use the `tryRecover` variants if you need to get the zero address back
upon recovery failure instead.
- As of Solady version 0.0.134, all `bytes signature` variants accept both
regular 65-byte `(r, s, v)` and EIP-2098 `(r, vs)` short form signatures.
See: https://eips.ethereum.org/EIPS/eip-2098
This is for calldata efficiency on smart accounts prevalent on L2s.

<b>WARNING! Do NOT directly use signatures as unique identifiers:</b>
- The recovery operations do NOT check if a signature is non-malleable.
- Use a nonce in the digest to prevent replay attacks on the same contract.
- Use EIP-712 for the digest to prevent replay attacks across different chains and contracts.
EIP-712 also enables readable signing of typed data for better user safety.
- If you need a unique hash from a signature, please use the `canonicalHash` functions.



<!-- customintro:start --><!-- customintro:end -->

## Constants

### N

```solidity
uint256 internal constant N =
    0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141
```

The order of the secp256k1 elliptic curve.

## Custom Errors

### InvalidSignature()

```solidity
error InvalidSignature()
```

The signature is invalid.

## Recovery Operations

### recover(bytes32,bytes)

```solidity
function recover(bytes32 hash, bytes memory signature)
    internal
    view
    returns (address result)
```

Recovers the signer's address from a message digest `hash`, and the `signature`.

### recoverCalldata(bytes32,bytes)

```solidity
function recoverCalldata(bytes32 hash, bytes calldata signature)
    internal
    view
    returns (address result)
```

Recovers the signer's address from a message digest `hash`, and the `signature`.

### recover(bytes32,bytes32,bytes32)

```solidity
function recover(bytes32 hash, bytes32 r, bytes32 vs)
    internal
    view
    returns (address result)
```

Recovers the signer's address from a message digest `hash`,   
and the EIP-2098 short form signature defined by `r` and `vs`.

### recover(bytes32,uint8,bytes32,bytes32)

```solidity
function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
    internal
    view
    returns (address result)
```

Recovers the signer's address from a message digest `hash`,   
and the signature defined by `v`, `r`, `s`.

## Try-recover Operations

WARNING!   
These functions will NOT revert upon recovery failure.   
Instead, they will return the zero address upon recovery failure.   
It is critical that the returned address is NEVER compared against   
a zero address (e.g. an uninitialized address variable).

### tryRecover(bytes32,bytes)

```solidity
function tryRecover(bytes32 hash, bytes memory signature)
    internal
    view
    returns (address result)
```

Recovers the signer's address from a message digest `hash`, and the `signature`.

### tryRecoverCalldata(bytes32,bytes)

```solidity
function tryRecoverCalldata(bytes32 hash, bytes calldata signature)
    internal
    view
    returns (address result)
```

Recovers the signer's address from a message digest `hash`, and the `signature`.

### tryRecover(bytes32,bytes32,bytes32)

```solidity
function tryRecover(bytes32 hash, bytes32 r, bytes32 vs)
    internal
    view
    returns (address result)
```

Recovers the signer's address from a message digest `hash`,   
and the EIP-2098 short form signature defined by `r` and `vs`.

### tryRecover(bytes32,uint8,bytes32,bytes32)

```solidity
function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
    internal
    view
    returns (address result)
```

Recovers the signer's address from a message digest `hash`,   
and the signature defined by `v`, `r`, `s`.

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
[`eth_sign`](https://ethereum.org/en/developers/docs/apis/json-rpc/#eth_sign)   
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
[`eth_sign`](https://ethereum.org/en/developers/docs/apis/json-rpc/#eth_sign)   
JSON-RPC method as part of EIP-191.   
Note: Supports lengths of `s` up to 999999 bytes.

## Canonical Hash Functions

The following functions returns the hash of the signature in it's canonicalized format,   
which is the 65-byte `abi.encodePacked(r, s, uint8(v))`, where `v` is either 27 or 28.   
If `s` is greater than `N / 2` then it will be converted to `N - s`   
and the `v` value will be flipped.   
If the signature has an invalid length, or if `v` is invalid,   
a uniquely corrupt hash will be returned.   
These functions are useful for "poor-mans-VRF".

### canonicalHash(bytes)

```solidity
function canonicalHash(bytes memory signature)
    internal
    pure
    returns (bytes32 result)
```

Returns the canonical hash of `signature`.

### canonicalHashCalldata(bytes)

```solidity
function canonicalHashCalldata(bytes calldata signature)
    internal
    pure
    returns (bytes32 result)
```

Returns the canonical hash of `signature`.

### canonicalHash(bytes32,bytes32)

```solidity
function canonicalHash(bytes32 r, bytes32 vs)
    internal
    pure
    returns (bytes32 result)
```

Returns the canonical hash of `signature`.

### canonicalHash(uint8,bytes32,bytes32)

```solidity
function canonicalHash(uint8 v, bytes32 r, bytes32 s)
    internal
    pure
    returns (bytes32 result)
```

Returns the canonical hash of `signature`.

## Empty Calldata Helpers

### emptySignature()

```solidity
function emptySignature()
    internal
    pure
    returns (bytes calldata signature)
```

Returns an empty calldata bytes.