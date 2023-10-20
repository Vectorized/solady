# Tips

## Transfers

For users, it is more gas optimal to transfer bulk minted tokens in ascending token ID order.

For example, if you have bulk minted token IDs (33, 34, ..., 99),  
you should transfer in the order (33, 34, ..., 99).

This is due to how the lazy-initialization mechanism works internally:  
it scans uninitialized slots in descending order until it finds an initialized slot.

## Popularity

The more popular your NFT collection, the larger the expected savings in transaction fees.

See [Design: Lower Fees](design.md#lower-fees).

## Aux

Consider using [`ERC721A._getAux`](erc721a.md#_getAux) and
[`ERC721A._setAux`](erc721a.md#_setAux) to get / set per-address variables  
(e.g. number of whitelist mints per address).

This can help remove an extra cold `SLOAD` and `SSTORE` operation.

## Minting

For typical artwork collections, consider using `_mint` over `_safeMint` if you don't expect users to mint to contracts.

## Batch Size

During transfers, ERC721A scans through ownership storage slots until it finds an initialized slot.

To prevent expensive first-time transfer fees for tokens minted in large batches, either:

- Restrict the max batch size for public mints to a reasonable number.

- Break up excessively large batches into mini batches internally when minting.

- Use [`_initializeOwnershipAt`](erc721a.md#_initializeOwnershipAt) every couple tokens to reduce number of reads during a transfer.

## Efficient Tokenomics

ERC721A keeps track of additional variables in the internal mappings.

- [`startTimestamp`](erc721a.md#_ownershipOf) (starting time of holding) per token.
- [`numberMinted`](erc721a.md#_numberMinted) per address.
- [`numberBurned`](erc721a.md#_numberBurned) per address.

These variables hitchhike on the `SLOAD`s and `SSTORE`s at near zero additional gas cost (< 1%).

You can use them to design tokenomics with very minimal gas overhead.

> The [`startTimestamp`](erc721a.md#_ownershipOf), is available via the 
> [`TokenOwnership`](erc721a.md#TokenOwnership) struct.
>
> You can get it from the 
> [`_ownershipOf`](erc721a.md#_ownershipOf) function or the non-reverting 
> [`ERC721AQueryable.explicitOwnershipOf`](erc721a-queryable.md#explicitOwnershipOf) function.

## ERC721A vs ERC1155

|                  | ERC721A        | ERC1155                |
| ---------------- | -------------- | ---------------------- |
| O(1) ownerOf     | Yes            | No ownerOf             |
| O(1) balanceOf   | For all tokens | Within fungible tokens |
| O(1)\* bulk mint | For all tokens | Within fungible tokens |
| # mint `SSTORE`s | 3              | 1 <sup>&#8224;</sup>   |

\* Approximately O(1) for ERC721A. See [Design](design.md).

<sup>&#8224;</sup> For unique collections, ERC1155 needs a counter which needs 1 more `SSTORE`.

ERC1155 requires centralized indexing services to emulate ERC721-like functionality off-chain.

## Other Implementations

ERC721A is not a one-size-fits-all solution.

It is heavily optimized for generative artwork NFT collections.

If your collection does not expect a busy mint phase (e.g. a pure utility NFT),  
or does not require bulk minting,  
these excellent implementations can be better for lowering overall transaction fees:

- [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [Solmate](https://github.com/Rari-Capital/solmate)

Use the right tool for the job.
