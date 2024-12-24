# ERC1967Factory

Factory for deploying and managing ERC1967 proxy contracts.






<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### Unauthorized()

```solidity
error Unauthorized()
```

The caller is not authorized to call the function.

### DeploymentFailed()

```solidity
error DeploymentFailed()
```

The proxy deployment failed.

### UpgradeFailed()

```solidity
error UpgradeFailed()
```

The upgrade failed.

### SaltDoesNotStartWithCaller()

```solidity
error SaltDoesNotStartWithCaller()
```

The salt does not start with the caller.

## Events

### _ADMIN_CHANGED_EVENT_SIGNATURE

```solidity
uint256 internal constant _ADMIN_CHANGED_EVENT_SIGNATURE =
    0x7e644d79422f17c01e4894b5f4f588d331ebfa28653d42ae832dc59e38c9798f
```

`keccak256(bytes("AdminChanged(address,address)"))`.

### _UPGRADED_EVENT_SIGNATURE

```solidity
uint256 internal constant _UPGRADED_EVENT_SIGNATURE =
    0x5d611f318680d00598bb735d61bacf0c514c6b50e1e5ad30040a4df2b12791c7
```

`keccak256(bytes("Upgraded(address,address)"))`.

### _DEPLOYED_EVENT_SIGNATURE

```solidity
uint256 internal constant _DEPLOYED_EVENT_SIGNATURE =
    0xc95935a66d15e0da5e412aca0ad27ae891d20b2fb91cf3994b6a3bf2b8178082
```

`keccak256(bytes("Deployed(address,address,address)"))`.

## Storage

The admin slot for a `proxy` is `shl(96, proxy)`.

### _IMPLEMENTATION_SLOT

```solidity
uint256 internal constant _IMPLEMENTATION_SLOT =
    0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
```

The ERC-1967 storage slot for the implementation in the proxy.   
`uint256(keccak256("eip1967.proxy.implementation")) - 1`.

## Admin Functions

### adminOf(address)

```solidity
function adminOf(address proxy) public view returns (address admin)
```

Returns the admin of the proxy.

### changeAdmin(address,address)

```solidity
function changeAdmin(address proxy, address admin) public
```

Sets the admin of the proxy.   
The caller of this function must be the admin of the proxy on this factory.

## Upgrade Functions

### upgrade(address,address)

```solidity
function upgrade(address proxy, address implementation) public payable
```

Upgrades the proxy to point to `implementation`.   
The caller of this function must be the admin of the proxy on this factory.

### upgradeAndCall(address,address,bytes)

```solidity
function upgradeAndCall(
    address proxy,
    address implementation,
    bytes calldata data
) public payable
```

Upgrades the proxy to point to `implementation`.   
Then, calls the proxy with abi encoded `data`.   
The caller of this function must be the admin of the proxy on this factory.

## Deploy Functions

### deploy(address,address)

```solidity
function deploy(address implementation, address admin)
    public
    payable
    returns (address proxy)
```

Deploys a proxy for `implementation`, with `admin`,   
and returns its address.   
The value passed into this function will be forwarded to the proxy.

### deployAndCall(address,address,bytes)

```solidity
function deployAndCall(
    address implementation,
    address admin,
    bytes calldata data
) public payable returns (address proxy)
```

Deploys a proxy for `implementation`, with `admin`,   
and returns its address.   
The value passed into this function will be forwarded to the proxy.   
Then, calls the proxy with abi encoded `data`.

### deployDeterministic(address,address,bytes32)

```solidity
function deployDeterministic(
    address implementation,
    address admin,
    bytes32 salt
) public payable returns (address proxy)
```

Deploys a proxy for `implementation`, with `admin`, `salt`,   
and returns its deterministic address.   
The value passed into this function will be forwarded to the proxy.

### deployDeterministicAndCall(address,address,bytes32,bytes)

```solidity
function deployDeterministicAndCall(
    address implementation,
    address admin,
    bytes32 salt,
    bytes calldata data
) public payable returns (address proxy)
```

Deploys a proxy for `implementation`, with `admin`, `salt`,   
and returns its deterministic address.   
The value passed into this function will be forwarded to the proxy.   
Then, calls the proxy with abi encoded `data`.

### _deploy(address,address,bytes32,bool,bytes)

```solidity
function _deploy(
    address implementation,
    address admin,
    bytes32 salt,
    bool useSalt,
    bytes calldata data
) internal returns (address proxy)
```

Deploys the proxy, with optionality to deploy deterministically with a `salt`.

### predictDeterministicAddress(bytes32)

```solidity
function predictDeterministicAddress(bytes32 salt)
    public
    view
    returns (address predicted)
```

Returns the address of the proxy deployed with `salt`.

### initCodeHash()

```solidity
function initCodeHash() public view returns (bytes32 result)
```

Returns the initialization code hash of the proxy.   
Used for mining vanity addresses with create2crunch.

### _initCode()

```solidity
function _initCode() internal view returns (bytes32 m)
```

Returns a pointer to the initialization code of a proxy created via this factory.

## Helpers

### _emptyData()

```solidity
function _emptyData() internal pure returns (bytes calldata data)
```

Helper function to return an empty bytes calldata.