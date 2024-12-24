# ReentrancyGuardTransient

Reentrancy guard mixin (transient storage variant).


<b>Note:</b>

This implementation utilizes the `TSTORE` and `TLOAD` opcodes.
Please ensure that the chain you are deploying on supports them.



<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### Reentrancy()

```solidity
error Reentrancy()
```

Unauthorized reentrant call.

## Reentrancy Guard

### nonReentrant()

```solidity
modifier nonReentrant() virtual
```

Guards a function from reentrancy.

### nonReadReentrant()

```solidity
modifier nonReadReentrant() virtual
```

Guards a view function from read-only reentrancy.

### _useTransientReentrancyGuardOnlyOnMainnet()

```solidity
function _useTransientReentrancyGuardOnlyOnMainnet()
    internal
    view
    virtual
    returns (bool)
```

For widespread compatibility with L2s.   
Only Ethereum mainnet is expensive anyways.