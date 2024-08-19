---
eip: 9999
title: Minimal Upgradeable Proxies
author: Atarpara (@Atarpara), JT Riley (@jtriley-eth), Vectorized (@Vectorized)
discussions-to: https://ethereum-magicians.org/t/minimal-upgrad
status: Draft
type: Standards Track
category: ERC
created: 2024-08-19
requires: 1967
---

## Abstract

This standard defines minimal [ERC-1967](./eip-1967.md) proxies for three patterns: (1) transparent, (2) UUPS, (3) beacon. The proxies support optional immutable arguments which are appended to the end of their runtime bytecode. Additional variants which support onchain implementation querying are provided.

## Motivation

Having standardized minimal bytecode for upgradeable proxies enables the following:

1. Automatic verification on block explorers.
2. Ability for immutable arguments to be queried onchain, as these arguments are stored in the same bytecode offset,
3. Ability for the implementation to be queried and verified onchain.

The minimal nature of the proxies enables cheaper deployment and runtime costs.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Minimal ERC-1967 transparent upgradeable proxy

<!-- Insert runtime bytecode for 20-byte factory address here, no need for the table -->

<!-- Insert runtime bytecode for 14-byte factory address here, no need for the table -->

#### Minimal ERC-1967 transparent upgradeable proxy (I-variant)

<!-- Insert runtime bytecode for 20-byte factory address here, no need for the table -->

<!-- Insert runtime bytecode for 14-byte factory address here, no need for the table -->

### Minimal ERC-1967 UUPS proxy

<!-- Insert runtime bytecode here, no need for the table -->

#### Minimal ERC-1967 UUPS proxy (I-variant)

<!-- Insert runtime bytecode here, no need for the table -->

### Minimal ERC-1967 beacon proxy

<!-- Insert runtime bytecode here, no need for the table -->

#### Minimal ERC-1967 beacon proxy (I-variant)

<!-- Insert runtime bytecode here, no need for the table -->

## Rationale

### Optimization priorities

<!-- Bytecode size before runtime gas. -->
<!-- No PUSH0 for widespread compatibility. -->

### Immutable admin in transparent upgradeable proxy

<!-- Insert explanation about saving deployment and runtime costs. -->
<!-- Insert argument that the admin can be a multisig or a factory, which can allow for keys to be rotated. -->

### I-variants 

<!-- Insert explanation the implementation being able to spoof the implementation. -->

### Omission of events in bytecode

<!-- Insert explanation about events being optional. -->

### Immutable arguments are not appended to forwarded calldata

<!-- Insert explanation about potential danger with ERC-2771. -->
<!-- Insert explanation about extcodecopy. -->

## Backwards Compatibility

No backward compatibility issues found.

## Reference Implementation

### Minimal ERC-1967 transparent upgradeable proxy implementation

<!-- Insert solidity function to return the creation code here. Add in the table. -->

#### Minimal ERC-1967 transparent upgradeable proxy implementation (I-variant)

<!-- Insert solidity function to return the creation code here. Add in the table. -->

### Minimal ERC-1967 UUPS proxy implementation

<!-- Insert solidity function to return the creation code here. Add in the table. -->

#### Minimal ERC-1967 UUPS proxy implementation (I-variant)

<!-- Insert solidity function to return the creation code here. Add in the table. -->

### Minimal ERC-1967 beacon proxy implementation

<!-- Insert solidity function to return the creation code here. Add in the table. -->

#### Minimal ERC-1967 beacon proxy implementation (I-variant)

<!-- Insert solidity function to return the creation code here. Add in the table. -->

## Security Considerations

<!-- Insert warning about incompatibility with implementations that use one-byte calldata for special purposes. -->

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
