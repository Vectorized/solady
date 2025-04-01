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
    hex"60c06040819052306080526102d63881900390819083398101604081905261002691610096565b7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc8290557fb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103819055811515110260a0526100c7565b80516001600160a01b0381168114610091575f5ffd5b919050565b5f5f604083850312156100a7575f5ffd5b6100b08361007b565b91506100be6020840161007b565b90509250929050565b60805160a0516101f06100e65f395f602701525f600601526101f05ff3fe60016040527f00000000000000000000000000000000000000000000000000000000000000007f00000000000000000000000000000000000000000000000000000000000000007f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc361960601c30841861010a576001361161008657815481165f5260205ff35b5f3560e01c80635c60da1b036100a157825482165f5260205ff35b7fb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d61038163f851a440036100d65780545f5260205ff35b80543303610106578382630900f01014028183638f2839701402178015610104576004358416815560206040f35b505b5f5ffd5b815481163660010361013b5780610133575082806101335760205f5f5f885afa15610106573d5ff35b805f5260205ff35b365f5f37806101a7575082806101a7576020365f5f885afa5f5f365f36515af416610168573d5f5f3e3d5ffd5b7f94e11c6e41e7fb92cb8bb65e13fdfbd4eba8b831292a1a220f7915c78c7c078f805c1561019e57365184548419161784555f815d5b503d5f5f3e3d5ff35b5f5f365f845af461019e573d5f5f3e3d5ffdfea2646970667358221220e8b1a2a38594baf32c154aa7dd7743c9cd741d4f386b5ab588a5dcd613c3a00e64736f6c634300081c0033"
```

The creation code for the EIP7702Proxy.   
This is generated from [`EIP7702Proxy.sol`](accounts/eip7702proxy.md) with exact compilation settings.

### EIP7702_PROXY_MINIMAL_CODE_HASH

```solidity
bytes32 internal constant EIP7702_PROXY_MINIMAL_CODE_HASH =
    0xf8710866f390ac7c12640457f9cb9663657ac8168b7d4ce6418a982932b3043e
```

The keccak256 of runtime code for [`EIP7702Proxy.sol`](accounts/eip7702proxy.md) with exact compilation settings,   
with immutables zeroized and without the CBOR metadata.

### EIP7702_PROXY_MINIMAL_CODE_LENGTH

```solidity
uint256 internal constant EIP7702_PROXY_MINIMAL_CODE_LENGTH = 0x1ba
```

The length of the runtime code for [`EIP7702Proxy.sol`](accounts/eip7702proxy.md) with exact compilation settings,   
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