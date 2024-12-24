# CREATE3

Deterministic deployments agnostic to the initialization code.






<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### DeploymentFailed()

```solidity
error DeploymentFailed()
```

Unable to deploy the contract.

## Bytecode Constants

### PROXY_INITCODE_HASH

```solidity
bytes32 internal constant PROXY_INITCODE_HASH =
    0x21c35dbe1b344a2488cf3321d6ce542f8e9f305544ff09e4993a62319a497c1f
```

Hash of the `_PROXY_INITCODE`.   
Equivalent to `keccak256(abi.encodePacked(hex"67363d3d37363d34f03d5260086018f3"))`.

## CREATE3 Operations

### deployDeterministic(bytes,bytes32)

```solidity
function deployDeterministic(bytes memory initCode, bytes32 salt)
    internal
    returns (address deployed)
```

Deploys `initCode` deterministically with a `salt`.   
Returns the deterministic address of the deployed contract,   
which solely depends on `salt`.

### deployDeterministic(uint256,bytes,bytes32)

```solidity
function deployDeterministic(
    uint256 value,
    bytes memory initCode,
    bytes32 salt
) internal returns (address deployed)
```

Deploys `initCode` deterministically with a `salt`.   
The deployed contract is funded with `value` (in wei) ETH.   
Returns the deterministic address of the deployed contract,   
which solely depends on `salt`.

### predictDeterministicAddress(bytes32)

```solidity
function predictDeterministicAddress(bytes32 salt)
    internal
    view
    returns (address deployed)
```

Returns the deterministic address for `salt`.

### predictDeterministicAddress(bytes32,address)

```solidity
function predictDeterministicAddress(bytes32 salt, address deployer)
    internal
    pure
    returns (address deployed)
```

Returns the deterministic address for `salt` with `deployer`.