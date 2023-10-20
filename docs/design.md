# Design

ERC721A enables a near constant gas cost for batch minting via a lazy-initialization mechanism.

Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...).

Regardless of the quantity minted, the `_mint` function only performs 3 `SSTORE` operations:

- Initialize the ownership slot at the starting token ID with the address.
- Update the address' balance.
- Update the next token ID.

> A `Transfer` event will still be emitted for each NFT minted.   
  However, emitting an event is an order of magnitude cheaper than a `SSTORE` operation.

## Lower Fees

ERC721A defers the initialization of token ownership slots from minting to transferring.

This allows users to batch mint with low, near-constant transaction fees, and pick a good time to transfer when the network's BASEFEE is lower.

Although this has a higher total gas cost (minting + transfers), **it gives significantly lower overall transaction fees in practice**. 

> Transaction Fee = (BASEFEE + Max Priority Per Gas) * Gas Used

Gas savings during high BASEFEE periods matter **more**.

As such, ERC721A prioritizes gas savings for the minting phase.

### Benchmark

To illustrate, we compare OpenZeppelin's ERC721 with ERC721A.

|                            | ERC721       | ERC721A        |
| -------------------------- | ------------ | -------------- |
| Batch Mint 5 Tokens        | 155949 gas   | 63748 gas      |
| Transfer 5 Tokens          | 226655 gas   | 334450 gas     |
| Mint BASEFEE               | 200 gwei     | 200 gwei       |
| Transfer BASEFEE           | 40 gwei      | 40 gwei        |
| Total Transaction Fees     | 0.0403 ether | 0.0261 ether   |

Even for conservatively small batch sizes (e.g. 5), we can observe decent savings over the barebones implementation. 

In practice, the Mint BASEFEE for ERC721 can be much higher. 

When consecutive blocks hit the block gas limit, [the BASEFEE increases exponentially](https://ethereum.org/en/developers/docs/gas/#base-fee). 

#### First Transfer vs Subsequent Transfers

The main overhead of transferring a token **only occurs during its very first transfer** for an uninitialized slot. 

|                            | ERC721       | ERC721A        |
| -------------------------- | ------------ | -------------- |
| First transfer             | 45331 gas    | 92822 gas      |
| Subsequent transfers       | 45331 gas    | 44499 gas      |

Here, we bulk mint 10 tokens, and compare the transfer costs of the 5th token in the batch.

To keep the cost of the `SSTORE` writing to the balance mapping constant, we ensure that the destination addresses have non-zero balances during all transfers.

The first transfer with ERC721A will incur the storage overheads:

- 2 extra `SSTORE`s (initialize current slot and next slot, both of which are empty).
- 5 extra `SLOAD`s (read previous slots and next slot).

## Balance Mapping

ERC721A maintains an internal mapping of address balances. This is an important and deliberate design decision:

- The `balanceOf` function is required by the ERC721 standard. 
  
  We understand that it is tempting to remove the mapping -- it can save a `SSTORE` during mints, and 2 `SSTORE`s during transfers. 

  However, this degrades the `balanceOf` function to become O(n) in complexity -- it must bruteforce through the entire mapping of ownerships. This hampers on-chain interoperability and scalability.

- While it is possible to emulate the `balanceOf` function by listening to emitted events, this requires users to use centralized indexing services. 

  In the case of service disruption, the data can get out-of-sync and hard to reconstruct.

- In the context of saving gas, we are able to allow whitelist minting achieve the same amount of `SSTORE`s when compared to implementations without the mapping. See `ERC721A._getAux` and `ERC721A._setAux`. 

  The address balance mapping is also used to store the mint and burn counts per address with negligible overhead, which can be very useful for tokenomics.

In all, the address balance mapping gives a good balance of features and gas savings, which makes it desirable to keep.

