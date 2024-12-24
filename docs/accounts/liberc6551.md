# LibERC6551

Library for interacting with ERC6551 accounts.






<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### AccountCreationFailed()

```solidity
error AccountCreationFailed()
```

Failed to create a ERC6551 account via the registry.

## Constants

### REGISTRY

```solidity
address internal constant REGISTRY =
    0x000000006551c19487814612e58FE06813775758
```

The canonical ERC6551 registry address for EVM chains.

### REGISTRY_BYTECODE

```solidity
bytes internal constant REGISTRY_BYTECODE =
    hex"608060405234801561001057600080fd5b50600436106100365760003560e01c8063246a00211461003b5780638a54c52f1461006a575b600080fd5b61004e6100493660046101b7565b61007d565b6040516001600160a01b03909116815260200160405180910390f35b61004e6100783660046101b7565b6100e1565b600060806024608c376e5af43d82803e903d91602b57fd5bf3606c5285605d52733d60ad80600a3d3981f3363d3d373d3d3d363d7360495260ff60005360b76055206035523060601b60015284601552605560002060601b60601c60005260206000f35b600060806024608c376e5af43d82803e903d91602b57fd5bf3606c5285605d52733d60ad80600a3d3981f3363d3d373d3d3d363d7360495260ff60005360b76055206035523060601b600152846015526055600020803b61018b578560b760556000f580610157576320188a596000526004601cfd5b80606c52508284887f79f19b3655ee38b1ce526556b7731a20c8f218fbda4a3990b6cc4172fdf887226060606ca46020606cf35b8060601b60601c60005260206000f35b80356001600160a01b03811681146101b257600080fd5b919050565b600080600080600060a086880312156101cf57600080fd5b6101d88661019b565b945060208601359350604086013592506101f46060870161019b565b94979396509194608001359291505056fea2646970667358221220ea2fe53af507453c64dd7c1db05549fa47a298dfb825d6d11e1689856135f16764736f6c63430008110033"
```

The canonical ERC6551 registry bytecode for EVM chains.   
Useful for forge tests:   
`vm.etch(REGISTRY, REGISTRY_BYTECODE)`.

## Account Bytecode Operations

### initCode(address,bytes32,uint256,address,uint256)

```solidity
function initCode(
    address implementation_,
    bytes32 salt_,
    uint256 chainId_,
    address tokenContract_,
    uint256 tokenId_
) internal pure returns (bytes memory result)
```

Returns the initialization code of the ERC6551 account.

### initCodeHash(address,bytes32,uint256,address,uint256)

```solidity
function initCodeHash(
    address implementation_,
    bytes32 salt_,
    uint256 chainId_,
    address tokenContract_,
    uint256 tokenId_
) internal pure returns (bytes32 result)
```

Returns the initialization code hash of the ERC6551 account.

### createAccount(address,bytes32,uint256,address,uint256)

```solidity
function createAccount(
    address implementation_,
    bytes32 salt_,
    uint256 chainId_,
    address tokenContract_,
    uint256 tokenId_
) internal returns (address result)
```

Creates an account via the ERC6551 registry.

### account(address,bytes32,uint256,address,uint256)

```solidity
function account(
    address implementation_,
    bytes32 salt_,
    uint256 chainId_,
    address tokenContract_,
    uint256 tokenId_
) internal pure returns (address result)
```

Returns the address of the ERC6551 account.

### isERC6551Account(address,address)

```solidity
function isERC6551Account(address a, address expectedImplementation)
    internal
    view
    returns (bool result)
```

Returns if `a` is an ERC6551 account with `expectedImplementation`.

### implementation(address)

```solidity
function implementation(address a) internal view returns (address result)
```

Returns the implementation of the ERC6551 account `a`.

### context(address)

```solidity
function context(address a)
    internal
    view
    returns (
        bytes32 salt_,
        uint256 chainId_,
        address tokenContract_,
        uint256 tokenId_
    )
```

Returns the static variables of the ERC6551 account `a`.

### salt(address)

```solidity
function salt(address a) internal view returns (bytes32 result)
```

Returns the salt of the ERC6551 account `a`.

### chainId(address)

```solidity
function chainId(address a) internal view returns (uint256 result)
```

Returns the chain ID of the ERC6551 account `a`.

### tokenContract(address)

```solidity
function tokenContract(address a) internal view returns (address result)
```

Returns the token contract of the ERC6551 account `a`.

### tokenId(address)

```solidity
function tokenId(address a) internal view returns (uint256 result)
```

Returns the token ID of the ERC6551 account `a`.