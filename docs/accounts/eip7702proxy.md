# EIP7702Proxy

Relay proxy for EIP7702 delegations.


<b>Note:</b>

This relay proxy is useful for upgradeable EIP7702 accounts
without the need for redelegation.

EOA -> EIP7702Proxy (relay) -> EIP7702 account implementation.

This relay proxy also allows for correctly revealing the
"Read as Proxy" and "Write as Proxy" tabs on Etherscan.



<!-- customintro:start --><!-- customintro:end -->

## Immutables

### __self

```solidity
uint256 internal immutable __self = uint256(uint160(address(this)))
```

For differentiating calls on the EOA and calls on the proxy itself.

### _defaultImplementation

```solidity
uint256 internal immutable _defaultImplementation
```

The default implementation. Provided for optimization.   
Set if the `initialAdmin == address(0) && initialImplementation != address(0)`.

## Storage

### _ERC1967_IMPLEMENTATION_SLOT

```solidity
bytes32 internal constant _ERC1967_IMPLEMENTATION_SLOT =
    0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
```

The ERC-1967 storage slot for the implementation in the proxy.   
`uint256(keccak256("eip1967.proxy.implementation")) - 1`.

### _ERC1967_ADMIN_SLOT

```solidity
bytes32 internal constant _ERC1967_ADMIN_SLOT =
    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
```

The ERC-1967 storage slot for the admin in the proxy.   
`uint256(keccak256("eip1967.proxy.admin")) - 1`.

### _EIP7702_PROXY_DELEGATION_INITIALIZATION_REQUEST_SLOT

```solidity
bytes32 internal constant
    _EIP7702_PROXY_DELEGATION_INITIALIZATION_REQUEST_SLOT =
        0x94e11c6e41e7fb92cb8bb65e13fdfbd4eba8b831292a1a220f7915c78c7c078f
```

The transient storage slot for requesting the proxy to initialize the implementation.   
`uint256(keccak256("eip7702.proxy.delegation.initialization.request")) - 1`.   
While we would love to use a smaller constant, this slot is used in both the proxy   
and the delegation, so we shall just use bytes32 in case we want to standardize this.