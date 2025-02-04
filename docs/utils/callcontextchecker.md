# CallContextChecker

Call context checker mixin.






<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### UnauthorizedCallContext()

```solidity
error UnauthorizedCallContext()
```

The call is from an unauthorized call context.

## Call Context Checks

### _checkOnlyProxy()

```solidity
function _checkOnlyProxy() internal view
```

Requires that the execution is performed through a proxy.

### _checkNotDelegated()

```solidity
function _checkNotDelegated() internal view
```

Requires that the execution is NOT performed via delegatecall.   
This is the opposite of `checkOnlyProxy`.

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