# Migration to 4.x

In version 4.x, we have made the following breaking changes:

- Removed OpenZeppelin
- Made some variables private
- Updated Upgradeable to use Diamond storage

## API Changes

### \_currentIndex

The `_currentIndex` variable has been made private.

Please use [`_nextTokenId`](erc721a.md#_nextTokenId) instead.

If you need a `tokensOfOwner` function, please use [`ERC721AQueryable.tokensOfOwner`](erc721a-queryable.md#tokensOfOwner).

### \_burnCounter

The `_burnCounter` variable has been made private.

Please use [`_totalBurned`](erc721a.md#_totalBurned) instead.

### \_ownerships

The `_ownerships` mapping has been made private.

Please use the following instead:
- [`_ownershipOf`](erc721a.md#_ownershipOf)
- [`ERC721AQueryable.explicitOwnershipOf`](erc721a-queryable.md#explicitOwnershipOf) (non-reverting)
- [`ERC721AQueryable.tokensOfOwner`](erc721a-queryable.md#tokensOfOwner)
- [`_ownershipAt`](erc721a.md#_ownershipAt)

### \_msgSender

The dependency on OpenZeppelin `_msgSender` has been removed.

Please use [`_msgSenderERC721A`](erc721a.md#_msgSenderERC721A) instead.

### Strings.toString

Due to removal of OpenZeppelin, `Strings.toString` has been removed.

Please use [`_toString`](erc721a.md#_toString) instead.

### supportsInterface

Due to removal of OpenZeppelin, using `super.supportsInterface` in the function override may not work.

When using with OpenZeppelin's libraries (e.g. [ERC2981](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/common/ERC2981.sol)), you will have to do the following:

```solidity
function supportsInterface(
    bytes4 interfaceId
) public view virtual override(ERC721A, ERC2981) returns (bool) {
    // Supports the following `interfaceId`s:
    // - IERC165: 0x01ffc9a7
    // - IERC721: 0x80ac58cd
    // - IERC721Metadata: 0x5b5e139f
    // - IERC2981: 0x2a55205a
    return 
        ERC721A.supportsInterface(interfaceId) || 
        ERC2981.supportsInterface(interfaceId);
}
```

### ERC721AOwnersExplicit

The `ERC721AOwnersExplicit` extension has been removed. 

Please use [`_initializeOwnershipAt`](erc721a.md#_initializeOwnershipAt) instead.

You can make your own public wrapper function to initialize the slots for any desired range in a loop.

## Diamond Storage

If your upgradeable contracts are deployed using version 3.x,  
they will **NOT** be compatible with version 4.x.

Using version 4.x to upgrade upgradeable contracts deployed with 3.x will lead to unintended consequences.

You will need to either continue using 3.3.0 (the last compatible version),  
or redeploy from scratch with 4.x (the redeployed contracts will not have the previous data).

Version 4.x of ERC721A Upgradeable will be compatible with the non-diamond OpenZeppelin Upgradeable libraries.

