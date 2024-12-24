# MetadataReaderLib

Library for reading contract metadata robustly.






<!-- customintro:start --><!-- customintro:end -->

## Constants

### GAS_STIPEND_NO_GRIEF

```solidity
uint256 internal constant GAS_STIPEND_NO_GRIEF = 100000
```

Default gas stipend for contract reads. High enough for most practical use cases   
(able to SLOAD about 1000 bytes of data), but low enough to prevent griefing.

### STRING_LIMIT_DEFAULT

```solidity
uint256 internal constant STRING_LIMIT_DEFAULT = 1000
```

Default string byte length limit.

## Metadata Reading Operations

Best-effort string reading operations.   
Should NOT revert as long as sufficient gas is provided.   
Performs the following in order:   
1. Returns the empty string for the following cases:   
- Reverts.   
- No returndata (e.g. function returns nothing, EOA).   
- Returns empty string.   
2. Attempts to `abi.decode` the returndata into a string.   
3. With any remaining gas, scans the returndata from start to end for the   
   null byte '\0', to interpret the returndata as a null-terminated string.

### readName(address)

```solidity
function readName(address target) internal view returns (string memory)
```

Equivalent to `readString(abi.encodeWithSignature("name()"))`.

### readName(address,uint256)

```solidity
function readName(address target, uint256 limit)
    internal
    view
    returns (string memory)
```

Equivalent to `readString(abi.encodeWithSignature("name()"), limit)`.

### readName(address,uint256,uint256)

```solidity
function readName(address target, uint256 limit, uint256 gasStipend)
    internal
    view
    returns (string memory)
```

Equivalent to `readString(abi.encodeWithSignature("name()"), limit, gasStipend)`.

### readSymbol(address)

```solidity
function readSymbol(address target) internal view returns (string memory)
```

Equivalent to `readString(abi.encodeWithSignature("symbol()"))`.

### readSymbol(address,uint256)

```solidity
function readSymbol(address target, uint256 limit)
    internal
    view
    returns (string memory)
```

Equivalent to `readString(abi.encodeWithSignature("symbol()"), limit)`.

### readSymbol(address,uint256,uint256)

```solidity
function readSymbol(address target, uint256 limit, uint256 gasStipend)
    internal
    view
    returns (string memory)
```

Equivalent to `readString(abi.encodeWithSignature("symbol()"), limit, gasStipend)`.

### readString(address,bytes)

```solidity
function readString(address target, bytes memory data)
    internal
    view
    returns (string memory)
```

Performs a best-effort string query on `target` with `data` as the calldata.   
The string will be truncated to `STRING_LIMIT_DEFAULT` (1000) bytes.

### readString(address,bytes,uint256)

```solidity
function readString(address target, bytes memory data, uint256 limit)
    internal
    view
    returns (string memory)
```

Performs a best-effort string query on `target` with `data` as the calldata.   
The string will be truncated to `limit` bytes.

### readString(address,bytes,uint256,uint256)

```solidity
function readString(
    address target,
    bytes memory data,
    uint256 limit,
    uint256 gasStipend
) internal view returns (string memory)
```

Performs a best-effort string query on `target` with `data` as the calldata.   
The string will be truncated to `limit` bytes.

### readDecimals(address)

```solidity
function readDecimals(address target) internal view returns (uint8)
```

Equivalent to `uint8(readUint(abi.encodeWithSignature("decimals()")))`.

### readDecimals(address,uint256)

```solidity
function readDecimals(address target, uint256 gasStipend)
    internal
    view
    returns (uint8)
```

Equivalent to `uint8(readUint(abi.encodeWithSignature("decimals()"), gasStipend))`.

### readUint(address,bytes)

```solidity
function readUint(address target, bytes memory data)
    internal
    view
    returns (uint256)
```

Performs a best-effort uint query on `target` with `data` as the calldata.

### readUint(address,bytes,uint256)

```solidity
function readUint(address target, bytes memory data, uint256 gasStipend)
    internal
    view
    returns (uint256)
```

Performs a best-effort uint query on `target` with `data` as the calldata.