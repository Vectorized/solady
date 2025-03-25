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

### EIP7702_PROXY_BYTECODE

```solidity
bytes internal constant EIP7702_PROXY_BYTECODE =
    hex"3d6040527f00000000000000000000000000000000000000000000000000000000000000007f00000000000000000000000000000000000000000000000000000000000000007f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc30831861011f573661007b5780543652602036f35b5f3560e01c80637dae87cb1481635c60da1b1417156100a55760205f5f36305afa156100a5573d5ff35b7fb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d610380548263f851a440036100db57805f5260205ff35b8033036101185760103560601c83638f283970036100ff5780835560015f5260205ff35b83630900f010036101165780855560015f5260205ff35b505b5050505f3dfd5b80543660010361015a578060601b61014c57826101495760205f5f36875afa61014457fe5b60205ff35b50815b8060601b60601c5f5260205ff35b365f5f378060601b6101d157826101ce576020365f36875afa5f5f365f36515af416610188573d5f5f3e3d5ffd5b7f94e11c6e41e7fb92cb8bb65e13fdfbd4eba8b831292a1a220f7915c78c7c078f805c156101c557365183546001600160a01b0319161783555f815d5b503d5f5f3e3d5ff35b50815b5f36365f845af46101e4573d5f5f3e3d5ffd5b50503d5f5f3e3d5ff3fea264697066735822122083f79db79e1d888dce9d6a6e069750bacafdfad774becb8ebfa8e7719225031464736f6c634300081c0033"
```

The runtime bytecode for the EIP7702Proxy, with immutables zeroized.   
See: https://gist.github.com/Vectorized/0a83937618a55b389e38a230da6d9531

### EIP7702_PROXY_CREATION_CODE

```solidity
bytes internal constant EIP7702_PROXY_CREATION_CODE = abi.encodePacked(
    hex"60c060408190523060805261031738819003908190833981016040819052610026916100a3565b6001600160a01b039182167f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc81905591167fb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103819055811515110260a0526100d4565b80516001600160a01b038116811461009e575f5ffd5b919050565b5f5f604083850312156100b4575f5ffd5b6100bd83610088565b91506100cb60208401610088565b90509250929050565b60805160a0516102246100f35f395f602601525f600501526102245ff3fe",
    EIP7702_PROXY_BYTECODE
)
```

The creation code for the EIP7702Proxy.

### EIP7702_PROXY_MINIMAL_CODE_HASH

```solidity
bytes32 internal constant EIP7702_PROXY_MINIMAL_CODE_HASH =
    0xc1e382531e1faf22da0080b8aefe50afbd511106dcc88cebabb3fee47c28c6ce
```

The keccak256 of deployed code for the EIP7702Proxy, with immutables zeroized,   
and without the CBOR metadata.

## Authority And Proxy Operations

### delegation(address)

```solidity
function delegation(address account)
    internal
    view
    returns (address result)
```

Returns the delegation of the account.   
If the account is not an EIP7702 authority, returns `address(0)`.

### delegationAndImplementation(address)

```solidity
function delegationAndImplementation(address account)
    internal
    view
    returns (address accountDelegation, address implementation)
```

Returns the delegation and the implementation of the account.   
If the account delegation is not a valid EIP7702Proxy, returns `address(0)`.

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

### proxyImplementation(address)

```solidity
function proxyImplementation(address proxy)
    internal
    view
    returns (address result)
```

Returns the implementation of the proxy.   
Assumes that the proxy is a proper EIP7702Proxy, if it exists.

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