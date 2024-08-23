---
eip: 9999
title: Minimal Upgradeable Proxies
description: Minimal upgradeable proxies with immutable arguments and support for onchain implementation queries
author: Atarpara (@Atarpara), JT Riley (@jtriley-eth), xiaobaiskill (@xiaobaiskill), Vectorized (@Vectorized)
discussions-to: https://ethereum-magicians.org/t/minimal-upgradeable-proxies/20868
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
2. Ability for immutable arguments to be queried onchain, as these arguments are stored at the same bytecode offset,
3. Ability for the implementation to be queried and verified onchain.

The minimal nature of the proxies enables cheaper deployment and runtime costs.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Overview

All of the following proxies MAY have optional data bytecode appended to the end of their runtime bytecode. 

### Minimal ERC-1967 transparent upgradeable proxy

This is the runtime bytecode:

```
3d3d336d________________________________________14605157363d3d37363d7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af43d6000803e604c573d6000fd5b3d6000f35b3d3560203555604080361115604c5736038060403d373d3d355af43d6000803e604c573d6000fd
```

where `________________________________________` is the 20-byte factory address.

The transparent upgradeable proxy MUST be deployed by a factory that is responsible for authenticating upgrades.

As the proxy's runtime bytecode contains logic to allow the factory to set any storage slot with any value, the initialization code MAY skip storing the implementation slot.

The upgrading logic does not emit the ERC-1967 event. Indexers MUST NOT expect the upgrading logic to emit the ERC-1967 events.

During upgrades, the factory MUST call the upgradeable proxy with following calldata:

```solidity
abi.encodePacked(
    // The new implementation address, converted to a 32-byte word.
    uint256(uint160(implementation)),
    // ERC-1967 implementation slot.
    bytes32(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc),
    // Optional calldata to be forwarded to the implementation
    // via delegatecall after setting the implementation slot.
    ""
)
```

Emitting the ERC-1967 events during initialization is OPTIONAL. Indexers MUST NOT expect the initialization code to emit the ERC-1967 events.

#### Minimal ERC-1967 transparent upgradeable proxy (14-byte factory address variant)

We provide a variant for a 14-byte factory address.

It is beneficial to install the factory at a vanity address with leading zero bytes so that the proxy's bytecode can be optimized to be shorter. 

This is the runtime bytecode:

```
3d3d3373____________________________14605757363d3d37363d7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af43d6000803e6052573d6000fd5b3d6000f35b3d356020355560408036111560525736038060403d373d3d355af43d6000803e6052573d6000fd
```

where `____________________________` is the 14-byte factory address.

Emitting the ERC-1967 events during initialization is OPTIONAL. Indexers MUST NOT expect the initialization code to emit the ERC-1967 events.

### Minimal ERC-1967 UUPS proxy

This is the runtime bytecode:

```
363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f3
```

During deployment, the initialization code MUST store the implementation at the ERC-1967 implementation storage slot `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`.

Emitting the ERC-1967 events during initialization is OPTIONAL. Indexers MUST NOT expect the initialization code to emit the ERC-1967 events.

#### Minimal ERC-1967 UUPS proxy (I-variant)

This is the runtime bytecode:

```
365814604357363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af43d6000803e603e573d6000fd5b3d6000f35b6020600f3d393d51543d52593df3
```

When called with any 1-byte calldata, the I-variant returns the address of the implementation, and will not forward the calldata to the implementation.

During deployment, the initialization code MUST store the implementation at the ERC-1967 implementation storage slot `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`.

Emitting the ERC-1967 events during initialization is OPTIONAL. Indexers MUST NOT expect the initialization code to emit the ERC-1967 events.

### Minimal ERC-1967 beacon proxy

This is the runtime bytecode:

```
363d3d373d3d363d602036600436635c60da1b60e01b36527fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50545afa5036515af43d6000803e604d573d6000fd5b3d6000f3
```

During deployment, the initialization code MUST store the beacon at the ERC-1967 beacon storage slot `0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50`.

Emitting the ERC-1967 events during initialization is OPTIONAL. Indexers MUST NOT expect the initialization code to emit the ERC-1967 events.

#### Minimal ERC-1967 beacon proxy (I-variant)

This is the runtime bytecode:

```
363d3d373d3d363d602036600436635c60da1b60e01b36527fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50545afa361460525736515af43d600060013e6052573d6001fd5b3d6001f3
```

