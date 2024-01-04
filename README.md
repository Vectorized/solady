# <img src="logo.svg" alt="solady" height="118"/>

[![NPM][npm-shield]][npm-url]
[![CI][ci-shield]][ci-url]
[![Solidity][solidity-shield]][solidity-ci-url]

Gas optimized Solidity snippets.

I'm sooooooOooooooooOoooOoooooooooooooooo...

## Installation

To install with [**Foundry**](https://github.com/gakonst/foundry):

```sh
forge install vectorized/solady
```

To install with [**Hardhat**](https://github.com/nomiclabs/hardhat) or [**Truffle**](https://github.com/trufflesuite/truffle):

```sh
npm install solady
```

## Contracts

The Solidity smart contracts are located in the `src` directory.

```ml
accounts
├─ Receiver — "Receiver mixin for ETH and safe-transferred ERC721 and ERC1155 tokens"
├─ ERC1271 — "ERC1271 mixin with nested EIP-712 approach"
├─ ERC4337 — "Simple ERC4337 account implementation"
├─ ERC4337Factory — "Simple ERC4337 account factory implementation"
├─ ERC6551 — "Simple ERC6551 account implementation"
├─ ERC6551Proxy — "Relay proxy for upgradeable ERC6551 accounts"
auth
├─ Ownable — "Simple single owner authorization mixin"
├─ OwnableRoles — "Simple single owner and multiroles authorization mixin"
tokens
├─ WETH — "Simple Wrapped Ether implementation"
├─ ERC20 — "Simple ERC20 + EIP-2612 implementation"
├─ ERC4626 — "Simple ERC4626 tokenized Vault implementation"
├─ ERC721 — "Simple ERC721 implementation with storage hitchhiking"
├─ ERC2981 — "Simple ERC2981 NFT Royalty Standard implementation"
├─ ERC1155 — "Simple ERC1155 implementation"
├─ ERC6909 — "Simple EIP-6909 minimal multi-token implementation"
utils
├─ MerkleProofLib — "Library for verification of Merkle proofs"
├─ SignatureCheckerLib — "Library for verification of ECDSA and ERC1271 signatures"
├─ ECDSA — "Library for verification of ECDSA signatures"
├─ EIP712 — "Contract for EIP-712 typed structured data hashing and signing"
├─ ERC1967Factory — "Factory for deploying and managing ERC1967 proxy contracts"
├─ ERC1967FactoryConstants — "The address and bytecode of the canonical ERC1967Factory"
├─ JSONParserLib — "Library for parsing JSONs"
├─ LibSort — "Library for efficient sorting of memory arrays"
├─ LibPRNG — "Library for generating pseudorandom numbers"
├─ Base64 — "Library for Base64 encoding and decoding"
├─ SSTORE2 — "Library for cheaper reads and writes to persistent storage"
├─ CREATE3 — "Deploy to deterministic addresses without an initcode factor"
├─ LibRLP — "Library for computing contract addresses from their deployer and nonce"
├─ LibBit — "Library for bit twiddling and boolean operations"
├─ LibZip — "Library for compressing and decompressing bytes"
├─ Clone — "Class with helper read functions for clone with immutable args"
├─ LibClone — "Minimal proxy library"
├─ Initializable — "Initializable mixin for the upgradeable contracts"
├─ UUPSUpgradeable — "UUPS proxy mixin"
├─ LibString — "Library for converting numbers into strings and other string operations"
├─ LibBitmap — "Library for storage of packed booleans"
├─ LibMap — "Library for storage of packed unsigned integers"
├─ MinHeapLib — "Library for managing a min-heap in storage"
├─ RedBlackTreeLib — "Library for managing a red-black-tree in storage"
├─ Multicallable — "Contract that enables a single call to call multiple methods on itself"
├─ GasBurnerLib — "Library for burning gas without reverting"
├─ SafeTransferLib — "Safe ERC20/ETH transfer lib that handles missing return values"
├─ DynamicBufferLib — "Library for buffers with automatic capacity resizing"
├─ MetadataReaderLib — "Library for reading contract metadata robustly"
├─ FixedPointMathLib — "Arithmetic library with operations for fixed-point numbers"
├─ SafeCastLib — "Library for integer casting that reverts on overflow"
└─ DateTimeLib — "Library for date time operations"
```

## Directories

```ml
src — "Solidity smart contracts"
test — "Foundry Forge tests"
js — "Accompanying JavaScript helper library"
ext — "Extra tests"
audits — "Audit reports"
```

## Contributing

This repository serves as a laboratory for cutting edge snippets that may be merged into [Solmate](https://github.com/transmissions11/solmate).

Feel free to make a pull request.

Do refer to the [contribution guidelines](https://github.com/Vectorized/solady/issues/19) for more details.

## Safety

This is **experimental software** and is provided on an "as is" and "as available" basis.

We **do not give any warranties** and **will not be liable for any loss** incurred through any use of this codebase.

While Solady has been heavily tested, there may be parts that may exhibit unexpected emergent behavior when used with other code, or may break in future Solidity versions.  

Please always include your own thorough tests when using Solady to make sure it works correctly with your code.  

## Upgradability

Most contracts in Solady are compatible with both upgradeable and non-upgradeable (i.e. regular) contracts. 

Please call any required internal initialization methods accordingly.

## EVM Compatibility

Some parts of Solady may not be compatible with chains with partial EVM equivalence.

Please always check and test for compatibility accordingly.

## Acknowledgements

This repository is inspired by or directly modified from many sources, primarily:

- [Solmate](https://github.com/transmissions11/solmate)
- [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [ERC721A](https://github.com/chiru-labs/ERC721A)
- [Zolidity](https://github.com/z0r0z/zolidity)
- [🐍 Snekmate](https://github.com/pcaversaccio/snekmate)
- [Femplate](https://github.com/abigger87/femplate)

[npm-shield]: https://img.shields.io/npm/v/solady.svg
[npm-url]: https://www.npmjs.com/package/solady

[ci-shield]: https://img.shields.io/github/actions/workflow/status/vectorized/solady/ci.yml?branch=main&label=build
[ci-url]: https://github.com/vectorized/solady/actions/workflows/ci.yml

[solidity-shield]: https://img.shields.io/badge/solidity-%3E=0.8.4%20%3C=0.8.23-aa6746
[solidity-ci-url]: https://github.com/Vectorized/solady/actions/workflows/ci-all-via-ir.yml
