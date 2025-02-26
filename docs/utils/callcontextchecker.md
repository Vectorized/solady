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

A proxy call can be either via a `delegatecall` to an implementation,   
or a 7702 call on an authority that points to a delegation.

### _onEIP7702Authority()

```solidity
function _onEIP7702Authority()
    internal
    view
    virtual
    returns (bool result)
```

Returns whether the current call context is on a EIP7702 authority   
(i.e. externally owned account).

### _selfImplementation()

```solidity
function _selfImplementation() internal view virtual returns (address)
```

Returns the implementation of this contract.

### _onImplementation()

```solidity
function _onImplementation() internal view virtual returns (bool)
```

Returns whether the current call context is on the implementation itself.

### _checkOnlyEIP7702Authority()

```solidity
function _checkOnlyEIP7702Authority() internal view virtual
```

Requires that the current call context is performed via a EIP7702 authority.

### _checkOnlyProxy()

```solidity
function _checkOnlyProxy() internal view virtual
```

Requires that the current call context is performed via a proxy.

### _checkNotDelegated()

```solidity
function _checkNotDelegated() internal view virtual
```

Requires that the current call context is NOT performed via a proxy.   
This is the opposite of `checkOnlyProxy`.

### onlyEIP7702Authority()

```solidity
modifier onlyEIP7702Authority() virtual
```

Requires that the current call context is performed via a EIP7702 authority.

### onlyProxy()

```solidity
modifier onlyProxy() virtual
```

Requires that the current call context is performed via a proxy.

### notDelegated()

```solidity
modifier notDelegated() virtual
```

Requires that the current call context is NOT performed via a proxy.   
This is the opposite of `onlyProxy`.