When called with any 1-byte calldata, the I-variant returns the address of the implementation, and will not forward the calldata to the implementation.

During deployment, the initialization code MUST store the beacon at the ERC-1967 beacon storage slot `0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50`.

Emitting the ERC-1967 events during initialization is OPTIONAL. Indexers MUST NOT expect the initialization code to emit the ERC-1967 events.

## Rationale

### No usage of `PUSH0` opcode

For more widespread EVM compatibility, the proxies deliberately do not use the `PUSH0` opcode proposed in [EIP-3855](./eip-3855.md).

Converting the proxies to `PUSH0` variants may be done in a separate future ERC.

### Optimization priorities

The proxies are first optimized for minimal runtime gas before minimal bytecode size.

### Transparent upgradeable proxy

The factory address in the transparent upgradeable proxy is baked into the immutable bytecode of the minimal transparent upgradeable proxy.

This is to save a `SLOAD` for every proxy call.

As the factory can contain custom authorization logic that allows for admin rotation, we do not lose any flexibility.

The upgrade logic takes in any 32 byte value and 32 byte storage slot. This is for flexibility and bytecode conciseness.

We do not lose any security as the implementation can still modify any storage slot.

### I-variants 

The so-called "I-variants" contain logic that returns the implementation address baked into the proxy bytecode.

This allows contracts to retrieve the implementation of the proxy onchain in a verifiable way.

As long as the proxy's runtime bytecode starts with the bytecode in this standard, we can be sure that the implementation address is not spoofed.

The choice of reserving 1-byte calldata to denote an implementation query request is for efficiency and to prevent calldata collision. Regular ETH transfers use 0-byte calldata, and regular Solidity function calls use calldata that is 4 bytes or longer.

### Omission of events in bytecode

This is for minimal bytecode size and deployment costs. 

Most block explorers and indexers are able to deduce the latest implementation without the use of events simply by reading the slots.

### Immutable arguments are not appended to forwarded calldata

This is to avoid compatibility and safety issues with other ERC standards that append extra data to the calldata.

The `EXTCODECOPY` opcode can be used to retrieve the immutable arguments.

## Backwards Compatibility

No backward compatibility issues found.

## Reference Implementation

### Minimal ERC-1967 transparent upgradeable proxy implementation


```solidity
pragma solidity ^0.8.0;

library ERC1967MinimalTransparentUpgradeableProxyLib {
    function initCodeFor20ByteFactoryAddress() internal view returns (bytes memory) {
        return abi.encodePacked(
            bytes13(0x607f3d8160093d39f33d3d3373),
            address(this),
            bytes32(0x14605757363d3d37363d7f360894a13ba1a3210667c828492db98dca3e2076cc),
            bytes32(0x3735a920a3ca505d382bbc545af43d6000803e6052573d6000fd5b3d6000f35b),
            bytes32(0x3d356020355560408036111560525736038060403d373d3d355af43d6000803e),
            bytes7(0x6052573d6000fd)
        );
    }

    function initCodeFor14ByteFactoryAddress() internal view returns (bytes memory) {
        return abi.encodePacked(
            bytes13(0x60793d8160093d39f33d3d336d),
            uint112(uint160(address(this))),
            bytes32(0x14605157363d3d37363d7f360894a13ba1a3210667c828492db98dca3e2076cc),
            bytes32(0x3735a920a3ca505d382bbc545af43d6000803e604c573d6000fd5b3d6000f35b),
            bytes32(0x3d3560203555604080361115604c5736038060403d373d3d355af43d6000803e),
            bytes7(0x604c573d6000fd)
        );
    }

    function initCode() internal view returns (bytes memory) {
        if (uint160(address(this)) >> 112 != 0) {
            return initCodeFor20ByteFactoryAddress();
        } else {
            return initCodeFor14ByteFactoryAddress();
        }
    }

    function deploy(address implementation) internal returns (address instance) {
        bytes memory m = initCode();
        assembly {
            instance := create(0, add(m, 0x20), mload(m))
        }
        require(instance != address(0), "Deployment failed.");
        (bool success,) = instance.call(
            abi.encodePacked(
                // The new implementation address, converted to a 32-byte word.
                uint256(uint160(implementation)),
                // ERC-1967 implementation slot.
                bytes32(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc),
                // Optional calldata to be forwarded to the implementation
                // via delegatecall after setting the implementation slot.
                ""
            )
        );
        require(success, "Initialization failed.");
    }
}
```

### Minimal ERC-1967 UUPS proxy implementation

