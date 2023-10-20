# ERC721ABurnable

[`erc721a/contracts/extensions/ERC721ABurnable.sol`](https://github.com/chiru-labs/ERC721A/blob/main/contracts/extensions/ERC721ABurnable.sol)

ERC721A Token that can be irreversibly burned (destroyed).

Inherits:

- [ERC721A](erc721a.md)
- [IERC721ABurnable](interfaces.md#ierc721aburnable) 

## Functions

### burn

```solidity
function burn(uint256 tokenId) public virtual
```

Burns `tokenId`. See [`ERC721A._burn`](erc721a.md#_burn).

Requirements:

- The caller must own `tokenId` or be an approved operator.

