# LibClone

Minimal proxy library.


<b>Minimal proxy:</b>

Although the sw0nt pattern saves 5 gas over the ERC1167 pattern during runtime,
it is not supported out-of-the-box on Etherscan. Hence, we choose to use the 0age pattern,
which saves 4 gas over the ERC1167 pattern during runtime, and has the smallest bytecode.
- Automatically verified on Etherscan.

<b>Minimal proxy (PUSH0 variant):</b>

This is a new minimal proxy that uses the PUSH0 opcode introduced during Shanghai.
It is optimized first for minimal runtime gas, then for minimal bytecode.
The PUSH0 clone functions are intentionally postfixed with a jarring "_PUSH0" as
many EVM chains may not support the PUSH0 opcode in the early months after Shanghai.
Please use with caution.
- Automatically verified on Etherscan.

<b>Clones with immutable args (CWIA):</b>

The implementation of CWIA here does NOT append the immutable args into the calldata
passed into delegatecall. It is simply an ERC1167 minimal proxy with the immutable arguments
appended to the back of the runtime bytecode.
- Uses the identity precompile (0x4) to copy args during deployment.

<b>Minimal ERC1967 proxy:</b>

A minimal ERC1967 proxy, intended to be upgraded with UUPS.
This is NOT the same as ERC1967Factory's transparent proxy, which includes admin logic.
- Automatically verified on Etherscan.

<b>Minimal ERC1967 proxy with immutable args:</b>

- Uses the identity precompile (0x4) to copy args during deployment.
- Automatically verified on Etherscan.

<b>ERC1967I proxy:</b>

A variant of the minimal ERC1967 proxy, with a special code path that activates
if `calldatasize() == 1`. This code path skips the delegatecall and directly returns the
`implementation` address. The returned implementation is guaranteed to be valid if the
keccak256 of the proxy's code is equal to `ERC1967I_CODE_HASH`.

<b>ERC1967I proxy with immutable args:</b>

A variant of the minimal ERC1967 proxy, with a special code path that activates
if `calldatasize() == 1`. This code path skips the delegatecall and directly returns the
- Uses the identity precompile (0x4) to copy args during deployment.

<b>Minimal ERC1967 beacon proxy:</b>

A minimal beacon proxy, intended to be upgraded with an upgradable beacon.
- Automatically verified on Etherscan.

<b>Minimal ERC1967 beacon proxy with immutable args:</b>

- Uses the identity precompile (0x4) to copy args during deployment.
- Automatically verified on Etherscan.

<b>ERC1967I beacon proxy:</b>

A variant of the minimal ERC1967 beacon proxy, with a special code path that activates
if `calldatasize() == 1`. This code path skips the delegatecall and directly returns the
`implementation` address. The returned implementation is guaranteed to be valid if the
keccak256 of the proxy's code is equal to `ERC1967I_CODE_HASH`.

<b>ERC1967I proxy with immutable args:</b>

A variant of the minimal ERC1967 beacon proxy, with a special code path that activates
if `calldatasize() == 1`. This code path skips the delegatecall and directly returns the
- Uses the identity precompile (0x4) to copy args during deployment.



<!-- customintro:start --><!-- customintro:end -->

## Constants

### CLONE_CODE_HASH

```solidity
bytes32 internal constant CLONE_CODE_HASH =
    0x48db2cfdb2853fce0b464f1f93a1996469459df3ab6c812106074c4106a1eb1f
```

The keccak256 of deployed code for the clone proxy,   
with the implementation set to `address(0)`.

### PUSH0_CLONE_CODE_HASH

```solidity
bytes32 internal constant PUSH0_CLONE_CODE_HASH =
    0x67bc6bde1b84d66e267c718ba44cf3928a615d29885537955cb43d44b3e789dc
```

The keccak256 of deployed code for the PUSH0 proxy,   
with the implementation set to `address(0)`.

### CWIA_CODE_HASH

```solidity
bytes32 internal constant CWIA_CODE_HASH =
    0x3cf92464268225a4513da40a34d967354684c32cd0edd67b5f668dfe3550e940
```

The keccak256 of deployed code for the ERC-1167 CWIA proxy,   
with the implementation set to `address(0)`.

### ERC1967_CODE_HASH

```solidity
bytes32 internal constant ERC1967_CODE_HASH =
    0xaaa52c8cc8a0e3fd27ce756cc6b4e70c51423e9b597b11f32d3e49f8b1fc890d
```

The keccak256 of the deployed code for the ERC1967 proxy.

### ERC1967I_CODE_HASH

```solidity
bytes32 internal constant ERC1967I_CODE_HASH =
    0xce700223c0d4cea4583409accfc45adac4a093b3519998a9cbbe1504dadba6f7
```

The keccak256 of the deployed code for the ERC1967I proxy.

### ERC1967_BEACON_PROXY_CODE_HASH

```solidity
bytes32 internal constant ERC1967_BEACON_PROXY_CODE_HASH =
    0x14044459af17bc4f0f5aa2f658cb692add77d1302c29fe2aebab005eea9d1162
```

The keccak256 of the deployed code for the ERC1967 beacon proxy.

### ERC1967I_BEACON_PROXY_CODE_HASH

```solidity
bytes32 internal constant ERC1967I_BEACON_PROXY_CODE_HASH =
    0xf8c46d2793d5aa984eb827aeaba4b63aedcab80119212fce827309788735519a
```

The keccak256 of the deployed code for the ERC1967 beacon proxy.

## Custom Errors

### DeploymentFailed()

```solidity
error DeploymentFailed()
```

Unable to deploy the clone.

### SaltDoesNotStartWith()

```solidity
error SaltDoesNotStartWith()
```

