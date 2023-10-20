# ERC721AQueryable

[`erc721a/contracts/extensions/ERC721AQueryable.sol`](https://github.com/chiru-labs/ERC721A/blob/main/contracts/extensions/ERC721AQueryable.sol)

ERC721A subclass with convenience query functions.

Inherits:

- [ERC721A](erc721a.md)
- [IERC721AQueryable](interfaces.md#ierc721aqueryable) 

## Functions

### \_domainNameAndVersionMayChange

```solidity
function explicitOwnershipOf(uint256 tokenId) public view returns (TokenOwnership memory)
```

Returns the [`TokenOwnership`](erc721a.md#tokenownership) struct at `tokenId` without reverting.

This is useful for on-chain and off-chain querying of ownership data for tokenomics.

The returned struct will contain the following values:

- If the `tokenId` is out of bounds:
  - `addr` = `address(0)`
  - `startTimestamp` = `0`
  - `burned` = `false`

- If the `tokenId` is burned:
  - `addr` = `<Address of owner before token was burned>`
  - `startTimestamp` = `<Timestamp when token was burned>`
  - `burned` = `true`

- Otherwise:
  - `addr` = `<Address of owner>`
  - `startTimestamp` = `<Timestamp of start of ownership>`
  - `burned` = `false`

### explicitOwnershipsOf

```solidity
function explicitOwnershipsOf(
    uint256[] memory tokenIds
) external view returns (TokenOwnership[] memory)
```

Returns an array of `TokenOwnership` structs at `tokenIds` in order.

See [`explicitOwnershipOf`](#explicitOwnershipOf).

### tokensOfOwner

```solidity
function tokensOfOwner(address owner) external view returns (uint256[] memory)
```

Returns an array of token IDs owned by `owner`.

This function scans the ownership mapping and is O(totalSupply) in complexity.  
It is meant to be called off-chain.

See [`tokensOfOwnerIn`](#tokensOfOwnerIn) for splitting the scan into 
multiple smaller scans if the collection is large enough to 
cause an out-of-gas error. 

This function should work fine for 10k PFP collections.

### tokensOfOwnerIn

```solidity
function tokensOfOwnerIn(
    address owner,
    uint256 start,
    uint256 stop
) external view returns (uint256[] memory)
```

Returns an array of token IDs owned by `owner`,
in the range \[`start`, `stop`)  
(i.e. `start` &le; `tokenId` &lt; `stop`).

This function allows for tokens to be queried if the collection
grows too big for a single call of [`tokensOfOwner`](#tokensOfOwner).

Requirements:

- `start` < `stop`.