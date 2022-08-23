# solady

Gas optimized Solidity snippets.

I'm sooooooOooooooooOoooOoooooooooooooooo...

## Contracts

```ml
auth
├─ OwnableRoles — "Simple single owner and multiroles authorization mixin"
utils
├─ MerkleProofLib — "Library for verification of Merkle proofs"
├─ SignatureCheckerLib — "Library for verification of ECDSA and ERC1271 signatures"
├─ ECDSA — "Library for verification of ECDSA signatures"
├─ Sort — "Optimized intro sort"
├─ Base64 — "Library for Base64 encoding"
├─ SSTORE2 — "Library for cheaper reads and writes to persistent storage"
├─ CREATE3 — "Deploy to deterministic addresses without an initcode factor"
├─ LibRLP — "Library for computing contract addresses from their deployer and nonce"
├─ LibClone — "Minimal proxy library using the 0age pattern"
├─ LibString — "Library for converting numbers into strings and other string operations"
├─ LibBitmap — "Library for mapping integers to single bit booleans"
├─ LibBytemap — "Library for mapping integers to 8 bit unsigned integers"
├─ Multicallable — "Contract that enables a single call to call multiple methods on itself"
├─ SafeTransferLib — "Safe ERC20/ETH transfer lib that handles missing return values"
```

## Contributing

This repository serves as a laboratory for cutting edge snippets that may be merged into [Solmate](https://github.com/rari-capital/solmate).

Feel free to make a pull request.

Do refer to the [contribution guidelines](https://github.com/Vectorized/solady/issues/19) for more details.

## Safety

This is **experimental software** and is provided on an "as is" and "as available" basis.

We **do not give any warranties** and **will not be liable for any loss** incurred through any use of this codebase.

## Installation

To install with [**Foundry**](https://github.com/gakonst/foundry):

```sh
forge install vectorized/solady
```

To install with [**Hardhat**](https://github.com/nomiclabs/hardhat) or [**Truffle**](https://github.com/trufflesuite/truffle):

```sh
npm install solady
```

## Acknowledgements

This repository is inspired by or directly modified from many sources, primarily:

- [Solmate](https://github.com/rari-capital/solmate)
- [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [ERC721A](https://github.com/chiru-labs/ERC721A)
- [Zolidity](https://github.com/z0r0z/zolidity)
- [🐍 Snekmate](https://github.com/pcaversaccio/snekmate)
- [Femplate](https://github.com/abigger87/femplate)
