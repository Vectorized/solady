# UUPSUpgradeable

UUPS proxy mixin.


<b>Note:</b>

- This implementation is intended to be used with ERC1967 proxies. See: `LibClone.deployERC1967` and related functions.
- This implementation is NOT compatible with legacy OpenZeppelin proxies
which do not store the implementation at `_ERC1967_IMPLEMENTATION_SLOT`.



<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### UpgradeFailed()

```solidity
error UpgradeFailed()
```

The upgrade failed.

### UnauthorizedCallContext()

```solidity
error UnauthorizedCallContext()
```

The call is from an unauthorized call context.

## Storage

### _ERC1967_IMPLEMENTATION_SLOT

```solidity
bytes32 internal constant _ERC1967_IMPLEMENTATION_SLOT =
    0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
```

The ERC-1967 storage slot for the implementation in the proxy.   
`uint256(keccak256("eip1967.proxy.implementation")) - 1`.

## UUPS Operations

### upgradeToAndCall(address,bytes)

```solidity
function upgradeToAndCall(address newImplementation, bytes calldata data)
    public
    payable
    virtual
    onlyProxy
```

Upgrades the proxy's implementation to `newImplementation`.   
Emits a {Upgraded} event.   
Note: Passing in empty `data` skips the delegatecall to `newImplementation`.

### onlyProxy()

```solidity
modifier onlyProxy()
```

Requires that the execution is performed through a proxy.

### notDelegated()

```solidity
modifier notDelegated()
```

Requires that the execution is NOT performed via delegatecall.   
This is the opposite of `onlyProxy`.