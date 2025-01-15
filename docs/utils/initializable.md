# Initializable

Initializable mixin for the upgradeable contracts.






<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### InvalidInitialization()

```solidity
error InvalidInitialization()
```

The contract is already initialized.

### NotInitializing()

```solidity
error NotInitializing()
```

The contract is not initializing.

## Operations

### _initializableSlot()

```solidity
function _initializableSlot() internal pure virtual returns (bytes32)
```

Override to return a non-zero custom storage slot if required.

### initializer()

```solidity
modifier initializer() virtual
```

Guards an initializer function so that it can be invoked at most once.   
You can guard a function with `onlyInitializing` such that it can be called   
through a function guarded with `initializer`.   
This is similar to `reinitializer(1)`, except that in the context of a constructor,   
an `initializer` guarded function can be invoked multiple times.   
This can be useful during testing and is not expected to be used in production.   
Emits an {Initialized} event.

### reinitializer(uint64)

```solidity
modifier reinitializer(uint64 version) virtual
```

Guards an reinitialzer function so that it can be invoked at most once.   
You can guard a function with `onlyInitializing` such that it can be called   
through a function guarded with `reinitializer`.   
Emits an {Initialized} event.

### onlyInitializing()

```solidity
modifier onlyInitializing() virtual
```

Guards a function such that it can only be called in the scope   
of a function guarded with `initializer` or `reinitializer`.

### _checkInitializing()

```solidity
function _checkInitializing() internal view virtual
```

Reverts if the contract is not initializing.

### _disableInitializers()

```solidity
function _disableInitializers() internal virtual
```

Locks any future initializations by setting the initialized version to `2**64 - 1`.   
Calling this in the constructor will prevent the contract from being initialized   
or reinitialized. It is recommended to use this to lock implementation contracts   
that are designed to be called through proxies.   
Emits an {Initialized} event the first time it is successfully called.

### _getInitializedVersion()

```solidity
function _getInitializedVersion()
    internal
    view
    virtual
    returns (uint64 version)
```

Returns the highest version that has been initialized.

### _isInitializing()

```solidity
function _isInitializing() internal view virtual returns (bool result)
```

Returns whether the contract is currently initializing.