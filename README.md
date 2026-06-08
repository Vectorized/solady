# <img src="logo.svg" alt="solady" height="118" width="305"/>

[![NPM][npm-shield]][npm-url]
[![CI][ci-shield]][ci-url]
[![Solidity][solidity-shield]][solidity-ci-url]
[![Docs][docs-shield]][docs-url]

Gas optimized Solidity snippets.

I'm sooooooOooooooooOoooOoooooooooooooooo...

## Installation

To install with [**Foundry**](https://github.com/foundry-rs/foundry):

```sh
forge install vectorized/solady
```

To install with [**Hardhat**](https://github.com/nomiclabs/hardhat):

```sh
npm install solady
```

## Documentation

https://vectorized.github.io/solady

## Contracts

The Solidity smart contracts are located in the `src` directory.

```ml
accounts
├─ EIP7702Proxy — "Relay proxy for EIP7702 delegations"
├─ ERC1271 — "ERC1271 mixin with nested EIP-712 approach"
├─ ERC4337 — "Simple ERC4337 account implementation"
├─ ERC4337Factory — "Simple ERC4337 account factory implementation"
├─ ERC6551 — "Simple ERC6551 account implementation"
├─ ERC6551Proxy — "Relay proxy for upgradeable ERC6551 accounts"
├─ ERC7821 — "Minimal batch executor mixin"
├─ LibEIP7702 — "Library for EIP7702 operations"
├─ LibERC6551 — "Library for interacting with ERC6551 accounts"
├─ LibERC7579 — "Library for handling ERC7579 mode and execution data"
├─ Receiver — "Receiver mixin for ETH and safe-transferred ERC721 and ERC1155 tokens"
├─ Timelock — "Simple timelock"
auth
├─ EnumerableRoles — "Enumerable multiroles authorization mixin"
├─ Ownable — "Simple single owner authorization mixin"
├─ OwnableRoles — "Simple single owner and multiroles authorization mixin"
├─ TimedRoles — "Timed multiroles authorization mixin"
tokens
├─ ERC1155 — "Simple ERC1155 implementation"
├─ ERC20 — "Simple ERC20 + EIP-2612 + ERC-8255 implementation"
├─ ERC20Votes — "ERC20 with votes based on ERC5805 and ERC6372"
├─ ERC2981 — "Simple ERC2981 NFT Royalty Standard implementation"
├─ ERC4626 — "Simple ERC4626 tokenized Vault implementation"
├─ ERC6909 — "Simple EIP-6909 minimal multi-token implementation"
├─ ERC721 — "Simple ERC721 implementation with storage hitchhiking"
├─ WETH — "Simple Wrapped Ether implementation"
utils
├─ Base58 — "Library for Base58 encoding and decoding"
├─ Base64 — "Library for Base64 encoding and decoding"
├─ BlockHashLib — "Library for accessing block hashes way beyond the 256-block limit"
├─ CallContextChecker — "Call context checker mixin"
├─ CREATE3 — "Deterministic deployments agnostic to the initialization code"
├─ DateTimeLib — "Library for date time operations"
├─ DeploylessPredeployQueryer — "Deployless queryer for predeploys"
├─ DynamicArrayLib — "Library for memory arrays with automatic capacity resizing"
├─ DynamicBufferLib — "Library for buffers with automatic capacity resizing"
├─ ECDSA — "Library for verification of ECDSA signatures"
├─ EIP712 — "Contract for EIP-712 typed structured data hashing and signing"
├─ ERC1967Factory — "Factory for deploying and managing ERC1967 proxy contracts"
├─ ERC1967FactoryConstants — "The address and bytecode of the canonical ERC1967Factory"
├─ EfficientHashLib — "Library for efficiently performing keccak256 hashes"
├─ EnumerableMapLib — "Library for managing enumerable maps in storage"
├─ EnumerableSetLib — "Library for managing enumerable sets in storage"
├─ FixedPointMathLib — "Arithmetic library with operations for fixed-point numbers"
├─ GasBurnerLib — "Library for burning gas without reverting"
├─ Initializable — "Initializable mixin for the upgradeable contracts"
├─ JSONParserLib — "Library for parsing JSONs"
├─ LibBit — "Library for bit twiddling and boolean operations"
├─ LibBitmap — "Library for storage of packed booleans"
├─ LibClone — "Minimal proxy library"
├─ LibMap — "Library for storage of packed unsigned integers"
├─ LibPRNG — "Library for generating pseudorandom numbers"
├─ LibRLP — "Library for RLP encoding and CREATE address computation"
├─ LibSort — "Library for efficient sorting of memory arrays"
├─ LibStorage — "Library for basic storage operations"
├─ LibString — "Library for converting numbers into strings and other string operations"
├─ LibTransient — "Library for transient storage operations"
├─ LibZip — "Library for compressing and decompressing bytes"
├─ Lifebuoy — "Class that allows for rescue of ETH, ERC20, ERC721 tokens"
├─ MerkleProofLib — "Library for verification of Merkle proofs"
├─ MerkleTreeLib — "Library for generating Merkle trees"
├─ MetadataReaderLib — "Library for reading contract metadata robustly"
├─ MinHeapLib — "Library for managing a min-heap in storage or memory"
├─ Multicallable — "Contract that enables a single call to call multiple methods on itself"
├─ P256 — "Gas optimized P256 wrapper"
├─ RedBlackTreeLib — "Library for managing a red-black-tree in storage"
├─ ReentrancyGuard — "Reentrancy guard mixin"
├─ SSTORE2 — "Library for cheaper reads and writes to persistent storage"
├─ SafeCastLib — "Library for integer casting that reverts on overflow"
├─ SafeTransferLib — "Safe ERC20/ETH transfer lib that handles missing return values"
├─ SemVerLib — "Library for comparing SemVers"
├─ SignatureCheckerLib — "Library for verification of ECDSA and ERC1271 signatures"
├─ UUPSUpgradeable — "UUPS proxy mixin"
├─ UpgradeableBeacon — "Upgradeable beacon for ERC1967 beacon proxies"
├─ WebAuthn — "WebAuthn helper"
├─ legacy — "Legacy support"
├─ clz - "Libraries with clz opcode"
└─ ext — "Utilities for external protocols"
```

## Directories

```ml
src — "Solidity smart contracts"
test — "Foundry Forge tests"
js — "Accompanying JavaScript helper library"
ext — "Extra tests"
prep — "Preprocessing scripts"
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

If you are deploying on ZKsync stack (e.g. Abstract) with partial EVM equivalence:

- Run `node prep/zksync-compat-analysis.js` to scan the files.
- For files that have incompatibilities (i.e. non-zero scores), look into the `ext/zksync` directories for substitutes. The substitutes may only have a subset of the original features. If there is no substitute, it means that the file is incompatible and infeasible to be implemented for ZKsync.

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

[solidity-shield]: https://img.shields.io/badge/solidity-%3E=0.8.4%20%3C=0.8.30-aa6746
[solidity-ci-url]: https://github.com/Vectorized/solady/actions/workflows/ci-all-via-ir.yml

[docs-shield]: https://img.shields.io/badge/docs-%F0%9F%93%84-blue
[docs-url]: https://vectorized.github.io/solady
