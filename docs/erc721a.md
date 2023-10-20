# ERC721A

[`erc721a/contracts/ERC721A.sol`](https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol)

Implementation of [ERC721](https://eips.ethereum.org/EIPS/eip-721) Non-Fungible Token Standard, including the Metadata extension. Built to optimize for lower gas during batch mints.

Token IDs are minted sequentially (e.g. 0, 1, 2, 3...) starting from `_startTokenId()`.

An owner cannot have more than `2**64 - 1` (max value of `uint64`) tokens.

Inherits:

- [IERC721A](interfaces.md#ierc721a) 

## Structs

### TokenOwnership 

```solidity
struct TokenOwnership {
    // The address of the owner.
    address addr;
    // Keeps track of the start time of ownership with minimal overhead for tokenomics.
    uint64 startTimestamp;
    // Whether the token has been burned.
    bool burned;
}
```

Holds ownership data for each token.

`startTimestamp` is the timestamp when the token is minted to, transferred to, or burned by `addr`.


## Functions

### constructor

```solidity
constructor(string memory name_, string memory symbol_)
```

Initializes the contract by setting a `name` and a `symbol` to the token collection.

### supportsInterface 

`IERC165-supportsInterface`

```solidity
function supportsInterface(bytes4 interfaceId) public view virtual returns (bool)
```

Returns `true` if this contract implements the interface defined by `interfaceId`. 

See the corresponding [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified) to learn more about how these ids are created.

See [migration](migration.md#supportsInterface) for `supportsInterface`.

### totalSupply

`IERC721Enumerable-totalSupply`

```solidity
function totalSupply() public view returns (uint256)
```

Returns the total number of tokens in existence. 

Burned tokens will reduce the count.

To get the total number of tokens minted, please see [`_totalMinted`](#_totalMinted).

### balanceOf

`IERC721-balanceOf`

```solidity
function balanceOf(address owner) public view override returns (uint256)
```

Returns the number of tokens in `owner`'s account.

### ownerOf

`IERC721-ownerOf`

```solidity
function ownerOf(uint256 tokenId) public view override returns (address)
```

Returns the owner of the `tokenId` token.

Requirements:

- `tokenId` must exist.

### name

`IERC721Metadata-name`

```solidity
function name() public view virtual override returns (string memory)
```

Returns the token collection name.

### symbol

`IERC721Metadata-symbol`

```solidity
function symbol() public view virtual override returns (string memory)
```

Returns the token collection symbol.

### tokenURI

`IERC721Metadata-tokenURI`

```solidity
function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
```

Returns the Uniform Resource Identifier (URI) for `tokenId` token.

See [`_baseURI`](#_baseURI) and [`_toString`](#_toString).


### approve

`IERC721-approve`

```solidity
function approve(address to, uint256 tokenId) public override
```

Gives permission to `to` to transfer `tokenId` token to another account. The approval is cleared when the token is transferred.

Only a single account can be approved at a time, so approving the zero address clears previous approvals.

Requirements:

- The caller must own the token or be an approved operator.
- `tokenId` must exist.

Emits an `Approval` event.

### getApproved

```solidity
function getApproved(uint256 tokenId) public view override returns (address)
```

`IERC721-getApproved`

Returns the account approved for `tokenId` token.

Requirements:

- `tokenId` must exist.

### setApprovalForAll

`IERC721-setApprovalForAll`

```solidity
function setApprovalForAll(
    address operator, 
    bool approved
) public virtual override
```

Approve or remove `operator` as an operator for the caller. Operators can call `transferFrom` or `safeTransferFrom` for any token owned by the caller.

Requirements:

- The `operator` cannot be the caller.

Emits an `ApprovalForAll` event.

### isApprovedForAll

`IERC721-isApprovedForAll`

```solidity
function isApprovedForAll(
    address owner, 
    address operator
) public view virtual override returns (bool)
```

Returns if the `operator` is allowed to manage all of the assets of owner.

See [`setApprovalForAll`](#setApprovalForAll).

### transferFrom

`IERC721-transferFrom`

```solidity
function transferFrom(
    address from, 
    address to, 
    uint256 tokenId
) public virtual override
```

Transfers `tokenId` token from `from` to `to`.

Requirements:

- `from` cannot be the zero address.
- `to` cannot be the zero address.
- `tokenId` token must be owned by `from`.
- If the caller is not `from`, it must be approved to move this token by either `approve` or `setApprovalForAll`.

Emits a `Transfer` event.

### safeTransferFrom

`IERC721-safeTransferFrom`

```solidity
function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
) public virtual override
```

Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients are aware of the ERC721 protocol to prevent tokens from being forever locked.

The `data` parameter is forwarded in `IERC721Receiver.onERC721Received` to contract recipients (optional, default: `""`).

Requirements:

- `from` cannot be the zero address.
- `to` cannot be the zero address.
- `tokenId` token must be owned by `from`.
- If the caller is not `from`, it must be approved to move this token by either `approve` or `setApprovalForAll`.
- If `to` refers to a smart contract, it must implement `IERC721Receiver.onERC721Received`, which is called upon a safe transfer.

Emits a `Transfer` event.


### \_startTokenId

```solidity
function _startTokenId() internal view virtual returns (uint256)
```

Returns the starting token ID (default: `0`). 

To change the starting token ID, override this function to return a different constant. 


### \_nextTokenId

```solidity
function _nextTokenId() internal view virtual returns (uint256)
```

Returns the next token ID to be minted.


### \_totalMinted

```solidity
function _totalMinted() internal view returns (uint256)
```

Returns the total amount of tokens minted.

### \_numberMinted

```solidity
function _numberMinted(address owner) internal view returns (uint256)
```

Returns the number of tokens minted by or on behalf of `owner`.

### \_totalBurned

```solidity
function _totalBurned() internal view returns (uint256)
```

Returns the total amount of tokens burned.


### \_numberBurned

```solidity
function _numberBurned(address owner) internal view returns (uint256)
```

Returns the number of tokens burned by or on behalf of `owner`.

### \_getAux

```solidity
function _getAux(address owner) internal view returns (uint64)
```

Returns the auxiliary data for `owner` (e.g. number of whitelist mint slots used).

### \_setAux

```solidity
function _setAux(address owner, uint64 aux) internal
```

Sets the auxiliary data for `owner` (e.g. number of whitelist mint slots used).

If there are multiple variables, please pack them into a `uint64`.


### \_ownershipOf

```solidity
function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory)
```

Returns the token ownership data for `tokenId`. See [`TokenOwnership`](#TokenOwnership).

The gas spent here starts off proportional to the maximum mint batch size.

It gradually moves to O(1) as tokens get transferred around in the collection over time. 


### \_ownershipAt

```solidity
function _ownershipAt(uint256 index) internal view returns (TokenOwnership memory)
```

Returns the token ownership data at the `index` slot. See [`TokenOwnership`](#TokenOwnership).

The token ownership data may or may not be initialized. 


### \_initializeOwnershipAt

```solidity
function _initializeOwnershipAt(uint256 index) internal
```

Initializes the token ownership data at the `index` slot, if it has not been initialized.

If the batch minted is very large, this function can be used to initialize some tokens to 
reduce the first-time transfer costs.


### \_exists

```solidity
function _exists(uint256 tokenId) internal view returns (bool)
```

Returns whether `tokenId` exists.

Tokens can be managed by their owner or approved accounts via `approve` or `setApprovalForAll`.

Tokens start existing when they are minted via `_mint`.

### \_safeMint

```solidity
function _safeMint(
    address to,
    uint256 quantity,
    bytes memory _data
) internal
```

The `data` parameter is forwarded in `IERC721Receiver.onERC721Received` to contract recipients (optional, default: `""`).

**Safe minting is reentrancy safe since V3.**

See [`_mint`](#_mint).

### \_mint

```solidity
function _mint(
    address to,
    uint256 quantity
) internal
```

Mints `quantity` tokens and transfers them to `to`.

> To prevent excessive first-time token transfer costs, please limit the `quantity` to a reasonable number (e.g. 30).   
> 
> Extremely large `quantity` amounts (e.g. > 5000) may result in some marketplaces and indexers to drop some `Transfer` events, 
> and cause some mints to not appear.

Requirements:

- `to` cannot be the zero address.
- `quantity` must be greater than `0`.

Emits a `Transfer` event.

### \_mintERC2309

```solidity
function _mintERC2309(
    address to,
    uint256 quantity
) internal
```

Mints `quantity` tokens and transfers them to `to`.

This function is intended for efficient minting **only** during contract creation.

It emits only one `ConsecutiveTransfer` as defined in [ERC2309](https://eips.ethereum.org/EIPS/eip-2309), 
instead of a sequence of `Transfer` event(s).

Calling this function outside of contract creation **will** make your contract non-compliant with the ERC721 standard.

For full ERC721 compliance, substituting ERC721 `Transfer` event(s) with the ERC2309 
`ConsecutiveTransfer` event is only permissible during contract creation.

> To prevent overflows, the function limits `quantity` to a maximum of 5000.

Requirements:

- `to` cannot be the zero address.
- `quantity` must be greater than `0`.

Emits a `ConsecutiveTransfer` event.

### \_burn

```solidity
function _burn(uint256 tokenId, bool approvalCheck) internal virtual
```

Destroys `tokenId`.

The approval is cleared when the token is burned.

Requirements:

- `tokenId` must exist.
- If `approvalCheck` is `true`, the caller must own `tokenId` or be an approved operator.

Emits a `Transfer` event.


### \_baseURI

```solidity
function _baseURI() internal view virtual returns (string memory)
```

Base URI for computing `tokenURI`.

If set, the resulting URI for each token will be the concatenation of the `baseURI` and the `tokenId`.

Empty by default, it can be overridden in child contracts.


### \_beforeTokenTransfers

```solidity
function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
) internal virtual
```

Hook that is called before a set of serially-ordered token IDs are about to be transferred. This includes minting.

Also called before burning one token.
     
`startTokenId` - the first token ID to be transferred.  
`quantity` - the amount to be transferred.

Calling conditions:

- When `from` and `to` are both non-zero, `from`'s `tokenId` will be transferred to `to`.
- When `from` is zero, `tokenId` will be minted for `to`.
- When `to` is zero, `tokenId` will be burned by `from`.
- `from` and `to` are never both zero.


### \_afterTokenTransfers

```solidity
function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
) internal virtual
```

Hook that is called after a set of serially-ordered token IDs are about to be transferred. This includes minting.

Also called after burning one token.
     
`startTokenId` - the first token ID to be transferred.  
`quantity` - the amount to be transferred.

Calling conditions:

- When `from` and `to` are both non-zero, `from`'s `tokenId` will be transferred to `to`.
- When `from` is zero, `tokenId` will be minted for `to`.
- When `to` is zero, `tokenId` will be burned by `from`.
- `from` and `to` are never both zero.


### \_toString

```solidity
function _toString(uint256 value) internal pure returns (string memory)
```

Converts a `uint256` to its ASCII `string` decimal representation.

This function is provided as a drop-in replacement for OpenZeppelin's `Strings.toString(uint256 value)`.


### \_msgSenderERC721A

```solidity
function _msgSenderERC721A() internal view virtual returns (address) 
```

Returns the message sender (defaults to `msg.sender`). 

If you are writing [GSN compatible contracts](https://docs.openzeppelin.com/contracts/2.x/gsn), 
you need to override this function   
(to return `_msgSender()` if using with OpenZeppelin).

### \_extraData

```solidity
function _extraData(
    address from,
    address to,
    uint24 previousExtraData
) internal view virtual returns (uint24)
```

Called during each token transfer to set the 24bit `extraData` field.

This is an advanced storage hitchhiking feature for storing token related data.

Intended to be overridden by the deriving contract to return the value to be stored after transfer.

`previousExtraData` - the value of `extraData` before transfer.

Calling conditions:

- When `from` and `to` are both non-zero, `from`'s `tokenId` will be transferred to `to`.
- When `from` is zero, `tokenId` will be minted for `to`.
- When `to` is zero, `tokenId` will be burned by `from`.
- `from` and `to` are never both zero.

### \_setExtraDataAt

```solidity
function _setExtraDataAt(uint256 index, uint24 extraData) internal
```

Directly sets the `extraData` for the ownership data at `index`.

This is an advanced storage hitchhiking feature for storing token related data.

Requirements:

- The token at `index` must be initialized.  
  For bulk mints, `index` is the value of [`_nextTokenId`](#_nextTokenId) before bulk minting.


## Events

### Transfer

`IERC721-Transfer`

```solidity
event Transfer(address from, address to, uint256 tokenId)
```

Emitted when `tokenId` token is transferred from `from` to `to`.

### Approval

`IERC721-Approval`

```solidity
event Approval(address owner, address approved, uint256 tokenId)
```

Emitted when `owner` enables `approved` to manage the `tokenId` token.

### ApprovalForAll

`IERC721-ApprovalForAll`

```solidity
event ApprovalForAll(address owner, address operator, bool approved)
```

Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.

### ConsecutiveTransfer

`IERC2309-ConsecutiveTransfer`

```solidity
event ConsecutiveTransfer(
    uint256 indexed fromTokenId, 
    uint256 toTokenId,
    address indexed from, 
    address indexed to
)
```

Emitted when tokens from `fromTokenId` to `toTokenId` (inclusive) are transferred from `from` to `to`, during contract creation.