The salt must start with either the zero address or `by`.

### ETHTransferFailed()

```solidity
error ETHTransferFailed()
```

The ETH transfer has failed.

## Minimal Proxy Operations

### clone(address)

```solidity
function clone(address implementation)
    internal
    returns (address instance)
```

Deploys a clone of `implementation`.

### clone(uint256,address)

```solidity
function clone(uint256 value, address implementation)
    internal
    returns (address instance)
```

Deploys a clone of `implementation`.   
Deposits `value` ETH during deployment.

### cloneDeterministic(address,bytes32)

```solidity
function cloneDeterministic(address implementation, bytes32 salt)
    internal
    returns (address instance)
```

Deploys a deterministic clone of `implementation` with `salt`.

### cloneDeterministic(uint256,address,bytes32)

```solidity
function cloneDeterministic(
    uint256 value,
    address implementation,
    bytes32 salt
) internal returns (address instance)
```

Deploys a deterministic clone of `implementation` with `salt`.   
Deposits `value` ETH during deployment.

### initCode(address)

```solidity
function initCode(address implementation)
    internal
    pure
    returns (bytes memory c)
```

Returns the initialization code of the clone of `implementation`.

### initCodeHash(address)

```solidity
function initCodeHash(address implementation)
    internal
    pure
    returns (bytes32 hash)
```

Returns the initialization code hash of the clone of `implementation`.

### predictDeterministicAddress(address,bytes32,address)

```solidity
function predictDeterministicAddress(
    address implementation,
    bytes32 salt,
    address deployer
) internal pure returns (address predicted)
```

Returns the address of the clone of `implementation`, with `salt` by `deployer`.   
Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.

## Minimal Proxy Operations (PUSH0 Variant)

### clone_PUSH0(address)

```solidity
function clone_PUSH0(address implementation)
    internal
    returns (address instance)
```

Deploys a PUSH0 clone of `implementation`.

### clone_PUSH0(uint256,address)

```solidity
function clone_PUSH0(uint256 value, address implementation)
    internal
    returns (address instance)
```

Deploys a PUSH0 clone of `implementation`.   
Deposits `value` ETH during deployment.

### cloneDeterministic_PUSH0(address,bytes32)

```solidity
function cloneDeterministic_PUSH0(address implementation, bytes32 salt)
    internal
    returns (address instance)
```

Deploys a deterministic PUSH0 clone of `implementation` with `salt`.

### cloneDeterministic_PUSH0(uint256,address,bytes32)

```solidity
function cloneDeterministic_PUSH0(
    uint256 value,
    address implementation,
    bytes32 salt
) internal returns (address instance)
```

Deploys a deterministic PUSH0 clone of `implementation` with `salt`.   
Deposits `value` ETH during deployment.

### initCode_PUSH0(address)

```solidity
function initCode_PUSH0(address implementation)
    internal
    pure
    returns (bytes memory c)
```

Returns the initialization code of the PUSH0 clone of `implementation`.

### initCodeHash_PUSH0(address)

```solidity
function initCodeHash_PUSH0(address implementation)
    internal
    pure
    returns (bytes32 hash)
```

Returns the initialization code hash of the PUSH0 clone of `implementation`.

### predictDeterministicAddress_PUSH0(address,bytes32,address)

```solidity
function predictDeterministicAddress_PUSH0(
    address implementation,
    bytes32 salt,
    address deployer
) internal pure returns (address predicted)
```

Returns the address of the PUSH0 clone of `implementation`, with `salt` by `deployer`.   
Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.

## Clones With Immutable Args Operations

### clone(address,bytes)

```solidity
function clone(address implementation, bytes memory args)
    internal
    returns (address instance)
```

Deploys a clone of `implementation` with immutable arguments encoded in `args`.

### clone(uint256,address,bytes)

```solidity
function clone(uint256 value, address implementation, bytes memory args)
    internal
    returns (address instance)
```

Deploys a clone of `implementation` with immutable arguments encoded in `args`.   
Deposits `value` ETH during deployment.

### cloneDeterministic(address,bytes,bytes32)

```solidity
function cloneDeterministic(
    address implementation,
    bytes memory args,
    bytes32 salt
) internal returns (address instance)
```

Deploys a deterministic clone of `implementation`   
with immutable arguments encoded in `args` and `salt`.

### cloneDeterministic(uint256,address,bytes,bytes32)

```solidity
function cloneDeterministic(
    uint256 value,
    address implementation,
    bytes memory args,
    bytes32 salt
) internal returns (address instance)
```

Deploys a deterministic clone of `implementation`   
with immutable arguments encoded in `args` and `salt`.

### createDeterministicClone(address,bytes,bytes32)

```solidity
function createDeterministicClone(
    address implementation,
    bytes memory args,
    bytes32 salt
) internal returns (bool alreadyDeployed, address instance)
```

Deploys a deterministic clone of `implementation`   
with immutable arguments encoded in `args` and `salt`.   
This method does not revert if the clone has already been deployed.

### createDeterministicClone(uint256,address,bytes,bytes32)

```solidity
function createDeterministicClone(
    uint256 value,
    address implementation,
    bytes memory args,
    bytes32 salt
) internal returns (bool alreadyDeployed, address instance)
```

Deploys a deterministic clone of `implementation`   
with immutable arguments encoded in `args` and `salt`.   
This method does not revert if the clone has already been deployed.

### initCode(address,bytes)

```solidity
function initCode(address implementation, bytes memory args)
    internal
    pure
    returns (bytes memory c)
```

Returns the initialization code of the clone of `implementation`   
using immutable arguments encoded in `args`.

### initCodeHash(address,bytes)

```solidity
function initCodeHash(address implementation, bytes memory args)
    internal
    pure
    returns (bytes32 hash)
```

