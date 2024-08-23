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

### Overview

All of the following proxies MAY have optional data bytecode appended to the end of their runtime bytecode.

During deployment, the initialization code MUST store the implementation at the ERC-1967 implementation storage slot `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`.

Emitting the ERC-1967 events during initialization is OPTIONAL. Indexers MUST NOT expect the initialization code to emit the ERC-1967 events.

### Minimal ERC-1967 transparent upgradeable proxy

This is the runtime bytecode:

```
3d3d336d________________________________________14605157363d3d37363d7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af43d6000803e604c573d6000fd5b3d6000f35b3d3560203555604080361115604c5736038060403d373d3d355af43d6000803e604c573d6000fd
```

where `________________________________________` is the 20-byte factory address.

The transparent upgradeable proxy MUST be deployed by a factory that is responsible for authenticating upgrades.

During upgrades, the factory MUST call the upgradeable proxy with following calldata:

```solidity
abi.encode(
	newImplementation,
	// ERC-1967 implementation slot.
	0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
)
```

#### Minimal ERC-1967 transparent upgradeable proxy (14-byte factory address variant)

We provide a variant for a 14-byte factory address.

It is beneficial to install the factory at a vanity address with leading zero bytes so that the proxy's bytecode can be optimized to be shorter. 

This is the runtime bytecode:

```
3d3d3373____________________________14605757363d3d37363d7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af43d6000803e6052573d6000fd5b3d6000f35b3d356020355560408036111560525736038060403d373d3d355af43d6000803e6052573d6000fd
```

where `____________________________` is the 14-byte factory address.

### Minimal ERC-1967 UUPS proxy

This is the runtime bytecode:

```
363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f3
```

#### Minimal ERC-1967 UUPS proxy (I-variant)

This is the runtime bytecode:

```
365814604357363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af43d6000803e603e573d6000fd5b3d6000f35b6020600f3d393d51543d52593df3
```

### Minimal ERC-1967 beacon proxy

This is the runtime bytecode:

```
363d3d373d3d363d602036600436635c60da1b60e01b36527fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50545afa5036515af43d6000803e604d573d6000fd5b3d6000f3
```

#### Minimal ERC-1967 beacon proxy (I-variant)

This is the runtime bytecode:

```
363d3d373d3d363d602036600436635c60da1b60e01b36527fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50545afa361460525736515af43d600060013e6052573d6001fd5b3d6001f3
```

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
