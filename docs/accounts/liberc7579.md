# LibERC7579

Library for handling ERC7579 mode and execution data.






<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### DecodingError()

```solidity
error DecodingError()
```

Cannot decode `executionData`.

## Constants

### CALLTYPE_SINGLE

```solidity
bytes1 internal constant CALLTYPE_SINGLE = 0x00
```

A single execution.

### CALLTYPE_BATCH

```solidity
bytes1 internal constant CALLTYPE_BATCH = 0x01
```

A batch of executions.

### CALLTYPE_STATICCALL

```solidity
bytes1 internal constant CALLTYPE_STATICCALL = 0xfe
```

A single `staticcall` execution.

### CALLTYPE_DELEGATECALL

```solidity
bytes1 internal constant CALLTYPE_DELEGATECALL = 0xff
```

A `delegatecall` execution.

### EXECTYPE_DEFAULT

```solidity
bytes1 internal constant EXECTYPE_DEFAULT = 0x00
```

Default execution type that reverts on failure.

### EXECTYPE_TRY

```solidity
bytes1 internal constant EXECTYPE_TRY = 0x01
```

Execution type that does not revert on failure.

## Mode Operations

### encodeMode(bytes1,bytes1,bytes4,bytes22)

```solidity
function encodeMode(
    bytes1 callType,
    bytes1 execType,
    bytes4 selector,
    bytes22 payload
) internal pure returns (bytes32 result)
```

Encodes the fields into a mode.

### getCallType(bytes32)

```solidity
function getCallType(bytes32 mode) internal pure returns (bytes1)
```

Returns the call type of the mode.

### getExecType(bytes32)

```solidity
function getExecType(bytes32 mode) internal pure returns (bytes1)
```

Returns the call type of the mode.

### getSelector(bytes32)

```solidity
function getSelector(bytes32 mode) internal pure returns (bytes4)
```

Returns the selector of the mode.

### getPayload(bytes32)

```solidity
function getPayload(bytes32 mode) internal pure returns (bytes22)
```

Returns the payload stored in the mode.

## Execution Data Operations

### decodeSingle(bytes)

```solidity
function decodeSingle(bytes calldata executionData)
    internal
    pure
    returns (address target, uint256 value, bytes calldata data)
```

Decodes a single call execution.   
Reverts if `executionData` is not correctly encoded.

### decodeSingleUnchecked(bytes)

```solidity
function decodeSingleUnchecked(bytes calldata executionData)
    internal
    pure
    returns (address target, uint256 value, bytes calldata data)
```

Decodes a single call execution without bounds checks.

### decodeDelegate(bytes)

```solidity
function decodeDelegate(bytes calldata executionData)
    internal
    pure
    returns (address target, bytes calldata data)
```

Decodes a single delegate execution.   
Reverts if `executionData` is not correctly encoded.

### decodeDelegateUnchecked(bytes)

```solidity
function decodeDelegateUnchecked(bytes calldata executionData)
    internal
    pure
    returns (address target, bytes calldata data)
```

Decodes a single delegate execution without bounds checks.

### decodeBatch(bytes)

```solidity
function decodeBatch(bytes calldata executionData)
    internal
    pure
    returns (bytes32[] calldata pointers)
```

Decodes a batch.   
Reverts if `executionData` is not correctly encoded.

### decodeBatchUnchecked(bytes)

```solidity
function decodeBatchUnchecked(bytes calldata executionData)
    internal
    pure
    returns (bytes32[] calldata pointers)
```

Decodes a batch without bounds checks.   
This function can be used in `execute`, if the validation phase has already   
decoded the `executionData` with checks via `decodeBatch`.

### decodeBatchAndOpData(bytes)

```solidity
function decodeBatchAndOpData(bytes calldata executionData)
    internal
    pure
    returns (bytes32[] calldata pointers, bytes calldata opData)
```

Decodes a batch and optional `opData`.   
Reverts if `executionData` is not correctly encoded.

### decodeBatchAndOpDataUnchecked(bytes)

```solidity
function decodeBatchAndOpDataUnchecked(bytes calldata executionData)
    internal
    pure
    returns (bytes32[] calldata pointers, bytes calldata opData)
```

Decodes a batch without bounds checks.   
This function can be used in `execute`, if the validation phase has already   
decoded the `executionData` with checks via `decodeBatchAndOpData`.

### hasOpData(bytes)

```solidity
function hasOpData(bytes calldata executionData)
    internal
    pure
    returns (bool result)
```

Returns whether the `executionData` has optional `opData`.

### getExecution(bytes32[],uint256)

```solidity
function getExecution(bytes32[] calldata pointers, uint256 i)
    internal
    pure
    returns (address target, uint256 value, bytes calldata data)
```

Returns the `i`th execution at `pointers`, without bounds checks.   
The bounds check is excluded as this function is intended to be called in a bounded loop.

### reencodeBatch(bytes,bytes)

```solidity
function reencodeBatch(bytes calldata executionData, bytes memory opData)
    internal
    pure
    returns (bytes memory result)
```

Reencodes `executionData` such that it has `opData` added to it.   
Like `abi.encode(abi.decode(executionData, (Call[])), opData)`.   
Useful for forwarding `executionData` with extra `opData`.   
This function does not perform any check on the validity of `executionData`.

### reencodeBatchAsExecuteCalldata(bytes32,bytes,bytes)

```solidity
function reencodeBatchAsExecuteCalldata(
    bytes32 mode,
    bytes calldata executionData,
    bytes memory opData
) internal pure returns (bytes memory result)
```

`abi.encodeWithSignature("execute(bytes32,bytes)", mode, reencodeBatch(executionData, opData))`.

## Helpers

### emptyCalldataBytes()

```solidity
function emptyCalldataBytes()
    internal
    pure
    returns (bytes calldata result)
```

Helper function to return empty calldata bytes.