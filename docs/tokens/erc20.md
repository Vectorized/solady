# ERC20

Source: [`tokens/ERC20.sol`](https://github.com/Vectorized/solady/blob/main/src/tokens/ERC20.sol)

Solady's ERC20 token implementation is an opinionated and highly optimized implementation of the [ERC20 standard](https://eips.ethereum.org/EIPS/eip-20). It also inherits the [ERC2612 standard](https://eips.ethereum.org/EIPS/eip-2612) which enables permit-based approvals.

## Things to note

- The ERC20 standard does not impose any restriction on the addresses and amounts used. As such, this implementation **WILL NOT** revert for the following:
    - mint to the zero address
    - transfer to and from the zero address
    - transfer zero tokens
    - self approvals
- Every function can be overridden with the `override` keyword if a custom implementation is required.
- The `permit` function uses the ecrecover precompile (0x1). 

## API Reference

### name

Returns the name of the token.

```solidity
function name() public view virtual returns (string memory)
```

#### Parameter(s)

- None

#### Return Value(s)

- string: The name of the token.

#### Note(s)

- Must override or the contract will not compile.

---

### symbol

Returns the symbol of the token.

```solidity
function symbol() public view virtual returns (string memory)
```

#### Parameter(s)

- None

#### Return Value(s)

- string: The symbol of the token.

#### Note(s)

- Must override or the contract will not compile.

---

### decimals

Returns the number of decimals of the token.

```solidity
function decimals() public view virtual returns (uint8)
```

#### Parameter(s)

- None

#### Return Value(s)

- uint8: The number of decimals of the token.

#### Note(s)

- None

---

### totalSupply

Returns the amount of tokens in existence.

```solidity
function totalSupply() public view virtual returns (uint256)
```

#### Parameter(s)

- None

#### Return Value(s)

- uint256: The number of tokens in existence.

#### Note(s)

- None

---

### balanceOf

Returns the amount of tokens owned by an address.

```solidity
function balanceOf(address) public view virtual returns (uint256)
```

#### Parameter(s)

- address: The address to query the token balance of.

#### Return Value(s)

- uint256: The amount of tokens owned by the input address.

#### Note(s)

- None

---

### allowance

Returns the amount of tokens that a spender can spend on behalf of an owner.

```solidity
function allowance(address,address) public view virtual returns (uint256)
```

#### Parameter(s)

- address: The owner of the tokens.
- address: The spender of the tokens.

#### Return Value(s)

- uint256: The amount of tokens that the input spender can spend on behalf of the input owner.

#### Note(s)

- None

---

### approve

Sets an amount of allowance for a spender over the caller's tokens.

```solidity
function approve(address,uint256) public virtual returns (bool)
```

#### Parameter(s)

- address: The spender of the tokens.
- uint256: The amount to set as spender's allowance.

#### Return Value(s)

- bool: `true`

#### Note(s)

- Emits the `Approval` event.

---

### transfer

Transfer an amount of tokens from the caller to a recipient.

```solidity
function transfer(address,uint256) public virtual returns (bool)
```

#### Parameter(s)

- address: The recipient address to receive the tokens.
- uint256: The amount of tokens to transfer from the caller.

#### Return Value(s)

- bool: `true` if it does not revert with `InsufficientBalance`.

#### Note(s)

- Emits the `Transfer` event.
- Reverts with the `InsufficientBalance` error if caller does not have enough tokens.

---

### transferFrom

Transfers an amount of tokens from an owner to a recipient.

```solidity
transferFrom(address,address,uint256) public virtual returns (bool)
```

#### Parameter(s)

- address: The owner address to transfer the tokens from.
- address: The recipient address to receive the tokens.
- uint256: The amount of tokens to be transferred.

#### Return Value(s)

- bool: `true` if it does not revert with `InsufficientAllowance` or `InsufficientBalance`.

#### Note(s)

- Emits the `Transfer` event.
- Does not update caller's allowance if allowance is `type(uint256).max`.
- Reverts with `InsufficientAllowance` error if the caller does not have enough allowance.
- Reverts with `InsufficientBalance` error if the input owner does not have enough tokens.

---

### nonces

Returns the current nonce of an address.

```solidity
function nonces(address) public view virtual returns (uint256)
```

#### Parameter(s)

- address: The address to query the nonce of.

#### Return Value(s)

- uint256: The current nonce of the input address.

#### Note(s)

- This value is used to compute the signature for [EIP-2612 permit](https://eips.ethereum.org/EIPS/eip-2612).

---

### permit

Sets an amount of allowance for a spender over an owner's tokens, authorized by a signed approval by the owner.

```solidity
function permit(address,address,uint256,uint256,uint8,bytes32,bytes32) public virtual
```

#### Parameter(s)

- address: The owner of the tokens.
- address: The spender of the tokens.
- uint256: The amount to set as spender's allowance.
- uint256: The deadline of the signature.
- uint8: The v component of the signature.
- bytes32: The r component of the signature.
- bytes32: The s component of the signature.

#### Return Value(s)

- None

#### Note(s)

- Emits the `Approval` if it does not revert with `PermitExpired` or `InvalidPermit`.
- The input owner's nonce will be incremented by 1 if `permit` is successful.
- Reverts with `PermitExpired` error if the current timestamp is greater than the input deadline.
- Reverts with `InvalidPermit` error if the address recovered does not match the input owner.

---

### DOMAIN_SEPERATOR

Returns the EIP-712 domain separator for the EIP-2612 permit.

```solidity
function DOMAIN_SEPARATOR() public view virtual returns (bytes32)
```

#### Parameter(s)

- None

#### Return Value(s)

- bytes32: The EIP-712 domain separator for the EIP-2612 permit.

#### Note(s)

- None

---

### Errors

| Name                | Description                                  | Selector     |
| ------------------- | -------------------------------------------- | ------------ |
| TotalSupplyOverflow | Thrown when the total supply has overflowed. | `0xe5cfe957` |
| AllowanceOverflow   | Thrown when the allowance has overflowed.    | `0xf9067066` |
| AllowanceUnderflow  | Thrown when the allowance has underflowed.   | `0x8301ab38` |
| InsufficientBalance | Thrown when there is insufficient balance.   | `0xf4d678b8` |
| InvalidPermit       | Thrown when the permit is invalid.           | `0xddafbaef` |
| PermitExpired       | Thrown when the permit has expired.          | `0x1a15a3cc` |

---

### Events

| Name                              | Description                          |
| --------------------------------- | ------------------------------------ |
| Transfer(address,address,uint256) | Emitted when tokens are transferred. |
| Approval(address,address,uint256) | Emitted when allowances are updated. |

---


### Constants

| Name                                     | Value                                                              |
| ---------------------------------------- | ------------------------------------------------------------------ |
| \_TRANSFER_EVENT_SIGNATURE               | 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef |
| \_APPROVAL_EVENT_SIGNATURE               | 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925 |
| \_TOTAL_SUPPLY_SLOT                      | 0x05345cdf77eb68f44c                                               |
| \_BALANCE_SLOT_SEED                      | 0x87a211a2                                                         |
| \_ALLOWANCE_SLOT_SEED                    | 0x7f5e9f20                                                         |
| \_NONCES_SLOT_SEED                       | 0x38377508                                                         |
| \_NONCES_SLOT_SEED_WITH_SIGNATURE_PREFIX | 0x383775081901                                                     |
| \_DOMAIN_TYPEHASH                        | 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f |
| \_VERSION_HASH                           | 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6 |
| \_PERMIT_TYPEHASH                        | 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9 |


---
