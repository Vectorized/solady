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

## Example usage

### Foundry

1. Create a new [foundry](https://github.com/foundry-rs/foundry) repository and navigate to the root folder.

```bash
$ forge init <name of project>
$ cd <name of project>
```

2. Install the Solady library

```bash
$ forge install vectorized/solady
```

3. Create a file called `MyToken.sol` in the `<project name>/src` folder.

```bash
$ touch src/MyToken.sol
```

4. Copy the following implementation into the `MyToken.sol` file.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC20} from "solady/src/tokens/ERC20.sol";

contract MyToken is ERC20 {
    function name() public view override returns (string memory) {
        return "Mytoken";
    }

    function symbol() public view override returns (string memory) {
        return "MYT";
    }
}
```

## Gas Benchmarks

| Function name    | [Solady](https://github.com/Vectorized/solady/blob/main/src/tokens/ERC20.sol) | [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC20Permit.sol) |
| ---------------- | ------ | ------------ |
| DOMAIN_SEPERATOR | 488    | 386          |
| allowance        | 700    | 814          |
| approve          | 24403  | 24762        |
| burn             | 2141   | 2439         |
| decimals         | 222    | 222          |
| mint             | 24649  | 24978        |
| name             | 494    | 3241         |
| nonces           | 555    | 616          |
| permit           | 50437  | 51478        |
| symbol           | 542    | 3306         |
| transfer         | 2235   | 2613         |
| transferFrom     | 2577   | 3295         |

## API Reference

### Functions

| Name                                  | Description                                                                                                        |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| [name](#name)                         | The name of the token.                                                                                             |
| [symbol](#symbol)                     | The symbol of the token.                                                                                           |
| [decimals](#decimals)                 | The number of decimals of the token.                                                                               |
| [totalSupply](#totalsupply)           | The amount of tokens in existence.                                                                                 |
| [balanceOf](#balanceof)               | The amount of tokens owned by `owner`.                                                                             |
| [allowance](#allowance)               | The amount of tokens that `spender` can spend on behalf of `owner`.                                                |
| [approve](#approve)                   | Sets `amount` as the allowance of `spender` over the caller's tokens.                                              |
| [transfer](#transfer)                 | Transfer `amount` tokens from the caller to `to`.                                                                  |
| [transferFrom](#transferfrom)         | Transfers `amount` tokens from `from` to `to`.                                                                     |
| [nonces](#nonces)                     | The current nonce for `owner`.                                                                                     |
| [permit](#permit)                     | Sets `value` as the allowance of `spender` over the tokens of `owner`, authorized by a signed approval by `owner`. |
| [DOMAIN_SEPARATOR](#domain_seperator) | The EIP-712 domain separator for the EIP-2612 permit.                                                              |

---

#### name

Returns the name of the token.

```solidity
function name() public view virtual returns (string memory)
```

##### Parameter(s)

- None

##### Return Value(s)

- The name of the token.

##### Note(s)

- Must override or the contract will not compile.

---

#### symbol

Returns the symbol of the token.

```solidity
function symbol() public view virtual returns (string memory)
```

##### Parameter(s)

- None

##### Return Value(s)

- The symbol of the token.

##### Note(s)

- Must override or the contract will not compile.

---

#### decimals

Returns the number of decimals of the token.

```solidity
function decimals() public view virtual returns (uint8)
```

##### Parameter(s)

- None

##### Return Value(s)

- The number of decimals of the token.

##### Note(s)

- None

---

#### totalSupply

Returns the amount of tokens in existence.

```solidity
function totalSupply() public view virtual returns (uint256 result)
```

##### Parameter(s)

- None

##### Return Value(s)

- `result`: The number of tokens in existence.

##### Note(s)

- None

---

#### balanceOf

Returns the amount of tokens owned by `owner`.

```solidity
function balanceOf(address owner) public view virtual returns (uint256 result)
```

##### Parameter(s)

- `owner`: The address to query the token balance of.

##### Return Value(s)

- `result`: The amount of tokens owned by `owner`.

##### Note(s)

- None

---

#### allowance

Returns the amount of tokens that `spender` can spend on behalf of `owner`.

```solidity
function allowance(address owner, address spender) public view virtual returns (uint256 result)
```

##### Parameter(s)

- `owner`: The owner of the tokens.
- `spender`: The spender of the tokens.

##### Return Value(s)

- `result`: The amount of tokens that `spender` can spend on behalf of `owner`.

##### Note(s)

- None

---

#### approve

Sets `amount` as the allowance of `spender` over the caller's tokens.

```solidity
function approve(address spender, uint256 amount) public virtual returns (bool)
```

##### Parameter(s)

- `spender`: The spender of the tokens.
- `amount`: The amount to set as spender's allowance.

##### Return Value(s)

- `true` if `spender`'s allowance is updated successfully.

##### Note(s)

- Emits the `Approval` event if `spender`'s allowance is updated successfully.

---

#### transfer

Transfer `amount` tokens from the caller to `to`.

```solidity
function transfer(address to, uint256 amount) public virtual returns (bool)
```

##### Parameter(s)

- `to`: The address to receive the tokens.
- `amount`: The amount of tokens to transfer from the caller.

##### Return Value(s)

- `true` if `amount` tokens are transferred from the caller to `to` successfully.

##### Note(s)

- Emits the `Transfer` event if `amount` of tokens are transferred from the caller to `to` successfully.
- Reverts with the `InsufficientBalance` error if caller does not have enough tokens.

---

#### transferFrom

Transfers `amount` tokens from `from` to `to`.

```solidity
transferFrom(address from, address to, uint256 amount) public virtual returns (bool)
```

##### Parameter(s)

- `from`: The address to transfer the tokens from.
- `to`: The address to transfer the tokens to.
- `amount`: The amount of tokens to be transferred.

##### Return Value(s)

- `true` if `amount` of tokens are transferred from `from` to `to`.

##### Note(s)

- Emits the `Transfer` event if `amount` of tokens are transferred from `from` to `to` successfully.
- Does not update caller's allowance if allowance is `type(uint256).max`.
- Reverts with `InsufficientAllowance` error if the caller does not have enough allowance.
- Reverts with `InsufficientBalance` error if `from` does not have enough tokens.

---

#### nonces

Returns the current nonce for `owner`.

```solidity
function nonces(address owner) public view virtual returns (uint256 result)
```

##### Parameter(s)

- `owner`: The address to query the nonce of.

##### Return Value(s)

- `result`: The current nonce of the `owner`.

##### Note(s)

- This value is used to compute the signature for [EIP-2612 permit](https://eips.ethereum.org/EIPS/eip-2612).

---

#### permit

Sets `value` as the allowance of `spender` over the tokens of `owner`, authorized by a signed approval by `owner`.

```solidity
function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual
```

##### Parameter(s)

- `owner`: The owner of the tokens.
- `spender`: The spender of the tokens.
- `value`: The amount to set as spender's allowance.
- `deadline`: The deadline of the signature.
- `v`: The v component of the signature.
- `r`: The r component of the signature.
- `s`: The s component of the signature.

##### Return Value(s)

- None

##### Note(s)

- Emits the `Approval` event if `spender`'s allowance is updated successfully.
- `owner`'s nonce will be incremented by 1 if `permit` is successful.
- Reverts with `PermitExpired` error if the current timestamp is greater than `deadline`.
- Reverts with `InvalidPermit` error if the address recovered does not match the `owner`.

---

#### DOMAIN_SEPERATOR

Returns the EIP-712 domain separator for the EIP-2612 permit.

```solidity
function DOMAIN_SEPARATOR() public view virtual returns (bytes32 result)
```

##### Parameter(s)

- None

##### Return Value(s)

- `result`: The EIP-712 domain separator for the EIP-2612 permit.

##### Note(s)

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

### Events

| Name                              | Description                          |
| --------------------------------- | ------------------------------------ |
| Transfer(address,address,uint256) | Emitted when tokens are transferred. |
| Approval(address,address,uint256) | Emitted when allowances are updated. |
