# BlockHashLib

Library for accessing block hashes way beyond the 256-block limit.






<!-- customintro:start --><!-- customintro:end -->

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