Returns the initialization code hash of the clone of `implementation`   
using immutable arguments encoded in `args`.

### predictDeterministicAddress(address,bytes,bytes32,address)

```solidity
function predictDeterministicAddress(
    address implementation,
    bytes memory data,
    bytes32 salt,
    address deployer
) internal pure returns (address predicted)
```

Returns the address of the clone of   
`implementation` using immutable arguments encoded in `args`, with `salt`, by `deployer`.   
Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.

### argsOnClone(address)

```solidity
function argsOnClone(address instance)
    internal
    view
    returns (bytes memory args)
```

Equivalent to `argsOnClone(instance, 0, 2 ** 256 - 1)`.

### argsOnClone(address,uint256)

```solidity
function argsOnClone(address instance, uint256 start)
    internal
    view
    returns (bytes memory args)
```

Equivalent to `argsOnClone(instance, start, 2 ** 256 - 1)`.

### argsOnClone(address,uint256,uint256)

```solidity
function argsOnClone(address instance, uint256 start, uint256 end)
    internal
    view
    returns (bytes memory args)
```

Returns a slice of the immutable arguments on `instance` from `start` to `end`.   
`start` and `end` will be clamped to the range `[0, args.length]`.   
The `instance` MUST be deployed via the clone with immutable args functions.   
Otherwise, the behavior is undefined.   
Out-of-gas reverts if `instance` does not have any code.

## Minimal ERC1967 Proxy Operations

Note: The ERC1967 proxy here is intended to be upgraded with UUPS.   
This is NOT the same as ERC1967Factory's transparent proxy, which includes admin logic.

### deployERC1967(address)

```solidity
function deployERC1967(address implementation)
    internal
    returns (address instance)
```

Deploys a minimal ERC1967 proxy with `implementation`.

### deployERC1967(uint256,address)

```solidity
function deployERC1967(uint256 value, address implementation)
    internal
    returns (address instance)
```

Deploys a minimal ERC1967 proxy with `implementation`.   
Deposits `value` ETH during deployment.

### deployDeterministicERC1967(address,bytes32)

```solidity
function deployDeterministicERC1967(address implementation, bytes32 salt)
    internal
    returns (address instance)
```

Deploys a deterministic minimal ERC1967 proxy with `implementation` and `salt`.

### deployDeterministicERC1967(uint256,address,bytes32)

```solidity
function deployDeterministicERC1967(
    uint256 value,
    address implementation,
    bytes32 salt
) internal returns (address instance)
```

Deploys a deterministic minimal ERC1967 proxy with `implementation` and `salt`.   
Deposits `value` ETH during deployment.

### createDeterministicERC1967(address,bytes32)

```solidity
function createDeterministicERC1967(address implementation, bytes32 salt)
    internal
    returns (bool alreadyDeployed, address instance)
```

Creates a deterministic minimal ERC1967 proxy with `implementation` and `salt`.   
Note: This method is intended for use in ERC4337 factories,   
which are expected to NOT revert if the proxy is already deployed.

### createDeterministicERC1967(uint256,address,bytes32)

```solidity
function createDeterministicERC1967(
    uint256 value,
    address implementation,
    bytes32 salt
) internal returns (bool alreadyDeployed, address instance)
```

Creates a deterministic minimal ERC1967 proxy with `implementation` and `salt`.   
Deposits `value` ETH during deployment.   
Note: This method is intended for use in ERC4337 factories,   
which are expected to NOT revert if the proxy is already deployed.

### initCodeERC1967(address)

```solidity
function initCodeERC1967(address implementation)
    internal
    pure
    returns (bytes memory c)
```

Returns the initialization code of the minimal ERC1967 proxy of `implementation`.

### initCodeHashERC1967(address)

```solidity
function initCodeHashERC1967(address implementation)
    internal
    pure
    returns (bytes32 hash)
```

Returns the initialization code hash of the minimal ERC1967 proxy of `implementation`.

### predictDeterministicAddressERC1967(address,bytes32,address)

```solidity
function predictDeterministicAddressERC1967(
    address implementation,
    bytes32 salt,
    address deployer
) internal pure returns (address predicted)
```

Returns the address of the ERC1967 proxy of `implementation`, with `salt` by `deployer`.   
Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.

## Minimal ERC1967 Proxy With Immutable Args Operations

### deployERC1967(address,bytes)

```solidity
function deployERC1967(address implementation, bytes memory args)
    internal
    returns (address instance)
```

Deploys a minimal ERC1967 proxy with `implementation` and `args`.

### deployERC1967(uint256,address,bytes)

```solidity
function deployERC1967(
    uint256 value,
    address implementation,
    bytes memory args
) internal returns (address instance)
```

Deploys a minimal ERC1967 proxy with `implementation` and `args`.   
Deposits `value` ETH during deployment.

### deployDeterministicERC1967(address,bytes,bytes32)

```solidity
function deployDeterministicERC1967(
    address implementation,
    bytes memory args,
    bytes32 salt
) internal returns (address instance)
```

Deploys a deterministic minimal ERC1967 proxy with `implementation`, `args` and `salt`.

### deployDeterministicERC1967(uint256,address,bytes,bytes32)

```solidity
function deployDeterministicERC1967(
    uint256 value,
    address implementation,
    bytes memory args,
    bytes32 salt
) internal returns (address instance)
```

Deploys a deterministic minimal ERC1967 proxy with `implementation`, `args` and `salt`.   
Deposits `value` ETH during deployment.

### createDeterministicERC1967(address,bytes,bytes32)

```solidity
function createDeterministicERC1967(
    address implementation,
    bytes memory args,
    bytes32 salt
) internal returns (bool alreadyDeployed, address instance)
```

