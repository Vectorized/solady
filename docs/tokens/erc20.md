# ERC20

Source: [`tokens/ERC20.sol`](https://github.com/Vectorized/solady/blob/main/src/tokens/ERC20.sol)

Solady's ERC20 token implementation is an opinionated and highly optimized implementation of the [ERC20 standard](https://eips.ethereum.org/EIPS/eip-20). It also inherits the [ERC2612 standard](https://eips.ethereum.org/EIPS/eip-2612) which enables permit-based approvals.

## Things to note

- The ERC20 standard does not impose any restriction on the addresses and amounts used. As such, this implementation **WILL NOT** revert for the following:
    - mint to the zero address
    - transfer to and from the zero address
    - transfer zero tokens
    - self approvals
- If any of these functionalities are required, please override the relevant functions and add your checks.
- Every function can be overridden with the `override` keyword if a different implementation is required.
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

TODO

## API Reference

### Functions

| Name                                  | Description                                                                                                        |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| [name](#name)                         | The name of the token.                                                                                             |
| [symbol](#symbol)                     | The symbol of the token.                                                                                           |
| [decimals](#decimals)                 | The decimal places of the token.                                                                                  |
| [totalSupply](#totalsupply)           | The amount of tokens in existence.                                                                                 |
| [balanceOf](#balanceof)               | The amount of tokens owned by `owner`.                                                                             |
| [allowance](#allowance)               | The amount of tokens that `spender` can spend on behalf of `owner`.                                                |
| [approve](#approve)                   | Sets the allowance of `spender` over the caller's tokens to `amount`.                                              |
| [transfer](#transfer)                 | Transfer `amount` tokens from the caller to `to`.                                                                  |
| [transferFrom](#transferfrom)         | Transfers `amount` tokens from `from` to `to`.                                                                     |
| [nonces](#nonces)         | The current nonce for `owner`.                                                                     |
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

##### Notes

- Must be overridden or the code will not compile.

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

##### Notes

- Must be overridden or the code will not compile.

---

#### decimals

Returns the decimal places of the token.

```solidity
function decimals() public view virtual returns (uint8)
```

##### Parameter(s)

- None

##### Return Value(s)

- The decimal places of the token.

##### Extras

 - Override if your token requires less than 18 decimals. 

---

#### totalSupply

Returns the amount of tokens in existence.

```solidity
function totalSupply() public view virtual returns (uint256 result)
```

##### Parameter(s)

- None

##### Return Value(s)

- The number of tokens in existence.

---

#### balanceOf

##### Parameter(s)

##### Return Value(s)

---

#### allowance

##### Parameter(s)

##### Return Value(s)

---

#### approve

##### Parameter(s)

##### Return Value(s)

---

#### transfer

##### Parameter(s)

##### Return Value(s)

---

#### transferFrom

##### Parameter(s)

##### Return Value(s)

---

#### nonces

##### Parameter(s)

##### Return Value(s)

---

#### permit

##### Parameter(s)

##### Return Value(s)

---

#### DOMAIN_SEPERATOR

##### Parameter(s)

##### Return Value(s)

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
