# BlockHashLib

Library for accessing block hashes way beyond the 256-block limit.






<!-- customintro:start --><!-- customintro:end -->

## Structs

### ShortHeader

```solidity
struct ShortHeader {
    bytes32 parentHash;
    bytes32 stateRoot;
    bytes32 transactionsRoot;
    bytes32 receiptsRoot;
    bytes32[8] logsBloom;
}
```

Ethereum block header fields relevant to historical MPT proofs.

## Custom Errors

### BlockHashMismatch()

```solidity
error BlockHashMismatch()
```

The keccak256 of the RLP-encoded block header does not equal to the block hash.

### InvalidBlockHeaderEncoding()

```solidity
error InvalidBlockHeaderEncoding()
```

The block header is not properly RLP-encoded.

## Constants

### HISTORY_STORAGE_ADDRESS

```solidity
address internal constant HISTORY_STORAGE_ADDRESS =
    0x0000F90827F1C53a10cb7A02335B175320002935
```

Address of the EIP-2935 history storage contract.   
See: https://eips.ethereum.org/EIPS/eip-2935

## Operations

### blockHash(uint256)

```solidity
function blockHash(uint256 blockNumber)
    internal
    view
    returns (bytes32 result)
```

Retrieves the block hash for any historical block within the supported range.   
The function gracefully handles future blocks and blocks beyond the history window by returning zero,   
consistent with the EVM's native `BLOCKHASH` behavior.

### verifyBlock(bytes,uint256)

```solidity
function verifyBlock(bytes calldata encodedHeader, uint256 blockNumber)
    internal
    view
    returns (bytes32 result)
```

Reverts if `keccak256(encodedHeader) != blockHash(blockNumber)`,   
where `encodedHeader` is a RLP-encoded block header.   
Else, returns `blockHash(blockNumber)`.

### toShortHeader(bytes)

```solidity
function toShortHeader(bytes calldata encodedHeader)
    internal
    pure
    returns (ShortHeader memory result)
```

Retrieves the most relevant fields for MPT proofs from an RLP-encoded block header.   
Leading fields are always present and have fixed offsets and lengths.   
This function efficiently extracts the fields without full RLP decoding.   
For the specification of field order and lengths, please refer to   
prefix. 6 of the Ethereum Yellow Paper:   
(https://ethereum.github.io/yellowpaper/paper.pdf)   
and the Ethereum Wiki (https://epf.wiki/#/wiki/EL/RLP).