Creates a deterministic minimal ERC1967 proxy with `implementation`, `args` and `salt`.   
Note: This method is intended for use in ERC4337 factories,   
which are expected to NOT revert if the proxy is already deployed.

### createDeterministicERC1967(uint256,address,bytes,bytes32)

```solidity
function createDeterministicERC1967(
    uint256 value,
    address implementation,
    bytes memory args,
    bytes32 salt
) internal returns (bool alreadyDeployed, address instance)
```

Creates a deterministic minimal ERC1967 proxy with `implementation`, `args` and `salt`.   
Deposits `value` ETH during deployment.   
Note: This method is intended for use in ERC4337 factories,   
which are expected to NOT revert if the proxy is already deployed.

### initCodeERC1967(address,bytes)

```solidity
function initCodeERC1967(address implementation, bytes memory args)
    internal
    pure
    returns (bytes memory c)
```

Returns the initialization code of the minimal ERC1967 proxy of `implementation` and `args`.

### initCodeHashERC1967(address,bytes)

```solidity
function initCodeHashERC1967(address implementation, bytes memory args)
    internal
    pure
    returns (bytes32 hash)
```

Returns the initialization code hash of the minimal ERC1967 proxy of `implementation` and `args`.

### predictDeterministicAddressERC1967(address,bytes,bytes32,address)

```solidity
function predictDeterministicAddressERC1967(
    address implementation,
    bytes memory args,
    bytes32 salt,
    address deployer
) internal pure returns (address predicted)
```

Returns the address of the ERC1967 proxy of `implementation`, `args`, with `salt` by `deployer`.   
Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.

### argsOnERC1967(address)

```solidity
function argsOnERC1967(address instance)
    internal
    view
    returns (bytes memory args)
```

Equivalent to `argsOnERC1967(instance, start, 2 ** 256 - 1)`.

### argsOnERC1967(address,uint256)

```solidity
function argsOnERC1967(address instance, uint256 start)
    internal
    view
    returns (bytes memory args)
```

Equivalent to `argsOnERC1967(instance, start, 2 ** 256 - 1)`.

### argsOnERC1967(address,uint256,uint256)

```solidity
function argsOnERC1967(address instance, uint256 start, uint256 end)
    internal
    view
    returns (bytes memory args)
```

Returns a slice of the immutable arguments on `instance` from `start` to `end`.   
`start` and `end` will be clamped to the range `[0, args.length]`.   
The `instance` MUST be deployed via the ERC1967 with immutable args functions.   
Otherwise, the behavior is undefined.   
Out-of-gas reverts if `instance` does not have any code.

## ERC1967I Proxy Operations

Note: This proxy has a special code path that activates if `calldatasize() == 1`.   
This code path skips the delegatecall and directly returns the `implementation` address.   
The returned implementation is guaranteed to be valid if the keccak256 of the   
proxy's code is equal to `ERC1967I_CODE_HASH`.

### deployERC1967I(address)

```solidity
function deployERC1967I(address implementation)
    internal
    returns (address instance)
```

Deploys a ERC1967I proxy with `implementation`.

### deployERC1967I(uint256,address)

```solidity
function deployERC1967I(uint256 value, address implementation)
    internal
    returns (address instance)
```

Deploys a ERC1967I proxy with `implementation`.   
Deposits `value` ETH during deployment.

### deployDeterministicERC1967I(address,bytes32)

```solidity
function deployDeterministicERC1967I(address implementation, bytes32 salt)
    internal
    returns (address instance)
```

Deploys a deterministic ERC1967I proxy with `implementation` and `salt`.

### deployDeterministicERC1967I(uint256,address,bytes32)

```solidity
function deployDeterministicERC1967I(
    uint256 value,
    address implementation,
    bytes32 salt
) internal returns (address instance)
```

Deploys a deterministic ERC1967I proxy with `implementation` and `salt`.   
Deposits `value` ETH during deployment.

### createDeterministicERC1967I(address,bytes32)

```solidity
function createDeterministicERC1967I(address implementation, bytes32 salt)
    internal
    returns (bool alreadyDeployed, address instance)
```

Creates a deterministic ERC1967I proxy with `implementation` and `salt`.   
Note: This method is intended for use in ERC4337 factories,   
which are expected to NOT revert if the proxy is already deployed.

### createDeterministicERC1967I(uint256,address,bytes32)

```solidity
function createDeterministicERC1967I(
    uint256 value,
    address implementation,
    bytes32 salt
) internal returns (bool alreadyDeployed, address instance)
```

Creates a deterministic ERC1967I proxy with `implementation` and `salt`.   
Deposits `value` ETH during deployment.   
Note: This method is intended for use in ERC4337 factories,   
which are expected to NOT revert if the proxy is already deployed.

### initCodeERC1967I(address)

```solidity
function initCodeERC1967I(address implementation)
    internal
    pure
    returns (bytes memory c)
```

Returns the initialization code of the ERC1967I proxy of `implementation`.

### initCodeHashERC1967I(address)

```solidity
function initCodeHashERC1967I(address implementation)
    internal
    pure
    returns (bytes32 hash)
```

Returns the initialization code hash of the ERC1967I proxy of `implementation`.

### predictDeterministicAddressERC1967I(address,bytes32,address)

```solidity
function predictDeterministicAddressERC1967I(
    address implementation,
    bytes32 salt,
    address deployer
) internal pure returns (address predicted)
```

Returns the address of the ERC1967I proxy of `implementation`, with `salt` by `deployer`.   
Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.

## ERC1967I Proxy With Immutable Args Operations

### deployERC1967I(address,bytes)

```solidity
function deployERC1967I(address implementation, bytes memory args)
    internal
    returns (address)
```

