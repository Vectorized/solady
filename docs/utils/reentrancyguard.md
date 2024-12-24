# ReentrancyGuard

Reentrancy guard mixin.






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