```solidity
pragma solidity ^0.8.0;

library ERC1967MinimalUUPSProxyLib {
    function initCode(address implementation, bytes memory args)
        internal
        pure
        returns (bytes memory)
    {
        uint256 n = 0x003d + args.length;
        require(n <= 0xffff, "Immutable args too long.");
        return abi.encodePacked(
            bytes1(0x61),
            uint16(n),
            bytes7(0x3d8160233d3973),
            implementation,
            bytes2(0x6009),
            bytes32(0x5155f3363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076),
            bytes32(0xcc3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f3),
            args
        );
    }

    function deploy(address implementation, bytes memory args)
        internal
        returns (address instance)
    {
        bytes memory m = initCode(implementation, args);
        assembly {
            instance := create(0, add(m, 0x20), mload(m))
        }
        require(instance != address(0), "Deployment failed.");
    }
}
```

#### Minimal ERC-1967 UUPS proxy implementation (I-variant)

```solidity
pragma solidity ^0.8.0;

library ERC1967IMinimalUUPSProxyLib {
    function initCode(address implementation, bytes memory args)
        internal
        pure
        returns (bytes memory)
    {
        uint256 n = 0x0052 + args.length;
        require(n <= 0xffff, "Immutable args too long.");
        return abi.encodePacked(
            bytes1(0x61),
            uint16(n),
            bytes7(0x3d8160233d3973),
            implementation,
            bytes23(0x600f5155f3365814604357363d3d373d3d363d7f360894),
            bytes32(0xa13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af4),
            bytes32(0x3d6000803e603e573d6000fd5b3d6000f35b6020600f3d393d51543d52593df3),
            args
        );
    }

    function deploy(address implementation, bytes memory args)
        internal
        returns (address instance)
    {
        bytes memory m = initCode(implementation, args);
        assembly {
            instance := create(0, add(m, 0x20), mload(m))
        }
        require(instance != address(0), "Deployment failed.");
    }
}
```

### Minimal ERC-1967 beacon proxy implementation

```solidity
pragma solidity ^0.8.0;

library ERC1967MinimalBeaconProxyLib {
    function initCode(address beacon, bytes memory args) internal pure returns (bytes memory) {
        uint256 n = 0x0052 + args.length;
        require(n <= 0xffff, "Immutable args too long.");
        return abi.encodePacked(
            bytes1(0x61),
            uint16(n),
            bytes7(0x3d8160233d3973),
            beacon,
            bytes23(0x60195155f3363d3d373d3d363d602036600436635c60da),
            bytes32(0x1b60e01b36527fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6c),
            bytes32(0xb3582b35133d50545afa5036515af43d6000803e604d573d6000fd5b3d6000f3),
            args
        );
    }

    function deploy(address beacon, bytes memory args) internal returns (address instance) {
        bytes memory m = initCode(beacon, args);
        assembly {
            instance := create(0, add(m, 0x20), mload(m))
        }
        require(instance != address(0), "Deployment failed.");
    }
}
```

#### Minimal ERC-1967 beacon proxy implementation (I-variant)

```solidity
pragma solidity ^0.8.0;

library ERC1967IMinimalBeaconProxyLib {
    function initCode(address beacon, bytes memory args) internal pure returns (bytes memory) {
        uint256 n = 0x0057 + args.length;
        require(n <= 0xffff, "Immutable args too long.");
        return abi.encodePacked(
            bytes1(0x61),
            uint16(n),
            bytes7(0x3d8160233d3973),
            beacon,
            bytes28(0x60195155f3363d3d373d3d363d602036600436635c60da1b60e01b36),
            bytes32(0x527fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b3513),
            bytes32(0x3d50545afa361460525736515af43d600060013e6052573d6001fd5b3d6001f3),
            args
        );
    }

    function deploy(address beacon, bytes memory args) internal returns (address instance) {
        bytes memory m = initCode(beacon, args);
        assembly {
            instance := create(0, add(m, 0x20), mload(m))
        }
        require(instance != address(0), "Deployment failed.");
    }
}
```

## Security Considerations

### Transparent upgradeable proxy factory security considerations

The transparent upgradeable proxy factory must implement proper access control to allow only authorized accounts to upgrade proxies.

### Calldata length collision for I-variants

The I-variants reserve all calldata of length 1 to denote a request to return the implementation. This may pose compatibility issues if the underlying implementation actually uses 1-byte calldata for special purposes.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