Deploys a minimal ERC1967I proxy with `implementation` and `args`.

### deployERC1967I(uint256,address,bytes)

```solidity
function deployERC1967I(
    uint256 value,
    address implementation,
    bytes memory args
) internal returns (address instance)
```

Deploys a minimal ERC1967I proxy with `implementation` and `args`.   
Deposits `value` ETH during deployment.

### deployDeterministicERC1967I(address,bytes,bytes32)

```solidity
function deployDeterministicERC1967I(
    address implementation,
    bytes memory args,
    bytes32 salt
) internal returns (address instance)
```

Deploys a deterministic ERC1967I proxy with `implementation`, `args`, and `salt`.

### deployDeterministicERC1967I(uint256,address,bytes,bytes32)

```solidity
function deployDeterministicERC1967I(
    uint256 value,
    address implementation,
    bytes memory args,
    bytes32 salt
) internal returns (address instance)
```

Deploys a deterministic ERC1967I proxy with `implementation`, `args`, and `salt`.   
Deposits `value` ETH during deployment.

### createDeterministicERC1967I(address,bytes,bytes32)

```solidity
function createDeterministicERC1967I(
    address implementation,
    bytes memory args,
    bytes32 salt
) internal returns (bool alreadyDeployed, address instance)
```

Creates a deterministic ERC1967I proxy with `implementation`, `args` and `salt`.   
Note: This method is intended for use in ERC4337 factories,   
which are expected to NOT revert if the proxy is already deployed.

### createDeterministicERC1967I(uint256,address,bytes,bytes32)

```solidity
function createDeterministicERC1967I(
    uint256 value,
    address implementation,
    bytes memory args,
    bytes32 salt
) internal returns (bool alreadyDeployed, address instance)
```

Creates a deterministic ERC1967I proxy with `implementation`, `args` and `salt`.   
Deposits `value` ETH during deployment.   
Note: This method is intended for use in ERC4337 factories,   
which are expected to NOT revert if the proxy is already deployed.

### initCodeERC1967I(address,bytes)

```solidity
function initCodeERC1967I(address implementation, bytes memory args)
    internal
    pure
    returns (bytes memory c)
```

Returns the initialization code of the ERC1967I proxy of `implementation` and `args`.

### initCodeHashERC1967I(address,bytes)

```solidity
function initCodeHashERC1967I(address implementation, bytes memory args)
    internal
    pure
    returns (bytes32 hash)
```

Returns the initialization code hash of the ERC1967I proxy of `implementation` and `args.

### predictDeterministicAddressERC1967I(address,bytes,bytes32,address)

```solidity
function predictDeterministicAddressERC1967I(
    address implementation,
    bytes memory args,
    bytes32 salt,
    address deployer
) internal pure returns (address predicted)
```

Returns the address of the ERC1967I proxy of `implementation`, `args` with `salt` by `deployer`.   
Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.

### argsOnERC1967I(address)

```solidity
function argsOnERC1967I(address instance)
    internal
    view
    returns (bytes memory args)
```

Equivalent to `argsOnERC1967I(instance, start, 2 ** 256 - 1)`.

### argsOnERC1967I(address,uint256)

```solidity
function argsOnERC1967I(address instance, uint256 start)
    internal
    view
    returns (bytes memory args)
```

Equivalent to `argsOnERC1967I(instance, start, 2 ** 256 - 1)`.

### argsOnERC1967I(address,uint256,uint256)

```solidity
function argsOnERC1967I(address instance, uint256 start, uint256 end)
    internal
    view
    returns (bytes memory args)
```

Returns a slice of the immutable arguments on `instance` from `start` to `end`.   
`start` and `end` will be clamped to the range `[0, args.length]`.   
The `instance` MUST be deployed via the ERC1967 with immutable args functions.   
Otherwise, the behavior is undefined.   
Out-of-gas reverts if `instance` does not have any code.

## ERC1967 Bootstrap Operations

A bootstrap is a minimal UUPS implementation that allows an ERC1967 proxy   
pointing to it to be upgraded. The ERC1967 proxy can then be deployed to a   
deterministic address independent of the implementation:   
```solidity   
address bootstrap = LibClone.erc1967Bootstrap();   
address instance = LibClone.deployDeterministicERC1967(0, bootstrap, salt);   
LibClone.bootstrapERC1967(bootstrap, implementation);   
```

### erc1967Bootstrap()

```solidity
function erc1967Bootstrap() internal returns (address)
```

Deploys the ERC1967 bootstrap if it has not been deployed.

### erc1967Bootstrap(address)

```solidity
function erc1967Bootstrap(address authorizedUpgrader)
    internal
    returns (address bootstrap)
```

Deploys the ERC1967 bootstrap if it has not been deployed.

### bootstrapERC1967(address,address)

```solidity
function bootstrapERC1967(address instance, address implementation)
    internal
```

Replaces the implementation at `instance`.

### bootstrapERC1967AndCall(address,address,bytes)

```solidity
function bootstrapERC1967AndCall(
    address instance,
    address implementation,
    bytes memory data
) internal
```

Replaces the implementation at `instance`, and then call it with `data`.

### predictDeterministicAddressERC1967Bootstrap()

```solidity
function predictDeterministicAddressERC1967Bootstrap()
    internal
    view
    returns (address)
```

Returns the implementation address of the ERC1967 bootstrap for this contract.

### predictDeterministicAddressERC1967Bootstrap(address,address)

```solidity
function predictDeterministicAddressERC1967Bootstrap(
    address authorizedUpgrader,
    address deployer
) internal pure returns (address)
```

Returns the implementation address of the ERC1967 bootstrap for this contract.

### initCodeERC1967Bootstrap(address)

```solidity
function initCodeERC1967Bootstrap(address authorizedUpgrader)
    internal
    pure
    returns (bytes memory c)
