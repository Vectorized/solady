# SSTORE2

Read and write to persistent storage at a fraction of the cost.






<!-- customintro:start --><!-- customintro:end -->

## Constants

### CREATE3_PROXY_INITCODE_HASH

```solidity
bytes32 internal constant CREATE3_PROXY_INITCODE_HASH =
    0x21c35dbe1b344a2488cf3321d6ce542f8e9f305544ff09e4993a62319a497c1f
```

Hash of the `_CREATE3_PROXY_INITCODE`.   
Equivalent to `keccak256(abi.encodePacked(hex"67363d3d37363d34f03d5260086018f3"))`.

## Custom Errors

### DeploymentFailed()

```solidity
error DeploymentFailed()
```

Unable to deploy the storage contract.

## Write Logic

### write(bytes)

```solidity
function write(bytes memory data) internal returns (address pointer)
```

Writes `data` into the bytecode of a storage contract and returns its address.

### writeCounterfactual(bytes,bytes32)

```solidity
function writeCounterfactual(bytes memory data, bytes32 salt)
    internal
    returns (address pointer)
```

Writes `data` into the bytecode of a storage contract with `salt`   
and returns its normal CREATE2 deterministic address.

### writeDeterministic(bytes,bytes32)

```solidity
function writeDeterministic(bytes memory data, bytes32 salt)
    internal
    returns (address pointer)
```

Writes `data` into the bytecode of a storage contract and returns its address.   
This uses the so-called "CREATE3" workflow,   
which means that `pointer` is agnostic to `data, and only depends on `salt`.

## Address Calculations

### initCodeHash(bytes)

```solidity
function initCodeHash(bytes memory data)
    internal
    pure
    returns (bytes32 hash)
```

Returns the initialization code hash of the storage contract for `data`.   
Used for mining vanity addresses with create2crunch.

### predictCounterfactualAddress(bytes,bytes32)

```solidity
function predictCounterfactualAddress(bytes memory data, bytes32 salt)
    internal
    view
    returns (address pointer)
```

Equivalent to `predictCounterfactualAddress(data, salt, address(this))`

### predictCounterfactualAddress(bytes,bytes32,address)

```solidity
function predictCounterfactualAddress(
    bytes memory data,
    bytes32 salt,
    address deployer
) internal pure returns (address predicted)
```

Returns the CREATE2 address of the storage contract for `data`   
deployed with `salt` by `deployer`.   
Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.

### predictDeterministicAddress(bytes32)

```solidity
function predictDeterministicAddress(bytes32 salt)
    internal
    view
    returns (address pointer)
```

Equivalent to `predictDeterministicAddress(salt, address(this))`.

### predictDeterministicAddress(bytes32,address)

```solidity
function predictDeterministicAddress(bytes32 salt, address deployer)
    internal
    pure
    returns (address pointer)
```

Returns the "CREATE3" deterministic address for `salt` with `deployer`.

## Read Logic

### read(address)

```solidity
function read(address pointer) internal view returns (bytes memory data)
```

Equivalent to `read(pointer, 0, 2 ** 256 - 1)`.

### read(address,uint256)

```solidity
function read(address pointer, uint256 start)
    internal
    view
    returns (bytes memory data)
```

Equivalent to `read(pointer, start, 2 ** 256 - 1)`.

### read(address,uint256,uint256)

```solidity
function read(address pointer, uint256 start, uint256 end)
    internal
    view
    returns (bytes memory data)
```

Returns a slice of the data on `pointer` from `start` to `end`.   
`start` and `end` will be clamped to the range `[0, args.length]`.   
The `pointer` MUST be deployed via the SSTORE2 write functions.   
Otherwise, the behavior is undefined.   
Out-of-gas reverts if `pointer` does not have any code.