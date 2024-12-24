# LibCall

Library for making calls.


<b>Note:</b>

- The arguments of the functions may differ from the libraries.
Please read the functions carefully before use.



<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### TargetIsNotContract()

```solidity
error TargetIsNotContract()
```

The target of the call is not a contract.

### DataTooShort()

```solidity
error DataTooShort()
```

The data is too short to contain a function selector.

## Contract Call Operations

These functions will revert if called on a non-contract   
(i.e. address without code).   
They will bubble up the revert if the call fails.

### callContract(address,uint256,bytes)

```solidity
function callContract(address target, uint256 value, bytes memory data)
    internal
    returns (bytes memory result)
```

Makes a call to `target`, with `data` and `value`.

### callContract(address,bytes)

```solidity
function callContract(address target, bytes memory data)
    internal
    returns (bytes memory result)
```

Makes a call to `target`, with `data`.

### staticCallContract(address,bytes)

```solidity
function staticCallContract(address target, bytes memory data)
    internal
    view
    returns (bytes memory result)
```

Makes a static call to `target`, with `data`.

### delegateCallContract(address,bytes)

```solidity
function delegateCallContract(address target, bytes memory data)
    internal
    returns (bytes memory result)
```

Makes a delegate call to `target`, with `data`.

## Try Call Operations

These functions enable gas limited calls to be performed,   
with a cap on the number of return data bytes to be copied.   
The can be used to ensure that the calling contract will not   
run out-of-gas.

### tryCall(address,uint256,uint256,uint16,bytes)

```solidity
function tryCall(
    address target,
    uint256 value,
    uint256 gasStipend,
    uint16 maxCopy,
    bytes memory data
)
    internal
    returns (bool success, bool exceededMaxCopy, bytes memory result)
```

Makes a call to `target`, with `data` and `value`.   
The call is given a gas limit of `gasStipend`,   
and up to `maxCopy` bytes of return data can be copied.

### tryStaticCall(address,uint256,uint16,bytes)

```solidity
function tryStaticCall(
    address target,
    uint256 gasStipend,
    uint16 maxCopy,
    bytes memory data
)
    internal
    view
    returns (bool success, bool exceededMaxCopy, bytes memory result)
```

Makes a call to `target`, with `data`.   
The call is given a gas limit of `gasStipend`,   
and up to `maxCopy` bytes of return data can be copied.

## Other Operations

### bubbleUpRevert(bytes)

```solidity
function bubbleUpRevert(bytes memory revertReturnData) internal pure
```

Bubbles up the revert.

### setSelector(bytes4,bytes)

```solidity
function setSelector(bytes4 newSelector, bytes memory data) internal pure
```

In-place replaces the function selector of encoded contract call data.