```

Returns the initialization code of the ERC1967 bootstrap.

### initCodeHashERC1967Bootstrap(address)

```solidity
function initCodeHashERC1967Bootstrap(address authorizedUpgrader)
    internal
    pure
    returns (bytes32)
```

Returns the initialization code hash of the ERC1967 bootstrap.

## Minimal ERC1967 Beacon Proxy Operations

Note: If you use this proxy, you MUST make sure that the beacon is a   
valid ERC1967 beacon. This means that the beacon must always return a valid   
address upon a staticcall to `implementation()`, given sufficient gas.   
For performance, the deployment operations and the proxy assumes that the   
beacon is always valid and will NOT validate it.

### deployERC1967BeaconProxy(address)

```solidity
function deployERC1967BeaconProxy(address beacon)
    internal
    returns (address instance)
```

Deploys a minimal ERC1967 beacon proxy.

### deployERC1967BeaconProxy(uint256,address)

```solidity
function deployERC1967BeaconProxy(uint256 value, address beacon)
    internal
    returns (address instance)
```

Deploys a minimal ERC1967 beacon proxy.   
Deposits `value` ETH during deployment.

### deployDeterministicERC1967BeaconProxy(address,bytes32)

```solidity
function deployDeterministicERC1967BeaconProxy(address beacon, bytes32 salt)
    internal
    returns (address instance)
```

Deploys a deterministic minimal ERC1967 beacon proxy with `salt`.

### deployDeterministicERC1967BeaconProxy(uint256,address,bytes32)

```solidity
function deployDeterministicERC1967BeaconProxy(
    uint256 value,
    address beacon,
    bytes32 salt
) internal returns (address instance)
```

Deploys a deterministic minimal ERC1967 beacon proxy with `salt`.   
Deposits `value` ETH during deployment.

### createDeterministicERC1967BeaconProxy(address,bytes32)

```solidity
function createDeterministicERC1967BeaconProxy(address beacon, bytes32 salt)
    internal
    returns (bool alreadyDeployed, address instance)
```

Creates a deterministic minimal ERC1967 beacon proxy with `salt`.   
Note: This method is intended for use in ERC4337 factories,   
which are expected to NOT revert if the proxy is already deployed.

### createDeterministicERC1967BeaconProxy(uint256,address,bytes32)

```solidity
function createDeterministicERC1967BeaconProxy(
    uint256 value,
    address beacon,
    bytes32 salt
) internal returns (bool alreadyDeployed, address instance)
```

Creates a deterministic minimal ERC1967 beacon proxy with `salt`.   
Deposits `value` ETH during deployment.   
Note: This method is intended for use in ERC4337 factories,   
which are expected to NOT revert if the proxy is already deployed.

### initCodeERC1967BeaconProxy(address)

```solidity
function initCodeERC1967BeaconProxy(address beacon)
    internal
    pure
    returns (bytes memory c)
```

Returns the initialization code of the minimal ERC1967 beacon proxy.

### initCodeHashERC1967BeaconProxy(address)

```solidity
function initCodeHashERC1967BeaconProxy(address beacon)
    internal
    pure
    returns (bytes32 hash)
```

Returns the initialization code hash of the minimal ERC1967 beacon proxy.

### predictDeterministicAddressERC1967BeaconProxy(address,bytes32,address)

```solidity
function predictDeterministicAddressERC1967BeaconProxy(
    address beacon,
    bytes32 salt,
    address deployer
) internal pure returns (address predicted)
```

Returns the address of the ERC1967 beacon proxy, with `salt` by `deployer`.   
Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.

## ERC1967 Beacon Proxy With Immutable Args Operations

### deployERC1967BeaconProxy(address,bytes)

```solidity
function deployERC1967BeaconProxy(address beacon, bytes memory args)
    internal
    returns (address instance)
```

Deploys a minimal ERC1967 beacon proxy with `args`.

### deployERC1967BeaconProxy(uint256,address,bytes)

```solidity
function deployERC1967BeaconProxy(
    uint256 value,
    address beacon,
    bytes memory args
) internal returns (address instance)
```

Deploys a minimal ERC1967 beacon proxy with `args`.   
Deposits `value` ETH during deployment.

### deployDeterministicERC1967BeaconProxy(address,bytes,bytes32)

```solidity
function deployDeterministicERC1967BeaconProxy(
    address beacon,
    bytes memory args,
    bytes32 salt
) internal returns (address instance)
```

Deploys a deterministic minimal ERC1967 beacon proxy with `args` and `salt`.

### deployDeterministicERC1967BeaconProxy(uint256,address,bytes,bytes32)

```solidity
function deployDeterministicERC1967BeaconProxy(
    uint256 value,
    address beacon,
    bytes memory args,
    bytes32 salt
) internal returns (address instance)
```

Deploys a deterministic minimal ERC1967 beacon proxy with `args` and `salt`.   
Deposits `value` ETH during deployment.

### createDeterministicERC1967BeaconProxy(address,bytes,bytes32)

```solidity
function createDeterministicERC1967BeaconProxy(
    address beacon,
    bytes memory args,
    bytes32 salt
) internal returns (bool alreadyDeployed, address instance)
```

Creates a deterministic minimal ERC1967 beacon proxy with `args` and `salt`.   
Note: This method is intended for use in ERC4337 factories,   
which are expected to NOT revert if the proxy is already deployed.

### createDeterministicERC1967BeaconProxy(uint256,address,bytes,bytes32)

```solidity
function createDeterministicERC1967BeaconProxy(
    uint256 value,
    address beacon,
    bytes memory args,
    bytes32 salt
) internal returns (bool alreadyDeployed, address instance)
```

Creates a deterministic minimal ERC1967 beacon proxy with `args` and `salt`.   
Deposits `value` ETH during deployment.   
Note: This method is intended for use in ERC4337 factories,   
which are expected to NOT revert if the proxy is already deployed.

### initCodeERC1967BeaconProxy(address,bytes)

```solidity
function initCodeERC1967BeaconProxy(address beacon, bytes memory args)
    internal
    pure
    returns (bytes memory c)
