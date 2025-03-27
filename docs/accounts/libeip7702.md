# LibEIP7702

Library for EIP7702 operations.






<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### DeploymentFailed()

```solidity
error DeploymentFailed()
```

Failed to deploy the EIP7702Proxy.

### ProxyQueryFailed()

```solidity
error ProxyQueryFailed()
```

The proxy query has failed.

### ChangeProxyAdminFailed()

```solidity
error ChangeProxyAdminFailed()
```

Failed to change the proxy admin.

### UpgradeProxyFailed()

```solidity
error UpgradeProxyFailed()
```

Failed to upgrade the proxy.

## Constants

### ERC1967_IMPLEMENTATION_SLOT

```solidity
bytes32 internal constant ERC1967_IMPLEMENTATION_SLOT =
    0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
```

The ERC-1967 storage slot for the implementation in the proxy.   
`uint256(keccak256("eip1967.proxy.implementation")) - 1`.

### EIP7702_PROXY_DELEGATION_INITIALIZATION_REQUEST_SLOT

```solidity
bytes32 internal constant
    EIP7702_PROXY_DELEGATION_INITIALIZATION_REQUEST_SLOT =
        0x94e11c6e41e7fb92cb8bb65e13fdfbd4eba8b831292a1a220f7915c78c7c078f
```

The transient storage slot for requesting the proxy to initialize the implementation.   
`uint256(keccak256("eip7702.proxy.delegation.initialization.request")) - 1`.   
While we would love to use a smaller constant, this slot is used in both the proxy   
and the delegation, so we shall just use bytes32 in case we want to standardize this.

### EIP7702_PROXY_CREATION_CODE

```solidity
bytes internal constant EIP7702_PROXY_CREATION_CODE =
    hex"60c060408190523060805261031138819003908190833981016040819052610026916100a3565b6001600160a01b039182167f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc81905591167fb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103819055811515110260a0526100d4565b80516001600160a01b038116811461009e575f5ffd5b919050565b5f5f604083850312156100b4575f5ffd5b6100bd83610088565b91506100cb60208401610088565b90509250929050565b60805160a05161021e6100f35f395f602601525f6005015261021e5ff3fe3d6040527f00000000000000000000000000000000000000000000000000000000000000007f00000000000000000000000000000000000000000000000000000000000000007f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc308318610119576001361161007e5780543652602036f35b5f3560e01c80635c60da1b0361009f5760205f5f36305afa1561009f573d5ff35b7fb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d610380548263f851a440036100d557805f5260205ff35b8033036101125760103560601c83638f283970036100f95780835560015f5260205ff35b83630900f010036101105780855560015f5260205ff35b505b5050505f3dfd5b805436600103610154578060601b61014657826101435760205f5f36875afa61013e57fe5b60205ff35b50815b8060601b60601c5f5260205ff35b365f5f378060601b6101cb57826101c8576020365f36875afa5f5f365f36515af416610182573d5f5f3e3d5ffd5b7f94e11c6e41e7fb92cb8bb65e13fdfbd4eba8b831292a1a220f7915c78c7c078f805c156101bf57365183546001600160a01b0319161783555f815d5b503d5f5f3e3d5ff35b50815b5f36365f845af46101de573d5f5f3e3d5ffd5b50503d5f5f3e3d5ff3fea2646970667358221220ad810cb1d8296ebd4649785ecb093c978531e8ae483468cdb56d4856d522f99464736f6c634300081c0033"
```

The creation code for the EIP7702Proxy.   
This is generated from [`EIP7702Proxy.sol`](accounts/eip7702proxy.md) with exact compilation settings.

### EIP7702_PROXY_MINIMAL_CODE_HASH

```solidity
bytes32 internal constant EIP7702_PROXY_MINIMAL_CODE_HASH =
    0x7386c2810632fa8ea702ec3b7b0ad8fe514f063d42915830c6dd30abd543082e
```

The keccak256 of runtime code for [`EIP7702Proxy.sol`](accounts/eip7702proxy.md) with exact compilation settings,   
with immutables zeroized and without the CBOR metadata.

## Authority And Proxy Operations

### delegationOf(address)

```solidity
function delegationOf(address account)
    internal
    view
    returns (address result)
```

Returns the delegation of the account.   
If the account is not an EIP7702 authority, returns `address(0)`.

### delegationAndImplementationOf(address)

```solidity
function delegationAndImplementationOf(address account)
    internal
    view
    returns (address delegation, address implementation)
```

Returns the delegation and the implementation of the account.   
If the account delegation is not a valid EIP7702Proxy, returns `address(0)`.

### implementationOf(address)

```solidity
function implementationOf(address target)
    internal
    view
    returns (address result)
```

Returns the implementation of `target`.   
If `target` is neither an EIP7702Proxy nor an EOA delegated to an EIP7702Proxy, returns `address(0)`.

### isEIP7702Proxy(address)

```solidity
function isEIP7702Proxy(address target)
    internal
    view
    returns (bool result)
```

Returns if `target` is an valid EIP7702Proxy based on a bytecode hash check.

### proxyInitCode(address,address)

```solidity
function proxyInitCode(address initialImplementation, address initialAdmin)
    internal
    pure
    returns (bytes memory)
```

Returns the initialization code for the EIP7702Proxy.

### deployProxy(address,address)

```solidity
function deployProxy(address initialImplementation, address initialAdmin)
    internal
    returns (address instance)
```

Deploys an EIP7702Proxy.

### deployProxyDeterministic(address,address,bytes32)

```solidity
function deployProxyDeterministic(
    address initialImplementation,
    address initialAdmin,
    bytes32 salt
) internal returns (address instance)
```

Deploys an EIP7702Proxy to a deterministic address with `salt`.

### proxyAdmin(address)

```solidity
function proxyAdmin(address proxy) internal view returns (address result)
```

Returns the admin of the proxy.   
Assumes that the proxy is a proper EIP7702Proxy, if it exists.

### changeProxyAdmin(address,address)

```solidity
function changeProxyAdmin(address proxy, address newAdmin) internal
```

Changes the admin on the proxy. The caller must be the admin.   
Assumes that the proxy is a proper EIP7702Proxy, if it exists.

### upgradeProxy(address,address)

```solidity
function upgradeProxy(address proxy, address newImplementation) internal
```

Changes the implementation on the proxy. The caller must be the admin.   
Assumes that the proxy is a proper EIP7702Proxy, if it exists.

## UUPS Operations

### upgradeProxyDelegation(address)

```solidity
function upgradeProxyDelegation(address newImplementation) internal
```

Upgrades the implementation.   
The new implementation will NOT be active until the next UserOp or transaction.   
To "auto-upgrade" to the latest implementation on the proxy, pass in `address(0)` to reset   
the implementation slot. This causes the proxy to use the latest default implementation,   
which may be optionally reinitialized via `requestProxyDelegationInitialization()`.   
This function is intended to be used on the authority of an EIP7702Proxy delegation.   
The most intended usage pattern is to wrap this in an access-gated admin function.

### requestProxyDelegationInitialization()

```solidity
function requestProxyDelegationInitialization() internal
```

Requests the implementation to be initialized to the latest implementation on the proxy.   
This function is intended to be used on the authority of an EIP7702Proxy delegation.   
The most intended usage pattern is to place it at the end of an `execute` function.