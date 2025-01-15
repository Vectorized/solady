# ERC4337Factory

Simple ERC4337 account factory implementation.


<b>Note:</b>

- Unlike the ERC1967Factory, this factory does NOT store any admin info on the factory itself.
The deployed ERC4337 accounts are minimal ERC1967 proxies to an ERC4337 implementation.
The proxy bytecode does NOT contain any upgrading logic.
- This factory does NOT contain any logic for upgrading the ERC4337 accounts.
Upgrading must be done via UUPS logic on the accounts themselves.
- The ERC4337 standard expects the factory to use deterministic deployment.
As such, this factory does not include any non-deterministic deployment methods.



<!-- customintro:start --><!-- customintro:end -->

## Immutables

### implementation

```solidity
address public immutable implementation
```

Address of the ERC4337 implementation.

## Deploy Functions

### createAccount(bytes32)

```solidity
function createAccount(bytes32 ownSalt)
    public
    payable
    virtual
    returns (address)
```

Deploys an ERC4337 account with `ownSalt` and returns its deterministic address.   
The `owner` is encoded in the upper 160 bits of `ownSalt`.   
If the account is already deployed, it will simply return its address.   
Any `msg.value` will simply be forwarded to the account, regardless.

### getAddress(bytes32)

```solidity
function getAddress(bytes32 ownSalt)
    public
    view
    virtual
    returns (address)
```

Returns the deterministic address of the account created via `createAccount`.

### initCodeHash()

```solidity
function initCodeHash() public view virtual returns (bytes32)
```

Returns the initialization code hash of the ERC4337 account (a minimal ERC1967 proxy).   
Used for mining vanity addresses with create2crunch.