```

Returns the initialization code of the minimal ERC1967 beacon proxy.

### initCodeHashERC1967BeaconProxy(address,bytes)

```solidity
function initCodeHashERC1967BeaconProxy(address beacon, bytes memory args)
    internal
    pure
    returns (bytes32 hash)
```

Returns the initialization code hash of the minimal ERC1967 beacon proxy with `args`.

### predictDeterministicAddressERC1967BeaconProxy(address,bytes,bytes32,address)

```solidity
function predictDeterministicAddressERC1967BeaconProxy(
    address beacon,
    bytes memory args,
    bytes32 salt,
    address deployer
) internal pure returns (address predicted)
```

Returns the address of the ERC1967 beacon proxy with `args`, with `salt` by `deployer`.   
Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.

### argsOnERC1967BeaconProxy(address)

```solidity
function argsOnERC1967BeaconProxy(address instance)
    internal
    view
    returns (bytes memory args)
```

Equivalent to `argsOnERC1967BeaconProxy(instance, start, 2 ** 256 - 1)`.

### argsOnERC1967BeaconProxy(address,uint256)

```solidity
function argsOnERC1967BeaconProxy(address instance, uint256 start)
    internal
    view
    returns (bytes memory args)
```

Equivalent to `argsOnERC1967BeaconProxy(instance, start, 2 ** 256 - 1)`.

### argsOnERC1967BeaconProxy(address,uint256,uint256)

```solidity
function argsOnERC1967BeaconProxy(
    address instance,
    uint256 start,
    uint256 end
) internal view returns (bytes memory args)
```

Returns a slice of the immutable arguments on `instance` from `start` to `end`.   
`start` and `end` will be clamped to the range `[0, args.length]`.   
The `instance` MUST be deployed via the ERC1967 beacon proxy with immutable args functions.   
Otherwise, the behavior is undefined.   
Out-of-gas reverts if `instance` does not have any code.

## ERC1967I Beacon Proxy Operations

Note: This proxy has a special code path that activates if `calldatasize() == 1`.   
This code path skips the delegatecall and directly returns the `implementation` address.   
The returned implementation is guaranteed to be valid if the keccak256 of the   
proxy's code is equal to `ERC1967_BEACON_PROXY_CODE_HASH`.   
If you use this proxy, you MUST make sure that the beacon is a   
valid ERC1967 beacon. This means that the beacon must always return a valid   
address upon a staticcall to `implementation()`, given sufficient gas.   
For performance, the deployment operations and the proxy assumes that the   
beacon is always valid and will NOT validate it.

### deployERC1967IBeaconProxy(address)

```solidity
function deployERC1967IBeaconProxy(address beacon)
    internal
    returns (address instance)
```

Deploys a ERC1967I beacon proxy.

### deployERC1967IBeaconProxy(uint256,address)

```solidity
function deployERC1967IBeaconProxy(uint256 value, address beacon)
    internal
    returns (address instance)
```

Deploys a ERC1967I beacon proxy.   
Deposits `value` ETH during deployment.

### deployDeterministicERC1967IBeaconProxy(address,bytes32)

```solidity
function deployDeterministicERC1967IBeaconProxy(
    address beacon,
    bytes32 salt
) internal returns (address instance)
```

Deploys a deterministic ERC1967I beacon proxy with `salt`.

### deployDeterministicERC1967IBeaconProxy(uint256,address,bytes32)

```solidity
function deployDeterministicERC1967IBeaconProxy(
    uint256 value,
    address beacon,
    bytes32 salt
) internal returns (address instance)
```

Deploys a deterministic ERC1967I beacon proxy with `salt`.   
Deposits `value` ETH during deployment.

### createDeterministicERC1967IBeaconProxy(address,bytes32)

```solidity
function createDeterministicERC1967IBeaconProxy(
    address beacon,
    bytes32 salt
) internal returns (bool alreadyDeployed, address instance)
```

Creates a deterministic ERC1967I beacon proxy with `salt`.   
Note: This method is intended for use in ERC4337 factories,   
which are expected to NOT revert if the proxy is already deployed.

### createDeterministicERC1967IBeaconProxy(uint256,address,bytes32)

```solidity
function createDeterministicERC1967IBeaconProxy(
    uint256 value,
    address beacon,
    bytes32 salt
) internal returns (bool alreadyDeployed, address instance)
```

Creates a deterministic ERC1967I beacon proxy with `salt`.   
Deposits `value` ETH during deployment.   
Note: This method is intended for use in ERC4337 factories,   
which are expected to NOT revert if the proxy is already deployed.

### initCodeERC1967IBeaconProxy(address)

```solidity
function initCodeERC1967IBeaconProxy(address beacon)
    internal
    pure
    returns (bytes memory c)
```

Returns the initialization code of the ERC1967I beacon proxy.

### initCodeHashERC1967IBeaconProxy(address)

```solidity
function initCodeHashERC1967IBeaconProxy(address beacon)
    internal
    pure
    returns (bytes32 hash)
