# Overview

Solady offers highly-optimized Solidity snippets with flexible, easy-to-use APIs.

## Installation

To install with [**Foundry**](https://github.com/gakonst/foundry):

```sh
forge install vectorized/solady
```

To install with [**Hardhat**](https://github.com/nomiclabs/hardhat) or [**Truffle**](https://github.com/trufflesuite/truffle):

```sh
npm install solady
```

## Principles

Formless precision.

Disciplined freedom.

## Upgradability

Most contracts in Solady are compatible with both upgradeable and non-upgradeable (i.e. regular) contracts. 

Please call any required internal initialization methods accordingly.

## EVM Compatibility

Some parts of Solady may not be compatible with chains with partial EVM equivalence.

Please always check and test for compatibility accordingly.