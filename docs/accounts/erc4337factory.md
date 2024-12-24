# ERC4337Factory

Simple ERC4337 account factory implementation.






<!-- customintro:start --><!-- customintro:end -->

## Immutables

### implementation

```solidity
address public immutable implementation
```

Address of the ERC4337 implementation.

## Deploy Functions

### createAccount(address,bytes32)

```solidity
function createAccount(address owner, bytes32 salt)
    public
    payable
    virtual
    returns (address)
```

Deploys an ERC4337 account with `salt` and returns its deterministic address.   
If the account is already deployed, it will simply return its address.   
Any `msg.value` will simply be forwarded to the account, regardless.

### getAddress(bytes32)

```solidity
function getAddress(bytes32 salt) public view virtual returns (address)
```

Returns the deterministic address of the account created via `createAccount`.

### initCodeHash()

```solidity
function initCodeHash() public view virtual returns (bytes32)
```

Returns the initialization code hash of the ERC4337 account (a minimal ERC1967 proxy).   
Used for mining vanity addresses with create2crunch.