```

Returns the initialization code hash of the ERC1967I beacon proxy.

### predictDeterministicAddressERC1967IBeaconProxy(address,bytes32,address)

```solidity
function predictDeterministicAddressERC1967IBeaconProxy(
    address beacon,
    bytes32 salt,
    address deployer
) internal pure returns (address predicted)
```

Returns the address of the ERC1967I beacon proxy, with `salt` by `deployer`.   
Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.

## ERC1967I Beacon Proxy With Immutable Args Operations

### deployERC1967IBeaconProxy(address,bytes)

```solidity
function deployERC1967IBeaconProxy(address beacon, bytes memory args)
    internal
    returns (address instance)
```

Deploys a ERC1967I beacon proxy with `args.

### deployERC1967IBeaconProxy(uint256,address,bytes)

```solidity
function deployERC1967IBeaconProxy(
    uint256 value,
    address beacon,
    bytes memory args
) internal returns (address instance)
```

Deploys a ERC1967I beacon proxy with `args.   
Deposits `value` ETH during deployment.

### deployDeterministicERC1967IBeaconProxy(address,bytes,bytes32)

```solidity
function deployDeterministicERC1967IBeaconProxy(
    address beacon,
    bytes memory args,
    bytes32 salt
) internal returns (address instance)
```

Deploys a deterministic ERC1967I beacon proxy with `args` and `salt`.

### deployDeterministicERC1967IBeaconProxy(uint256,address,bytes,bytes32)

```solidity
function deployDeterministicERC1967IBeaconProxy(
    uint256 value,
    address beacon,
    bytes memory args,
    bytes32 salt
) internal returns (address instance)
```

Deploys a deterministic ERC1967I beacon proxy with `args` and `salt`.   
Deposits `value` ETH during deployment.

### createDeterministicERC1967IBeaconProxy(address,bytes,bytes32)

```solidity
function createDeterministicERC1967IBeaconProxy(
    address beacon,
    bytes memory args,
    bytes32 salt
) internal returns (bool alreadyDeployed, address instance)
```

Creates a deterministic ERC1967I beacon proxy with `args` and `salt`.   
Note: This method is intended for use in ERC4337 factories,   
which are expected to NOT revert if the proxy is already deployed.

### createDeterministicERC1967IBeaconProxy(uint256,address,bytes,bytes32)

```solidity
function createDeterministicERC1967IBeaconProxy(
    uint256 value,
    address beacon,
    bytes memory args,
    bytes32 salt
) internal returns (bool alreadyDeployed, address instance)
```

Creates a deterministic ERC1967I beacon proxy with `args` and `salt`.   
Deposits `value` ETH during deployment.   
Note: This method is intended for use in ERC4337 factories,   
which are expected to NOT revert if the proxy is already deployed.

### initCodeERC1967IBeaconProxy(address,bytes)

```solidity
function initCodeERC1967IBeaconProxy(address beacon, bytes memory args)
    internal
    pure
    returns (bytes memory c)
```

Returns the initialization code of the ERC1967I beacon proxy with `args`.

### initCodeHashERC1967IBeaconProxy(address,bytes)

```solidity
function initCodeHashERC1967IBeaconProxy(address beacon, bytes memory args)
    internal
    pure
    returns (bytes32 hash)
```

Returns the initialization code hash of the ERC1967I beacon proxy with `args`.

### predictDeterministicAddressERC1967IBeaconProxy(address,bytes,bytes32,address)

```solidity
function predictDeterministicAddressERC1967IBeaconProxy(
    address beacon,
    bytes memory args,
    bytes32 salt,
    address deployer
) internal pure returns (address predicted)
```

Returns the address of the ERC1967I beacon proxy, with  `args` and salt` by `deployer`.   
Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.

### argsOnERC1967IBeaconProxy(address)

```solidity
function argsOnERC1967IBeaconProxy(address instance)
    internal
    view
    returns (bytes memory args)
```

Equivalent to `argsOnERC1967IBeaconProxy(instance, start, 2 ** 256 - 1)`.

### argsOnERC1967IBeaconProxy(address,uint256)

```solidity
function argsOnERC1967IBeaconProxy(address instance, uint256 start)
    internal
    view
    returns (bytes memory args)
```

Equivalent to `argsOnERC1967IBeaconProxy(instance, start, 2 ** 256 - 1)`.

### argsOnERC1967IBeaconProxy(address,uint256,uint256)

```solidity
function argsOnERC1967IBeaconProxy(
    address instance,
    uint256 start,
    uint256 end
) internal view returns (bytes memory args)
```

Returns a slice of the immutable arguments on `instance` from `start` to `end`.   
`start` and `end` will be clamped to the range `[0, args.length]`.   
The `instance` MUST be deployed via the ERC1967I beacon proxy with immutable args functions.   
Otherwise, the behavior is undefined.   
Out-of-gas reverts if `instance` does not have any code.

## Other Operations

### implementationOf(address)

```solidity
function implementationOf(address instance)
    internal
    view
    returns (address result)
```

Returns `address(0)` if the implementation address cannot be determined.

### predictDeterministicAddress(bytes32,bytes32,address)

```solidity
function predictDeterministicAddress(
    bytes32 hash,
    bytes32 salt,
    address deployer
) internal pure returns (address predicted)
```

Returns the address when a contract with initialization code hash,   
`hash`, is deployed with `salt`, by `deployer`.   
Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.

### checkStartsWith(bytes32,address)

```solidity
function checkStartsWith(bytes32 salt, address by) internal pure
```

Requires that `salt` starts with either the zero address or `by`.

### argLoad(bytes,uint256)

```solidity
function argLoad(bytes memory args, uint256 offset)
    internal
    pure
    returns (bytes32 result)
```

Returns the `bytes32` at `offset` in `args`, without any bounds checks.   
To load an address, you can use `address(bytes20(argLoad(args, offset)))`.