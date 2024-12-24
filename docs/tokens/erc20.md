# ERC20

Simple ERC20 + EIP-2612 implementation.


<b>Note:</b>

- The ERC20 standard allows minting and transferring to and from the zero address,
minting and transferring zero tokens, as well as self-approvals.
For performance, this implementation WILL NOT revert for such actions.
Please add any checks with overrides if desired.
- The `permit` function uses the ecrecover precompile (0x1).

<b>If you are overriding:</b>
- NEVER violate the ERC20 invariant&#58;
the total sum of all balances must be equal to `totalSupply()`.
- Check that the overridden function is actually used in the function you want to
change the behavior of. Much of the code has been manually inlined for performance.



<!-- customintro:start --><!-- customintro:end -->

## Custom Errors

### TotalSupplyOverflow()

```solidity
error TotalSupplyOverflow()
```

The total supply has overflowed.

### AllowanceOverflow()

```solidity
error AllowanceOverflow()
```

The allowance has overflowed.

### AllowanceUnderflow()

```solidity
error AllowanceUnderflow()
```

The allowance has underflowed.

### InsufficientBalance()

```solidity
error InsufficientBalance()
```

Insufficient balance.

### InsufficientAllowance()

```solidity
error InsufficientAllowance()
```

Insufficient allowance.

### InvalidPermit()

```solidity
error InvalidPermit()
```

The permit is invalid.

### PermitExpired()

```solidity
error PermitExpired()
```

The permit has expired.

### Permit2AllowanceIsFixedAtInfinity()

```solidity
error Permit2AllowanceIsFixedAtInfinity()
```

The allowance of Permit2 is fixed at infinity.

## Constants

### _PERMIT2

```solidity
address internal constant _PERMIT2 =
    0x000000000022D473030F116dDEE9F6B43aC78BA3
```

The canonical Permit2 address.   
For signature-based allowance granting for single transaction ERC20 `transferFrom`.   
To enable, override `_givePermit2InfiniteAllowance()`.   
[Github](https://github.com/Uniswap/permit2)   
[Etherscan](https://etherscan.io/address/0x000000000022D473030F116dDEE9F6B43aC78BA3)

## ERC20

### totalSupply()

```solidity
function totalSupply() public view virtual returns (uint256 result)
```

Returns the amount of tokens in existence.

### balanceOf(address)

```solidity
function balanceOf(address owner)
    public
    view
    virtual
    returns (uint256 result)
```

Returns the amount of tokens owned by `owner`.

### allowance(address,address)

```solidity
function allowance(address owner, address spender)
    public
    view
    virtual
    returns (uint256 result)
```

Returns the amount of tokens that `spender` can spend on behalf of `owner`.

### approve(address,uint256)

```solidity
function approve(address spender, uint256 amount)
    public
    virtual
    returns (bool)
```

Sets `amount` as the allowance of `spender` over the caller's tokens.   
Emits a {Approval} event.

### transfer(address,uint256)

```solidity
function transfer(address to, uint256 amount)
    public
    virtual
    returns (bool)
```

Transfer `amount` tokens from the caller to `to`.   
Requirements:   
- `from` must at least have `amount`.   
Emits a {Transfer} event.

### transferFrom(address,address,uint256)

```solidity
function transferFrom(address from, address to, uint256 amount)
    public
    virtual
    returns (bool)
```

Transfers `amount` tokens from `from` to `to`.   
Note: Does not update the allowance if it is the maximum uint256 value.   
Requirements:   
- `from` must at least have `amount`.   
- The caller must have at least `amount` of allowance to transfer the tokens of `from`.   
Emits a {Transfer} event.

## EIP-2612

### _constantNameHash()

```solidity
function _constantNameHash()
    internal
    view
    virtual
    returns (bytes32 result)
```

For more performance, override to return the constant value   
of `keccak256(bytes(name()))` if `name()` will never change.

### _versionHash()

```solidity
function _versionHash() internal view virtual returns (bytes32 result)
```

If you need a different value, override this function.

### _incrementNonce(address)

```solidity
function _incrementNonce(address owner) internal virtual
```

For inheriting contracts to increment the nonce.

### nonces(address)

```solidity
function nonces(address owner)
    public
    view
    virtual
    returns (uint256 result)
```

Returns the current nonce for `owner`.   
This value is used to compute the signature for EIP-2612 permit.

### permit(address,address,uint256,uint256,uint8,bytes32,bytes32)

```solidity
function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
) public virtual
```

Sets `value` as the allowance of `spender` over the tokens of `owner`,   
authorized by a signed approval by `owner`.   
Emits a {Approval} event.

### DOMAIN_SEPARATOR()

```solidity
function DOMAIN_SEPARATOR() public view virtual returns (bytes32 result)
```

Returns the EIP-712 domain separator for the EIP-2612 permit.

## Internal Mint Functions

### _mint(address,uint256)

```solidity
function _mint(address to, uint256 amount) internal virtual
```

Mints `amount` tokens to `to`, increasing the total supply.   
Emits a {Transfer} event.

## Internal Burn Functions

### _burn(address,uint256)

```solidity
function _burn(address from, uint256 amount) internal virtual
```

Burns `amount` tokens from `from`, reducing the total supply.   
Emits a {Transfer} event.

## Internal Transfer Functions

### _transfer(address,address,uint256)

```solidity
function _transfer(address from, address to, uint256 amount)
    internal
    virtual
```

Moves `amount` of tokens from `from` to `to`.

## Internal Allowance Functions

### _spendAllowance(address,address,uint256)

```solidity
function _spendAllowance(address owner, address spender, uint256 amount)
    internal
    virtual
```

Updates the allowance of `owner` for `spender` based on spent `amount`.

### _approve(address,address,uint256)

```solidity
function _approve(address owner, address spender, uint256 amount)
    internal
    virtual
```

Sets `amount` as the allowance of `spender` over the tokens of `owner`.   
Emits a {Approval} event.

## Hooks To Override

### _beforeTokenTransfer(address,address,uint256)

```solidity
function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal
    virtual
```

Hook that is called before any transfer of tokens.   
This includes minting and burning.

### _afterTokenTransfer(address,address,uint256)

```solidity
function _afterTokenTransfer(address from, address to, uint256 amount)
    internal
    virtual
```

Hook that is called after any transfer of tokens.   
This includes minting and burning.

## Permit2

### _givePermit2InfiniteAllowance()

```solidity
function _givePermit2InfiniteAllowance()
    internal
    view
    virtual
    returns (bool)
```

Returns whether to fix the Permit2 contract's allowance at infinity.   
This value should be kept constant after contract initialization,   
or else the actual allowance values may not match with the {Approval} events.   
For best performance, return a compile-time constant for zero-cost abstraction.